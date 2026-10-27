import 'dart:async' show unawaited;
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/needs_internet_view.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../data/game_history.dart';
import '../data/games_adapters.dart';
import '../data/game_settings.dart';
import '../data/games_store.dart';
import '../data/learning_loader.dart';
import '../engine/game_registry.dart';
import '../engine/quiz_engine.dart';
import '../ui/games_theme.dart';
import '../../hadi/data/hadi_game_ask.dart';
import '../ui/learning_widgets.dart';
import 'game_results_screen.dart';
import 'games_screens.dart';

/// /games/g/:id/play - the shared quiz screen for Qur'an Knowledge and
/// Stories Trivia. No timer. After every answer it shows the right answer,
/// why, and the source. The game is saved after each answer so it can be
/// continued from the hub.
class QuizPlayScreen extends ConsumerStatefulWidget {
  const QuizPlayScreen({
    required this.gameId,
    required this.config,
    this.resume = false,
    super.key,
  });

  final String gameId;
  final QuizConfig config;

  /// Open the saved, unfinished game instead of starting a new one.
  final bool resume;

  @override
  ConsumerState<QuizPlayScreen> createState() => _QuizPlayState();
}

class _QuizPlayState extends ConsumerState<QuizPlayScreen> {
  final Random _rnd = Random();
  QuizSession? _session;
  bool _loading = true;
  bool _failed = false;
  GameResult? _result;
  bool _review = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  GameDef? get _def => gameById(widget.gameId);

  Future<void> _load() async {
    try {
      QuizSession? s;
      if (widget.resume) {
        s = ref.read(gamesStoreProvider.notifier).savedSession(widget.gameId);
      }
      if (s == null) {
        final QuizConfig c = widget.config;
        final List<QuizQuestion> qs;
        if (widget.gameId == 'qk') {
          final String raw =
              await rootBundle.loadString('assets/quran/quran.json');
          final List<dynamic> quran = json.decode(raw) as List<dynamic>;
          qs = buildQuranQuiz(
            quran,
            _rnd,
            count: c.count,
            difficulty: c.difficulty,
            topic: c.topic,
          );
        } else if (widget.gameId == 'stories') {
          final List<TriviaQ> rows = await ref.read(triviaProvider.future);
          qs = buildStoriesQuiz(
            triviaRows(rows),
            _rnd,
            count: c.count,
            topic: c.topic,
          );
        } else if (widget.gameId == 'seerah') {
          qs = await LearningLoader.seerahQuiz(_rnd, c.count);
        } else if (widget.gameId == 'hadith') {
          qs = await LearningLoader.hadithQuiz(_rnd, c.count);
        } else if (widget.gameId == 'arabic-words') {
          qs = await LearningLoader.arabicWordsQuiz(_rnd, c.count, c.topic);
        } else {
          qs = <QuizQuestion>[];
        }
        if (qs.isEmpty) throw StateError('no questions');
        s = QuizSession(config: c, questions: qs);
      }
      if (!mounted) return;
      setState(() {
        _session = s;
        _loading = false;
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _failed = false;
    });
    if (widget.gameId == 'stories') ref.invalidate(triviaProvider);
    unawaited(_load());
  }

  void _save() {
    final QuizSession? s = _session;
    if (s == null) return;
    unawaited(ref.read(gamesStoreProvider.notifier).saveSession(s));
  }

  void _pick(int o) {
    final QuizSession s = _session!;
    if (!s.pick(o)) return;
    setState(() {});
    _save();
  }

  void _hint() {
    final QuizSession s = _session!;
    if (s.useHint(_rnd) == null) return;
    setState(() {});
    _save();
  }

  void _next() {
    final QuizSession s = _session!;
    if (s.finished) {
      _finish();
      return;
    }
    if (s.next()) {
      setState(() {});
      _save();
    }
  }

  void _finish() {
    final QuizSession s = _session!;
    final GameDef? g = _def;
    final int now = DateTime.now().millisecondsSinceEpoch;
    final GameResult r = GameResult(
      id: '${widget.gameId}-$now',
      gameId: widget.gameId,
      title: g?.title ?? 'Quiz',
      finishedMs: now,
      correct: s.correct,
      total: s.total,
      players: s.config.players,
      playerScores: s.config.players > 1 ? List<int>.of(s.scores) : <int>[],
      difficulty: widget.gameId == 'qk' ? s.config.difficulty.label : null,
    );
    final GamesStoreController store = ref.read(gamesStoreProvider.notifier);
    unawaited(store.record(r));
    unawaited(store.clearSaved(widget.gameId));
    setState(() => _result = r);
  }

  @override
  Widget build(BuildContext context) {
    final String title = _def?.title ?? 'Quiz';
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: <Widget>[
            ScreenHeader(title: title, close: true, showSettings: false),
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
            ),
          ],
        ),
      );
    }
    if (_failed || _session == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: <Widget>[
            ScreenHeader(title: title, close: true, showSettings: false),
            Expanded(
              child: widget.gameId == 'stories'
                  ? NeedsInternetView(what: title, onRetry: _retry)
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              'The questions could not be made. Please try '
                              'again.',
                              textAlign: TextAlign.center,
                              style: AppText.body,
                            ),
                            const SizedBox(height: 16),
                            PlayButton(label: 'Try again', onPressed: _retry),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      );
    }
    final QuizSession s = _session!;
    final GameResult? done = _result;
    if (done != null) return _finishedPage(s, done, title);
    return _questionPage(s, title);
  }

  Widget _finishedPage(QuizSession s, GameResult r, String title) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: <Widget>[
          ScreenHeader(title: title, close: true, showSettings: false),
          ResultSummaryView(result: r),
          const SizedBox(height: 16),
          Center(
            child: OutlineAction(
              label: _review ? 'Hide answers' : 'Review answers',
              icon: Icons.fact_check_outlined,
              onPressed: () => setState(() => _review = !_review),
            ),
          ),
          if (_review) ...<Widget>[
            const SizedBox(height: 14),
            QuizReviewList(session: s),
          ],
        ],
      ),
      bottomNavigationBar: BottomActions(
        children: <Widget>[
          PlayButton(
            label: 'Play again',
            icon: Icons.replay,
            onPressed: () => context.go('/games/g/${widget.gameId}/setup'),
          ),
          OutlineAction(
            label: 'Game history',
            onPressed: () => context.open('/games/history'),
          ),
          OutlineAction(
            label: 'All games',
            onPressed: () => context.go(AppRoutes.games),
          ),
        ],
      ),
    );
  }

  Widget _questionPage(QuizSession s, String title) {
    final QuizQuestion q = s.current;
    final int? pick = s.picks[s.index];
    final bool answered = pick != null;
    final int players = s.config.players;
    final bool correct = pick == q.answer;
    final String nextLabel = s.finished
        ? 'See results'
        : players > 1
            ? 'Pass to Player ${(s.index + 1) % players + 1}'
            : 'Next question';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: <Widget>[
          ScreenHeader(title: title, close: true, showSettings: false),
          Text(
            'QUESTION ${s.index + 1} OF ${s.total}',
            style: AppText.eyebrow,
          ),
          const SizedBox(height: 8),
          GameProgressBar(
            value: (s.index + (answered ? 1 : 0)) / s.total,
            label: 'Question ${s.index + 1} of ${s.total}',
          ),
          if (players > 1) ...<Widget>[
            const SizedBox(height: 12),
            GamePanel(
              selected: true,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.person_outline, color: AppColors.goldLight),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Player ${s.player + 1}, it is your turn',
                      style: AppText.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: GamesTheme.champagne,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (s.config.hints &&
              !answered &&
              ref.watch(gameSettingsProvider).showHints) ...<Widget>[
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: OutlineAction(
                label: s.hintsLeft > 0
                    ? 'Hint (${s.hintsLeft} left)'
                    : 'No hints left',
                icon: Icons.lightbulb_outline,
                onPressed: s.canUseHint ? _hint : null,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (q.context != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 4),
              child: Text(q.context!, style: AppText.bodyMuted),
            ),
          GamePanel(
            child: q.promptIsArabic
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        q.kicker ?? 'Complete the ayah',
                        style: AppText.eyebrow,
                      ),
                      const SizedBox(height: 8),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          q.prompt,
                          textAlign: TextAlign.center,
                          style: AppText.arabic.copyWith(
                            fontSize: 26,
                            height: 2,
                            color: GamesTheme.champagne,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (q.kicker != null) ...<Widget>[
                        Text(q.kicker!, style: AppText.eyebrow),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        q.prompt,
                        style: AppText.body.copyWith(fontSize: 17, height: 1.5),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          for (int o = 0; o < q.options.length; o++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _option(s, o),
            ),
          if (answered) ...<Widget>[
            const SizedBox(height: 4),
            GamePanel(
              selected: correct,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        correct ? Icons.check_circle : Icons.info_outline,
                        color: correct
                            ? GamesTheme.good
                            : AppColors.sand,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          correct ? 'Correct' : 'Not quite',
                          style: AppText.titleMedium.copyWith(
                            color: GamesTheme.champagne,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    q.explanation,
                    style: AppText.body.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Source: ${q.citation}',
                    style: AppText.bodyMuted.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  AskHadiAboutButton(question: _askText(q)),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: answered
          ? BottomActions(
              children: <Widget>[
                PlayButton(
                  label: nextLabel,
                  icon: Icons.arrow_forward,
                  onPressed: _next,
                ),
              ],
            )
          : null,
    );
  }

  /// The question Hadi is asked from "Ask Hadi about this".
  String _askText(QuizQuestion q) => HadiGameAsk.quiz(
        prompt: q.prompt,
        answer: q.options[q.answer],
        explanation: q.explanation,
        citation: q.citation,
      );

  Widget _option(QuizSession s, int o) {
    final QuizQuestion q = s.current;
    final int? pick = s.picks[s.index];
    final bool answered = pick != null;
    final bool hidden = s.hiddenNow.contains(o);
    final bool isAnswer = o == q.answer;
    final bool isPick = o == pick;
    IconData icon = Icons.circle_outlined;
    String? tag;
    if (answered && isAnswer) {
      icon = Icons.check_circle;
      tag = 'Right answer';
    } else if (answered && isPick) {
      icon = Icons.remove_circle_outline;
      tag = 'Your answer';
    }
    final String text = q.options[o];
    final Widget label = q.optionsAreArabic
        ? Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: AppText.arabic.copyWith(
                fontSize: 24,
                color: GamesTheme.champagne,
              ),
            ),
          )
        : Text(text, style: AppText.body.copyWith(fontSize: 16, height: 1.4));
    final Widget panel = GamePanel(
      selected: answered && isAnswer,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      semanticsLabel: answered || hidden
          ? null
          : text,
      onTap: answered || hidden ? null : () => _pick(o),
      child: Row(
        children: <Widget>[
          Icon(
            icon,
            size: 22,
            color: answered && isAnswer
                ? GamesTheme.good
                : AppColors.goldLight,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: q.optionsAreArabic
                  ? CrossAxisAlignment.stretch
                  : CrossAxisAlignment.start,
              children: <Widget>[
                label,
                if (tag != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      tag,
                      textAlign:
                          q.optionsAreArabic ? TextAlign.center : TextAlign.start,
                      style: AppText.caption,
                    ),
                  ),
                if (hidden)
                  Text(
                    'Removed by your hint',
                    textAlign:
                        q.optionsAreArabic ? TextAlign.center : TextAlign.start,
                    style: AppText.caption,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    return hidden ? Opacity(opacity: 0.45, child: panel) : panel;
  }
}
