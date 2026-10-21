import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/sound/sound_services.dart';
import '../app_colors.dart';

/// Small gold speaker button that reads English text aloud via the device
/// voice — the app's "verbally communicative" layer (NOOR, Hādi, du'as).
///
/// The circle is drawn at [size], but the button is at least 48 x 48 logical
/// pixels to hit, and a screen reader announces it as "Read aloud".
class SpeakButton extends ConsumerWidget {
  const SpeakButton({required this.text, this.size = 26, super.key});

  final String text;
  final double size;

  /// The smallest touch target (Material and WCAG guidance).
  static const double minTarget = 48;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void speak() => ref.read(speechServiceProvider).speak(text);
    final double box = size < minTarget ? minTarget : size;
    return Semantics(
      button: true,
      label: 'Read aloud',
      excludeSemantics: true,
      onTap: speak,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: speak,
        child: SizedBox(
          width: box,
          height: box,
          child: Center(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.night.withValues(alpha: 0.4),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              child: Icon(
                Icons.volume_up_outlined,
                size: size * 0.5,
                color: AppColors.gold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
