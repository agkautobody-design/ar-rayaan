import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/sound/sound_services.dart';
import '../app_colors.dart';

/// Small gold speaker button that reads English text aloud via the device
/// voice — the app's "verbally communicative" layer (NOOR, Hādi, du'as).
///
/// A screen reader hears it as a button ([semanticLabel]). The gold circle
/// stays [size] wide; [minTapTarget] grows only the area that answers a tap
/// (48 for a touch target that meets the platform guidance).
class SpeakButton extends ConsumerWidget {
  const SpeakButton({
    required this.text,
    this.size = 26,
    this.minTapTarget = 0,
    this.semanticLabel = 'Read aloud',
    super.key,
  });

  final String text;
  final double size;
  final double minTapTarget;
  final String semanticLabel;

  /// The smallest touch target (Material and WCAG guidance).
  static const double minTarget = 48;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void speak() => ref.read(speechServiceProvider).speak(text);
    final Widget circle = Container(
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
    );
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: speak,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: speak,
        child: minTapTarget > size
            ? SizedBox(
                width: minTapTarget,
                height: minTapTarget,
                child: Center(child: circle),
              )
            : circle,
      ),
    );
  }
}
