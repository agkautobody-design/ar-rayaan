import 'package:flutter_test/flutter_test.dart';

import 'package:ar_rayaan/features/games/data/race_protocol.dart';
import 'package:ar_rayaan/features/games/presentation/race_banner.dart';

RaceState _s(RaceOpponent o, {bool left = false}) =>
    RaceState(opponent: o, joined: true, left: left);

void main() {
  test('progress while racing', () {
    expect(
      RaceBanner.line(
        _s(const RaceOpponent(answered: 3, total: 10, score: 2)),
        myScore: 1,
        iFinished: false,
      ),
      'Friend: 3 of 10 answered, 2 right.',
    );
  });

  test('before the friend answers, and when they leave', () {
    expect(RaceBanner.line(_s(const RaceOpponent()), myScore: 0, iFinished: false),
        contains('first question'));
    expect(
        RaceBanner.line(_s(const RaceOpponent(), left: true),
            myScore: 0, iFinished: false),
        contains('left'));
  });

  test('verdicts: higher score wins, equal scores go to the first finisher', () {
    String v(int mine, int theirs, int myMs, int theirMs) => RaceBanner.line(
          _s(RaceOpponent(
              answered: 10,
              total: 10,
              score: theirs,
              finished: true,
              finishedMs: theirMs)),
          myScore: mine,
          iFinished: true,
          myFinishedMs: myMs,
        );
    expect(v(8, 6, 0, 0), startsWith('You won'));
    expect(v(5, 7, 0, 0), startsWith('Your friend won'));
    expect(v(7, 7, 0, 0), startsWith('A draw'));
    expect(v(7, 7, 10000, 20000), 'You won, finishing first: you 7, friend 7.');
    expect(v(7, 7, 20000, 10000), startsWith('Your friend won, finishing first'));
    expect(v(7, 7, 10000, 11000), startsWith('A draw'));
  });

  test('waiting lines', () {
    expect(
        RaceBanner.line(
            _s(const RaceOpponent(answered: 4, total: 10, score: 3)),
            myScore: 9,
            iFinished: true),
        contains('Waiting'));
    expect(
        RaceBanner.line(
            _s(const RaceOpponent(
                answered: 10, total: 10, score: 3, finished: true)),
            myScore: 9,
            iFinished: false),
        contains('finished with 3 of 10'));
  });
}
