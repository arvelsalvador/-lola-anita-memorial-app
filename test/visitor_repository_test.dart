import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nita/data/visitors/visitor_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('fresh device has no visitor', () async {
    const repo = VisitorRepository();
    expect(await repo.hasVisitor(), isFalse);
  });

  test('saveVisitor remembers, clearVisitor forgets', () async {
    const repo = VisitorRepository();

    // Supabase is unconfigured in tests, so remote save is skipped —
    // local remember-me is what matters here.
    await repo.saveVisitor(
      name: 'Test Visitor',
      address: 'Purok 3, Mercedes, Camarines Norte',
    );
    expect(await repo.hasVisitor(), isTrue);
    expect(await repo.localName(), 'Test Visitor');

    await repo.clearVisitor();
    expect(await repo.hasVisitor(), isFalse);
  });

  test('fetchVisitorCount/fetchVisitorNames return null offline, never throw',
      () async {
    const repo = VisitorRepository();
    // Supabase is uninitialized in tests: null = offline, list hides.
    expect(await repo.fetchVisitorCount(), isNull);
    expect(await repo.fetchVisitorNames(), isNull);
  });

  test('validateAddress rejects empty and too-short input', () {
    expect(VisitorRepository.validateAddress(''), 'visitor_address_required');
    expect(
      VisitorRepository.validateAddress('  '),
      'visitor_address_required',
    );
    expect(VisitorRepository.validateAddress('Ab'), 'visitor_address_invalid');
    expect(VisitorRepository.validateAddress('Abc'), isNull);
    // Short real place names must pass (Daet, Labo, Naga).
    expect(VisitorRepository.validateAddress('Daet'), isNull);
    expect(VisitorRepository.validateAddress('Labo'), isNull);
    expect(
      VisitorRepository.validateAddress('Purok 3, Mercedes'),
      isNull,
    );
  });
}
