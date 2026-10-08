import 'dart:convert';

import 'package:http/http.dart' as http;

import '../application/prayer_repository.dart';
import '../domain/prayer_times.dart';

/// Live prayer times from the Aladhan API (approved default source, O-5).
///
/// Method 3 = Muslim World League; school 0 = Shafi'i (Asr). Both become
/// user settings in the settings module.
class AladhanPrayerRepository implements PrayerRepository {
  AladhanPrayerRepository({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static const String _base = 'https://api.aladhan.com/v1/timingsByCity';
  static const int _method = 3; // Muslim World League
  static const int _school = 0; // Shafi'i

  @override
  Future<PrayerTimes> timingsForToday(PrayerLocation location) async {
    final Uri uri = Uri.parse(
      '$_base?city=${Uri.encodeComponent(location.city)}'
      '&country=${Uri.encodeComponent(location.country)}'
      '&method=$_method&school=$_school',
    );
    final http.Response response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw PrayerTimesException('Prayer times unavailable right now.');
    }
    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
    if (body['code'] != 200) {
      throw PrayerTimesException('Prayer times unavailable for this city.');
    }
    final Map<String, dynamic> timings =
        (body['data'] as Map<String, dynamic>)['timings']
            as Map<String, dynamic>;
    final DateTime now = DateTime.now();

    DateTime at(String key) {
      // API returns "05:12" or "05:12 (EDT)" — keep the HH:mm part.
      final String raw = (timings[key] as String).split(' ').first;
      final List<String> parts = raw.split(':');
      return DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    }

    return PrayerTimes(
      fajr: at('Fajr'),
      sunrise: at('Sunrise'),
      dhuhr: at('Dhuhr'),
      asr: at('Asr'),
      maghrib: at('Maghrib'),
      isha: at('Isha'),
      locationLabel: location.label,
      methodLabel: 'Muslim World League',
    );
  }
}

class PrayerTimesException implements Exception {
  const PrayerTimesException(this.message);
  final String message;
}
