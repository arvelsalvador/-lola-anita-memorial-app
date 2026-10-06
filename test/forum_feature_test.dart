import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nita/controllers/forum_controller.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/data/forum/forum_repository.dart';
import 'package:nita/models/forum_post_model.dart';
import 'package:nita/views/condolences/forum/community_forum_section.dart';
import 'package:nita/views/condolences/forum/forum_post_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ForumRepository & Controller Tests', () {
    test('creates new post and persists locally', () async {
      final repo = const ForumRepository();
      final post = await repo.createPost(
        authorName: 'Juan Dela Cruz',
        message: 'Isang taos-pusong pakikiramay para sa pamilya.',
      );

      expect(post, isNotNull);
      expect(post!.authorName, 'Juan Dela Cruz');
      expect(post.message, contains('pakikiramay'));

      final allPosts = await repo.fetchPosts();
      expect(allPosts.any((p) => p.authorName == 'Juan Dela Cruz'), isTrue);
    });

    test('adds reply to post', () async {
      final repo = const ForumRepository();
      final post = await repo.createPost(
        authorName: 'Maria',
        message: 'Pakikiramay po.',
      );

      expect(post, isNotNull);

      final reply = await repo.addReply(
        postId: post!.id,
        authorName: 'Pedro',
        message: 'Salamat sa pakikiramay.',
      );

      expect(reply, isNotNull);
      expect(reply!.postId, post.id);
      final allPosts = await repo.fetchPosts();
      final updatedPost = allPosts.firstWhere((p) => p.id == post.id);
      expect(updatedPost.replies.length, 1);
      expect(updatedPost.replies.first.message, 'Salamat sa pakikiramay.');
    });

    test('controller optimistic reactions', () async {
      final controller = ForumController();
      final post = await controller.addPost(
        authorName: 'Elena',
        message: 'Mahigpit na yakap sa buong pamilya.',
      );

      expect(post, isNotNull);
      expect(controller.posts, isNotEmpty);

      final firstPost = controller.posts.first;
      final initialCandles = firstPost.reactions['candle'] ?? 0;

      await controller.toggleReaction(firstPost.id, 'candle');
      final updatedFirstPost = controller.posts.firstWhere((p) => p.id == firstPost.id);
      expect(updatedFirstPost.reactions['candle'], initialCandles + 1);
      expect(updatedFirstPost.userReactions.contains('candle'), isTrue);
    });
  });

  group('CommunityForumSection Widget Tests', () {
    testWidgets('renders forum section and post cards', (tester) async {
      final controller = ForumController();
      await controller.addPost(
        authorName: 'Maria Clara',
        message: 'Napakabuting tao ni Nanay Nita.',
      );

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(),
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CommunityForumSection(forumController: controller),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CommunityForumSection), findsOneWidget);
      expect(find.byType(ForumPostCard), findsOneWidget);
      expect(find.text('Maria Clara'), findsOneWidget);
    });
  });
}
