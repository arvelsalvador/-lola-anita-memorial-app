import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nita/controllers/guide_controller.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/constants/app_routes.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/views/home/home_page.dart';
import 'package:nita/views/splash/entry_page.dart';
import 'package:nita/views/splash/splash_page.dart';

class LolaApp extends StatelessWidget {
  final GuideController? guideController;

  const LolaApp({super.key, this.guideController});

  @override
  Widget build(BuildContext context) {
    // Global app state lives here. Feature controllers (Home/Gallery/
    // Words/Condolences) stay explicitly injected via `HomePage`'s
    // composition root so `HomeShell` remains directly testable with
    // constructor injection — see `test/header_scroll_test.dart`.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(
          create: (_) => guideController ?? GuideController(),
        ),
      ],
      child: MaterialApp(
        title: 'In Loving Memory',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.cream,
          // Body voice: Inter (open SF Pro stand-in) carries all body copy as
          // the base family; Playfair Display is applied at display/heading
          // call sites. Sans fallback chain for body text.
          fontFamily: 'Inter',
          fontFamilyFallback: const [
            '-apple-system',
            'Inter',
            'Helvetica Neue',
            'Arial',
            'sans-serif',
          ],
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.rose),
          useMaterial3: true,
        ),
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const SplashPage(),
          AppRoutes.entry: (_) => const EntryPage(),
          AppRoutes.home: (_) => const HomePage(),
        },
      ),
    );
  }
}
