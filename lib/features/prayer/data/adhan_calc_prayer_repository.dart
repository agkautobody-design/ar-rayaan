import 'package:adhan/adhan.dart' as adhan;

import '../application/prayer_repository.dart';
import '../application/prayer_settings.dart';
import '../domain/prayer_times.dart';

/// Offline astronomical prayer-time calculation — the batoulapps `adhan`
/// port (the same math that powers the Aladhan API) running on-device.
///
/// Benefits over the HTTP API: works fully offline, no rate limits, no
/// location leaves the device. Method and Asr school come from the user's
/// [PrayerSettings] (automatic regional default until they choose).
class AdhanCalcPrayerRepository implements PrayerRepository {
  AdhanCalcPrayerRepository({this.settings = const PrayerSettings()});

  final PrayerSettings settings;

  @override
  Future<PrayerTimes> timingsForToday(PrayerLocation location) async {
    final adhan.Coordinates coords = adhan.Coordinates(
      location.latitude,
      location.longitude,
    );
    final adhan.CalculationParameters params = settings.parameters(location);
    final adhan.PrayerTimes times = adhan.PrayerTimes.today(coords, params);
    return PrayerTimes(
      fajr: times.fajr,
      sunrise: times.sunrise,
      dhuhr: times.dhuhr,
      asr: times.asr,
      maghrib: times.maghrib,
      isha: times.isha,
      locationLabel: location.label,
      methodLabel: '${settings.label(location)} · calculated on-device',
    );
  }
}
