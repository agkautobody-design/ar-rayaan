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
      // Standard density and padded tap targets on every platform. Without
      // this a desktop browser gets the compact density and buttons shrink
      // to 32 px, below the 44 px a finger or a pointer needs.
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      scaffoldBackgroundColor: AppColors.night,
      textTheme: AppText.textTheme(),
      fontFamily: AppFonts.body,
      // Inter has no U+FDFA (the salawat ligature); Amiri does. Without this
      // the Prophet's honorific can render as an empty box on the web.
      // Noto Sans Bengali (SIL OFL, bundled) covers the Bangla UI so it never
      // depends on a font download from Google at run time.
      fontFamilyFallback: const <String>[AppFonts.arabic, AppFonts.bengali],
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
      // Keyboard focus must be easy to see: a clear gold wash on every
      // material control (cards, tiles and rows also draw a 3px gold ring,
      // see FocusRing).
      focusColor: AppColors.gold.withValues(alpha: 0.4),
      // Plain buttons (icon, text, outlined) also get the 3 px bright ring
      // while the keyboard is on them; a faint wash alone was nearly
      // invisible over the patterned backgrounds.
      iconButtonTheme: const IconButtonThemeData(style: _focusRingStyle),
      textButtonTheme: const TextButtonThemeData(style: _focusRingStyle),
      outlinedButtonTheme: const OutlinedButtonThemeData(
        style: _focusRingStyle,
      ),
      // Gold-filled buttons ("Use my location", "Begin") hide a gold ring, so
      // theirs is white; without it the keyboard focus was barely visible.
      elevatedButtonTheme: const ElevatedButtonThemeData(
        style: _focusRingOnFillStyle,
      ),
      filledButtonTheme: const FilledButtonThemeData(
        style: _focusRingOnFillStyle,
      ),
    );
  }

  /// Draws the focus ring as the button's border only while it has focus;
  /// every other state keeps the button's own border.
  static const ButtonStyle _focusRingStyle = ButtonStyle(
    side: _FocusRingSide(),
  );

  /// The same, in white, for buttons with a solid fill.
  static const ButtonStyle _focusRingOnFillStyle = ButtonStyle(
    side: _FocusRingOnFillSide(),
  );
}

class _FocusRingOnFillSide extends WidgetStateBorderSide {
  const _FocusRingOnFillSide();

  @override
  BorderSide? resolve(Set<WidgetState> states) =>
      states.contains(WidgetState.focused)
      ? const BorderSide(color: Color(0xFFFFFFFF), width: 3)
      : null;
}

class _FocusRingSide extends WidgetStateBorderSide {
  const _FocusRingSide();

  @override
  BorderSide? resolve(Set<WidgetState> states) =>
      states.contains(WidgetState.focused)
      ? const BorderSide(color: AppColors.goldLight, width: 3)
      : null;
}
