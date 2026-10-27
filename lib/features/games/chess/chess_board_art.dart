import 'dart:ui' show Rect;

import '../ui/games_art.dart';
import 'chess_settings.dart';

/// Where the 8 x 8 playing area is inside a board PICTURE (the picture
/// includes its gold frame). All numbers are pixels of the shipped file and are
/// measured by `tool/process_game_art.py`, which also writes them to
/// `assets/games/art/manifest.json` ("boards"); `test/games/chess_board_art_test.dart`
/// checks them against the manifest and against the picture's pixels.
class ChessBoardGrid {
  const ChessBoardGrid({
    required this.imageSize,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double imageSize;
  final double left;
  final double top;
  final double width;
  final double height;

  /// The playing area as fractions of the picture's side.
  Rect get fractions => Rect.fromLTWH(
        left / imageSize,
        top / imageSize,
        width / imageSize,
        height / imageSize,
      );
}

/// The kinds of highlight tile a board can come with.
enum ChessHighlight { selected, legalMove, lastMove }

extension ChessHighlightFile on ChessHighlight {
  String get fileKey => switch (this) {
        ChessHighlight.selected => 'selected',
        ChessHighlight.legalMove => 'legal_move',
        ChessHighlight.lastMove => 'last_move',
      };
}

/// The chess board pictures and highlight tiles, and how to add more.
///
/// To add a theme's picture, drop `chess_board_<theme>.png` (or `.webp`) into
/// `assets/games/chess/boards/`; for its tiles drop
/// `chess_board_<theme>_highlight_{selected,legal_move,last_move}.png` there
/// too. The loader finds them through the asset list, no code change. The
/// frame of a new picture may differ from the shipped ones: re-measure with
/// `python3 tool/process_game_art.py --measure-only` and put the numbers in
/// [grid]. A theme with no picture draws the older textured squares, and a
/// missing tile draws a code-drawn glow in [accent].
abstract final class ChessBoardArt {
  static const String folder = 'assets/games/chess/boards/';

  /// Files shipped in the app. Anything else is looked up in the asset list.
  static final Set<String> shipped = <String>{
    '${folder}chess_board_royal.webp',
    '${folder}chess_board_green.webp',
    '${folder}chess_board_blue.webp',
    '${folder}chess_board_grey.webp',
    '${folder}chess_board_classic.webp',
    for (final String t in <String>['green', 'blue', 'classic'])
      for (final String k in <String>['selected', 'legal_move', 'last_move'])
        '${folder}chess_board_${t}_highlight_$k.png',
    '${folder}chess_board_grey_highlight_selected.png',
    '${folder}chess_board_grey_highlight_legal_move.png',
  };

  /// Files still awaited from the designer: none. (The grey last-move tile
  /// that was delivered is opaque and fringed, so it is not used: the Grey
  /// board draws a soft silver-gold tint in code, see [lastMoveTint].)
  static const List<String> awaited = <String>[];

  /// Colour of the code-drawn last-move tint, for a theme without a tile.
  static int lastMoveTint(ChessBoardTheme t) =>
      t == ChessBoardTheme.grey ? 0xFFD8C79A : accent(t);

  /// The playing area of each theme's picture, as measured on the shipped
  /// file (all five share one frame, to within a pixel).
  static ChessBoardGrid grid(ChessBoardTheme t) => switch (t) {
        ChessBoardTheme.royal => const ChessBoardGrid(
            imageSize: 1254,
            left: 69.9,
            top: 64.8,
            width: 1112.9,
            height: 1121.0,
          ),
        ChessBoardTheme.green => const ChessBoardGrid(
            imageSize: 1254,
            left: 69.9,
            top: 64.8,
            width: 1112.7,
            height: 1120.9,
          ),
        ChessBoardTheme.blue => const ChessBoardGrid(
            imageSize: 1254,
            left: 69.9,
            top: 64.7,
            width: 1112.6,
            height: 1120.9,
          ),
        ChessBoardTheme.grey => const ChessBoardGrid(
            imageSize: 1254,
            left: 69.8,
            top: 64.1,
            width: 1112.4,
            height: 1121.2,
          ),
        ChessBoardTheme.classic => const ChessBoardGrid(
            imageSize: 1254,
            left: 69.8,
            top: 64.1,
            width: 1113.0,
            height: 1120.6,
          ),
      };

  /// The accent of a theme: the colour of the code-drawn highlight glow.
  static int accent(ChessBoardTheme t) => switch (t) {
        ChessBoardTheme.royal => 0xFFE8C96A,
        ChessBoardTheme.green => 0xFF3DDC84,
        ChessBoardTheme.blue => 0xFF4DA3FF,
        ChessBoardTheme.grey => 0xFFFFFFFF,
        ChessBoardTheme.classic => 0xFFFFA040,
      };

  static String boardStem(ChessBoardTheme t) =>
      '${folder}chess_board_${t.name}';

  static String highlightStem(ChessBoardTheme t, ChessHighlight h) =>
      '${boardStem(t)}_highlight_${h.fileKey}';

  /// The file names a theme's picture is looked for under, best first.
  static List<String> boardCandidates(ChessBoardTheme t) =>
      <String>['${boardStem(t)}.webp', '${boardStem(t)}.png'];

  static List<String> highlightCandidates(ChessBoardTheme t, ChessHighlight h) =>
      <String>['${highlightStem(t, h)}.png', '${highlightStem(t, h)}.webp'];

  static String? _find(List<String> candidates) {
    for (final String p in candidates) {
      if (shipped.contains(p) || GamesArt.hasAsset(p) == true) return p;
    }
    return null;
  }

  /// The theme's board picture, or null when there is none (textured squares
  /// are drawn instead).
  static String? board(ChessBoardTheme t) => _find(boardCandidates(t));

  /// The theme's tile for [h], or null (a code-drawn glow is drawn instead).
  static String? highlight(ChessBoardTheme t, ChessHighlight h) =>
      _find(highlightCandidates(t, h));

  /// Every shipped file; the asset test checks each exists and that nothing
  /// in the folder is unused.
  static List<String> get allShipped => shipped.toList()..sort();
}
