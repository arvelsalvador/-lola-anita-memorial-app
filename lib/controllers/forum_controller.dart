import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:nita/core/constants/supabase_config.dart';
import 'package:nita/data/forum/forum_repository.dart';
import 'package:nita/models/forum_post_model.dart';

/// Controller for the community messages, memories, and condolences board.
///
/// Live updates: subscribes to Supabase Realtime (`pakikiramay_messages`,
/// `pakikiramay_replies`, `pakikiramay_reactions`) so new posts, replies,
/// and likes appear without refresh. Falls back to one-shot fetch offline.
class ForumController extends ChangeNotifier {
  final ForumRepository _repository;

  ForumController({ForumRepository repository = const ForumRepository()})
      : _repository = repository {
    loadPosts();
    // Fire-and-forget: never blocks construction or tests.
    unawaited(subscribeRealtime());
  }

  List<ForumPost> _posts = [];
  bool _loading = false;
  bool _disposed = false;
  RealtimeChannel? _channel;
  bool _subscribing = false;
  bool _realtimeConnected = false;

  List<ForumPost> get posts => _posts;
  bool get loading => _loading;
  bool get realtimeConnected => _realtimeConnected;

  /// Loads real posts from the database / local cache.
  Future<void> loadPosts() async {
    if (_loading || _disposed) return;
    _loading = true;
    notifyListeners();

    try {
      final fetched = await _repository.fetchPosts();
      if (_disposed) return;
      _posts = fetched;
    } catch (e) {
      debugPrint('ForumController.loadPosts error: $e');
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
        final idx = _posts.indexWhere((p) => p.id == postId);
        if (idx != -1) {
          final target = _posts[idx];
          _posts[idx] = target.copyWith(replies: [...target.replies, reply]);
          notifyListeners();
        }
      }
      return reply;
    } catch (e) {
      debugPrint('ForumController.addReply error: $e');
      return null;
    }
  }

  /// Toggles a reaction (candle, dove, heart, pray) with optimistic UI update.
  Future<void> toggleReaction(String postId, String reactionType) async {
    if (_disposed) return;
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final post = _posts[idx];
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
    // Shared counts so other devices see the like live. Fire-and-forget.
    if (!hasReacted) {
      unawaited(
        _repository.addReactionRemote(
          targetId: postId,
          reactionType: reactionType,
        ),
      );
    } else {
      unawaited(
        _repository.removeReactionRemote(
          targetId: postId,
          reactionType: reactionType,
        ),
      );
    }
  }

  /// Toggles a reaction on a reply, with the same optimistic update
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
    if (!hasReacted) {
      unawaited(
        _repository.addReactionRemote(
          targetId: replyId,
          reactionType: reactionType,
        ),
      );
    } else {
      unawaited(
        _repository.removeReactionRemote(
          targetId: replyId,
          reactionType: reactionType,
        ),
      );
    }
  }

  /// Opens the shared Realtime feed. Safe to call twice; subsequent
  /// calls are no-ops while subscribed. Never throws — failures leave
  /// [realtimeConnected] false and the one-shot cache keeps working.
  Future<void> subscribeRealtime() async {
    if (_disposed || _channel != null || _subscribing) return;
    if (!SupabaseConfig.isConfigured) return;
    _subscribing = true;
    try {
      final client = Supabase.instance.client;
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
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: ForumRepository.reactionsTable,
            callback: (payload) {
              final parsed =
                  _repository.parseReactionRecord(payload.newRecord);
              if (parsed != null) {
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
                _applyReactionDelta(parsed.targetId, parsed.reactionType, -1);
              }
            },
          )
          .subscribe((status, error) {
        if (_disposed) return;
        _realtimeConnected = status == RealtimeSubscribeStatus.subscribed;
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
      await Supabase.instance.client.removeChannel(channel);
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
      if (_posts.any((p) => p.id == post.id)) return; // own echo
      // Replace just-sent temp post (same author+message) with the real row.
      final tempIdx = _posts.indexWhere(
        (p) =>
            (p.id.startsWith('msg-')) &&
            p.authorName == post.authorName &&
            p.message == post.message,
      );
      if (tempIdx != -1) {
        _posts[tempIdx] = post.copyWith(
          reactions: _posts[tempIdx].reactions,
          userReactions: _posts[tempIdx].userReactions,
          replies: _posts[tempIdx].replies,
        );
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
        updated[tempIdx] = reply.copyWith(
          replyToName: updated[tempIdx].replyToName,
          reactions: updated[tempIdx].reactions,
          userReactions: updated[tempIdx].userReactions,
        );
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
