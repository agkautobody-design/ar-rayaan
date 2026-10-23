import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/elder/application/elder_mode.dart';
import 'keyboard_scroll.dart';
import 'text_size.dart';

/// Elder Mode keeps every control at least this tall (the usual minimum is 48).
const double kElderMinTapHeight = 56;

/// Applies, once for the whole app:
/// * the text scale: the phone's size x Settings > Text size, lifted to a
///   floor of [kElderTextFloor] in Elder Mode, never beyond [kMaxTextScale];
/// * in Elder Mode, bigger minimum tap targets for buttons;
/// * keyboard scrolling (Space, Page Up/Down, Home, End).
class AccessibilityScope extends ConsumerWidget {
  const AccessibilityScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool elder = ref.watch(elderModeProvider);
    final TextSizeChoice size = ref.watch(textSizeProvider);
    final MediaQueryData mq = MediaQuery.of(context);

    final TextScaler scaler;
    if (!elder && size == TextSizeChoice.normal) {
      // The phone's own scaler (it may be non-linear), only bounded.
      scaler = mq.textScaler.clamp(
        minScaleFactor: kMinTextScale,
        maxScaleFactor: kMaxTextScale,
      );
    } else {
      scaler = TextScaler.linear(
        effectiveTextScale(
          system: mq.textScaler.scale(14) / 14,
          user: size.factor,
          elder: elder,
        ),
      );
    }

    Widget out = MediaQuery(
      data: mq.copyWith(textScaler: scaler),
      child: KeyboardScrollScope(child: child),
    );
    if (elder) {
      out = Theme(data: elderTheme(Theme.of(context)), child: out);
    }
    return out;
  }
}

/// [base] with larger minimum tap targets: padded targets everywhere and
/// buttons at least [kElderMinTapHeight] tall.
ThemeData elderTheme(ThemeData base) {
  const WidgetStateProperty<Size> min = WidgetStatePropertyAll<Size>(
    Size(64, kElderMinTapHeight),
  );
  ButtonStyle tall(ButtonStyle? style) =>
      (style ?? const ButtonStyle()).copyWith(minimumSize: min);
  return base.copyWith(
    materialTapTargetSize: MaterialTapTargetSize.padded,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: tall(base.elevatedButtonTheme.style),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: tall(base.filledButtonTheme.style),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: tall(base.outlinedButtonTheme.style),
    ),
    textButtonTheme: TextButtonThemeData(
      style: tall(base.textButtonTheme.style),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: (base.iconButtonTheme.style ?? const ButtonStyle()).copyWith(
        minimumSize: const WidgetStatePropertyAll<Size>(
          Size(kElderMinTapHeight, kElderMinTapHeight),
        ),
      ),
    ),
  );
}
