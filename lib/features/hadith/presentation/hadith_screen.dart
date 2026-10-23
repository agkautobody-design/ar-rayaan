import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/speak_button.dart';
import '../../share/application/share_text.dart';
import '../../share/presentation/share_actions.dart';
import '../application/hadith_providers.dart';
import '../domain/hadith_models.dart';
import 'daily_hadith_card.dart';

/// Hadith — the Forty Hadith of Imam an-Nawawi (bundled, offline).
/// New screen designed within the locked system — pending Founder approval.
class HadithScreen extends ConsumerStatefulWidget {
  const HadithScreen({super.key, this.initialNumber});

  /// Scroll to this hadith on arrival (from a search result).
  final int? initialNumber;

  @override
  ConsumerState<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends ConsumerState<HadithScreen> {
  final GlobalKey _target = GlobalKey();
  bool _scrolled = false;

  void _scrollToTarget() {
    if (_scrolled || widget.initialNumber == null) return;
    _scrolled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? c = _target.currentContext;
      if (!mounted || c == null) return;
      Scrollable.ensureVisible(
        c,
        duration: const Duration(milliseconds: 300),
        alignment: 0.05,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Hadith>> collection = ref.watch(
      hadithCollectionProvider,
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Hadith'),
            Expanded(
              child: collection.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
                error: (Object e, _) => Center(
                  child: Text(
                    'The collection could not be loaded.',
                    style: AppText.bodyMuted,
                  ),
                ),
                data: (List<Hadith> hadiths) {
                  _scrollToTarget();
                  return ListView(
                  // Build the whole list when opened at a hadith, so the
                  // target exists to scroll to.
                  cacheExtent: widget.initialNumber == null ? null : 100000,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    const DailyHadithHero(),
                    const SizedBox(height: 16),
                    const FeelingCheckInCard(),
                    const SizedBox(height: 16),
                    // Collection heading
                    GlassCard(
                      strong: true,
                      padding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 16,
                      ),
                      child: Column(
                        children: [
                          Text(
                            'الأربعون النووية',
                            style: AppText.arabicLarge.copyWith(
                              fontSize: 24,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'The Forty Hadith of Imam an-Nawawi · ${hadiths.length} hadiths',
                            style: AppText.bodyMuted.copyWith(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      blur: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        children: [
                          for (int i = 0; i < hadiths.length; i++) ...[
                            if (i > 0)
                              Divider(
                                height: 28,
                                color: AppColors.gold.withValues(alpha: 0.1),
                              ),
                            _HadithBlock(
                              key: hadiths[i].number == widget.initialNumber
                                  ? _target
                                  : null,
                              hadith: hadiths[i],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Founder-approved hadith sources: the six canonical collections.
                    GlassCard(
                      onTap: () => context.push(AppRoutes.sources),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OUR HADITH SOURCES · THE SIX COLLECTIONS',
                            style: AppText.eyebrow.copyWith(fontSize: 12),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Sahih al-Bukhari · Sahih Muslim · Sunan Abu Dawood · '
                            'Jami’ al-Tirmidhi · Sunan an-Nasa’i · Sunan Ibn Majah',
                            style: AppText.body.copyWith(
                              fontSize: 12.5,
                              height: 1.6,
                              color: AppColors.sand.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'The six canonical collections (al-Kutub as-Sittah); not every '
                            'report in them is sahih. Tap to see all our sources.',
                            style: AppText.bodyMuted.copyWith(
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'SOURCE: FAWAZAHMED0 HADITH-API · ARABIC + ENGLISH\n'
                      'GRADES: AS STATED BY THE NAMED GRADER ON EACH HADITH',
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

/// One of the Forty Hadith as plain text: Arabic, English, its source line
/// (with grade and grader where it has one) and the app credit.
String hadithShareText(Hadith hadith) => composeShareText(
      title: 'Hadith ${hadith.number}, The Forty Hadith of Imam an-Nawawi',
      arabic: hadith.arabic,
      body: hadith.english,
      source: hadith.sourceLine ?? 'The Forty Hadith of Imam an-Nawawi',
    );

class _HadithBlock extends StatelessWidget {
  const _HadithBlock({super.key, required this.hadith});

  final Hadith hadith;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.4),
                  ),
                  color: AppColors.gold.withValues(alpha: 0.1),
                ),
                child: Text(
                  '${hadith.number}',
                  style: AppText.caption.copyWith(
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'HADITH ${hadith.number}',
                style: AppText.eyebrow.copyWith(fontSize: 12),
              ),
            ],
          ),
          if (hadith.sourceLine != null) ...[
            const SizedBox(height: 8),
            Text(
              hadith.sourceLine!.toUpperCase(),
              key: ValueKey<String>('hadith-grade-${hadith.number}'),
              style: AppText.eyebrow.copyWith(
                fontSize: 12,
                color: AppColors.gold.withValues(alpha: 0.9),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            hadith.arabic,
            style: AppText.arabicLarge.copyWith(fontSize: 19, height: 2.0),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 10),
          Text(
            hadith.english,
            style: AppText.bodyMuted.copyWith(fontSize: 12.5, height: 1.6),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShareCopyButtons(
                  text: hadithShareText(hadith),
                  title: 'Hadith ${hadith.number}',
                  subject: 'hadith ${hadith.number}',
                ),
                SpeakButton(
                  text: 'Hadith ${hadith.number}. ${hadith.english}',
                  size: 26,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
