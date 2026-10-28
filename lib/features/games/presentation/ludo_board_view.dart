import 'dart:math' as math;

import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';

import '../../../app/theme/app_colors.dart';
import '../data/ludo_board_art.dart';
import '../data/ludo_rules.dart';
import '../../../app/theme/widgets/focus_safe_semantics.dart';

/// Pawn colours, in colour order: red, blue, yellow, green. Used for dots and
/// markers; the board picture and pawn sprites carry the real artwork.
const List<Color> kLudoColours = <Color>[
  Color(0xFFD32F2F),
  Color(0xFF1E64C8),
  Color(0xFFF2B01E),
  Color(0xFF2E8B3E),
];

/// Colour-blind aid: every colour also has its own shape (circle, square,
/// triangle, diamond) and every pawn a number, so no colour has to be told
/// apart by hue alone.
const List<String> kLudoShapeNames = <String>[
  'circle',
  'diamond',
  'triangle',
  'square',
];

/// Draws the shape of [colour] (0 red circle, 1 blue diamond, 2 yellow
/// triangle, 3 green square) filling its box. These are the shapes on the
/// top disc of the pawn pictures.
class LudoShapePainter extends CustomPainter {
  const LudoShapePainter({required this.colour, required this.color});

  final int colour;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final double w = size.width;
    final double h = size.height;
    if (colour == 0) {
      canvas.drawCircle(Offset(w / 2, h / 2), math.min(w, h) / 2, p);
    } else if (colour == 1) {
      final Path path = Path()
        ..moveTo(w / 2, 0)
        ..lineTo(w, h / 2)
        ..lineTo(w / 2, h)
        ..lineTo(0, h / 2)
        ..close();
      canvas.drawPath(path, p);
    } else if (colour == 2) {
      final Path path = Path()
        ..moveTo(w / 2, h * 0.04)
        ..lineTo(w * 0.96, h * 0.94)
        ..lineTo(w * 0.04, h * 0.94)
        ..close();
      canvas.drawPath(path, p);
    } else {
      canvas.drawRect(Rect.fromLTWH(w * 0.12, h * 0.12, w * 0.76, h * 0.76), p);
    }
  }

  @override
  bool shouldRepaint(LudoShapePainter old) =>
      old.colour != colour || old.color != color;
}

/// A small shape marker widget.
class LudoShapeMark extends StatelessWidget {
  const LudoShapeMark({
    required this.colour,
    this.size = 12,
    this.color = Colors.white,
    super.key,
  });

  final int colour;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: LudoShapePainter(colour: colour, color: color),
        ),
      ),
    );
  }
}

class _PawnSpec {
  _PawnSpec({
    required this.seat,
    required this.token,
    required this.colour,
    required this.point,
    required this.scale,
    required this.where,
    required this.movable,
  });

  final int seat;
  final int token;
  final int colour;
  final LudoPt point;
  final double scale;
  final String where;
  final bool movable;
}

/// The owner's board picture with the pawns laid on it.
///
/// [tokens] is indexed by seat; [seats] gives each seat's colour. Pawns in
/// [movable] (tokens of [movableSeat]) glow and can be tapped. The board is
/// square; every position comes from [LudoBoardArt] (cell units of the
/// measured 15 x 15 grid).
class LudoBoardView extends StatelessWidget {
  const LudoBoardView({
    required this.seats,
    required this.tokens,
    this.movableSeat,
    this.movable = const <int>{},
    this.onTapToken,
    super.key,
  });

  final List<int> seats;
  final List<List<int>> tokens;
  final int? movableSeat;
  final Set<int> movable;
  final void Function(int token)? onTapToken;

  static String _where(int colour, int p) {
    if (p < 0) return 'in the yard';
    if (p >= LudoRules.finished) return 'home';
    if (p >= LudoRules.trackLen[colour]) return 'in the home column';
    return 'on the track';
  }

  List<_PawnSpec> _specs() {
    final List<_PawnSpec> out = <_PawnSpec>[];
    for (int seat = 0; seat < seats.length; seat++) {
      final int colour = seats[seat];
      int homeRank = 0;
      for (int t = 0; t < tokens[seat].length; t++) {
        final int p = tokens[seat][t];
        final LudoPt pt = LudoBoardArt.position(
          colour,
          p,
          t,
          homeRank: homeRank,
        );
        double scale;
        if (p < 0) {
          scale = LudoBoardArt.yardScale;
        } else if (p >= LudoRules.finished) {
          scale = LudoBoardArt.homeScale;
          homeRank++;
        } else {
          scale = 1.0;
        }
        out.add(
          _PawnSpec(
            seat: seat,
            token: t,
            colour: colour,
            point: pt,
            scale: scale,
            where: _where(colour, p),
            movable: seat == movableSeat && movable.contains(t),
          ),
        );
      }
    }
    return out;
  }

  String _summary() {
    final StringBuffer sb = StringBuffer('Ludo board. ');
    for (int seat = 0; seat < seats.length; seat++) {
      final int colour = seats[seat];
      int yard = 0, track = 0, home = 0;
      for (final int p in tokens[seat]) {
        if (p < 0) {
          yard++;
        } else if (p >= LudoRules.finished) {
          home++;
        } else {
          track++;
        }
      }
      sb.write(
        '${LudoRules.colourNames[colour]}: $yard in the yard, $track '
        'moving, $home home. ',
      );
    }
    return sb.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          final double k = c.maxWidth / LudoBoardArt.imageSize;
          final double cell = LudoBoardArt.cell * k;
          final List<_PawnSpec> specs = _specs();
          // Fan out pawns that share a square.
          final Map<String, List<_PawnSpec>> shared =
              <String, List<_PawnSpec>>{};
          for (final _PawnSpec s in specs) {
            if (s.where == 'on the track' || s.where == 'in the home column') {
              shared
                  .putIfAbsent('${s.point.x},${s.point.y}', () => <_PawnSpec>[])
                  .add(s);
            }
          }
          final List<Widget> rings = <Widget>[];
          final List<Widget> pawns = <Widget>[];
          // Pawns lower on the board are drawn last, so they overlap the ones
          // behind them; movable pawns are on top of all.
          final List<_PawnSpec> order = <_PawnSpec>[
            ...(specs.where((_PawnSpec s) => !s.movable).toList()
              ..sort((_PawnSpec a, _PawnSpec b) =>
                  a.point.y.compareTo(b.point.y))),
            ...specs.where((_PawnSpec s) => s.movable),
          ];
          for (final _PawnSpec s in order) {
            double dx = 0;
            double scale = s.scale;
            final List<_PawnSpec>? group = shared['${s.point.x},${s.point.y}'];
            if (group != null && group.length > 1) {
              final int i = group.indexOf(s);
              dx = (i - (group.length - 1) / 2) * 0.34 * LudoBoardArt.cell;
              scale *= LudoBoardArt.sharedScale;
            }
            final double cx = (s.point.x + dx) * k;
            final double cy = s.point.y * k;
            final double side = LudoBoardArt.spriteCells * cell * scale;
            final double left = cx - LudoBoardArt.spriteBaseX * side;
            final double top = cy +
                LudoBoardArt.baseDrop * cell -
                LudoBoardArt.spriteBaseY * side;
            if (s.movable) {
              final double r = cell * 0.62;
              rings.add(
                Positioned(
                  left: cx - r,
                  top: cy - r,
                  width: r * 2,
                  height: r * 2,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.goldLight, width: 2),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(color: Color(0xCCFFD367), blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
            final double lift = s.movable ? -3 * k : 0;
            // 12 px is the app's minimum text size. A pawn that is already home
            // is small and its number would sit above it, so it has none (the
            // player card and the board summary count the pawns home).
            final double font = math.max(side * 0.2, 12);
            final bool atHome = s.where == 'home';
            final String name = LudoRules.colourNames[s.colour];
            pawns.add(
              Positioned(
                left: left,
                top: top + lift,
                width: side,
                height: side,
                child: FocusSafeSemantics(
                  button: s.movable,
                  label: '$name pawn ${s.token + 1}, ${s.where}',
                  onTap: s.movable && onTapToken != null
                      ? () => onTapToken!(s.token)
                      : null,
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: s.movable && onTapToken != null
                        ? () => onTapToken!(s.token)
                        : null,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        Positioned.fill(
                          child: Image.asset(
                            LudoBoardArt.pawnFiles[s.colour],
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (
                              BuildContext ctx,
                              Object e,
                              StackTrace? st,
                            ) =>
                                DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: kLudoColours[s.colour],
                              ),
                            ),
                          ),
                        ),
                        // The number, drawn in code on the ball under the
                        // shape disc (the shape itself is in the picture).
                        if (!atHome)
                        Positioned(
                          left: 0,
                          right: 0,
                          top: side * LudoBoardArt.numberY[s.colour] -
                              font * 0.5,
                          child: Center(
                            child: Text(
                              '${s.token + 1}',
                              textScaler: TextScaler.noScaling,
                              style: TextStyle(
                                fontSize: font,
                                height: 1,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                shadows: const <Shadow>[
                                  Shadow(color: Colors.black, blurRadius: 2),
                                  Shadow(color: Colors.black87, blurRadius: 4),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          return Semantics(
            container: true,
            label: _summary(),
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned.fill(
                  child: Image.asset(
                    LudoBoardArt.board,
                    key: const ValueKey<String>('ludo-board-art'),
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                    excludeFromSemantics: true,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (
                      BuildContext ctx,
                      Object e,
                      StackTrace? st,
                    ) =>
                        const DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFF2A1D10),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                ),
                ...rings,
                ...pawns,
              ],
            ),
          );
        },
      ),
    );
  }
}
