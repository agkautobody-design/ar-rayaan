import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Locked typography: Playfair Display (headings), Inter (body), Amiri (Arabic).
abstract final class AppFonts {
  static const String display = 'PlayfairDisplay';
  static const String body = 'Inter';
  static const String arabic = 'Amiri';
}

abstract final class AppText {
  static const TextStyle displayLarge = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 40,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  /// Caption: 12px Inter, muted — helper text, links, form footnotes.
  static const TextStyle caption = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  /// Label: 14px Inter semibold — button labels, emphasized UI text.
  static const TextStyle label = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Eyebrow: 10px · medium · uppercase · 0.3em tracking · gold/80.
  static const TextStyle eyebrow = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 3.0,
    color: Color(0xCCD4AF37),
  );

  static const TextStyle arabicLarge = TextStyle(
    fontFamily: AppFonts.arabic,
    fontSize: 34,
    height: 1.9,
    color: AppColors.textPrimary,
  );

  static TextTheme textTheme() {
    return const TextTheme(
      displayLarge: displayLarge,
      displayMedium: displayMedium,
      titleMedium: titleMedium,
      bodyMedium: body,
      bodySmall: bodyMuted,
    );
  }
}
