import 'dart:math';

import 'package:flutter/material.dart' hide Text;

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../data/learning_loader.dart';
import '../engine/quiz_engine.dart';
import '../ui/games_theme.dart';
import 'puzzle_games.dart';

/// Family Quiz: two teams share one device and answer in turn. Twelve
/// questions from the Seerah and the Hadith banks, six for each team.
/// Every answer shows the explanation and its source before the device
/// moves on.
class FamilyQuizScreen extends StatefulWidget {
  const FamilyQuizScreen({super.key});

  @override
  State<FamilyQuizScreen> createState() => _FamilyQuizState();
}

class _FamilyQuizState extends State<FamilyQuizScreen> {
  static const int _perTeam = 6;
  List<QuizQuestion>? _qs;
  String? _error;
  int _i = 0;
  int? _picked;
  final List<int> _right = <int>[0, 0];
  final List<String> _names = <String>['Team Gold', 'Team Cream'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final Random r = Random();
      final List<QuizQuestion> a =
          await LearningLoader.seerahQuiz(r, _perTeam);
      final List<QuizQuestion> b =
          await LearningLoader.hadithQuiz(r, _perTeam);
      final List<QuizQuestion> mix = <QuizQuestion>[];
      for (int k = 0; k < _perTeam; k++) {
        if (k < a.length) mix.add(a[k]);
        if (k < b.length) mix.add(b[k]);
      }
      if (!mounted) return;
      setState(() {
        _qs = mix;
        _i = 0;
        _picked = null;
        _right[0] = 0;
        _right[1] = 0;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'The questions could not be loaded.');
    }
  }

  void _pick(int o) {
    if (_picked != null) return;
    setState(() {
      _picked = o;
      if (o == _qs![_i].answer) _right[_i % 2]++;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return PuzzleFrame(title: 'Family Quiz', children: <Widget>[Text(_error!)]);
    }
    final List<QuizQuestion>? qs = _qs;
    if (qs == null) {
      return const PuzzleFrame(
        title: 'Family Quiz',
        children: <Widget>[Center(child: CircularProgressIndicator())],
      );
    }
    if (_i >= qs.length) {
      final String result = _right[0] == _right[1]
          ? 'A tie'
          : '${_names[_right[0] > _right[1] ? 0 : 1]} wins';
      return PuzzleFrame(
        title: 'Family Quiz',
        children: <Widget>[
          const SizedBox(height: 12),
          puzzleDone(
            context,
            headline: result,
            detail: '${_names[0]}: ${_right[0]} right.  '
                '${_names[1]}: ${_right[1]} right.',
          ),
          const SizedBox(height: 10),
          OutlineAction(
            label: 'Play again',
            onPressed: () => setState(() {
              _qs = null;
              _load();
            }),
          ),
        ],
      );
    }
    final QuizQuestion q = qs[_i];
    final int team = _i % 2;
    final bool answered = _picked != null;
    return PuzzleFrame(
      title: 'Family Quiz',
      tagline: 'Two teams, one device',
      children: <Widget>[
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            for (int t = 0; t < 2; t++)
              Text(
                '${_names[t]}: ${_right[t]}',
                style: AppText.label.copyWith(
                  color: t == team ? AppColors.goldLight : AppColors.textMuted,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Semantics(
          liveRegion: true,
          child: Text('${_names[team]}, your question'.toUpperCase(),
              style: AppText.eyebrow),
        ),
        const SizedBox(height: 8),
        GamePanel(
          child: Text(q.prompt,
              style: AppText.body.copyWith(height: 1.5),
              textDirection:
                  q.promptIsArabic ? TextDirection.rtl : TextDirection.ltr),
        ),
        const SizedBox(height: 10),
        for (int o = 0; o < q.options.length; o++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GamePanel(
              semanticsLabel: q.options[o],
              onTap: () => _pick(o),
              child: Row(children: <Widget>[
                Expanded(
                  child: Text(
                    q.options[o],
                    style: AppText.body.copyWith(
                      color: !answered
                          ? null
                          : o == q.answer
                              ? AppColors.goldLight
                              : (o == _picked ? AppColors.textFaint : null),
                    ),
                  ),
                ),
                if (answered && o == q.answer)
                  const Icon(Icons.check_circle, color: AppColors.goldLight),
              ]),
            ),
          ),
        if (answered) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            _picked == q.answer ? 'Right.' : 'Not this time.',
            style: AppText.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(q.explanation,
              style: AppText.bodyMuted.copyWith(height: 1.5)),
          const SizedBox(height: 4),
          Text(q.citation, style: AppText.caption),
          const SizedBox(height: 12),
          PlayButton(
            label: _i + 1 >= qs.length ? 'See the result' : 'Pass the device',
            onPressed: () => setState(() {
              _i++;
              _picked = null;
            }),
          ),
        ],
      ],
    );
  }
}
