import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../application/quran_providers.dart';
import '../domain/quran_models.dart';

/// Qur'an index — all 114 surahs + Continue Reading banner.
/// New screen designed within the locked system — pending Founder approval.
class QuranScreen extends ConsumerWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<SurahMeta>> index = ref.watch(quranIndexProvider);
    final ReadingPosition? position = ref.watch(readingPositionProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Qur\'an'),
            Expanded(
              child: index.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
                error: (Object e, _) => Center(
                  child: Text(
                    'The Qur\'an could not be loaded.',
                    style: AppText.bodyMuted,
                  ),
                ),
                data: (List<SurahMeta> surahs) => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    if (position != null) ...[
                      _ContinueBanner(position: position, surahs: surahs),
                      const SizedBox(height: 16),
                    ],
                    GlassCard(
                      padding: EdgeInsets.zero,
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: surahs.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: AppColors.gold.withValues(alpha: 0.1),
                          indent: 66,
                        ),
                        itemBuilder: (context, i) => _SurahRow(meta: surahs[i]),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'ARABIC: TANZIL · TRANSLATION: SAHEEH INTERNATIONAL',
                      style: AppText.eyebrow.copyWith(
                        fontSize: 8,
                        color: AppColors.gold.withValues(alpha: 0.4),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueBanner extends StatelessWidget {
  const _ContinueBanner({required this.position, required this.surahs});

  final ReadingPosition position;
  final List<SurahMeta> surahs;

  @override
  Widget build(BuildContext context) {
    final SurahMeta meta = surahs[position.surah - 1];
    return GlassCard(
      strong: true,
      onTap: () => context.go(AppRoutes.surah(position.surah)),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: 0.15),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
            ),
            child: const Icon(
              Icons.play_arrow,
              color: AppColors.gold,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONTINUE READING',
                  style: AppText.eyebrow.copyWith(fontSize: 8),
                ),
                const SizedBox(height: 4),
                Text(
                  'Surah ${meta.transliteration} · Ayah ${position.ayah}',
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 18,
            color: AppColors.gold.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}

class _SurahRow extends StatelessWidget {
  const _SurahRow({required this.meta});

  final SurahMeta meta;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => context.go(AppRoutes.surah(meta.number)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.35),
                  ),
                  color: AppColors.gold.withValues(alpha: 0.08),
                ),
                child: Text(
                  '${meta.number}',
                  style: AppText.caption.copyWith(
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta.transliteration,
                      style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${meta.englishMeaning} · ${meta.isMeccan ? 'Meccan' : 'Medinan'} · ${meta.ayahCount} ayahs',
                      style: AppText.bodyMuted.copyWith(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                meta.arabicName,
                style: AppText.arabicLarge.copyWith(fontSize: 20, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
