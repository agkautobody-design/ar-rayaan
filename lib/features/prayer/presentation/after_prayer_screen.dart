import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/scholar_review.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../../adhkar/application/adhkar_providers.dart';
import '../../adhkar/domain/adhkar_models.dart';
import '../../reading/presentation/arabic_block.dart';

/// "After prayer": the remembrance said after the obligatory prayers, laid
/// out as one card per dhikr to read through (Arabic, reading, meaning,
/// source). It reads the same bundled `after-prayer` set the Dhikr counter
/// uses, so the text and sources live in one place; counting is one tap away.
class AfterPrayerScreen extends ConsumerWidget {
  const AfterPrayerScreen({super.key});

  static const String setId = 'after-prayer';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AdhkarSet>> sets = ref.watch(adhkarSetsProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const ScreenHeader(title: 'After Prayer'),
            const ScholarReviewNote(
              reviewKey: 'dua.adhkar',
              padding: EdgeInsets.only(bottom: 8),
            ),
            Expanded(
              child: sets.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
                error: (Object e, _) => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Could not load the remembrance. Try again.'),
                  ),
                ),
                data: (List<AdhkarSet> data) {
                  AdhkarSet? set;
                  for (final AdhkarSet s in data) {
                    if (s.id == setId) set = s;
                  }
                  if (set == null) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('This remembrance is not available.'),
                      ),
                    );
                  }
                  final AdhkarSet found = set;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    children: <Widget>[
                      Text(
                        'Said quietly after each obligatory prayer.',
                        textAlign: TextAlign.center,
                        style: AppText.bodyMuted.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      for (final Dhikr d in found.items)
                        _AfterPrayerCard(dhikr: d),
                      const SizedBox(height: 4),
                      Center(
                        child: TextButton.icon(
                          key: const Key('after-prayer-count'),
                          onPressed: () => context
                              .open('${AppRoutes.adhkar}?set=$setId'),
                          icon: const Icon(Icons.touch_app_outlined, size: 18),
                          label: const Text('Count them one by one'),
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.goldLight),
                        ),
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

class _AfterPrayerCard extends StatelessWidget {
  const _AfterPrayerCard({required this.dhikr});

  final Dhikr dhikr;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        blur: false,
        padding: const EdgeInsets.all(16),
        child: Column(
          key: Key('after-prayer-${dhikr.number}'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold),
                  ),
                  child: Text('${dhikr.number}',
                      style: AppText.label.copyWith(fontSize: 12)),
                ),
                const Spacer(),
                Text(
                  dhikr.count == 1 ? 'Once' : '× ${dhikr.count}',
                  style: AppText.label.copyWith(
                      fontSize: 13, color: AppColors.goldLight),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ArabicBlock(
              arabic: dhikr.arabic,
              translit: dhikr.transliteration,
              translitSource: dhikr.transliterationSource,
              meaning: dhikr.translation,
              arabicSize: 22,
            ),
            if (dhikr.source != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Source: ${dhikr.source!}',
                style: AppText.bodyMuted.copyWith(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.gold.withValues(alpha: 0.9),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
