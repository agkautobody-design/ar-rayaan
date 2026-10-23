import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
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
    // Re-evaluates which dhikr is next (it gets the big counter) on every tap.
    ref.watch(adhkarProgressProvider);

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
                  // The first dhikr not yet finished is the one to do next: its
                  // counter is the big one-thumb tap area.
                  int nextOpen = -1;
                  for (int i = 0; i < set.items.length; i++) {
                    final Dhikr d = set.items[i];
                    if (ref
                            .read(adhkarProgressProvider.notifier)
                            .doneFor(set.id, d.number) <
                        d.count) {
                      nextOpen = i;
                      break;
                    }
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      _SetPicker(
                        sets: data,
                        selected: set.id,
                        onSelect: (id) => setState(() => _selectedSet = id),
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          onPressed: () => context.open(AppRoutes.tasbeeh),
                          icon: const Icon(Icons.touch_app_outlined, size: 18),
                          label: const Text('Plain counter'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ProgressCard(set: set),
                      const SizedBox(height: 16),
                      GlassCard(
                        blur: false,
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
                              _DhikrCard(
                                set: set,
                                dhikr: set.items[i],
                                big: i == nextOpen,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'SOURCE: HISN AL-MUSLIM · PROGRESS RESETS DAILY',
                        style: AppText.eyebrow.copyWith(
                          fontSize: 12,
                          color: AppColors.gold.withValues(alpha: 0.9),
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
            child: Semantics(
              button: true,
              selected: sets[i].id == selected,
              child: GestureDetector(
              onTap: () => onSelect(sets[i].id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                constraints: const BoxConstraints(minHeight: 48),
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
                    fontSize: 12,
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
                      fontSize: 12,
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
                  style: AppText.bodyMuted.copyWith(fontSize: 12),
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
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DhikrCard extends ConsumerWidget {
  const _DhikrCard({
    required this.set,
    required this.dhikr,
    this.big = false,
  });

  final AdhkarSet set;
  final Dhikr dhikr;

  /// The dhikr to do next: its counter is a large tap area (160 dp circle)
  /// under the text instead of the small circle beside it.
  final bool big;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(adhkarProgressProvider);
    final int done = ref
        .read(adhkarProgressProvider.notifier)
        .doneFor(set.id, dhikr.number);
    final bool complete = done >= dhikr.count;
    final bool bigCounter = big && !complete;

    final Widget details = Column(
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
        if (dhikr.source != null) ...[
          Text(
            'Source: ${dhikr.source!}',
            key: Key('dhikr-${set.id}-${dhikr.number}-source'),
            style: AppText.bodyMuted.copyWith(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.gold.withValues(alpha: 0.9),
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
              style: AppText.bodyMuted.copyWith(fontSize: 12),
            ),
          ],
        ),
      ],
    );

    // Tap-to-count button. The whole circle is the tap area.
    final double size = bigCounter ? 160 : 52;
    final Widget counter = Semantics(
      button: true,
      label: complete
          ? 'Dhikr ${dhikr.number} complete'
          : 'Count dhikr ${dhikr.number}, ${dhikr.count - done} left',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: complete
            ? null
            : () => ref
                  .read(adhkarProgressProvider.notifier)
                  .increment(set.id, dhikr.number, dhikr.count),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: complete
                ? AppColors.gold.withValues(alpha: 0.18)
                : AppColors.gold.withValues(alpha: bigCounter ? 0.14 : 0.08),
            border: Border.all(
              color: complete
                  ? AppColors.gold
                  : AppColors.gold.withValues(alpha: 0.35),
              width: complete ? 1.6 : 1,
            ),
          ),
          child: complete
              ? const Icon(Icons.check, color: AppColors.gold, size: 20)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${dhikr.count - done}',
                      key: Key('dhikr-${set.id}-${dhikr.number}-remaining'),
                      style: AppText.titleMedium.copyWith(
                        color: AppColors.goldLight,
                        fontSize: bigCounter ? 44 : 16,
                      ),
                    ),
                    if (bigCounter)
                      Text(
                        'tap to count',
                        style: AppText.bodyMuted.copyWith(fontSize: 12),
                      ),
                  ],
                ),
        ),
      ),
    );

    if (bigCounter) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [details, const SizedBox(height: 14), Center(child: counter)],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: details),
          const SizedBox(width: 12),
          counter,
        ],
      ),
    );
  }
}
