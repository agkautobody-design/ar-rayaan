import 'dart:math';

import 'package:flutter/material.dart' hide Text;
import 'package:flutter/semantics.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../ui/games_theme.dart';
import 'puzzle_games.dart';

const List<String> _pictures = <String>[
  'assets/games/jigsaw/1.webp',
  'assets/games/jigsaw/2.webp',
  'assets/games/jigsaw/3.webp',
  'assets/games/jigsaw/4.webp',
  'assets/games/jigsaw/5.webp',
];

/// Jigsaw: the picture is cut into squares and shuffled. Tap one piece, then
/// another, to swap them. Put every piece back to finish.
class JigsawScreen extends StatefulWidget {
  const JigsawScreen({super.key});

  @override
  State<JigsawScreen> createState() => _JigsawState();
}

class _JigsawState extends State<JigsawScreen> {
  final Random _rnd = Random();
  int _n = 3;
  late String _pic;
  late List<int> _order; // _order[slot] = which piece sits in that slot
  int? _sel;
  int _moves = 0;

  @override
  void initState() {
    super.initState();
    _deal();
  }

  void _deal() {
    _pic = _pictures[_rnd.nextInt(_pictures.length)];
    final int total = _n * _n;
    do {
      _order = List<int>.generate(total, (int i) => i)..shuffle(_rnd);
    } while (_solved);
    _sel = null;
    _moves = 0;
  }

  bool get _solved {
    for (int i = 0; i < _order.length; i++) {
      if (_order[i] != i) return false;
    }
    return true;
  }

  void _tap(int slot) {
    if (_solved) return;
    setState(() {
      final int? s = _sel;
      if (s == null) {
        _sel = slot;
      } else if (s == slot) {
        _sel = null;
      } else {
        final int t = _order[s];
        _order[s] = _order[slot];
        _order[slot] = t;
        _sel = null;
        _moves++;
        if (_solved) {
          SemanticsService.announce('Finished in $_moves moves', TextDirection.ltr);
        }
      }
    });
  }

  Widget _piece(int piece) {
    final int r = piece ~/ _n;
    final int c = piece % _n;
    final double ax = _n == 1 ? 0 : -1 + 2 * c / (_n - 1);
    final double ay = _n == 1 ? 0 : -1 + 2 * r / (_n - 1);
    return ClipRect(
      child: Align(
        alignment: Alignment(ax, ay),
        widthFactor: 1 / _n,
        heightFactor: 1 / _n,
        child: Image.asset(_pic, fit: BoxFit.cover),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool done = _solved;
    return PuzzleFrame(
      title: 'Jigsaw',
      tagline: 'Tap two pieces to swap them',
      children: <Widget>[
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text('Moves: $_moves', style: AppText.label),
            Row(children: <Widget>[
              GameChip(
                label: '3 × 3',
                selected: _n == 3,
                onTap: () => setState(() {
                  _n = 3;
                  _deal();
                }),
              ),
              const SizedBox(width: 8),
              GameChip(
                label: '4 × 4',
                selected: _n == 4,
                onTap: () => setState(() {
                  _n = 4;
                  _deal();
                }),
              ),
            ]),
          ],
        ),
        const SizedBox(height: 10),
        AspectRatio(
          aspectRatio: 1,
          child: GridView.count(
            crossAxisCount: _n,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            physics: const NeverScrollableScrollPhysics(),
            children: <Widget>[
              for (int slot = 0; slot < _order.length; slot++)
                Semantics(
                  button: true,
                  selected: _sel == slot,
                  label: 'Piece in row ${slot ~/ _n + 1}, column ${slot % _n + 1}'
                      '${_order[slot] == slot ? ', in place' : ''}',
                  child: GestureDetector(
                    onTap: () => _tap(slot),
                    child: ExcludeSemantics(
                      child: DecoratedBox(
                        position: DecorationPosition.foreground,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _sel == slot
                                ? AppColors.goldLight
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: _piece(_order[slot]),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (done)
          puzzleDone(
            context,
            headline: 'Picture complete',
            detail: 'Finished in $_moves moves.',
          ),
        if (done) ...<Widget>[
          const SizedBox(height: 10),
          OutlineAction(
            label: 'Play again',
            onPressed: () => setState(_deal),
          ),
        ],
      ],
    );
  }
}
