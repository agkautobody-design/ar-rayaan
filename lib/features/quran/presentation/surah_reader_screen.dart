import 'dart:async' show Timer, unawaited;

import '../../../app/core/tight_layout.dart';
import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;

import 'dart:convert';

import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../academy/application/academy_providers.dart';
import '../../academy/presentation/verse_range_player_bar.dart';

import '../../../app/core/sound/sound_services.dart';

import '../../../app/core/open_link.dart';
import '../../../app/core/safe_url.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/core/content_loader.dart'
    show ContentLoader, kQuranSizeHint;
import '../../../app/theme/widgets/content_loading_view.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/needs_internet_view.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../elder/application/elder_mode.dart';
import '../../habits/application/return_loop.dart';
import '../../habits/presentation/quiet_done.dart';
import '../../downloads/presentation/surah_download_button.dart';
import '../application/quran_marks_controller.dart';
import '../application/quran_offline.dart' show kQuranOfflineHint;
import '../application/quran_providers.dart';
import '../application/test_me_provider.dart';
import '../application/translation_providers.dart';
import '../domain/quran_marks.dart';
import '../domain/quran_models.dart';
import '../domain/quran_texts.dart';
import '../domain/surah_search.dart';
import 'ayah_actions_sheet.dart';
import 'hideable_arabic.dart';
import '../../../app/core/retry_when_online.dart';
import '../../../app/theme/widgets/focus_ring.dart';

/// How solid the panel behind the ayat is (1 = no pattern shows through).
const double kReadingPanelAlpha = 0.9;

/// Surah reader — Arabic (Amiri) with gold ayah medallions + translation.
/// Tapping an ayah saves the Continue-Reading position.
class SurahReaderScreen extends ConsumerStatefulWidget {
  const SurahReaderScreen({required this.number, this.startAyah, super.key});

  final int number;

  /// Open at this ayah instead of the saved place (from "?ayah=" links such
  /// as the Ayat al-Kursi shortcut). Out-of-range values are clamped.
  final int? startAyah;

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

final transliterationProvider = FutureProvider<Map<String, String>>((
  ref,
) async {
  try {
    // Through ContentLoader so a copy saved for offline reading is used.
    final raw = await ContentLoader.loadString(
      'assets/quran/transliteration.json',
    );
    final m = (json.decode(raw) as Map)['map'] as Map;
    return m.map((k, v) => MapEntry(k as String, v as String));
  } catch (_) {
    // Offline: show the surah without transliteration now, and fetch it
    // again as soon as the connection is back (not only after a reload).
    refreshWhenBackOnline(ref);
    return const {};
  }
});

class _SurahReaderScreenState extends ConsumerState<SurahReaderScreen> {
  /// Where this surah should open: the ayah last saved INSIDE this surah
  /// (1 when the surah has never been opened). Read once, before the
  /// open below overwrites the "last read" pointer.
  late final int _startAyah;

  @override
  void initState() {
    super.initState();
    final ReadingPositionController controller = ref.read(
      readingPositionProvider.notifier,
    );
    _startAyah = widget.startAyah ?? controller.ayahFor(widget.number);
    // Record that this surah was opened. The ayah stays whatever was saved
    // for this surah, so browsing never wipes your place.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ReadingPosition? current = ref.read(readingPositionProvider);
      if (current?.surah != widget.number) {
        ref
            .read(readingPositionProvider.notifier)
            .save(ReadingPosition(surah: widget.number, ayah: _startAyah));
      }
    });
  }

  List<HeaderAction> _sizeActions(ArabicSizeController size) => <HeaderAction>[
    HeaderAction(
      icon: Icons.text_decrease,
      tooltip: 'Smaller text',
      onTap: size.smaller,
    ),
    HeaderAction(
      icon: Icons.text_increase,
      tooltip: 'Larger text',
      onTap: size.larger,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Surah> surah = ref.watch(surahProvider(widget.number));
    // A- / A+ live in the header so they never scroll away while reading.
    // On a very narrow window there is no room, so the toolbar keeps them.
    final bool sizeInHeader = MediaQuery.sizeOf(context).width >= 300;
    final ArabicSizeController sizeCtl = ref.read(arabicSizeProvider.notifier);

    return ScenicScaffold.pattern(
      // Escape leaves the surah: with three buttons per ayah, Tab alone made
      // Back unreachable in a long surah.
      body: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.quran);
            }
          },
        },
        child: SafeArea(
          child: Column(
            children: [
              surah.maybeWhen(
                data: (Surah s) => ScreenHeader(
                  title: s.meta.transliteration,
                  actions: sizeInHeader ? _sizeActions(sizeCtl) : const [],
                ),
                orElse: () => ScreenHeader(
                  title: 'Qur\'an',
                  actions: sizeInHeader ? _sizeActions(sizeCtl) : const [],
                ),
              ),
              // The reading controls (Jump, text size, bookmarks) and the heading
              // are the first items INSIDE the list, so they scroll away and the
              // reading area keeps the screen (see _Reader).
              Expanded(
                child: surah.when(
                  skipLoadingOnRefresh: false,
                  loading: () => ContentLoadingView(
                    what: 'this surah',
                    sizeHint: kQuranSizeHint,
                    // Same repository: no second download on top of the
                    // one already running.
                    onRetry: () => ref.invalidate(surahProvider(widget.number)),
                  ),
                  error: (Object e, _) => NeedsInternetView(
                    what: 'This surah',
                    hint: kQuranOfflineHint,
                    onRetry: () {
                      ref.invalidate(quranRepositoryProvider);
                      ref.invalidate(quranAllProvider);
                      ref.invalidate(quranIndexProvider);
                      ref.invalidate(surahProvider(widget.number));
                      ref.invalidate(transliterationProvider);
                      ref.invalidate(quranTextsProvider);
                    },
                  ),
                  data: (Surah s) => _Reader(surah: s, initialAyah: _startAyah),
                ),
              ),
              Consumer(
                builder: (context, ref, _) {
                  final int? ayahCount = ref
                      .watch(surahProvider(widget.number))
                      .valueOrNull
                      ?.meta
                      .ayahCount;
                  if (ayahCount == null) return const SizedBox.shrink();
                  return VerseRangePlayerBar(
                    surah: widget.number,
                    ayahCount: ayahCount,
                  );
                },
              ),
              const SizedBox(height: 2),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lazy reader: the heading, one list item per ayah, and a footer. Items
/// are built on demand (Al-Baqarah is 286 ayahs), and the list scrolls to
/// [initialAyah] when it opens at a saved place.
class _Reader extends ConsumerStatefulWidget {
  const _Reader({required this.surah, required this.initialAyah});

  final Surah surah;
  final int initialAyah;

  @override
  ConsumerState<_Reader> createState() => _ReaderState();
}

class _ReaderState extends ConsumerState<_Reader> {
  final ScrollController _scroll = ScrollController();
  final Map<int, GlobalKey> _keys = <int, GlobalKey>{};
  bool _userScrolled = false;

  /// The ayah the list is scrolling to.
  late int _target = widget.initialAyah;

  @override
  void initState() {
    super.initState();
    if (widget.initialAyah > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _seek(0));
    }
  }

  /// Scrolls to [ayah] (the "Jump to ayah" control).
  void jumpTo(int ayah) {
    _target = ayah;
    _seek(0);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// When scrolling stops, remember the first ayah in view as the place to
  /// continue from, so "Continue reading" returns to the ayah reached and not
  /// only to the start of the surah.
  void _rememberReached() {
    if (!mounted || !_scroll.hasClients) return;
    final RenderObject? viewport =
        _scroll.position.context.notificationContext?.findRenderObject();
    if (viewport is! RenderBox) return;
    final double top = viewport.localToGlobal(Offset.zero).dy;
    int? best;
    double bestDy = double.infinity;
    _keys.forEach((int n, GlobalKey k) {
      final RenderObject? ro = k.currentContext?.findRenderObject();
      if (ro is! RenderBox || !ro.attached) return;
      final double dy = ro.localToGlobal(Offset.zero).dy - top;
      final double bottom = dy + ro.size.height;
      // The first ayah that still has most of itself below the top edge.
      if (bottom > 40 && dy < bestDy) {
        bestDy = dy;
        best = n;
      }
    });
    final int? ayah = best;
    if (ayah == null) return;
    final ReadingPosition? now = ref.read(readingPositionProvider);
    if (now?.surah == widget.surah.meta.number && now?.ayah == ayah) return;
    ref
        .read(readingPositionProvider.notifier)
        .save(ReadingPosition(surah: widget.surah.meta.number, ayah: ayah));
  }

  /// Bring the saved ayah on screen. The list is lazy, so the target may
  /// not exist yet: jump by an estimate, see which ayahs got built, nudge
  /// toward the target, and finish with ensureVisible once it is built.
  void _seek(int attempt) {
    if (!mounted || attempt > 12) return;
    final int target = _target.clamp(1, widget.surah.ayahs.length);
    final BuildContext? targetContext = _keys[target]?.currentContext;
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        alignment: 0.1,
        duration: Duration.zero,
      );
      return;
    }
    if (_scroll.hasClients) {
      final ScrollPosition pos = _scroll.position;
      final int count = widget.surah.ayahs.length;
      final double total = pos.maxScrollExtent + pos.viewportDimension;
      final double perAyah = total / (count + 2);
      int? lowest;
      int? highest;
      _keys.forEach((int n, GlobalKey k) {
        if (k.currentContext == null) return;
        if (lowest == null || n < lowest!) lowest = n;
        if (highest == null || n > highest!) highest = n;
      });
      double to;
      if (lowest == null || highest == null) {
        to = total * ((target - 1) / count);
      } else if (target < lowest!) {
        to = pos.pixels - (lowest! - target) * perAyah;
      } else {
        to = pos.pixels + (target - highest!) * perAyah;
      }
      _scroll.jumpTo(to.clamp(0.0, pos.maxScrollExtent).toDouble());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _seek(attempt + 1));
  }

  @override
  Widget build(BuildContext context) {
    final Surah surah = widget.surah;
    final bool showBismillah = surah.meta.number != 1 && surah.meta.number != 9;
    final ReadingPosition? position = ref.watch(readingPositionProvider);
    final int n = surah.ayahs.length;
    final double arabicSize = ref.watch(arabicSizeProvider);

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification note) {
        // Only the reader's own list, and only a finger, wheel or key moving
        // it (a jump to a saved ayah is not "reading").
        if (note.depth != 0) return false;
        if (note is UserScrollNotification &&
            note.direction != ScrollDirection.idle) {
          _userScrolled = true;
        } else if (note is ScrollEndNotification && _userScrolled) {
          _userScrolled = false;
          _rememberReached();
        }
        return false;
      },
      child: ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: n + 2,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _ReaderToolbar(
                  surah: surah.meta.number,
                  ayahCount: n,
                  onJump: jumpTo,
                  showSize: MediaQuery.sizeOf(context).width < 300,
                ),
                _MadinahLink(surah: surah.meta.number, ayahCount: n),
                _heading(surah, showBismillah),
              ],
            ),
          );
        }
        if (index == n + 1) {
          return _ReaderFooter(
            surah: surah.meta.number,
            surahName: surah.meta.transliteration,
          );
        }
        final int i = index - 1;
        final Ayah ayah = surah.ayahs[i];
        final bool bookmarked =
            position?.surah == surah.meta.number &&
            position?.ayah == ayah.number;
        final BorderSide edge = BorderSide(
          color: AppColors.gold.withValues(alpha: 0.25),
        );
        return Container(
          key: _keys.putIfAbsent(ayah.number, () => GlobalKey()),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            // Reading text sits on a mostly solid panel: the gold pattern
            // behind the page crossed the lines of text on a plain glass fill.
            color: AppColors.night.withValues(alpha: kReadingPanelAlpha),
            border: Border(
              left: edge,
              right: edge,
              top: i == 0 ? edge : BorderSide.none,
              bottom: i == n - 1 ? edge : BorderSide.none,
            ),
          ),
          child: Column(
            children: <Widget>[
              if (i > 0)
                Divider(
                  height: 1,
                  color: AppColors.gold.withValues(alpha: 0.1),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _AyahBlock(
                  ayah: ayah,
                  surahNumber: surah.meta.number,
                  surahName: surah.meta.transliteration,
                  arabicSize: arabicSize,
                  isBookmarked: bookmarked,
                  onTap: () {
                    unawaited(noteReturn(ref, ReturnAct.quran));
                    ref
                        .read(readingPositionProvider.notifier)
                        .save(
                          ReadingPosition(
                            surah: surah.meta.number,
                            ayah: ayah.number,
                          ),
                        );
                  },
                ),
              ),
            ],
          ),
        );
      },
      ),
    );
  }

  Widget _heading(Surah surah, bool showBismillah) {
    // With little room the heading is one compact card, so the first ayah is
    // on the first screen.
    final bool tight = isTightLayout(context);
    return GlassCard(
      strong: true,
      padding: EdgeInsets.symmetric(vertical: tight ? 8 : 20, horizontal: 16),
      child: Column(
        children: [
          Text(
            'سُورَةُ ${surah.meta.arabicName}',
            style: AppText.arabicLarge.copyWith(
              fontSize: tight ? 20 : 26,
              height: tight ? 1.4 : 1.6,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          SizedBox(height: tight ? 2 : 6),
          Text(
            '${surah.meta.englishMeaning} · '
            '${surah.meta.isMeccan ? 'Meccan' : 'Medinan'} · '
            '${surah.meta.ayahCount} ayahs',
            style: AppText.bodyMuted.copyWith(fontSize: 12),
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
              style: AppText.arabicLarge.copyWith(fontSize: 22, height: 1.7),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
          ],
        ],
      ),
    );
  }
}

/// Madinah page mode link — visible only when the checksum-verified layout
/// pack has shipped (the provider returns null otherwise).
class _MadinahLink extends ConsumerWidget {
  const _MadinahLink({required this.surah, required this.ayahCount});

  final int surah;
  final int ayahCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(mushafLayoutProvider)
        .maybeWhen(
          data: (pages) => pages == null
              ? const SizedBox.shrink()
              : Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () =>
                        context.go('/quran/madinah/$surah/$ayahCount'),
                    icon: const Icon(
                      Icons.auto_awesome_motion,
                      color: AppColors.gold,
                      size: 18,
                    ),
                    label: Text(
                      'Madinah page view',
                      style: AppText.caption.copyWith(color: AppColors.gold),
                    ),
                  ),
                ),
          orElse: () => const SizedBox.shrink(),
        );
  }
}

class _ReaderToolbar extends ConsumerWidget {
  const _ReaderToolbar({
    required this.surah,
    required this.ayahCount,
    required this.onJump,
    required this.showSize,
  });

  final int surah;

  /// False when the header already carries the text-size buttons.
  final bool showSize;

  /// Null while the surah is still loading.
  final int? ayahCount;
  final ValueChanged<int> onJump;

  Future<void> _askAyah(BuildContext context, int count) async {
    final int? ayah = await showDialog<int>(
      context: context,
      builder: (BuildContext ctx) => _JumpToAyahDialog(ayahCount: count),
    );
    if (ayah != null) onJump(ayah);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ArabicSizeController size = ref.read(arabicSizeProvider.notifier);
    final double sizeNow = ref.watch(arabicSizeProvider);
    final int? count = ayahCount;
    final bool hiding = ref.watch(testMeProvider);
    final Widget tools = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          SurahDownloadButton(surah: surah),
          Tooltip(
            message: 'Open the Hifz planner on this surah',
            child: TextButton.icon(
              key: const Key('reader-memorise'),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: AppColors.gold,
              ),
              onPressed: () => context.open('/academy/hifz?surah=$surah'),
              icon: const Icon(Icons.psychology_outlined, size: 18),
              label: const Text('Memorise this surah'),
            ),
          ),
          Tooltip(
            message: hiding
                ? 'Show the Arabic again'
                : 'Cover the Arabic and tap each ayah to check yourself',
            child: TextButton.icon(
              key: const Key('reader-test-me'),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: AppColors.gold,
              ),
              onPressed: () {
                ref.read(revealedAyahsProvider.notifier).state =
                    const <String>{};
                ref.read(testMeProvider.notifier).state = !hiding;
              },
              icon: Icon(
                hiding ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 18,
              ),
              label: Text(hiding ? 'Show text' : 'Hide text / test me'),
            ),
          ),
          if (count != null && count > 1)
            Tooltip(
              message: 'Jump to an ayah in this surah',
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: AppColors.gold,
                ),
                onPressed: () => _askAyah(context, count),
                icon: const Icon(Icons.input, size: 18),
                label: const Text('Jump to ayah'),
              ),
            ),
          if (showSize) ...<Widget>[
          IconButton(
            tooltip: 'Smaller Arabic text',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: size.smaller,
            icon: const Icon(Icons.text_decrease, color: AppColors.gold),
          ),
          // Shows the size, so a tap that changes little still visibly
          // changes something.
          Semantics(
            label: 'Arabic text size ${sizeNow.round()}',
            excludeSemantics: true,
            child: Text(
              '${sizeNow.round()}',
              style: AppText.caption.copyWith(color: AppColors.gold),
            ),
          ),
          IconButton(
            tooltip: 'Larger Arabic text',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: size.larger,
            icon: const Icon(Icons.text_increase, color: AppColors.gold),
          ),
          ],
          IconButton(
            tooltip: 'My bookmarks, collections and notes',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => context.push(AppRoutes.quranBookmarks),
            icon: const Icon(Icons.bookmarks_outlined, color: AppColors.gold),
          ),
        ],
      ),
    );
    // At large text the tools alone fill most of the screen and push the
    // verses down: fold them into one line the reader can open.
    if (!isTightLayout(context)) return tools;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: const Key('reader-tools-fold'),
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 20),
        iconColor: AppColors.gold,
        collapsedIconColor: AppColors.gold,
        title: Text(
          'Reader tools',
          style: AppText.body.copyWith(color: AppColors.gold),
        ),
        children: <Widget>[tools],
      ),
    );
  }
}

/// Asks for an ayah number and checks it against the surah's ayah count.
class _JumpToAyahDialog extends StatefulWidget {
  const _JumpToAyahDialog({required this.ayahCount});

  final int ayahCount;

  @override
  State<_JumpToAyahDialog> createState() => _JumpToAyahDialogState();
}

class _JumpToAyahDialogState extends State<_JumpToAyahDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final int? ayah = parseAyahJump(_controller.text, widget.ayahCount);
    if (ayah == null) {
      setState(() => _error = 'Enter a number from 1 to ${widget.ayahCount}.');
      return;
    }
    Navigator.of(context).pop(ayah);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      semanticLabel: 'Jump to ayah',
      backgroundColor: const Color(0xFF0A0F18),
      title: Text('Jump to ayah', style: AppText.titleMedium),
      content: Semantics(label: 'Ayah 1 to ${widget.ayahCount}', child: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.go,
        style: AppText.body,
        decoration: InputDecoration(
          hintText: 'Ayah 1 to ${widget.ayahCount}',
          errorText: _error,
        ),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        onSubmitted: (_) => _submit(),
      )),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('Go', style: TextStyle(color: AppColors.goldLight)),
        ),
      ],
    );
  }
}

/// End of surah: how to save a place, and where the two texts come from
/// (Tanzil asks for its source to be named and linked).
class _ReaderFooter extends ConsumerStatefulWidget {
  const _ReaderFooter({required this.surah, required this.surahName});

  final int surah;
  final String surahName;

  @override
  ConsumerState<_ReaderFooter> createState() => _ReaderFooterState();
}

class _ReaderFooterState extends ConsumerState<_ReaderFooter> {
  Timer? _settle;

  @override
  void initState() {
    super.initState();
    // The footer is only built when the end of the surah is reached. Wait a
    // few seconds on it, so a quick jump past it is not counted as reading.
    _settle = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      unawaited(noteReturn(ref, ReturnAct.quran));
      unawaited(
        showQuietDone(
          context,
          ref,
          moment: 'surah:${widget.surah}',
        ),
      );
    });
  }

  @override
  void dispose() {
    _settle?.cancel();
    super.dispose();
  }

  Future<void> _open(String url) async {
    await openLinkWithFeedback(context, SafeUrl.web(url));
  }

  @override
  Widget build(BuildContext context) {
    final QuranTexts texts =
        ref.watch(quranTextsProvider).value ?? QuranTexts.fallback;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: <Widget>[
          Text(
            'TAP AN AYAH TO SAVE YOUR PLACE',
            style: AppText.eyebrow.copyWith(
              fontSize: 12,
              color: AppColors.gold.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Semantics(
            link: true,
            label: 'Arabic text and translation source: Tanzil.net',
            child: FocusRing(borderRadius: 12, child: InkWell(
              onTap: () => _open(texts.arabic.url),
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
          ),
        ],
      ),
    );
  }
}

class _AyahBlock extends ConsumerWidget {
  const _AyahBlock({
    required this.ayah,
    required this.surahNumber,
    required this.surahName,
    required this.arabicSize,
    required this.isBookmarked,
    required this.onTap,
  });

  final Ayah ayah;
  final int surahNumber;
  final String surahName;
  final double arabicSize;

  /// True for the saved reading place (Continue Reading), not a bookmark.
  final bool isBookmarked;
  final VoidCallback onTap;

  /// Transliteration entries that are placeholders, not text, are never
  /// shown (the 2:255 placeholder used to leak onto the screen).
  static bool _usable(String? s) =>
      s != null && s.isNotEmpty && !s.contains('...') && !s.contains('…');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, String> trAll =
        ref.watch(transliterationProvider).value ?? const <String, String>{};
    final String? tr = trAll['$surahNumber:${ayah.number}'];
    final bool playing = ref.watch(
      recitationServiceProvider.select(
        (RecitationState s) => s.surah == surahNumber && s.ayah == ayah.number,
      ),
    );
    final AyahMark? mark = ref.watch(
      quranMarksProvider.select(
        (QuranMarks m) => m.of(surahNumber, ayah.number),
      ),
    );
    final bool saved = mark?.bookmarked ?? false;
    final bool hasNote = mark?.note.isNotEmpty ?? false;
    final bool elder = ref.watch(elderModeProvider);
    // "Hide text / test me" covers the transliteration and the translation
    // too, until the ayah is tapped open.
    final bool covered = ayahIsCovered(ref, surahNumber, ayah.number);
    // The translation and transliteration follow the A- / A+ choice, so one
    // control makes everything on the page bigger, not only the Arabic.
    final double follow = (arabicSize / ArabicSizeController.defaultSize)
        .clamp(0.8, 2.0)
        .toDouble();
    return Semantics(
      container: true,
      label: 'Surah $surahName, ayah ${ayah.number}',
      child: FocusRing(borderRadius: 12, child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isBookmarked || playing
                ? AppColors.gold.withValues(alpha: playing ? 0.14 : 0.08)
                : Colors.transparent,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Arabic with end-of-ayah medallion
              HideableArabic(
                surah: surahNumber,
                ayah: ayah.number,
                child: RichText(
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                text: TextSpan(
                  style: AppText.arabicLarge.copyWith(
                    fontSize: arabicSize,
                    height: 2.0,
                  ),
                  children: [
                    TextSpan(text: ayah.arabic),
                    TextSpan(
                      text:
                          ' ﴿${SurahReaderScreen.toArabicIndic(ayah.number)}﴾',
                      style: TextStyle(
                        color: AppColors.gold.withValues(alpha: 0.9),
                        fontSize: arabicSize * 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              ),
              if (covered)
                const SizedBox(height: 8)
              else if (_usable(tr)) ...[
                const SizedBox(height: 4),
                Text(
                  tr!,
                  style: AppText.body.copyWith(
                    fontSize: 12.5 * follow,
                    height: 1.6,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFFCFBE92),
                  ),
                ),
                const SizedBox(height: 6),
              ] else
                const SizedBox(height: 8),
              // Urdu and Arabic packs read right to left.
              if (!covered)
              Directionality(
                textDirection: ref.watch(translationRtlProvider)
                    ? TextDirection.rtl
                    : Directionality.of(context),
                child: Text(
                  ayah.english,
                  style: AppText.bodyMuted.copyWith(
                    fontSize: 13 * follow,
                    height: 1.55,
                  ),
                ),
              ),
              if (hasNote)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Your note: ${mark!.note}',
                    style: AppText.caption.copyWith(color: AppColors.gold),
                  ),
                ),
              if (elder)
                // Elder Mode: three big buttons that say what they do.
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 4,
                  children: <Widget>[
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 56),
                        foregroundColor: AppColors.goldLight,
                      ),
                      onPressed: () => unawaited(
                        ref
                            .read(recitationServiceProvider.notifier)
                            .toggle(surahNumber, ayah.number),
                      ),
                      icon: Icon(
                        playing
                            ? Icons.stop_circle_outlined
                            : Icons.play_circle_outline,
                        size: 28,
                      ),
                      label: Text(playing ? 'Stop' : 'Play'),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 56),
                        foregroundColor: AppColors.goldLight,
                      ),
                      onPressed: () => unawaited(
                        ref
                            .read(quranMarksProvider.notifier)
                            .toggleBookmark(surahNumber, ayah.number),
                      ),
                      icon: Icon(
                        saved ? Icons.bookmark : Icons.bookmark_border,
                        size: 28,
                      ),
                      label: Text(saved ? 'Saved' : 'Save'),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 56),
                        foregroundColor: AppColors.goldLight,
                      ),
                      onPressed: () => showAyahActions(
                        context,
                        surahName: surahName,
                        surah: surahNumber,
                        ayah: ayah,
                      ),
                      icon: Icon(
                        hasNote ? Icons.edit_note : Icons.more_horiz,
                        size: 28,
                      ),
                      label: const Text('More'),
                    ),
                  ],
                )
              else
              // A Wrap, not a Row: in a very narrow window the three round
              // buttons go to a second line instead of overflowing.
              Wrap(
                alignment: WrapAlignment.end,
                children: [
                  IconButton(
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    tooltip: playing ? 'Stop' : 'Play this ayah',
                    onPressed: () async {
                      await ref
                          .read(recitationServiceProvider.notifier)
                          .toggle(surahNumber, ayah.number);
                    },
                    icon: Icon(
                      playing
                          ? Icons.stop_circle_outlined
                          : Icons.play_circle_outline,
                      size: 28,
                      color: AppColors.gold.withValues(
                        alpha: playing ? 1.0 : 0.8,
                      ),
                    ),
                  ),
                  IconButton(
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    tooltip: saved ? 'Remove bookmark' : 'Bookmark this ayah',
                    onPressed: () => ref
                        .read(quranMarksProvider.notifier)
                        .toggleBookmark(surahNumber, ayah.number),
                    icon: Icon(
                      saved ? Icons.bookmark : Icons.bookmark_border,
                      size: 28,
                      color: AppColors.gold.withValues(
                        alpha: saved ? 1.0 : 0.8,
                      ),
                    ),
                  ),
                  IconButton(
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    tooltip: 'Note, collections and copy',
                    onPressed: () => showAyahActions(
                      context,
                      surahName: surahName,
                      surah: surahNumber,
                      ayah: ayah,
                    ),
                    icon: Icon(
                      hasNote ? Icons.edit_note : Icons.more_horiz,
                      size: 28,
                      color: AppColors.gold.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      )),
    );
  }
}
