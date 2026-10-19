import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nita/data/security/spam_guard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SpamGuard blocklist', () {
    test('flags profanity as whole words', () {
      expect(SpamGuard.containsBlockedWords('tangina mo'), isTrue);
      expect(SpamGuard.containsBlockedWords('TANGINA!'), isTrue);
      expect(SpamGuard.containsBlockedWords('visit my casino now'), isTrue);
    });

    test('flags links and money spam', () {
      expect(
        SpamGuard.containsBlockedWords('see https://example.com'),
        isTrue,
      );
      expect(SpamGuard.containsBlockedWords('send gcash here'), isTrue);
      expect(SpamGuard.containsBlockedWords('www.promo-claim now'), isTrue);
    });

    test('passes normal condolences, no false positives', () {
      expect(
        SpamGuard.containsBlockedWords(
          'Taos-pusong pakikiramay sa pamilya.',
        ),
        isFalse,
      );
      // "analala" must not match a substring of a blocked word.
      expect(
        SpamGuard.containsBlockedWords('mga alaala ni nanay'),
        isFalse,
      );
      expect(SpamGuard.containsBlockedWords(''), isFalse);
    });
  });

  group('SpamGuard throttle', () {
    test('posts allow first send, then block for 60s', () async {
      expect(await SpamGuard.secondsUntilNextPost(), 0);
      final start = DateTime.now();
      await SpamGuard.recordPost(start);
      final wait = await SpamGuard.secondsUntilNextPost(start);
      expect(wait, greaterThan(0));
      expect(wait, lessThanOrEqualTo(60));
      final later = start.add(const Duration(seconds: 61));
      expect(await SpamGuard.secondsUntilNextPost(later), 0);
    });

    test('replies allow first send, then block for 20s', () async {
      expect(await SpamGuard.secondsUntilNextReply(), 0);
      final start = DateTime.now();
      await SpamGuard.recordReply(start);
      final wait = await SpamGuard.secondsUntilNextReply(start);
      expect(wait, greaterThan(0));
      expect(wait, lessThanOrEqualTo(20));
      final later = start.add(const Duration(seconds: 21));
      expect(await SpamGuard.secondsUntilNextReply(later), 0);
    });

    test('hidden ids persist across loads', () async {
      expect(await SpamGuard.loadHiddenIds(), isEmpty);
      await SpamGuard.saveHiddenIds({'post-1', 'reply-2'});
      expect(await SpamGuard.loadHiddenIds(), {'post-1', 'reply-2'});
    });
  });
}
