import 'package:ar_rayaan/features/academy/domain/mushaf_layout.dart';
import 'package:flutter_test/flutter_test.dart';

/// SCAFFOLD helper — builds structurally valid fake pages for engine
/// tests. NEVER authentic Madinah geometry; production data comes from
/// the checksum-verified content pack.
List<MushafPage> buildScaffoldPages() {
  // One ayah per page, 15 lines each, markers on line 8.
  final List<MushafPage> pages = <MushafPage>[];
  for (int pg = 1; pg <= MushafPage.totalPages; pg++) {
    pages.add(
      MushafPage(
        pageNumber: pg,
        lines: <MushafLine>[
          for (int ln = 0; ln < MushafPage.linesPerPage; ln++)
            MushafLine(<LayoutSegment>[
              if (ln == 0)
                LayoutSegment(
                  text: 'scaffold-ayah-$pg',
                  surah: 114,
                  ayah: pg,
                  startsNewAyah: true,
                  endsAyah: ln == MushafPage.linesPerPage - 1,
                )
              else
                const LayoutSegment(text: '·', marker: true),
            ]),
        ],
      ),
    );
  }
  return pages;
}

void main() {
  group('MushafLayoutEngine.validate', () {
    test('accepts a structurally valid 604×15 layout', () {
      expect(() => MushafLayoutEngine.validate(buildScaffoldPages()),
          returnsNormally);
    });

    test('rejects wrong page count', () {
      final pages = buildScaffoldPages()..removeLast();
      expect(() => MushafLayoutEngine.validate(pages),
          throwsA(isA<LayoutFormatException>()));
    });

    test('rejects wrong line count on any page', () {
      final pages = buildScaffoldPages();
      final bad = MushafPage(
        pageNumber: 10,
        lines: pages[9].lines.sublist(0, 14),
      );
      pages[9] = bad;
      expect(() => MushafLayoutEngine.validate(pages),
          throwsA(isA<LayoutFormatException>()));
    });

    test('rejects empty lines', () {
      final pages = buildScaffoldPages();
      pages[3] = MushafPage(
        pageNumber: 4,
        lines: <MushafLine>[
          pages[3].lines[0],
          const MushafLine(<LayoutSegment>[]),
          ...pages[3].lines.sublist(2),
        ],
      );
      expect(() => MushafLayoutEngine.validate(pages),
          throwsA(isA<LayoutFormatException>()));
    });

    test('rejects ayah order violations', () {
      final pages = buildScaffoldPages();
      // Page 5 claims to start ayah 9:5 while page 4 started 114:4.
      pages[4] = MushafPage(
        pageNumber: 5,
        lines: <MushafLine>[
          MushafLine(<LayoutSegment>[
            LayoutSegment(
              text: 'x',
              surah: 9,
              ayah: 5,
              startsNewAyah: true,
            ),
          ]),
          ...pages[4].lines.sublist(1),
        ],
      );
      expect(() => MushafLayoutEngine.validate(pages),
          throwsA(isA<LayoutFormatException>()));
    });
  });

  group('MushafLayoutEngine.findAyah', () {
    test('locates an ayah at its page and line', () {
      final pages = buildScaffoldPages();
      // Scaffold: page N line 0 starts "ayah N" of surah 114.
      final loc = MushafLayoutEngine.findAyah(pages, 114, 604);
      expect(loc, isNotNull);
      expect(loc!.page, 604);
      expect(loc.lineIndex, 0);
    });

    test('returns null for a missing ayah', () {
      final pages = buildScaffoldPages();
      expect(MushafLayoutEngine.findAyah(pages, 2, 999), isNull);
    });
  });

  group('MushafLayoutEngine.pagesBetween', () {
    test('returns inclusive page span', () {
      final pages = buildScaffoldPages();
      final from = AyahLocation(10, 0);
      final to = AyahLocation(12, 0);
      final span = MushafLayoutEngine.pagesBetween(pages, from, to);
      expect(span.map((p) => p.pageNumber), <int>[10, 11, 12]);
    });
  });

  group('line locking invariant', () {
    test('every page has exactly 15 lines (the recall contract)', () {
      final pages = buildScaffoldPages();
      MushafLayoutEngine.validate(pages);
      for (final p in pages) {
        expect(p.lines.length, MushafPage.linesPerPage);
      }
    });
  });
}
