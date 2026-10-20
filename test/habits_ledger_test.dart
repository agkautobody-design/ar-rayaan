import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/habits/application/habits_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> make(Map<String, Object> initial) async {
  SharedPreferences.setMockInitialValues(initial);
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final ProviderContainer c = ProviderContainer(
    overrides: <Override>[sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Qada ledger', () {
    test('adjusts, never goes below zero, and survives a restart', () async {
      final ProviderContainer c = await make(<String, Object>{});
      final QadaController q = c.read(qadaProvider.notifier);
      await q.adjust('Fajr', 3);
      await q.adjust('Isha', 1);
      await q.adjust('Isha', -5);
      await q.adjust('Sunrise', 4); // not a prayer: ignored
      expect(c.read(qadaProvider)['Fajr'], 3);
      expect(c.read(qadaProvider)['Isha'], 0);
      expect(q.total, 3);

      final SharedPreferences prefs = c.read(sharedPreferencesProvider);
      final ProviderContainer again = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(again.dispose);
      expect(again.read(qadaProvider)['Fajr'], 3);
    });
  });

  group('Fasting log', () {
    test('stamps are zero-padded and legacy keys are normalised', () {
      expect(FastingLogController.stamp(DateTime(2026, 10, 4)), '2026-10-04');
      expect(FastingLogController.normalize('2026-10-4'), '2026-10-04');
      expect(FastingLogController.normalize('2026-1-9'), '2026-01-09');
      expect(FastingLogController.normalize('garbage'), isNull);
      expect(FastingLogController.normalize('a-b-c'), isNull);
    });

    test('legacy unpadded entries are read as the same day', () async {
      final ProviderContainer c = await make(<String, Object>{
        'ar.habits.fasting': <String>['2026-10-4', 'junk'],
      });
      expect(c.read(fastingLogProvider), <String>{'2026-10-04'});
      expect(
        c.read(fastingLogProvider.notifier).fastedOn(DateTime(2026, 10, 4)),
        isTrue,
      );
    });

    test('any day can be marked, unmarked and is remembered', () async {
      final ProviderContainer c = await make(<String, Object>{});
      final FastingLogController f = c.read(fastingLogProvider.notifier);
      final DateTime n = DateTime.now();
      final DateTime yesterday = DateTime(n.year, n.month, n.day - 1);
      await f.toggleDate(yesterday);
      expect(f.fastedYesterday(), isTrue);
      expect(f.fastedToday(), isFalse);
      await f.toggleToday();
      expect(f.fastedToday(), isTrue);
      await f.toggleDate(yesterday);
      expect(f.fastedYesterday(), isFalse);

      final SharedPreferences prefs = c.read(sharedPreferencesProvider);
      expect(
        prefs.getStringList('ar.habits.fasting'),
        <String>[FastingLogController.stamp(n)],
      );
    });
  });

  group('Dhikr ledger', () {
    test('records per day, ignores non-positive counts, persists', () async {
      final ProviderContainer c = await make(<String, Object>{});
      final DhikrLedgerController d = c.read(dhikrLedgerProvider.notifier);
      await d.record(33);
      await d.record(33);
      await d.record(0);
      await d.record(-4);
      expect(d.today, 66);

      final DateTime n = DateTime.now();
      await d.record(10, day: DateTime(n.year, n.month, n.day - 3));
      expect(d.lastSevenDays, 76);
      await d.record(5, day: DateTime(n.year, n.month, n.day - 30));
      expect(d.lastSevenDays, 76);

      final SharedPreferences prefs = c.read(sharedPreferencesProvider);
      final ProviderContainer again = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(again.dispose);
      expect(again.read(dhikrLedgerProvider.notifier).today, 66);
    });
  });
}
