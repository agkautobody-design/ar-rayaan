/// Weather for Hādi, from MET Norway (api.met.no, CC BY 4.0).
///
/// Pure Dart apart from the injectable fetch. Hādi only reports numbers the
/// forecast gave and says plainly when it has no location or no connection.
/// For Jumu'ah or a prayer outdoors it gives a stay-in or go-out suggestion
/// from the numbers; it never gives a ruling.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

/// One hour of forecast.
class WeatherHour {
  const WeatherHour({
    required this.time,
    required this.tempC,
    required this.windMs,
    required this.rainMm,
    required this.symbol,
  });
  final DateTime time; // UTC
  final double tempC;
  final double windMs;
  final double rainMm;
  final String symbol;
}

enum WeatherWhen { now, today, tomorrow, friday }

abstract final class HadiWeather {
  static const String attribution = 'Weather data: MET Norway (CC BY 4.0).';

  static final RegExp _weather = RegExp(
      r'\b(?:weather|forecast|temperature|raining|rain|snowing|snow|humid|'
      r'sunny|windy|storm|hot outside|cold outside|umbrella)\b');
  static final RegExp _outdoor = RegExp(
      r'\b(?:jumu?ah|juma|jummah|friday prayer|eid|outside|outdoor|outdoors|'
      r'musalla|open air|stay indoors|stay in)\b');

  /// A weather question: the weather words, or an outdoor-prayer question
  /// that also asks about conditions.
  static bool detect(String q) {
    final String s = q.toLowerCase();
    if (!_weather.hasMatch(s)) return false;
    // "rain prayer" (salat al-istisqa) is a religious question, not weather.
    if (RegExp(r'\bistisqa\b|\bprayer for rain\b|\brain prayer\b|\bdua for rain\b')
        .hasMatch(s)) {
      return false;
    }
    if (RegExp(r'\b(?:dua|supplication|hadith|sunnah|verse|ayah|surah|quran)\b')
            .hasMatch(s) &&
        !RegExp(r'\b(?:weather|forecast|temperature)\b').hasMatch(s)) {
      return false;
    }
    return true;
  }

  static bool wantsOutdoorAdvice(String q) =>
      _outdoor.hasMatch(q.toLowerCase());

  static WeatherWhen whenOf(String q) {
    final String s = q.toLowerCase();
    if (RegExp(r'\bjumu?ah\b|\bjuma\b|\bjummah\b|\bfriday\b').hasMatch(s)) {
      return WeatherWhen.friday;
    }
    if (s.contains('tomorrow')) return WeatherWhen.tomorrow;
    if (RegExp(r'\btoday\b|\btonight\b').hasMatch(s)) return WeatherWhen.today;
    return WeatherWhen.now;
  }

  /// Parses MET's compact JSON into hourly entries (empty when malformed).
  static List<WeatherHour> parse(String body) {
    try {
      final dynamic j = jsonDecode(body);
      final List<dynamic> ts = j['properties']['timeseries'] as List<dynamic>;
      final List<WeatherHour> out = <WeatherHour>[];
      for (final dynamic e in ts) {
        final Map<String, dynamic> d = e['data']['instant']['details'];
        final dynamic n1 = e['data']['next_1_hours'];
        final dynamic n6 = e['data']['next_6_hours'];
        final dynamic n = n1 ?? n6;
        final double rain =
            (((n?['details']?['precipitation_amount']) ?? 0) as num).toDouble();
        out.add(WeatherHour(
          time: DateTime.parse(e['time'] as String).toUtc(),
          tempC: (d['air_temperature'] as num).toDouble(),
          windMs: ((d['wind_speed'] ?? 0) as num).toDouble(),
          rainMm: n1 != null ? rain : rain / 6,
          symbol: (n?['summary']?['symbol_code'] ?? '') as String,
        ));
      }
      return out;
    } catch (_) {
      return <WeatherHour>[];
    }
  }

  /// Fetches the forecast. Coordinates are cut to 4 decimals (MET's rule).
  /// Returns null on any failure.
  static Future<List<WeatherHour>?> fetch(double lat, double lon,
      {http.Client? client}) async {
    final http.Client c = client ?? http.Client();
    try {
      final Uri u = Uri.https('api.met.no',
          '/weatherapi/locationforecast/2.0/compact', <String, String>{
        'lat': lat.toStringAsFixed(4),
        'lon': lon.toStringAsFixed(4),
      });
      final http.Response r =
          await c.get(u).timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return null;
      final List<WeatherHour> h = parse(r.body);
      return h.isEmpty ? null : h;
    } catch (_) {
      return null;
    } finally {
      if (client == null) c.close();
    }
  }

  static String _describe(String symbol) {
    final String s = symbol.split('_').first;
    switch (s) {
      case 'clearsky':
        return 'clear';
      case 'fair':
        return 'mostly clear';
      case 'partlycloudy':
        return 'partly cloudy';
      case 'cloudy':
        return 'cloudy';
      case 'fog':
        return 'foggy';
      default:
        if (s.contains('thunder')) return 'stormy';
        if (s.contains('snow') || s.contains('sleet')) return 'snowy';
        if (s.contains('rain') || s.contains('shower')) return 'rainy';
        return 'changeable';
    }
  }

  /// The hour to report: for Friday, about 1 pm local solar time on the next
  /// Friday (longitude/15 hours from UTC); otherwise now, or tomorrow noon.
  static WeatherHour? pick(List<WeatherHour> h, WeatherWhen when, double lon,
      DateTime nowUtc) {
    if (h.isEmpty) return null;
    if (when == WeatherWhen.now || when == WeatherWhen.today) return h.first;
    final Duration off = Duration(minutes: (lon / 15 * 60).round());
    final DateTime localNow = nowUtc.add(off);
    final DateTime target;
    if (when == WeatherWhen.tomorrow) {
      target =
          DateTime.utc(localNow.year, localNow.month, localNow.day + 1, 12)
              .subtract(off);
    } else {
      int add = (DateTime.friday - localNow.weekday) % 7;
      if (add == 0 && localNow.hour >= 14) add = 7;
      target = DateTime.utc(localNow.year, localNow.month, localNow.day + add, 13)
          .subtract(off);
    }
    WeatherHour best = h.first;
    for (final WeatherHour e in h) {
      if (e.time.difference(target).abs() < best.time.difference(target).abs()) {
        best = e;
      }
    }
    // Out of range of the forecast (about 9 days): no answer.
    if (best.time.difference(target).abs() > const Duration(hours: 4)) {
      return null;
    }
    return best;
  }

  /// A short suggestion from the numbers, only when asked about praying or
  /// gathering outdoors.
  static String outdoorAdvice(WeatherHour w) {
    final bool wet = w.rainMm >= 0.3 || _describe(w.symbol) == 'rainy' ||
        _describe(w.symbol) == 'snowy' || _describe(w.symbol) == 'stormy';
    if (wet || w.windMs >= 11) {
      return 'For a prayer outside, that looks like a day to stay indoors if '
          'there is a covered place. Rain is a recognised reason in the Sunnah to '
          'pray where you are, and I am not giving a ruling, only the '
          'weather.';
    }
    if (w.tempC <= -5 || w.tempC >= 38) {
      return 'It is an extreme temperature, so if you pray outside, keep it '
          'short, bring water or warm layers, and look after children and '
          'the elderly.';
    }
    return 'That looks fine for praying outside. Bring a mat, and check again '
        'nearer the time because forecasts shift.';
  }

  static String reply(String q, List<WeatherHour> hours, double lon,
      {DateTime? now}) {
    final WeatherWhen when = whenOf(q);
    final DateTime n = (now ?? DateTime.now()).toUtc();
    final WeatherHour? w = pick(hours, when, lon, n);
    if (w == null) {
      return 'I only have about nine days of forecast, and nothing for that '
          'day yet. Ask me again closer to it.';
    }
    final String label = switch (when) {
      WeatherWhen.now => 'Right now',
      WeatherWhen.today => 'Right now',
      WeatherWhen.tomorrow => 'Tomorrow around midday',
      WeatherWhen.friday => 'Around Jumu’ah time on Friday',
    };
    final String rain = w.rainMm >= 0.3
        ? 'about ${w.rainMm.toStringAsFixed(1)} mm of rain in that hour'
        : 'no rain expected';
    final StringBuffer b = StringBuffer(
        '$label where you set your location it is ${_describe(w.symbol)}, '
        '${w.tempC.round()}°C, wind ${w.windMs.toStringAsFixed(0)} m/s, '
        '$rain.');
    if (wantsOutdoorAdvice(q)) {
      b.write('\n\n${outdoorAdvice(w)}');
      if (RegExp(r'\beid\b').hasMatch(q.toLowerCase()) &&
          when != WeatherWhen.tomorrow) {
        b.write(' I do not know the Eid date from here: say "tomorrow" if Eid '
            'is tomorrow and I will check that day.');
      }
    }
    b.write('\n\n$attribution');
    return b.toString();
  }

  static const String noLocation =
      'I can tell you the weather once I know where you are. Set your '
      'location on the Prayer Times screen (it stays on your device), then '
      'ask me again.\n[GO:/prayer]';

  static const String noConnection =
      'I could not reach the weather service just now, so I will not guess. '
      'Try again in a moment, or check your phone’s weather app.';
}
