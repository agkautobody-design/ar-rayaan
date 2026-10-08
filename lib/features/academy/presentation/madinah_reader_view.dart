/// Madinah Reader View — the line-locked page mode of the Quran reader.
///
/// Shown only when the checksum-verified layout pack is present (the
/// provider returns null otherwise — unverified geometry never ships).
/// Two-tap ayah selection sets the player's range; the playing ayah's
/// line lights up; the verse-range bar sits in the thumb zone.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/academy_providers.dart';
import '../application/recitation_player_provider.dart';
import '../domain/mushaf_layout.dart';
import '../domain/recitation_audio.dart';
import 'mushaf_page_view.dart';
import 'verse_range_player_bar.dart';

class MadinahReaderView extends ConsumerStatefulWidget {
  const MadinahReaderView({
    super.key,
    required this.surah,
    required this.ayahCount,
  });

  final int surah;
  final int ayahCount;

  @override
  ConsumerState<MadinahReaderView> createState() =>
      _MadinahReaderViewState();
}

class _MadinahReaderViewState extends ConsumerState<MadinahReaderView> {
  int? _rangeStart;
  int? _rangeEnd;
  final PageController _pager = PageController();

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _onAyahTapped(int surah, int ayah) {
    if (surah != widget.surah) return;
    setState(() {
      if (_rangeStart == null || (_rangeStart != null && _rangeEnd != null)) {
        _rangeStart = ayah; // first tap (or new selection)
        _rangeEnd = null;
      } else {
        _rangeEnd = ayah < _rangeStart! ? _rangeStart : ayah;
        if (ayah < _rangeStart!) _rangeStart = ayah;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<MushafPage>?> pack =
        ref.watch(mushafLayoutProvider);
    final RecitationPlaybackState playback =
        ref.watch(recitationPlayerProvider);

    return pack.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (List<MushafPage>? pages) {
        if (pages == null) return const SizedBox.shrink(); // pack absent
        final AyahLocation? first = MushafLayoutEngine.findAyah(
            pages, widget.surah, 1);
        final AyahLocation? last = MushafLayoutEngine.findAyah(
            pages, widget.surah, widget.ayahCount);
        if (first == null || last == null) {
          return const Center(child: Text('Page mapping unavailable'));
        }
        final List<MushafPage> span =
            MushafLayoutEngine.pagesBetween(pages, first, last);

        AyahLocation? highlight;
        if (playback.playing && playback.plan.isNotEmpty) {
          final PlaybackEvent e = playback.plan[playback.eventIndex];
          highlight = MushafLayoutEngine.findAyah(
              pages, e.ref.surah, e.ref.ayah);
        }

        return Column(
          children: <Widget>[
            Expanded(
              child: PageView.builder(
                controller: _pager,
                itemCount: span.length,
                itemBuilder: (context, i) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: MushafPageView(
                    page: span[i],
                    onAyahTapped: _onAyahTapped,
                    highlight: highlight,
                  ),
                ),
              ),
            ),
            VerseRangePlayerBar(
              key: ValueKey('$_rangeStart-$_rangeEnd'),
              surah: widget.surah,
              ayahCount: widget.ayahCount,
              initialStartAyah: _rangeStart ?? 1,
              initialEndAyah: _rangeEnd ?? widget.ayahCount,
            ),
          ],
        );
      },
    );
  }
}
