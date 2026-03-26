import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'Pages/Splash/splash_page.dart';
import 'Pages/Home//View/home_page.dart';
import 'utils/Constants/app_constants.dart';
import 'utils/Constants/app_routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const LolaApp());
}

class LolaApp extends StatelessWidget {
  const LolaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
    );
  }
}
