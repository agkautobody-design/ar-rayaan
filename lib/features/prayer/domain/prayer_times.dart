/// Daily prayer schedule value object.
///
/// Source: Aladhan API (approved O-5 default). Times are local civil times
/// for the configured location; Sunrise (Shurūq) marks the end of Fajr.
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

  /// The six rows in display order.
  List<(String, DateTime)> get ordered => <(String, DateTime)>[
    ('Fajr', fajr),
    ('Sunrise', sunrise),
    ('Dhuhr', dhuhr),
    ('Asr', asr),
    ('Maghrib', maghrib),
    ('Isha', isha),
  ];

  /// The next upcoming moment. After Isha, wraps to tomorrow's Fajr.
  (String, DateTime) nextPrayer(DateTime now) {
    for (final (String, DateTime) entry in ordered) {
      if (entry.$2.isAfter(now)) return entry;
    }
    return ('Fajr', fajr.add(const Duration(days: 1)));
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
}
