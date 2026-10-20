import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../academy/application/academy_providers.dart';
import '../../academy/application/recitation_player_provider.dart';
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

final transliterationProvider = FutureProvider<Map<String, String>>((ref) async {
  try {
    final raw = await rootBundle.loadString('assets/quran/transliteration.json');
    final m = (json.decode(raw) as Map)['map'] as Map;
    return m.map((k, v) => MapEntry(k as String, v as String));
  } catch (_) {
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
    final ReadingPositionController controller =
        ref.read(readingPositionProvider.notifier);
    _startAyah = controller.ayahFor(widget.number);
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
                data: (Surah s) => _Reader(surah: s, initialAyah: _startAyah),
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

  @override
  void initState() {
    super.initState();
    if (widget.initialAyah > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _seek(0));
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Bring the saved ayah on screen. The list is lazy, so the target may
  /// not exist yet: jump by an estimate, see which ayahs got built, nudge
  /// toward the target, and finish with ensureVisible once it is built.
  void _seek(int attempt) {
    if (!mounted || attempt > 12) return;
    final int target = widget.initialAyah > widget.surah.ayahs.length
        ? widget.surah.ayahs.length
        : widget.initialAyah;
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

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: n + 2,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _heading(surah, showBismillah),
          );
        }
        if (index == n + 1) {
          return Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text(
              'TAP AN AYAH TO SAVE YOUR PLACE',
              style: AppText.eyebrow.copyWith(
                fontSize: 8,
                color: AppColors.gold.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),
          );
        }
        final int i = index - 1;
        final Ayah ayah = surah.ayahs[i];
        final bool bookmarked = position?.surah == surah.meta.number &&
            position?.ayah == ayah.number;
        final BorderSide edge =
            BorderSide(color: AppColors.gold.withValues(alpha: 0.25));
        return Container(
          key: _keys.putIfAbsent(ayah.number, () => GlobalKey()),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.glassFill,
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
                  isBookmarked: bookmarked,
                  onTap: () {
                    ref.read(readingPositionProvider.notifier).save(
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
    );
  }

  Widget _heading(Surah surah, bool showBismillah) {
    return GlassCard(
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
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
            if (_usable(tr)) ...[
              const SizedBox(height: 4),
              Text(
                tr!,
                style: AppText.body.copyWith(
                  fontSize: 12.5,
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFFCFBE92),
                ),
              ),
              const SizedBox(height: 6),
            ] else
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
                SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: playing ? 'Stop' : 'Play this ayah',
                    onPressed: () async {
                      // One voice at a time: silence the range player.
                      await ref
                          .read(recitationPlayerProvider.notifier)
                          .stop();
                      await ref
                          .read(recitationServiceProvider.notifier)
                          .toggle(surahNumber, ayah.number);
                    },
                    icon: Icon(
                      playing
                          ? Icons.stop_circle_outlined
                          : Icons.play_circle_outline,
                      size: 22,
                      color: AppColors.gold.withValues(
                        alpha: playing ? 1.0 : 0.55,
                      ),
                    ),
                  ),
                ),
                if (isBookmarked)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 12),
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
