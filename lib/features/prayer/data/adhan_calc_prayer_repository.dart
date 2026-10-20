import 'package:adhan/adhan.dart' as adhan;

import '../application/prayer_repository.dart';
import '../application/prayer_settings.dart';
import '../domain/prayer_times.dart';
import '../domain/prayer_zone.dart';

/// Offline astronomical prayer-time calculation — the batoulapps `adhan`
/// port (the same math that powers the Aladhan API) running on-device.
///
/// Benefits over the HTTP API: works fully offline, no rate limits, no
/// location leaves the device. Method and Asr school come from the user's
/// [PrayerSettings] (automatic regional default until they choose).
///
/// Time zones: `adhan` converts its results to the DEVICE zone, which is
/// wrong for a manually chosen city elsewhere. So the calendar day is taken
/// in the location's own zone ([PrayerLocation.zone]; the device zone for a
/// GPS fix), and the calculated instants are converted back into that same
/// zone's wall clock before they leave this class.
class AdhanCalcPrayerRepository implements PrayerRepository {
  AdhanCalcPrayerRepository({
    this.settings = const PrayerSettings(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final PrayerSettings settings;
  final DateTime Function() _clock;

  @override
  Future<PrayerTimes> timingsForToday(PrayerLocation location) async {
    return timingsAt(location, _clock());
  }

  /// The schedule for the civil day containing [instant] in the
  /// location's zone.
  PrayerTimes timingsAt(PrayerLocation location, DateTime instant) {
    final DateTime day = PrayerZone.wallClock(location.zone, instant);
    final adhan.Coordinates coords = adhan.Coordinates(
      location.latitude,
      location.longitude,
    );
    final adhan.CalculationParameters params = settings.parameters(
      location,
      date: day,
    );
    final adhan.PrayerTimes times = adhan.PrayerTimes(
      coords,
      adhan.DateComponents(day.year, day.month, day.day),
      params,
    );
    DateTime wall(DateTime t) => PrayerZone.wallClock(location.zone, t);
    return PrayerTimes(
      fajr: wall(times.fajr),
      sunrise: wall(times.sunrise),
      dhuhr: wall(times.dhuhr),
      asr: wall(times.asr),
      maghrib: wall(times.maghrib),
      isha: wall(times.isha),
      locationLabel: location.label,
      methodLabel:
          '${settings.label(location, date: day)} · calculated on-device',
      zone: location.zone,
    );
  }
}
