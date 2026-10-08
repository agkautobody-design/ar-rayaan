import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/core/content/content_sync.dart';

class TriviaQ {
  final String id, category, question, why;
  final List<String> options;
  final int answer;
  const TriviaQ({required this.id, required this.category, required this.question,
      required this.options, required this.answer, required this.why});
  factory TriviaQ.fromJson(Map<String, dynamic> j) => TriviaQ(
    id: j['id'], category: j['category'], question: j['question'],
    options: (j['options'] as List).cast<String>(),
    answer: j['answer'], why: j['why']);
}

final triviaProvider = FutureProvider<List<TriviaQ>>((ref) async {
  final raw = await ContentSync.load('games/trivia.json');
  return (json.decode(raw) as List).map((e) => TriviaQ.fromJson(e)).toList();
});

class Name99 {
  final int n; final String name, meaning, ref;
  const Name99({required this.n, required this.name, required this.meaning, required this.ref});
  factory Name99.fromJson(Map<String, dynamic> j) =>
      Name99(n: j['n'], name: j['name'], meaning: j['meaning'], ref: j['ref']);
}

final namesProvider = FutureProvider<List<Name99>>((ref) async {
  final raw = await ContentSync.load('games/names99.json');
  return (json.decode(raw) as List).map((e) => Name99.fromJson(e)).toList();
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
            onTap: () => context.go(AppRoutes.trivia),
            child: _gameRow(Icons.quiz_outlined, 'Daily Trivia',
                'Questions from the stories, graded and sourced'),
          ),
          const SizedBox(height: 10),
          GlassCard(
            onTap: () => context.go(AppRoutes.names99),
            child: _gameRow(Icons.spa_outlined, 'The 99 Names',
                'The beautiful names, one flashcard at a time'),
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

  @override
  Widget build(BuildContext context) {
    final qs = ref.watch(triviaProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: qs.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(child: Text('Could not load trivia.', style: AppText.bodyMuted)),
        data: (all) {
          if (_qs.isEmpty) {
            final rnd = Random();
            _qs = List.of(all)..shuffle(rnd);
            _qs = _qs.take(10).toList();
          }
          if (_done) return _result();
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

  Widget _result() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('FINISHED', style: AppText.eyebrow),
            const SizedBox(height: 8),
            Text('$_score / ${_qs.length}',
                style: const TextStyle(
                    fontFamily: 'Cinzel', fontSize: 44, color: AppColors.goldLight)),
            const SizedBox(height: 6),
            Text(
              _score >= 8
                  ? 'MashaAllah — the stories are becoming yours.'
                  : _score >= 5
                      ? 'Well walked. Read one story tonight and return.'
                      : 'Every master was once here. The Stories shelf is waiting.',
              style: AppText.bodyMuted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: () => setState(() {
                _qs = [];
                _i = 0; _score = 0; _picked = null; _done = false;
              }),
              child: const Text('Play again',
                  style: TextStyle(color: AppColors.goldLight)),
            ),
          ],
        ),
      ),
    );
  }
}

class Names99Screen extends ConsumerStatefulWidget {
  const Names99Screen({super.key});
  @override
  ConsumerState<Names99Screen> createState() => _Names99ScreenState();
}

class _Names99ScreenState extends ConsumerState<Names99Screen> {
  int _i = 0;
  bool _flip = false;

  @override
  Widget build(BuildContext context) {
    final names = ref.watch(namesProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: names.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(child: Text('Could not load the names.', style: AppText.bodyMuted)),
        data: (deck) {
          final d = deck[_i];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              const ScreenHeader(title: 'The 99 Names', close: true),
              const SizedBox(height: 6),
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
                              Text(d.ref,
                                  style: AppText.bodyMuted.copyWith(fontSize: 11)),
                            ],
                          )
                        : Text(
                            d.name,
                            key: const ValueKey('front'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontFamily: 'Cinzel',
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
          );
        },
      ),
    );
  }
}
