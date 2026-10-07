import 'package:flutter/material.dart';
import 'package:nita/data/forum/forum_repository.dart';
import 'package:nita/models/forum_post_model.dart';

/// Controller for the community messages, memories, and condolences board.
class ForumController extends ChangeNotifier {
  final ForumRepository _repository;

  ForumController({ForumRepository repository = const ForumRepository()})
      : _repository = repository {
    loadPosts();
  }

  List<ForumPost> _posts = [];
  bool _loading = false;
  bool _disposed = false;

  List<ForumPost> get posts => _posts;
  bool get loading => _loading;

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
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
