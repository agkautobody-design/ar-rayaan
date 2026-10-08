/// Madinah mushaf layout — the LINE-LOCKED 15-line page geometry.
///
/// Why this exists: visual memorizers recall ayat by LINE POSITION.
/// Any reflowable reader breaks their recall — so the Recitation
/// School renders fixed pages identical to the Madinah mushaf.
///
/// DATA INTEGRITY (constitution): this engine NEVER fabricates page
/// breaks. The authentic 604-page mapping ships as a content pack
/// (`assets/quran/madinah_layout.json`, KFGQPC-verified + SHA-256
/// checksum — the build fails if a bit flips). Scaffolding data used
/// in tests is marked SCAFFOLD and must never reach production.
library;

/// One piece of a line: either Quranic text bound to an ayah, or a
/// decorative marker (sajdah icon, rub'/hizb ornament).
class LayoutSegment {
  const LayoutSegment({
    this.text = '',
    this.surah,
    this.ayah,
    this.startsNewAyah = false,
    this.endsAyah = false,
    this.sajdah = false,
    this.marker = false,
  });

  final String text;
  final int? surah;
  final int? ayah;
  final bool startsNewAyah;
  final bool endsAyah;
  final bool sajdah;

  /// Decorative segment (ornament, not recitable text).
  final bool marker;

  bool get isText => !marker && text.isNotEmpty;
}

/// One of exactly 15 locked lines on a Madinah page.
class MushafLine {
  const MushafLine(this.segments);

  final List<LayoutSegment> segments;

  /// Full line text (joined ayah pieces) — for rendering/tests.
  String get text => segments.map((LayoutSegment s) => s.text).join();
}

/// A Madinah mushaf page: always 15 lines, page 1 of 604.
class MushafPage {
  const MushafPage({required this.pageNumber, required this.lines});

  final int pageNumber;
  final List<MushafLine> lines;

  static const int linesPerPage = 15;
  static const int totalPages = 604;
}

/// Where an ayah starts: page (1-based) + line index (0-based).
class AyahLocation {
  const AyahLocation(this.page, this.lineIndex);

  final int page;
  final int lineIndex;
}

abstract final class MushafLayoutEngine {
  /// Validate a parsed layout. Throws [LayoutFormatException] on any
  /// structural violation — the asset pipeline runs this at build time.
  static void validate(List<MushafPage> pages) {
    if (pages.length != MushafPage.totalPages) {
      throw LayoutFormatException(
        'expected ${MushafPage.totalPages} pages, got ${pages.length}',
      );
    }
    for (final MushafPage p in pages) {
      if (p.lines.length != MushafPage.linesPerPage) {
        throw LayoutFormatException(
          'page ${p.pageNumber}: expected ${MushafPage.linesPerPage} '
          'lines, got ${p.lines.length}',
        );
      }
      for (final MushafLine l in p.lines) {
        if (l.segments.isEmpty) {
          throw LayoutFormatException(
            'page ${p.pageNumber}: empty line',
          );
        }
      }
    }
    _validateAyahContinuity(pages);
  }

  /// Ayat must appear in recitation order, exactly once at start.
  static void _validateAyahContinuity(List<MushafPage> pages) {
    int lastSurah = 1;
    int lastAyah = 0;
    for (final MushafPage p in pages) {
      for (final MushafLine l in p.lines) {
        for (final LayoutSegment s in l.segments) {
          if (!s.startsNewAyah) continue;
          final int sN = s.surah ?? 0;
          final int aN = s.ayah ?? 0;
          if (aN != 1) {
            // Continuing a surah: must follow the previous ayah exactly.
            if (sN != lastSurah || aN != lastAyah + 1) {
              throw LayoutFormatException(
                'ayah $sN:$aN out of order (after $lastSurah:$lastAyah)',
              );
            }
          } else {
            // Ayah 1 of a surah: any surah, but never a step backwards.
            if (sN < lastSurah) {
              throw LayoutFormatException(
                'surah regression at $sN:1 (after surah $lastSurah)',
              );
            }
          }
          lastSurah = sN;
          lastAyah = aN;
        }
      }
    }
  }

  /// Find where an ayah begins. Returns null if not in the layout.
  static AyahLocation? findAyah(List<MushafPage> pages, int surah, int ayah) {
    for (final MushafPage p in pages) {
      for (int i = 0; i < p.lines.length; i++) {
        for (final LayoutSegment s in p.lines[i].segments) {
          if (s.startsNewAyah && s.surah == surah && s.ayah == ayah) {
            return AyahLocation(p.pageNumber, i);
          }
        }
      }
    }
    return null;
  }

  /// All pages between two locations (inclusive) — for range playback
  /// and screen paging.
  static List<MushafPage> pagesBetween(
    List<MushafPage> pages,
    AyahLocation from,
    AyahLocation to,
  ) {
    return pages
        .where((MushafPage p) =>
            p.pageNumber >= from.page && p.pageNumber <= to.page)
        .toList();
  }
}

class LayoutFormatException implements Exception {
  LayoutFormatException(this.message);
  final String message;
  @override
  String toString() => 'LayoutFormatException: $message';
}
