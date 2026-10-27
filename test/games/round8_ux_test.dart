import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/games/presentation/ludo_screen.dart';
import 'package:ar_rayaan/features/games/ui/games_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Round 8 tester findings in the Games section: the Ludo die must roll when
/// it is tapped, and the filter / option chips must be as wide as their label
/// (they filled the whole row, one per line, in a Wrap).
void main() {
  Widget host(Widget child) => MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(body: Center(child: child)),
      );

  testWidgets('tapping the Ludo die rolls it when a roll is allowed',
      (WidgetTester tester) async {
    final SemanticsHandle sem = tester.ensureSemantics();
    int rolls = 0;
    await tester.pumpWidget(
      host(LudoDiceStage(value: 0, onTap: () => rolls++)),
    );
    await tester.tap(find.byType(LudoDiceStage));
    expect(rolls, 1);
    expect(find.bySemanticsLabel('Die, not rolled yet. Tap to roll'),
        findsOneWidget);
    sem.dispose();
  });

  testWidgets('the Ludo die does nothing and is no button when no roll is due',
      (WidgetTester tester) async {
    final SemanticsHandle sem = tester.ensureSemantics();
    await tester.pumpWidget(host(const LudoDiceStage(value: 4)));
    await tester.tap(find.byType(LudoDiceStage));
    expect(find.bySemanticsLabel('Die showing 4'), findsOneWidget);
    expect(find.bySemanticsLabel('Die, not rolled yet. Tap to roll'),
        findsNothing);
    sem.dispose();
  });

  testWidgets('GameChip is as wide as its label, so chips share a row',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 360,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final String l in <String>['5', '10', '15', '20'])
                GameChip(label: l, selected: l == '5', onTap: () {}),
            ],
          ),
        ),
      ),
    );
    final Finder chips = find.byType(GameChip);
    expect(chips, findsNWidgets(4));
    for (int i = 0; i < 4; i++) {
      expect(tester.getSize(chips.at(i)).width, lessThan(120));
    }
    // All four on one line.
    final double y0 = tester.getTopLeft(chips.at(0)).dy;
    for (int i = 1; i < 4; i++) {
      expect(tester.getTopLeft(chips.at(i)).dy, y0);
    }
  });

  testWidgets('GameChip still fills a tight-width parent',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              GameChip(label: 'Solo', selected: false, onTap: () {}),
            ],
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(GameChip)).width, 300);
  });
}
