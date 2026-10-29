import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:nita/core/constants/app_timeouts.dart';
import 'package:nita/core/constants/supabase_config.dart';
import 'package:nita/controllers/forum_pending_sync.dart';
import 'package:nita/data/forum/forum_repository.dart';
import 'package:nita/data/security/own_ids.dart';
import 'package:nita/data/security/reaction_identity.dart';
import 'package:nita/data/security/spam_guard.dart';
import 'package:nita/data/visitors/visitor_repository.dart';
import 'package:nita/models/admin_report_model.dart';
import 'package:nita/models/forum_post_model.dart';

/// Controller for the community messages, memories, and condolences board.
///
/// Live updates: subscribes to Supabase Realtime (`pakikiramay_messages`,
/// `pakikiramay_replies`, `pakikiramay_reactions`) so new posts, replies,
/// edits, and likes appear without refresh. Falls back to one-shot fetch
/// offline.
class ForumController extends ChangeNotifier {
  final ForumRepository _repository;

  ForumController({ForumRepository repository = const ForumRepository()})
      : _repository = repository {
    loadPosts();
    // Fire-and-forget: never blocks construction or tests.
    unawaited(subscribeRealtime());
    unawaited(_loadOwnIds());
  }

  List<ForumPost> _posts = [];
  bool _loading = false;
  bool _loadError = false;
  bool _disposed = false;
  RealtimeChannel? _channel;
  bool _subscribing = false;
  bool _realtimeConnected = false;
  bool _remoteConnected = false;
  // Anonymous owner id of this phone's likes (loaded lazily).
  String _deviceId = '';
  // Display name from the visitor gate (loaded lazily).
  String _visitorName = '';
  // Per-post/reply write queue: taps run instantly on screen, but their
  // server writes run one-after-another per target so an Unlike can
  // never overtake its Like and leak a row.
  final Map<String, Future<void>> _reactionQueues = {};
  // Ids this device already reported (per-device dedupe, survives restart).
  static const String _reportedIdsKey = 'memorial_reported_ids_v1';
  Set<String> _reportedIds = {};
  bool _reportedLoaded = false;
  // Ids of posts/replies created on this device (fix #4: only these
  // show Edit/Delete). Loaded once, kept in memory for sync checks.
  Set<String> _ownPostIds = {};
  Set<String> _ownReplyIds = {};
  bool _ownLoaded = false;
  // Completes once the persisted own-ids load has landed. Adoption waits
  // on it: the load assigns the sets from disk, so a claim made before it
  // finished would be silently overwritten and the post would lose its
  // Edit/Delete rights until the next install.
  final Completer<void> _ownIdsReady = Completer<void>();
  // Fix #3: guards so pending uploads retry once per fetch / resend tap,
  // never looping or double-inserting while a retry is in flight.
  bool _retryingPendingSync = false;

  /// Edit window for your own posts/replies (fix #4).
  static const editWindow = Duration(minutes: 15);

  /// Pure check for the edit window — unit-testable without clocks.
  static bool editableAt(DateTime createdAt, DateTime now) {
    return now.difference(createdAt.toLocal()) <= editWindow;
  }

  List<ForumPost> get posts => _posts;
  bool get loading => _loading;
  bool get loadError => _loadError;
  bool get realtimeConnected => _realtimeConnected;
  bool get isOnline => _remoteConnected || _realtimeConnected;

  /// Display names of who liked [targetId] (post or reply id).
  /// Merges remote names with this device's local like so the sheet never
  /// says empty while the heart count shows > 0 (offline / temp ids).
  Future<List<String>> likerNames(String targetId) async {
    final remote = await _repository.fetchLikerNames(targetId);
    final names = <String>[...remote];
    if (_hasLocalHeart(targetId)) {
      final me = await _localDisplayName();
      if (!names.contains(me)) names.insert(0, me);
    }
    return names;
  }

  bool _hasLocalHeart(String targetId) {
    for (final p in _posts) {
      if (p.id == targetId) return p.userReactions.contains('heart');
      for (final r in p.replies) {
        if (r.id == targetId) return r.userReactions.contains('heart');
      }
    }
    return false;
  }

  /// True when this device already reported [targetId].
  bool isReported(String targetId) => _reportedIds.contains(targetId);

  /// True when [postId] was created on this device (fix #4).
  bool isOwnPost(String postId) => _ownPostIds.contains(postId);

  /// True when [replyId] was created on this device (fix #4).
  bool isOwnReply(String replyId) => _ownReplyIds.contains(replyId);

  /// True when your own post is still inside the edit window.
  bool canEditPost(String postId) {
    if (!isOwnPost(postId)) return false;
    for (final p in _posts) {
      if (p.id == postId) return editableAt(p.createdAt, DateTime.now());
    }
    return false;
  }

  /// True when your own reply is still inside the edit window.
  bool canEditReply(String postId, String replyId) {
    if (!isOwnReply(replyId)) return false;
    for (final p in _posts) {
      if (p.id != postId) continue;
      for (final r in p.replies) {
        if (r.id == replyId) return editableAt(r.createdAt, DateTime.now());
      }
    }
    return false;
  }

  Future<void> _loadOwnIds() async {
    if (_ownLoaded) return;
    _ownLoaded = true;
    try {
      _ownPostIds = await OwnIds.loadPosts();
      _ownReplyIds = await OwnIds.loadReplies();
      if (!_disposed) notifyListeners();
    } catch (_) {
      // Unreadable prefs: keep the empty sets, ownership still works for
      // posts created in this session.
    } finally {
      if (!_ownIdsReady.isCompleted) _ownIdsReady.complete();
    }
  }

  /// One-time backfill: claims loaded posts/replies whose author matches
  /// this device's splash-gate name, so messages made before fix #4 (or
  /// before a reinstall) still get Edit/Delete. Persisted, so a later
  /// gate-name change never un-claims them. Never throws.
  Future<void> _adoptOwnByGateName() async {
    try {
      // Never claim ids before the on-disk load has replaced the sets.
      await _ownIdsReady.future;
      final name = (await _localDisplayName()).trim();
      // _localDisplayName falls back to 'Anonymous' when the gate was
      // never completed — adopting that would claim strangers' posts.
      if (name.isEmpty || name.toLowerCase() == 'anonymous') return;
      final lower = name.toLowerCase();
      var changed = false;
      for (final p in _posts) {
        if (p.authorName.trim().toLowerCase() == lower &&
            _ownPostIds.add(p.id)) {
          changed = true;
          unawaited(OwnIds.addPost(p.id));
        }
        for (final r in p.replies) {
          if (r.authorName.trim().toLowerCase() == lower &&
              _ownReplyIds.add(r.id)) {
            changed = true;
            unawaited(OwnIds.addReply(r.id));
          }
        }
      }
      if (changed && !_disposed) notifyListeners();
    } catch (_) {}
  }

  Future<void> _ensureReportedLoaded() async {
    if (_reportedLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_reportedIdsKey);
      if (raw != null && raw.isNotEmpty) {
        final list = (jsonDecode(raw) as List).map((e) => '$e').toList();
        _reportedIds = list.toSet();
      }
    } catch (_) {}
    _reportedLoaded = true;
  }

  /// Sends a moderation report. Returns [ReportSubmitOutcome.saved] when
  /// stored, [ReportSubmitOutcome.alreadyReported] when this device
  /// already reported it (locally or duplicate row remotely),
  /// [ReportSubmitOutcome.failed] when offline or temp id.
  /// Never throws.
  Future<ReportSubmitOutcome> reportTarget({
    required String targetId,
    required String targetKind,
    required String reason,
    String details = '',
  }) async {
    if (_disposed || targetId.isEmpty || reason.trim().isEmpty) {
      return ReportSubmitOutcome.failed;
    }
    await _ensureReportedLoaded();
    if (_disposed) return ReportSubmitOutcome.failed;
    if (_reportedIds.contains(targetId)) {
      return ReportSubmitOutcome.alreadyReported;
    }
    try {
      if (_deviceId.trim().isEmpty) {
        _deviceId = await ReactionIdentity.deviceId();
      }
    } catch (_) {}
    // Ephemeral fallback so an empty id never blocks or collides.
    if (_deviceId.trim().isEmpty) {
      _deviceId =
          'dev-mem-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
    }
    if (_disposed) return ReportSubmitOutcome.failed;
    final reporterName = await _localDisplayName();
    if (_disposed) return ReportSubmitOutcome.failed;
    final outcome = await _repository.submitReport(
      targetId: targetId,
      targetKind: targetKind,
      reason: reason.trim(),
      details: details,
      deviceId: _deviceId,
      reporterName: reporterName,
    );
    if (_disposed) return outcome;
    if (outcome == ReportSubmitOutcome.failed) return outcome;
    // Both saved + remote-duplicate count as reported locally so the
    // next tap shows "already reported" instead of failing again.
    _reportedIds.add(targetId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _reportedIdsKey, jsonEncode(_reportedIds.toList()));
    } catch (_) {}
    notifyListeners();
    if (outcome == ReportSubmitOutcome.saved) {
      // Spam layer 3: hide immediately once the threshold report lands.
      unawaited(_hideIfThresholdReached(targetId));
    }
    return outcome;
  }

  /// Removes [targetId] from the feed when its report count reaches the
  /// threshold, remembering the hide locally so offline stays hidden.
  Future<void> _hideIfThresholdReached(String targetId) async {
    try {
      final count = await _repository.fetchReportCount(targetId);
      if (count < SpamGuard.hideThreshold || _disposed) return;
      final hidden = await SpamGuard.loadHiddenIds();
      hidden.add(targetId);
      await SpamGuard.saveHiddenIds(hidden);
      if (_disposed) return;
      _removeTargetLocally(targetId);
    } catch (_) {}
  }

  void _removeTargetLocally(String targetId) {
    var changed = false;
    _posts = _posts.where((p) {
      if (p.id == targetId) {
        changed = true;
        return false;
      }
      return true;
    }).toList();
    if (!changed) {
      for (var i = 0; i < _posts.length; i++) {
        final post = _posts[i];
        if (post.replies.any((r) => r.id == targetId)) {
          _posts[i] = post.copyWith(
            replies: post.replies.where((r) => r.id != targetId).toList(),
          );
          changed = true;
          break;
        }
      }
    }
    if (changed && !_disposed) notifyListeners();
  }

  /// Loads real posts from the database / local cache.
  Future<void> loadPosts() async {
    if (_loading || _disposed) return;
    _loading = true;
    _loadError = false;
    notifyListeners();

    try {
      final fetched = await _repository.fetchPosts();
      if (_disposed) return;
      _remoteConnected = _repository.lastFetchSucceededRemotely;
      // Fix #3: merge unsent (pendingSync) posts/replies back in — a
      // successful fetch alone would wipe them silently.
      _posts = ForumPendingSync.merge(_posts, fetched);
      _loadError = false;
      // Fix #4 backfill: posts made before ownership tracking (or on a
      // previous install) are claimed when they match this device's
      // gate name. Skipped for empty/Anonymous names.
      unawaited(_adoptOwnByGateName());
      // Fix #3: one best-effort upload retry per successful fetch.
      unawaited(_retryPendingSyncUploads());
    } catch (e) {
      debugPrint('ForumController.loadPosts error: $e');
      _remoteConnected = false;
      if (!_disposed && _posts.isEmpty) {
        _loadError = true;
      }
    } finally {
      if (!_disposed) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  /// Adds a new real message directly to the database.
  Future<ForumPost?> addPost({
    required String authorName,
    required String message,
  }) async {
    if (_disposed) return null;
    try {
      final post = await _repository.createPost(
        authorName: authorName,
        message: message,
      );
      if (post != null && !_disposed) {
        _posts = [post, ..._posts.where((p) => p.id != post.id)];
        // Fix #3: a surviving temp id means the insert failed — mark it
        // unsent so refreshes keep it and retry the upload.
        if (post.id.startsWith('msg-')) {
          _posts[0] = post.copyWith(pendingSync: true);
        } else {
          _remoteConnected = true;
        }
        _ownPostIds.add(post.id);
        unawaited(OwnIds.addPost(post.id));
        notifyListeners();
      }
      return post;
    } catch (e) {
      debugPrint('ForumController.addPost error: $e');
      return null;
    }
  }

  /// Adds a reply to a message. [replyToName] optionally records who
  /// the reply answers so the thread shows its context.
  Future<ForumReply?> addReply({
    required String postId,
    required String authorName,
    required String message,
    String replyToName = '',
  }) async {
    if (_disposed) return null;
    try {
      final reply = await _repository.addReply(
        postId: postId,
        authorName: authorName,
        message: message,
        replyToName: replyToName,
      );

      if (reply != null && !_disposed) {
        if (!reply.id.startsWith('reply-')) {
          _remoteConnected = true;
        }
        final idx = _posts.indexWhere((p) => p.id == postId);
        if (idx != -1) {
          final target = _posts[idx];
          // Fix #3: a surviving temp id means the insert failed — mark
          // it unsent so refreshes keep it and retry the upload.
          final marked = reply.id.startsWith('reply-')
              ? reply.copyWith(pendingSync: true)
              : reply;
          _posts[idx] = target.copyWith(
            replies: [...target.replies, marked],
          );
          _ownReplyIds.add(reply.id);
          unawaited(OwnIds.addReply(reply.id));
          notifyListeners();
        }
      }
      return reply;
    } catch (e) {
      debugPrint('ForumController.addReply error: $e');
      return null;
    }
  }

  /// Edits your own post's text (fix #4). Only ids in the own-set and
  /// inside [editWindow] are accepted. Optimistic: reverts + false when
  /// the save fails (e.g. missing UPDATE policy). Never throws.
  Future<bool> editPost({
    required String postId,
    required String message,
  }) async {
    if (_disposed || !isOwnPost(postId) || !canEditPost(postId)) return false;
    final clean = message.trim();
    if (clean.isEmpty || clean.length > 1000) return false;
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return false;
    final previous = _posts[idx].message;
    if (previous == clean) return true;
    _posts[idx] = _posts[idx].copyWith(message: clean);
    notifyListeners();
    try {
      final ok = await _repository.updatePostMessage(
        postId: postId,
        message: clean,
      );
      if (!ok && !_disposed) {
        // Re-find by id at revert time: the feed may have changed during
        // the save (realtime insert/delete), so a captured list index
        // could write the old message onto the WRONG post.
        final i = _posts.indexWhere((p) => p.id == postId);
        if (i != -1) {
          _posts[i] = _posts[i].copyWith(message: previous);
          notifyListeners();
        }
      }
      return ok;
    } catch (_) {
      if (!_disposed) {
        final i = _posts.indexWhere((p) => p.id == postId);
        if (i != -1) {
          _posts[i] = _posts[i].copyWith(message: previous);
          notifyListeners();
        }
      }
      return false;
    }
  }

  /// Edits your own reply's text (fix #4). Same rules as [editPost].
  /// Never throws.
  Future<bool> editReply({
    required String postId,
    required String replyId,
    required String message,
  }) async {
    if (_disposed ||
        !isOwnReply(replyId) ||
        !canEditReply(postId, replyId)) {
      return false;
    }
    final clean = message.trim();
    if (clean.isEmpty || clean.length > 1000) return false;
    final postIdx = _posts.indexWhere((p) => p.id == postId);
    if (postIdx == -1) return false;
    final replyIdx =
        _posts[postIdx].replies.indexWhere((r) => r.id == replyId);
    if (replyIdx == -1) return false;
    final previous = _posts[postIdx].replies[replyIdx].message;
    if (previous == clean) return true;
    final updated = List<ForumReply>.from(_posts[postIdx].replies);
    updated[replyIdx] = updated[replyIdx].copyWith(message: clean);
    _posts[postIdx] = _posts[postIdx].copyWith(replies: updated);
    notifyListeners();
    try {
      final ok = await _repository.updateReplyMessage(
        postId: postId,
        replyId: replyId,
        message: clean,
      );
      if (!ok && !_disposed) {
        _revertReplyMessage(postId, replyId, previous);
      }
      return ok;
    } catch (_) {
      if (!_disposed) _revertReplyMessage(postId, replyId, previous);
      return false;
    }
  }

  void _revertReplyMessage(String postId, String replyId, String previous) {
    final postIdx = _posts.indexWhere((p) => p.id == postId);
    if (postIdx == -1) return;
    final replyIdx =
        _posts[postIdx].replies.indexWhere((r) => r.id == replyId);
    if (replyIdx == -1) return;
    final updated = List<ForumReply>.from(_posts[postIdx].replies);
    updated[replyIdx] = updated[replyIdx].copyWith(message: previous);
    _posts[postIdx] = _posts[postIdx].copyWith(replies: updated);
    notifyListeners();
  }

  /// Deletes your own post and its replies (fix #4). No time limit.
  /// Optimistic: restores + false when the delete fails. Never throws.
  Future<bool> deletePost(String postId) async {
    if (_disposed || !isOwnPost(postId)) return false;
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return false;
    final removed = _posts[idx];
    _posts = _posts.where((p) => p.id != postId).toList();
    notifyListeners();
    try {
      final ok = await _repository.deletePost(postId);
      if (_disposed) return ok;
      if (ok) {
        _ownPostIds.remove(postId);
        for (final r in removed.replies) {
          _ownReplyIds.remove(r.id);
          unawaited(OwnIds.removeReply(r.id));
        }
        unawaited(OwnIds.removePost(postId));
      } else {
        _posts = [removed, ..._posts];
        notifyListeners();
      }
      return ok;
    } catch (_) {
      if (!_disposed) {
        _posts = [removed, ..._posts];
        notifyListeners();
      }
      return false;
    }
  }

  /// Deletes your own reply (fix #4). No time limit. Never throws.
  Future<bool> deleteReply({
    required String postId,
    required String replyId,
  }) async {
    if (_disposed || !isOwnReply(replyId)) return false;
    final postIdx = _posts.indexWhere((p) => p.id == postId);
    if (postIdx == -1) return false;
    final replyIdx =
        _posts[postIdx].replies.indexWhere((r) => r.id == replyId);
    if (replyIdx == -1) return false;
    final removed = _posts[postIdx].replies[replyIdx];
    final updated = List<ForumReply>.from(_posts[postIdx].replies)
      ..removeAt(replyIdx);
    _posts[postIdx] = _posts[postIdx].copyWith(replies: updated);
    notifyListeners();
    try {
      final ok = await _repository.deleteReply(
        postId: postId,
        replyId: replyId,
      );
      if (_disposed) return ok;
      if (ok) {
        _ownReplyIds.remove(replyId);
        unawaited(OwnIds.removeReply(replyId));
      } else {
        final i = _posts.indexWhere((p) => p.id == postId);
        if (i != -1) {
          _posts[i] = _posts[i].copyWith(
            replies: [..._posts[i].replies, removed],
          );
          notifyListeners();
        }
      }
      return ok;
    } catch (_) {
      if (!_disposed) {
        final i = _posts.indexWhere((p) => p.id == postId);
        if (i != -1) {
          _posts[i] = _posts[i].copyWith(
            replies: [..._posts[i].replies, removed],
          );
          notifyListeners();
        }
      }
      return false;
    }
  }

  /// Fix #3: one best-effort upload retry for every unsent post and
  /// reply, run after each successful fetch. Never loops — a failed
  /// retry keeps its pendingSync mark and waits for the next fetch.
  /// Never throws.
  Future<void> _retryPendingSyncUploads() async {
    if (_retryingPendingSync || _disposed) return;
    _retryingPendingSync = true;
    try {
      // Posts first: their replies can only upload once the parent has
      // a real id (temp parents are skipped by the repository).
      for (final post in List<ForumPost>.from(_posts)) {
        if (_disposed) return;
        if (!post.pendingSync) continue;
        await _retryPendingPost(post);
      }
      // Replies under real (non-temp) parents.
      for (final post in List<ForumPost>.from(_posts)) {
        if (_disposed) return;
        if (post.id.startsWith('msg-')) continue;
        for (final reply in List<ForumReply>.from(post.replies)) {
          if (_disposed) return;
          if (!reply.pendingSync) continue;
          await _retryPendingReply(post.id, reply);
        }
      }
    } catch (e) {
      debugPrint('ForumController pending retry skipped: $e');
    } finally {
      _retryingPendingSync = false;
    }
  }

  /// Manual retry for an unsent post or reply (the "Unsent · Tap to
  /// retry" cue). When the reply's parent post is itself still unsent,
  /// the parent is retried first — the reply needs a real parent id.
  /// Best-effort: keeps the pendingSync mark when the write fails again.
  /// Never throws.
  Future<void> resendPending(String targetId) async {
    if (_disposed || targetId.isEmpty || _retryingPendingSync) return;
    final postIdx = _posts.indexWhere((p) => p.id == targetId);
    if (postIdx != -1) {
      if (!_posts[postIdx].pendingSync) return;
      _retryingPendingSync = true;
      try {
        await _retryPendingPost(_posts[postIdx]);
      } finally {
        _retryingPendingSync = false;
      }
      return;
    }
    for (var i = 0; i < _posts.length; i++) {
      final replyIdx =
          _posts[i].replies.indexWhere((r) => r.id == targetId);
      if (replyIdx == -1) continue;
      final post = _posts[i];
      final reply = post.replies[replyIdx];
      if (!reply.pendingSync) return;
      _retryingPendingSync = true;
      try {
        if (post.pendingSync) {
          await _retryPendingPost(post);
          // The parent may have just received its real id. Send the
          // reply under it in the same tap instead of making the user
          // tap "retry" a second time.
          final refreshedIdx = _posts.indexWhere(
            (p) => p.replies.any((r) => r.id == reply.id),
          );
          if (refreshedIdx != -1) {
            final refreshed = _posts[refreshedIdx];
            final idx =
                refreshed.replies.indexWhere((r) => r.id == reply.id);
            if (!refreshed.pendingSync &&
                idx != -1 &&
                refreshed.replies[idx].pendingSync) {
              await _retryPendingReply(refreshed.id, refreshed.replies[idx]);
            }
          }
        } else {
          await _retryPendingReply(post.id, reply);
        }
      } finally {
        _retryingPendingSync = false;
      }
      return;
    }
  }

  /// Re-uploads one unsent post. On success swaps the temp id → real id
  /// exactly like the live-echo path does (reactions, replies, and
  /// ownership travel across). Keeps pendingSync on failure. Never
  /// throws.
  Future<void> _retryPendingPost(ForumPost post) async {
    try {
      final saved = await _repository.createPost(
        authorName: post.authorName,
        message: post.message,
      );
      if (_disposed || saved == null) return;
      if (saved.id.startsWith('msg-')) {
        debugPrint(
          'ForumController pending post still unsent (${post.id}).',
        );
        // createPost minted a fresh temp id and cached it. Keep the
        // original pending row as the single copy instead of stacking
        // duplicate "Unsent" posts on every failed retry.
        unawaited(_repository.removeLocalPost(saved.id));
        return;
      }
      final idx = _posts.indexWhere((p) => p.id == post.id);
      if (idx == -1) return; // live echo already swapped it in
      final tempId = _posts[idx].id;
      _posts[idx] = saved.copyWith(
        reactions: _posts[idx].reactions,
        userReactions: _posts[idx].userReactions,
        replies: _posts[idx].replies,
      );
      if (_ownPostIds.remove(tempId)) {
        _ownPostIds.add(saved.id);
        unawaited(OwnIds.migratePost(tempId, saved.id));
      }
      notifyListeners();
      // The temp copy is still in the cache from the failed first
      // attempt. Remove it so a later refresh cannot show a duplicate
      // "Unsent" post next to the delivered one.
      await _repository.finalizeLocalPost(tempId, saved.id);
    } catch (e) {
      debugPrint('ForumController pending post retry skipped: $e');
    }
  }

  /// Re-uploads one unsent reply under the real [postId]. Same swap
  /// semantics as [_retryPendingPost]. Never throws.
  Future<void> _retryPendingReply(String postId, ForumReply reply) async {
    try {
      final saved = await _repository.addReply(
        postId: postId,
        authorName: reply.authorName,
        message: reply.message,
        replyToName: reply.replyToName,
      );
      if (_disposed || saved == null) return;
      if (saved.id.startsWith('reply-')) {
        debugPrint(
          'ForumController pending reply still unsent (${reply.id}).',
        );
        // addReply cached a fresh temp reply. Keep the original pending
        // row as the single copy instead of stacking duplicates.
        unawaited(_repository.removeLocalReply(saved.id));
        return;
      }
      final postIdx = _posts.indexWhere((p) => p.id == postId);
      if (postIdx == -1) return;
      final parent = _posts[postIdx];
      final replyIdx = parent.replies.indexWhere((r) => r.id == reply.id);
      if (replyIdx == -1) return; // live echo already swapped it in
      final updated = List<ForumReply>.from(parent.replies);
      final tempId = updated[replyIdx].id;
      updated[replyIdx] = saved.copyWith(
        replyToName: updated[replyIdx].replyToName,
        reactions: updated[replyIdx].reactions,
        userReactions: updated[replyIdx].userReactions,
      );
      _posts[postIdx] = parent.copyWith(replies: updated);
      if (_ownReplyIds.remove(tempId)) {
        _ownReplyIds.add(saved.id);
        unawaited(OwnIds.migrateReply(tempId, saved.id));
      }
      notifyListeners();
      // The temp copy is still in the local cache from the failed first
      // attempt. Remove it now, otherwise a later refresh re-adds it as a
      // duplicate "Unsent" row next to the delivered reply.
      await _repository.removeLocalReply(tempId);
    } catch (e) {
      debugPrint('ForumController pending reply retry skipped: $e');
    }
  }

  /// Toggles the heart Like with optimistic UI update.
  Future<void> toggleReaction(String postId, String reactionType) async {
    if (_disposed) return;
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final post = _posts[idx];
    // Failure-rollback snapshot (see _revertReactionOptimistic).
    final previousUserReactions = Set<String>.from(post.userReactions);
    final previousCount = post.reactions[reactionType] ?? 0;

    final userReactions = Set<String>.from(post.userReactions);
    final hasReacted = userReactions.contains(reactionType);

    final newReactions = Map<String, int>.from(post.reactions);
    final currentCount = newReactions[reactionType] ?? 0;

    if (hasReacted) {
      userReactions.remove(reactionType);
      newReactions[reactionType] = (currentCount - 1).clamp(0, 99999);
    } else {
      userReactions.add(reactionType);
      newReactions[reactionType] = currentCount + 1;
    }

    _posts[idx] = post.copyWith(
      reactions: newReactions,
      userReactions: userReactions,
    );
    notifyListeners();

    _repository.toggleReaction(
      postId: postId,
      reactionType: reactionType,
    ).catchError((err) {
      debugPrint('Reaction error: $err');
    });
    // Shared counts so other devices see the like live. Queued per
    // target: rapid Like->Unlike->Like runs in tap order, and the
    // authoritative server count reconciles afterwards. A definitive
    // remote write failure rolls the optimistic tap back.
    _enqueueReactionSync(
      postId,
      reactionType,
      liked: !hasReacted,
      previousUserReactions: previousUserReactions,
      previousCount: previousCount,
      optimisticUserReactions: Set<String>.from(userReactions),
      optimisticCount: newReactions[reactionType] ?? 0,
    );
  }

  /// This phone's display name for presence + liker stamps.
  Future<String> _localDisplayName() async {
    if (_visitorName.trim().isNotEmpty) return _visitorName.trim();
    try {
      final name =
          await const VisitorRepository().localName().timeout(AppTimeouts.local);
      _visitorName = (name ?? '').trim();
    } catch (_) {}
    return _visitorName.isEmpty ? 'Anonymous' : _visitorName;
  }

  /// Toggles the heart Like on a reply, with the same optimistic update
  /// pattern as posts. Persisted in the same id-keyed local stores.
  Future<void> toggleReplyReaction(
    String postId,
    String replyId,
    String reactionType,
  ) async {
    if (_disposed) return;
    final postIdx = _posts.indexWhere((p) => p.id == postId);
    if (postIdx == -1) return;

    final post = _posts[postIdx];
    final replyIdx = post.replies.indexWhere((r) => r.id == replyId);
    if (replyIdx == -1) return;

    final reply = post.replies[replyIdx];
    // Failure-rollback snapshot (see _revertReactionOptimistic).
    final previousUserReactions = Set<String>.from(reply.userReactions);
    final previousCount = reply.reactions[reactionType] ?? 0;

    final userReactions = Set<String>.from(reply.userReactions);
    final hasReacted = userReactions.contains(reactionType);

    final newReactions = Map<String, int>.from(reply.reactions);
    final currentCount = newReactions[reactionType] ?? 0;

    if (hasReacted) {
      userReactions.remove(reactionType);
      newReactions[reactionType] = (currentCount - 1).clamp(0, 99999);
    } else {
      userReactions.add(reactionType);
      newReactions[reactionType] = currentCount + 1;
    }

    final updatedReplies = List<ForumReply>.from(post.replies);
    updatedReplies[replyIdx] = reply.copyWith(
      reactions: newReactions,
      userReactions: userReactions,
    );
    _posts[postIdx] = post.copyWith(replies: updatedReplies);
    notifyListeners();

    _repository.toggleReaction(
      postId: replyId,
      reactionType: reactionType,
    ).catchError((err) {
      debugPrint('Reply reaction error: $err');
    });
    _enqueueReactionSync(
      replyId,
      reactionType,
      liked: !hasReacted,
      previousUserReactions: previousUserReactions,
      previousCount: previousCount,
      optimisticUserReactions: Set<String>.from(userReactions),
      optimisticCount: newReactions[reactionType] ?? 0,
    );
  }

  /// Opens the shared Realtime feed. Safe to call twice; subsequent
  /// calls are no-ops while subscribed. Never throws — failures leave
  /// [realtimeConnected] false and the one-shot cache keeps working.
  Future<void> subscribeRealtime() async {
    if (_disposed || _subscribing) return;
    if (_channel != null) {
      if (_realtimeConnected) return;
      await unsubscribeRealtime();
      if (_disposed) return;
    }
    if (!SupabaseConfig.isConfigured) return;
    final client = SupabaseConfig.safeClient();
    if (client == null) return;
    _subscribing = true;
    try {
      _deviceId = await ReactionIdentity.deviceId();
      if (_disposed) return;
      final channel = client.channel('pakikiramay-feed');
      channel
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: ForumRepository.messagesTable,
            callback: (payload) => _handleLivePost(payload.newRecord),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: ForumRepository.repliesTable,
            callback: (payload) => _handleLiveReply(payload.newRecord),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: ForumRepository.messagesTable,
            callback: (payload) =>
                _handleLivePostUpdate(payload.newRecord),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: ForumRepository.repliesTable,
            callback: (payload) =>
                _handleLiveReplyUpdate(payload.newRecord),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: ForumRepository.messagesTable,
            callback: (payload) {
              final id = payload.oldRecord['id']?.toString() ?? '';
              if (id.isNotEmpty) _removeTargetLocally(id);
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: ForumRepository.repliesTable,
            callback: (payload) {
              final id = payload.oldRecord['id']?.toString() ?? '';
              if (id.isNotEmpty) _removeTargetLocally(id);
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: ForumRepository.reactionsTable,
            callback: (payload) {
              final parsed =
                  _repository.parseReactionRecord(payload.newRecord);
              if (parsed != null) {
                if (_isOwnReactionEcho(parsed.deviceId)) {
                  // Our optimistic update already counted it; snap to
                  // the server truth instead of adding again.
                  unawaited(_reconcileReaction(
                      parsed.targetId, parsed.reactionType));
                  return;
                }
                _applyReactionDelta(parsed.targetId, parsed.reactionType, 1);
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: ForumRepository.reactionsTable,
            callback: (payload) {
              final parsed =
                  _repository.parseReactionRecord(payload.oldRecord);
              if (parsed != null) {
                if (_isOwnReactionEcho(parsed.deviceId)) {
                  unawaited(_reconcileReaction(
                      parsed.targetId, parsed.reactionType));
                  return;
                }
                _applyReactionDelta(parsed.targetId, parsed.reactionType, -1);
              }
            },
          )
          .subscribe((status, error) {
        if (_disposed) return;
        _realtimeConnected = status == RealtimeSubscribeStatus.subscribed;
        if (_realtimeConnected) {
          _remoteConnected = true;
        } else if (status == RealtimeSubscribeStatus.channelError ||
            status == RealtimeSubscribeStatus.timedOut ||
            status == RealtimeSubscribeStatus.closed) {
          if (identical(_channel, channel)) {
            _channel = null;
          }
          unawaited(client.removeChannel(channel).catchError((_) => ''));
        }
        if (error != null) {
          debugPrint('ForumController realtime status error: $error');
        }
        notifyListeners();
      });
      _channel = channel;
    } catch (e) {
      debugPrint('ForumController.subscribeRealtime skipped: $e');
      _realtimeConnected = false;
      if (!_disposed) notifyListeners();
    } finally {
      _subscribing = false;
    }
  }

  /// Leaves the shared feed. Safe to call when never subscribed.
  Future<void> unsubscribeRealtime() async {
    final channel = _channel;
    _channel = null;
    _realtimeConnected = false;
    if (channel == null) return;
    try {
      final client = SupabaseConfig.safeClient();
      if (client != null) {
        await client.removeChannel(channel);
      }
    } catch (e) {
      debugPrint('ForumController.unsubscribeRealtime skipped: $e');
    }
    if (!_disposed) notifyListeners();
  }

  void _handleLivePost(Map<String, dynamic> record) {
    if (_disposed) return;
    try {
      final post = _repository.parsePostRecord(record);
      if (post == null) return;
      // Spam layer 2: never render blocked content arriving live.
      if (SpamGuard.containsBlockedWords(post.message)) return;
      if (_posts.any((p) => p.id == post.id)) return; // own echo
      // Replace just-sent temp post (same author+message) with the real row.
      final tempIdx = _posts.indexWhere(
        (p) =>
            (p.id.startsWith('msg-')) &&
            p.authorName == post.authorName &&
            p.message == post.message,
      );
      if (tempIdx != -1) {
        final tempId = _posts[tempIdx].id;
        _posts[tempIdx] = post.copyWith(
          reactions: _posts[tempIdx].reactions,
          userReactions: _posts[tempIdx].userReactions,
          replies: _posts[tempIdx].replies,
        );
        // Fix #4: keep ownership across the temp → real id swap.
        if (_ownPostIds.remove(tempId)) {
          _ownPostIds.add(post.id);
          unawaited(OwnIds.migratePost(tempId, post.id));
        }
        // The real row is live; drop the local temp copy so it cannot
        // come back as a duplicate "Unsent" post after a refresh.
        unawaited(_repository.finalizeLocalPost(tempId, post.id));
      } else {
        _posts = [post, ..._posts];
      }
      notifyListeners();
    } catch (e) {
      debugPrint('ForumController live post skipped: $e');
    }
  }

  void _handleLiveReply(Map<String, dynamic> record) {
    if (_disposed) return;
    try {
      final reply = _repository.parseReplyRecord(record);
      if (reply == null) return;
      // Spam layer 2: never render blocked content arriving live.
      if (SpamGuard.containsBlockedWords(reply.message)) return;
      final postIdx = _posts.indexWhere((p) => p.id == reply.postId);
      if (postIdx == -1) return;
      final post = _posts[postIdx];
      if (post.replies.any((r) => r.id == reply.id)) return; // own echo
      final tempIdx =
          post.replies.indexWhere((r) => r.id.startsWith('reply-') &&
              r.authorName == reply.authorName &&
              r.message == reply.message);
      final updated = List<ForumReply>.from(post.replies);
      if (tempIdx != -1) {
        final tempId = updated[tempIdx].id;
        updated[tempIdx] = reply.copyWith(
          replyToName: updated[tempIdx].replyToName,
          reactions: updated[tempIdx].reactions,
          userReactions: updated[tempIdx].userReactions,
        );
        // Fix #4: keep ownership across the temp → real id swap.
        if (_ownReplyIds.remove(tempId)) {
          _ownReplyIds.add(reply.id);
          unawaited(OwnIds.migrateReply(tempId, reply.id));
        }
        // The real row is live, so the local temp copy is no longer
        // needed; leaving it behind would show a duplicate "Unsent" row
        // after the next refresh.
        unawaited(_repository.removeLocalReply(tempId));
      } else {
        updated.add(reply);
        updated.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      }
      _posts[postIdx] = post.copyWith(replies: updated);
      notifyListeners();
    } catch (e) {
      debugPrint('ForumController live reply skipped: $e');
    }
  }

  void _handleLivePostUpdate(Map<String, dynamic> record) {
    if (_disposed) return;
    try {
      final id = record['id']?.toString() ?? '';
      final message = (record['message'] as String? ?? '').trim();
      if (id.isEmpty || message.isEmpty) return;
      final idx = _posts.indexWhere((p) => p.id == id);
      if (idx == -1) return;
      if (_posts[idx].message == message) return;
      if (SpamGuard.containsBlockedWords(message)) {
        _posts = _posts.where((p) => p.id != id).toList();
      } else {
        final author = (record['name'] as String? ?? '').trim();
        _posts[idx] = _posts[idx].copyWith(
          message: message,
          authorName:
              author.isEmpty ? _posts[idx].authorName : author,
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('ForumController live post update skipped: $e');
    }
  }

  void _handleLiveReplyUpdate(Map<String, dynamic> record) {
    if (_disposed) return;
    try {
      final id = record['id']?.toString() ?? '';
      final message = (record['message'] as String? ?? '').trim();
      if (id.isEmpty || message.isEmpty) return;
      final postId = record['post_id']?.toString() ?? '';
      var postIdx = _posts.indexWhere((p) => p.id == postId);
      if (postIdx == -1) {
        for (var i = 0; i < _posts.length; i++) {
          if (_posts[i].replies.any((r) => r.id == id)) {
            postIdx = i;
            break;
          }
        }
      }
      if (postIdx == -1) return;
      final post = _posts[postIdx];
      final replyIdx = post.replies.indexWhere((r) => r.id == id);
      if (replyIdx == -1) return;
      if (post.replies[replyIdx].message == message) return;
      final updated = List<ForumReply>.from(post.replies);
      if (SpamGuard.containsBlockedWords(message)) {
        updated.removeAt(replyIdx);
      } else {
        final author = (record['author_name'] as String? ?? '').trim();
        updated[replyIdx] = updated[replyIdx].copyWith(
          message: message,
          authorName: author.isEmpty
              ? updated[replyIdx].authorName
              : author,
        );
      }
      _posts[postIdx] = post.copyWith(replies: updated);
      notifyListeners();
    } catch (e) {
      debugPrint('ForumController live reply update skipped: $e');
    }
  }

  /// Queues a server write behind any in-flight write for the same
  /// post/reply, so rapid Like->Unlike->Like runs in tap order and an
  /// Unlike can never overtake its Like and leak a row. When the write
  /// definitively fails, the optimistic tap is rolled back.
  void _enqueueReactionSync(
    String targetId,
    String type, {
    required bool liked,
    required Set<String> previousUserReactions,
    required int previousCount,
    required Set<String> optimisticUserReactions,
    required int optimisticCount,
  }) {
    final prev = _reactionQueues[targetId] ?? Future.value();
    final next = prev.then(
      (_) => _syncReactionRemote(targetId, type, liked: liked),
    );
    _reactionQueues[targetId] = next;
    unawaited(next.then((synced) {
      if (!synced) {
        _revertReactionOptimistic(
          targetId,
          type,
          previousUserReactions: previousUserReactions,
          previousCount: previousCount,
          optimisticUserReactions: optimisticUserReactions,
          optimisticCount: optimisticCount,
        );
      }
      if (_reactionQueues[targetId] == next) {
        _reactionQueues.remove(targetId);
      }
    }));
  }

  /// Rolls back an optimistic like whose remote write failed. Re-finds
  /// the post/reply by id at revert time (the feed may have changed
  /// during the write), and only reverts when the target still shows
  /// this tap's optimistic state — a newer tap's state is never
  /// clobbered.
  void _revertReactionOptimistic(
    String targetId,
    String type, {
    required Set<String> previousUserReactions,
    required int previousCount,
    required Set<String> optimisticUserReactions,
    required int optimisticCount,
  }) {
    if (_disposed || targetId.isEmpty) return;
    final postIdx = _posts.indexWhere((p) => p.id == targetId);
    if (postIdx != -1) {
      final post = _posts[postIdx];
      if (setEquals(post.userReactions, optimisticUserReactions) &&
          (post.reactions[type] ?? 0) == optimisticCount) {
        final next = Map<String, int>.from(post.reactions);
        next[type] = previousCount.clamp(0, 99999);
        _posts[postIdx] = post.copyWith(
          reactions: next,
          userReactions: previousUserReactions,
        );
        notifyListeners();
      }
      return;
    }
    for (var i = 0; i < _posts.length; i++) {
      final post = _posts[i];
      final replyIdx = post.replies.indexWhere((r) => r.id == targetId);
      if (replyIdx == -1) continue;
      final reply = post.replies[replyIdx];
      if (setEquals(reply.userReactions, optimisticUserReactions) &&
          (reply.reactions[type] ?? 0) == optimisticCount) {
        final updated = List<ForumReply>.from(post.replies);
        final next = Map<String, int>.from(reply.reactions);
        next[type] = previousCount.clamp(0, 99999);
        updated[replyIdx] = reply.copyWith(
          reactions: next,
          userReactions: previousUserReactions,
        );
        _posts[i] = post.copyWith(replies: updated);
        notifyListeners();
      }
      return;
    }
  }

  /// Writes our own tap to Supabase, then reconciles with the
  /// authoritative server count. Returns true when the tap was synced
  /// (or nothing remote was needed: temp ids, unconfigured, no device
  /// id — those keep the local heart so taps never flicker away).
  /// Returns false when a real (non-temp) remote write definitively
  /// failed, so the caller rolls the optimistic tap back. Never throws.
  Future<bool> _syncReactionRemote(
    String targetId,
    String type, {
    required bool liked,
  }) async {
    try {
      if (_disposed) return true;
      if (_deviceId.isEmpty) {
        try {
          _deviceId = await ReactionIdentity.deviceId();
        } catch (e) {
          debugPrint(
            'ForumController device id skipped, keeping local like: $e',
          );
          return true;
        }
        if (_disposed) return true;
      }
      // Temp ids don't exist remotely yet — keep the local heart.
      if (targetId.startsWith('msg-') || targetId.startsWith('reply-')) {
        return true;
      }
      if (SupabaseConfig.safeClient() == null) return true;
      final reactorName = await _localDisplayName();
      if (_disposed) return true;
      final ok = liked
          ? await _repository.addReactionRemote(
              targetId: targetId,
              reactionType: type,
              deviceId: _deviceId,
              reactorName: reactorName)
          : await _repository.removeReactionRemote(
              targetId: targetId, reactionType: type, deviceId: _deviceId);
      if (_disposed) return true;
      if (!ok) {
        debugPrint(
          'ForumController reaction write failed '
          '(target=$targetId type=$type liked=$liked) — reverting.',
        );
        return false;
      }
      await _reconcileReaction(targetId, type);
      return true;
    } catch (e) {
      debugPrint('ForumController reaction sync skipped: $e');
      return false;
    }
  }

  /// True when a realtime reaction echo carries our own device id —
  /// our optimistic update already counted it.
  bool _isOwnReactionEcho(String echoDeviceId) {
    return echoDeviceId.isNotEmpty && echoDeviceId == _deviceId;
  }

  Future<void> _reconcileReaction(String targetId, String type) async {
    try {
      final counts = await _repository.fetchReactionCountFor(targetId);
      if (_disposed || counts == null) return;
      _setReactionCount(targetId, type, counts[type] ?? 0);
    } catch (e) {
      debugPrint('ForumController reconcile reaction skipped: $e');
    }
  }

  void _setReactionCount(String targetId, String type, int value) {
    if (_disposed || targetId.isEmpty) return;
    final postIdx = _posts.indexWhere((p) => p.id == targetId);
    if (postIdx != -1) {
      final post = _posts[postIdx];
      final next = Map<String, int>.from(post.reactions);
      next[type] = value.clamp(0, 99999);
      _posts[postIdx] = post.copyWith(reactions: next);
      notifyListeners();
      return;
    }
    for (var i = 0; i < _posts.length; i++) {
      final post = _posts[i];
      final replyIdx = post.replies.indexWhere((r) => r.id == targetId);
      if (replyIdx == -1) continue;
      final updated = List<ForumReply>.from(post.replies);
      final reply = updated[replyIdx];
      final next = Map<String, int>.from(reply.reactions);
      next[type] = value.clamp(0, 99999);
      updated[replyIdx] = reply.copyWith(reactions: next);
      _posts[i] = post.copyWith(replies: updated);
      notifyListeners();
      return;
    }
  }

  void _applyReactionDelta(String targetId, String type, int delta) {
    if (_disposed || targetId.isEmpty || delta == 0) return;
    try {
      final postIdx = _posts.indexWhere((p) => p.id == targetId);
      if (postIdx != -1) {
        final post = _posts[postIdx];
        final next = Map<String, int>.from(post.reactions);
        next[type] = ((next[type] ?? 0) + delta).clamp(0, 99999);
        _posts[postIdx] = post.copyWith(reactions: next);
        notifyListeners();
        return;
      }
      for (var i = 0; i < _posts.length; i++) {
        final post = _posts[i];
        final replyIdx = post.replies.indexWhere((r) => r.id == targetId);
        if (replyIdx == -1) continue;
        final updated = List<ForumReply>.from(post.replies);
        final reply = updated[replyIdx];
        final next = Map<String, int>.from(reply.reactions);
        next[type] = ((next[type] ?? 0) + delta).clamp(0, 99999);
        updated[replyIdx] = reply.copyWith(reactions: next);
        _posts[i] = post.copyWith(replies: updated);
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint('ForumController live reaction skipped: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    final channel = _channel;
    _channel = null;
    if (channel != null) {
      try {
        Supabase.instance.client.removeChannel(channel);
      } catch (_) {}
    }
    super.dispose();
  }
}
