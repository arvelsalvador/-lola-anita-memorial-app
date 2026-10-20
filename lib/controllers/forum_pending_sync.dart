import 'package:nita/models/forum_post_model.dart';

/// Pure pending-sync merge for the forum feed.
///
/// Fix #3: keeps unsent (pendingSync) posts and replies from the previous
/// feed inside the freshly fetched list, so a successful refresh never
/// silently deletes the user's text. A temp post whose exact content
/// already landed as a real row is dropped instead (the live echo swapped
/// it in). Pure list shaping — no writes, no notifiers. Unit-testable.
class ForumPendingSync {
  ForumPendingSync._();

  static List<ForumPost> merge(
    List<ForumPost> previous,
    List<ForumPost> fetched,
  ) {
    if (previous.isEmpty) return fetched;
    final kept = List<ForumPost>.from(fetched);
    final pendingPosts = <ForumPost>[];
    for (final old in previous) {
      if (!old.pendingSync) continue;
      final landed = fetched.any(
        (p) =>
            !p.id.startsWith('msg-') &&
            p.authorName == old.authorName &&
            p.message == old.message,
      );
      if (landed) continue;
      pendingPosts.add(old);
    }
    if (pendingPosts.isNotEmpty) {
      kept.removeWhere((p) => pendingPosts.any((pp) => pp.id == p.id));
      kept.insertAll(0, pendingPosts);
    }
    // Unsent replies: re-attach the ones the fetch dropped, and restore
    // the unsent mark when the repository cache re-materialized the same
    // temp reply without it.
    final oldById = <String, ForumPost>{
      for (final p in previous) p.id: p,
    };
    return kept.map((p) {
      final oldPost = oldById[p.id];
      if (oldPost == null) return p;
      var changed = false;
      final replies = <ForumReply>[];
      for (final r in p.replies) {
        ForumReply? oldReply;
        for (final o in oldPost.replies) {
          if (o.id == r.id) {
            oldReply = o;
            break;
          }
        }
        if (oldReply != null && oldReply.pendingSync && !r.pendingSync) {
          replies.add(r.copyWith(pendingSync: true));
          changed = true;
        } else {
          replies.add(r);
        }
      }
      for (final r in oldPost.replies) {
        if (!r.pendingSync) continue;
        final exists = replies.any(
          (nr) =>
              nr.id == r.id ||
              (!nr.id.startsWith('reply-') &&
                  nr.authorName == r.authorName &&
                  nr.message == r.message),
        );
        if (exists) continue;
        replies.add(r);
        changed = true;
      }
      if (!changed) return p;
      replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return p.copyWith(replies: replies);
    }).toList();
  }
}
