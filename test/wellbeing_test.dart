import 'package:ar_rayaan/features/elder/application/elder_mode.dart';
import 'package:ar_rayaan/features/sakina/application/wellbeing_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<SharedPreferences> prefs([Map<String, Object>? init]) async {
    SharedPreferences.setMockInitialValues(init ?? <String, Object>{});
    return SharedPreferences.getInstance();
  }

  group('mood check-in', () {
    test('one entry per day; the second tap replaces the first', () async {
      final MoodStore s = MoodStore(await prefs());
      final DateTime d = DateTime(2026, 10, 20, 9);
      await s.record(Mood.heavy, now: d);
      await s.record(Mood.good, now: d.add(const Duration(hours: 5)));
      expect(s.all.length, 1);
      expect(s.all.single.mood, Mood.good);
      expect(s.all.single.day, '2026-10-20');
    });

    test('7 and 30 day windows', () async {
      final MoodStore s = MoodStore(await prefs());
      final DateTime today = DateTime(2026, 10, 20);
      for (int i = 0; i < 40; i++) {
        await s.record(Mood.okay, now: today.subtract(Duration(days: i)));
      }
      expect(s.lastDays(7, now: today).length, 7);
      expect(s.lastDays(30, now: today).length, 30);
    });

    test('export and delete', () async {
      final MoodStore s = MoodStore(await prefs());
      await s.record(Mood.low, now: DateTime(2026, 1, 2));
      expect(s.exportText(), contains('2026-01-02, Low'));
      await s.clear();
      expect(s.all, isEmpty);
    });

    test('there is no score, streak or diagnosis in the data', () async {
      final SharedPreferences p = await prefs();
      final MoodStore s = MoodStore(p);
      await s.record(Mood.heavy);
      final String raw = p.getString(MoodStore.key)!;
      expect(raw.toLowerCase().contains('streak'), isFalse);
      expect(raw.toLowerCase().contains('score'), isFalse);
    });

    test('bad stored data does not crash', () async {
      final MoodStore s =
          MoodStore(await prefs(<String, Object>{MoodStore.key: 'not json'}));
      expect(s.all, isEmpty);
    });
  });

  group('safety plan', () {
    test('saves, loads, exports and deletes', () async {
      final SafetyPlanStore s = SafetyPlanStore(await prefs());
      expect(s.load().isEmpty, isTrue);
      await s.save(const SafetyPlan(
        warningSigns: 'not sleeping',
        peopleToAsk: 'Aunt Amina 555-0100',
        reasons: 'my kids',
      ));
      final SafetyPlan p = s.load();
      expect(p.warningSigns, 'not sleeping');
      expect(p.isEmpty, isFalse);
      expect(p.exportText(), contains('Aunt Amina'));
      expect(p.exportText(), contains('What I am living for'));
      await s.clear();
      expect(s.load().isEmpty, isTrue);
    });
  });

  group('elder launch', () {
    test('Elder mode on opens the Elder home; off keeps the fallback',
        () async {
      final SharedPreferences on =
          await prefs(<String, Object>{ElderMode.pref: true});
      expect(ElderMode.launchLocation(on, fallback: '/splash'),
          ElderMode.homeRoute);
      final SharedPreferences off = await prefs();
      expect(ElderMode.launchLocation(off, fallback: '/splash'), '/splash');
    });
  });
}
