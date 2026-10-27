import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ar_rayaan/features/games/chess/chess_board_art.dart';
import 'package:ar_rayaan/features/games/chess/chess_settings.dart';
import 'package:flutter_test/flutter_test.dart';

/// The board pictures include their gold frame, so pieces and highlights are
/// laid on a measured 8 x 8 playing area. These tests pin that area against
/// the manifest and against the picture's own pixels.
class _Img {
  _Img(this.w, this.h, this.rgba);
  final int w;
  final int h;
  final List<int> rgba;
  double lum(int x, int y) {
    final int i = (y * w + x) * 4;
    return (rgba[i] + rgba[i + 1] + rgba[i + 2]) / 3;
  }

  /// Mean luminance of a (2*half)^2 patch.
  double patch(double x, double y, int half) {
    double s = 0;
    int n = 0;
    for (int yy = y.round() - half; yy < y.round() + half; yy++) {
      for (int xx = x.round() - half; xx < x.round() + half; xx++) {
        s += lum(xx, yy);
        n++;
      }
    }
    return s / n;
  }
}

Future<_Img> _decode(String path) async {
  final ui.Codec codec =
      await ui.instantiateImageCodec(File(path).readAsBytesSync());
  final ui.Image img = (await codec.getNextFrame()).image;
  final ByteData d = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  return _Img(img.width, img.height, d.buffer.asUint8List(d.offsetInBytes, d.lengthInBytes));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Map<String, dynamic> boards = (jsonDecode(
    File('assets/games/art/manifest.json').readAsStringSync(),
  ) as Map<String, dynamic>)['boards'] as Map<String, dynamic>;

  group('board pictures and tiles', () {
    test('every theme has a picture; the default is Royal marble', () {
      expect(ChessBoardTheme.values.first, ChessBoardTheme.royal);
      expect(const ChessSettings().theme, ChessBoardTheme.royal);
      expect(ChessBoardTheme.royal.label, 'Royal marble');
      for (final ChessBoardTheme t in ChessBoardTheme.values) {
        final String? p = ChessBoardArt.board(t);
        expect(p, isNotNull, reason: t.name);
        expect(File(p!).existsSync(), isTrue, reason: p);
      }
      expect(ChessBoardArt.awaited, isEmpty);
    });

    test('tiles: every theme has selected and legal-move; grey draws last-move',
        () {
      for (final ChessBoardTheme t in ChessBoardTheme.values) {
        for (final ChessHighlight h in ChessHighlight.values) {
          final String? p = ChessBoardArt.highlight(t, h);
          if (t == ChessBoardTheme.royal) {
            expect(p, isNull, reason: 'royal has no tiles: code-drawn glow');
          } else if (t == ChessBoardTheme.grey && h == ChessHighlight.lastMove) {
            expect(p, isNull);
          } else {
            expect(p, isNotNull, reason: '${t.name} ${h.name}');
            expect(File(p!).existsSync(), isTrue, reason: p);
          }
        }
      }
    });

    test('every shipped file is on disk and the folder holds nothing else', () {
      final Set<String> onDisk = Directory(ChessBoardArt.folder)
          .listSync()
          .whereType<File>()
          .map((File f) => f.path)
          .toSet();
      expect(onDisk, ChessBoardArt.shipped);
    });

    test('file names follow chess_board_<theme>[_highlight_<kind>]', () {
      expect(
        ChessBoardArt.highlightCandidates(ChessBoardTheme.grey, ChessHighlight.lastMove),
        <String>[
          'assets/games/chess/boards/chess_board_grey_highlight_last_move.png',
          'assets/games/chess/boards/chess_board_grey_highlight_last_move.webp',
        ],
      );
      expect(
        ChessBoardArt.boardCandidates(ChessBoardTheme.classic).first,
        'assets/games/chess/boards/chess_board_classic.webp',
      );
    });

    test('pictures are under 400 KB and tiles under 60 KB', () {
      for (final String p in ChessBoardArt.shipped) {
        final int n = File(p).lengthSync();
        expect(n, lessThan(p.endsWith('.png') ? 60 * 1024 : 400 * 1024), reason: p);
      }
    });
  });

  group('playing-area geometry', () {
    test('the constants equal the measured values in the manifest', () {
      for (final ChessBoardTheme t in ChessBoardTheme.values) {
        final Map<String, dynamic> g = boards['chess_${t.name}'] as Map<String, dynamic>;
        final ChessBoardGrid c = ChessBoardArt.grid(t);
        expect(c.imageSize, (g['image'] as List<dynamic>).first, reason: t.name);
        expect(c.left, (g['left'] as num).toDouble(), reason: t.name);
        expect(c.top, (g['top'] as num).toDouble(), reason: t.name);
        expect(c.width, (g['width'] as num).toDouble(), reason: t.name);
        expect(c.height, (g['height'] as num).toDouble(), reason: t.name);
      }
    });

    test('the area is the inner 8 x 8 grid, centred inside the frame', () {
      for (final ChessBoardTheme t in ChessBoardTheme.values) {
        final ChessBoardGrid c = ChessBoardArt.grid(t);
        expect(c.left, inInclusiveRange(55, 85), reason: t.name);
        expect(c.top, inInclusiveRange(55, 85), reason: t.name);
        expect(c.imageSize - (c.left + c.width), closeTo(c.left, 3), reason: t.name);
        expect(c.imageSize - (c.top + c.height), closeTo(c.top, 6), reason: t.name);
        expect(c.width / c.height, closeTo(1, 0.02), reason: t.name);
      }
    });

    test('the pixels agree: square edges fall on the grid, colours alternate',
        () async {
      for (final ChessBoardTheme t in ChessBoardTheme.values) {
        final _Img img = await _decode(ChessBoardArt.board(t)!);
        final ChessBoardGrid g = ChessBoardArt.grid(t);
        final double cw = g.width / 8, ch = g.height / 8;
        // Edge strength across a grid line vs. in the middle of a square,
        // averaged over a column/row of squares.
        double edge(bool vertical, int k) {
          double s = 0;
          int n = 0;
          for (int i = 40; i < 1200 - 40; i += 3) {
            final int a = vertical ? (g.left + k * cw).round() : i;
            final int b = vertical ? i : (g.top + k * ch).round();
            if (vertical) {
              s += (img.lum(a - 4, b) - img.lum(a + 4, b)).abs();
            } else {
              s += (img.lum(a, b - 4) - img.lum(a, b + 4)).abs();
            }
            n++;
          }
          return s / n;
        }

        for (int k = 1; k < 8; k++) {
          for (final bool v in <bool>[true, false]) {
            final double on = edge(v, k);
            expect(on, greaterThan(25), reason: '${t.name} line $k vertical=$v');
          }
        }
        // Square (0,0) is light, (0,1) dark, and so on.
        double lightMin = 999, darkMax = 0;
        for (int r = 0; r < 8; r++) {
          for (int c = 0; c < 8; c++) {
            final double l = img.patch(g.left + (c + 0.5) * cw, g.top + (r + 0.5) * ch, 18);
            if ((r + c) % 2 == 0) {
              if (l < lightMin) lightMin = l;
            } else {
              if (l > darkMax) darkMax = l;
            }
          }
        }
        expect(lightMin, greaterThan(darkMax), reason: '${t.name}: a8 must be light');
      }
    });
  });
}
