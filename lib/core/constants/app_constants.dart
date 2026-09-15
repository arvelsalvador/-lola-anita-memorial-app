import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // ── Core palette (DESIGN.md) ─────────────────────────────────────────
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
  static const textDark = Color(0xFF3D2B1F);
  static const muted = Color(0xFF8C7267);

  /// The paper card fill (#FFFDF9). Named `paper` per DESIGN.md — it is
  /// NOT pure white (#FFFFFF), so it must never stand in for plain white.
  static const paper = Color(0xFFFFFDF9);

  /// Deep near-black ground for the photo lightbox / video viewer.
  static const viewerBackground = Color(0xFF17110D);

  // ── Warm paper tints (one-off surfaces, byte-matched from the views) ──
  /// Warm ivory for foreground content on dark grounds (candle button,
  /// language toggle, splash petals).
  static const linen = Color(0xFFFAF0E6);

  /// Family detail-sheet / initials tile tint.
  static const blushPaper = Color(0xFFFFF4EC);

  /// Family-tree canvas branch chip tint.
  static const warmPaper = Color(0xFFFFF0DD);

  /// Settings tech-chip fill.
  static const mistPaper = Color(0xFFF6F1E6);

  /// Search / input field fill.
  static const fieldFill = Color(0xFFF0ECE5);

  /// Contact form field fill.
  static const fieldPaper = Color(0xFFFBF8F2);

  /// Words-page quote card tint.
  static const quotePaper = Color(0xFFFBF3E8);

  // ── Borders & warm accents ───────────────────────────────────────────
  static const sandBorder = Color(0xFFEBE1D3);
  static const stoneBorder = Color(0xFFE0D6CC);
  static const copper = Color(0xFFB0653A);
  static const amber = Color(0xFFB06A2B);
  static const glowGold = Color(0xFFF7E7B6);
  static const candleGlow = Color(0xFFFFF6E0);
  static const haloCream = Color(0xFFFFF6E3);

  /// Pale gold used for the curved memorial header text and glow pulse.
  static const paleGold = Color(0xFFE6D3A3);

  /// Antiqued gold ink (settings about/developer headings).
  static const goldInk = Color(0xFF96742A);

  /// Near-black warm charcoal (top bar, settings header, glow ring).
  static const charcoal = Color(0xFF1C1713);

  /// Hero scrim base — always consumed via `withValues(alpha: …)`.
  static const heroScrim = Color(0xFF1A100D);

  // ── Grandchild avatar pastels (family page, cycled by index) ────────
  static const tintLavender = Color(0xFFF1E9FB);
  static const tintMint = Color(0xFFE6F5EA);
  static const tintPink = Color(0xFFFDE8F0);
  static const accentPurple = Color(0xFF8B5FBF);
  static const accentGreen = Color(0xFF3F9142);
  static const accentPink = Color(0xFFD1568B);

  // ── Candle gate dark ramp (radial light falloff) ─────────────────────
  static const darkAsh = Color(0xFF322217);
  static const darkEmber = Color(0xFF1B120B);
  static const darkSoot = Color(0xFF0D0805);

  // ── Candle painter (gate medallion, flame, wax, hand) ────────────────
  static const medallionGoldLight = Color(0xFFE9D3A6);
  static const medallionGoldDeep = Color(0xFFB98E4F);
  static const medallionInk = Color(0xFF8F6A33);
  static const flameGold = Color(0xFFFFC96A);
  static const flameCore = Color(0xFFFFD54F);
  static const flameAmber = Color(0xFFFF8F00);
  static const flameEmber = Color(0xFFFF6D00);
  static const flameGlow = Color(0xFFFFE082);
  static const flameInner = Color(0xFFFFFDE7);
  static const wickBrown = Color(0xFF4A3626);
  static const waxShade = Color(0xFFE9DEC8);
  static const waxLight = Color(0xFFFBF6EA);
  static const waxDeep = Color(0xFFD9CBB0);
  static const waxDrip = Color(0xFFF3EBD8);
  static const handPaper = Color(0xFFFDF8EE);
  static const handShade = Color(0xFFEDE2CC);

  // ── Splash screen ────────────────────────────────────────────────────
  static const dawnRose = Color(0xFFC4956A);
  static const duskBrown = Color(0xFF7A4E3A);
  static const petalBlush = Color(0xFFD4BFB5);

  // ── Settings icon backgrounds & developer accents ────────────────────
  static const iconBgSand = Color(0xFFEBCFA8);
  static const iconBgSage = Color(0xFFB3BC9F);
  static const iconBgCream = Color(0xFFF1E7CF);
  static const iconBgOlive = Color(0xFF7C8B5F);
  static const devCopper = Color(0xFFB26B45);
  static const devCopperDeep = Color(0xFF8E4F2E);
}

class AppAssets {
  AppAssets._();
  static const String nanayPortrait = 'assets/images/Family DP/Nanay_dp.jpg';
}

class AppTextStyles {
  AppTextStyles._();

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
    fontFamily: 'Inter',
  );
}
