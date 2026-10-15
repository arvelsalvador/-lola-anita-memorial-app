import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nita/controllers/forum_controller.dart';
import 'package:nita/data/forum/forum_repository.dart';
import 'package:nita/data/forum/own_ids.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OwnIds store', () {
    test('remembers, checks, and forgets ids', () async {
      expect(await OwnIds.loadPosts(), isEmpty);
      await OwnIds.addPost('post-1');
      expect(await OwnIds.loadPosts(), {'post-1'});
      await OwnIds.addPost('post-1');
      expect((await OwnIds.loadPosts()).length, 1);
      await OwnIds.removePost('post-1');
      expect(await OwnIds.loadPosts(), isEmpty);

      expect(await OwnIds.loadReplies(), isEmpty);
      await OwnIds.addReply('reply-1');
      expect(await OwnIds.loadReplies(), {'reply-1'});
      await OwnIds.removeReply('reply-1');
      expect(await OwnIds.loadReplies(), isEmpty);
    });

    test('migrates temp ids to real ids', () async {
      await OwnIds.addPost('msg-1');
      await OwnIds.migratePost('msg-1', 'real-1');
      expect(await OwnIds.loadPosts(), {'real-1'});

      await OwnIds.addReply('reply-temp');
      await OwnIds.migrateReply('reply-temp', 'reply-real');
      expect(await OwnIds.loadReplies(), {'reply-real'});
    });

    test('ignores empty ids and no-op migrations', () async {
      await OwnIds.addPost('');
      await OwnIds.addReply('');
      expect(await OwnIds.loadPosts(), isEmpty);
      expect(await OwnIds.loadReplies(), isEmpty);
      await OwnIds.migratePost('', 'x');
      await OwnIds.migratePost('x', 'x');
      expect(await OwnIds.loadPosts(), isEmpty);
    });
  });

  group('ForumController edit window', () {
    test('editableAt allows 15 minutes', () {
      final now = DateTime(2026, 10, 14, 12, 0);
      expect(
        ForumController.editableAt(
          DateTime(2026, 10, 14, 11, 50),
          now,
        ),
        isTrue,
      );
      expect(
        ForumController.editableAt(
          DateTime(2026, 10, 14, 11, 44),
          now,
        ),
        isFalse,
      );
    });

    test('edit and delete only your own posts', () async {
      final controller = ForumController();
      final post = await controller.addPost(
        authorName: 'Arvel',
        message: 'Original message.',
      );
      expect(post, isNotNull);
      expect(controller.isOwnPost(post!.id), isTrue);
      expect(controller.isOwnPost('someone-else'), isFalse);

      expect(
        await controller.editPost(postId: post.id, message: 'Edited.'),
        isTrue,
      );
      expect(controller.posts.first.message, 'Edited.');
      expect(
        await controller.editPost(postId: post.id, message: '  '),
        isFalse,
      );
      expect(
        await controller.editPost(postId: 'someone-else', message: 'Hi.'),
        isFalse,
      );

      expect(await controller.deletePost('someone-else'), isFalse);
      expect(await controller.deletePost(post.id), isTrue);
      expect(controller.posts, isEmpty);
      expect(controller.isOwnPost(post.id), isFalse);
      controller.dispose();
    });

    test('edit and delete only your own replies', () async {
      final controller = ForumController();
      final post = await controller.addPost(
        authorName: 'Arvel',
        message: 'Post.',
      );
      expect(post, isNotNull);
      final reply = await controller.addReply(
        postId: post!.id,
        authorName: 'Arvel',
        message: 'Reply.',
      );
      expect(reply, isNotNull);
      expect(controller.isOwnReply(reply!.id), isTrue);

      expect(
        await controller.editReply(
          postId: post.id,
          replyId: reply.id,
          message: 'Edited reply.',
        ),
        isTrue,
      );
      expect(controller.posts.first.replies.first.message, 'Edited reply.');
      expect(
        await controller.editReply(
          postId: post.id,
          replyId: 'other-reply',
          message: 'Hi.',
        ),
        isFalse,
      );

      expect(
        await controller.deleteReply(
          postId: post.id,
          replyId: reply.id,
        ),
        isTrue,
      );
      expect(controller.posts.first.replies, isEmpty);
      controller.dispose();
    });

    test('adopts pre-existing posts matching the gate name', () async {
      SharedPreferences.setMockInitialValues({'visitor_name': 'Mina'});
      const repo = ForumRepository();
      final old = await repo.createPost(
        authorName: 'Mina',
        message: 'Old post from before tracking.',
      );
      final stranger = await repo.createPost(
        authorName: 'Stranger',
        message: 'Not mine.',
      );
      final anon = await repo.createPost(
        authorName: 'Anonymous',
        message: 'Nobody in particular.',
      );
      expect(old, isNotNull);
      expect(stranger, isNotNull);
      expect(anon, isNotNull);

      final controller = ForumController();
      var tries = 0;
      while (!controller.isOwnPost(old!.id) && tries < 300) {
        await Future.delayed(const Duration(milliseconds: 10));
        tries++;
      }
      expect(controller.isOwnPost(old.id), isTrue);
      expect(controller.isOwnPost(stranger!.id), isFalse);
      expect(controller.isOwnPost(anon!.id), isFalse);
      controller.dispose();
    });

    test('adopts nothing without a gate name', () async {
      SharedPreferences.setMockInitialValues({});
      const repo = ForumRepository();
      final anon = await repo.createPost(
        authorName: 'Anonymous',
        message: 'Nobody in particular.',
      );
      expect(anon, isNotNull);

      final controller = ForumController();
      while (controller.loading) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
      await Future.delayed(const Duration(milliseconds: 100));
      expect(controller.isOwnPost(anon!.id), isFalse);
      controller.dispose();
    });
  });
}
