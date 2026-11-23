import 'dart:math';

import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../ui/game_stats.dart';
import '../ui/games_theme.dart';
import 'games_screens.dart';
import 'puzzle_games.dart';

/// Matching: six Names of Allah in Arabic on one side and their meanings on
/// the other, shuffled. Tap a Name, then the meaning that goes with it.
class MatchingScreen extends ConsumerStatefulWidget {
  const MatchingScreen({super.key});

  @override
  ConsumerState<MatchingScreen> createState() => _MatchingState();
}

class _MatchingState extends ConsumerState<MatchingScreen> {
  List<Name99>? _names;
  List<Name99> _meanings = <Name99>[];
  final Set<int> _matched = <int>{};
  int? _picked;
  int _misses = 0;
  String? _note;

  void _deal(List<Name99> all) {
    final Random r = Random();
    final List<Name99> pool = all
        .where((Name99 n) => n.arabic != null && n.meaning.trim().isNotEmpty)
        .toList()
      ..shuffle(r);
    _names = pool.take(6).toList();
    _meanings = List<Name99>.of(_names!)..shuffle(r);
    _matched.clear();
    _picked = null;
    _misses = 0;
    _note = null;
  }

  void _tapMeaning(Name99 m) {
    final int? p = _picked;
    if (p == null) {
      setState(() => _note = 'Tap a Name first');
      return;
    }
    setState(() {
      if (_names![p].n == m.n) {
        _matched.add(m.n);
        _note = '${m.name}: correct';
      } else {
        _misses++;
        _note = 'Not that one. Try again';
      }
      _picked = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Name99>> data = ref.watch(namesProvider);
    return data.when(
      loading: () => const PuzzleFrame(
        title: 'Matching',
        children: <Widget>[Center(child: CircularProgressIndicator())],
      ),
      error: (Object e, StackTrace s) => const PuzzleFrame(
        title: 'Matching',
        children: <Widget>[Text('The cards could not be loaded.')],
      ),
      data: (List<Name99> all) {
        if (_names == null) _deal(all);
        final List<Name99> names = _names!;
        if (_matched.length == names.length) {
          return PuzzleFrame(
            title: 'Matching',
            children: <Widget>[
              const SizedBox(height: 12),
              puzzleDone(
                context,
                headline: 'All ${names.length} matched',
                detail: _misses == 0
                    ? 'Not one miss.'
                    : '$_misses ${_misses == 1 ? 'miss' : 'misses'} along the way.',
              ),
              const SizedBox(height: 10),
              OutlineAction(
                label: 'Play again',
                onPressed: () => setState(() => _deal(all)),
              ),
            ],
          );
        }
        final int total = names.length;
        return PuzzleFrame(
          title: 'Matching Game',
          tagline: 'Match each Name of Allah with its meaning.',
          children: <Widget>[
            const SizedBox(height: 8),
            GameStatBar(
              stats: <GameStat>[
                GameStat(Icons.check_circle_outline, 'Matched',
                    '${_matched.length} / $total'),
                GameStat(Icons.close, 'Misses', '$_misses'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    children: <Widget>[
                      for (final Name99 n in names)
                        _MatchCard(
                          semanticsLabel: 'Name ${n.name}',
                          done: _matched.contains(n.n),
                          selected:
                              _picked != null && names[_picked!].n == n.n,
                          onTap: _matched.contains(n.n)
                              ? null
                              : () => setState(
                                    () => _picked = names.indexOf(n),
                                  ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                n.arabic!,
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(
                                  fontSize: 26,
                                  height: 1.5,
                                  color: AppColors.goldLight,
                                ),
                              ),
                              Text(n.name, style: AppText.bodyMuted),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      for (final Name99 m in _meanings)
                        _MatchCard(
                          semanticsLabel: 'Meaning: ${m.meaning}',
                          done: _matched.contains(m.n),
                          selected: false,
                          onTap: _matched.contains(m.n)
                              ? null
                              : () => _tapMeaning(m),
                          child: Text(
                            m.meaning,
                            textAlign: TextAlign.center,
                            style: AppText.body.copyWith(height: 1.3),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(child: Text(_note ?? ' ', style: AppText.bodyMuted)),
          ],
        );
      },
    );
  }
}

/// One card in a matching column: gold edge, green and ticked once matched.
class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.child,
    required this.semanticsLabel,
    required this.done,
    required this.selected,
    required this.onTap,
  });

  final Widget child;
  final String semanticsLabel;
  final bool done;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 84),
        child: GamePanel(
          semanticsLabel: done ? '$semanticsLabel, matched' : semanticsLabel,
          selected: selected || done,
          onTap: onTap,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (done)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.check_circle,
                        color: GamesTheme.good, size: 20),
                  ),
                Flexible(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
