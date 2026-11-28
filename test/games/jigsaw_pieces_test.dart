import 'dart:io';
import 'dart:ui';

import 'package:ar_rayaan/features/games/engine/jigsaw_cuts.dart';
import 'package:ar_rayaan/features/games/presentation/jigsaw_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

double _area(JigsawPiece p) {
  double a = 0;
  final List<double> q = p.points;
  final int n = q.length ~/ 2;
  for (int i = 0; i < n; i++) {
    final int j = (i + 1) % n;
    a += q[2 * i] * q[2 * j + 1] - q[2 * j] * q[2 * i + 1];
  }
  return a.abs() / 2;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('jigsaw cuts', () {
    test('eight pictures: four of 16 pieces, four of 12', () {
      expect(kJigsawCuts.length, 8);
      expect(
        kJigsawCuts.where((JigsawCut c) => c.pieces.length == 16).length,
        4,
      );
      expect(
        kJigsawCuts.where((JigsawCut c) => c.pieces.length == 12).length,
        4,
      );
      for (final JigsawCut c in kJigsawCuts) {
        expect(c.pieces.length, c.rows * c.cols, reason: c.asset);
        expect(File(c.asset).existsSync(), isTrue, reason: c.asset);
        expect(c.title, isNotEmpty);
      }
    });

    test('each piece is a real shaped piece in its own place', () {
      for (final JigsawCut c in kJigsawCuts) {
        final double cell = 1 / (c.rows * c.cols);
        double total = 0;
        int shaped = 0;
        for (int i = 0; i < c.pieces.length; i++) {
          final JigsawPiece p = c.pieces[i];
          final String why = '${c.asset} piece $i';
          expect(p.points.length, greaterThan(40), reason: why);
          expect(p.points.length.isEven, isTrue, reason: why);
          expect(p.x0, greaterThanOrEqualTo(0), reason: why);
          expect(p.y0, greaterThanOrEqualTo(0), reason: why);
          expect(p.x1, lessThanOrEqualTo(1), reason: why);
          expect(p.y1, lessThanOrEqualTo(1), reason: why);
          // Reading order: row by row, left to right.
          final double cx = (p.x0 + p.x1) / 2;
          final double cy = (p.y0 + p.y1) / 2;
          final int r = i ~/ c.cols;
          final int col = i % c.cols;
          expect(cx, closeTo((col + 0.5) / c.cols, 0.5 / c.cols), reason: why);
          expect(cy, closeTo((r + 0.5) / c.rows, 0.5 / c.rows), reason: why);
          final double a = _area(p);
          expect(a, greaterThan(cell * 0.6), reason: why);
          expect(a, lessThan(cell * 1.4), reason: why);
          total += a;
          // Tabs and blanks: the outline fills clearly less (or more) than
          // its bounding box, so it is not a plain square.
          if (a / (p.width * p.height) < 0.97) shaped++;
        }
        // The cut lines and the picture's margin take the rest.
        expect(total, inInclusiveRange(0.7, 1.0), reason: c.asset);
        expect(shaped, c.pieces.length, reason: '${c.asset} has square pieces');
      }
    });

    test('neighbouring pieces interlock without overlapping', () {
      const int grid = 110;
      for (final JigsawCut c in kJigsawCuts) {
        final List<Path> paths = <Path>[
          for (final JigsawPiece p in c.pieces)
            p.path(1).shift(Offset(p.x0, p.y0)),
        ];
        int twice = 0;
        int none = 0;
        for (int yy = 0; yy < grid; yy++) {
          for (int xx = 0; xx < grid; xx++) {
            final Offset o = Offset((xx + 0.5) / grid, (yy + 0.5) / grid);
            int hits = 0;
            for (int i = 0; i < paths.length; i++) {
              final JigsawPiece p = c.pieces[i];
              if (o.dx < p.x0 || o.dx > p.x1 || o.dy < p.y0 || o.dy > p.y1) {
                continue;
              }
              if (paths[i].contains(o)) hits++;
            }
            if (hits > 1) twice++;
            if (hits == 0) none++;
          }
        }
        expect(twice, lessThan(grid * grid * 0.004), reason: c.asset);
        // Only the thin cut lines and the margin are uncovered.
        expect(none, lessThan(grid * grid * 0.2), reason: c.asset);
      }
    });
  });

  group('jigsaw game', () {
    const double b = 560; // board side in a wide test window

    Future<void> open(WidgetTester tester, {int seed = 3}) async {
      tester.view.physicalSize = const Size(1000, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: JigsawScreen(seed: seed)));
      await tester.pump();
    }

    JigsawCut shown(WidgetTester tester) {
      for (final Image img in tester.widgetList<Image>(find.byType(Image))) {
        final ImageProvider<Object> p = img.image;
        if (p is AssetImage && p.assetName.startsWith('assets/games/jigsaw/')) {
          return kJigsawCuts.firstWhere((JigsawCut c) => c.asset == p.assetName);
        }
      }
      throw StateError('no jigsaw picture on screen');
    }

    /// Index of the piece on top of the loose pile, given those done.
    int topLoose(WidgetTester tester, Set<int> done) {
      final Stack stack = tester.widget<Stack>(
        find.byKey(const ValueKey<String>('jigsaw-stack')),
      );
      int? top;
      for (final Widget w in stack.children) {
        final Key? k = w.key;
        if (k is ValueKey<int> && !done.contains(k.value)) top = k.value;
      }
      return top!;
    }

    Offset target(WidgetTester tester, JigsawPiece p) {
      final Offset board = tester.getTopLeft(
        find.byKey(const ValueKey<String>('jigsaw-board')),
      );
      return board + Offset(p.x0 * b, p.y0 * b);
    }

    Finder face(int i) => find.byKey(ValueKey<String>('jigsaw-piece-$i'));

    testWidgets('pieces start loose in the tray, below the board',
        (WidgetTester tester) async {
      await open(tester);
      final JigsawCut cut = shown(tester);
      final Offset board = tester.getTopLeft(
        find.byKey(const ValueKey<String>('jigsaw-board')),
      );
      expect(find.text('Placed: 0 of ${cut.pieces.length}'), findsOneWidget);
      for (int i = 0; i < cut.pieces.length; i++) {
        final Offset at = tester.getTopLeft(face(i));
        expect(at.dy, greaterThanOrEqualTo(board.dy + b), reason: 'piece $i');
      }
    });

    testWidgets('dragging a piece home clicks it in; a wrong drop does not',
        (WidgetTester tester) async {
      await open(tester);
      final JigsawCut cut = shown(tester);
      final Set<int> done = <int>{};
      final int first = topLoose(tester, done);
      final Offset home = target(tester, cut.pieces[first]);

      expect(
        find.descendant(of: face(first), matching: find.byType(Listener)),
        findsWidgets,
      );

      // Far from home: stays loose where it was dropped.
      await tester.drag(face(first), const Offset(0, -40));
      await tester.pump();
      expect(find.text('Placed: 0 of ${cut.pieces.length}'), findsOneWidget);

      // Close to home but not exactly on it: it clicks in.
      final Offset now = tester.getTopLeft(face(first));
      await tester.drag(face(first), home - now + const Offset(12, 8));
      await tester.pump();
      expect(find.text('Placed: 1 of ${cut.pieces.length}'), findsOneWidget);
      expect(tester.getTopLeft(face(first)).dx, closeTo(home.dx, 0.6));
      expect(tester.getTopLeft(face(first)).dy, closeTo(home.dy, 0.6));

      // A placed piece is locked: it no longer takes touches.
      expect(
        find.descendant(of: face(first), matching: find.byType(Listener)),
        findsNothing,
      );
    });

    for (final int count in <int>[16, 12]) {
      testWidgets('all $count pieces can be dragged home to finish',
          (WidgetTester tester) async {
        await open(tester, seed: count);
        if (count == 12) {
          await tester.tap(find.text('12 pieces'));
          await tester.pump();
        }
        final JigsawCut cut = shown(tester);
        expect(cut.pieces.length, count);
        final Set<int> done = <int>{};
        for (int step = 0; step < count; step++) {
          final int i = topLoose(tester, done);
          final Offset home = target(tester, cut.pieces[i]);
          final Offset now = tester.getTopLeft(face(i));
          await tester.drag(face(i), home - now);
          await tester.pump();
          expect(tester.getTopLeft(face(i)).dx, closeTo(home.dx, 0.6),
              reason: 'piece $i');
          done.add(i);
          expect(find.text('Placed: ${step + 1} of $count'), findsOneWidget);
        }
        expect(find.text('Picture complete'), findsOneWidget);
        expect(find.text('Play again'), findsOneWidget);
        // Playing again deals a different picture, loose again.
        await tester.tap(find.text('Play again'));
        await tester.pump();
        expect(find.text('Picture complete'), findsNothing);
        expect(shown(tester).asset, isNot(cut.asset));
        expect(find.text('Placed: 0 of $count'), findsOneWidget);
      });
    }

    testWidgets('a screen reader can place a piece without dragging',
        (WidgetTester tester) async {
      final SemanticsHandle sem = tester.ensureSemantics();
      await open(tester);
      final JigsawCut cut = shown(tester);
      final SemanticsNode node = tester.getSemantics(
        find.bySemanticsLabel(RegExp('Piece in row 1, column 1, loose')),
      );
      tester.binding.pipelineOwner.semanticsOwner!
          .performAction(node.id, SemanticsAction.tap);
      await tester.pump();
      expect(find.text('Placed: 1 of ${cut.pieces.length}'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Piece in row 1, column 1, placed')),
        findsOneWidget,
      );
      sem.dispose();
    });

    testWidgets('works on a phone-sized screen too', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: JigsawScreen(seed: 5)));
      await tester.pump();
      final JigsawCut cut = shown(tester);
      final Size board = tester.getSize(
        find.byKey(const ValueKey<String>('jigsaw-board')),
      );
      expect(board.width, 350);
      final int i = topLoose(tester, <int>{});
      final Offset home = tester.getTopLeft(
            find.byKey(const ValueKey<String>('jigsaw-board')),
          ) +
          Offset(cut.pieces[i].x0 * 350, cut.pieces[i].y0 * 350);
      await tester.drag(face(i), home - tester.getTopLeft(face(i)));
      await tester.pump();
      expect(find.text('Placed: 1 of ${cut.pieces.length}'), findsOneWidget);
    });
  });
}
