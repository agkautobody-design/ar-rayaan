import 'dart:math';

import 'package:flutter/material.dart' hide Text;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../engine/jigsaw_cuts.dart';
import '../ui/games_theme.dart';
import 'puzzle_games.dart';

/// How close (as a fraction of the picture) a dropped piece must be to its
/// place for it to click in.
const double kJigsawSnap = 0.08;

/// Height of the loose-piece tray, as a fraction of the picture's height.
const double _trayHeight = 0.95;

/// Jigsaw: real jigsaw pieces, cut along the lines of the picture. The pieces
/// start scattered in the tray under the board. Drag each one to its place;
/// a piece that is close enough clicks in and stays.
class JigsawScreen extends StatefulWidget {
  const JigsawScreen({this.seed, super.key});

  /// Fixes the dealing so tests can repeat it.
  final int? seed;

  @override
  State<JigsawScreen> createState() => _JigsawState();
}

class _JigsawState extends State<JigsawScreen> {
  late final Random _rnd = Random(widget.seed);
  int _count = 16;
  late JigsawCut _cut;
  late List<Offset> _pos; // top-left of each piece, as fractions of the board
  late List<bool> _placed;
  late List<int> _loose; // loose pieces, last one is drawn on top
  int? _drag;
  int? _dragPointer;
  int _drops = 0;
  bool _peek = false;
  late Stopwatch _clock;
  Duration? _finishedIn;

  double _pathsFor = 0;
  final Map<int, Path> _paths = <int, Path>{};

  @override
  void initState() {
    super.initState();
    _deal();
  }

  Iterable<JigsawCut> get _choices =>
      kJigsawCuts.where((JigsawCut c) => c.pieces.length == _count);

  void _deal({JigsawCut? not}) {
    final List<JigsawCut> options = _choices.toList();
    final List<JigsawCut> fresh =
        options.where((JigsawCut c) => c != not).toList();
    final List<JigsawCut> from = fresh.isEmpty ? options : fresh;
    _cut = from[_rnd.nextInt(from.length)];
    final int n = _cut.pieces.length;
    final List<int> cells = List<int>.generate(n, (int i) => i)..shuffle(_rnd);
    final int rowsT = (n / 4).ceil();
    _pos = List<Offset>.filled(n, Offset.zero);
    for (int i = 0; i < n; i++) {
      final JigsawPiece p = _cut.pieces[i];
      final int k = cells[i];
      final double jx = (_rnd.nextDouble() - 0.5) * 0.05;
      final double jy = (_rnd.nextDouble() - 0.5) * 0.05;
      final double cx = ((k % 4) + 0.5) / 4 + jx;
      final double cy = 1 + _trayHeight * (((k ~/ 4) + 0.5) / rowsT) + jy;
      _pos[i] = Offset(
        (cx - p.width / 2).clamp(0.0, 1 - p.width),
        (cy - p.height / 2).clamp(1.01, 1 + _trayHeight - p.height),
      );
    }
    _placed = List<bool>.filled(n, false);
    _loose = List<int>.generate(n, (int i) => i)..shuffle(_rnd);
    _drag = null;
    _dragPointer = null;
    _drops = 0;
    _peek = false;
    _finishedIn = null;
    _clock = Stopwatch()..start();
    _paths.clear();
  }

  bool get _solved => _placed.every((bool b) => b);
  int get _placedCount => _placed.where((bool b) => b).length;

  Path _path(int i, double b) {
    if (_pathsFor != b) {
      _paths.clear();
      _pathsFor = b;
    }
    return _paths.putIfAbsent(i, () => _cut.pieces[i].path(b));
  }

  void _down(int i, PointerDownEvent e) {
    if (_dragPointer != null || _placed[i]) return;
    setState(() {
      _drag = i;
      _dragPointer = e.pointer;
      _loose
        ..remove(i)
        ..add(i);
    });
  }

  void _move(int i, PointerMoveEvent e, double b) {
    if (_drag != i || e.pointer != _dragPointer) return;
    final JigsawPiece p = _cut.pieces[i];
    setState(() {
      final Offset o = _pos[i] + e.delta / b;
      _pos[i] = Offset(
        o.dx.clamp(0.0, 1 - p.width),
        o.dy.clamp(0.0, 1 + _trayHeight - p.height),
      );
    });
  }

  void _up(int i, PointerEvent e) {
    if (_drag != i || e.pointer != _dragPointer) return;
    setState(() {
      _drag = null;
      _dragPointer = null;
      _drops++;
      _tryClick(i);
    });
  }

  /// Clicks piece [i] into its place if it was dropped close enough.
  bool _tryClick(int i) {
    final JigsawPiece p = _cut.pieces[i];
    final Offset home = Offset(p.x0, p.y0);
    if ((_pos[i] - home).distance > kJigsawSnap) return false;
    _place(i);
    return true;
  }

  void _place(int i) {
    final JigsawPiece p = _cut.pieces[i];
    _pos[i] = Offset(p.x0, p.y0);
    _placed[i] = true;
    _loose.remove(i);
    HapticFeedback.selectionClick();
    if (_solved) {
      _clock.stop();
      _finishedIn = _clock.elapsed;
      SemanticsService.announce('Picture complete', TextDirection.ltr);
    }
  }

  void _setCount(int n) {
    if (n == _count) return;
    setState(() {
      _count = n;
      _deal();
    });
  }

  String _time(Duration d) {
    final int s = d.inSeconds;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bool done = _solved;
    final int n = _cut.pieces.length;
    return PuzzleFrame(
      title: 'Jigsaw',
      tagline: 'Drag each piece to its place',
      children: <Widget>[
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text('Placed: $_placedCount of $n', style: AppText.label),
            Row(children: <Widget>[
              GameChip(
                label: '12 pieces',
                selected: _count == 12,
                onTap: () => _setCount(12),
              ),
              const SizedBox(width: 8),
              GameChip(
                label: '16 pieces',
                selected: _count == 16,
                onTap: () => _setCount(16),
              ),
            ]),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(builder: (BuildContext context, BoxConstraints cons) {
          final double b = min(cons.maxWidth, 560);
          final double h = done ? b : b * (1 + _trayHeight);
          return Center(
            child: SizedBox(
              key: const ValueKey<String>('jigsaw-board'),
              width: b,
              height: h,
              child: Stack(
                key: const ValueKey<String>('jigsaw-stack'),
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    key: const ValueKey<String>('jigsaw-bg'),
                    left: 0,
                    top: 0,
                    width: b,
                    height: b,
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _BoardPainter(_cut, _placed, b),
                      ),
                    ),
                  ),
                  if (_peek && !done)
                    Positioned(
                      key: const ValueKey<String>('jigsaw-peek'),
                      left: 0,
                      top: 0,
                      width: b,
                      height: b,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: 0.4,
                          child: Image.asset(_cut.asset, fit: BoxFit.fill),
                        ),
                      ),
                    ),
                  if (!done)
                    Positioned(
                      key: const ValueKey<String>('jigsaw-tray'),
                      left: 0,
                      top: b + 6,
                      width: b,
                      height: b * _trayHeight - 6,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.night.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.25),
                            ),
                          ),
                        ),
                      ),
                    ),
                  for (int i = 0; i < n; i++)
                    if (_placed[i]) _pieceView(i, b),
                  for (final int i in _loose) _pieceView(i, b),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        if (!done)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              GameChip(
                label: 'Peek at the picture',
                selected: _peek,
                onTap: () => setState(() => _peek = !_peek),
              ),
            ],
          ),
        if (done)
          puzzleDone(
            context,
            headline: 'Picture complete',
            detail: '${_cut.title}\n'
                'Finished in ${_time(_finishedIn ?? Duration.zero)}, '
                '$_drops drops.',
          ),
        if (done) ...<Widget>[
          const SizedBox(height: 10),
          OutlineAction(
            label: 'Play again',
            onPressed: () => setState(() => _deal(not: _cut)),
          ),
        ],
      ],
    );
  }

  Widget _pieceView(int i, double b) {
    final JigsawPiece p = _cut.pieces[i];
    final Path path = _path(i, b);
    final double w = p.width * b;
    final double h = p.height * b;
    final bool placed = _placed[i];
    final bool lifted = _drag == i;
    final Widget face = SizedBox(
      key: ValueKey<String>('jigsaw-piece-$i'),
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          if (!placed)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _ShadowPainter(path, lifted)),
              ),
            ),
          // The clip comes first so that only the piece's own shape takes
          // touches: a finger on another piece's corner goes to that piece.
          ClipPath(
            clipper: _PathClipper(path, i, b),
            child: placed
                ? _picture(p, b)
                : Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (PointerDownEvent e) => _down(i, e),
                    onPointerMove: (PointerMoveEvent e) => _move(i, e, b),
                    onPointerUp: (PointerUpEvent e) => _up(i, e),
                    onPointerCancel: (PointerCancelEvent e) => _up(i, e),
                    // Claims the touch so the page does not scroll while a
                    // piece is being dragged.
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragUpdate: (_) {},
                      onVerticalDragUpdate: (_) {},
                      child: _picture(p, b),
                    ),
                  ),
          ),
          if (!placed)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _EdgePainter(path)),
              ),
            ),
        ],
      ),
    );
    final int row = i ~/ _cut.cols + 1;
    final int col = i % _cut.cols + 1;
    return Positioned(
      key: ValueKey<int>(i),
      left: _pos[i].dx * b,
      top: _pos[i].dy * b,
      width: w,
      height: h,
      child: Semantics(
        button: !placed,
        label: 'Piece in row $row, column $col'
            '${placed ? ', placed' : ', loose'}',
        hint: placed ? null : 'Drag it to its place. Double tap to place it.',
        onTap: placed
            ? null
            : () => setState(() {
                  _drops++;
                  _place(i);
                }),
        child: ExcludeSemantics(child: face),
      ),
    );
  }

  Widget _picture(JigsawPiece p, double b) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          left: -p.x0 * b,
          top: -p.y0 * b,
          width: b,
          height: b,
          child: Image.asset(
            _cut.asset,
            fit: BoxFit.fill,
            gaplessPlayback: true,
          ),
        ),
      ],
    );
  }
}

class _PathClipper extends CustomClipper<Path> {
  const _PathClipper(this.path, this.index, this.size);

  final Path path;
  final int index;
  final double size;

  @override
  Path getClip(Size _) => path;

  @override
  bool shouldReclip(_PathClipper old) =>
      old.index != index || old.size != size || old.path != path;
}

/// The board: a dark backdrop with the outline of every empty place.
class _BoardPainter extends CustomPainter {
  _BoardPainter(this.cut, this.placed, this.size);

  final JigsawCut cut;
  final List<bool> placed;
  final double size;

  @override
  void paint(Canvas canvas, Size _) {
    final RRect frame = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size, size),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      frame,
      Paint()..color = AppColors.night.withValues(alpha: 0.6),
    );
    final Paint fill = Paint()..color = AppColors.sand.withValues(alpha: 0.07);
    final Paint line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.gold.withValues(alpha: 0.4);
    for (int i = 0; i < cut.pieces.length; i++) {
      if (placed[i]) continue;
      final JigsawPiece p = cut.pieces[i];
      final Path path = p.path(size).shift(Offset(p.x0 * size, p.y0 * size));
      canvas.drawPath(path, fill);
      canvas.drawPath(path, line);
    }
    canvas.drawRRect(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppColors.gold.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(_BoardPainter old) =>
      old.cut != cut || old.size != size || !_same(old.placed, placed);

  static bool _same(List<bool> a, List<bool> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _ShadowPainter extends CustomPainter {
  const _ShadowPainter(this.path, this.lifted);

  final Path path;
  final bool lifted;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawShadow(path, Colors.black, lifted ? 12 : 4, true);
  }

  @override
  bool shouldRepaint(_ShadowPainter old) =>
      old.lifted != lifted || old.path != path;
}

class _EdgePainter extends CustomPainter {
  const _EdgePainter(this.path);

  final Path path;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.black.withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(_EdgePainter old) => old.path != path;
}
