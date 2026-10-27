import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/features/huda/presentation/huda_screens.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every thing a Huda guide has the person say shows its Arabic, a
/// transliteration, the meaning and a source; Qur'an recitations are exactly
/// the ayat of assets/quran/quran.json; and a recitation whose wording was not
/// verified shows no Arabic at all.
void main() {
  final List<Map<String, dynamic>> raw = (json.decode(
    File('assets/guides/guides.json').readAsStringSync(),
  ) as List<dynamic>)
      .cast<Map<String, dynamic>>();
  final List<Map<String, dynamic>> surahs = (json.decode(
    File('assets/quran/quran.json').readAsStringSync(),
  ) as List<dynamic>)
      .cast<Map<String, dynamic>>();

  String ayah(String ref) {
    final List<String> p = ref.split(':');
    final Map<String, dynamic> s =
        surahs.firstWhere((Map<String, dynamic> x) => x['n'] == int.parse(p[0]));
    final List<String> range = p[1].split('-');
    final int a = int.parse(range.first);
    final int b = int.parse(range.last);
    return (s['v'] as List<dynamic>)
        .cast<List<dynamic>>()
        .where((List<dynamic> v) => (v[0] as int) >= a && (v[0] as int) <= b)
        .map((List<dynamic> v) => v[1] as String)
        .join('\n');
  }

  final RegExp arabicOnly = RegExp(r'^[؀-ۿ\s]+$');

  test('the Guide model reads recitations', () {
    final List<Guide> guides = raw.map(Guide.fromJson).toList();
    final int total = guides.fold<int>(0, (int n, Guide g) => n + g.recitations.length);
    expect(total, greaterThan(40));
  });

  test('every verified recitation has Arabic, transliteration, meaning and source', () {
    for (final Map<String, dynamic> g in raw) {
      for (final Map<String, dynamic> r
          in ((g['recitations'] as List<dynamic>?) ?? const <dynamic>[])
              .cast<Map<String, dynamic>>()) {
        final String where = '${g['id']}: ${r['when']}';
        if (r['status'] == 'verified') {
          expect(r['arabic'], isA<String>(), reason: where);
          expect(arabicOnly.hasMatch(r['arabic'] as String), isTrue,
              reason: '$where: Arabic holds a non-Arabic character');
          expect((r['translit'] as String? ?? '').trim(), isNotEmpty, reason: where);
          expect((r['meaning'] as String? ?? '').trim(), isNotEmpty, reason: where);
          expect((r['sources'] as List<dynamic>? ?? <dynamic>[]), isNotEmpty,
              reason: where);
          expect(r['needsScholarReview'], isTrue, reason: where);
        } else {
          expect(r['status'], 'unverified', reason: where);
          expect(r['arabic'], isNull, reason: '$where: unverified wording shows no Arabic');
          expect((r['note'] as String? ?? '').trim(), isNotEmpty, reason: where);
        }
      }
    }
  });

  test('Qur\'an recitations are exactly the ayat of quran.json', () {
    int seen = 0;
    for (final Map<String, dynamic> g in raw) {
      for (final Map<String, dynamic> r
          in ((g['recitations'] as List<dynamic>?) ?? const <dynamic>[])
              .cast<Map<String, dynamic>>()) {
        if (r['kind'] == 'quran') {
          seen++;
          expect(r['arabic'], ayah(r['ref'] as String),
              reason: '${g['id']}: ${r['ref']}');
        }
      }
    }
    expect(seen, greaterThan(5));
  });

  test('guides that tell the person to say something carry recitations', () {
    final Map<String, Map<String, dynamic>> byId = <String, Map<String, dynamic>>{
      for (final Map<String, dynamic> g in raw) g['id'] as String: g,
    };
    for (final String id in <String>[
      'huda-prayer', 'huda-wudu', 'huda-adhan', 'huda-istikhara', 'huda-travel',
      'huda-sleep', 'huda-food', 'huda-janazah-prayer', 'huda-witr', 'huda-ihram',
      'huda-hardship', 'huda-adhkar', 'huda-illness', 'huda-fasting',
    ]) {
      expect((byId[id]!['recitations'] as List<dynamic>? ?? <dynamic>[]), isNotEmpty,
          reason: id);
    }
  });
}
