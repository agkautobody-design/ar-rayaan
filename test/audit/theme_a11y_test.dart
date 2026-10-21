import 'dart:io';
import 'dart:math' as math;

import 'package:ar_rayaan/app/theme/app_colors.dart';
import 'package:ar_rayaan/app/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Theme accessibility floors: WCAG AA contrast (4.5:1) for the text tokens on
/// every dark surface the app draws, and no text style below 12 px.
double _lin(int c) {
  final double v = c / 255;
  return v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4) as double;
}

double _luminance(Color c) {
  final int argb = c.toARGB32();
  return 0.2126 * _lin((argb >> 16) & 0xFF) +
      0.7152 * _lin((argb >> 8) & 0xFF) +
      0.0722 * _lin(argb & 0xFF);
}

/// [fg] (with its alpha) painted over opaque [bg].
Color _over(Color fg, Color bg) => Color.alphaBlend(fg, bg);

double _contrast(Color a, Color b) {
  final double la = _luminance(a);
  final double lb = _luminance(b);
  final double hi = math.max(la, lb);
  final double lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  // Opaque surfaces text actually sits on: the page, the navy panels, and the
  // glass card (10 %) and strong glass (20 %) over each.
  final Map<String, Color> surfaces = <String, Color>{
    'night': AppColors.night,
    'navy': AppColors.navy,
    'glass over night': _over(AppColors.glassFill, AppColors.night),
    'glass over navy': _over(AppColors.glassFill, AppColors.navy),
    'double glass over night': _over(
      AppColors.glassFill,
      _over(AppColors.glassFill, AppColors.night),
    ),
  };

  for (final MapEntry<String, Color> t in <String, Color>{
    'textPrimary': AppColors.textPrimary,
    'textMuted': AppColors.textMuted,
    'textFaint': AppColors.textFaint,
    'gold': AppColors.gold,
  }.entries) {
    test('${t.key} meets 4.5:1 on every surface', () {
      for (final MapEntry<String, Color> s in surfaces.entries) {
        final double ratio = _contrast(_over(t.value, s.value), s.value);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '${t.key} on ${s.key} is ${ratio.toStringAsFixed(2)}:1',
        );
      }
    });
  }

  // Floors for text drawn with a translucent gold/sand colour (the low-alpha
  // text colours found in the audit). Each floor was computed from the surfaces
  // above; below it the colour is under 4.5:1.
  test('translucent text colours used in lib meet 4.5:1 at their floors', () {
    final Map<String, (Color, double)> floors = <String, (Color, double)>{
      'gold@0.9': (AppColors.gold, 0.9),
      'sand@0.7': (AppColors.sand, 0.7),
      'goldLight@0.8': (AppColors.goldLight, 0.8),
    };
    for (final MapEntry<String, (Color, double)> e in floors.entries) {
      final Color fg = e.value.$1.withValues(alpha: e.value.$2);
      for (final MapEntry<String, Color> s in surfaces.entries) {
        final double ratio = _contrast(_over(fg, s.value), s.value);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '${e.key} on ${s.key} is ${ratio.toStringAsFixed(2)}:1',
        );
      }
    }
  });

  test('destructive (Log Out) meets 4.5:1 on the page and on a glass card', () {
    for (final Color bg in <Color>[
      AppColors.night,
      _over(AppColors.glassFill, AppColors.night),
    ]) {
      expect(
        _contrast(_over(AppColors.destructive, bg), bg),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  test('the shared text styles are never below 12 px', () {
    final Map<String, TextStyle> styles = <String, TextStyle>{
      'bodyMuted': AppText.bodyMuted,
      'caption': AppText.caption,
      'label': AppText.label,
      'eyebrow': AppText.eyebrow,
      'body': AppText.body,
    };
    for (final MapEntry<String, TextStyle> e in styles.entries) {
      expect(e.value.fontSize, greaterThanOrEqualTo(12), reason: e.key);
    }
  });

  test('no fontSize literal anywhere in lib is under 12 px', () {
    final RegExp size = RegExp(r'fontSize:\s*(\d+(?:\.\d+)?)');
    final List<String> small = <String>[];
    for (final String dir in <String>['lib']) {
      for (final FileSystemEntity f in Directory(dir).listSync(recursive: true)) {
        if (f is! File || !f.path.endsWith('.dart')) continue;
        if (f.path.contains('/generated/')) continue;
        for (final RegExpMatch m in size.allMatches(f.readAsStringSync())) {
          if (double.parse(m.group(1)!) < 12) small.add('${f.path}: ${m.group(0)}');
        }
      }
    }
    expect(small, isEmpty, reason: small.join('\n'));
  });
}
