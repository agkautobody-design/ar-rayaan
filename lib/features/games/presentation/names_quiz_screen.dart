import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../data/names_rounds.dart';
import '../data/race_link.dart';
import 'games_screens.dart';
import 'race_banner.dart';

/// "Which Name means …?" — ten questions from the 99 Names. Played alone, or
/// raced with a friend online: both players get the same questions (one
/// shared seed) and see each other's progress ([RaceLink]).
class NamesQuizScreen extends ConsumerStatefulWidget {
  const NamesQuizScreen({super.key, this.raceCode, this.raceSide, this.seed});

  final String? raceCode;
  final String? raceSide;
  final int? seed;

  @override
  ConsumerState<NamesQuizScreen> createState() => _NamesQuizState();
}

class _NamesQuizState extends ConsumerState<NamesQuizScreen> {
  RaceLink? _race;
  List<NamesRound>? _rounds;
  int _i = 0, _score = 0;
  int? _picked;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    final String? code = widget.raceCode;
    if (code != null && widget.raceSide != null) {
      _race = RaceLink(
        code: code,
        side: widget.raceSide!,
        startN: widget.raceSide == 'host' ? 1 : 0,
      )..listen();
    }
  }

  @override
  void dispose() {
    final RaceLink? r = _race;
    if (r != null) {
      if (!_finished || r.state.value.opponent.finished) {
        unawaited(r.leave());
      }
      r.dispose();
    }
    super.dispose();
  }

  void _next() {
    final List<NamesRound> rounds = _rounds!;
    final NamesRound r = rounds[_i];
    if (_picked == r.answer) _score++;
    unawaited(_race?.report(_i + 1, rounds.length, _score) ??
        Future<void>.value());
    if (_i == rounds.length - 1) {
      unawaited(_race?.finish(rounds.length, _score) ?? Future<void>.value());
      setState(() => _finished = true);
    } else {
      setState(() {
        _picked = null;
        _i++;
      });
    }
  }

  Widget _option(NamesRound r, int o) {
    final bool answered = _picked != null;
    final bool right = answered && o == r.answer;
    final bool wrong = answered && o == _picked && o != r.answer;
    final String? tag = right
        ? (o == _picked ? 'Correct answer · your answer' : 'Correct answer')
        : (wrong ? 'Your answer' : null);
    final Color? edge = right
        ? const Color(0xFF7FD1A8)
        : (wrong ? const Color(0xFFE8A07F) : null);
    final Widget card = GlassCard(
      onTap: answered ? null : () => setState(() => _picked = o),
      semanticsLabel: tag == null ? null : '${r.options[o]}. $tag',
      child: Row(children: <Widget>[
        if (answered && edge != null) ...<Widget>[
          Icon(right ? Icons.check_circle : Icons.cancel, size: 20, color: edge),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(r.options[o], style: AppText.body.copyWith(fontSize: 14)),
              if (tag != null)
                Text(tag,
                    style: AppText.bodyMuted.copyWith(fontSize: 12, color: edge)),
            ],
          ),
        ),
      ]),
    );
    if (edge == null) return card;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: edge, width: 2),
      ),
      child: card,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Name99>> async = ref.watch(namesProvider);
    return async.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      ),
      error: (Object e, StackTrace s) => Scaffold(
        backgroundColor: Colors.transparent,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: <Widget>[
            const ScreenHeader(title: 'Names quiz', close: true),
            Text('The Names could not be loaded. Check your connection and try again.',
                style: AppText.bodyMuted),
          ],
        ),
      ),
      data: (List<Name99> names) {
        _rounds ??= buildNamesRounds(
          <NamesCard>[
            for (final Name99 n in names)
              if (n.kind == 'name')
                NamesCard(n.name, n.meaning, n.ref, n.arabic),
          ],
          widget.seed != null ? Random(widget.seed) : Random(),
        );
        final List<NamesRound> rounds = _rounds!;
        if (rounds.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: <Widget>[
                const ScreenHeader(title: 'Names quiz', close: true),
                Text('There are not enough Names to make a quiz.',
                    style: AppText.bodyMuted),
              ],
            ),
          );
        }
        if (_finished) return _done(rounds.length);
        final NamesRound r = rounds[_i];
        final bool last = _i == rounds.length - 1;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: <Widget>[
              const ScreenHeader(title: 'Names quiz', close: true),
              if (_race != null)
                RaceBanner(
                    link: _race!, myScore: _score, myTotal: rounds.length),
              Text('QUESTION ${_i + 1} OF ${rounds.length} · SCORE $_score',
                  style: AppText.eyebrow),
              const SizedBox(height: 10),
              GlassCard(
                child: Text('Which Name of Allah means: “${r.meaning}”?',
                    style: AppText.body.copyWith(fontSize: 15.5, height: 1.5)),
              ),
              const SizedBox(height: 12),
              for (int o = 0; o < r.options.length; o++)
                Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _option(r, o)),
              if (_picked != null) ...<Widget>[
                if (r.arabic != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      r.arabic!,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: names99ArabicStyle(30),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _picked == r.answer
                        ? 'Correct! ${r.options[r.answer]} · ${names99RefLabel(r.ref)}'
                        : 'Not quite. It is ${r.options[r.answer]} · ${names99RefLabel(r.ref)}',
                    style: AppText.bodyMuted.copyWith(height: 1.5),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _next,
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward_ios,
                        size: 13, color: AppColors.gold),
                    label: Text(last ? 'Finish' : 'Next',
                        style: AppText.bodyMuted),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _done(int total) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: <Widget>[
          const ScreenHeader(title: 'Names quiz', close: true),
          if (_race != null)
            RaceBanner(
              link: _race!,
              myScore: _score,
              myTotal: total,
              iFinished: true,
            ),
          GlassCard(
            child: Column(
              children: <Widget>[
                Text('Score: $_score of $total', style: AppText.titleMedium),
                const SizedBox(height: 6),
                Text('Every Name is a door to knowing Allah. Come back to the '
                    'cards any time.',
                    textAlign: TextAlign.center,
                    style: AppText.bodyMuted.copyWith(height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Align(
            child: TextButton(
              onPressed: () => context.go(AppRoutes.games),
              child: const Text('Done',
                  style: TextStyle(color: AppColors.goldLight)),
            ),
          ),
        ],
      ),
    );
  }
}
