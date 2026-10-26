/// Where things are on the owner's Ludo board picture.
///
/// All numbers are pixels of `assets/games/ludo/board.webp` (863 x 686),
/// measured on that file. They are DATA: if the picture is replaced (see
/// `tool/crop_game_boards.py` and the asset list in the Ludo PR), re-measure
/// these and nothing else in the game changes.
///
/// The picture is drawn in perspective (cells near the bottom are bigger), so
/// [pawnScaleAt] grows with y.
library;

import 'ludo_rules.dart';

abstract final class LudoBoardArt {
  static const String board = 'assets/games/ludo/board.webp';
  static const String dice = 'assets/games/ludo/dice_idle.webp';

  /// Sprite files per colour (red, blue, yellow, green). A name slot: drop a
  /// better PNG/WebP of the same name over the file and it is picked up.
  static const List<String> pawnFiles = <String>[
    'assets/games/ludo/pawn_red.webp',
    'assets/games/ludo/pawn_blue.webp',
    'assets/games/ludo/pawn_yellow.webp',
    'assets/games/ludo/pawn_green.webp',
  ];

  static const double imageWidth = 863;
  static const double imageHeight = 686;

  /// Sprite canvas (px) and where the middle of the pawn's base plate is on
  /// it; a pawn is drawn so that this point lands on the cell centre.
  static const double spriteWidth = 72;
  static const double spriteHeight = 88;
  static const LudoPt spriteAnchor = LudoPt(36, 72);

  /// Pawn size relative to the sprite: smallest at the top of the picture,
  /// largest at the bottom, because of the perspective.
  static double pawnScaleAt(double y) {
    final double t = ((y - 40) / 600).clamp(0.0, 1.0);
    return 0.70 + 0.16 * t;
  }

  /// Pawns standing in a yard socket are drawn a little larger.
  static const double yardScale = 0.84;

  /// The 46 cells of the shared loop, clockwise from the top arrow square.
  static const List<LudoPt> loop = <LudoPt>[
    LudoPt(434, 39), // 0 top arrow (red entry)
    LudoPt(486, 40), LudoPt(487, 75), LudoPt(488, 110), //  1-3 top arm, right
    LudoPt(488, 147), LudoPt(489, 186), LudoPt(489, 226), //  4-6
    LudoPt(543, 259), LudoPt(597, 260), LudoPt(649, 260), // 7-9 right arm, top
    LudoPt(701, 260), LudoPt(753, 261), // 10-11
    LudoPt(758, 306), // 12 right end (yellow entry)
    LudoPt(764, 354), LudoPt(710, 354), LudoPt(656, 358), // 13-15 bottom row
    LudoPt(602, 354), LudoPt(547, 357), // 16-17
    LudoPt(492, 399), LudoPt(492, 444), LudoPt(493, 491), // 18-20 bottom arm
    LudoPt(494, 542), LudoPt(495, 598), // 21-22
    LudoPt(432, 597), // 23 bottom end (green entry)
    LudoPt(369, 598), LudoPt(371, 542), LudoPt(372, 491), // 24-26
    LudoPt(373, 444), LudoPt(374, 399), // 27-28
    LudoPt(320, 354), LudoPt(265, 354), LudoPt(211, 354), // 29-31 left arm
    LudoPt(156, 357), LudoPt(100, 354), // 32-33
    LudoPt(107, 307), // 34 left end (blue entry)
    LudoPt(112, 260), LudoPt(165, 260), LudoPt(218, 260), // 35-37 left arm top
    LudoPt(270, 260), LudoPt(324, 260), // 38-39
    LudoPt(378, 226), LudoPt(379, 186), LudoPt(380, 147), // 40-42 top arm, left
    LudoPt(381, 110), LudoPt(382, 75), LudoPt(382, 39), // 43-45
  ];

  /// Home-column cells per colour (red, blue, yellow, green), in walking
  /// order from the cell after the entry square to the one before home.
  static const List<List<LudoPt>> column = <List<LudoPt>>[
    <LudoPt>[
      LudoPt(433, 76), LudoPt(433, 111), LudoPt(433, 148),
      LudoPt(433, 187), LudoPt(433, 227),
    ],
    <LudoPt>[
      LudoPt(160, 307), LudoPt(214, 307), LudoPt(268, 307), LudoPt(322, 307),
    ],
    <LudoPt>[
      LudoPt(706, 306), LudoPt(653, 306), LudoPt(600, 306), LudoPt(547, 306),
    ],
    <LudoPt>[
      LudoPt(432, 542), LudoPt(432, 491), LudoPt(432, 444), LudoPt(432, 399),
    ],
  ];

  /// Pawn sockets in the four yards, per colour, token 0..3: top left, top
  /// right, bottom left, bottom right.
  static const List<List<LudoPt>> yard = <List<LudoPt>>[
    <LudoPt>[LudoPt(189, 106), LudoPt(269, 103), LudoPt(184, 170), LudoPt(265, 170)],
    <LudoPt>[LudoPt(599, 106), LudoPt(676, 106), LudoPt(602, 169), LudoPt(682, 167)],
    <LudoPt>[LudoPt(627, 474), LudoPt(715, 468), LudoPt(630, 550), LudoPt(721, 550)],
    <LudoPt>[LudoPt(148, 473), LudoPt(238, 474), LudoPt(141, 550), LudoPt(235, 545)],
  ];

  /// Where finished pawns of each colour rest, inside its centre triangle.
  static const List<LudoPt> homeCentre = <LudoPt>[
    LudoPt(433, 270), // red, top triangle
    LudoPt(385, 308), // blue, left
    LudoPt(488, 310), // yellow, right
    LudoPt(428, 342), // green, bottom
  ];

  /// Offsets (before scaling) of up to four finished pawns around a centre.
  static const List<LudoPt> homeSpread = <LudoPt>[
    LudoPt(-9, -4), LudoPt(9, -4), LudoPt(-9, 8), LudoPt(9, 8),
  ];

  /// Size of a finished pawn relative to a normal one.
  static const double homeScale = 0.42;

  /// Cell size (px of the picture) for tap and highlight circles, by y.
  static double cellRadiusAt(double y) => 20 + 6 * ((y - 40) / 600).clamp(0.0, 1.0);

  /// Where a token stands, as a point of the picture.
  /// [colour] 0..3, [p] progress (-1 yard .. 49 home), [token] 0..3 and, for a
  /// finished token, [homeRank] (0..3) in the pile of finished pawns.
  static LudoPt position(int colour, int p, int token, {int homeRank = 0}) {
    if (p < 0) return yard[colour][token];
    if (p >= LudoRules.finished) {
      final LudoPt c = homeCentre[colour];
      final LudoPt d = homeSpread[homeRank.clamp(0, 3)];
      return LudoPt(c.x + d.x, c.y + d.y);
    }
    final int? cell = LudoRules.loopCell(colour, p);
    if (cell != null) return loop[cell];
    return column[colour][LudoRules.columnIndex(colour, p)!];
  }
}

/// A point on the board picture.
class LudoPt {
  const LudoPt(this.x, this.y);
  final double x;
  final double y;
}
