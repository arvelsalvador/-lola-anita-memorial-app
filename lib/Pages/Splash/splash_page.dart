import 'package:flutter/material.dart';
import 'package:nita/utils/Constants/app_constants.dart';
import 'package:nita/utils/Constants/app_routes.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.home);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmDark,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.gold, AppColors.rose],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withOpacity(0.3),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFC4956A), Color(0xFF7A4E3A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'L',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 40,
                        color: Color(0xFFFAF0E6),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'In Loving Memory',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 24,
                  color: Color(0xFFFAF0E6),
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Anita Daiz Lumbao',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.gold,
                  letterSpacing: 5,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppColors.gold.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
