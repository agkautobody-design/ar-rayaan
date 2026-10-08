import 'package:ar_rayaan/features/prayer/domain/prayer_times.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tahajjud (last third of the night)', () {
    PrayerTimes sample() => PrayerTimes(
          fajr: DateTime(2026, 10, 4, 6, 0),
          sunrise: DateTime(2026, 10, 4, 7, 20),
          dhuhr: DateTime(2026, 10, 4, 13, 0),
          asr: DateTime(2026, 10, 4, 16, 30),
          maghrib: DateTime(2026, 10, 4, 18, 45),
          isha: DateTime(2026, 10, 4, 20, 15),
          locationLabel: 'Toronto, Canada',
          methodLabel: 'Muslim World League',
        );

    test('last third starts between Maghrib and next Fajr', () {
      final PrayerTimes t = sample();
      final DateTime start = t.lastThirdStart;
      expect(start.isAfter(t.maghrib), isTrue);
      expect(start.isBefore(t.fajr.add(const Duration(days: 1))), isTrue);
    });

    test('last third is the final third of the night, not earlier', () {
      final PrayerTimes t = sample();
      final Duration night =
          t.fajr.add(const Duration(days: 1)).difference(t.maghrib);
      final Duration intoNight = t.lastThirdStart.difference(t.maghrib);
      // Two-thirds of the night, ±1 minute rounding.
      expect(
        (intoNight.inMinutes - night.inMinutes * 2 / 3).abs(),
        lessThan(2),
      );
    });

    test('the remaining night after last-third start is one third', () {
      final PrayerTimes t = sample();
      final Duration night =
          t.fajr.add(const Duration(days: 1)).difference(t.maghrib);
      final Duration remaining =
          t.fajr.add(const Duration(days: 1)).difference(t.lastThirdStart);
      expect(
        (remaining.inMinutes - night.inMinutes / 3).abs(),
        lessThan(2),
      );
    });
  });
}
