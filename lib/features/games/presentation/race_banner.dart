import 'package:flutter/material.dart' hide Text;

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../data/race_link.dart';
import '../data/race_protocol.dart';

/// "Friend: 3 of 10, 2 right" while racing, and the comparison at the end.
/// Shows counts only, never a name.
class RaceBanner extends StatelessWidget {
  const RaceBanner({
    required this.link,
    required this.myScore,
    required this.myTotal,
    this.iFinished = false,
    super.key,
  });

  final RaceLink link;
  final int myScore;
  final int myTotal;
  final bool iFinished;

  /// The one line shown for the state of the race.
  static String line(
    RaceState s, {
    required int myScore,
    required bool iFinished,
    int myFinishedMs = 0,
  }) {
    if (s.left) return 'Your friend left the table.';
    final RaceOpponent o = s.opponent;
    if (o.finished) {
      if (!iFinished) {
        return 'Your friend finished with ${o.score} of ${o.total} right.';
      }
      String verdict = myScore > o.score
          ? 'You won'
          : myScore < o.score
              ? 'Your friend won'
              : 'A draw';
      // Equal scores: whoever finished first wins, unless it was a photo
      // finish (under two seconds apart, or a clock is missing).
      if (myScore == o.score && myFinishedMs > 0 && o.finishedMs > 0) {
        final int gap = o.finishedMs - myFinishedMs;
        if (gap > 2000) verdict = 'You won, finishing first';
        if (gap < -2000) verdict = 'Your friend won, finishing first';
      }
      return '$verdict: you $myScore, friend ${o.score}.';
    }
    if (iFinished) return 'Waiting for your friend to finish…';
    if (o.total == 0) return 'Your friend is on the first question.';
    return 'Friend: ${o.answered} of ${o.total} answered, ${o.score} right.';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RaceState>(
      valueListenable: link.state,
      builder: (BuildContext context, RaceState s, Widget? _) {
        return Semantics(
          liveRegion: true,
          child: Container(
            key: const Key('race-banner'),
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
            ),
            child: Row(children: <Widget>[
              const Icon(Icons.people_alt_outlined,
                  size: 18, color: AppColors.gold),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  line(s,
                      myScore: myScore,
                      iFinished: iFinished,
                      myFinishedMs: link.myFinishedMs),
                  style: AppText.body.copyWith(fontSize: 14),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}
