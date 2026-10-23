import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/core/web_offline.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../academy/application/academy_providers.dart';
import '../../adhkar/application/adhkar_providers.dart';
import '../../adhkar/domain/adhkar_models.dart';
import '../../hadith/application/hadith_providers.dart';
import '../../hadith/domain/hadith_models.dart';
import '../../huda/presentation/huda_screens.dart' show Guide, guidesProvider;
import '../../quran/application/quran_providers.dart';
import '../../quran/domain/quran_models.dart';
import '../domain/app_destinations.dart';
import '../domain/did_you_mean.dart';
import '../domain/quran_search.dart';
import '../domain/search_text.dart';
import '../../stories/data/stories_repository.dart';
import '../../stories/domain/story.dart';

/// FIND ANYTHING — one search across every shelf. Results come in this
/// order: the app's own rooms (Qibla, Tasbih, the 99 Names…), surahs by
/// name, then the Huda guides, the Forty Hadith, the story packs and the
/// Hisn al-Muslim adhkar, and last the Qur'an's verses (Arabic and
/// English, or a verse key like 2:255), which are by far the most numerous.
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
  /// Trimmed, lower-cased query used for matching.
  String _q = '';

  /// Trimmed query as typed, used when talking to the person.
  String _raw = '';

  final TextEditingController _controller = TextEditingController();
  FocusNode _focus = FocusNode();

  /// Bumped by Clear: the box is rebuilt from scratch (see [_clearSearch]).
  int _fieldGen = 0;

  /// The Clear button must never take the keyboard focus from the box: a
  /// button that is focused and then removed (it disappears once the box is
  /// empty) leaves the web text input detached, and typing went nowhere.
  final FocusNode _clearFocus =
      FocusNode(canRequestFocus: false, skipTraversal: true);
  Timer? _retryFocus;

  static const int _otherCap = 40;
  static const int _quranCap = 30;

  @override
  void initState() {
    super.initState();
    // `autofocus` fires while the page is still fading in, and on the web the
    // first tap then did not reach the field. Ask again once it has settled.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
    _retryFocus = Timer(const Duration(milliseconds: 400), () {
      if (mounted && !_focus.hasFocus) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _retryFocus?.cancel();
    _focus.dispose();
    _clearFocus.dispose();
    _controller.dispose();
    super.dispose();
  }

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
    // The guides and the Academy switch only add to the answer; they never
    // hold the search back or count as a failed shelf.
    final List<Guide> guides =
        ref.watch(guidesProvider).valueOrNull ?? const <Guide>[];
    final bool academyOn = ref.watch(academyFlagProvider).valueOrNull ?? true;

    // Result groups, shown in this order.
    final List<_Hit> destinationHits = <_Hit>[];
    final List<_Hit> surahHits = <_Hit>[];
    final List<_Hit> otherHits = <_Hit>[];
    final List<_Hit> quranCards = <_Hit>[];
    int otherTotal = 0;
    int quranTotal = 0;
    String? suggestion;
    final bool arabicQuery = containsArabicLetters(_q);
    final String foldedQ = foldArabic(_q);
    final String skeletonQ = arabicSkeleton(_q);
    bool arabicMatch(String text) =>
        arabicQuery &&
        skeletonQ.length >= 2 &&
        (foldArabic(text).contains(foldedQ) ||
            arabicSkeleton(text).contains(skeletonQ));
    void addOther(_Hit hit) {
      otherTotal++;
      if (otherHits.length < _otherCap) otherHits.add(hit);
    }

    if (_q.length >= 2 || parseVerseKey(_q) != null) {
      if (parseVerseKey(_q) == null) {
        for (final AppDestination d
            in matchDestinations(_q, academyOn: academyOn)) {
          destinationHits.add(_Hit(
            shelf: 'IN THE APP',
            title: d.title,
            kicker: d.subtitle,
            icon: Icons.apps_outlined,
            open: () => context.open(d.route),
          ));
        }
        final List<SurahMeta> metas =
            quran.map((Surah s) => s.meta).toList();
        suggestion = didYouMean(metas, _q);
        for (final SurahMeta m in matchSurahNames(metas, _q)) {
          surahHits.add(_Hit(
            shelf: 'SURAH ${m.number}',
            title: '${m.transliteration} · ${m.englishMeaning}',
            kicker: '${m.ayahCount} ayahs · ${m.revelationType}',
            icon: Icons.menu_book_outlined,
            open: () => context.open(AppRoutes.surah(m.number)),
          ));
        }
      }

      final List<QuranHit> quranHits = searchQuran(quran, _q, limit: 200);
      quranTotal = quranHits.length;
      for (final QuranHit h in quranHits.take(_quranCap)) {
        quranCards.add(_Hit(
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

      for (final Guide g in guides) {
        if (matchesQuery('${g.title} ${g.subtitle} ${g.category}', _q)) {
          addOther(_Hit(
            shelf: 'GUIDE',
            title: g.title,
            kicker: g.subtitle,
            icon: Icons.checklist_rtl_outlined,
            open: () => context.push(
              '${AppRoutes.hudaGuide}?id=${Uri.encodeQueryComponent(g.id)}',
              extra: g,
            ),
          ));
        }
      }
      for (final h in hadiths) {
        if (matchesQuery(h.english, _q) || arabicMatch(h.arabic)) {
          addOther(_Hit(
            shelf: 'HADITH',
            title: 'Hadith ${h.number} — an-Nawawi 40',
            kicker: h.english.length > 90
                ? '${h.english.substring(0, 90)}…'
                : h.english,
            icon: Icons.format_quote_outlined,
            open: () => context.push(AppRoutes.hadithAt(h.number)),
          ));
        }
      }
      for (final s in stories) {
        if (matchesQuery(s.title, _q) ||
            matchesQuery(s.subtitle, _q) ||
            matchesQuery(s.kicker, _q) ||
            (s.chapters.isNotEmpty &&
                matchesQuery(s.chapters.first.body, _q))) {
          addOther(_Hit(
            shelf: 'STORY',
            title: s.title,
            kicker: (s.hasUnverified || s.hasWeakNarration)
                ? 'Unverified · ${s.kicker}'
                : s.kicker,
            icon: Icons.auto_stories_outlined,
            open: () => context.open(AppRoutes.storyReader, extra: s),
          ));
        }
      }
      final Set<String> seenDhikr = <String>{};
      for (final set in sets) {
        for (final d in set.items) {
          final t = d.translation ?? '';
          if (matchesQuery(t, _q) || arabicMatch(d.arabic)) {
            // Morning and evening sets share many identical adhkar.
            if (!seenDhikr.add('${d.arabic}|$t')) continue;
            addOther(_Hit(
              shelf: 'DHIKR',
              title: set.titleEn,
              kicker: t.length > 90 ? '${t.substring(0, 90)}…' : t,
              icon: Icons.volunteer_activism_outlined,
              open: () =>
                  context.push('${AppRoutes.adhkar}?set=${set.id}'),
            ));
          }
        }
      }
    }

    final String? dym = suggestion;
    final List<_Hit> hits = <_Hit>[
      ...destinationHits,
      ...surahHits,
      ...otherHits,
      ...quranCards,
    ];
    final int total =
        destinationHits.length + surahHits.length + otherTotal + quranTotal;
    // Honest counts: say what is shown and how much more there is.
    String countsLine = '${hits.length} FOUND';
    if (hits.length < total) {
      countsLine = '${hits.length} SHOWN';
      if (otherTotal > otherHits.length) {
        countsLine += ' · $otherTotal ON THE OTHER SHELVES';
      }
      if (quranTotal > quranCards.length) {
        final String plus = quranTotal >= 200 ? '+' : '';
        countsLine += " · $quranTotal$plus IN THE QUR'AN";
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          // The header and the box stay put; only the answers scroll. A box
          // that scrolls away is torn down with its focus, and typing then
          // went nowhere until the page was reopened.
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: ScreenHeader(title: 'Find Anything', close: true),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: KeyedSubtree(
                key: ValueKey<int>(_fieldGen),
                child: TextField(
                key: const Key('search-field'),
                controller: _controller,
                focusNode: _focus,
                autofocus: true,
                style: AppText.body,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search the Qur\'an and every shelf — or type 2:255',
                  prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                  suffixIcon: _raw.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.close, color: AppColors.gold),
                          focusNode: _clearFocus,
                          onPressed: _clearSearch,
                        ),
                ),
                onChanged: _onTyped,
                ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
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
              if (dym != null && !loading && _q.length >= 2)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    key: const Key('did-you-mean'),
                    onPressed: () => _useSuggestion(dym),
                    child: Text('Did you mean "$dym"?'),
                  ),
                ),
              if (_q.length < 2)
                GlassCard(
                    child: Text(
                        'Try "mulk", "qibla", "mercy", "بسم الله", "2:255", "patience", "before sleep" — the app\'s own rooms, every surah, the whole Qur\'an, the story packs, the guides, the Forty Hadith, and the adhkar all answer here.',
                        style: AppText.bodyMuted.copyWith(height: 1.6)))
              else if (loading)
                const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.gold))
              else if (hits.isEmpty)
                GlassCard(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        shelfFailed
                            ? 'No match for "$_raw" in the shelves that loaded.'
                            : 'Nothing on any shelf matches "$_raw". Try another word, or a verse like 2:255 — or ask Hādi.',
                        style: AppText.bodyMuted.copyWith(height: 1.5)),
                    if (!shelfFailed)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () =>
                              context.go(AppRoutes.hadiAsk(_raw)),
                          child: Text('Ask Hādi: "$_raw"'),
                        ),
                      ),
                  ],
                ))
              else
                Column(children: [
                  Text(countsLine, style: AppText.eyebrow),
                  const SizedBox(height: 8),
                  for (final h in hits)
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
            ],
          ),
        ),
      ),
    );
  }

  /// Empties the box and keeps it ready for typing.
  ///
  /// On the web the tap on Clear takes the browser's focus away from the
  /// text input before Flutter sees the tap, and the engine then drops its
  /// editing session while the framework still believes the box has focus:
  /// the box shows a cursor but typed letters go nowhere (reopening the page
  /// was the only cure). A box built from scratch, with a fresh focus node,
  /// is exactly what reopening gives, so Clear does the same: a new field,
  /// focused once the frame is done, and asked again if it did not take.
  void _clearSearch() {
    final FocusNode old = _focus;
    _controller.clear();
    setState(() {
      _q = '';
      _raw = '';
      _fieldGen++;
      _focus = FocusNode();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      old.dispose();
      if (mounted) _focus.requestFocus();
    });
    _retryFocus?.cancel();
    _retryFocus = Timer(const Duration(milliseconds: 350), () {
      if (mounted && !_focus.hasFocus) _focus.requestFocus();
    });
  }

  void _onTyped(String v) {
    setState(() {
      _raw = v.trim();
      _q = _raw.toLowerCase();
    });
  }

  /// Replace the box's text with a suggestion and search for it.
  void _useSuggestion(String text) {
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _onTyped(text);
    _focus.requestFocus();
  }
}
