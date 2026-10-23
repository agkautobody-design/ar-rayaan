import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/core/content_loader.dart' show kQuranSizeHint;
import '../../../app/theme/widgets/content_loading_view.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/needs_internet_view.dart';
import '../../../app/theme/widgets/screen_header.dart';

import 'package:url_launcher/url_launcher.dart';

import '../application/quran_providers.dart';
import '../domain/quran_texts.dart';
import '../domain/quran_models.dart';
import '../domain/surah_search.dart';
import '../../../app/theme/widgets/whole_word_text.dart';
import 'quran_offline_card.dart';

/// Qur'an index — all 114 surahs + Continue Reading banner.
/// New screen designed within the locked system — pending Founder approval.
class QuranScreen extends ConsumerStatefulWidget {
  const QuranScreen({super.key});

  @override
  ConsumerState<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends ConsumerState<QuranScreen> {
  String _query = '';
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<SurahMeta>> index = ref.watch(quranIndexProvider);
    final ReadingPosition? position = ref.watch(readingPositionProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Qur\'an'),
            Expanded(
              child: index.when(
                // A retry must show the loading state again (not freeze on
                // the old error), so the person sees it is working.
                skipLoadingOnRefresh: false,
                loading: () => ContentLoadingView(
                  what: 'the Qur\u2019an',
                  sizeHint: kQuranSizeHint,
                  onRetry: () {
                    ref.invalidate(quranRepositoryProvider);
                    ref.invalidate(quranAllProvider);
                    ref.invalidate(quranIndexProvider);
                  },
                ),
                error: (Object e, _) => NeedsInternetView(
                  what: 'The Qur\u2019an',
                  onRetry: () {
                    ref.invalidate(quranRepositoryProvider);
                    ref.invalidate(quranAllProvider);
                    ref.invalidate(quranIndexProvider);
                  },
                ),
                data: (List<SurahMeta> surahs) {
                  final List<SurahMeta> shown = filterSurahs(surahs, _query);
                  final bool searching = _query.trim().isNotEmpty;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      TextField(
                        style: AppText.body,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Find a surah: name, meaning or number',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.gold,
                          ),
                          suffixIcon: searching
                              ? IconButton(
                                  tooltip: 'Clear search',
                                  icon: const Icon(
                                    Icons.close,
                                    color: AppColors.gold,
                                  ),
                                  onPressed: () {
                                    _controller.clear();
                                    setState(() => _query = '');
                                  },
                                )
                              : null,
                        ),
                        controller: _controller,
                        onChanged: (String v) => setState(() => _query = v),
                      ),
                      const SizedBox(height: 12),
                      // Web only, and only until the Qur'an is saved here.
                      if (!searching) ...[
                        const QuranOfflineCard(compact: true),
                        const SizedBox(height: 12),
                      ],
                      if (!searching) ...[
                        _AyatAlKursiShortcut(
                          onTap: () => context.open(
                            AppRoutes.surahAt(
                              kAyatAlKursiSurah,
                              kAyatAlKursiAyah,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (position != null && !searching) ...[
                        _ContinueBanner(position: position, surahs: surahs),
                        const SizedBox(height: 16),
                      ],
                      Semantics(
                        button: true,
                        label: 'My bookmarks, collections and notes',
                        child: GlassCard(
                          onTap: () => context.push(AppRoutes.quranBookmarks),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                Icons.bookmarks_outlined,
                                color: AppColors.gold,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: WholeWordText(
                                  'Bookmarks, collections & notes',
                                  style: AppText.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: AppColors.gold.withValues(alpha: 0.6),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (shown.isEmpty)
                        GlassCard(
                          child: Text(
                            'No surah matches \u201c${_query.trim()}\u201d. Try '
                            'a name like Yasin, a meaning like Cow, or a '
                            'number from 1 to 114.',
                            style: AppText.bodyMuted.copyWith(height: 1.5),
                          ),
                        )
                      else
                        // 114 rows under one card: no backdrop blur (one huge
                        // blurred layer), same translucent fill and border.
                        GlassCard(
                          blur: false,
                          padding: EdgeInsets.zero,
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: shown.length,
                            separatorBuilder: (_, _) => Divider(
                              height: 1,
                              color: AppColors.gold.withValues(alpha: 0.1),
                              indent: 66,
                            ),
                            itemBuilder: (context, i) =>
                                _SurahRow(meta: shown[i]),
                          ),
                        ),
                      const SizedBox(height: 24),
                      const _TextCredit(),
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

/// Credit and link for the two bundled texts (Tanzil requires its source to
/// be named and linked).
class _TextCredit extends ConsumerWidget {
  const _TextCredit();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuranTexts texts =
        ref.watch(quranTextsProvider).value ?? QuranTexts.fallback;
    return Semantics(
      link: true,
      label: 'Arabic text and translation source: Tanzil.net',
      child: InkWell(
        onTap: () async {
          try {
            await launchUrl(
              Uri.parse(texts.arabic.url),
              mode: LaunchMode.externalApplication,
            );
          } catch (_) {}
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(
            child: Text(
              'Arabic: Tanzil Uthmani · Translation: Saheeh International, '
              'via Tanzil.net',
              style: AppText.caption.copyWith(
                decoration: TextDecoration.underline,
              ),
              textAlign: TextAlign.center,
            ),
          ),
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
      onTap: () => context.open(AppRoutes.surah(position.surah)),
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
                  style: AppText.eyebrow.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Surah ${meta.transliteration} · Ayah ${position.ayah}',
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
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
        onTap: () => context.open(AppRoutes.surah(meta.number)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.35),
                    ),
                    color: AppColors.gold.withValues(alpha: 0.08),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${meta.number}',
                      style: AppText.caption.copyWith(
                        color: AppColors.goldLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // The name may wrap to two lines (large text, narrow
                      // phones) instead of being cut to "A...".
                      Text(
                        meta.transliteration,
                        style: AppText.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${meta.englishMeaning} · '
                        '${meta.isMeccan ? 'Meccan' : 'Medinan'} · '
                        '${meta.ayahCount} ayahs',
                        style: AppText.bodyMuted.copyWith(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Never lets the Arabic name squeeze the Latin name.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 96),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      meta.arabicName,
                      style: AppText.arabicLarge.copyWith(
                        fontSize: 20,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One-tap way to Ayat al-Kursi (2:255), opened at that ayah.
class _AyatAlKursiShortcut extends StatelessWidget {
  const _AyatAlKursiShortcut({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ayat al-Kursi, Al-Baqarah 2:255',
      excludeSemantics: true,
      onTap: onTap,
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.auto_stories_outlined,
              color: AppColors.gold,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ayat al-Kursi · 2:255',
                style: AppText.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.gold.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
