import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nita/controllers/gallery_controller.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/models/gallery_model.dart';
import 'package:nita/views/gallery/gallery_page.dart';

/// The featured card is the entry point to the highlights slideshow. It must
/// say so in words, not only with a play badge and chevron, and the hint has
/// to stay on one line on the narrowest supported phone width.
void main() {
  const expected = {
    AppLanguage.tagalog: 'Pindutin para i-play',
    AppLanguage.english: 'Tap to play',
    AppLanguage.bicol: 'Pindota para i-play',
  };

  for (final language in AppLanguage.values) {
    testWidgets(
      'featured card shows the play hint at 320px (${language.name})',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final lang = LanguageProvider()..setLanguage(language);
        final controller = GalleryController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: lang,
            child: MaterialApp(
              home: Scaffold(
                body: HeroSlideshowCard(
                  images: [
                    GalleryImageItem(
                      path: 'assets/images/Bahay.jpg',
                      group: GalleryGroup.bahay,
                    ),
                  ],
                  galleryController: controller,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text(expected[language]!), findsOneWidget);
        expect(find.byIcon(Icons.play_circle_outline_rounded), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Dispose the card so its 5s hero-rotation timer is cancelled.
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
