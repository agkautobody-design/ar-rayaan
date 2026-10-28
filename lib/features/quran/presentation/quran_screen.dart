import '../../../app/core/tight_layout.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/core/content_loader.dart'
    show kQuranSizeHint, quranOfflineReadyProvider;
import '../../../app/core/web_offline.dart';
import '../../../app/theme/widgets/content_loading_view.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/needs_internet_view.dart';
import '../../../app/theme/widgets/screen_header.dart';

import '../../../app/core/open_link.dart';
import '../../../app/core/safe_url.dart';

import '../application/quran_offline.dart' show kQuranOfflineHint;
import '../application/quran_providers.dart';
import '../domain/quran_texts.dart';
import '../domain/quran_models.dart';
import '../domain/surah_search.dart';
import '../../../app/theme/widgets/whole_word_text.dart';
import 'quran_offline_card.dart';
import '../../../app/theme/widgets/focus_ring.dart';

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

  /// True while the text itself (2 MB the first time on the web) is still
  /// being fetched in the background. The list does not wait for it.
  bool _textPending = true;

  @override
  void initState() {
    super.initState();
    // Start the text download now, while the person looks at the list, so a
    // surah opens at once when tapped. Failure is shown by the reader.
    unawaited(
      ref
          .read(quranRepositoryProvider)
          .all()
          .then<void>(
            (_) {
              if (!mounted) return;
              setState(() => _textPending = false);
              ref.invalidate(quranOfflineReadyProvider);
            },
            onError: (Object _) {
              if (mounted) setState(() => _textPending = false);
            },
          ),
    );
  }

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
                  // Keeps the same repository: a retry must not start a second
                  // 2 MB download next to the one already running.
                  onRetry: () => ref.invalidate(quranIndexProvider),
                ),
                error: (Object e, _) => NeedsInternetView(
                  what: 'The Qur\u2019an',
                  hint: kQuranOfflineHint,
                  onRetry: () {
                    ref.invalidate(quranRepositoryProvider);
                    ref.invalidate(quranAllProvider);
                    ref.invalidate(quranIndexProvider);
                    ref.invalidate(quranTextsProvider);
                  },
                ),
                data: (List<SurahMeta> surahs) {
                  final List<SurahMeta> shown = filterSurahs(surahs, _query);
                  final bool searching = _query.trim().isNotEmpty;
                  // The shortcut cards above the list. At large text they take a
                  // whole screen, so there they go below the surahs instead.
                  final bool largeText = isTightLayout(context);
                  final List<Widget> extras = <Widget>[
                      // Web only, and only until the Qur'an is saved here.
                      if (!searching) ...[
                        const QuranOfflineCard(compact: true),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            key: const Key('quran-downloads-link'),
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              foregroundColor: AppColors.gold,
                            ),
                            onPressed: () => context.open(AppRoutes.downloads),
                            icon: const Icon(
                              Icons.download_for_offline_outlined,
                              size: 18,
                            ),
                            label: const Text('Download recitation'),
                          ),
                        ),
                        const SizedBox(height: 8),
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
                      // One control, one name: the card is already a button,
                      // so its label is given to it (a Semantics around it
                      // made a second, duplicate Tab stop).
                      Semantics(
                        child: GlassCard(
                          semanticsLabel: 'My bookmarks, collections and notes',
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
                      const SizedBox(height: 10),
                      Semantics(
                        child: GlassCard(
                          semanticsLabel: 'Memorise: Hifz planner and review',
                          key: const Key('quran-memorise'),
                          onTap: () => context.open('/academy/hifz'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                Icons.psychology_outlined,
                                color: AppColors.gold,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    WholeWordText(
                                      'Memorise',
                                      style: AppText.body.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Hifz planner. Open a surah to hide '
                                      'the text and test yourself.',
                                      style: AppText.bodyMuted.copyWith(
                                        fontSize: 13,
                                      ),
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
                        ),
                      ),
                      const SizedBox(height: 16),
                  ];
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      Semantics(label: 'Find a surah: name, meaning or number', child: TextField(
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
                      )),
                      if (_textPending && WebOffline.isWeb && !searching) ...[
                        const SizedBox(height: 12),
                        const QuranTextLoadingNote(),
                      ],
                      const SizedBox(height: 12),
                      if (!largeText) ...extras,
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
                      if (largeText) ...<Widget>[
                        const SizedBox(height: 16),
                        ...extras,
                      ],
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
      child: FocusRing(borderRadius: 12, child: InkWell(
        onTap: () => openLinkWithFeedback(
          context,
          SafeUrl.web(texts.arabic.url),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(
            child: Text(
              texts.footerLine,
              style: AppText.caption.copyWith(
                decoration: TextDecoration.underline,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      )),
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
      child: FocusRing(borderRadius: 12, child: InkWell(
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
      )),
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

/// Shown over the surah list while the text downloads in the background, so a
/// slow connection reads as "working", not as a frozen screen.
class QuranTextLoadingNote extends StatelessWidget {
  const QuranTextLoadingNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 4,
              backgroundColor: AppColors.gold.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Getting the text ready ($kQuranSizeHint, first time only). '
            'You can look through the list now; a surah opens as soon as '
            'this finishes.',
            key: const Key('quran-text-loading-note'),
            style: AppText.caption.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}
