import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../academy/application/academy_providers.dart';
import '../../academy/presentation/verse_range_player_bar.dart';

import '../../../app/core/sound/sound_services.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../application/quran_providers.dart';
import '../domain/quran_models.dart';

/// Surah reader — Arabic (Amiri) with gold ayah medallions + translation.
/// Tapping an ayah saves the Continue-Reading position.
class SurahReaderScreen extends ConsumerStatefulWidget {
  const SurahReaderScreen({required this.number, super.key});

  final int number;

  static const String _bismillah = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';

  static const List<String> _arabicIndic = <String>[
    '٠',
    '١',
    '٢',
    '٣',
    '٤',
    '٥',
    '٦',
    '٧',
    '٨',
    '٩',
  ];

  static String toArabicIndic(int n) {
    return n.toString().split('').map((c) => _arabicIndic[int.parse(c)]).join();
  }

  @override
  ConsumerState<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends ConsumerState<SurahReaderScreen> {
  @override
  void initState() {
    super.initState();
    // Record that this surah was opened (Continue Reading → ayah 1 unless
    // the user taps deeper).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ReadingPosition? current = ref.read(readingPositionProvider);
      if (current?.surah != widget.number) {
        ref
            .read(readingPositionProvider.notifier)
            .save(ReadingPosition(surah: widget.number, ayah: 1));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Surah> surah = ref.watch(surahProvider(widget.number));

    return ScenicScaffold.pattern(
      body: SafeArea(
        child: Column(
          children: [
            surah.maybeWhen(
              data: (Surah s) => ScreenHeader(title: s.meta.transliteration),
              orElse: () => const ScreenHeader(title: 'Qur\'an'),
            ),
            // Madinah page mode — visible only when the checksum-verified
            // layout pack has shipped (provider returns null otherwise).
            Consumer(
              builder: (context, ref, _) {
                return ref.watch(mushafLayoutProvider).maybeWhen(
                  data: (pages) => pages == null
                      ? const SizedBox.shrink()
                      : Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              final int? ayahCount = ref
                                  .read(surahProvider(widget.number))
                                  .value
                                  ?.meta
                                  .ayahCount;
                              if (ayahCount == null) return;
                              context.go(
                                '/quran/madinah/${widget.number}/$ayahCount',
                              );
                            },
                            icon: const Icon(
                              Icons.auto_awesome_motion,
                              color: AppColors.gold,
                              size: 18,
                            ),
                            label: Text(
                              'Madinah page view',
                              style: AppText.caption
                                  .copyWith(color: AppColors.gold),
                            ),
                          ),
                        ),
                  orElse: () => const SizedBox.shrink(),
                );
              },
            ),
            Expanded(
              child: surah.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
                error: (Object e, _) => Center(
                  child: Text(
                    'This surah could not be loaded.',
                    style: AppText.bodyMuted,
                  ),
                ),
                data: (Surah s) => _Reader(surah: s),
              ),
            ),
            Consumer(
              builder: (context, ref, _) {
                final int? ayahCount = ref
                    .watch(surahProvider(widget.number))
                    .value
                    ?.meta
                    .ayahCount;
                if (ayahCount == null) return const SizedBox.shrink();
                return VerseRangePlayerBar(
                  surah: widget.number,
                  ayahCount: ayahCount,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Reader extends ConsumerWidget {
  const _Reader({required this.surah});

  final Surah surah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool showBismillah = surah.meta.number != 1 && surah.meta.number != 9;
    final ReadingPosition? position = ref.watch(readingPositionProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        // Surah heading
        GlassCard(
          strong: true,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            children: [
              Text(
                'سُورَةُ ${surah.meta.arabicName}',
                style: AppText.arabicLarge.copyWith(fontSize: 26, height: 1.6),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 6),
              Text(
                '${surah.meta.englishMeaning} · '
                '${surah.meta.isMeccan ? 'Meccan' : 'Medinan'} · '
                '${surah.meta.ayahCount} ayahs',
                style: AppText.bodyMuted.copyWith(fontSize: 11),
                textAlign: TextAlign.center,
              ),
              if (showBismillah) ...[
                const SizedBox(height: 14),
                Divider(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  indent: 40,
                  endIndent: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  SurahReaderScreen._bismillah,
                  style: AppText.arabicLarge.copyWith(
                    fontSize: 22,
                    height: 1.7,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Ayahs
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              for (int i = 0; i < surah.ayahs.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 24,
                    color: AppColors.gold.withValues(alpha: 0.1),
                  ),
                _AyahBlock(
                  ayah: surah.ayahs[i],
                  surahNumber: surah.meta.number,
                  isBookmarked:
                      position?.surah == surah.meta.number &&
                      position?.ayah == surah.ayahs[i].number,
                  onTap: () {
                    ref
                        .read(readingPositionProvider.notifier)
                        .save(
                          ReadingPosition(
                            surah: surah.meta.number,
                            ayah: surah.ayahs[i].number,
                          ),
                        );
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'TAP AN AYAH TO SAVE YOUR PLACE',
          style: AppText.eyebrow.copyWith(
            fontSize: 8,
            color: AppColors.gold.withValues(alpha: 0.4),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _AyahBlock extends ConsumerWidget {
  const _AyahBlock({
    required this.ayah,
    required this.surahNumber,
    required this.isBookmarked,
    required this.onTap,
  });

  final Ayah ayah;
  final int surahNumber;
  final bool isBookmarked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RecitationState rec = ref.watch(recitationServiceProvider);
    final bool playing = rec.surah == surahNumber && rec.ayah == ayah.number;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isBookmarked
              ? AppColors.gold.withValues(alpha: 0.08)
              : Colors.transparent,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Arabic with end-of-ayah medallion
            RichText(
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              text: TextSpan(
                style: AppText.arabicLarge.copyWith(fontSize: 21, height: 2.0),
                children: [
                  TextSpan(text: ayah.arabic),
                  TextSpan(
                    text: ' ﴿${SurahReaderScreen.toArabicIndic(ayah.number)}﴾',
                    style: TextStyle(
                      color: AppColors.gold.withValues(alpha: 0.9),
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    ayah.english,
                    style: AppText.bodyMuted.copyWith(
                      fontSize: 12.5,
                      height: 1.55,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => ref
                      .read(recitationServiceProvider.notifier)
                      .toggle(surahNumber, ayah.number),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Icon(
                      playing
                          ? Icons.stop_circle_outlined
                          : Icons.play_circle_outline,
                      size: 17,
                      color: AppColors.gold.withValues(
                        alpha: playing ? 1.0 : 0.55,
                      ),
                    ),
                  ),
                ),
                if (isBookmarked)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Icon(
                      Icons.bookmark,
                      size: 14,
                      color: AppColors.gold.withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
