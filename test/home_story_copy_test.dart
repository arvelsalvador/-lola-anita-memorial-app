import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:nita/controllers/home_controller.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/views/home/home_page.dart';

/// The Story tab must render the long-form Tagalog copy in full on a narrow
/// window: the quote, the 1940/1958 timeline entries, and the expanded About
/// paragraph. None of these are line-capped, so this guards against a future
/// fixed height or ellipsis creeping back in.
void main() {
  setUpAll(() {
    // VisibilityDetector defers its callbacks on a periodic timer, which
    // otherwise stays pending at teardown.
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  testWidgets('Story copy wraps in full on a 320px window', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LanguageProvider(),
        child: MaterialApp(
          home: Scaffold(body: StoryPage(homeController: HomeController())),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Marunong at Diyos'), findsOneWidget);
    expect(
      find.textContaining('Ang kabataan niya ang humubog kung gaano'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Sampung taon ang agwat ng edad niya'),
      findsOneWidget,
    );

    final scrollable = find
        .descendant(
          of: find.byType(StoryPage),
          matching: find.byType(Scrollable),
        )
        .first;
    final aboutParagraph = find.textContaining(
      'Isa rin siyang negosyante. Ang pag-aalaga ng baboy',
    );
    await tester.scrollUntilVisible(
      aboutParagraph,
      200,
      scrollable: scrollable,
    );
    expect(aboutParagraph, findsOneWidget);
    expect(
      find.textContaining(
        'Laging abala ang kanyang mga kamay: pag-aaruga, paglilinis',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('nagtatahi'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Pag-aalaga'),
      200,
      scrollable: scrollable,
    );
    expect(find.text('Pag-aalaga'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
