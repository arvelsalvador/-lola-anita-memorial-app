import 'package:flutter_test/flutter_test.dart';

import 'package:nita/controllers/forum_pending_sync.dart';
import 'package:nita/core/utils/forum_format.dart';
import 'package:nita/models/forum_post_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ForumFormat (Fix #3 extraction)', () {
    test('relative: just now / hours / days / fallback', () {
      final now = DateTime.now();
      String hours(int c) => '$c hours ago';
      String days(int c) => '$c days ago';

      expect(
        ForumFormat.relative(
          now,
          fallback: 'X',
          justNow: 'now',
          hoursAgo: hours,
          daysAgo: days,
        ),
        'now',
      );
      expect(
        ForumFormat.relative(
          now.subtract(const Duration(hours: 3)),
          fallback: 'X',
          justNow: 'now',
          hoursAgo: hours,
          daysAgo: days,
        ),
        '3 hours ago',
      );
      expect(
        ForumFormat.relative(
          now.subtract(const Duration(days: 3)),
          fallback: 'X',
          justNow: 'now',
          hoursAgo: hours,
          daysAgo: days,
        ),
        '3 days ago',
      );
      expect(
        ForumFormat.relative(
          now.subtract(const Duration(days: 30)),
          fallback: 'OLD',
          justNow: 'now',
          hoursAgo: hours,
          daysAgo: days,
        ),
        'OLD',
      );
    });

    test('exact + short carry month/day, initials handle names', () {
      String h(int c) => '${c}h';
      String d(int c) => '${c}d';
      final dt = DateTime(2026, 10, 6, 12);
      final exact = ForumFormat.exact(
        dt,
        english: false,
        justNow: 'now',
        hoursAgo: h,
        daysAgo: d,
      );
      expect(exact, contains('Okt 6, 2026'));
      final short = ForumFormat.short(
        dt,
        english: true,
        justNow: 'now',
        hoursAgo: h,
        daysAgo: d,
      );
      expect(short, contains('Oct 6'));

      expect(ForumFormat.initials('Juan Dela Cruz'), 'JD');
      expect(ForumFormat.initials('Maria'), 'M');
      expect(ForumFormat.initials('  '), 'A');
    });
  });

  group('ForumPendingSync.merge (Fix #3 extraction)', () {
    ForumPost post({
      required String id,
      bool pending = false,
      List<ForumReply> replies = const [],
    }) =>
        ForumPost(
          id: id,
          authorName: 'A',
          message: 'm-$id',
          createdAt: DateTime(2026, 1, 1),
          pendingSync: pending,
          replies: replies,
        );

    test('empty previous returns fetched as-is', () {
      final fetched = [post(id: '1')];
      expect(ForumPendingSync.merge([], fetched), fetched);
    });

    test('keeps unsent temp post on top, drops landed duplicate', () {
      final temp = post(id: 'msg-1', pending: true);
      // Landed: same content arrived as a real row -> temp dropped.
      final landed = ForumPost(
        id: 'real-9',
        authorName: 'A',
        message: 'm-msg-1',
        createdAt: DateTime(2026, 1, 2),
      );
      final merged = ForumPendingSync.merge([temp], [landed]);
      expect(merged.map((p) => p.id), ['real-9']);
    });
  });
}
