import 'package:flutter/material.dart' hide Text;

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/tr_text.dart';
import 'games_theme.dart';

/// One cell of a [GameStatBar]: a small gold icon, a label and a value.
class GameStat {
  const GameStat(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;
}

/// The row of figures across the top of a game, as in the designs: a gold
/// icon in a ring, a muted label and the figure, with thin dividers.
class GameStatBar extends StatelessWidget {
  const GameStatBar({required this.stats, super.key});

  final List<GameStat> stats;

  @override
  Widget build(BuildContext context) {
    final List<Widget> cells = <Widget>[];
    for (int i = 0; i < stats.length; i++) {
      if (i > 0) {
        cells.add(Container(
          width: 1,
          height: 34,
          color: GamesTheme.border.withValues(alpha: 0.5),
        ));
      }
      cells.add(Expanded(child: _Cell(stat: stats[i])));
    }
    return Semantics(
      liveRegion: true,
      label: <String>[
        for (final GameStat s in stats) '${s.label} ${s.value}',
      ].join(', '),
      child: ExcludeSemantics(
        child: GamePanel(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Row(children: cells),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.stat});

  final GameStat stat;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.7)),
          ),
          child: Icon(stat.icon, size: 18, color: AppColors.gold),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                stat.label,
                style: AppText.bodyMuted.copyWith(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                stat.value,
                style: AppText.titleMedium.copyWith(
                  color: GamesTheme.champagne,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A gold-edged strip with a star and a short instruction, like "Find the
/// matching pairs" in the designs.
class GameHintBar extends StatelessWidget {
  const GameHintBar({required this.title, required this.body, super.key});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: <Widget>[
          const Icon(Icons.auto_awesome, color: AppColors.gold, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppText.titleMedium.copyWith(
                    color: GamesTheme.champagne,
                  ),
                ),
                Text(body, style: AppText.bodyMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Round dots joined by a line: filled gold up to [done].
class GameDots extends StatelessWidget {
  const GameDots({required this.done, required this.total, super.key});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < total; i++) ...<Widget>[
            if (i > 0)
              Container(
                width: 14,
                height: 2,
                color: AppColors.gold.withValues(alpha: i <= done ? 0.9 : 0.3),
              ),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < done ? AppColors.gold : Colors.transparent,
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.8),
                  width: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
