import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/constants/app_routes.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/features/home/home_page.dart';
import 'package:nita/features/splash/splash_page.dart';

class LolaApp extends StatelessWidget {
  const LolaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: MaterialApp(
        title: 'In Loving Memory',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.cream,
          fontFamily: 'Georgia',
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
