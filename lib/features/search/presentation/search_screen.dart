import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/core/web_offline.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../adhkar/application/adhkar_providers.dart';
import '../../adhkar/domain/adhkar_models.dart';
import '../../hadith/application/hadith_providers.dart';
import '../../hadith/domain/hadith_models.dart';
import '../../quran/application/quran_providers.dart';
import '../../quran/domain/quran_models.dart';
import '../domain/quran_search.dart';
import '../../stories/data/stories_repository.dart';
import '../../stories/domain/story.dart';

/// FIND ANYTHING — one search across every shelf: the whole Qur'an
/// (Arabic and English, or a verse key like 2:255), the 11 story
/// packs (Prophets, Seerah, Khutbahs, Daily Duas, Modern Hadith…), the
/// Forty Hadith of an-Nawawi, and the Hisn al-Muslim adhkar.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchState();
}

class _Hit {
  const _Hit({
    required this.shelf,
    required this.title,
    required this.kicker,
    required this.icon,
    required this.open,
  });

  final String shelf;
  final String title;
  final String kicker;
  final IconData icon;
  final void Function() open;
}

class _SearchState extends ConsumerState<SearchScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final storiesAsync = ref.watch(storiesProvider);
    final hadithAsync = ref.watch(hadithCollectionProvider);
    final adhkarAsync = ref.watch(adhkarSetsProvider);
    final quranAsync = ref.watch(quranAllProvider);
    final loading = storiesAsync.isLoading ||
        hadithAsync.isLoading ||
        adhkarAsync.isLoading ||
        quranAsync.isLoading;
    // A shelf that failed to load (on the web: no internet) is reported,
    // never mistaken for "no results"; the shelves that did load still answer.
    final bool shelfFailed = quranAsync.hasError ||
        storiesAsync.hasError ||
        hadithAsync.hasError ||
        adhkarAsync.hasError;
    final List<Surah> quran = quranAsync.valueOrNull ?? const <Surah>[];

    final stories = storiesAsync.valueOrNull ?? const <Story>[];
    final hadiths = hadithAsync.valueOrNull ?? const <Hadith>[];
    final sets = adhkarAsync.valueOrNull ?? const <AdhkarSet>[];

    final hits = <_Hit>[];
    int quranTotal = 0;
    final bool arabicQuery = containsArabicLetters(_q);
    final String foldedQ = foldArabic(_q);
    final String skeletonQ = arabicSkeleton(_q);
    bool arabicMatch(String text) =>
        arabicQuery &&
        skeletonQ.length >= 2 &&
        (foldArabic(text).contains(foldedQ) ||
            arabicSkeleton(text).contains(skeletonQ));
    if (_q.length >= 2 || parseVerseKey(_q) != null) {
      final List<QuranHit> quranHits = searchQuran(quran, _q, limit: 200);
      quranTotal = quranHits.length;
      for (final QuranHit h in quranHits.take(30)) {
        hits.add(_Hit(
          shelf: "QUR'AN ${h.key}",
          title: '${h.surahName} · ayah ${h.ayah}',
          kicker: containsArabicLetters(_q) ? h.arabic : h.english,
          icon: Icons.menu_book_outlined,
          open: () {
            // Open the surah at this ayah (the reader resumes at the
            // surah's saved ayah).
            ref
                .read(readingPositionProvider.notifier)
                .save(ReadingPosition(surah: h.surah, ayah: h.ayah));
            context.push(AppRoutes.surah(h.surah));
          },
        ));
      }
      for (final s in stories) {
        if (s.title.toLowerCase().contains(_q) ||
            s.subtitle.toLowerCase().contains(_q) ||
            s.kicker.toLowerCase().contains(_q) ||
            (s.chapters.isNotEmpty &&
                s.chapters.first.body.toLowerCase().contains(_q))) {
          hits.add(_Hit(
            shelf: 'STORY',
            title: s.title,
            kicker: (s.hasUnverified || s.hasWeakNarration)
                ? 'Unverified \u00b7 ${s.kicker}'
                : s.kicker,
            icon: Icons.auto_stories_outlined,
            open: () => context.open(AppRoutes.storyReader, extra: s),
          ));
        }
      }
      for (final h in hadiths) {
        if (h.english.toLowerCase().contains(_q) || arabicMatch(h.arabic)) {
          hits.add(_Hit(
            shelf: 'HADITH',
            title: 'Hadith ${h.number} — an-Nawawi 40',
            kicker: h.english.length > 90
                ? '${h.english.substring(0, 90)}…'
                : h.english,
            icon: Icons.format_quote_outlined,
            open: () => context.push(AppRoutes.hadith),
          ));
        }
      }
      final Set<String> seenDhikr = <String>{};
      for (final set in sets) {
        for (final d in set.items) {
          final t = d.translation ?? '';
          if (t.toLowerCase().contains(_q) || arabicMatch(d.arabic)) {
            // Morning and evening sets share many identical adhkar.
            if (!seenDhikr.add('${d.arabic}|$t')) continue;
            hits.add(_Hit(
              shelf: 'DHIKR',
              title: set.titleEn,
              kicker: t.length > 90 ? '${t.substring(0, 90)}…' : t,
              icon: Icons.volunteer_activism_outlined,
              open: () => context.push(AppRoutes.adhkar),
            ));
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              const ScreenHeader(title: 'Find Anything', close: true),
              TextField(
                autofocus: true,
                style: AppText.body,
                decoration: const InputDecoration(
                  hintText: 'Search the Qur\'an and every shelf — or type 2:255',
                  prefixIcon: Icon(Icons.search, color: AppColors.gold),
                ),
                onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
              ),
              const SizedBox(height: 14),
              if (shelfFailed) ...[
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    const Icon(Icons.cloud_off_outlined,
                        size: 20, color: AppColors.gold),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        WebOffline.needsInternet('Some of the library'),
                        style: AppText.bodyMuted.copyWith(height: 1.5),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.invalidate(quranAllProvider);
                        ref.invalidate(storiesProvider);
                        ref.invalidate(hadithCollectionProvider);
                        ref.invalidate(adhkarSetsProvider);
                      },
                      child: const Text('Try again'),
                    ),
                  ]),
                ),
                const SizedBox(height: 10),
              ],
              if (_q.length < 2)
                GlassCard(
                    child: Text(
                        'Try "mercy", "بسم الله", "2:255", "Yusuf", "patience", "before sleep" — the whole Qur\'an, the story packs, the Forty Hadith, and the adhkar all answer here.',
                        style: AppText.bodyMuted.copyWith(height: 1.6)))
              else if (loading)
                const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.gold))
              else if (hits.isEmpty)
                GlassCard(
                    child: Text(
                        shelfFailed
                            ? 'No match for "$_q" in the shelves that loaded.'
                            : 'Nothing on any shelf matches "$_q" yet — ask Hādi, he may know.',
                        style: AppText.bodyMuted))
              else
                Column(children: [
                  Text(
                      quranTotal > 30
                          ? '${hits.length} SHOWN · $quranTotal${quranTotal >= 200 ? '+' : ''} IN THE QUR\'AN'
                          : '${hits.length} FOUND',
                      style: AppText.eyebrow),
                  const SizedBox(height: 8),
                  for (final h in hits.take(70))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassCard(
                        blur: false,
                        onTap: h.open,
                        child: Row(children: [
                          Icon(h.icon, size: 17, color: AppColors.goldLight),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                h.shelf,
                                style: AppText.bodyMuted.copyWith(
                                    fontSize: 12, letterSpacing: 1.5),
                              ),
                              Text(h.title,
                                  style: AppText.body.copyWith(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600)),
                              Text(h.kicker,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.bodyMuted
                                      .copyWith(fontSize: 12)),
                            ],
                          )),
                          const Icon(Icons.chevron_right,
                              color: AppColors.gold, size: 16),
                        ]),
                      ),
                    ),
                ]),
            ],
          ),
        ),
      ),
    );
  }
}
