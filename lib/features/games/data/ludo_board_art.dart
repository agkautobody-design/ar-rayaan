/// Where things are on the owner's Ludo board picture.
///
/// The picture (`assets/games/ludo/board.webp`, 1254 x 1254) is the STANDARD
/// 15 x 15 Ludo board inside a gold frame. Squares are addressed as
/// (col, row), counted from the top-left square of the 15 x 15 playing grid.
/// The grid is measured on the file by `tool/process_game_art.py` (it writes
/// the same numbers to `assets/games/art/manifest.json` under "boards.ludo",
/// and `test/games/ludo_board_art_test.dart` checks the constants against
/// both the manifest and the picture's pixels). If the picture is replaced,
/// re-run that script and copy the new numbers here.
///
/// Layout (cells): arms 6 long and 3 wide; yards 6 x 6 in the corners:
/// Red top-left (0-5, 0-5), Blue top-right (9-14, 0-5), Yellow bottom-right
/// (9-14, 9-14), Green bottom-left (0-5, 9-14).
///
/// Home columns (five coloured squares leading to the centre): Red column 7
/// rows 1-5, Blue row 7 cols 13..9, Yellow column 7 rows 13..9, Green row 7
/// cols 1-5. Start squares: Red (8,1), Blue (13,8), Yellow (6,13), Green
/// (1,6). Gold stars: those four plus (6,2), (12,6), (8,12), (2,8).
library;

import 'ludo_rules.dart';

/// A square of the 15 x 15 grid.
class LudoCell {
  const LudoCell(this.col, this.row);
  final int col;
  final int row;

  @override
  bool operator ==(Object other) =>
      other is LudoCell && other.col == col && other.row == row;

  @override
  int get hashCode => col * 31 + row;

  @override
  String toString() => '($col,$row)';
}

/// A point on the board picture, in pixels of the 1254 px file.
class LudoPt {
  const LudoPt(this.x, this.y);
  final double x;
  final double y;
}

abstract final class LudoBoardArt {
  static const String board = 'assets/games/ludo/board.webp';

  /// The face a die shows before the first roll and while it is rolling.
  static const String dieRolling = 'assets/games/ludo/die_rolling.webp';

  /// Sprite per colour (red, blue, yellow, green). Shapes on the top disc:
  /// red circle, blue diamond, yellow triangle, green square.
  static const List<String> pawnFiles = <String>[
    'assets/games/ludo/pawn_red.webp',
    'assets/games/ludo/pawn_blue.webp',
    'assets/games/ludo/pawn_yellow.webp',
    'assets/games/ludo/pawn_green.webp',
  ];

  /// 'assets/games/ludo/die_4.webp' for a four (1 to 6).
  static String dieFace(int value) => 'assets/games/ludo/die_$value.webp';

  static List<String> get allFiles => <String>[
        board,
        dieRolling,
        ...pawnFiles,
        for (int v = 1; v <= 6; v++) dieFace(v),
      ];

  /// Size of the picture and of its square playing grid (measured).
  static const double imageSize = 1254;
  static const double gridLeft = 76.83;
  static const double gridTop = 76.69;
  static const double cell = 73.56;
  static const int gridCells = 15;

  /// Pixel centre of a square.
  static LudoPt centreOf(num col, num row) =>
      LudoPt(gridLeft + (col + 0.5) * cell, gridTop + (row + 0.5) * cell);

  /// The 52 squares of the shared loop, clockwise from the top of the top
  /// arm, (8,0). Index = [LudoRules] loop square.
  static final List<LudoCell> loop = List<LudoCell>.unmodifiable(<LudoCell>[
    for (int r = 0; r <= 5; r++) LudoCell(8, r), //            0-5
    for (int c = 9; c <= 14; c++) LudoCell(c, 6), //           6-11
    const LudoCell(14, 7), //                                  12
    for (int c = 14; c >= 9; c--) LudoCell(c, 8), //           13-18
    for (int r = 9; r <= 14; r++) LudoCell(8, r), //           19-24
    const LudoCell(7, 14), //                                  25
    for (int r = 14; r >= 9; r--) LudoCell(6, r), //           26-31
    for (int c = 5; c >= 0; c--) LudoCell(c, 8), //            32-37
    const LudoCell(0, 7), //                                   38
    for (int c = 0; c <= 5; c++) LudoCell(c, 6), //            39-44
    for (int r = 5; r >= 0; r--) LudoCell(6, r), //            45-50
    const LudoCell(7, 0), //                                   51
  ]);

  /// Home-column squares per colour (red, blue, yellow, green), in walking
  /// order from the square after the entry square to the last one.
  static const List<List<LudoCell>> column = <List<LudoCell>>[
    <LudoCell>[
      LudoCell(7, 1), LudoCell(7, 2), LudoCell(7, 3), LudoCell(7, 4),
      LudoCell(7, 5),
    ],
    <LudoCell>[
      LudoCell(13, 7), LudoCell(12, 7), LudoCell(11, 7), LudoCell(10, 7),
      LudoCell(9, 7),
    ],
    <LudoCell>[
      LudoCell(7, 13), LudoCell(7, 12), LudoCell(7, 11), LudoCell(7, 10),
      LudoCell(7, 9),
    ],
    <LudoCell>[
      LudoCell(1, 7), LudoCell(2, 7), LudoCell(3, 7), LudoCell(4, 7),
      LudoCell(5, 7),
    ],
  ];

  /// Start squares per colour.
  static const List<LudoCell> start = <LudoCell>[
    LudoCell(8, 1), LudoCell(13, 8), LudoCell(6, 13), LudoCell(1, 6),
  ];

  /// The four stars that are not start squares.
  static const List<LudoCell> extraStars = <LudoCell>[
    LudoCell(6, 2), LudoCell(12, 6), LudoCell(8, 12), LudoCell(2, 8),
  ];

  /// The four pawn sockets of each yard, per colour, token 0..3 (top left,
  /// top right, bottom left, bottom right). Measured centres of the holes, in
  /// cell units from the grid's top-left corner (so 2.2 is a fifth of the way
  /// into the third column).
  static const List<List<(double, double)>> yardUnits =
      <List<(double, double)>>[
    <(double, double)>[
      (2.2, 2.35),
      (4.2, 2.35),
      (2.2, 4.14),
      (4.2, 4.14),
    ],
    <(double, double)>[
      (10.9, 2.35),
      (12.83, 2.34),
      (10.89, 4.13),
      (12.83, 4.13),
    ],
    <(double, double)>[
      (10.89, 10.94),
      (12.83, 10.9),
      (10.91, 12.68),
      (12.82, 12.68),
    ],
    <(double, double)>[
      (2.18, 10.91),
      (4.2, 10.9),
      (2.18, 12.7),
      (4.2, 12.7),
    ],
  ];

  /// Where finished pawns of each colour rest: the middle of its triangle of
  /// the centre square (cell units): red top, blue right, yellow bottom,
  /// green left.
  static const List<(double, double)> homeUnits = <(double, double)>[
    (7.5, 6.55), (8.45, 7.5), (7.5, 8.45), (6.55, 7.5),
  ];

  /// Offsets, in cells, of up to four finished pawns around a triangle's
  /// middle.
  static const List<(double, double)> homeSpread = <(double, double)>[
    (-0.28, -0.12), (0.28, -0.12), (-0.28, 0.16), (0.28, 0.16),
  ];

  /// Pawn sprite: side of its square image, in cells, and where the middle of
  /// its base sits in that image (fraction of the side). A pawn is drawn so
  /// the base middle lands a little below the square's centre.
  static const double spriteCells = 1.75;
  static const double spriteBaseX = 0.5;
  static const double spriteBaseY = 0.93;
  static const double baseDrop = 0.30;

  /// Pawns standing in a yard socket, finished pawns, and pawns sharing a
  /// square, relative to a normal pawn.
  static const double yardScale = 1.0;
  static const double homeScale = 0.55;
  static const double sharedScale = 0.82;

  /// Where the number goes on a pawn (fraction of the sprite, centred on x):
  /// on the ball under the shape disc. Red and green have a lower disc.
  static const List<double> numberY = <double>[0.31, 0.19, 0.19, 0.31];

  /// Where a token stands, as a point of the picture.
  /// [colour] 0..3, [p] progress (-1 yard .. 56 home), [token] 0..3 and, for a
  /// finished token, [homeRank] (0..3) in the pile of finished pawns.
  static LudoPt position(int colour, int p, int token, {int homeRank = 0}) {
    if (p < 0) {
      final (double, double) u = yardUnits[colour][token];
      return centreOf(u.$1 - 0.5, u.$2 - 0.5);
    }
    if (p >= LudoRules.finished) {
      final (double, double) c = homeUnits[colour];
      final (double, double) d = homeSpread[homeRank.clamp(0, 3)];
      return centreOf(c.$1 + d.$1 - 0.5, c.$2 + d.$2 - 0.5);
    }
    final int? sq = LudoRules.loopCell(colour, p);
    if (sq != null) {
      final LudoCell c = loop[sq];
      return centreOf(c.col, c.row);
    }
    final LudoCell c = column[colour][LudoRules.columnIndex(colour, p)!];
    return centreOf(c.col, c.row);
  }
}
