import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Material 3 custom theme — dark, gold-glass Ar-Rayaan design system.
abstract final class AppTheme {
  /// True when running under the widget-test binding (the InkSparkle
  /// shader asset doesn't exist there).
  static bool get _runningInTest {
    try {
      return WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return false;
    }
  }

  static ThemeData dark() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.gold,
      brightness: Brightness.dark,
      surface: AppColors.night,
      primary: AppColors.gold,
      onPrimary: AppColors.night,
      secondary: AppColors.navy,
      onSecondary: AppColors.sand,
      error: AppColors.destructive,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.night,
      textTheme: AppText.textTheme(),
      fontFamily: AppFonts.body,
      // InkSparkle's fragment shader isn't bundled in the widget-test
      // environment (taps throw FragmentProgram asset errors there), so
      // tests fall back to InkRipple; production keeps the sparkle.
      // NB: the FLUTTER_TEST define is NOT reliably set here, so detect
      // the test binding at runtime instead.
      splashFactory: _runningInTest
          ? InkRipple.splashFactory
          : InkSparkle.splashFactory,
      dividerTheme: const DividerThemeData(
        color: Color(0x1AD4AF37),
        thickness: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.gold, size: 20),
    );
  }
}
