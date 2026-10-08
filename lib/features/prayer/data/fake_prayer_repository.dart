import '../application/prayer_repository.dart';
import '../domain/prayer_times.dart';

/// Deterministic schedule for tests and offline development.
class FakePrayerRepository implements PrayerRepository {
  @override
  Future<PrayerTimes> timingsForToday(PrayerLocation location) async {
    final DateTime now = DateTime.now();
    DateTime at(int h, int m) => DateTime(now.year, now.month, now.day, h, m);
    return PrayerTimes(
      fajr: at(5, 12),
      sunrise: at(6, 41),
      dhuhr: at(12, 47),
      asr: at(16, 5),
      maghrib: at(19, 28),
      isha: at(21, 2),
      locationLabel: location.label,
      methodLabel: 'Muslim World League',
    );
  }
}
