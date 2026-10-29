import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nita/core/constants/supabase_config.dart';
import 'package:nita/data/visitors/visitor_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Keep tests offline: syncVisitor must not reach the real backend.
    SupabaseConfig.isConfigured = false;
    SupabaseConfig.isInitialized = false;
  });

  test('fresh device has no visitor', () async {
    const repo = VisitorRepository();
    expect(await repo.hasVisitor(), isFalse);
  });

  test('saveVisitorLocal remembers without touching the network', () async {
    const repo = VisitorRepository();
    await repo.saveVisitorLocal(
      name: 'Test Visitor',
      address: 'Purok 3, Mercedes, Camarines Norte',
    );
    expect(await repo.hasVisitor(), isTrue);
    expect(await repo.localName(), 'Test Visitor');

    await repo.clearVisitor();
    expect(await repo.hasVisitor(), isFalse);
  });

  test('syncVisitor returns false offline, never throws', () async {
    const repo = VisitorRepository();
    expect(
      await repo.syncVisitor(
        name: 'Test Visitor',
        address: 'Purok 3, Mercedes, Camarines Norte',
      ),
      isFalse,
    );
  });

  test('saveVisitor still saves locally when remote is unavailable', () async {
    const repo = VisitorRepository();
    expect(
      await repo.saveVisitor(
        name: 'Test Visitor',
        address: 'Purok 3, Mercedes, Camarines Norte',
      ),
      isFalse,
    );
    expect(await repo.hasVisitor(), isTrue);
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
