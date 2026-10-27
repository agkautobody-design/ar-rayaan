import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../application/habits_providers.dart';
import '../../../app/theme/widgets/focus_ring.dart';

/// "The Gentle Ledger" — Qada make-up counter + fasting log, shown on
/// My Journey. Tone per constitution: ledgers of return, never scoreboards.
class HabitsCard extends ConsumerWidget {
  const HabitsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, int> qada = ref.watch(qadaProvider);
    final int total = qada.values.fold(0, (int a, int b) => a + b);
    final FastingLogController fasting = ref.read(fastingLogProvider.notifier);
    ref.watch(fastingLogProvider);
    final bool fastedToday = fasting.fastedToday();
    final bool fastedYesterday = fasting.fastedYesterday();
    final int yearCount = fasting.thisYear();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 24, bottom: 8),
          child: Text('THE GENTLE LEDGER', style: AppText.eyebrow),
        ),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Qada — prayers to make up',
                      style: AppText.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    total == 0 ? 'All caught up 🤍' : '$total remaining',
                    style: AppText.caption.copyWith(
                      color: total == 0 ? AppColors.gold : AppColors.sand,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'One at a time. “The most beloved deeds are the most '
                'consistent, even if small.” (Bukhari 6464)',
                style: AppText.caption.copyWith(
                  height: 1.4,
                  color: AppColors.sand.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 10),
              for (final String prayer in QadaController.prayers)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 64,
                        child: Text(prayer, style: AppText.body),
                      ),
                      const Spacer(),
                      _StepperButton(
                        icon: Icons.remove,
                        onTap: () => ref
                            .read(qadaProvider.notifier)
                            .adjust(prayer, -1),
                      ),
                      SizedBox(
                        width: 44,
                        child: Text(
                          '${qada[prayer] ?? 0}',
                          style: AppText.label.copyWith(
                            color: AppColors.gold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      _StepperButton(
                        icon: Icons.add,
                        onTap: () => ref
                            .read(qadaProvider.notifier)
                            .adjust(prayer, 1),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _DhikrLedgerRow(),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fasting',
                      style: AppText.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$yearCount ${yearCount == 1 ? 'day' : 'days'} fasted '
                      'this year — every one written.',
                      style: AppText.caption.copyWith(
                        color: AppColors.sand.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                    ),
                    FocusRing(borderRadius: 12, child: InkWell(
                      onTap: () {
                        final DateTime n = DateTime.now();
                        fasting.toggleDate(DateTime(n.year, n.month, n.day - 1));
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          fastedYesterday
                              ? 'Yesterday: fasted ✓ (tap to undo)'
                              : 'I also fasted yesterday',
                          style: AppText.caption.copyWith(
                            color: AppColors.gold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    )),
                  ],
                ),
              ),
              FocusRing(borderRadius: 18, child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: fasting.toggleToday,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: fastedToday
                          ? AppColors.gold
                          : AppColors.gold.withValues(alpha: 0.3),
                    ),
                    color: fastedToday
                        ? AppColors.gold.withValues(alpha: 0.15)
                        : Colors.transparent,
                  ),
                  child: Text(
                    fastedToday ? 'Fasted today ✓' : 'I fasted today',
                    style: AppText.caption.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FocusRing(borderRadius: 12, child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
        ),
        child: Icon(icon, size: 14, color: AppColors.gold),
      ),
    ));
  }
}

/// Today's and this week's remembrances from the Dhikr School.
class _DhikrLedgerRow extends ConsumerWidget {
  const _DhikrLedgerRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(dhikrLedgerProvider);
    final DhikrLedgerController ledger = ref.read(dhikrLedgerProvider.notifier);
    final int today = ledger.today;
    final int week = ledger.lastSevenDays;
    if (week == 0) return const SizedBox.shrink();
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Dhikr',
              style: AppText.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '$today today · $week this week',
            style: AppText.caption.copyWith(color: AppColors.gold),
          ),
        ],
      ),
    );
  }
}
