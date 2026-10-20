/// Time-zone handling for a manually chosen city.
///
/// The `adhan` package returns instants converted to the DEVICE time zone
/// (`toLocal()`), so a city picked in another zone would be shown on the
/// wrong clock and for the wrong calendar day. The app has no timezone
/// database (and may not add a dependency), so each curated city carries
/// its standard UTC offset plus one of a handful of daylight-saving rules.
/// GPS locations carry no zone: the device is where the user is, so the
/// device zone is correct.
library;

/// Daylight-saving rule families used by the curated cities.
enum DstRule {
  /// No daylight saving.
  none,

  /// United States / Canada: second Sunday of March 02:00 to first Sunday of
  /// November 02:00 (local time).
  us,

  /// European Union / UK: last Sunday of March to last Sunday of October,
  /// both at 01:00 UTC.
  eu,

  /// Australia (south-east): first Sunday of October 02:00 (standard) to
  /// first Sunday of April 03:00 (daylight).
  au,

  /// Egypt (reinstated 2023): last Friday of April 00:00 to last Thursday of
  /// October 24:00 (local time).
  egypt,
}

/// A standard UTC offset plus a daylight-saving rule.
class PrayerZone {
  const PrayerZone(this.standardMinutes, [this.dst = DstRule.none]);

  /// Standard (non-DST) offset from UTC, in minutes.
  final int standardMinutes;
  final DstRule dst;

  /// Compact id for persistence, e.g. `us|-300`.
  String get id => '${dst.name}|$standardMinutes';

  /// Inverse of [id]; null when [raw] is missing or malformed.
  static PrayerZone? parse(String? raw) {
    if (raw == null) return null;
    final List<String> parts = raw.split('|');
    if (parts.length != 2) return null;
    final int? minutes = int.tryParse(parts[1]);
    if (minutes == null) return null;
    for (final DstRule r in DstRule.values) {
      if (r.name == parts[0]) return PrayerZone(minutes, r);
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is PrayerZone &&
      other.standardMinutes == standardMinutes &&
      other.dst == dst;

  @override
  int get hashCode => Object.hash(standardMinutes, dst);

  @override
  String toString() => 'PrayerZone($id)';

  Duration get _std => Duration(minutes: standardMinutes);

  /// UTC offset in effect at the UTC instant [utc].
  Duration offsetAtUtc(DateTime utc) {
    final DateTime u = utc.toUtc();
    return _isDstAtUtc(u) ? _std + const Duration(hours: 1) : _std;
  }

  /// UTC offset on the civil date [year]-[month]-[day], taken at local noon
  /// (daylight-saving switches happen in the small hours).
  Duration offsetOnDate(int year, int month, int day) {
    final DateTime noonUtc = DateTime.utc(year, month, day, 12).subtract(_std);
    return offsetAtUtc(noonUtc);
  }

  bool _isDstAtUtc(DateTime u) {
    switch (dst) {
      case DstRule.none:
        return false;
      case DstRule.us:
        final DateTime start = DateTime.utc(
          u.year,
          3,
          _nthWeekday(u.year, 3, DateTime.sunday, 2),
          2,
        ).subtract(_std);
        // 02:00 daylight time = 01:00 standard time.
        final DateTime end = DateTime.utc(
          u.year,
          11,
          _nthWeekday(u.year, 11, DateTime.sunday, 1),
          1,
        ).subtract(_std);
        return !u.isBefore(start) && u.isBefore(end);
      case DstRule.eu:
        final DateTime start = DateTime.utc(
          u.year,
          3,
          _lastWeekday(u.year, 3, DateTime.sunday),
          1,
        );
        final DateTime end = DateTime.utc(
          u.year,
          10,
          _lastWeekday(u.year, 10, DateTime.sunday),
          1,
        );
        return !u.isBefore(start) && u.isBefore(end);
      case DstRule.au:
        // Southern hemisphere: DST spans the new year.
        final DateTime end = DateTime.utc(
          u.year,
          4,
          _nthWeekday(u.year, 4, DateTime.sunday, 1),
          2,
        ).subtract(_std);
        final DateTime start = DateTime.utc(
          u.year,
          10,
          _nthWeekday(u.year, 10, DateTime.sunday, 1),
          2,
        ).subtract(_std);
        return u.isBefore(end) || !u.isBefore(start);
      case DstRule.egypt:
        final DateTime start = DateTime.utc(
          u.year,
          4,
          _lastWeekday(u.year, 4, DateTime.friday),
        ).subtract(_std);
        // 24:00 daylight time = 23:00 standard time.
        final DateTime end = DateTime.utc(
          u.year,
          10,
          _lastWeekday(u.year, 10, DateTime.thursday),
          23,
        ).subtract(_std);
        return !u.isBefore(start) && u.isBefore(end);
    }
  }

  /// Day of month of the [n]th [weekday] (1-based) in [month].
  static int _nthWeekday(int year, int month, int weekday, int n) {
    final int first = DateTime.utc(year, month, 1).weekday;
    final int offset = (weekday - first + 7) % 7;
    return 1 + offset + 7 * (n - 1);
  }

  /// Day of month of the last [weekday] in [month].
  static int _lastWeekday(int year, int month, int weekday) {
    final DateTime last = DateTime.utc(year, month + 1, 0);
    final int back = (last.weekday - weekday + 7) % 7;
    return last.day - back;
  }

  /// The wall-clock reading (as a plain local-flagged [DateTime], so
  /// `DateFormat` prints it as-is) of the instant [instant] in [zone]; the
  /// device zone when [zone] is null.
  static DateTime wallClock(PrayerZone? zone, DateTime instant) {
    if (zone == null) return instant.toLocal();
    final DateTime u = instant.toUtc();
    final DateTime w = u.add(zone.offsetAtUtc(u));
    return DateTime(w.year, w.month, w.day, w.hour, w.minute, w.second);
  }

  /// The real instant (UTC) of the wall-clock reading [wall] in [zone]; the
  /// device zone when [zone] is null.
  static DateTime instantOf(PrayerZone? zone, DateTime wall) {
    if (zone == null) {
      return DateTime(
        wall.year,
        wall.month,
        wall.day,
        wall.hour,
        wall.minute,
        wall.second,
      ).toUtc();
    }
    final DateTime asUtc = DateTime.utc(
      wall.year,
      wall.month,
      wall.day,
      wall.hour,
      wall.minute,
      wall.second,
    );
    return asUtc.subtract(zone.offsetOnDate(wall.year, wall.month, wall.day));
  }
}
