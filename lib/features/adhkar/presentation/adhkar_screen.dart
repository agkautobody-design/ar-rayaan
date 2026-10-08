import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/speak_button.dart';
import '../application/adhkar_providers.dart';
import '../domain/adhkar_models.dart';

/// Dhikr & Du'a — Hisn al-Muslim sets with tap-to-count repetitions and
/// daily-resetting progress. Pending Founder approval.
class AdhkarScreen extends ConsumerStatefulWidget {
  const AdhkarScreen({super.key});

  @override
  ConsumerState<AdhkarScreen> createState() => _AdhkarScreenState();
}

class _AdhkarScreenState extends ConsumerState<AdhkarScreen> {
  String _selectedSet = 'morning';

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<AdhkarSet>> sets = ref.watch(adhkarSetsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Dhikr & Du\'a'),
            Expanded(
              child: sets.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
                error: (Object e, _) => Center(
                  child: Text(
                    'The adhkar could not be loaded.',
                    style: AppText.bodyMuted,
                  ),
                ),
                data: (List<AdhkarSet> data) {
                  final AdhkarSet set = data.firstWhere(
                    (s) => s.id == _selectedSet,
                    orElse: () => data.first,
                  );
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      _SetPicker(
                        sets: data,
                        selected: set.id,
                        onSelect: (id) => setState(() => _selectedSet = id),
                      ),
                      const SizedBox(height: 16),
                      _ProgressCard(set: set),
                      const SizedBox(height: 16),
                      GlassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            for (int i = 0; i < set.items.length; i++) ...[
                              if (i > 0)
                                Divider(
                                  height: 24,
                                  color: AppColors.gold.withValues(alpha: 0.1),
                                ),
                              _DhikrCard(set: set, dhikr: set.items[i]),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'SOURCE: HISN AL-MUSLIM · PROGRESS RESETS DAILY',
                        style: AppText.eyebrow.copyWith(
                          fontSize: 8,
                          color: AppColors.gold.withValues(alpha: 0.4),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetPicker extends StatelessWidget {
  const _SetPicker({
    required this.sets,
    required this.selected,
    required this.onSelect,
  });

  final List<AdhkarSet> sets;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < sets.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => onSelect(sets[i].id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 11),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: sets[i].id == selected
                      ? AppColors.gold.withValues(alpha: 0.16)
                      : Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: sets[i].id == selected
                        ? AppColors.gold.withValues(alpha: 0.55)
                        : Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  sets[i].titleEn,
                  style: AppText.caption.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: sets[i].id == selected
                        ? AppColors.goldLight
                        : AppColors.sand.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ProgressCard extends ConsumerWidget {
  const _ProgressCard({required this.set});

  final AdhkarSet set;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(adhkarProgressProvider);
    final int done = ref
        .read(adhkarProgressProvider.notifier)
        .completedInSet(set);
    final int total = set.totalRepetitions;
    final double ratio = total == 0 ? 0 : done / total;
    final bool complete = done >= total && total > 0;

    return GlassCard(
      strong: true,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: ratio,
                  strokeWidth: 3.5,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                ),
                if (complete)
                  const Icon(Icons.check, color: AppColors.gold, size: 18)
                else
                  Text(
                    '${(ratio * 100).round()}%',
                    style: AppText.caption.copyWith(
                      fontSize: 10,
                      color: AppColors.goldLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  set.titleEn,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  complete
                      ? 'Complete — may Allah accept it'
                      : '$done of $total repetitions · ${total - done} remaining',
                  style: AppText.bodyMuted.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          if (done > 0 && !complete)
            TextButton(
              onPressed: () =>
                  ref.read(adhkarProgressProvider.notifier).resetSet(set.id),
              child: Text(
                'Reset',
                style: AppText.caption.copyWith(
                  color: AppColors.goldLight,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DhikrCard extends ConsumerWidget {
  const _DhikrCard({required this.set, required this.dhikr});

  final AdhkarSet set;
  final Dhikr dhikr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(adhkarProgressProvider);
    final int done = ref
        .read(adhkarProgressProvider.notifier)
        .doneFor(set.id, dhikr.number);
    final bool complete = done >= dhikr.count;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  dhikr.arabic,
                  style: AppText.arabicLarge.copyWith(
                    fontSize: 18,
                    height: 2.0,
                    color: complete
                        ? AppColors.sand.withValues(alpha: 0.45)
                        : AppColors.sand,
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 8),
                if (dhikr.translation != null) ...[
                  Text(
                    dhikr.translation!,
                    style: AppText.bodyMuted.copyWith(
                      fontSize: 12,
                      height: 1.55,
                      color: complete
                          ? AppColors.sand.withValues(alpha: 0.35)
                          : AppColors.sand.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (dhikr.translation != null)
                      SpeakButton(text: dhikr.translation!, size: 24)
                    else
                      const SizedBox.shrink(),
                    Text(
                      complete
                          ? 'Completed'
                          : '${dhikr.count} ${dhikr.count == 1 ? 'repetition' : 'repetitions'}',
                      style: AppText.bodyMuted.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Tap-to-count button
          GestureDetector(
            onTap: complete
                ? null
                : () => ref
                      .read(adhkarProgressProvider.notifier)
                      .increment(set.id, dhikr.number, dhikr.count),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: complete
                    ? AppColors.gold.withValues(alpha: 0.18)
                    : AppColors.gold.withValues(alpha: 0.08),
                border: Border.all(
                  color: complete
                      ? AppColors.gold
                      : AppColors.gold.withValues(alpha: 0.35),
                  width: complete ? 1.6 : 1,
                ),
              ),
              child: complete
                  ? const Icon(Icons.check, color: AppColors.gold, size: 20)
                  : Text(
                      '${dhikr.count - done}',
                      key: Key('dhikr-${set.id}-${dhikr.number}-remaining'),
                      style: AppText.titleMedium.copyWith(
                        color: AppColors.goldLight,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
