import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/constants/app_routes.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/views/home_page.dart';
import 'package:nita/views/splash_page.dart';

class LolaApp extends StatelessWidget {
  const LolaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Global app state lives here. Feature controllers (Home/Gallery/
    // Memories/Tribute) stay explicitly injected via `HomePage`'s
    // composition root so `HomeShell` remains directly testable with
    // constructor injection — see `test/header_scroll_test.dart`.
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => LanguageProvider())],
      child: MaterialApp(
        title: 'In Loving Memory',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.cream,
          // Two-Voice Rule (DESIGN.md): Lora carries all body copy as the
          // base family; Playfair Display is applied at display/heading
          // call sites. Georgia is only a fallback — it can't be the base
          // because it doesn't exist on Android.
          fontFamily: 'Lora',
          fontFamilyFallback: const ['Georgia', 'Times New Roman', 'serif'],
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.rose),
          useMaterial3: true,
        ),
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const SplashPage(),
          AppRoutes.home: (_) => const HomePage(),
        },
      ),
    );
  }
}
