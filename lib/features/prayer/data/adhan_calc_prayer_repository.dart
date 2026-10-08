import 'package:adhan/adhan.dart' as adhan;

import '../application/prayer_repository.dart';
import '../domain/prayer_times.dart';

/// Offline astronomical prayer-time calculation — the batoulapps `adhan`
/// port (the same math that powers the Aladhan API) running on-device.
///
/// Benefits over the HTTP API: works fully offline, no rate limits, no
/// location leaves the device. Method: Muslim World League (O-5 default);
/// Asr follows the Standard (Shafi'i) shadow factor.
class AdhanCalcPrayerRepository implements PrayerRepository {
  @override
  Future<PrayerTimes> timingsForToday(PrayerLocation location) async {
    final adhan.Coordinates coords = adhan.Coordinates(
      location.latitude,
      location.longitude,
    );
    final adhan.CalculationParameters params =
        adhan.CalculationMethod.muslim_world_league.getParameters();
    params.madhab = adhan.Madhab.shafi;
    final adhan.PrayerTimes times = adhan.PrayerTimes.today(coords, params);
    return PrayerTimes(
      fajr: times.fajr,
      sunrise: times.sunrise,
      dhuhr: times.dhuhr,
      asr: times.asr,
      maghrib: times.maghrib,
      isha: times.isha,
      locationLabel: location.label,
      methodLabel: 'Muslim World League · calculated on-device',
    );
  }
}
