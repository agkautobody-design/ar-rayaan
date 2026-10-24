import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/packages/hadi_package.dart';
import '../../../app/core/packages/usage_meter.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../application/hadi_controller.dart';
import '../data/hosted_ai.dart';

/// "2 of 3 AI messages left today". Shown only when a hosted-AI backend
/// exists in this build; otherwise it takes no space. The built-in library
/// is free and never counted, and the line says so.
class HadiUsageLine extends ConsumerWidget {
  const HadiUsageLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(hostedAiProvider).isAvailable) {
      return const SizedBox.shrink();
    }
    // Rebuilds after every question: the controller state changes then.
    ref.watch(hadiControllerProvider);
    final HadiPackage pkg = ref.watch(hadiPackageProvider);
    final UsageSnapshot snap = ref
        .watch(usageMeterProvider)
        .snapshot(kHadiPackageLimits[pkg]!);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: Text(
          '${snap.label} · ${kHadiPackageLabels[pkg]} package. The built-in '
          'library never runs out.',
          key: const Key('hadi-usage-line'),
          textAlign: TextAlign.center,
          style: AppText.bodyMuted.copyWith(
            fontSize: 12,
            color: snap.canUse ? AppColors.textFaint : AppColors.gold,
          ),
        ),
      ),
    );
  }
}
