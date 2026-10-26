import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../data/ludo_board_art.dart';
import '../data/ludo_rules.dart';

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
  'square',
  'triangle',
  'diamond',
];

/// Draws the shape of [colour] (0 red circle, 1 blue square, 2 yellow
/// triangle, 3 green diamond) filling its box.
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
      canvas.drawRect(Rect.fromLTWH(w * 0.12, h * 0.12, w * 0.76, h * 0.76), p);
    } else if (colour == 2) {
      final Path path = Path()
        ..moveTo(w / 2, h * 0.04)
        ..lineTo(w * 0.96, h * 0.94)
        ..lineTo(w * 0.04, h * 0.94)
        ..close();
      canvas.drawPath(path, p);
    } else {
      final Path path = Path()
        ..moveTo(w / 2, 0)
        ..lineTo(w, h / 2)
        ..lineTo(w / 2, h)
        ..lineTo(0, h / 2)
        ..close();
      canvas.drawPath(path, p);
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

/// Gold star on the four start squares (the art has stars on the arm ends).
class _StartMarksPainter extends CustomPainter {
  const _StartMarksPainter(this.k);

  final double k;

  @override
  void paint(Canvas canvas, Size size) {
    for (int c = 0; c < 4; c++) {
      final LudoPt pt = LudoBoardArt.loop[LudoRules.startCell[c]];
      final double s = LudoBoardArt.pawnScaleAt(pt.y);
      final Offset centre = Offset(pt.x * k, pt.y * k);
      final double r = 11 * s * k;
      final Paint ring = Paint()
        ..color = kLudoColours[c]
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.6, 2.4 * k);
      canvas.drawCircle(centre, r * 1.45, ring);
      final Path star = Path();
      for (int i = 0; i < 10; i++) {
        final double a = -math.pi / 2 + i * math.pi / 5;
        final double rr = i.isEven ? r : r * 0.45;
        final Offset o = Offset(
          centre.dx + math.cos(a) * rr,
          centre.dy + math.sin(a) * rr,
        );
        if (i == 0) {
          star.moveTo(o.dx, o.dy);
        } else {
          star.lineTo(o.dx, o.dy);
        }
      }
      star.close();
      canvas.drawPath(star, Paint()..color = const Color(0xFFB8860B));
    }
  }

  @override
  bool shouldRepaint(_StartMarksPainter old) => old.k != k;
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
/// [movable] (tokens of [movableSeat]) glow and can be tapped.
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
          scale = LudoBoardArt.pawnScaleAt(pt.y);
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
      aspectRatio: LudoBoardArt.imageWidth / LudoBoardArt.imageHeight,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          final double k = c.maxWidth / LudoBoardArt.imageWidth;
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
          final List<_PawnSpec> order = <_PawnSpec>[
            ...specs.where((_PawnSpec s) => !s.movable),
            ...specs.where((_PawnSpec s) => s.movable),
          ];
          for (final _PawnSpec s in order) {
            double dx = 0;
            double scale = s.scale;
            final List<_PawnSpec>? group = shared['${s.point.x},${s.point.y}'];
            if (group != null && group.length > 1) {
              final int i = group.indexOf(s);
              dx = (i - (group.length - 1) / 2) * 13;
              scale *= 0.88;
            }
            final double cx = s.point.x + dx;
            final double cy = s.point.y;
            final double w = LudoBoardArt.spriteWidth * scale * k;
            final double h = LudoBoardArt.spriteHeight * scale * k;
            final double left =
                (cx - LudoBoardArt.spriteAnchor.x * scale) * k;
            final double top =
                (cy - LudoBoardArt.spriteAnchor.y * scale) * k;
            if (s.movable) {
              final double r = LudoBoardArt.cellRadiusAt(cy) * 1.2 * k;
              rings.add(
                Positioned(
                  left: cx * k - r,
                  top: cy * k - r * 0.8,
                  width: r * 2,
                  height: r * 1.6,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.elliptical(r, r * 0.8)),
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
            final double mark = math.max(w * 0.24, 7);
            final double font = math.max(w * 0.30, 8);
            final String name = LudoRules.colourNames[s.colour];
            pawns.add(
              Positioned(
                left: left,
                top: top + lift,
                width: w,
                height: h,
                child: Semantics(
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
                        Positioned(
                          left: (w - mark) / 2,
                          top: h * 0.20,
                          width: mark,
                          height: mark,
                          child: LudoShapeMark(
                            colour: s.colour,
                            size: mark,
                            color: const Color(0xCCFFFFFF),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: h * 0.46,
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
                                  Shadow(color: Colors.black87, blurRadius: 2),
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
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                    excludeFromSemantics: true,
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
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _StartMarksPainter(k)),
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
