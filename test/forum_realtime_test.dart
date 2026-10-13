import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nita/data/forum/forum_repository.dart';

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

      expect(
        repo.parseReplyRecord({'id': 'x', 'message': 'hi'}),
        isNull,
      );
    });

    test('parseReactionRecord accepts valid row', () {
      final parsed = repo.parseReactionRecord({
        'target_id': '11111111-1111-1111-1111-111111111111',
        'reaction_type': 'heart',
      });
      expect(parsed, isNotNull);
      expect(parsed!.targetId, '11111111-1111-1111-1111-111111111111');
      expect(parsed.reactionType, 'heart');

      expect(repo.parseReactionRecord({'target_id': '', 'reaction_type': 'heart'}), isNull);
    });

    test('fetchReactionCounts returns empty when Supabase uninitialized', () async {
      // In tests Supabase is never initialized; must fall back to {}.
      final counts = await repo.fetchReactionCounts();
      expect(counts, isEmpty);
    });
  });
}
