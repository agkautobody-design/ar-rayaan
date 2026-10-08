import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../application/prayer_repository.dart';
import '../domain/prayer_times.dart';

/// Offline-resilient wrapper: caches each successful day's schedule and
/// falls back to it when the network is unavailable. Prayer times must
/// work offline — users depend on them.
class CachedPrayerRepository implements PrayerRepository {
  CachedPrayerRepository(this._inner, this._prefs);

  final PrayerRepository _inner;
  final SharedPreferences? _prefs;

  static String _key(PrayerLocation l) {
    final DateTime d = DateTime.now();
    return 'ar.prayer.${l.city}.${l.country}.${d.year}-${d.month}-${d.day}';
  }

  @override
  Future<PrayerTimes> timingsForToday(PrayerLocation location) async {
    try {
      final PrayerTimes t = await _inner.timingsForToday(location);
      await _prefs?.setString(
        _key(location),
        jsonEncode(<String, dynamic>{
          'fajr': t.fajr.toIso8601String(),
          'sunrise': t.sunrise.toIso8601String(),
          'dhuhr': t.dhuhr.toIso8601String(),
          'asr': t.asr.toIso8601String(),
          'maghrib': t.maghrib.toIso8601String(),
          'isha': t.isha.toIso8601String(),
          'methodLabel': t.methodLabel,
        }),
      );
      return t;
    } catch (_) {
      final String? raw = _prefs?.getString(_key(location));
      if (raw == null) rethrow;
      final Map<String, dynamic> j = jsonDecode(raw) as Map<String, dynamic>;
      return PrayerTimes(
        fajr: DateTime.parse(j['fajr'] as String),
        sunrise: DateTime.parse(j['sunrise'] as String),
        dhuhr: DateTime.parse(j['dhuhr'] as String),
        asr: DateTime.parse(j['asr'] as String),
        maghrib: DateTime.parse(j['maghrib'] as String),
        isha: DateTime.parse(j['isha'] as String),
        locationLabel: location.label,
        methodLabel: j['methodLabel'] as String,
      );
    }
  }
}
