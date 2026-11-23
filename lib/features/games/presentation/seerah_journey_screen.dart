import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../data/learning_loader.dart';
import '../engine/quiz_engine.dart';
import '../ui/game_stats.dart';
import '../ui/games_theme.dart';
import 'puzzle_games.dart';

typedef _Chapter = ({String id, String title, List<QuizQuestion> questions});

const String _prefKey = 'seerah_journey_done';

/// Seerah Journey: the stories of the Seerah School in order, one chapter
/// each. Answer a chapter's questions; get at least half right to finish it
/// and move on. Finished chapters are remembered on this device.
class SeerahJourneyScreen extends ConsumerStatefulWidget {
  const SeerahJourneyScreen({super.key});

  @override
  ConsumerState<SeerahJourneyScreen> createState() => _JourneyState();
}

class _JourneyState extends ConsumerState<SeerahJourneyScreen> {
  List<_Chapter>? _chapters;
  Set<String> _done = <String>{};
  _Chapter? _open;
  int _i = 0;
  int? _picked;
  int _right = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _done = (ref.read(sharedPreferencesProvider).getStringList(_prefKey) ??
            <String>[])
        .toSet();
    LearningLoader.seerahJourney().then((List<_Chapter> c) {
      if (mounted) setState(() => _chapters = c);
    });
  }

  void _begin(_Chapter c) => setState(() {
        _open = c;
        _i = 0;
        _picked = null;
        _right = 0;
        _finished = false;
      });

  void _pick(int o) {
    if (_picked != null) return;
    setState(() {
      _picked = o;
      if (o == _open!.questions[_i].answer) _right++;
    });
  }

  void _next() {
    final _Chapter c = _open!;
    if (_i + 1 < c.questions.length) {
      setState(() {
        _i++;
        _picked = null;
      });
      return;
    }
    final bool pass = _right * 2 >= c.questions.length;
    if (pass) {
      _done.add(c.id);
      ref
          .read(sharedPreferencesProvider)
          .setStringList(_prefKey, _done.toList());
    }
    setState(() => _finished = true);
  }

  @override
  Widget build(BuildContext context) {
    final List<_Chapter>? chapters = _chapters;
    if (chapters == null) {
      return const PuzzleFrame(
        title: 'Seerah Journey',
        children: <Widget>[Center(child: CircularProgressIndicator())],
      );
    }
    final _Chapter? c = _open;
    if (c == null) return _list(chapters);
    if (_finished) {
      final bool pass = _right * 2 >= c.questions.length;
      return PuzzleFrame(
        title: 'Seerah Journey',
        tagline: c.title,
        children: <Widget>[
          const SizedBox(height: 12),
          GamePanel(
            child: Column(children: <Widget>[
              Icon(
                pass ? Icons.emoji_events_outlined : Icons.refresh,
                size: 56,
                color: AppColors.gold,
              ),
              const SizedBox(height: 6),
              Text(pass ? 'Chapter complete' : 'Not quite yet',
                  style: AppText.titleMedium),
              const SizedBox(height: 6),
              Text('$_right of ${c.questions.length} right.',
                  style: AppText.bodyMuted),
            ]),
          ),
          const SizedBox(height: 12),
          GameStatBar(
            stats: <GameStat>[
              GameStat(Icons.check_circle_outline, 'Correct',
                  '$_right / ${c.questions.length}'),
              GameStat(Icons.track_changes, 'Accuracy',
                  '${(100 * _right / c.questions.length).round()}%'),
            ],
          ),
          const SizedBox(height: 12),
          PlayButton(
            label: pass ? 'Back to the journey' : 'Try the chapter again',
            onPressed: () => pass ? setState(() => _open = null) : _begin(c),
          ),
          if (!pass) ...<Widget>[
            const SizedBox(height: 10),
            OutlineAction(
              label: 'Back to the journey',
              onPressed: () => setState(() => _open = null),
            ),
          ],
        ],
      );
    }
    final QuizQuestion q = c.questions[_i];
    final bool answered = _picked != null;
    return PuzzleFrame(
      title: 'Seerah Journey',
      tagline: c.title,
      children: <Widget>[
        const SizedBox(height: 8),
        GamePanel(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Question ${_i + 1} of ${c.questions.length}',
                  style: AppText.titleMedium.copyWith(
                    color: GamesTheme.champagne,
                  ),
                ),
              ),
              GameDots(
                done: _i + (answered ? 1 : 0),
                total: c.questions.length,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GamePanel(child: Text(q.prompt, style: AppText.body.copyWith(height: 1.5))),
        const SizedBox(height: 10),
        for (int o = 0; o < q.options.length; o++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GamePanel(
              semanticsLabel: q.options[o],
              onTap: () => _pick(o),
              child: Row(children: <Widget>[
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  margin: const EdgeInsetsDirectional.only(end: 12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.goldLight),
                  ),
                  child: Text(
                    String.fromCharCode(65 + o),
                    style: AppText.body.copyWith(
                      color: AppColors.goldLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    q.options[o],
                    style: AppText.body.copyWith(
                      color: answered && o == q.answer
                          ? AppColors.goldLight
                          : null,
                    ),
                  ),
                ),
                if (answered && o == q.answer)
                  const Icon(Icons.check_circle, color: AppColors.goldLight),
              ]),
            ),
          ),
        if (answered) ...<Widget>[
          Text(_picked == q.answer ? 'Right.' : 'Not this time.',
              style: AppText.titleMedium),
          const SizedBox(height: 4),
          Text(q.explanation, style: AppText.bodyMuted.copyWith(height: 1.5)),
          const SizedBox(height: 4),
          Text(q.citation, style: AppText.caption),
          const SizedBox(height: 12),
          PlayButton(
            label: _i + 1 >= c.questions.length ? 'Finish chapter' : 'Next',
            onPressed: _next,
          ),
        ],
      ],
    );
  }

  Widget _list(List<_Chapter> chapters) {
    return PuzzleFrame(
      title: 'Seerah Journey',
      tagline: 'Follow the story, chapter by chapter',
      children: <Widget>[
        const SizedBox(height: 8),
        GameStatBar(
          stats: <GameStat>[
            GameStat(Icons.flag_outlined, 'Chapters',
                '${_done.length} of ${chapters.length}'),
          ],
        ),
        const SizedBox(height: 10),
        for (int k = 0; k < chapters.length; k++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GamePanel(
              semanticsLabel:
                  'Chapter ${k + 1}, ${chapters[k].title}${_done.contains(chapters[k].id) ? ', complete' : ''}',
              onTap: () => _begin(chapters[k]),
              child: Row(children: <Widget>[
                Icon(
                  _done.contains(chapters[k].id)
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: AppColors.goldLight,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('${k + 1}. ${chapters[k].title}',
                      style: AppText.body),
                ),
                const Icon(Icons.chevron_right, color: AppColors.goldLight),
              ]),
            ),
          ),
      ],
    );
  }
}
