import 'package:flutter_test/flutter_test.dart';
import 'package:nita/data/condolences/condolence_repository.dart';

void main() {
  test('validateMessage rejects empty and too-long input', () {
    expect(
      CondolenceRepository.validateMessage(''),
      'candle_message_required',
    );
    expect(
      CondolenceRepository.validateMessage('   '),
      'candle_message_required',
    );
    expect(CondolenceRepository.validateMessage('Thank you, Nanay'), isNull);
    expect(
      CondolenceRepository.validateMessage('a' * 501),
      'candle_message_too_long',
    );
    expect(
      CondolenceRepository.validateMessage('a' * 500),
      isNull,
    );
  });

  test('saveMessage returns false without throwing when unconfigured', () async {
    const repo = CondolenceRepository();
    // Supabase is unconfigured in tests: skips network, never throws.
    expect(await repo.saveMessage(name: 'Arvel', message: 'Hi'), isFalse);
    // Invalid input never hits the network either.
    expect(await repo.saveMessage(name: 'Arvel', message: '   '), isFalse);
    expect(
      await repo.saveMessage(name: 'Arvel', message: 'a' * 501),
      isFalse,
    );
  });
}
