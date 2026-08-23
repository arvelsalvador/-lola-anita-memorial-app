import 'package:flutter_test/flutter_test.dart';
import 'package:nita/core/localization/language_provider.dart';

void main() {
  test('EN, TL and BI maps contain exactly the same keys', () {
    final enKeys = LanguageProvider.en.keys.toSet();
    final tlKeys = LanguageProvider.tl.keys.toSet();
    final biKeys = LanguageProvider.bi.keys.toSet();
    expect(
      enKeys,
      tlKeys,
      reason:
          'Missing in EN: ${tlKeys.difference(enKeys).join(', ')}\n'
          'Missing in TL: ${enKeys.difference(tlKeys).join(', ')}',
    );
    expect(
      enKeys,
      biKeys,
      reason:
          'Missing in EN: ${biKeys.difference(enKeys).join(', ')}\n'
          'Missing in BI: ${enKeys.difference(biKeys).join(', ')}',
    );
  });

  test('No key resolves to its raw key in any language', () {
    final provider = LanguageProvider();
    for (final key in LanguageProvider.en.keys) {
      expect(
        provider.t(key),
        isNot(key),
        reason: 'EN missing translation for $key',
      );
    }
    provider.setLanguage(AppLanguage.tagalog);
    for (final key in LanguageProvider.tl.keys) {
      expect(
        provider.t(key),
        isNot(key),
        reason: 'TL missing translation for $key',
      );
    }
    provider.setLanguage(AppLanguage.bicol);
    for (final key in LanguageProvider.bi.keys) {
      expect(
        provider.t(key),
        isNot(key),
        reason: 'BI missing translation for $key',
      );
    }
  });

  test('default language is Tagalog', () {
    final provider = LanguageProvider();
    expect(provider.isTagalog, isTrue);
  });

  test('toggling switches the translation language', () {
    final provider = LanguageProvider();
    expect(provider.t('nav_home'), 'Tahanan');
    provider.setLanguage(AppLanguage.english);
    expect(provider.t('nav_home'), 'Home');
    expect(provider.t('story_quote'), contains('kitchen'));
    provider.setLanguage(AppLanguage.bicol);
    expect(provider.t('nav_home'), 'Harong');
    expect(provider.t('story_quote'), contains('kusina'));
  });
}
