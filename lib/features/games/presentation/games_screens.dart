import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/needs_internet_view.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/core/content/content_sync.dart';

class TriviaQ {
  final String id, category, question, why;
  final List<String> options;
  final int answer;
  const TriviaQ({required this.id, required this.category, required this.question,
      required this.options, required this.answer, required this.why});
  factory TriviaQ.fromJson(Map<String, dynamic> j) => TriviaQ(
    id: j['id'] as String, category: j['category'] as String, question: j['question'] as String,
    options: (j['options'] as List).cast<String>(),
    answer: j['answer'] as int, why: j['why'] as String);

  /// Same question with the options in a random order and [answer]
  /// re-pointed at the right one, so the correct position carries no signal
  /// whatever order the content pack ships in.
  TriviaQ shuffled(Random rnd) {
    final List<int> order = List<int>.generate(options.length, (int i) => i)
      ..shuffle(rnd);
    return TriviaQ(
      id: id,
      category: category,
      question: question,
      options: <String>[for (final int i in order) options[i]],
      answer: order.indexOf(answer),
      why: why,
    );
  }
}

final triviaProvider = FutureProvider<List<TriviaQ>>((ref) {
  return ContentSync.loadParsed<List<TriviaQ>>('games/trivia.json', (raw) {
    return (json.decode(raw) as List)
        .map((e) => TriviaQ.fromJson(e as Map<String, dynamic>))
        .toList();
  });
});

class Name99 {
  final int n; final String name, meaning, ref;
  const Name99({required this.n, required this.name, required this.meaning, required this.ref});
  factory Name99.fromJson(Map<String, dynamic> j) =>
      Name99(n: j['n'] as int, name: j['name'] as String, meaning: j['meaning'] as String, ref: j['ref'] as String);
}

final namesProvider = FutureProvider<List<Name99>>((ref) {
  return ContentSync.loadParsed<List<Name99>>('games/names99.json', (raw) {
    return (json.decode(raw) as List)
        .map((e) => Name99.fromJson(e as Map<String, dynamic>))
        .toList();
  });
});

class GamesScreen extends ConsumerWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          const ScreenHeader(title: 'Games', close: true),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text('LEARN BY PLAYING', style: AppText.eyebrow),
          ),
          GlassCard(
            onTap: () => context.open('/games/ludo'),
            child: _gameRow(Icons.casino_outlined, 'Ludo \u00b7 the second crown',
                'Dice, captures and four tokens racing home'),
          ),
          const SizedBox(height: 10),
          GlassCard(
            onTap: () => context.open('/games/shatranj'),
            child: _gameRow(Icons.extension_outlined, 'Shatranj \u00b7 the crown jewel',
                'Chess against Hadi\u2019s engine or a friend beside you'),
          ),
          const SizedBox(height: 10),
          GlassCard(
            onTap: () => context.open(AppRoutes.trivia),
            child: _gameRow(Icons.quiz_outlined, 'Daily Trivia',
                'Questions from the stories, graded and sourced'),
          ),
          const SizedBox(height: 10),
          GlassCard(
            onTap: () => context.open(AppRoutes.names99),
            child: _gameRow(Icons.spa_outlined, 'The 99 Names',
                'The beautiful names, one flashcard at a time'),
          ),
          const SizedBox(height: 10),
          GlassCard(
            onTap: () => context.open('/games/lineage'),
            child: _gameRow(Icons.account_tree_outlined, 'Lineage Challenge',
                'Who begot whom — the Messengers\u2019 tree as a game'),
          ),
          const SizedBox(height: 10),
          GlassCard(
            onTap: () => context.open('/games/ayah'),
            child: _gameRow(Icons.format_quote_outlined, 'Ayah Completion',
                'One word veiled — what did Allah say?'),
          ),
          const SizedBox(height: 10),
          GlassCard(
            onTap: () => context.open('/games/hijrah'),
            child: _gameRow(Icons.route_outlined, 'The Hijrah Journey',
                'Makkah to Madinah, station by station'),
          ),
        ],
      ),
    );
  }

  Widget _gameRow(IconData icon, String title, String sub) {
    return Row(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
          ),
          child: Icon(icon, size: 20, color: AppColors.goldLight),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.titleMedium),
              const SizedBox(height: 2),
              Text(sub, style: AppText.bodyMuted),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppColors.gold),
      ],
    );
  }
}

class TriviaScreen extends ConsumerStatefulWidget {
  const TriviaScreen({super.key});
  @override
  ConsumerState<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends ConsumerState<TriviaScreen> {
  List<TriviaQ> _qs = [];
  int _i = 0, _score = 0;
  int? _picked;
  bool _done = false;
  bool _review = false;

  /// The option chosen for each question, by question index, for the review.
  final Map<int, int> _answers = <int, int>{};

  @override
  Widget build(BuildContext context) {
    final qs = ref.watch(triviaProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: qs.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Column(children: [
          const ScreenHeader(title: 'Trivia', close: true),
          Expanded(
            child: NeedsInternetView(
              what: 'Trivia',
              onRetry: () => ref.invalidate(triviaProvider),
            ),
          ),
        ]),
        data: (all) {
          if (_qs.isEmpty) {
            final rnd = Random();
            _qs = (List.of(all)..shuffle(rnd))
                .take(10)
                .map((TriviaQ q) => q.shuffled(rnd))
                .toList();
          }
          if (_done) return _review ? _reviewList() : _result();
          final q = _qs[_i];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              const ScreenHeader(title: 'Trivia', close: true),
              const SizedBox(height: 8),
              Text('QUESTION ${_i + 1} OF ${_qs.length} — SCORE $_score',
                  style: AppText.eyebrow),
              const SizedBox(height: 10),
              GlassCard(
                child: Text(q.question,
                    style: AppText.body.copyWith(fontSize: 16, height: 1.5)),
              ),
              const SizedBox(height: 14),
              for (var o = 0; o < q.options.length; o++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _option(q, o),
                ),
              if (_picked != null) ...[
                const SizedBox(height: 6),
                GlassCard(
                  strong: _picked == q.answer,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _picked == q.answer ? 'CORRECT' : 'THE ANSWER: ${q.options[q.answer]}',
                        style: AppText.eyebrow.copyWith(
                          color: _picked == q.answer
                              ? AppColors.goldLight
                              : AppColors.sand,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(q.why, style: AppText.bodyMuted.copyWith(height: 1.5)),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => setState(() {
                            _picked = null;
                            if (_i + 1 >= _qs.length) {
                              _done = true;
                            } else {
                              _i++;
                            }
                          }),
                          child: Text(
                            _i + 1 >= _qs.length ? 'See results' : 'Next',
                            style: const TextStyle(color: AppColors.goldLight),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _option(TriviaQ q, int o) {
    final picked = _picked;
    Color? border = AppColors.gold.withValues(alpha: 0.25);
    if (picked != null) {
      if (o == q.answer) border = AppColors.gold;
      else if (o == picked) border = AppColors.sand.withValues(alpha: 0.7);
    }
    return GlassCard(
      onTap: picked == null
          ? () => setState(() {
                _picked = o;
                _answers[_i] = o;
                if (o == q.answer) _score++;
              })
          : null,
      child: Row(
        children: [
          Icon(Icons.circle_outlined, size: 14, color: border),
          const SizedBox(width: 10),
          Expanded(child: Text(q.options[o], style: AppText.body)),
        ],
      ),
    );
  }

  /// Back to the Games hub: pop to it when the trivia was opened from it
  /// (so its own Back keeps working), open it when there is nothing to pop.
  void _backToGames() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.games);
    }
  }

  void _playAgain() => setState(() {
        _qs = [];
        _i = 0;
        _score = 0;
        _picked = null;
        _done = false;
        _review = false;
        _answers.clear();
      });

  Widget _result() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        const ScreenHeader(title: 'Trivia', close: true),
        const SizedBox(height: 24),
        Center(child: Text('FINISHED', style: AppText.eyebrow)),
        const SizedBox(height: 8),
        Center(
          child: Text('$_score / ${_qs.length}',
              style: const TextStyle(
                  fontFamily: 'PlayfairDisplay', fontSize: 44, color: AppColors.goldLight)),
        ),
        const SizedBox(height: 6),
        Text(
          _score >= 8
              ? 'MashaAllah \u2014 the stories are becoming yours.'
              : _score >= 5
                  ? 'Well walked. Read one story tonight and return.'
                  : 'Every master was once here. The Stories shelf is waiting.',
          style: AppText.bodyMuted,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => setState(() => _review = true),
              icon: const Icon(Icons.fact_check_outlined, size: 16),
              label: const Text('Review answers'),
            ),
            OutlinedButton.icon(
              onPressed: _playAgain,
              icon: const Icon(Icons.replay, size: 16),
              label: const Text('Play again'),
            ),
            OutlinedButton.icon(
              onPressed: _backToGames,
              icon: const Icon(Icons.sports_esports_outlined, size: 16),
              label: const Text('Back to Games'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go(AppRoutes.home),
              icon: const Icon(Icons.home_outlined, size: 16),
              label: const Text('Home'),
            ),
          ],
        ),
      ],
    );
  }

  /// Every question with the answer given, the right answer and the reason.
  Widget _reviewList() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        const ScreenHeader(title: 'Your answers', close: true),
        for (var i = 0; i < _qs.length; i++) ...[
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QUESTION ${i + 1} \u00b7 '
                  '${_answers[i] == _qs[i].answer ? 'CORRECT' : 'MISSED'}',
                  style: AppText.eyebrow.copyWith(
                    color: _answers[i] == _qs[i].answer
                        ? AppColors.goldLight
                        : AppColors.sand,
                  ),
                ),
                const SizedBox(height: 6),
                Text(_qs[i].question,
                    style: AppText.body.copyWith(height: 1.45)),
                const SizedBox(height: 8),
                if (_answers[i] != null && _answers[i] != _qs[i].answer)
                  Text('Your answer: ${_qs[i].options[_answers[i]!]}',
                      style: AppText.bodyMuted),
                Text('Answer: ${_qs[i].options[_qs[i].answer]}',
                    style: AppText.body.copyWith(color: AppColors.goldLight)),
                const SizedBox(height: 6),
                Text(_qs[i].why,
                    style: AppText.bodyMuted.copyWith(height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: () => setState(() => _review = false),
              child: const Text('Back to results'),
            ),
            OutlinedButton(
              onPressed: _backToGames,
              child: const Text('Back to Games'),
            ),
            OutlinedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Home'),
            ),
          ],
        ),
      ],
    );
  }
}

class Names99Screen extends ConsumerStatefulWidget {
  const Names99Screen({super.key});
  @override
  ConsumerState<Names99Screen> createState() => _Names99ScreenState();
}

/// How a name's source reads on screen: "Qur’an 2:163" for a verse
/// reference, the text as it is for anything else (the first name's ref is
/// just "Allah").
String names99RefLabel(String ref) =>
    RegExp(r'^\d+:\d+').hasMatch(ref) ? 'Qur\u2019an $ref' : ref;

class _Names99ScreenState extends ConsumerState<Names99Screen> {
  int _i = 0;
  bool _flip = false;
  bool _list = false;

  Widget _modeToggle() => Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final (bool, String) m in const <(bool, String)>[
            (false, 'One at a time'),
            (true, 'All 99'),
          ])
            ChoiceChip(
              key: Key(m.$1 ? 'names-mode-list' : 'names-mode-cards'),
              label: Text(m.$2),
              selected: _list == m.$1,
              onSelected: (_) => setState(() => _list = m.$1),
            ),
        ],
      );

  Widget _listView(List<Name99> deck) => Column(
        children: [
          for (int k = 0; k < deck.length; k++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                key: Key('names-row-${deck[k].n}'),
                blur: false,
                onTap: () => setState(() {
                  _i = k;
                  _flip = false;
                  _list = false;
                }),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 34,
                      child: Text('${deck[k].n}', style: AppText.eyebrow),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(deck[k].name, style: AppText.titleMedium),
                          const SizedBox(height: 2),
                          Text(deck[k].meaning, style: AppText.bodyMuted),
                          const SizedBox(height: 2),
                          Text(
                            names99RefLabel(deck[k].ref),
                            style: AppText.bodyMuted.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final names = ref.watch(namesProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: names.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Column(children: [
          const ScreenHeader(title: 'The 99 Names', close: true),
          Expanded(
            child: NeedsInternetView(
              what: 'The 99 Names',
              onRetry: () => ref.invalidate(namesProvider),
            ),
          ),
        ]),
        data: (deck) {
          final d = deck[_i];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              const ScreenHeader(title: 'The 99 Names', close: true),
              _modeToggle(),
              const SizedBox(height: 10),
              if (_list) _listView(deck) else ...[
              Center(child: Text('${_i + 1} OF ${deck.length}', style: AppText.eyebrow)),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => setState(() => _flip = !_flip),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
                    color: const Color(0x0F05090F),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _flip
                        ? Column(
                            key: const ValueKey('back'),
                            children: [
                              Text(d.meaning,
                                  textAlign: TextAlign.center,
                                  style: AppText.body.copyWith(fontSize: 17, height: 1.5)),
                              const SizedBox(height: 8),
                              Text(names99RefLabel(d.ref),
                                  style: AppText.bodyMuted.copyWith(fontSize: 12)),
                            ],
                          )
                        : Text(
                            d.name,
                            key: const ValueKey('front'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontFamily: 'PlayfairDisplay',
                                fontSize: 34,
                                color: AppColors.goldLight),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(child: Text('Tap the card to flip', style: AppText.bodyMuted)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _i > 0
                        ? () => setState(() { _i--; _flip = false; })
                        : null,
                    child: Text('Previous',
                        style: TextStyle(
                            color: _i > 0
                                ? AppColors.goldLight
                                : AppColors.sand.withValues(alpha: 0.3))),
                  ),
                  TextButton.icon(
                    onPressed: _i < deck.length - 1
                        ? () => setState(() { _i++; _flip = false; })
                        : null,
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward_ios,
                        size: 12, color: AppColors.gold),
                    label: Text('Next', style: AppText.bodyMuted),
                  ),
                ],
              ),
              ],
            ],
          );
        },
      ),
    );
  }
}
