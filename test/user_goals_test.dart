import 'package:ar_rayaan/features/hadi/data/user_knows.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _now = DateTime(2026, 11, 28);

void main() {
  group('goals the person says out loud', () {
    test('an explicit goal is kept, in plain words', () {
      expect(UserKnowsRules.goalOf('My goal is to finish Juz Amma by Ramadan.'),
          'finish Juz Amma by Ramadan');
      expect(UserKnowsRules.goalOf('I want to wake up for Fajr every day'),
          'wake up for Fajr every day');
      final UserKnows k = UserKnowsRules.learn(
          UserKnows.empty, 'My goal is to read the Qur\'an daily', _now);
      expect(k.goals.single.text, 'read the Qur\'an daily');
      expect(UserKnowsRules.describe(k), contains('Your goal: read the Qur\'an daily'));
    });

    test('a casual question is not a goal', () {
      expect(UserKnowsRules.goalOf('how do I pray witr'), isNull);
      expect(UserKnowsRules.goalOf('what is zakat'), isNull);
    });

    test('nothing sensitive is kept as a goal', () {
      expect(UserKnowsRules.goalOf('I want to kill myself'), isNull);
      expect(UserKnowsRules.goalOf('my goal is to stop drinking'), isNull);
      expect(UserKnowsRules.goalOf('I want to get over my depression'), isNull);
    });

    test('at most five, newest first, no duplicates, deletable', () {
      UserKnows k = UserKnows.empty;
      for (final String g in <String>[
        'learn arabic basics', 'memorise surah mulk', 'read more hadith',
        'pray on time daily', 'give sadaqah weekly', 'visit my parents more',
      ]) {
        k = UserKnowsRules.learn(k, 'my goal is to $g', _now);
      }
      expect(k.goals.length, UserKnowsRules.maxGoals);
      expect(k.goals.first.text, 'visit my parents more');
      k = UserKnowsRules.learn(k, 'My goal is to Visit my parents more', _now);
      expect(k.goals.length, UserKnowsRules.maxGoals);
      final UserKnows gone = k.withoutGoal(k.goals.first.text);
      expect(gone.goals.length, UserKnowsRules.maxGoals - 1);
    });

    test('survives storage and merge, and is forgotten after a year', () {
      final UserKnows k = UserKnowsRules.learn(
          UserKnows.empty, 'my goal is to learn arabic basics', _now);
      final UserKnows back = UserKnows.decode(k.encode());
      expect(back.goals.single.text, 'learn arabic basics');
      final UserKnows merged = UserKnowsRules.merge(
          back,
          UserKnowsRules.learn(UserKnows.empty, 'my goal is to pray on time', _now),
          _now);
      expect(merged.goals.length, 2);
      final UserKnows later = UserKnowsRules.tidy(merged, DateTime(2027, 12, 30));
      expect(later.goals, isEmpty);
    });
  });
}
