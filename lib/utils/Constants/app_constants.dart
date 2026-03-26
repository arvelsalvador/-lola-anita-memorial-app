import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const warmDark = Color(0xFF2E1F17);
  static const warmMid = Color(0xFF6B4C3B);
  static const warmDeep = Color(0xFF4A2E22);
  static const rose = Color(0xFFC4836A);
  static const roseLight = Color(0xFFF5E6DF);
  static const gold = Color(0xFFC9A96E);
  static const goldLight = Color(0xFFF0E4C8);
  static const cream = Color(0xFFFAF6F1);
  static const white = Color(0xFFFFFDF9);
  static const textDark = Color(0xFF3D2B1F);
  static const muted = Color(0xFF8C7267);
}

class AppTextStyles {
  AppTextStyles._();

  static const serifDisplay = TextStyle(
    fontFamily: 'Georgia',
    fontSize: 28,
    color: Color(0xFFFAF0E6),
    fontWeight: FontWeight.w300,
    letterSpacing: 2,
  );
  static const serifHeading = TextStyle(
    fontFamily: 'Georgia',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );
  static const serifBody = TextStyle(
    fontFamily: 'Georgia',
    fontSize: 14,
    color: AppColors.warmMid,
    height: 1.8,
  );
  static const serifItalic = TextStyle(
    fontFamily: 'Georgia',
    fontStyle: FontStyle.italic,
    fontSize: 16,
    color: AppColors.textDark,
    height: 1.7,
  );
  static const sectionLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 3,
    color: AppColors.rose,
  );
  static const caption = TextStyle(
    fontSize: 12,
    color: AppColors.muted,
    height: 1.5,
  );
  static const goldYears = TextStyle(
    fontSize: 12,
    color: AppColors.gold,
    letterSpacing: 4,
    fontWeight: FontWeight.w300,
  );
}
