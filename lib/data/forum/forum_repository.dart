import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:nita/core/constants/supabase_config.dart';
import 'package:nita/models/forum_post_model.dart';

/// Public board repository (Field 2) directly connected to Supabase.
///
/// - No fake or hardcoded messages: directly queries the real database (`pakikiramay_messages`).
/// - Private candle messages live separately in `candle_messages` and never appear here.
/// - Real-time insertion & threaded replies.
/// - Offline fallback via SharedPreferences caching so mourners are never blocked.
class ForumRepository {
  const ForumRepository();

  static const String _cachedPostsKey = 'memorial_db_posts_cache_v1';
  static const String _userReactionsKey = 'memorial_user_reactions_v1';
  static const String _reactionsMapKey = 'memorial_reactions_counts_v1';
  static const String _repliesKey = 'memorial_local_replies_v1';

  static const String messagesTable = 'pakikiramay_messages';
  static const String repliesTable = 'pakikiramay_replies';
  static const String reactionsTable = 'pakikiramay_reactions';

  /// Fetches real messages directly from Supabase.
  /// Falls back to local cache if offline or unconfigured.
  Future<List<ForumPost>> fetchPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final userReactions = await _loadUserReactions(prefs);
    final reactionCounts = await _loadReactionCounts(prefs);
    final localReplies = await _loadLocalReplies(prefs);

    if (SupabaseConfig.isConfigured) {
      try {
        final client = Supabase.instance.client;

        // Fetch messages from the database (newest first)
        final rows = await client
            .from(messagesTable)
            .select('id, name, message, created_at')
            .order('created_at', ascending: false)
            .limit(100)
            .timeout(const Duration(seconds: 8));

        // Fetch replies from database if table is available
        Map<String, List<ForumReply>> dbReplies = {};
        // Remote like counts (shared across devices). Empty when the
        // reactions table is missing or offline — local cache wins then.
        Map<String, Map<String, int>> remoteCounts = {};
        try {
          remoteCounts = await fetchReactionCounts();
        } catch (_) {
          remoteCounts = {};
        }
        try {
          final replyRows = await client
              .from(repliesTable)
              .select('id, post_id, author_name, message, created_at')
              .order('created_at', ascending: true)
              .timeout(const Duration(seconds: 5));

          for (final r in (replyRows as List)) {
            final replyId = r['id']?.toString() ?? '';
            var reply = ForumReply(
              id: replyId,
              postId: r['post_id']?.toString() ?? '',
              authorName: r['author_name'] as String? ?? 'Anonymous',
              message: r['message'] as String? ?? '',
              createdAt: r['created_at'] != null
                  ? DateTime.tryParse(r['created_at'] as String) ?? DateTime.now()
                  : DateTime.now(),
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
        } catch (_) {
          // Replies table may be local or unmigrated yet
          dbReplies = localReplies;
        }

        final List<ForumPost> realPosts = [];
        for (final row in (rows as List)) {
          final id = row['id']?.toString() ?? '';
          final author = (row['name'] as String? ?? '').trim();
          final message = (row['message'] as String? ?? '').trim();
          if (message.isEmpty) continue;

          final createdAt = row['created_at'] != null
              ? DateTime.tryParse(row['created_at'] as String) ?? DateTime.now()
              : DateTime.now();

          // Merge replies (from DB or local)
          final postReplies = [
            ...?dbReplies[id],
            ...?localReplies[id]?.where((lr) => !dbReplies.containsKey(id) || !dbReplies[id]!.any((dr) => dr.id == lr.id)),
          ];

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

        // Cache real posts locally
        await _saveLocalCache(prefs, realPosts);
        return realPosts;
      } catch (e) {
        debugPrint('ForumRepository Supabase fetch skipped: $e');
      }
    }

    // Offline / unconfigured: return cached real posts
    return _loadLocalCache(prefs, userReactions, reactionCounts, localReplies);
  }

  /// Inserts a new message directly to Supabase and updates local cache.
  Future<ForumPost?> createPost({
    required String authorName,
    required String message,
  }) async {
    final cleanName = authorName.trim().isEmpty ? 'Anonymous' : authorName.trim();
    final cleanMessage = message.trim();
    if (cleanMessage.isEmpty) return null;

    final tempId = 'msg-${DateTime.now().millisecondsSinceEpoch}';
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

    if (SupabaseConfig.isConfigured) {
      try {
        final client = Supabase.instance.client;
        // Auto-public: new rows are readable instantly because the
        // SELECT policy only allows `approved = true`.
        final res = await client
            .from(messagesTable)
            .insert({
              'name': cleanName,
              'message': cleanMessage,
              'approved': true,
            })
            .select()
            .single()
            .timeout(const Duration(seconds: 8));

        final realId = res['id']?.toString() ?? tempId;
        newPost = newPost.copyWith(id: realId);
      } catch (e) {
        debugPrint('ForumRepository post insert error: $e');
      }
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

  /// Inserts a reply to a message. [replyToName] records who the reply
  /// answers (shown as "Tumutugon kay X"); it is stored locally only —
  /// the remote insert keeps the known columns so no migration is needed.
  Future<ForumReply?> addReply({
    required String postId,
    required String authorName,
    required String message,
    String replyToName = '',
  }) async {
    final cleanName = authorName.trim().isEmpty ? 'Anonymous' : authorName.trim();
    final cleanMessage = message.trim();
    if (cleanMessage.isEmpty) return null;

    final tempId = 'reply-${DateTime.now().millisecondsSinceEpoch}';
    ForumReply newReply = ForumReply(
      id: tempId,
      postId: postId,
      authorName: cleanName,
      message: cleanMessage,
      createdAt: DateTime.now(),
      replyToName: replyToName.trim(),
    );

    // Remote insert uses DB defaults for id/created_at (uuid mismatch fix).
    // Temp parents (msg-...) don't exist remotely — local-only, no FK error.
    final isTempParent =
        postId.startsWith('msg-') || postId.startsWith('reply-');
    if (SupabaseConfig.isConfigured && !isTempParent) {
      try {
        final client = Supabase.instance.client;
        final res = await client
            .from(repliesTable)
            .insert({
              'post_id': postId,
              'author_name': cleanName,
              'message': cleanMessage,
            })
            .select('id, created_at')
            .single()
            .timeout(const Duration(seconds: 8));
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
    if (!SupabaseConfig.isConfigured) return {};
    try {
      final client = Supabase.instance.client;
      final rows = await client
          .from(reactionsTable)
          .select('target_id, reaction_type')
          .limit(2000)
          .timeout(const Duration(seconds: 8));
      final Map<String, Map<String, int>> counts = {};
      for (final row in (rows as List)) {
        final target = row['target_id']?.toString() ?? '';
        final type = (row['reaction_type'] as String? ?? '').trim();
        if (target.isEmpty || type.isEmpty) continue;
        counts.putIfAbsent(target, () => {
              'heart': 0,
            });
        counts[target]![type] = (counts[target]![type] ?? 0) + 1;
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
    if (!SupabaseConfig.isConfigured) return false;
    if (targetId.startsWith('msg-') || targetId.startsWith('reply-')) {
      return false;
    }
    if (targetId.isEmpty || deviceId.isEmpty) return false;
    final trimmed = reactorName.trim();
    final cleanName =
        trimmed.isEmpty ? 'Anonymous' : trimmed.substring(0, trimmed.length > 50 ? 50 : trimmed.length);
    try {
      await Supabase.instance.client.from(reactionsTable).insert({
        'target_id': targetId,
        'reaction_type': reactionType,
        'device_id': deviceId,
        'reactor_name': cleanName,
      }).timeout(const Duration(seconds: 8));
      return true;
    } catch (e) {
      debugPrint('ForumRepository addReactionRemote FAILED: $e');
      return false;
    }
  }

  /// Removes our own remote like (un-like). Scoped to this device's row
  /// so other visitors' likes on the same post are preserved.
  /// Returns true when a row was deleted.
  Future<bool> removeReactionRemote({
    required String targetId,
    required String reactionType,
    required String deviceId,
  }) async {
    if (!SupabaseConfig.isConfigured) return false;
    if (targetId.startsWith('msg-') || targetId.startsWith('reply-')) {
      return false;
    }
    if (targetId.isEmpty || deviceId.isEmpty) return false;
    try {
      final client = Supabase.instance.client;
      final rows = await client
          .from(reactionsTable)
          .select('id')
          .eq('target_id', targetId)
          .eq('reaction_type', reactionType)
          .eq('device_id', deviceId)
          .limit(1)
          .timeout(const Duration(seconds: 8));
      final list = rows as List;
      if (list.isEmpty) return false;
      final rowId = list.first['id']?.toString() ?? '';
      if (rowId.isEmpty) return false;
      await client
          .from(reactionsTable)
          .delete()
          .eq('id', rowId)
          .timeout(const Duration(seconds: 8));
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
    if (!SupabaseConfig.isConfigured || targetId.isEmpty) return [];
    if (targetId.startsWith('msg-') || targetId.startsWith('reply-')) {
      return [];
    }
    try {
      final rows = await Supabase.instance.client
          .from(reactionsTable)
          .select('reactor_name, created_at')
          .eq('target_id', targetId)
          .eq('reaction_type', 'heart')
          .order('created_at', ascending: true)
          .limit(100)
          .timeout(const Duration(seconds: 8));
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

  /// Authoritative remote count for one post/reply, used to reconcile
  /// after our own write (kills echo double-counts). Null when offline
  /// or the table is missing.
  Future<Map<String, int>?> fetchReactionCountFor(String targetId) async {
    if (!SupabaseConfig.isConfigured || targetId.isEmpty) return null;
    try {
      final rows = await Supabase.instance.client
          .from(reactionsTable)
          .select('reaction_type')
          .eq('target_id', targetId)
          .limit(2000)
          .timeout(const Duration(seconds: 8));
      final counts = {'heart': 0};
      for (final row in (rows as List)) {
        final type = (row['reaction_type'] as String? ?? '').trim();
        if (type.isEmpty) continue;
        counts[type] = (counts[type] ?? 0) + 1;
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
    return ForumReply(
      id: id,
      postId: postId,
      authorName: author.isEmpty ? 'Anonymous' : author,
      message: message,
      createdAt: createdAt,
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
