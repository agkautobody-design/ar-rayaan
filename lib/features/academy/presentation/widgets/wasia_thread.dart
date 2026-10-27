import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/widgets/speak_button.dart';
import '../../../sakina/presentation/widgets/need_help_button.dart';
import '../../application/wasia_controller.dart';

/// The shared Wasia conversation thread — every chat box renders the same
/// brain, so a question in the lessons and a follow-up in the exam hall are
/// one continuing conversation.
class WasiaThread extends ConsumerWidget {
  const WasiaThread({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(wasiaControllerProvider);
    if (s.messages.isEmpty && s.notice == null) {
      return const SizedBox.shrink();
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text('CONVERSATION', style: AppText.eyebrow)),
        GestureDetector(
          onTap: () => ref.read(wasiaControllerProvider.notifier).clear(),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.restart_alt, size: 15, color: AppColors.gold),
          ),
        ),
      ]),
      const SizedBox(height: 6),
      for (final m in s.messages)
        Align(
          alignment: m.fromHadi ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            constraints: const BoxConstraints(maxWidth: 300),
            decoration: BoxDecoration(
              color: m.fromHadi
                  ? AppColors.sand.withValues(alpha: 0.08)
                  : AppColors.gold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.18)),
            ),
            child: m.fromHadi
                ? Row(mainAxisSize: MainAxisSize.min, children: [
                    Flexible(
                        child: Text(m.text,
                            style: AppText.body
                                .copyWith(fontSize: 13, height: 1.5))),
                    const SizedBox(width: 6),
                    SpeakButton(
                      text: m.text,
                      size: 18,
                      minTapTarget: SpeakButton.minTarget,
                    ),
                  ])
                : Text(m.text,
                    style: AppText.bodyMuted
                        .copyWith(fontSize: 13, height: 1.4)),
          ),
        ),
      if (s.messages.isNotEmpty &&
          s.messages.last.fromHadi &&
          s.messages.last.crisis != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            // Help lines inside Wasia itself: Sakina is closed to a child.
            child: NeedHelpNowButton(
              key: const Key('wasia-help-lines'),
              kind: s.messages.last.crisis!,
              label: 'Show help lines',
              showSakinaLink: false,
            ),
          ),
        ),
      if (s.notice != null)
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(s.notice!,
              key: const Key('wasia-notice'),
              style: AppText.bodyMuted.copyWith(fontSize: 13, height: 1.45)),
        ),
      if (s.isLoading && s.messages.isNotEmpty && !s.messages.last.fromHadi)
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text('Wasia is thinking\u2026',
              style: AppText.bodyMuted
                  .copyWith(fontSize: 12, fontStyle: FontStyle.italic)),
        ),
    ]);
  }
}
