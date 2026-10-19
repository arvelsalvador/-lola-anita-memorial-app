import 'package:flutter/foundation.dart';

/// A reply to a community message. Replies support a heart Like,
/// keyed by reply id in the local reaction stores.
class ForumReply {
  final String id;
  final String postId;
  final String authorName;
  final String message;
  final DateTime createdAt;
  final Map<String, int> reactions; // {'heart': 0}
  final Set<String> userReactions; // reaction types tapped on this device
  /// Name of the person this reply answers. Empty = replies to the post.
  /// Shown as "Tumutugon kay X" so others see the context.
  final String replyToName;
  /// True while this reply only exists locally (its insert failed, e.g.
  /// offline). Kept in the feed across refreshes and retried once per
  /// fetch so the typed text is never silently lost.
  final bool pendingSync;

  const ForumReply({
    required this.id,
    required this.postId,
    required this.authorName,
    required this.message,
    required this.createdAt,
    this.reactions = const {'heart': 0},
    this.userReactions = const {},
    this.replyToName = '',
    this.pendingSync = false,
  });

  ForumReply copyWith({
    String? id,
    String? postId,
    String? authorName,
    String? message,
    DateTime? createdAt,
    Map<String, int>? reactions,
    Set<String>? userReactions,
    String? replyToName,
    bool? pendingSync,
  }) {
    return ForumReply(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorName: authorName ?? this.authorName,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      reactions: reactions ?? this.reactions,
      userReactions: userReactions ?? this.userReactions,
      replyToName: replyToName ?? this.replyToName,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }

  static Map<String, int> _parseReactions(Map<String, dynamic>? raw) {
    return {
      'heart': (raw?['heart'] as num?)?.toInt() ?? 0,
    };
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'post_id': postId,
    'author_name': authorName,
    'message': message,
    'created_at': createdAt.toIso8601String(),
    'reactions': reactions,
    'reply_to_name': replyToName,
    'pending_sync': pendingSync,
  };

  factory ForumReply.fromJson(Map<String, dynamic> json) {
    return ForumReply(
      id: json['id'] as String? ?? UniqueKey().toString(),
      postId: json['post_id'] as String? ?? '',
      authorName: json['author_name'] as String? ?? 'Anonymous',
      message: json['message'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      reactions:
          _parseReactions(json['reactions'] as Map<String, dynamic>?),
      replyToName: json['reply_to_name'] as String? ?? '',
      pendingSync: json['pending_sync'] as bool? ?? false,
    );
  }
}

/// A real community message / condolence / story from the database.
class ForumPost {
  final String id;
  final String authorName;
  final String message;
  final DateTime createdAt;
  final Map<String, int> reactions; // {'heart': 0}
  final Set<String> userReactions;  // reaction types tapped on this device
  final List<ForumReply> replies;
  /// True while this post only exists locally (its insert failed, e.g.
  /// offline). Kept in the feed across refreshes and retried once per
  /// fetch so the typed text is never silently lost.
  final bool pendingSync;

  const ForumPost({
    required this.id,
    required this.authorName,
    required this.message,
    required this.createdAt,
    this.reactions = const {'heart': 0},
    this.userReactions = const {},
    this.replies = const [],
    this.pendingSync = false,
  });

  ForumPost copyWith({
    String? id,
    String? authorName,
    String? message,
    DateTime? createdAt,
    Map<String, int>? reactions,
    Set<String>? userReactions,
    List<ForumReply>? replies,
    bool? pendingSync,
  }) {
    return ForumPost(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      reactions: reactions ?? this.reactions,
      userReactions: userReactions ?? this.userReactions,
      replies: replies ?? this.replies,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'author_name': authorName,
    'message': message,
    'created_at': createdAt.toIso8601String(),
    'reactions': reactions,
    'pending_sync': pendingSync,
    'replies': replies.map((r) => r.toJson()).toList(),
  };

  factory ForumPost.fromJson(Map<String, dynamic> json) {
    final rawReactions = json['reactions'] as Map<String, dynamic>?;
    final Map<String, int> parsedReactions = {
      'heart': (rawReactions?['heart'] as num?)?.toInt() ?? 0,
    };

    final rawReplies = json['replies'] as List<dynamic>? ?? [];
    final parsedReplies = rawReplies
        .map((r) => ForumReply.fromJson(r as Map<String, dynamic>))
        .toList();

    return ForumPost(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      authorName: json['name'] as String? ?? json['author_name'] as String? ?? 'Anonymous',
      message: json['message'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      reactions: parsedReactions,
      pendingSync: json['pending_sync'] as bool? ?? false,
      replies: parsedReplies,
    );
  }
}
