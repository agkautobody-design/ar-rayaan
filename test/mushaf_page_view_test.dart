import 'package:ar_rayaan/features/academy/domain/mushaf_layout.dart';
import 'package:ar_rayaan/features/academy/presentation/mushaf_page_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MushafPage scaffoldPage() {
  // Page 1: ayah 1:1 on line 0, ayah 1:2 on line 3 (segment-split across
  // lines 3-4 to exercise multi-line ayah + tap detection).
  return MushafPage(
    pageNumber: 1,
    lines: <MushafLine>[
      MushafLine(<LayoutSegment>[
        LayoutSegment(
            text: 'بِسْمِ اللَّهِ', surah: 1, ayah: 1, startsNewAyah: true),
        LayoutSegment(text: ' الرَّحْمَٰنِ', surah: 1, ayah: 1),
        LayoutSegment(
            text: ' الرَّحِيمِ ۝١', surah: 1, ayah: 1, endsAyah: true),
      ]),
      for (int i = 1; i < 15; i++)
        if (i == 3) ...[
          MushafLine(<LayoutSegment>[
            LayoutSegment(
                text: 'الْحَمْدُ', surah: 1, ayah: 2, startsNewAyah: true),
            LayoutSegment(text: ' لِلَّهِ', surah: 1, ayah: 2),
          ]),
        ] else if (i == 4) ...[
          MushafLine(<LayoutSegment>[
            LayoutSegment(
                text: 'رَبِّ الْعَالَمِينَ ۝٢', surah: 1, ayah: 2, endsAyah: true),
          ]),
        ] else
          MushafLine(<LayoutSegment>[
            const LayoutSegment(text: '·', marker: true),
          ]),
    ],
  );
}

void main() {
  testWidgets('renders exactly the page\'s 15 lines', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: MushafPageView(page: scaffoldPage()))),
    ));
    await tester.pumpAndSettle();
    // Line-locked contract: 15 Expanded rows inside the page column.
    expect(find.byType(Expanded), findsNWidgets(15));
    expect(find.textContaining('بِسْمِ'), findsOneWidget);
    expect(find.textContaining('رَبِّ الْعَالَمِينَ'), findsOneWidget);
  });

  testWidgets('tapping an ayah segment reports surah and ayah', (tester) async {
    int? tappedSurah;
    int? tappedAyah;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: MushafPageView(
            page: scaffoldPage(),
            onAyahTapped: (s, a) {
              tappedSurah = s;
              tappedAyah = a;
            },
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('الْحَمْدُ'));
    expect(tappedSurah, 1);
    expect(tappedAyah, 2);
  });

  testWidgets('playing ayah line gets the active tint', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: MushafPageView(
            page: scaffoldPage(),
            highlight: const AyahLocation(1, 3),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final Container? tinted = tester
        .widgetList<Container>(find.byType(Container))
        .cast<Container?>()
        .firstWhere(
          (Container? c) =>
              c?.decoration is BoxDecoration &&
              (c!.decoration as BoxDecoration).color != null,
          orElse: () => null,
        );
    expect(tinted, isNotNull, reason: 'highlighted line painted');
  });
}
