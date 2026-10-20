import 'prayer_zone.dart';

/// Daily prayer schedule value object.
///
/// Times are WALL-CLOCK readings in the schedule's own [zone] (the chosen
/// city's zone, or the device zone for a GPS fix) stored as plain
/// [DateTime]s, so `DateFormat` prints the city's clock directly. Sunrise
/// (Shurūq) marks the end of Fajr. Compare against a real instant (for
/// example `DateTime.now()`) only through [wallClock] / [nextPrayer], which
/// convert into the same zone first.
class PrayerTimes {
  const PrayerTimes({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.locationLabel,
    required this.methodLabel,
    this.zone,
  });

  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  /// e.g. "Toronto, Canada"
  final String locationLabel;

  /// e.g. "Muslim World League"
  final String methodLabel;

  /// Zone the wall-clock times are in; null = device zone.
  final PrayerZone? zone;

  /// The six rows in display order.
  List<(String, DateTime)> get ordered => <(String, DateTime)>[
    ('Fajr', fajr),
    ('Sunrise', sunrise),
    ('Dhuhr', dhuhr),
    ('Asr', asr),
    ('Maghrib', maghrib),
    ('Isha', isha),
  ];

  /// The five obligatory prayers (Sunrise is a boundary, not a prayer).
  List<(String, DateTime)> get prayers => <(String, DateTime)>[
    ('Fajr', fajr),
    ('Dhuhr', dhuhr),
    ('Asr', asr),
    ('Maghrib', maghrib),
    ('Isha', isha),
  ];

  /// [instant] (e.g. `DateTime.now()`) as a wall-clock reading in [zone].
  DateTime wallClock(DateTime instant) => PrayerZone.wallClock(zone, instant);

  /// The next upcoming prayer. After Isha, wraps to tomorrow's Fajr.
  /// Sunrise is not a prayer and is never returned.
  (String, DateTime) nextPrayer(DateTime now) {
    final DateTime w = wallClock(now);
    for (final (String, DateTime) entry in prayers) {
      if (entry.$2.isAfter(w)) return entry;
    }
    return (
      'Fajr',
      DateTime(
        fajr.year,
        fajr.month,
        fajr.day + 1,
        fajr.hour,
        fajr.minute,
        fajr.second,
      ),
    );
  }

  /// Start of the last third of the night — the time of tahajjud, when
  /// Allah descends and asks who is calling upon Him (Bukhari 1145).
  ///
  /// The night runs Maghrib → tomorrow's Fajr (approximated as today's
  /// Fajr + 24h; a one-day Fajr drift of a minute or two is honest for a
  /// devotional reminder and labeled approximate on screen).
  DateTime get lastThirdStart {
    final DateTime nextFajr = fajr.add(const Duration(days: 1));
    final Duration night = nextFajr.difference(maghrib);
    return maghrib.add(Duration(minutes: (night.inMinutes * 2) ~/ 3));
  }

  /// The last third of the night that is relevant at [now]: after midnight
  /// but before Fajr the night in progress began at yesterday's Maghrib
  /// (approximated by today's Maghrib − 24h), so the answer is that night's
  /// last third rather than the next one.
  DateTime lastThirdStartFor(DateTime now) {
    final DateTime w = wallClock(now);
    if (w.isBefore(fajr)) {
      final DateTime prevMaghrib = maghrib.subtract(const Duration(days: 1));
      final Duration night = fajr.difference(prevMaghrib);
      return prevMaghrib.add(Duration(minutes: (night.inMinutes * 2) ~/ 3));
    }
    return lastThirdStart;
  }
}
