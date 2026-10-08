import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/speak_button.dart';
import '../application/feeling_providers.dart';
import '../domain/daily_hadith.dart';

/// "Today's Hadith" hero + Feeling Check-in — the top of the Hadith screen,
/// following the locked design rhythm: hero → Ask-Hādi row → daily content.
class DailyHadithHero extends ConsumerWidget {
  const DailyHadithHero({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DailyHadith hadith = ref.watch(todaysHadithProvider);
    final Set<String> saved = ref.watch(savedDailyHadithsProvider);
    final bool isSaved = saved.contains(hadith.text);

    return GlassCard(
      strong: true,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 14,
                color: AppColors.gold.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 6),
              Text(
                "TODAY'S HADITH",
                style: AppText.eyebrow.copyWith(color: AppColors.gold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '“${hadith.text}”',
            style: AppText.body.copyWith(
              fontSize: 15,
              height: 1.6,
              color: AppColors.sand,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '— Narrated by ${hadith.narrator}',
            style: AppText.caption.copyWith(
              color: AppColors.sand.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hadith.source,
            style: AppText.eyebrow.copyWith(
              fontSize: 9,
              color: AppColors.gold.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SpeakButton(text: 'Today’s hadith. ${hadith.text}', size: 30),
              const Spacer(),
              _HeroAction(
                icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                label: isSaved ? 'Saved' : 'Save',
                onTap: () => ref
                    .read(savedDailyHadithsProvider.notifier)
                    .toggle(hadith.text),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.gold),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppText.caption.copyWith(color: AppColors.gold),
            ),
          ],
        ),
      ),
    );
  }
}

/// "How does your heart feel today?" — the 10-feeling wheel. Tapping a
/// feeling reveals today's sourced response for it. No judgment, ever.
class FeelingCheckInCard extends ConsumerWidget {
  const FeelingCheckInCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? checkedIn = ref.watch(feelingCheckInProvider);

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOW DOES YOUR HEART FEEL TODAY?',
            style: AppText.eyebrow.copyWith(color: AppColors.gold),
          ),
          const SizedBox(height: 4),
          Text(
            checkedIn == null
                ? 'Whatever it is — there is a word for it here.'
                : 'A word for your heart, from the sources.',
            style: AppText.caption,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final Feeling f in MoodMap.feelings)
                _FeelingChip(feeling: f, selected: checkedIn == f.id),
            ],
          ),
          if (checkedIn != null) ...[
            const SizedBox(height: 14),
            _FeelingResponseView(feelingId: checkedIn),
          ],
        ],
      ),
    );
  }
}

class _FeelingChip extends ConsumerWidget {
  const _FeelingChip({required this.feeling, required this.selected});

  final Feeling feeling;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () =>
          ref.read(feelingCheckInProvider.notifier).checkIn(feeling.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.gold
                : AppColors.gold.withValues(alpha: 0.25),
          ),
          color: selected
              ? AppColors.gold.withValues(alpha: 0.15)
              : AppColors.glassFill,
        ),
        child: Text(
          '${feeling.emoji}  ${feeling.label}',
          style: AppText.caption.copyWith(
            color: selected
                ? AppColors.gold
                : AppColors.sand.withValues(alpha: 0.85),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _FeelingResponseView extends StatelessWidget {
  const _FeelingResponseView({required this.feelingId});

  final String feelingId;

  @override
  Widget build(BuildContext context) {
    final FeelingResponse r = MoodMap.responseFor(feelingId, DateTime.now());
    final Feeling f = MoodMap.byId(feelingId);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
        color: AppColors.gold.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${f.emoji}  FOR THE ${f.label.toUpperCase()} HEART · ${r.kind.toUpperCase()}',
            style: AppText.eyebrow.copyWith(
              fontSize: 8,
              color: AppColors.gold.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            r.text,
            style: AppText.body.copyWith(
              fontSize: 13.5,
              height: 1.6,
              color: AppColors.sand.withValues(alpha: 0.95),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            r.source,
            style: AppText.eyebrow.copyWith(
              fontSize: 8.5,
              color: AppColors.gold.withValues(alpha: 0.6),
            ),
          ),
          if (r.note != null) ...[
            const SizedBox(height: 6),
            Text(
              r.note!,
              style: AppText.caption.copyWith(
                color: AppColors.sand.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
