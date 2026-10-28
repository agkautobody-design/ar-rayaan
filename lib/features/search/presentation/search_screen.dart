import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/core/web_offline.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../academy/application/academy_providers.dart';
import '../../academy/presentation/qa_bank_screen.dart'
    show QaEntry, qaBankProvider;
import '../../adhkar/application/adhkar_providers.dart';
import '../../adhkar/domain/adhkar_models.dart';
import '../../hadith/application/hadith_providers.dart';
import '../../hadith/domain/hadith_models.dart';
import '../../huda/presentation/huda_screens.dart' show Guide, guidesProvider;
import '../../notes/application/notes_controller.dart';
import '../../notes/domain/notes.dart';
import '../../quran/application/quran_providers.dart';
import '../../quran/domain/quran_models.dart';
import '../../quran/presentation/surah_reader_screen.dart'
    show transliterationProvider;
import '../domain/app_destinations.dart';
import '../domain/did_you_mean.dart';
import '../domain/quran_find.dart';
import '../domain/quran_search.dart';
import '../domain/search_docs.dart';
import '../domain/search_engine.dart';
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
    this.score = 0,
  });

  /// How well the item answers the query (see `scoreDoc`); better first.
  final int score;

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

  /// True while the box holds anything (shows Clear straight away, before
  /// the pause that precedes a new search).
  bool _hasText = false;

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

  /// The box can fire many times a second (typing, a paste, a held key).
  /// The answers wait for a short pause, so a long burst is searched once.
  Timer? _debounce;
  static const Duration _pause = Duration(milliseconds: 180);

  /// How many results of each kind are shown; "Show more" adds a page.
  static const int _page = 30;
  int _otherShown = _page;
  int _quranShown = _page;

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
    _debounce?.cancel();
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
    // The guides, the Q&A, the notes, the transliteration and the Academy
    // switch only add to the answer; they never hold the search back or
    // count as a failed shelf.
    final List<Guide> guides =
        ref.watch(guidesProvider).valueOrNull ?? const <Guide>[];
    final bool academyOn = ref.watch(academyFlagProvider).valueOrNull ?? true;
    final List<QaEntry> qa = academyOn
        ? (ref.watch(qaBankProvider).valueOrNull ?? const <QaEntry>[])
        : const <QaEntry>[];
    final Map<String, String> translit =
        ref.watch(transliterationProvider).valueOrNull ??
            const <String, String>{};
    final List<NoteItem> notes = ref.watch(notesProvider);

    // Result groups, shown in this order.
    final List<_Hit> destinationHits = <_Hit>[];
    final List<_Hit> surahHits = <_Hit>[];
    final List<_Hit> allOther = <_Hit>[];
    final List<_Hit> quranCards = <_Hit>[];
    int quranTotal = 0;
    String? suggestion;
    final bool arabicQuery = containsArabicLetters(_q);
    final String foldedQ = foldArabic(_q);
    final String skeletonQ = arabicSkeleton(_q);
    bool arabicMatch(String? text) =>
        text != null &&
        arabicQuery &&
        skeletonQ.length >= 2 &&
        (foldArabic(text).contains(foldedQ) ||
            arabicSkeleton(text).contains(skeletonQ));
    String clip(String t) => t.length > 90 ? '${t.substring(0, 90)}…' : t;

    if (_q.length >= 2 || parseVerseKey(_q) != null) {
      final QuerySpec spec = QuerySpec.parse(_q);
      // Score an item; for an Arabic query an Arabic match is a good answer.
      int rate(Object owner, SearchDoc Function() make, {String? arabic}) {
        if (arabicMatch(arabic)) return 70;
        if (arabicQuery) return 0;
        return scoreDoc(docFor(owner, make), spec);
      }

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
        for (final SurahMeta m in matchSurahNames(
          metas,
          _q,
          // A room that answers the word ("hijri" -> Calendar) is enough;
          // a one-letter-off surah name would only add noise.
          allowNear: destinationHits.isEmpty,
        )) {
          surahHits.add(_Hit(
            shelf: 'SURAH ${m.number}',
            title: '${m.transliteration} · ${m.englishMeaning}',
            kicker: '${m.ayahCount} ayahs · ${m.revelationType}',
            icon: Icons.menu_book_outlined,
            open: () => context.open(AppRoutes.surah(m.number)),
          ));
        }
      }

      final List<QuranHit> quranHits =
          findQuran(quran, _q, translit: translit);
      quranTotal = quranHits.length;
      for (final QuranHit h in quranHits.take(_quranShown)) {
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
            context.open(AppRoutes.surah(h.surah));
          },
        ));
      }

      for (final Guide g in guides) {
        final int sc = rate(
          g,
          () => SearchDoc(
            title: g.title,
            subtitle: '${g.subtitle} ${g.category}',
            body: g.steps.join(' '),
          ),
        );
        if (sc > 0) {
          allOther.add(_Hit(
            shelf: 'GUIDE',
            score: sc,
            title: g.title,
            kicker: g.subtitle,
            icon: Icons.checklist_rtl_outlined,
            open: () => context.open(
              '${AppRoutes.hudaGuide}?id=${Uri.encodeQueryComponent(g.id)}',
              extra: g,
            ),
          ));
        }
      }
      for (final h in hadiths) {
        // The grade and who gave it are searchable too ("sahih", "hasan").
        final int sc = rate(h, () => hadithDoc(h), arabic: h.arabic);
        if (sc > 0) {
          allOther.add(_Hit(
            shelf: 'HADITH',
            score: sc,
            title: 'Hadith ${h.number} — an-Nawawi 40',
            kicker: clip(h.english),
            icon: Icons.format_quote_outlined,
            open: () => context.open(AppRoutes.hadithAt(h.number)),
          ));
        }
      }
      for (final s in stories) {
        // Every chapter is searched, not just the first.
        final int sc = rate(s, () => storyDoc(s), arabic: arabicQuery ? storyArabic(s) : null);
        if (sc > 0) {
          // A story that only MENTIONS the word is listed after the ones
          // named for it, and says so.
          final bool named = sc >= 80;
          allOther.add(_Hit(
            shelf: named ? 'STORY' : 'STORY · MENTIONED',
            score: sc,
            title: s.title,
            kicker: (s.hasUnverified || s.hasWeakNarration)
                ? 'Unverified · ${s.kicker}'
                : s.kicker,
            icon: Icons.auto_stories_outlined,
            open: () => context.open(AppRoutes.storyReader, extra: s),
          ));
        }
      }
      for (final QaEntry e in qa) {
        final int sc = rate(e, () => qaDoc(e.q, e.a));
        if (sc > 0) {
          allOther.add(_Hit(
            shelf: 'Q&A',
            score: sc,
            title: e.q,
            kicker: clip(e.a),
            icon: Icons.help_outline,
            open: () => context.open('/academy/qa'),
          ));
        }
      }
      for (final NoteItem n in notes) {
        final int sc = rate(n, () => noteDoc(n));
        if (sc > 0) {
          allOther.add(_Hit(
            shelf: 'YOUR NOTE',
            score: sc,
            title: n.title,
            kicker: clip(n.body.isEmpty ? n.title : n.body),
            icon: Icons.edit_note_outlined,
            open: () => context.open(AppRoutes.notes),
          ));
        }
      }
      final Set<String> seenDhikr = <String>{};
      for (final set in sets) {
        for (final d in set.items) {
          final t = d.translation ?? '';
          final int sc = rate(
            d,
            () => dhikrDoc(
              setTitle: set.titleEn,
              transliteration: d.transliteration,
              translation: d.translation,
            ),
            arabic: d.arabic,
          );
          if (sc > 0) {
            // Morning and evening sets share many identical adhkar.
            if (!seenDhikr.add('${d.arabic}|$t')) continue;
            allOther.add(_Hit(
              shelf: 'DHIKR',
              score: sc,
              title: set.titleEn,
              kicker: clip(t),
              icon: Icons.volunteer_activism_outlined,
              open: () => context.open('${AppRoutes.adhkar}?set=${set.id}'),
            ));
          }
        }
      }
    }

    // Best answer first; equal scores keep the shelf order above (the sort
    // is made stable by the original position).
    final List<(int, _Hit)> indexed = <(int, _Hit)>[
      for (int i = 0; i < allOther.length; i++) (i, allOther[i]),
    ]..sort(((int, _Hit) a, (int, _Hit) b) {
        final int c = b.$2.score.compareTo(a.$2.score);
        return c != 0 ? c : a.$1.compareTo(b.$1);
      });
    final int otherTotal = indexed.length;
    final List<_Hit> otherHits = <_Hit>[
      for (final (int, _Hit) e in indexed.take(_otherShown)) e.$2,
    ];

    // A word that found things is not a typo.
    final String? dym =
        (otherTotal == 0 && quranTotal == 0) ? suggestion : null;
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
        countsLine += " · $quranTotal IN THE QUR'AN";
      }
    }
    final int otherLeft = otherTotal - otherHits.length;
    final int quranLeft = quranTotal - quranCards.length;

    Widget card(_Hit h) => Padding(
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
                    style: AppText.bodyMuted
                        .copyWith(fontSize: 12, letterSpacing: 1.5),
                  ),
                  Text(h.title,
                      style: AppText.body.copyWith(
                          fontSize: 13.5, fontWeight: FontWeight.w600)),
                  Text(h.kicker,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodyMuted.copyWith(fontSize: 12)),
                ],
              )),
              const Icon(Icons.chevron_right, color: AppColors.gold, size: 16),
            ]),
          ),
        );

    Widget moreButton(Key key, String label, VoidCallback onTap) => Align(
          alignment: Alignment.centerLeft,
          child: TextButton(key: key, onPressed: onTap, child: Text(label)),
        );

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
                child: Semantics(label: 'Search the Qur\'an and every shelf — or type 2:255', child: TextField(
                key: const Key('search-field'),
                controller: _controller,
                focusNode: _focus,
                autofocus: true,
                style: AppText.body,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search the Qur\'an and every shelf — or type 2:255',
                  prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                  suffixIcon: !_hasText
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.close, color: AppColors.gold),
                          focusNode: _clearFocus,
                          onPressed: _clearSearch,
                        ),
                ),
                // Nothing past the cap is searched, so nothing past it is
                // kept: a pasted wall of text becomes one short query.
                inputFormatters: <TextInputFormatter>[
                  LengthLimitingTextInputFormatter(kMaxSearchQueryChars),
                ],
                onChanged: _onTyped,
                )),
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
                  for (final h in <_Hit>[
                    ...destinationHits,
                    ...surahHits,
                    ...otherHits,
                  ])
                    card(h),
                  if (otherLeft > 0)
                    moreButton(
                      const Key('search-more-other'),
                      'Show ${otherLeft < _page ? otherLeft : _page} more '
                      'of $otherLeft',
                      () => setState(() => _otherShown += _page),
                    ),
                  for (final h in quranCards) card(h),
                  if (quranLeft > 0)
                    moreButton(
                      const Key('search-more-quran'),
                      "Show ${quranLeft < _page ? quranLeft : _page} more "
                      "verses of $quranLeft",
                      () => setState(() => _quranShown += _page),
                    ),
                  // A whole sentence is a question, not a word to find:
                  // the hits above are only loose matches, so say where a
                  // real answer is (round 6).
                  if (_raw.trim().split(RegExp(r'\s+')).length >= 4)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        key: const Key('search-ask-hadi-sentence'),
                        onPressed: () => context.go(AppRoutes.hadiAsk(_raw)),
                        child: const Text('Asking a question? Ask Hādi'),
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
    _debounce?.cancel();
    setState(() {
      _q = '';
      _raw = '';
      _hasText = false;
      _otherShown = _page;
      _quranShown = _page;
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
    _debounce?.cancel();
    if (v.trim().isEmpty) {
      setState(() {
        _hasText = false;
        _raw = '';
        _q = '';
      });
      return;
    }
    if (!_hasText) setState(() => _hasText = true);
    // Search once the typing pauses, not on every key.
    _debounce = Timer(_pause, () => _apply(v));
  }

  void _apply(String v) {
    if (!mounted) return;
    final String raw = normalizeSearchQuery(v);
    setState(() {
      _hasText = raw.isNotEmpty;
      _raw = raw;
      _q = asciiDigits(raw).toLowerCase();
      _otherShown = _page;
      _quranShown = _page;
    });
  }

  /// Replace the box's text with a suggestion and search for it.
  void _useSuggestion(String text) {
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _debounce?.cancel();
    _apply(text);
    _focus.requestFocus();
  }
}
