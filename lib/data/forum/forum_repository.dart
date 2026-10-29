import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nita/core/constants/app_timeouts.dart';
import 'package:nita/core/constants/supabase_config.dart';
import 'package:nita/data/security/admin_pin.dart';
import 'package:nita/data/security/reaction_identity.dart';
import 'package:nita/data/security/spam_guard.dart';
import 'package:nita/models/admin_report_model.dart';
import 'package:nita/models/forum_post_model.dart';

/// Public board repository (Field 2) directly connected to Supabase.
///
/// - No fake or hardcoded messages: directly queries the real database (`pakikiramay_messages`).
/// - Private candle messages live separately in `candle_messages` and never appear here.
/// - Real-time insertion & threaded replies.
/// - Offline fallback via SharedPreferences caching so mourners are never blocked.
///
/// SECURITY (after `supabase/pakikiramay_security.sql` runs):
/// - Tables are INSERT+SELECT only for the anon key. Every privileged
///   action (admin edit/delete/dismiss/private reads, self edit/delete,
///   unlike) goes through PIN- or device-id-verified security-definer RPCs.
/// - Fail closed: when an RPC is missing (project not yet migrated) the
///   action fails with no legacy direct-table fallback, so the anon key
///   can never bypass PIN or device verification.
class ForumRepository {
  const ForumRepository();

  /// Temp (local-only) id sequence. Millisecond timestamps alone collide
  /// when two messages are written in the same millisecond, and the
  /// cache's read-modify-write then drops the earlier row — so every temp
  /// id also carries a monotonic counter. The prefix still marks the row
  /// as local-only (msg-/reply- checks elsewhere keep working).
  static int _tempSeq = 0;

  static String _tempId(String prefix) =>
      '$prefix-${DateTime.now().millisecondsSinceEpoch}-${_tempSeq++}';

  static bool _lastFetchSucceededRemotely = false;

  /// True when the most recent [fetchPosts] call loaded live rows from
  /// Supabase rather than falling back to the local cache.
  bool get lastFetchSucceededRemotely => _lastFetchSucceededRemotely;

  static const String _cachedPostsKey = 'memorial_db_posts_cache_v1';
  static const String _userReactionsKey = 'memorial_user_reactions_v1';
  static const String _reactionsMapKey = 'memorial_reactions_counts_v1';
  static const String _repliesKey = 'memorial_local_replies_v1';

  static const String messagesTable = 'pakikiramay_messages';
  static const String repliesTable = 'pakikiramay_replies';
  static const String reactionsTable = 'pakikiramay_reactions';
  static const String reportsTable = 'pakikiramay_reports';

  /// Fetches real messages directly from Supabase.
  /// Falls back to local cache if offline or unconfigured.
  Future<List<ForumPost>> fetchPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final userReactions = await _loadUserReactions(prefs);
    final reactionCounts = await _loadReactionCounts(prefs);
    final localReplies = await _loadLocalReplies(prefs);
    // Snapshot the previous cache before a successful remote fetch
    // overwrites it. Unsent (pendingSync) posts live only here until
    // their retry succeeds, so they must survive the overwrite.
    final cachedPosts = await _loadLocalCache(
      prefs,
      userReactions,
      reactionCounts,
      localReplies,
    );

    _lastFetchSucceededRemotely = false;
    final client = SupabaseConfig.safeClient();
    if (client != null) {
      try {
        // Fetch messages from the database (newest first)
        final rows = await client
            .from(messagesTable)
            .select('id, name, message, created_at')
            .order('created_at', ascending: false)
            .limit(100)
            .timeout(AppTimeouts.remote);

        // Fetch replies from database if table is available
        Map<String, List<ForumReply>> dbReplies = {};
        var dbRepliesLoaded = false;
        // Remote like counts (shared across devices). Empty when the
        // reactions table is missing or offline — local cache wins then.
        Map<String, Map<String, int>> remoteCounts = {};
        // Spam layer 3: report counts for auto-hide. Empty when the
        // reports table is not readable — filtering degrades gracefully.
        Map<String, int> reportCounts = {};
        try {
          remoteCounts = await fetchReactionCounts();
        } catch (_) {
          remoteCounts = {};
        }
        try {
          reportCounts = await fetchReportCounts();
        } catch (_) {
          reportCounts = {};
        }
        try {
          // Prefer the reply_to_name column; fall back when the DB
          // hasn't been migrated yet (old deployments).
          List replyRows;
          try {
            replyRows = await client
                .from(repliesTable)
                .select(
                    'id, post_id, author_name, message, created_at, reply_to_name')
                .order('created_at', ascending: true)
                .timeout(AppTimeouts.quick) as List;
          } catch (_) {
            replyRows = await client
                .from(repliesTable)
                .select('id, post_id, author_name, message, created_at')
                .order('created_at', ascending: true)
                .timeout(AppTimeouts.quick) as List;
          }

          for (final r in replyRows) {
            final replyId = r['id']?.toString() ?? '';
            final rawMessage = r['message'] as String? ?? '';
            // Spam layer 3: skip heavily reported replies.
            if ((reportCounts[replyId] ?? 0) >= SpamGuard.hideThreshold) {
              continue;
            }
            final remoteReplyTo =
                (r['reply_to_name'] as String? ?? '').trim();
            var reply = ForumReply(
              id: replyId,
              postId: r['post_id']?.toString() ?? '',
              authorName: r['author_name'] as String? ?? 'Anonymous',
              message: rawMessage,
              createdAt: r['created_at'] != null
                  ? DateTime.tryParse(r['created_at'] as String) ?? DateTime.now()
                  : DateTime.now(),
              replyToName: remoteReplyTo.isNotEmpty
                  ? remoteReplyTo
                  : deriveReplyToFromMention(rawMessage),
            );
            // Overlay remote like counts first, then local reaction state
            // (same id-keyed stores as post reactions).
            final baseReactions =
                remoteCounts[replyId] ?? reactionCounts[replyId];
            if (baseReactions != null ||
                userReactions.containsKey(replyId)) {
              reply = reply.copyWith(
                reactions: baseReactions ?? reply.reactions,
                userReactions: userReactions[replyId] ?? <String>{},
              );
            }
            dbReplies.putIfAbsent(reply.postId, () => []).add(reply);
          }
          dbRepliesLoaded = true;
        } catch (_) {
          // Replies table may be local or unmigrated yet
          dbReplies = localReplies;
        }

        // Drop cached temp replies whose real row already landed (e.g.
        // an insert timed out after the server accepted it). This keeps
        // duplicate "Unsent" replies out of the cache across restarts.
        if (dbRepliesLoaded) {
          var localRepliesChanged = false;
          for (final entry in localReplies.entries) {
            final realForPost = dbReplies[entry.key] ?? const <ForumReply>[];
            final before = entry.value.length;
            entry.value.removeWhere(
              (r) =>
                  r.pendingSync &&
                  r.id.startsWith('reply-') &&
                  realForPost.any(
                    (real) =>
                        real.authorName == r.authorName &&
                        real.message == r.message,
                  ),
            );
            if (entry.value.length != before) localRepliesChanged = true;
          }
          if (localRepliesChanged) {
            await _saveLocalReplies(prefs, localReplies);
          }
        }

        final List<ForumPost> realPosts = [];
        final hiddenIds = await SpamGuard.loadHiddenIds();
        for (final row in (rows as List)) {
          final id = row['id']?.toString() ?? '';
          final author = (row['name'] as String? ?? '').trim();
          final message = (row['message'] as String? ?? '').trim();
          if (message.isEmpty) continue;
          // Spam layer 3: skip heavily reported posts (server counts or
          // locally remembered hides so offline stays hidden).
          if ((reportCounts[id] ?? 0) >= SpamGuard.hideThreshold ||
              hiddenIds.contains(id)) {
            hiddenIds.add(id);
            continue;
          }

          final createdAt = row['created_at'] != null
              ? DateTime.tryParse(row['created_at'] as String) ?? DateTime.now()
              : DateTime.now();

          // Merge replies (from DB or local), dropping heavily reported
          // and locally hidden ones.
          final postReplies = [
            ...?dbReplies[id],
            ...?localReplies[id]?.where((lr) => !dbReplies.containsKey(id) || !dbReplies[id]!.any((dr) => dr.id == lr.id)),
          ].where((r) {
            if ((reportCounts[r.id] ?? 0) >= SpamGuard.hideThreshold ||
                hiddenIds.contains(r.id)) {
              hiddenIds.add(r.id);
              return false;
            }
            return true;
          }).toList();

          final postReactions = remoteCounts[id] ??
              reactionCounts[id] ?? {
            'heart': 0,
          };

          realPosts.add(
            ForumPost(
              id: id,
              authorName: author.isEmpty ? 'Anonymous' : author,
              message: message,
              createdAt: createdAt,
              reactions: postReactions,
              userReactions: userReactions[id] ?? <String>{},
              replies: postReplies,
            ),
          );
        }

        // Keep unsent posts across a successful refresh. Without this,
        // the cache overwrite below deletes a pending post before it can
        // be retried (especially on a fresh app start).
        final pendingPosts = <ForumPost>[];
        for (final p in cachedPosts) {
          if (!p.pendingSync) continue;
          if (realPosts.any(
            (r) =>
                r.authorName == p.authorName && r.message == p.message,
          )) {
            continue;
          }
          if (pendingPosts.any(
            (pp) =>
                pp.id == p.id ||
                (pp.authorName == p.authorName &&
                    pp.message == p.message),
          )) {
            continue;
          }
          pendingPosts.add(p);
        }
        final mergedPosts = [
          ...pendingPosts.where(
            (pp) => !realPosts.any((p) => p.id == pp.id),
          ),
          ...realPosts,
        ];

        // Cache real posts locally (plus any still-unsent posts)
        await _saveLocalCache(prefs, mergedPosts);
        await SpamGuard.saveHiddenIds(hiddenIds);
        _lastFetchSucceededRemotely = true;
        // Filter the just-cached list too so hidden posts vanish now,
        // not only on the next launch.
        return mergedPosts
            .where((p) => !hiddenIds.contains(p.id))
            .toList();
      } catch (e) {
        _lastFetchSucceededRemotely = false;
        debugPrint('ForumRepository Supabase fetch skipped: $e');
      }
    }

    // Offline / unconfigured: return cached real posts (minus hidden).
    final hiddenIds = await SpamGuard.loadHiddenIds();
    return cachedPosts
        .where((p) => !hiddenIds.contains(p.id))
        .map(
          (p) => p.copyWith(
            replies: p.replies
                .where((r) => !hiddenIds.contains(r.id))
                .toList(),
          ),
        )
        .toList();
  }

  /// Inserts a new message directly to Supabase and updates local cache.
  Future<ForumPost?> createPost({
    required String authorName,
    required String message,
  }) async {
    final rawName = authorName.trim();
    final cleanName = rawName.isEmpty
        ? 'Anonymous'
        : (rawName.length > 50 ? rawName.substring(0, 50) : rawName);
    final cleanMessage = message.trim();
    if (cleanMessage.isEmpty || cleanMessage.length > 1000) return null;
    // Spam layer 2: blocklist — never store or send blocked content.
    if (SpamGuard.containsBlockedWords(cleanMessage)) return null;

    final tempId = _tempId('msg');
    final now = DateTime.now();

    ForumPost newPost = ForumPost(
      id: tempId,
      authorName: cleanName,
      message: cleanMessage,
      createdAt: now,
      reactions: const {'heart': 0},
      userReactions: const {},
      replies: const [],
    );

    final client = SupabaseConfig.safeClient();
    if (client != null) {
      try {
        final deviceId = await ReactionIdentity.deviceId();
        // Auto-public: new rows are readable instantly because the
        // SELECT policy only allows `approved = true`. The flag is owned
        // by the database — `supabase/pakikiramay_security.sql` sets
        // `default true` on the column — so the client never sends it
        // (a client-chosen value would let anyone approve their row).
        // `device_id` stamps ownership for self-edit/delete and rate
        // limiting, and `.select('id, created_at')` avoids reading back
        // `device_id` (which is hidden from public SELECT).
        final res = await client
            .from(messagesTable)
            .insert({
              'name': cleanName,
              'message': cleanMessage,
              'device_id': deviceId,
            })
            .select('id, created_at')
            .single()
            .timeout(AppTimeouts.remote);

        final realId = res['id']?.toString() ?? tempId;
        final rawAt = res['created_at'];
        final realAt = rawAt is String ? DateTime.tryParse(rawAt) : null;
        newPost = newPost.copyWith(
          id: realId,
          createdAt: realAt ?? newPost.createdAt,
        );
      } catch (e) {
        debugPrint('ForumRepository post insert error: $e');
      }
    }

    if (newPost.id.startsWith('msg-')) {
      newPost = newPost.copyWith(pendingSync: true);
    }

    // Save in local cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = await fetchPosts();
      final updated = [newPost, ...cached.where((p) => p.id != newPost.id)];
      await _saveLocalCache(prefs, updated);
    } catch (_) {}

    return newPost;
  }

  /// Derives "Juan Dela Cruz" from a leading "@Juan Dela Cruz hello".
  /// Used when the remote row has no reply_to_name column so other
  /// devices still see the thread context from the @mention prefix.
  static String deriveReplyToFromMention(String message) {
    if (!message.startsWith('@')) return '';
    final m = RegExp(r'^@\S+(?:\s+\S+){0,2}').firstMatch(message.trim());
    if (m == null) return '';
    return m.group(0)!.substring(1).trim();
  }

  /// Inserts a reply to a message. [replyToName] records who the reply
  /// answers (shown as "Tumutugon kay X"). It is sent as reply_to_name
  /// when the column exists, with a fallback insert without it so old
  /// databases keep working. The @mention prefix in [message] is always
  /// kept so context survives even without the column.
  Future<ForumReply?> addReply({
    required String postId,
    required String authorName,
    required String message,
    String replyToName = '',
  }) async {
    final rawName = authorName.trim();
    final cleanName = rawName.isEmpty
        ? 'Anonymous'
        : (rawName.length > 50 ? rawName.substring(0, 50) : rawName);
    final cleanMessage = message.trim();
    if (cleanMessage.isEmpty || cleanMessage.length > 1000) return null;
    // Spam layer 2: blocklist — never store or send blocked content.
    if (SpamGuard.containsBlockedWords(cleanMessage)) return null;
    final rawReplyTo = replyToName.trim();
    final cleanReplyTo =
        rawReplyTo.length > 50 ? rawReplyTo.substring(0, 50) : rawReplyTo;

    final tempId = _tempId('reply');
    ForumReply newReply = ForumReply(
      id: tempId,
      postId: postId,
      authorName: cleanName,
      message: cleanMessage,
      createdAt: DateTime.now(),
      replyToName: cleanReplyTo,
    );

    // Remote insert uses DB defaults for id/created_at (uuid mismatch fix).
    // Temp parents (msg-...) don't exist remotely — local-only, no FK error.
    final isTempParent =
        postId.startsWith('msg-') || postId.startsWith('reply-');
    final client = SupabaseConfig.safeClient();
    if (client != null && !isTempParent) {
      try {
        final deviceId = await ReactionIdentity.deviceId();
        Map<String, dynamic> res;
        try {
          res = await client
              .from(repliesTable)
              .insert({
                'post_id': postId,
                'author_name': cleanName,
                'message': cleanMessage,
                'device_id': deviceId,
                if (cleanReplyTo.isNotEmpty) 'reply_to_name': cleanReplyTo,
              })
              .select('id, created_at')
              .single()
              .timeout(AppTimeouts.remote);
        } catch (_) {
          // Column missing on old DBs — retry without reply_to_name.
          res = await client
              .from(repliesTable)
              .insert({
                'post_id': postId,
                'author_name': cleanName,
                'message': cleanMessage,
                'device_id': deviceId,
              })
              .select('id, created_at')
              .single()
              .timeout(AppTimeouts.remote);
        }
        final realId = res['id']?.toString();
        DateTime? realAt;
        final rawAt = res['created_at'];
        if (rawAt is String) realAt = DateTime.tryParse(rawAt);
        newReply = ForumReply(
          id: (realId == null || realId.isEmpty) ? tempId : realId,
          postId: postId,
          authorName: cleanName,
          message: cleanMessage,
          createdAt: realAt ?? newReply.createdAt,
          replyToName: newReply.replyToName,
        );
      } catch (e) {
        debugPrint('ForumRepository Supabase reply error: $e');
      }
    }

    // Save reply locally
    try {
      final prefs = await SharedPreferences.getInstance();
      final localReplies = await _loadLocalReplies(prefs);
      localReplies.putIfAbsent(postId, () => []).add(newReply);
      await _saveLocalReplies(prefs, localReplies);
    } catch (_) {}

    return newReply;
  }

  /// Drops a local-only reply row (temp `reply-...` id) from the local
  /// replies store and the cached feed after its upload succeeds. Without
  /// this, the temp copy can reappear as a duplicate "Unsent" row on the
  /// next refresh. Local cache only, best-effort, never throws.
  Future<void> removeLocalReply(String replyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localReplies = await _loadLocalReplies(prefs);
      var changed = false;
      for (final entry in localReplies.entries) {
        final before = entry.value.length;
        entry.value.removeWhere((r) => r.id == replyId);
        if (entry.value.length != before) changed = true;
      }
      if (changed) await _saveLocalReplies(prefs, localReplies);
      final cached = await _loadLocalCache(
        prefs,
        await _loadUserReactions(prefs),
        await _loadReactionCounts(prefs),
        localReplies,
      );
      await _saveLocalCache(
        prefs,
        cached
            .map(
              (p) => p.copyWith(
                replies: p.replies.where((r) => r.id != replyId).toList(),
              ),
            )
            .toList(),
      );
    } catch (e) {
      debugPrint('ForumRepository removeLocalReply skipped: $e');
    }
  }

  /// Drops a local-only post row (temp `msg-...` id) and its local replies
  /// from the cache after its upload succeeds. Without this, the temp copy
  /// stays in the cache and can reappear as a duplicate "Unsent" post.
  /// Local cache only, best-effort, never throws.
  Future<void> removeLocalPost(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localReplies = await _loadLocalReplies(prefs);
      localReplies.remove(postId);
      await _saveLocalReplies(prefs, localReplies);
      final cached = await _loadLocalCache(
        prefs,
        await _loadUserReactions(prefs),
        await _loadReactionCounts(prefs),
        localReplies,
      );
      await _saveLocalCache(
        prefs,
        cached.where((p) => p.id != postId).toList(),
      );
    } catch (e) {
      debugPrint('ForumRepository removeLocalPost skipped: $e');
    }
  }

  /// After a pending post gets its real id: move its still-unsent
  /// replies from the temp id bucket to the real id bucket, then drop the
  /// temp post from the cache. Keeps a failed reply retry recoverable on
  /// the next launch instead of losing it with the temp parent.
  Future<void> finalizeLocalPost(String tempId, String realId) async {
    if (tempId == realId) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final localReplies = await _loadLocalReplies(prefs);
      final moving = localReplies.remove(tempId);
      if (moving != null && moving.isNotEmpty) {
        localReplies.putIfAbsent(realId, () => []).addAll(
              moving.map((r) => r.copyWith(postId: realId)),
            );
      }
      await _saveLocalReplies(prefs, localReplies);
      final cached = await _loadLocalCache(
        prefs,
        await _loadUserReactions(prefs),
        await _loadReactionCounts(prefs),
        localReplies,
      );
      await _saveLocalCache(
        prefs,
        cached.where((p) => p.id != tempId).toList(),
      );
    } catch (e) {
      debugPrint('ForumRepository finalizeLocalPost skipped: $e');
    }
  }

  /// Toggles the heart Like for a post OR a reply — both are keyed by
  /// their unique id in the same local stores.
  Future<void> toggleReaction({
    required String postId,
    required String reactionType,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userReactions = await _loadUserReactions(prefs);
      final reactionCounts = await _loadReactionCounts(prefs);

      final currentSet = userReactions[postId] ?? <String>{};
      final hasReacted = currentSet.contains(reactionType);

      final currentMap = reactionCounts[postId] ?? {
        'heart': 0,
      };

      final currentCount = currentMap[reactionType] ?? 0;

      if (hasReacted) {
        currentSet.remove(reactionType);
        currentMap[reactionType] = (currentCount - 1).clamp(0, 99999);
      } else {
        currentSet.add(reactionType);
        currentMap[reactionType] = currentCount + 1;
      }

      userReactions[postId] = currentSet;
      reactionCounts[postId] = currentMap;

      await _saveUserReactions(prefs, userReactions);
      await _saveReactionCounts(prefs, reactionCounts);
    } catch (e) {
      debugPrint('ForumRepository toggleReaction error: $e');
    }
  }

  /// Shared like counts across devices (powers live likes).
  /// Returns {targetId: {reactionType: count}}. Empty when offline,
  /// unconfigured, or the reactions table is missing.
  Future<Map<String, Map<String, int>>> fetchReactionCounts() async {
    final client = SupabaseConfig.safeClient();
    if (client == null) return {};
    try {
      // Paginate over the whole table instead of a hard 2000-row cap so
      // counts stay exact as the memorial grows (1000 is the PostgREST
      // server-side max rows per request).
      const pageSize = 1000;
      var from = 0;
      final counts = <String, Map<String, int>>{};
      while (true) {
        final rows = await client
            .from(reactionsTable)
            .select('target_id, reaction_type')
            .order('target_id')
            .range(from, from + pageSize - 1)
            .timeout(AppTimeouts.remote);
        final list = rows as List;
        for (final row in list) {
          final target = row['target_id']?.toString() ?? '';
          final type = (row['reaction_type'] as String? ?? '').trim();
          if (target.isEmpty || type.isEmpty) continue;
          counts.putIfAbsent(target, () => {
                'heart': 0,
              });
          counts[target]![type] = (counts[target]![type] ?? 0) + 1;
        }
        if (list.length < pageSize) break;
        from += pageSize;
      }
      return counts;
    } catch (e) {
      debugPrint('ForumRepository fetchReactionCounts skipped: $e');
      return {};
    }
  }

  /// Persists a like remotely so other devices see it live.
  /// Returns true when the row was saved. Never throws — failures are
  /// logged and reported as false so the caller can retry/reconcile.
  /// Temp ids (msg-...) never exist remotely — skipped as false.
  /// [deviceId] stamps the row owner so unlike deletes only our row.
  /// [reactorName] is the display name shown in the likers sheet.
  Future<bool> addReactionRemote({
    required String targetId,
    required String reactionType,
    required String deviceId,
    String reactorName = 'Anonymous',
  }) async {
    final client = SupabaseConfig.safeClient();
    if (client == null) return false;
    if (targetId.startsWith('msg-') || targetId.startsWith('reply-')) {
      return false;
    }
    if (targetId.isEmpty || deviceId.isEmpty) return false;
    final trimmed = reactorName.trim();
    final cleanName =
        trimmed.isEmpty ? 'Anonymous' : trimmed.substring(0, trimmed.length > 50 ? 50 : trimmed.length);
    try {
      await client.from(reactionsTable).insert({
        'target_id': targetId,
        'reaction_type': reactionType,
        'device_id': deviceId,
        'reactor_name': cleanName,
      }).timeout(AppTimeouts.remote);
      return true;
    } catch (e) {
      debugPrint('ForumRepository addReactionRemote FAILED: $e');
      return false;
    }
  }

  /// Removes our own remote like (un-like). Goes through the
  /// device-id-verified RPC `pakikiramay_unlike` (the reactions table has
  /// no anon DELETE after the security migration); legacy direct
  /// select+delete fallback while the project is unmigrated.
  /// Returns true when a row was deleted. Never throws.
  Future<bool> removeReactionRemote({
    required String targetId,
    required String reactionType,
    required String deviceId,
  }) async {
    final client = SupabaseConfig.safeClient();
    if (client == null) return false;
    if (targetId.startsWith('msg-') || targetId.startsWith('reply-')) {
      return false;
    }
    if (targetId.isEmpty || deviceId.isEmpty) return false;
    try {
      final ok = (await client.rpc(
            'pakikiramay_unlike',
            params: {
              'p_target_id': targetId,
              'p_reaction_type': reactionType,
              'p_device_id': deviceId,
            },
          ).timeout(AppTimeouts.remote)) as bool?;
      return ok ?? false;
    } catch (e) {
      if (!isRpcMissing(e)) {
        debugPrint('ForumRepository removeReactionRemote FAILED: $e');
        return false;
      }
      debugPrint('ForumRepository unlike RPC missing — legacy fallback.');
    }
    try {
      final client = SupabaseConfig.safeClient();
      if (client == null) return false;
      final rows = await client
          .from(reactionsTable)
          .select('id')
          .eq('target_id', targetId)
          .eq('reaction_type', reactionType)
          .eq('device_id', deviceId)
          .limit(1)
          .timeout(AppTimeouts.remote);
      final list = rows as List;
      if (list.isEmpty) return false;
      final rowId = list.first['id']?.toString() ?? '';
      if (rowId.isEmpty) return false;
      await client
          .from(reactionsTable)
          .delete()
          .eq('id', rowId)
          .timeout(AppTimeouts.remote);
      return true;
    } catch (e) {
      debugPrint('ForumRepository removeReactionRemote FAILED: $e');
      return false;
    }
  }

  /// Display names of who liked a post/reply, oldest first, deduped.
  /// Powers the likers bottom sheet. Empty when offline, unconfigured,
  /// or nobody liked yet. Never throws.
  Future<List<String>> fetchLikerNames(String targetId) async {
    final client = SupabaseConfig.safeClient();
    if (client == null || targetId.isEmpty) return [];
    if (targetId.startsWith('msg-') || targetId.startsWith('reply-')) {
      return [];
    }
    try {
      final rows = await client
          .from(reactionsTable)
          .select('reactor_name, created_at')
          .eq('target_id', targetId)
          .eq('reaction_type', 'heart')
          .order('created_at', ascending: true)
          .limit(100)
          .timeout(AppTimeouts.remote);
      final names = <String>[];
      for (final row in (rows as List)) {
        final raw = (row as Map)['reactor_name'];
        final name = (raw is String ? raw : '').trim();
        final clean = name.isEmpty ? 'Anonymous' : name;
        if (!names.contains(clean)) names.add(clean);
      }
      return names;
    } catch (e) {
      debugPrint('ForumRepository fetchLikerNames skipped: $e');
      return [];
    }
  }

  /// Submits a moderation report for a post or reply.
  /// Returns [ReportSubmitOutcome.saved] when stored,
  /// [ReportSubmitOutcome.alreadyReported] on duplicate
  /// (unique target+device), [ReportSubmitOutcome.failed] when offline,
  /// unconfigured, temp id, or the table is missing.
  /// Never throws — failures are logged so the UI can show a retry note.
  Future<ReportSubmitOutcome> submitReport({
    required String targetId,
    required String targetKind,
    required String reason,
    String details = '',
    String deviceId = '',
    String reporterName = 'Anonymous',
  }) async {
    final client = SupabaseConfig.safeClient();
    if (client == null || targetId.isEmpty) {
      return ReportSubmitOutcome.failed;
    }
    if (targetId.startsWith('msg-') || targetId.startsWith('reply-')) {
      return ReportSubmitOutcome.failed;
    }
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) return ReportSubmitOutcome.failed;
    final kind = targetKind == 'reply' ? 'reply' : 'post';
    final trimmedDetails = details.trim();
    final cleanDetails = trimmedDetails.length > 200
        ? trimmedDetails.substring(0, 200)
        : trimmedDetails;
    final nameTrimmed = reporterName.trim();
    final cleanName = nameTrimmed.isEmpty
        ? 'Anonymous'
        : (nameTrimmed.length > 50 ? nameTrimmed.substring(0, 50) : nameTrimmed);
    try {
      await client.from(reportsTable).insert({
        'target_id': targetId,
        'target_kind': kind,
        'reason': cleanReason,
        'details': cleanDetails,
        'reporter_device_id': deviceId.trim(),
        'reporter_name': cleanName,
      }).timeout(AppTimeouts.remote);
      return ReportSubmitOutcome.saved;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      // Unique violation (second report from same device, e.g. after
      // reinstall when local dedupe was cleared) is not a failure:
      // tell the UI to show "already reported".
      if (msg.contains('409') ||
          msg.contains('23505') ||
          msg.contains('duplicate') ||
          msg.contains('unique') ||
          msg.contains('already exists')) {
        debugPrint('ForumRepository submitReport duplicate: $e');
        return ReportSubmitOutcome.alreadyReported;
      }
      debugPrint('ForumRepository submitReport skipped: $e');
      return ReportSubmitOutcome.failed;
    }
  }

  /// Report counts per target ({targetId: count}). Powers spam layer 3:
  /// targets with >= [SpamGuard.hideThreshold] reports are hidden.
  /// Runs through the aggregate RPC `pakikiramay_report_counts()` — raw
  /// report rows are private after the security migration, so there is
  /// deliberately NO direct-table fallback (fail closed). Empty when
  /// offline, unconfigured, or the RPC is missing. Never throws.
  Future<Map<String, int>> fetchReportCounts() async {
    final client = SupabaseConfig.safeClient();
    if (client == null) return {};
    try {
      final rows = await client
          .rpc('pakikiramay_report_counts')
          .timeout(AppTimeouts.remote);
      final counts = <String, int>{};
      for (final row in (rows as List)) {
        final m = row as Map;
        final target = m['target_id']?.toString() ?? '';
        if (target.isEmpty) continue;
        final raw = m['report_count'];
        final count = raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;
        counts[target] = count;
      }
      return counts;
    } catch (e) {
      debugPrint('ForumRepository fetchReportCounts skipped: $e');
      return {};
    }
  }

  /// Report count for one target. Used to hide immediately after the
  /// threshold report lands. Returns 0 when offline or unreadable.
  /// Never throws.
  Future<int> fetchReportCount(String targetId) async {
    if (targetId.isEmpty) return 0;
    final client = SupabaseConfig.safeClient();
    if (client == null) return 0;
    final counts = await fetchReportCounts();
    return counts[targetId] ?? 0;
  }

  /// Full report rows for the family admin page, newest first.
  /// Runs through the PIN-verified RPC `pakikiramay_admin_list_reports()`
  /// — raw report rows are private after the migration, so there is
  /// deliberately NO direct-table fallback (fail closed). Empty when
  /// offline, unconfigured, the RPC is missing, or the PIN is wrong
  /// server-side. Never throws.
  Future<List<AdminReportRow>> fetchAdminReports({int limit = 200}) async {
    final client = SupabaseConfig.safeClient();
    if (client == null) return [];
    final pin = await AdminCredential.effectivePin();
    try {
      final rows = await client
          .rpc('pakikiramay_admin_list_reports', params: {
        'p_pin': pin,
        'p_limit': limit,
      }).timeout(AppTimeouts.remote);
      return _parseAdminReportRows(rows as List);
    } catch (e) {
      debugPrint('ForumRepository fetchAdminReports skipped: $e');
      return [];
    }
  }

  /// Shared row mapper for the RPC result.
  List<AdminReportRow> _parseAdminReportRows(List rows) {
    final out = <AdminReportRow>[];
    for (final row in rows) {
      final m = row as Map;
      final targetId = m['target_id']?.toString() ?? '';
      if (targetId.isEmpty) continue;
      DateTime at = DateTime.now();
      final rawAt = m['created_at'];
      if (rawAt is String) at = DateTime.tryParse(rawAt) ?? at;
      out.add(AdminReportRow(
        id: m['id']?.toString() ?? '',
        targetId: targetId,
        targetKind: (m['target_kind'] as String? ?? 'post').trim() == 'reply'
            ? 'reply'
            : 'post',
        reason: (m['reason'] as String? ?? '').trim(),
        details: (m['details'] as String? ?? '').trim(),
        reporterName: (m['reporter_name'] as String? ?? '').trim().isEmpty
            ? 'Anonymous'
            : (m['reporter_name'] as String).trim(),
        createdAt: at,
      ));
    }
    return out;
  }

  /// Dismisses all reports for one target (family reviewed, kept the
  /// message). PIN-verified RPC only — reports rows are private after
  /// the security migration, so there is deliberately NO anon DELETE
  /// fallback (fail closed). Returns true when deleted. Never throws.
  Future<bool> dismissReports(String targetId) async {
    final client = SupabaseConfig.safeClient();
    if (client == null || targetId.isEmpty) return false;
    if (targetId.startsWith('msg-') || targetId.startsWith('reply-')) {
      return true;
    }
    final pin = await AdminCredential.effectivePin();
    try {
      final ok = (await client.rpc(
            'pakikiramay_admin_dismiss_reports',
            params: {'p_pin': pin, 'p_target_id': targetId},
          ).timeout(AppTimeouts.remote)) as bool?;
      return ok ?? false;
    } catch (e) {
      debugPrint('ForumRepository dismissReports skipped: $e');
      return false;
    }
  }

  /// Admin edit of any post text (no own-device or time check — only
  /// call from the PIN-gated admin page). PIN-verified RPC only — there
  /// is deliberately NO anon UPDATE fallback (fail closed). Returns true
  /// when saved. Never throws.
  Future<bool> adminUpdatePost({
    required String postId,
    required String message,
  }) async {
    final clean = message.trim();
    if (postId.isEmpty || clean.isEmpty || clean.length > 1000) return false;
    if (SpamGuard.containsBlockedWords(clean)) return false;
    if (postId.startsWith('msg-')) {
      return _updateCachedPostMessage(postId, clean);
    }
    final client = SupabaseConfig.safeClient();
    if (client == null) return false;
    final pin = await AdminCredential.effectivePin();
    try {
      final ok = (await client.rpc(
            'pakikiramay_admin_edit_message',
            params: {'p_pin': pin, 'p_id': postId, 'p_message': clean},
          ).timeout(AppTimeouts.remote)) as bool?;
      if (ok ?? false) {
        await _updateCachedPostMessage(postId, clean);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('ForumRepository adminUpdatePost skipped: $e');
      return false;
    }
  }

  /// Admin edit of any reply text (no own-device or time check — only
  /// call from the PIN-gated admin page). PIN-verified RPC only — there
  /// is deliberately NO anon UPDATE fallback (fail closed). Returns true
  /// when saved. Never throws.
  Future<bool> adminUpdateReply({
    required String postId,
    required String replyId,
    required String message,
  }) async {
    final clean = message.trim();
    if (postId.isEmpty ||
        replyId.isEmpty ||
        clean.isEmpty ||
        clean.length > 1000) {
      return false;
    }
    if (SpamGuard.containsBlockedWords(clean)) return false;
    if (replyId.startsWith('reply-') || postId.startsWith('msg-')) {
      return _updateCachedReplyMessage(postId, replyId, clean);
    }
    final client = SupabaseConfig.safeClient();
    if (client == null) return false;
    final pin = await AdminCredential.effectivePin();
    try {
      final ok = (await client.rpc(
            'pakikiramay_admin_edit_reply',
            params: {
              'p_pin': pin,
              'p_post_id': postId,
              'p_reply_id': replyId,
              'p_message': clean,
            },
          ).timeout(AppTimeouts.remote)) as bool?;
      if (ok ?? false) {
        await _updateCachedReplyMessage(postId, replyId, clean);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('ForumRepository adminUpdateReply skipped: $e');
      return false;
    }
  }

  /// Admin delete of any message/reply + its reports (bypasses the
  /// own-device check in the controller — only call from the PIN-gated
  /// admin page). PIN-verified RPC only; temp ids (local-only rows) are
  /// cleaned from the device cache. There is deliberately NO direct-table
  /// delete fallback (fail closed). Returns true when deleted.
  /// Never throws.
  Future<bool> adminDeleteTarget({
    required String targetId,
    required String targetKind,
    String parentPostId = '',
  }) async {
    if (targetId.isEmpty) return false;
    // Temp ids (msg-/reply-) are local-only rows — clean the device cache.
    if (targetId.startsWith('msg-') || targetId.startsWith('reply-')) {
      return _adminDeleteTargetCached(
        targetId: targetId,
        targetKind: targetKind,
        parentPostId: parentPostId,
      );
    }
    final client = SupabaseConfig.safeClient();
    if (client == null) return false;
    final pin = await AdminCredential.effectivePin();
    try {
      final params = <String, dynamic>{
        'p_pin': pin,
        'p_target_kind': targetKind,
        'p_target_id': targetId,
      };
      if (parentPostId.isNotEmpty) params['p_parent_post_id'] = parentPostId;
      final ok = (await client.rpc(
            'pakikiramay_admin_delete_target',
            params: params,
          ).timeout(AppTimeouts.remote)) as bool?;
      if (ok ?? false) {
        await dismissReports(targetId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('ForumRepository adminDeleteTarget skipped: $e');
      return false;
    }
  }

  /// Local-cache cleanup for temp-id rows that only exist on-device.
  Future<bool> _adminDeleteTargetCached({
    required String targetId,
    required String targetKind,
    required String parentPostId,
  }) async {
    try {
      if (targetKind == 'reply') {
        if (parentPostId.isEmpty) return false;
        final ok = await deleteReply(
          postId: parentPostId,
          replyId: targetId,
        );
        if (!ok) return false;
      } else {
        final ok = await deletePost(targetId);
        if (!ok) return false;
      }
      await dismissReports(targetId);
      return true;
    } catch (e) {
      debugPrint('ForumRepository adminDeleteTarget skipped: $e');
      return false;
    }
  }

  /// Edits your own post's text (fix #4). Temp ids are local-only and
  /// always succeed. Real ids go through the device-id-verified RPC
  /// `pakikiramay_edit_message` (owner match + 15-minute edit window
  /// enforced server-side); there is deliberately NO direct-table
  /// fallback (fail closed). Returns true when saved. Never throws.
  Future<bool> updatePostMessage({
    required String postId,
    required String message,
  }) async {
    final clean = message.trim();
    if (postId.isEmpty || clean.isEmpty || clean.length > 1000) return false;
    if (SpamGuard.containsBlockedWords(clean)) return false;
    if (postId.startsWith('msg-')) {
      return _updateCachedPostMessage(postId, clean);
    }
    final client = SupabaseConfig.safeClient();
    if (client == null) return false;
    final deviceId = await ReactionIdentity.deviceId();
    if (deviceId.isEmpty) return false;
    try {
      final ok = (await client.rpc(
            'pakikiramay_edit_message',
            params: {
              'p_id': postId,
              'p_device_id': deviceId,
              'p_message': clean,
            },
          ).timeout(AppTimeouts.remote)) as bool?;
      if (ok ?? false) {
        await _updateCachedPostMessage(postId, clean);
        return true;
      }
      // false = not this device's row, outside the edit window, or the
      // row predates device tracking — treated as a genuine failure.
      return false;
    } catch (e) {
      debugPrint('ForumRepository updatePostMessage skipped: $e');
      return false;
    }
  }

  /// Edits your own reply's text (fix #4). Same rules as posts.
  /// Returns true when saved. Never throws.
  Future<bool> updateReplyMessage({
    required String postId,
    required String replyId,
    required String message,
  }) async {
    final clean = message.trim();
    if (postId.isEmpty ||
        replyId.isEmpty ||
        clean.isEmpty ||
        clean.length > 1000) {
      return false;
    }
    if (SpamGuard.containsBlockedWords(clean)) return false;
    if (replyId.startsWith('reply-') || postId.startsWith('msg-')) {
      return _updateCachedReplyMessage(postId, replyId, clean);
    }
    final client = SupabaseConfig.safeClient();
    if (client == null) return false;
    final deviceId = await ReactionIdentity.deviceId();
    if (deviceId.isEmpty) return false;
    try {
      final ok = (await client.rpc(
            'pakikiramay_edit_reply',
            params: {
              'p_id': replyId,
              'p_post_id': postId,
              'p_device_id': deviceId,
              'p_message': clean,
            },
          ).timeout(AppTimeouts.remote)) as bool?;
      if (ok ?? false) {
        await _updateCachedReplyMessage(postId, replyId, clean);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('ForumRepository updateReplyMessage skipped: $e');
      return false;
    }
  }

  /// Deletes your own post and its replies (fix #4). No time limit.
  /// Device-id-verified RPC only; there is deliberately NO direct-table
  /// fallback (fail closed). Optimistic: restores + false when the delete
  /// fails. Never throws.
  Future<bool> deletePost(String postId) async {
    if (postId.isEmpty) return false;
    if (postId.startsWith('msg-')) {
      return _deleteCachedPost(postId);
    }
    final client = SupabaseConfig.safeClient();
    if (client == null) return false;
    final deviceId = await ReactionIdentity.deviceId();
    if (deviceId.isEmpty) return false;
    try {
      final ok = (await client.rpc(
            'pakikiramay_delete_message',
            params: {'p_id': postId, 'p_device_id': deviceId},
          ).timeout(AppTimeouts.remote)) as bool?;
      if (ok ?? false) {
        await _deleteCachedPost(postId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('ForumRepository deletePost skipped: $e');
      return false;
    }
  }

  /// Deletes your own reply (fix #4). Device-id-verified RPC only; there
  /// is deliberately NO direct-table fallback (fail closed). Never throws.
  Future<bool> deleteReply({
    required String postId,
    required String replyId,
  }) async {
    if (postId.isEmpty || replyId.isEmpty) return false;
    if (replyId.startsWith('reply-') || postId.startsWith('msg-')) {
      return _deleteCachedReply(postId, replyId);
    }
    final client = SupabaseConfig.safeClient();
    if (client == null) return false;
    final deviceId = await ReactionIdentity.deviceId();
    if (deviceId.isEmpty) return false;
    try {
      final ok = (await client.rpc(
            'pakikiramay_delete_reply',
            params: {
              'p_id': replyId,
              'p_post_id': postId,
              'p_device_id': deviceId,
            },
          ).timeout(AppTimeouts.remote)) as bool?;
      if (ok ?? false) {
        await _deleteCachedReply(postId, replyId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('ForumRepository deleteReply skipped: $e');
      return false;
    }
  }

  Future<bool> _updateCachedPostMessage(String postId, String message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userReactions = await _loadUserReactions(prefs);
      final reactionCounts = await _loadReactionCounts(prefs);
      final localReplies = await _loadLocalReplies(prefs);
      final cached = await _loadLocalCache(
        prefs,
        userReactions,
        reactionCounts,
        localReplies,
      );
      final updated = cached
          .map((p) => p.id == postId ? p.copyWith(message: message) : p)
          .toList();
      await _saveLocalCache(prefs, updated);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _updateCachedReplyMessage(
    String postId,
    String replyId,
    String message,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localReplies = await _loadLocalReplies(prefs);
      var changed = false;
      for (final entry in localReplies.entries) {
        for (var i = 0; i < entry.value.length; i++) {
          final r = entry.value[i];
          if (r.id == replyId && (entry.key == postId || r.postId == postId)) {
            entry.value[i] = r.copyWith(message: message);
            changed = true;
          }
        }
      }
      if (!changed) {
        final cached = await _loadLocalCache(
          prefs,
          await _loadUserReactions(prefs),
          await _loadReactionCounts(prefs),
          localReplies,
        );
        final updated = cached.map((p) {
          if (p.id != postId) return p;
          return p.copyWith(
            replies: p.replies
                .map((r) => r.id == replyId ? r.copyWith(message: message) : r)
                .toList(),
          );
        }).toList();
        await _saveLocalCache(prefs, updated);
        return true;
      }
      await _saveLocalReplies(prefs, localReplies);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _deleteCachedPost(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userReactions = await _loadUserReactions(prefs);
      final reactionCounts = await _loadReactionCounts(prefs);
      final localReplies = await _loadLocalReplies(prefs);
      localReplies.remove(postId);
      await _saveLocalReplies(prefs, localReplies);
      final cached = await _loadLocalCache(
        prefs,
        userReactions,
        reactionCounts,
        localReplies,
      );
      await _saveLocalCache(
        prefs,
        cached.where((p) => p.id != postId).toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _deleteCachedReply(String postId, String replyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localReplies = await _loadLocalReplies(prefs);
      var changed = false;
      for (final entry in localReplies.entries) {
        final before = entry.value.length;
        entry.value.removeWhere((r) => r.id == replyId);
        if (entry.value.length != before) changed = true;
      }
      if (changed) await _saveLocalReplies(prefs, localReplies);
      final cached = await _loadLocalCache(
        prefs,
        await _loadUserReactions(prefs),
        await _loadReactionCounts(prefs),
        localReplies,
      );
      await _saveLocalCache(
        prefs,
        cached
            .map(
              (p) => p.id == postId
                  ? p.copyWith(
                      replies: p.replies
                          .where((r) => r.id != replyId)
                          .toList(),
                    )
                  : p,
            )
            .toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
  /// Authoritative remote count for one post/reply, used to reconcile
  /// after our own write (kills echo double-counts). Null when offline
  /// or the table is missing.
  Future<Map<String, int>?> fetchReactionCountFor(String targetId) async {
    if (targetId.isEmpty) return null;
    final client = SupabaseConfig.safeClient();
    if (client == null) return null;
    try {
      // Paginate instead of a hard 2000-row cap so the count stays exact
      // (one target only — typically a single page).
      const pageSize = 1000;
      var from = 0;
      final counts = {'heart': 0};
      while (true) {
        final rows = await client
            .from(reactionsTable)
            .select('reaction_type')
            .eq('target_id', targetId)
            .order('reaction_type')
            .range(from, from + pageSize - 1)
            .timeout(AppTimeouts.remote);
        final list = rows as List;
        for (final row in list) {
          final type = (row['reaction_type'] as String? ?? '').trim();
          if (type.isEmpty) continue;
          counts[type] = (counts[type] ?? 0) + 1;
        }
        if (list.length < pageSize) break;
        from += pageSize;
      }
      return counts;
    } catch (e) {
      debugPrint('ForumRepository fetchReactionCountFor skipped: $e');
      return null;
    }
  }

  /// Parses a Supabase Realtime INSERT payload row into a [ForumPost].
  /// Returns null when the row is not a displayable message.
  ForumPost? parsePostRecord(Map<String, dynamic> record) {
    final id = record['id']?.toString() ?? '';
    final message = (record['message'] as String? ?? '').trim();
    if (id.isEmpty || message.isEmpty) return null;
    final author = (record['name'] as String? ?? '').trim();
    DateTime createdAt = DateTime.now();
    final rawAt = record['created_at'];
    if (rawAt is String) createdAt = DateTime.tryParse(rawAt) ?? DateTime.now();
    return ForumPost(
      id: id,
      authorName: author.isEmpty ? 'Anonymous' : author,
      message: message,
      createdAt: createdAt,
    );
  }

  /// Parses a Supabase Realtime INSERT payload row into a [ForumReply].
  ForumReply? parseReplyRecord(Map<String, dynamic> record) {
    final id = record['id']?.toString() ?? '';
    final postId = record['post_id']?.toString() ?? '';
    final message = (record['message'] as String? ?? '').trim();
    if (id.isEmpty || postId.isEmpty || message.isEmpty) return null;
    final author = (record['author_name'] as String? ?? '').trim();
    DateTime createdAt = DateTime.now();
    final rawAt = record['created_at'];
    if (rawAt is String) createdAt = DateTime.tryParse(rawAt) ?? DateTime.now();
    final remoteReplyTo = (record['reply_to_name'] as String? ??
            record['replyToName'] as String? ??
            '')
        .trim();
    return ForumReply(
      id: id,
      postId: postId,
      authorName: author.isEmpty ? 'Anonymous' : author,
      message: message,
      createdAt: createdAt,
      replyToName: remoteReplyTo.isNotEmpty
          ? remoteReplyTo
          : deriveReplyToFromMention(message),
    );
  }

  /// Parses a reactions-table payload row into (targetId, reactionType,
  /// deviceId). Returns null when the row is malformed. deviceId is ''
  /// for rows written before the owner column existed.
  ({String targetId, String reactionType, String deviceId})?
      parseReactionRecord(
    Map<String, dynamic> record,
  ) {
    final target = record['target_id']?.toString() ?? '';
    final type = (record['reaction_type'] as String? ?? '').trim();
    if (target.isEmpty || type.isEmpty) return null;
    final device = (record['device_id'] as String? ?? '').trim();
    return (targetId: target, reactionType: type, deviceId: device);
  }

  Future<void> _saveLocalCache(
    SharedPreferences prefs,
    List<ForumPost> posts,
  ) async {
    final encoded = jsonEncode(posts.map((p) => p.toJson()).toList());
    await prefs.setString(_cachedPostsKey, encoded);
  }

  Future<List<ForumPost>> _loadLocalCache(
    SharedPreferences prefs,
    Map<String, Set<String>> userReactions,
    Map<String, Map<String, int>> reactionCounts,
    Map<String, List<ForumReply>> localReplies,
  ) async {
    final jsonStr = prefs.getString(_cachedPostsKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(jsonStr) as List<dynamic>;
      return decoded.map((item) {
        final post = ForumPost.fromJson(item as Map<String, dynamic>);
        final postReactions = reactionCounts[post.id] ?? post.reactions;
        final postReplies = [
          ...post.replies,
          ...?localReplies[post.id]?.where((lr) => !post.replies.any((r) => r.id == lr.id)),
        ].map((reply) {
          // Restore local reply-reaction state on top of cached counts.
          if (reactionCounts.containsKey(reply.id) ||
              userReactions.containsKey(reply.id)) {
            return reply.copyWith(
              reactions: reactionCounts[reply.id] ?? reply.reactions,
              userReactions: userReactions[reply.id] ?? reply.userReactions,
            );
          }
          return reply;
        }).toList();

        return post.copyWith(
          reactions: postReactions,
          userReactions: userReactions[post.id] ?? <String>{},
          replies: postReplies,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, Set<String>>> _loadUserReactions(
    SharedPreferences prefs,
  ) async {
    final jsonStr = prefs.getString(_userReactionsKey);
    if (jsonStr == null || jsonStr.isEmpty) return {};
    try {
      final Map<String, dynamic> raw =
          jsonDecode(jsonStr) as Map<String, dynamic>;
      return raw.map((k, v) => MapEntry(k, (v as List).cast<String>().toSet()));
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveUserReactions(
    SharedPreferences prefs,
    Map<String, Set<String>> reactions,
  ) async {
    final mapForJson = reactions.map((k, v) => MapEntry(k, v.toList()));
    await prefs.setString(_userReactionsKey, jsonEncode(mapForJson));
  }

  Future<Map<String, Map<String, int>>> _loadReactionCounts(
    SharedPreferences prefs,
  ) async {
    final jsonStr = prefs.getString(_reactionsMapKey);
    if (jsonStr == null || jsonStr.isEmpty) return {};
    try {
      final Map<String, dynamic> raw =
          jsonDecode(jsonStr) as Map<String, dynamic>;
      return raw.map((k, v) {
        final inner = (v as Map<String, dynamic>).map(
          (ik, iv) => MapEntry(ik, (iv as num).toInt()),
        );
        return MapEntry(k, inner);
      });
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveReactionCounts(
    SharedPreferences prefs,
    Map<String, Map<String, int>> counts,
  ) async {
    await prefs.setString(_reactionsMapKey, jsonEncode(counts));
  }

  Future<Map<String, List<ForumReply>>> _loadLocalReplies(
    SharedPreferences prefs,
  ) async {
    final jsonStr = prefs.getString(_repliesKey);
    if (jsonStr == null || jsonStr.isEmpty) return {};
    try {
      final Map<String, dynamic> raw =
          jsonDecode(jsonStr) as Map<String, dynamic>;
      return raw.map((k, v) {
        final list = (v as List)
            .map((item) => ForumReply.fromJson(item as Map<String, dynamic>))
            .toList();
        return MapEntry(k, list);
      });
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveLocalReplies(
    SharedPreferences prefs,
    Map<String, List<ForumReply>> replies,
  ) async {
    final mapForJson = replies.map(
      (k, v) => MapEntry(k, v.map((r) => r.toJson()).toList()),
    );
    await prefs.setString(_repliesKey, jsonEncode(mapForJson));
  }
}
