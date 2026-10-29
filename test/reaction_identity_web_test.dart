@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nita/data/security/reaction_identity.dart';

/// Regression test for the web-only crash that made every forum write
/// fall back to "Unsent":
///
/// dart2js compiles `1 << 32` to `0`, so the old
/// `Random.secure().nextInt(1 << 32)` threw
/// `RangeError: max must be in range 0 < max <= 2^32, was 0`.
///
/// This test only runs in a real browser (`flutter test --platform chrome`).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('deviceId generates a suffix on web without a RangeError', () async {
    SharedPreferences.setMockInitialValues({});

    final id = await ReactionIdentity.deviceId();

    expect(id, startsWith('dev-'));
    // Format: dev-<timestamp base36>-<random suffix base36>.
    final parts = id.split('-');
    expect(parts.length, greaterThanOrEqualTo(3));
    expect(parts.sublist(2).join('-'), isNotEmpty);
  });

  test('deviceId is stable for the same device', () async {
    SharedPreferences.setMockInitialValues({});

    final first = await ReactionIdentity.deviceId();
    final second = await ReactionIdentity.deviceId();

    expect(second, first);
  });
}
