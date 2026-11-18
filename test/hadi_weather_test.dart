import 'package:flutter_test/flutter_test.dart';
import 'package:ar_rayaan/features/hadi/data/hadi_weather.dart';

const String _body = '''
{"properties":{"timeseries":[
{"time":"2026-11-20T09:00:00Z","data":{"instant":{"details":{"air_temperature":9.2,"wind_speed":5.4}},
 "next_1_hours":{"summary":{"symbol_code":"rain"},"details":{"precipitation_amount":1.2}}}},
{"time":"2026-11-20T18:00:00Z","data":{"instant":{"details":{"air_temperature":8.0,"wind_speed":3}},
 "next_6_hours":{"summary":{"symbol_code":"cloudy"},"details":{"precipitation_amount":0}}}}
]}}
''';

void main() {
  test('detects weather questions, not religious rain questions', () {
    expect(HadiWeather.detect('what is the weather today'), isTrue);
    expect(HadiWeather.detect('will it rain on Friday for jummah outside'),
        isTrue);
    expect(HadiWeather.detect('how to pray salat al istisqa for rain'), isFalse);
    expect(HadiWeather.detect('what is the dua when it rains'), isFalse);
    expect(HadiWeather.detect('how do I pray witr'), isFalse);
  });

  test('parses MET compact JSON', () {
    final List<WeatherHour> h = HadiWeather.parse(_body);
    expect(h.length, 2);
    expect(h.first.tempC, 9.2);
    expect(h.first.rainMm, 1.2);
    expect(h.first.symbol, 'rain');
    expect(HadiWeather.parse('nonsense'), isEmpty);
  });

  test('rain gives a stay-in suggestion and credits MET', () {
    final List<WeatherHour> h = HadiWeather.parse(_body);
    final String r = HadiWeather.reply('weather now, jummah outside?', h, 0,
        now: DateTime.utc(2026, 11, 20, 8));
    expect(r, contains('rainy'));
    expect(r, contains('stay indoors'));
    expect(r, contains('MET Norway'));
    expect(r, isNot(contains('ruling:')));
  });

  test('a day beyond the forecast is said plainly', () {
    final List<WeatherHour> h = HadiWeather.parse(_body);
    final String r = HadiWeather.reply('weather tomorrow', h, 0,
        now: DateTime.utc(2026, 12, 30, 8));
    expect(r, contains('nine days'));
  });
}
