import 'package:flutter/material.dart' hide Text;

import '../engine/board_engines.dart';

/// The Four in a Row board, from the owner's art: the gold-and-black frame
/// with its arch and star, the emerald and ruby tokens, and the carved base.
/// The frame pieces are images; the grid of holes is drawn in code so the
/// playing area is exactly six rows by seven columns, and every piece falls
/// back to a plain drawing if an image is missing.
class Connect4Board extends StatelessWidget {
  const Connect4Board({
    super.key,
    required this.game,
    required this.onDrop,
  });

  final ConnectFour game;
  final ValueChanged<int> onDrop;

  static const String _dir = 'assets/games/connect4/';
  static const Color emerald = Color(0xFF1E8A4C);
  static const Color ruby = Color(0xFFB3202A);

  // Proportions of the art, as a share of the board's width.
  static const double _side = 0.05;
  static const double _crownRatio = 232 / 1000;
  static const double _baseWidth = 1.149;
  static const double _baseRatio = 123 / 1000;

  static const List<String> _name = <String>['', 'emerald', 'ruby'];

  Widget _img(String file, {BoxFit fit = BoxFit.fill, Widget? fallback}) =>
      Image.asset(
        '$_dir$file.webp',
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => fallback ?? const SizedBox.shrink(),
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (BuildContext _, BoxConstraints bc) {
      final double w = bc.maxWidth;
      final double gridW = w * (1 - 2 * _side);
      final double cell = gridW / ConnectFour.cols;
      final double gridH = cell * ConnectFour.rows;
      final double crownH = w * _crownRatio;
      final double baseH = w * _baseWidth * _baseRatio;
      return SizedBox(
        width: w,
        height: crownH + gridH + baseH * 0.82,
        child: Stack(clipBehavior: Clip.none, children: <Widget>[
          // The dark panel behind the holes and the two side rails.
          Positioned(
            left: 0,
            top: crownH - 2,
            width: w,
            height: gridH + 4,
            child: Row(children: <Widget>[
              SizedBox(
                  width: w * _side,
                  child: _img('side_left',
                      fallback: const ColoredBox(color: Color(0xFFB8892B)))),
              Expanded(
                child: const DecoratedBox(
                  decoration: BoxDecoration(color: Color(0xFF0E1218)),
                ),
              ),
              SizedBox(
                  width: w * _side,
                  child: _img('side_right',
                      fallback: const ColoredBox(color: Color(0xFFB8892B)))),
            ]),
          ),
          Positioned(
            left: 0,
            top: 0,
            width: w,
            height: crownH,
            child: _img('crown',
                fallback: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFF0E1218),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                )),
          ),
          // Tokens fall behind the frame's gold rings, which sit above them.
          Positioned(
            left: w * _side,
            top: crownH,
            width: gridW,
            height: gridH,
            child: Stack(children: <Widget>[
              for (int c = 0; c < ConnectFour.cols; c++)
                for (int r = 0; r < ConnectFour.rows; r++)
                  Positioned(
                    left: c * cell,
                    top: r * cell,
                    width: cell,
                    height: cell,
                    child: _Hole(
                      cell: cell,
                      value: game.at(r, c),
                      row: r,
                      lit: game.line.contains(r * ConnectFour.cols + c),
                      token: game.at(r, c) == 0
                          ? null
                          : _img(game.at(r, c) == 1 ? 'token_emerald' : 'token_ruby',
                              fit: BoxFit.contain,
                              fallback: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: game.at(r, c) == 1 ? emerald : ruby,
                                ),
                              )),
                    ),
                  ),
              // One tap target per column, with a plain spoken label.
              for (int c = 0; c < ConnectFour.cols; c++)
                Positioned(
                  left: c * cell,
                  top: 0,
                  width: cell,
                  height: gridH,
                  child: Semantics(
                    button: true,
                    label: 'Drop in column ${c + 1}'
                        '${game.canDrop(c) ? '' : ', full'}',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onDrop(c),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
            ]),
          ),
          // The base, a little wider than the board, as in the art.
          Positioned(
            left: -(w * (_baseWidth - 1) / 2),
            top: crownH + gridH - baseH * 0.18,
            width: w * _baseWidth,
            height: baseH,
            child: _img('base',
                fallback: const DecoratedBox(
                  decoration: BoxDecoration(color: Color(0xFFB8892B)),
                )),
          ),
        ]),
      );
    });
  }

  /// Spoken description of a token, for tests and screen readers.
  static String tokenName(int v) => _name[v];
}

/// One hole: a dark well with a gold ring, and the token that lies in it.
class _Hole extends StatelessWidget {
  const _Hole({
    required this.cell,
    required this.value,
    required this.row,
    required this.lit,
    required this.token,
  });

  final double cell;
  final int value;
  final int row;
  final bool lit;
  final Widget? token;

  @override
  Widget build(BuildContext context) {
    final double d = cell * 0.82;
    return Center(
      child: SizedBox(
        width: d,
        height: d,
        child: Stack(alignment: Alignment.center, children: <Widget>[
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF05070B),
              border: Border.all(color: const Color(0xFFD4A53A), width: cell * 0.04),
            ),
          ),
          if (token != null)
            TweenAnimationBuilder<double>(
              key: ValueKey<String>('t$row-$value'),
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 320),
              curve: Curves.bounceOut,
              builder: (BuildContext _, double t, Widget? child) =>
                  Transform.translate(
                offset: Offset(0, -(1 - t) * cell * (row + 1.5)),
                child: child,
              ),
              child: Padding(
                padding: EdgeInsets.all(cell * 0.03),
                child: Semantics(
                  label: '${Connect4Board.tokenName(value)} token',
                  child: token,
                ),
              ),
            ),
          if (lit)
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: cell * 0.06),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFFFFE08A).withValues(alpha: 0.8),
                    blurRadius: cell * 0.3,
                  ),
                ],
              ),
            ),
        ]),
      ),
    );
  }
}
