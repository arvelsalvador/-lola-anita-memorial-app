import 'package:flutter_test/flutter_test.dart';
import 'package:nita/controllers/condolences_controller.dart';

void main() {
  test('displayCount falls back to 124 seed before remote loads', () {
    final c = CondolencesController();
    expect(c.displayCount, 124);
    expect(c.recentNames, isNull);
    expect(c.listLoading, isFalse);
    c.dispose();
  });

  test('applyRemote switches count to shared number + names list', () {
    final c = CondolencesController();
    c.applyRemote(count: 200, names: ['Arvel', 'Hanna']);
    expect(c.displayCount, 200);
    expect(c.recentNames, ['Arvel', 'Hanna']);
    expect(c.listLoading, isFalse);
    c.dispose();
  });

  test('offline snapshot (nulls) keeps seed and hides list', () async {
    final c = CondolencesController();
    await c.lightCandle();
    // Local light still bumps the seed even when remote is unreachable.
    expect(c.displayCount, 125);
    c.applyRemote(count: null, names: null);
    expect(c.displayCount, 125);
    expect(c.recentNames, isNull);
    c.dispose();
  });

  test('noteOwnLight adds own name optimistically when online', () {
    final c = CondolencesController();
    c.applyRemote(count: 200, names: ['Hanna']);
    c.noteOwnLight('Arvel');
    expect(c.displayCount, 201);
    expect(c.recentNames!.first, 'Arvel');
    c.dispose();
  });

  test('noteOwnLight keeps offline hidden (null list stays null)', () {
    final c = CondolencesController();
    c.noteOwnLight('Arvel');
    expect(c.recentNames, isNull);
    c.dispose();
  });

  test('lit-during-load race: stale 0/[] cannot erase own candle', () async {
    final c = CondolencesController();
    await c.lightCandle();
    c.noteOwnLight('Vianca');
    // Slow initial fetch arrives AFTER lighting with an empty table.
    c.applyRemote(count: 0, names: []);
    expect(c.displayCount, 1);
    expect(c.recentNames, ['Vianca']);
    c.dispose();
  });

  test('overlay never duplicates a name the server already has', () {
    final c = CondolencesController();
    c.applyRemote(count: 200, names: ['Hanna']);
    c.noteOwnLight('Arvel');
    // Server snapshot already includes us (e.g. second refresh).
    c.applyRemote(count: 201, names: ['Arvel', 'Hanna']);
    expect(
      c.recentNames!.where((n) => n == 'Arvel').length,
      1,
    );
    c.dispose();
  });

  test('post-save refresh clears pending so later snapshots stay true',
      () async {
    final c = CondolencesController();
    await c.lightCandle();
    c.noteOwnLight('Vianca');
    // Post-save refresh: server truth includes us, pending cleared.
    c.applyRemote(count: 1, names: ['Vianca'], markSynced: true);
    expect(c.displayCount, 1);
    // A later stale snapshot no longer gets +1 overlaid.
    c.applyRemote(count: 1, names: ['Vianca']);
    expect(c.displayCount, 1);
    expect(
      c.recentNames!.where((n) => n == 'Vianca').length,
      1,
    );
    c.dispose();
  });
}
