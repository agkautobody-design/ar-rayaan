import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/sound/sound_services.dart';
import '../app_colors.dart';

/// Small gold speaker button that reads English text aloud via the device
/// voice — the app's "verbally communicative" layer (NOOR, Hādi, du'as).
class SpeakButton extends ConsumerWidget {
  const SpeakButton({required this.text, this.size = 26, super.key});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(speechServiceProvider).speak(text),
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
    );
  }
}
