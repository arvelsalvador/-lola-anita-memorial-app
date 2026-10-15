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

  Future<void> pumpCard(
    WidgetTester tester, {
    bool isPostOwn = false,
    bool canEditPost = false,
    Future<bool> Function()? onDeletePost,
  }) async {
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
                onSendReply: (author, message, replyTo) async => null,
                isPostOwn: isPostOwn,
                canEditPost: canEditPost,
                onDeletePost: onDeletePost ?? () async => true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openPostMenu(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
  }

  group('Own post menu (fix #4)', () {
    testWidgets('own post shows Edit and Delete, no Report', (
      tester,
    ) async {
      await pumpCard(tester, isPostOwn: true, canEditPost: true);
      await openPostMenu(tester);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsWidgets);
      expect(find.text('Report'), findsNothing);
    });

    testWidgets('own post past the edit window shows Delete only', (
      tester,
    ) async {
      await pumpCard(tester, isPostOwn: true, canEditPost: false);
      await openPostMenu(tester);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Delete'), findsWidgets);
    });

    testWidgets('other visitor post shows Report, no edit or delete', (
      tester,
    ) async {
      await pumpCard(tester);
      await openPostMenu(tester);
      // Pill + menu item.
      expect(find.text('Report'), findsNWidgets(2));
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('failed delete shows a note instead of silent return', (
      tester,
    ) async {
      await pumpCard(
        tester,
        isPostOwn: true,
        canEditPost: false,
        onDeletePost: () async => false,
      );
      await openPostMenu(tester);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      // Confirm dialog.
      expect(
        find.text('Burahin ang mensaheng ito? Hindi na ito maibabalik.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(
        find.text('Hindi nabura. Tingnan ang connection at subukan ulit.'),
        findsOneWidget,
      );
    });
  });
}
