import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/models/forum_post_model.dart';
import 'package:nita/views/condolences/forum/forum_post_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ForumPost postWithReplies(List<String> messages) {
    return ForumPost(
      id: 'post-preview',
      authorName: 'Maria',
      message: 'Pakikiramay po.',
      createdAt: DateTime(2026, 10, 6),
      replies: [
        for (var i = 0; i < messages.length; i++)
          ForumReply(
            id: 'reply-$i',
            postId: 'post-preview',
            authorName: 'User $i',
            message: messages[i],
            createdAt: DateTime(2026, 10, 6, 10, i),
          ),
      ],
    );
  }

  Future<void> pumpCard(WidgetTester tester, ForumPost post) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LanguageProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ForumPostCard(
                post: post,
                onViewLikers: (targetId) async => <String>[],
                onReactionTap: (type) {},
                onReplyReactionTap: (replyId, type) {},
                onSendReply: (author, message, replyTo) async => null,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Replies preview (fix #3)', () {
    testWidgets('collapsed post previews first 2 of 3 replies', (
      tester,
    ) async {
      await pumpCard(
        tester,
        postWithReplies(['oldest reply', 'middle reply', 'newest reply']),
      );

      // Preview shows the oldest two without any tap.
      expect(find.text('oldest reply'), findsOneWidget);
      expect(find.text('middle reply'), findsOneWidget);
      expect(find.text('newest reply'), findsNothing);
      // "See more" with no count.
      expect(find.text('See more'), findsOneWidget);
      // Reading-only expand: no composer keyboard forced open.
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('preview prefers top-level over reply-to-reply', (
      tester,
    ) async {
      final post = ForumPost(
        id: 'post-preview',
        authorName: 'Maria',
        message: 'Pakikiramay po.',
        createdAt: DateTime(2026, 10, 6),
        replies: [
          ForumReply(
            id: 'reply-0',
            postId: 'post-preview',
            authorName: 'User 0',
            message: 'first top reply',
            createdAt: DateTime(2026, 10, 6, 10, 0),
          ),
          ForumReply(
            id: 'reply-1',
            postId: 'post-preview',
            authorName: 'User 1',
            message: '@User 0 nested reply',
            replyToName: 'User 0',
            createdAt: DateTime(2026, 10, 6, 10, 1),
          ),
          ForumReply(
            id: 'reply-2',
            postId: 'post-preview',
            authorName: 'User 2',
            message: 'second top reply',
            createdAt: DateTime(2026, 10, 6, 10, 2),
          ),
          ForumReply(
            id: 'reply-3',
            postId: 'post-preview',
            authorName: 'User 3',
            message: '@User 2 another nested',
            replyToName: 'User 2',
            createdAt: DateTime(2026, 10, 6, 10, 3),
          ),
        ],
      );
      await pumpCard(tester, post);

      expect(find.text('first top reply'), findsOneWidget);
      expect(find.text('second top reply'), findsOneWidget);
      expect(find.text('@User 0', findRichText: true), findsNothing);
      expect(find.text('@User 2', findRichText: true), findsNothing);
      expect(find.text('See more'), findsOneWidget);
    });

    testWidgets('show-more expands all without opening composer', (
      tester,
    ) async {
      await pumpCard(
        tester,
        postWithReplies(['oldest reply', 'middle reply', 'newest reply']),
      );

      await tester.tap(find.text('See more'));
      await tester.pumpAndSettle();

      expect(find.text('oldest reply'), findsOneWidget);
      expect(find.text('middle reply'), findsOneWidget);
      expect(find.text('newest reply'), findsOneWidget);
      expect(find.text('See more'), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('1-2 replies show fully with no show-more button', (
      tester,
    ) async {
      await pumpCard(tester, postWithReplies(['only reply']));
      expect(find.text('only reply'), findsOneWidget);
      expect(find.text('See more'), findsNothing);

      await pumpCard(tester, postWithReplies(['reply one', 'reply two']));
      expect(find.text('reply one'), findsOneWidget);
      expect(find.text('reply two'), findsOneWidget);
      expect(find.text('See more'), findsNothing);
    });

    testWidgets('reply menu sits at the trailing edge', (
      tester,
    ) async {
      await pumpCard(tester, postWithReplies(['only reply']));
      final cardRight = tester.getRect(find.byType(ForumPostCard)).right;
      // First menu is the post's, last is the reply's.
      final menuRight =
          tester.getRect(find.byType(PopupMenuButton<String>).last).right;
      // Card content padding is 14 — menu must end exactly there.
      expect(menuRight, moreOrLessEquals(cardRight - 14, epsilon: 1.0));
    });

    testWidgets('reply menu opens full-width with its items', (
      tester,
    ) async {
      await pumpCard(tester, postWithReplies(['only reply']));
      // Last kebab is the reply's.
      await tester.tap(find.byIcon(Icons.more_vert_rounded).last);
      await tester.pumpAndSettle();
      // Menu item labels render (post pill + open menu item).
      expect(find.text('Report'), findsNWidgets(2));
      expect(find.text('Copy text'), findsOneWidget);
      // The open item must not be crushed into a narrow box.
      final itemWidth =
          tester.getRect(find.text('Report').last).width;
      expect(itemWidth, greaterThan(40));
    });
  });
}
