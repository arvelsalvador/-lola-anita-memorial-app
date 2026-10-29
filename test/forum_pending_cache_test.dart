import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nita/data/forum/forum_repository.dart';
import 'package:nita/models/forum_post_model.dart';

/// Local-cache cleanup for pending forum rows.
///
/// A post/reply typed while the upload failed lives under a temp
/// `msg-...` / `reply-...` id. When the upload finally succeeds, the temp
/// copy must leave the cache or it reappears as a duplicate "Unsent" row.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const repliesKey = 'memorial_local_replies_v1';
  const postsKey = 'memorial_db_posts_cache_v1';

  test('finalizeLocalPost moves pending replies to the real post id',
      () async {
    const tempId = 'msg-1';
    const realId = 'real-1';
    final tempReply = ForumReply(
      id: 'reply-1',
      postId: tempId,
      authorName: 'A',
      message: 'hello',
      createdAt: DateTime(2026, 1, 1),
      pendingSync: true,
    );
    final tempPost = ForumPost(
      id: tempId,
      authorName: 'A',
      message: 'post text',
      createdAt: DateTime(2026, 1, 1),
      pendingSync: true,
      replies: [tempReply],
    );
    SharedPreferences.setMockInitialValues({
      repliesKey: jsonEncode({
        tempId: [tempReply.toJson()],
      }),
      postsKey: jsonEncode([tempPost.toJson()]),
    });

    await const ForumRepository().finalizeLocalPost(tempId, realId);

    final prefs = await SharedPreferences.getInstance();
    final replies =
        jsonDecode(prefs.getString(repliesKey)!) as Map<String, dynamic>;
    expect(replies.containsKey(tempId), isFalse);
    final moved = (replies[realId] as List).single as Map<String, dynamic>;
    expect(moved['id'], 'reply-1');
    expect(moved['post_id'], realId);

    final posts = jsonDecode(prefs.getString(postsKey)!) as List<dynamic>;
    expect(
      posts.any((p) => (p as Map<String, dynamic>)['id'] == tempId),
      isFalse,
    );
  });

  test('removeLocalPost drops the temp post from the cache', () async {
    const tempId = 'msg-2';
    final tempPost = ForumPost(
      id: tempId,
      authorName: 'A',
      message: 'still unsent',
      createdAt: DateTime(2026, 1, 1),
      pendingSync: true,
    );
    SharedPreferences.setMockInitialValues({
      postsKey: jsonEncode([tempPost.toJson()]),
    });

    await const ForumRepository().removeLocalPost(tempId);

    final prefs = await SharedPreferences.getInstance();
    final posts = jsonDecode(prefs.getString(postsKey)!) as List<dynamic>;
    expect(posts, isEmpty);
  });
}
