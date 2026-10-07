import 'package:flutter/foundation.dart';

/// A reply to a community message. Replies support the same four
/// reactions as posts, keyed by reply id in the local reaction stores.
class ForumReply {
  final String id;
  final String postId;
  final String authorName;
  final String message;
  final DateTime createdAt;
  final Map<String, int> reactions; // {'candle': 0, 'dove': 0, 'heart': 0, 'pray': 0}
  final Set<String> userReactions; // reaction types tapped on this device
  /// Name of the person this reply answers. Empty = replies to the post.
  /// Shown as "Tumutugon kay X" so others see the context.
  final String replyToName;

  const ForumReply({
    required this.id,
    required this.postId,
    required this.authorName,
    required this.message,
    required this.createdAt,
    this.reactions = const {'candle': 0, 'dove': 0, 'heart': 0, 'pray': 0},
    this.userReactions = const {},
    this.replyToName = '',
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
    );
  }

  static Map<String, int> _parseReactions(Map<String, dynamic>? raw) {
    return {
      'candle': (raw?['candle'] as num?)?.toInt() ?? 0,
      'dove': (raw?['dove'] as num?)?.toInt() ?? 0,
      'heart': (raw?['heart'] as num?)?.toInt() ?? 0,
      'pray': (raw?['pray'] as num?)?.toInt() ?? 0,
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
    );
  }
}

/// A real community message / condolence / story from the database.
class ForumPost {
  final String id;
  final String authorName;
  final String message;
  final DateTime createdAt;
  final Map<String, int> reactions; // {'candle': 0, 'dove': 0, 'heart': 0, 'pray': 0}
  final Set<String> userReactions;  // reaction types tapped on this device
  final List<ForumReply> replies;

  const ForumPost({
    required this.id,
    required this.authorName,
    required this.message,
    required this.createdAt,
    this.reactions = const {'candle': 0, 'dove': 0, 'heart': 0, 'pray': 0},
    this.userReactions = const {},
    this.replies = const [],
  });

  ForumPost copyWith({
    String? id,
    String? authorName,
    String? message,
    DateTime? createdAt,
    Map<String, int>? reactions,
    Set<String>? userReactions,
    List<ForumReply>? replies,
  }) {
    return ForumPost(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      reactions: reactions ?? this.reactions,
      userReactions: userReactions ?? this.userReactions,
      replies: replies ?? this.replies,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'author_name': authorName,
    'message': message,
    'created_at': createdAt.toIso8601String(),
    'reactions': reactions,
    'replies': replies.map((r) => r.toJson()).toList(),
  };

  factory ForumPost.fromJson(Map<String, dynamic> json) {
    final rawReactions = json['reactions'] as Map<String, dynamic>?;
    final Map<String, int> parsedReactions = {
      'candle': (rawReactions?['candle'] as num?)?.toInt() ?? 0,
      'dove': (rawReactions?['dove'] as num?)?.toInt() ?? 0,
      'heart': (rawReactions?['heart'] as num?)?.toInt() ?? 0,
      'pray': (rawReactions?['pray'] as num?)?.toInt() ?? 0,
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
      replies: parsedReplies,
    );
  }
}
