import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nita/controllers/forum_controller.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/data/forum/forum_repository.dart';
import 'package:nita/data/security/reaction_identity.dart';
import 'package:nita/views/condolences/forum/likers_sheet.dart';
import 'package:nita/models/forum_post_model.dart';
import 'package:nita/views/condolences/forum/forum_post_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ForumRepository realtime record parsers', () {
    const repo = ForumRepository();

    test('parsePostRecord accepts valid row, rejects empty message', () {
      final post = repo.parsePostRecord({
        'id': '11111111-1111-1111-1111-111111111111',
        'name': 'Maria',
        'message': 'Pakikiramay po.',
        'created_at': '2026-10-06T10:00:00.000Z',
      });
      expect(post, isNotNull);
      expect(post!.id, '11111111-1111-1111-1111-111111111111');
      expect(post.authorName, 'Maria');

      expect(repo.parsePostRecord({'id': 'x', 'message': '  '}), isNull);
      expect(repo.parsePostRecord({'message': 'hi'}), isNull);
    });

    test('parseReplyRecord accepts valid row, rejects missing post_id', () {
      final reply = repo.parseReplyRecord({
        'id': '22222222-2222-2222-2222-222222222222',
        'post_id': '11111111-1111-1111-1111-111111111111',
        'author_name': 'Pedro',
        'message': 'Salamat.',
        'created_at': '2026-10-06T11:00:00.000Z',
      });
      expect(reply, isNotNull);
      expect(reply!.postId, '11111111-1111-1111-1111-111111111111');

      expect(repo.parseReplyRecord({'id': 'x', 'message': 'hi'}), isNull);
    });

    test('parseReactionRecord accepts valid row', () {
      final parsed = repo.parseReactionRecord({
        'target_id': '11111111-1111-1111-1111-111111111111',
        'reaction_type': 'heart',
      });
      expect(parsed, isNotNull);
      expect(parsed!.targetId, '11111111-1111-1111-1111-111111111111');
      expect(parsed.reactionType, 'heart');

      expect(
        repo.parseReactionRecord({'target_id': '', 'reaction_type': 'heart'}),
        isNull,
      );
    });

    test(
      'fetchReactionCounts returns empty when Supabase uninitialized',
      () async {
        // In tests Supabase is never initialized; must fall back to {}.
        final counts = await repo.fetchReactionCounts();
        expect(counts, isEmpty);
      },
    );

    test(
      'remote writes report false (never throw) when Supabase uninitialized',
      () async {
        expect(
          await repo.addReactionRemote(
            targetId: '11111111-1111-1111-1111-111111111111',
            reactionType: 'heart',
            deviceId: 'dev-test',
          ),
          isFalse,
        );
        expect(
          await repo.removeReactionRemote(
            targetId: '11111111-1111-1111-1111-111111111111',
            reactionType: 'heart',
            deviceId: 'dev-test',
          ),
          isFalse,
        );
        expect(await repo.fetchReactionCountFor('anything'), isNull);
      },
    );

    test('remote writes reject empty device id without throwing', () async {
      expect(
        await repo.addReactionRemote(
          targetId: '11111111-1111-1111-1111-111111111111',
          reactionType: 'heart',
          deviceId: '',
        ),
        isFalse,
      );
      expect(
        await repo.removeReactionRemote(
          targetId: '11111111-1111-1111-1111-111111111111',
          reactionType: 'heart',
          deviceId: '',
        ),
        isFalse,
      );
    });

    test('reaction identity is stable per device', () async {
      ReactionIdentity.debugResetCache();
      final first = await ReactionIdentity.deviceId();
      final second = await ReactionIdentity.deviceId();
      expect(first, isNotEmpty);
      expect(second, first);
    });

    test('parseReactionRecord carries the owner device id', () {
      final parsed = repo.parseReactionRecord({
        'target_id': '11111111-1111-1111-1111-111111111111',
        'reaction_type': 'heart',
        'device_id': 'dev-abc',
      });
      expect(parsed!.deviceId, 'dev-abc');
      // Rows written before the owner column default to ''.
      final legacy = repo.parseReactionRecord({
        'target_id': '11111111-1111-1111-1111-111111111111',
        'reaction_type': 'heart',
      });
      expect(legacy!.deviceId, '');
    });

    test('parsed records default to heart-only reactions', () {
      final post = repo.parsePostRecord({
        'id': 'x',
        'name': 'A',
        'message': 'Hi',
      });
      expect(post!.reactions.keys, ['heart']);

      final reply = repo.parseReplyRecord({
        'id': 'y',
        'post_id': 'x',
        'author_name': 'B',
        'message': 'Hello',
      });
      expect(reply!.reactions.keys, ['heart']);
    });
  });

  group('Enter-to-send composer', () {
    testWidgets('plain Enter sends the reply, Shift+Enter makes a newline', (
      tester,
    ) async {
      var sent = 0;
      final post = ForumPost(
        id: 'post-1',
        authorName: 'Maria',
        message: 'Pakikiramay po.',
        createdAt: DateTime(2026, 10, 6),
      );

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
                  onSendReply: (author, message, replyTo) async {
                    sent++;
                    return null;
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Composer is reply-gated: tap the replies button to open it.
      await tester.tap(find.text('0 replies'));
      await tester.pumpAndSettle();

      final field = find.byType(TextField);
      expect(field, findsOneWidget);
      await tester.tap(field);
      await tester.pump();
      tester.testTextInput.enterText('Hello po');
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(sent, 1);

      // Shift+Enter must not send — it inserts a newline instead.
      tester.testTextInput.enterText('line one');
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pumpAndSettle();
      expect(sent, 1);
    });

    test('rapid Like->Unlike->Like never drifts: ends liked at 1', () async {
      final controller = ForumController();
      final created = await controller.addPost(
        authorName: 'Arvel',
        message: 'oo nga te',
      );
      expect(created, isNotNull);

      // Fired without awaiting — exactly the user's fast-tap scenario.
      final f1 = controller.toggleReaction(created!.id, 'heart');
      final f2 = controller.toggleReaction(created.id, 'heart');
      final f3 = controller.toggleReaction(created.id, 'heart');
      await Future.wait([f1, f2, f3]);

      final post = controller.posts.firstWhere((p) => p.id == created.id);
      // Optimistic taps apply in order: on, off, on.
      expect(post.userReactions.contains('heart'), isTrue);
      expect(post.reactions['heart'], 1);
      controller.dispose();
    });

    test('controller keeps heart count consistent on double toggle', () async {
      final controller = ForumController();
      final created = await controller.addPost(
        authorName: 'Elena',
        message: 'Mahigpit na yakap.',
      );
      expect(created, isNotNull);

      await controller.toggleReaction(created!.id, 'heart');
      await controller.toggleReaction(created.id, 'heart');
      final post = controller.posts.firstWhere((p) => p.id == created.id);
      // Toggled on then off: back to zero, flag cleared.
      expect(post.reactions['heart'], 0);
      expect(post.userReactions.contains('heart'), isFalse);
      controller.dispose();
    });
  });

  group('Likers + Avatars', () {
    test('fetchLikerNames returns empty offline without throwing', () async {
      const repo = ForumRepository();
      expect(await repo.fetchLikerNames('post-1'), isEmpty);
      expect(await repo.fetchLikerNames(''), isEmpty);
      expect(await repo.fetchLikerNames('msg-temp'), isEmpty);
    });

    testWidgets('author avatar renders cleanly without presence dots', (
      tester,
    ) async {
      ForumPost post({required String author}) => ForumPost(
        id: 'post-$author',
        authorName: author,
        message: 'Hi.',
        createdAt: DateTime(2026, 10, 6),
      );
      Future<List<String>> likers(String _) async => <String>[];

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(),
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ForumPostCard(
                  post: post(author: 'Maria'),
                  onViewLikers: likers,
                  onReactionTap: (type) {},
                  onReplyReactionTap: (replyId, type) {},
                  onSendReply: (a, m, r) async {
                    return null;
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No green presence dot is drawn.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).color == const Color(0xFF1F9D55),
        ),
        findsNothing,
      );
      expect(find.text('M'), findsOneWidget);
    });

    testWidgets('likers sheet shows names and empty state', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(),
          child: const MaterialApp(home: Scaffold(body: SizedBox())),
        ),
      );

      LikersSheet.show(
        tester.element(find.byType(SizedBox)),
        loadNames: () async => ['Arvel', 'Maria'],
      );
      await tester.pumpAndSettle();
      expect(find.text('Arvel'), findsOneWidget);
      expect(find.text('Maria'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      LikersSheet.show(
        tester.element(find.byType(SizedBox)),
        loadNames: () async => <String>[],
      );
      await tester.pumpAndSettle();
      expect(find.byType(LikersSheet), findsOneWidget);
    });
  });
}
