import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:ar_rayaan/features/games/data/ludo_board_art.dart';
import 'package:ar_rayaan/features/games/data/ludo_rules.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Ludo board picture is the STANDARD 15 x 15 board. These tests pin the
/// measured grid, the path geometry (52-square loop, 5-square home columns,
/// start squares, stars, yard sockets) and the picture's own pixels.
class _Pixels {
  _Pixels(this.w, this.h, this.rgba);
  final int w;
  final int h;
  final List<int> rgba;

  /// Median colour of a square patch centred on (x, y).
  List<int> median(double x, double y, {int half = 7}) {
    final List<int> r = <int>[], g = <int>[], b = <int>[];
    for (int yy = y.round() - half; yy < y.round() + half; yy++) {
      for (int xx = x.round() - half; xx < x.round() + half; xx++) {
        final int i = (yy * w + xx) * 4;
        r.add(rgba[i]);
        g.add(rgba[i + 1]);
        b.add(rgba[i + 2]);
      }
    }
    int m(List<int> v) => (v..sort())[v.length ~/ 2];
    return <int>[m(r), m(g), m(b)];
  }
}

Future<_Pixels> _decode(String path) async {
  final ui.Codec codec =
      await ui.instantiateImageCodec(File(path).readAsBytesSync());
  final ui.Image img = (await codec.getNextFrame()).image;
  final ByteData data =
      (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  return _Pixels(
    img.width,
    img.height,
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
  );
}

String _classify(List<int> c) {
  final int r = c[0], g = c[1], b = c[2];
  final int spread = <int>[r, g, b].reduce((int a, int x) => a > x ? a : x) -
      <int>[r, g, b].reduce((int a, int x) => a < x ? a : x);
  if (r > 195 && g > 175 && b > 130 && spread < 90) return 'cream';
  if (r > 150 && g < 100 && b < 100) return 'red';
  if (b > 100 && r < 90 && g < 130) return 'blue';
  if (r > 160 && g > 110 && b < 100) return 'yellow';
  if (g > 70 && r < 100 && b < 100) return 'green';
  return 'other';
}

bool _adjacent(LudoCell a, LudoCell b) =>
    (a.col - b.col).abs() <= 1 &&
    (a.row - b.row).abs() <= 1 &&
    !(a.col == b.col && a.row == b.row);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Ludo path geometry', () {
    test('the loop has 52 distinct squares, all on the arms, no centre', () {
      expect(LudoBoardArt.loop.length, LudoRules.loopLen);
      expect(LudoBoardArt.loop.toSet().length, 52);
      for (final LudoCell c in LudoBoardArt.loop) {
        final bool inCentre = c.col >= 6 && c.col <= 8 && c.row >= 6 && c.row <= 8;
        final bool inYard = (c.col <= 5 || c.col >= 9) && (c.row <= 5 || c.row >= 9);
        expect(inCentre || inYard, isFalse, reason: '$c');
        expect(c.col >= 0 && c.col < 15 && c.row >= 0 && c.row < 15, isTrue);
      }
    });

    test('each loop square touches the next, all the way round', () {
      for (int i = 0; i < 52; i++) {
        expect(
          _adjacent(LudoBoardArt.loop[i], LudoBoardArt.loop[(i + 1) % 52]),
          isTrue,
          reason: '$i ${LudoBoardArt.loop[i]} -> ${LudoBoardArt.loop[(i + 1) % 52]}',
        );
      }
    });

    test('start squares and stars sit where the board has them', () {
      for (int c = 0; c < 4; c++) {
        expect(LudoBoardArt.loop[LudoRules.startCell[c]], LudoBoardArt.start[c]);
      }
      expect(LudoBoardArt.start, const <LudoCell>[
        LudoCell(8, 1),
        LudoCell(13, 8),
        LudoCell(6, 13),
        LudoCell(1, 6),
      ]);
      final Set<LudoCell> safe = <LudoCell>{
        for (final int i in LudoRules.safeCells) LudoBoardArt.loop[i],
      };
      expect(safe, <LudoCell>{...LudoBoardArt.start, ...LudoBoardArt.extraStars});
      expect(LudoBoardArt.extraStars.toSet(), <LudoCell>{
        const LudoCell(6, 2),
        const LudoCell(12, 6),
        const LudoCell(8, 12),
        const LudoCell(2, 8),
      });
    });

    test('home columns: 5 squares each, leading from the entry to the centre', () {
      const List<List<LudoCell>> expected = <List<LudoCell>>[
        <LudoCell>[LudoCell(7, 1), LudoCell(7, 2), LudoCell(7, 3), LudoCell(7, 4), LudoCell(7, 5)],
        <LudoCell>[LudoCell(13, 7), LudoCell(12, 7), LudoCell(11, 7), LudoCell(10, 7), LudoCell(9, 7)],
        <LudoCell>[LudoCell(7, 13), LudoCell(7, 12), LudoCell(7, 11), LudoCell(7, 10), LudoCell(7, 9)],
        <LudoCell>[LudoCell(1, 7), LudoCell(2, 7), LudoCell(3, 7), LudoCell(4, 7), LudoCell(5, 7)],
      ];
      for (int c = 0; c < 4; c++) {
        expect(LudoBoardArt.column[c], expected[c]);
        final LudoCell entry = LudoBoardArt.loop[LudoRules.entryCell[c]];
        expect(_adjacent(entry, LudoBoardArt.column[c].first), isTrue, reason: 'colour $c');
        for (int i = 0; i < 4; i++) {
          expect(_adjacent(LudoBoardArt.column[c][i], LudoBoardArt.column[c][i + 1]), isTrue);
        }
        final LudoCell last = LudoBoardArt.column[c].last;
        final bool touchesCentre = (last.col - 7).abs() + (last.row - 7).abs() == 2;
        expect(touchesCentre, isTrue, reason: 'colour $c ends next to the centre');
      }
    });

    test('every colour walks 51 loop squares + 5 column squares + home', () {
      for (int c = 0; c < 4; c++) {
        final List<LudoCell> walked = <LudoCell>[];
        for (int p = 0; p <= LudoRules.finished; p++) {
          final LudoPt pt = LudoBoardArt.position(c, p, 0);
          expect(pt.x.isFinite && pt.y.isFinite, isTrue);
          final int? loop = LudoRules.loopCell(c, p);
          final int? col = LudoRules.columnIndex(c, p);
          if (p < 51) {
            expect(loop, isNotNull, reason: 'c$c p$p');
            walked.add(LudoBoardArt.loop[loop!]);
          } else if (p < 56) {
            expect(loop, isNull);
            expect(col, p - 51);
            walked.add(LudoBoardArt.column[c][col!]);
          } else {
            expect(loop, isNull);
            expect(col, isNull);
          }
        }
        expect(walked.length, 56);
        expect(walked.toSet().length, 56, reason: 'no square twice');
        expect(walked.first, LudoBoardArt.start[c]);
        for (int i = 0; i < walked.length - 1; i++) {
          expect(_adjacent(walked[i], walked[i + 1]), isTrue, reason: 'c$c step $i');
        }
        // The square just behind the start is never walked.
        final int behind = (LudoRules.startCell[c] + 51) % 52;
        expect(walked.contains(LudoBoardArt.loop[behind]), isFalse);
      }
    });

    test('yard sockets are inside each yard, the right way round', () {
      const List<(int, int)> origin = <(int, int)>[(0, 0), (9, 0), (9, 9), (0, 9)];
      for (int c = 0; c < 4; c++) {
        final List<(double, double)> s = LudoBoardArt.yardUnits[c];
        expect(s.length, 4);
        for (final (double, double) p in s) {
          expect(p.$1 > origin[c].$1 + 1 && p.$1 < origin[c].$1 + 5.5, isTrue);
          expect(p.$2 > origin[c].$2 + 1 && p.$2 < origin[c].$2 + 5.5, isTrue);
        }
        expect(s[0].$1 < s[1].$1 && s[0].$2 < s[2].$2, isTrue);
      }
    });

    test('2 players sit opposite: red and yellow; 4 go clockwise', () {
      expect(LudoRules.seatColours(2), <int>[0, 2]);
      expect(LudoRules.seatColours(4), <int>[0, 1, 2, 3]);
      expect(LudoRules.colourNames, <String>['Red', 'Blue', 'Yellow', 'Green']);
    });
  });

  group('Ludo board picture', () {
    final Map<String, dynamic> manifest = jsonDecode(
      File('assets/games/art/manifest.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    test('the constants equal the measured geometry in the manifest', () {
      final Map<String, dynamic> g =
          (manifest['boards'] as Map<String, dynamic>)['ludo'] as Map<String, dynamic>;
      expect(LudoBoardArt.gridLeft, (g['left'] as num).toDouble());
      expect(LudoBoardArt.gridTop, (g['top'] as num).toDouble());
      expect(LudoBoardArt.cell, (g['cell'] as num).toDouble());
      expect((g['image'] as List<dynamic>).first, LudoBoardArt.imageSize.round());
      final Map<String, dynamic> y = g['yard_sockets'] as Map<String, dynamic>;
      const List<String> names = <String>['red', 'blue', 'yellow', 'green'];
      for (int c = 0; c < 4; c++) {
        final List<dynamic> pts = y[names[c]] as List<dynamic>;
        for (int i = 0; i < 4; i++) {
          final List<dynamic> p = pts[i] as List<dynamic>;
          expect(LudoBoardArt.yardUnits[c][i].$1, (p[0] as num).toDouble());
          expect(LudoBoardArt.yardUnits[c][i].$2, (p[1] as num).toDouble());
        }
      }
      // 15 cells fit inside the picture with the frame around them.
      expect(LudoBoardArt.gridLeft + 15 * LudoBoardArt.cell,
          lessThan(LudoBoardArt.imageSize - 40));
    });

    test('the pixels agree: home columns, starts, stars, yard sockets', () async {
      final _Pixels px = await _decode(LudoBoardArt.board);
      expect(px.w, LudoBoardArt.imageSize.round());
      LudoPt at(num c, num r) => LudoBoardArt.centreOf(c, r);
      const List<String> names = <String>['red', 'blue', 'yellow', 'green'];
      for (int c = 0; c < 4; c++) {
        for (final LudoCell cell in LudoBoardArt.column[c]) {
          final LudoPt p = at(cell.col, cell.row);
          expect(_classify(px.median(p.x, p.y)), names[c], reason: '${names[c]} $cell');
        }
        final LudoCell s = LudoBoardArt.start[c];
        final LudoPt sp = at(s.col, s.row);
        // The star is in the middle of the square: read its corner.
        expect(
          _classify(px.median(sp.x - 0.3 * LudoBoardArt.cell, sp.y - 0.3 * LudoBoardArt.cell, half: 5)),
          names[c],
          reason: 'start ${names[c]}',
        );
      }
      // Plain track squares are cream.
      for (final LudoCell cell in <LudoCell>[
        const LudoCell(6, 0), const LudoCell(8, 3), const LudoCell(3, 6),
        const LudoCell(11, 8), const LudoCell(8, 10), const LudoCell(6, 11),
      ]) {
        final LudoPt p = at(cell.col, cell.row);
        expect(_classify(px.median(p.x, p.y)), 'cream', reason: '$cell');
      }
      // Stars: a patch with gold in it, where a plain cream square has none.
      for (final LudoCell cell in LudoBoardArt.extraStars) {
        final LudoPt p = at(cell.col, cell.row);
        int gold = 0, n = 0;
        for (int y = p.y.round() - 12; y < p.y.round() + 12; y++) {
          for (int x = p.x.round() - 12; x < p.x.round() + 12; x++) {
            final int i = (y * px.w + x) * 4;
            n++;
            if (px.rgba[i] > 150 && px.rgba[i + 1] > 100 && px.rgba[i + 2] < 100) gold++;
          }
        }
        expect(gold / n, greaterThan(0.03), reason: 'star at $cell');
      }
      // Yard sockets are dark holes.
      for (int c = 0; c < 4; c++) {
        for (final (double, double) u in LudoBoardArt.yardUnits[c]) {
          final LudoPt p = at(u.$1 - 0.5, u.$2 - 0.5);
          final List<int> m = px.median(p.x, p.y, half: 6);
          expect(m.reduce((int a, int b) => a > b ? a : b), lessThan(110),
              reason: 'socket ${names[c]} $u');
        }
      }
    });
  });
}
