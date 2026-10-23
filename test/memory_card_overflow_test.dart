import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nita/controllers/home_controller.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/views/home/home_page.dart';

/// Lays [text] out exactly like the card does (same style, maxLines,
/// ellipsis, and the width the widget actually renders at) and asserts the
/// text fits — no trailing "…". Used for the memory titles, which stay
/// capped at two lines. Bodies are no longer capped (the card grows), so
/// they are checked with the adaptive-height probe below instead.
void expectTextFits(
  WidgetTester tester,
  String text,
  TextStyle style,
  int maxLines,
  String reason,
) {
  final matches = find.text(text).evaluate().toList();
  expect(
    matches,
    hasLength(1),
    reason: 'expected to find rendered text: $reason',
  );
  final widget = matches.first.widget as Text;
  final renderedWidth = tester.getSize(find.text(text)).width;

  final painter = TextPainter(
    text: TextSpan(text: widget.data, style: widget.style),
    textDirection: TextDirection.ltr,
    maxLines: maxLines,
    ellipsis: '\u2026',
  );
  painter.layout(maxWidth: renderedWidth);
  final diag = File('build/fit_diag.txt');
  try {
    diag.parent.createSync(recursive: true);
    diag.writeAsStringSync(
      '[fit] "$text" width=$renderedWidth maxLines=$maxLines '
      'chars=${text.length} exceeded=${painter.didExceedMaxLines} '
      'paintedH=${painter.height} '
      'family=${widget.style?.fontFamily}\n',
      mode: FileMode.append,
    );
  } catch (_) {
    // Diagnostics are best-effort; never fail the test on a write error.
  }
  debugPrint(
    '[fit] "$text" width=$renderedWidth maxLines=$maxLines '
    'chars=${text.length} exceeded=${painter.didExceedMaxLines} '
    'paintedH=${painter.height}',
  );
  expect(
    painter.didExceedMaxLines,
    isFalse,
    reason: 'text is cropped with an ellipsis ($reason)',
  );
  painter.dispose();
}

/// Loads every font declared in pubspec.yaml (via the app's
/// FontManifest.json) so the no-ellipsis probes measure with the real
/// bundled Lora/Playfair Display metrics.
///
/// The flutter_test engine does not auto-register pubspec-declared custom
/// fonts — without this every glyph falls back to the square test font
/// (~12px per glyph, about twice as wide as real Lora) and copy that fits
/// on devices reads as overflowing here. Unlike the old google_fonts setup
/// (which needed an HTTP fetch that flutter_test blocks), the TTFs now ship
/// in the app bundle, so this needs no network at all.
///
/// Returns false when no fonts could be loaded (e.g. corrupt bundle);
/// callers skip metric-sensitive probes in that case instead of failing on
/// fake metrics.
Future<bool> _loadBundledFonts() async {
  try {
    final manifestRaw = await rootBundle.loadString('FontManifest.json');
    final manifest = jsonDecode(manifestRaw) as List<dynamic>;
    var loadedFamilies = 0;
    for (final entry in manifest) {
      final family = entry['family'] as String?;
      final fonts = entry['fonts'] as List<dynamic>?;
      if (family == null || fonts == null || family == 'MaterialIcons') {
        continue;
      }
      final loader = FontLoader(family);
      for (final font in fonts) {
        final asset = font['asset'] as String?;
        if (asset == null) continue;
        loader.addFont(rootBundle.load(asset));
      }
      await loader.load();
      loadedFamilies++;
    }
    return loadedFamilies > 0;
  } catch (_) {
    // Missing or unreadable manifest — caller skips the precision probes.
    return false;
  }
}

Future<void> main() async {
  // Initialize the binding before touching rootBundle — the font loader
  // reads the asset manifest from main(), outside any testWidgets zone.
  TestWidgetsFlutterBinding.ensureInitialized();
  // The no-ellipsis probes measure with the real bundled Lora/Playfair
  // metrics. If the bundle somehow carries no fonts, these probes skip
  // rather than fail against the square test font.
  final fontsReady = _loadBundledFonts();

  // Regression probe: the memory card's photo is a fixed 150x200 slot in
  // the card row. When its asset wasn't bundled, the default load-failure
  // widget (an unwrapped error string) overflowed that slot — the "RIGHT
  // OVERFLOWED BY 104 PIXELS" seen on the Story tab's memories section.
  // Pump the card (photo on the left, index 0) across common phone widths
  // and assert nothing escapes — neither a flex overflow nor an unhandled
  // image-load error.
  const sizes = <double>[240, 280, 320, 360, 390, 412, 600, 800];

  for (final width in sizes) {
    testWidgets('memory card overflow probe @ ${width.toInt()}px', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(),
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: MemoryCard(
                    memory: HomeController.memoriesData.memories.first,
                    index: 0,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        tester.takeException(),
        isNull,
        reason: 'overflow/exception at ${width.toInt()}px width',
      );
    });
  }

  // Every memory has a real photo wired in now — probe each card so a bad
  // asset path or layout break on any of them surfaces, not just the
  // first's. Three representative widths keep the run time reasonable.
  const perMemorySizes = <double>[320, 390, 412];
  final memories = HomeController.memoriesData.memories;
  for (var i = 0; i < memories.length; i++) {
    for (final width in perMemorySizes) {
      testWidgets('${memories[i].id} overflow probe @ ${width.toInt()}px', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => LanguageProvider(),
            child: MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: MemoryCard(memory: memories[i], index: i),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(
          tester.takeException(),
          isNull,
          reason:
              '${memories[i].id} overflow/exception at '
              '${width.toInt()}px width',
        );
      });
    }
  }

  testWidgets('tapping the photo opens the preview with the real image', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LanguageProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: MemoryCard(
                  memory: HomeController.memoriesData.memories.first,
                  index: 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    // Tap the card's photo (the Hero) — the preview route pushes on top
    // with its own Hero, showing the same wired-in photo.
    await tester.tap(find.byType(Hero));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(Hero), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  // Adaptive-height probe: every memory body must render in full — no
  // maxLines cap, no ellipsis — with the card growing to fit it. Cards keep
  // 276px as a minimum, and the photo is pinned to both vertical edges so
  // it fills whatever height the copy needs (no empty strip). Titles stay
  // capped at 2 lines because every title is short.
  final widths = <double>[360, 390, 412];
  final allMemories = HomeController.memoriesData.memories;
  if (!(await fontsReady)) {
    testWidgets(
      'no-ellipsis probes skipped (bundled fonts unavailable)',
      (WidgetTester tester) async {},
    );
    return;
  }

  // Canary: the square flutter_test font draws every glyph exactly 12px
  // wide, so ten M's measure 120px under it. Real Lora measures ~104-110px.
  // This catches a silently failed font registration so the probes below
  // can never pass/fail on fake metrics.
  testWidgets('real font metrics are active (canary)', (
    WidgetTester tester,
  ) async {
    final painter = TextPainter(
      text: const TextSpan(text: 'MMMMMMMMMM', style: AppTextStyles.caption),
      textDirection: TextDirection.ltr,
    );
    painter.layout();
    final width = painter.width;
    painter.dispose();
    expect(
      width,
      lessThan(115),
      reason:
          'text measured with the square test font (10 M = $width px); '
          'real bundled font registration did not take effect',
    );
  });

  for (final width in widths) {
    for (final language in AppLanguage.values) {
      final languageName = switch (language) {
        AppLanguage.tagalog => 'Tagalog',
        AppLanguage.english => 'English',
        AppLanguage.bicol => 'Bicol',
      };
      testWidgets(
        'memory copy renders fully @ ${width.toInt()}px ($languageName)',
        (WidgetTester tester) async {
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);
          final lang = LanguageProvider()..setLanguage(language);

          for (var i = 0; i < allMemories.length; i++) {
            tester.view.physicalSize = Size(width, 844);
            await tester.pumpWidget(
              ChangeNotifierProvider(
                create: (_) => lang,
                child: MaterialApp(
                  home: Scaffold(
                    body: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: MemoryCard(memory: allMemories[i], index: i),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 50));

            final cardSize = tester.getSize(find.byType(MemoryCard));
            expect(
              cardSize.height,
              greaterThanOrEqualTo(276.0),
              reason:
                  '${allMemories[i].id} card must keep its 276px minimum '
                  '@ ${width.toInt()}px ($languageName)',
            );

            final body = lang.t(allMemories[i].bodyKey);
            final bodyFinder = find.text(body);
            expect(
              bodyFinder,
              findsOneWidget,
              reason:
                  '${allMemories[i].id} body @ ${width.toInt()}px '
                  '($languageName)',
            );
            final bodyWidget = tester.widget<Text>(bodyFinder);
            expect(
              bodyWidget.maxLines,
              isNull,
              reason:
                  '${allMemories[i].id} body must not cap its lines '
                  '@ ${width.toInt()}px ($languageName)',
            );
            expect(
              bodyWidget.overflow,
              isNot(TextOverflow.ellipsis),
              reason:
                  '${allMemories[i].id} body must not end in an ellipsis '
                  '@ ${width.toInt()}px ($languageName)',
            );

            // The rendered body must sit fully inside the card's padding —
            // proof it was laid out in the grown card, not clipped.
            final bodyRect = tester.getRect(bodyFinder);
            final cardRect = tester.getRect(find.byType(MemoryCard));
            expect(
              bodyRect.bottom,
              lessThanOrEqualTo(cardRect.bottom - 15.0),
              reason:
                  '${allMemories[i].id} body is clipped by the card bottom '
                  '@ ${width.toInt()}px ($languageName)',
            );
            expect(
              bodyRect.top,
              greaterThanOrEqualTo(cardRect.top + 15.0),
              reason:
                  '${allMemories[i].id} body is clipped by the card top '
                  '@ ${width.toInt()}px ($languageName)',
            );

            // The photo is pinned to both vertical edges; it must fill the
            // card interior even when the copy pushes the card past its
            // minimum. The 1.4px difference is the card's 0.7px border.
            final photoSize = tester.getSize(find.byType(Hero));
            expect(
              photoSize.height,
              closeTo(cardSize.height - 1.4, 0.5),
              reason:
                  '${allMemories[i].id} photo must fill the grown card '
                  '@ ${width.toInt()}px ($languageName)',
            );

            if (allMemories[i].id == 'memory_1' && width == 360) {
              expect(
                cardSize.height,
                greaterThan(276.0),
                reason: 'long body must grow the card at 360px ($languageName)',
              );
            }

            final title = lang.t(allMemories[i].titleKey);
            expectTextFits(
              tester,
              title,
              AppTextStyles.homeContent,
              2,
              '${allMemories[i].id} title @ ${width.toInt()}px ($languageName)',
            );
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
