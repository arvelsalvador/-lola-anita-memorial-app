import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();
  static const Color viewerBackground = Color(0xFF17110D);
  static const warmDark = Color(0xFF2E1F17);
  static const warmMid = Color(0xFF6B4C3B);
  static const warmDeep = Color(0xFF4A2E22);
  static const rose = Color(0xFFC4836A);
  static const roseDeep = Color(0xFF6B3524);
  static const roseLight = Color(0xFFF5E6DF);
  static const terracotta = Color(0xFFCB6A4B);
  static const gold = Color(0xFFC9A96E);
  static const goldLight = Color(0xFFF0E4C8);
  static const cream = Color(0xFFFAF6F1);
  static const white = Color(0xFFFFFDF9);
  static const textDark = Color(0xFF3D2B1F);
  static const muted = Color(0xFF8C7267);
}

class AppAssets {
  AppAssets._();
  static const String nanayPortrait = 'assets/images/Family DP/Nanay_dp.jpg';
}

class AppTextStyles {
  AppTextStyles._();

  static final serifDisplay = GoogleFonts.inter(
    fontSize: 28,
    color: const Color(0xFFFAF0E6),
    fontWeight: FontWeight.w300,
    letterSpacing: 2,
  );
  static final serifHeading = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );
  static final serifBody = GoogleFonts.inter(
    fontSize: 14,
    color: AppColors.warmMid,
    height: 1.8,
  );
  static final serifItalic = GoogleFonts.inter(
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
