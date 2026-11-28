import 'package:flutter/material.dart' hide Text;

import '../engine/board_engines.dart';

/// The Checkers board, from the owner's art: the gold-framed board in its
/// slight perspective and the ruby and onyx pieces. The 64 squares are laid
/// over the picture using the picture's own corners, so every piece sits on
/// its square and every square can be tapped. A king is two pieces stacked,
/// as on a real board. Each piece falls back to a plain disc if its image is
/// missing.
class CheckersBoard extends StatelessWidget {
  const CheckersBoard({
    super.key,
    required this.board,
    required this.selected,
    required this.targets,
    required this.onTap,
  });

  /// The 64 squares, row 0 at the top: 0 empty, 1/3 ruby man/king, 2/4 onyx.
  final List<int> board;
  final int? selected;
  final Set<int> targets;
  final ValueChanged<int> onTap;

  static const String _dir = 'assets/games/checkers/';

  // The playing area in the picture, in a 1254 x 1254 frame: top edge from x
  // 190 to 1062 at y 152, bottom edge from x 140 to 1125 at y 1018.
  static const double _size = 1254;
  static const double _top = 152, _bottom = 1018;
  static const double _tl = 190, _tr = 1062, _bl = 140, _br = 1125;

  static String pieceName(int p) => switch (p) {
        0 => 'empty',
        1 => 'ruby man',
        2 => 'onyx man',
        3 => 'ruby king',
        _ => 'onyx king',
      };

  Widget _piece(int p, double w) => SizedBox(
        width: w,
        height: w * 0.67,
        child: Image.asset(
          '$_dir${Draughts.side(p) == 1 ? 'piece_ruby' : 'piece_onyx'}.webp',
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Draughts.side(p) == 1
                  ? const Color(0xFFA81F2A)
                  : const Color(0xFF0B0E14),
              border: Border.all(color: const Color(0xFFD4A53A), width: 2),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(builder: (BuildContext _, BoxConstraints bc) {
        final double s = bc.maxWidth / _size;
        final double rowH = (_bottom - _top) / 8 * s;
        final List<Widget> kids = <Widget>[
          Positioned.fill(
            child: Image.asset(
              '${_dir}board.webp',
              fit: BoxFit.fill,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => _plainBoard(),
            ),
          ),
        ];
        // Squares and pieces, back row first so nearer pieces draw on top.
        for (int r = 0; r < 8; r++) {
          final double t = (r + 0.5) / 8;
          final double left = _tl + (_bl - _tl) * t;
          final double right = _tr + (_br - _tr) * t;
          final double cw = (right - left) / 8 * s;
          final double cy = (_top + (_bottom - _top) * t) * s;
          for (int c = 0; c < 8; c++) {
            final int i = r * 8 + c;
            final double cx = (left + (right - left) * (c + 0.5) / 8) * s;
            final int p = board[i];
            final bool sel = selected == i;
            final bool tgt = targets.contains(i);
            kids.add(Positioned(
              left: cx - cw / 2,
              top: cy - rowH / 2,
              width: cw,
              height: rowH,
              child: Semantics(
                button: true,
                selected: sel,
                label: 'Row ${r + 1}, column ${c + 1}, ${pieceName(p)}'
                    '${tgt ? ', you can move here' : ''}',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: ExcludeSemantics(
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        if (sel || tgt)
                          Container(
                            margin: EdgeInsets.all(cw * 0.04),
                            decoration: BoxDecoration(
                              color: tgt
                                  ? const Color(0x667FD1A8)
                                  : const Color(0x33FFD367),
                              border: Border.all(
                                color: tgt
                                    ? const Color(0xFF7FD1A8)
                                    : const Color(0xFFFFD367),
                                width: 3,
                              ),
                            ),
                          ),
                        if (p != 0)
                          Transform.translate(
                            offset: Offset(0, -rowH * 0.06),
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: <Widget>[
                                _piece(p, cw * 0.84),
                                if (Draughts.isKing(p))
                                  Transform.translate(
                                    offset: Offset(0, -cw * 0.17),
                                    child: _piece(p, cw * 0.84),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ));
          }
        }
        return Stack(clipBehavior: Clip.none, children: kids);
      }),
    );
  }

  Widget _plainBoard() => GridView.count(
        crossAxisCount: 8,
        physics: const NeverScrollableScrollPhysics(),
        children: <Widget>[
          for (int i = 0; i < 64; i++)
            ColoredBox(
              color: (i ~/ 8 + i % 8).isOdd
                  ? const Color(0xFF1B2A44)
                  : const Color(0xFFEAD6B4),
            ),
        ],
      );
}
