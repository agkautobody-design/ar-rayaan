import 'package:flutter_test/flutter_test.dart';

import 'package:ar_rayaan/features/hadi/data/hadi_explain.dart';
import 'package:ar_rayaan/features/hadi/data/hadi_nearest_masjid.dart';
import 'package:ar_rayaan/features/masjid/domain/masjid_search_service.dart';
import 'package:ar_rayaan/features/places/domain/community_place.dart';
import 'package:ar_rayaan/features/places/domain/jumuah_time.dart';

void main() {
  group('"where is juma" is a place request', () {
    test('short where-questions about Friday prayer', () {
      for (final String q in <String>[
        'Where is juma',
        'where is jummah',
        "where's jumuah",
        'where is friday prayer',
      ]) {
        expect(HadiExplain.asksNearestMasjidFirst(q), isTrue, reason: q);
        expect(HadiExplain.asksFridayOrMasjidPlace(q), isTrue, reason: q);
      }
    });
    test('rulings and history stay with the topic answers', () {
      for (final String q in <String>[
        'where is jumuah mentioned in the quran',
        'is jumuah obligatory for women',
        'why is juma on friday',
        'what is jumuah',
      ]) {
        expect(HadiExplain.asksNearestMasjidFirst(q), isFalse, reason: q);
      }
    });
    test('halal food is not answered with masajid', () {
      expect(HadiExplain.asksFridayOrMasjidPlace('halal food near me'), isFalse);
    });
  });

  group('HadiNearestMasjid', () {
    const Mosque near = Mosque(
        name: 'Near Masjid', lat: 43.501, lon: -79.8, jumuah: 'Fr 13:15');
    const Mosque far = Mosque(name: 'Far Masjid', lat: 43.6, lon: -79.8);
    const Mosque mid = Mosque(name: 'Mid Masjid', lat: 43.52, lon: -79.8);

    test('distance wording', () {
      expect(HadiNearestMasjid.distance(850), '850 m');
      expect(HadiNearestMasjid.distance(1234), '1.2 km');
      expect(HadiNearestMasjid.distance(14200), '14 km');
    });

    test('nearest first, with the map time and "not listed"', () {
      final String r = HadiNearestMasjid.reply(
        mosques: <Mosque>[far, near, mid],
        lat: 43.5,
        lon: -79.8,
        friday: true,
      );
      expect(r.indexOf('Near Masjid') < r.indexOf('Mid Masjid'), isTrue);
      expect(r.indexOf('Mid Masjid') < r.indexOf('Far Masjid'), isTrue);
      expect(r, contains('Fr 13:15 (from open map data)'));
      expect(r, contains('Jumu’ah time not listed'));
      expect(r, contains('[GO:/masajid]'));
    });

    test('a community time wins over the map time', () {
      final String key =
          PlacesPolicy.osmTargetId(near.name, near.lat, near.lon);
      final String r = HadiNearestMasjid.reply(
        mosques: <Mosque>[near],
        lat: 43.5,
        lon: -79.8,
        friday: true,
        community: <String, JumuahEntry>{
          key: JumuahEntry(key: key, text: '1:45 PM', uid: 'u'),
        },
      );
      expect(r, contains('1:45 PM (added by a community member)'));
      expect(r, isNot(contains('Fr 13:15')));
    });

    test('an empty search says so and points to the Masajid screen', () {
      final String r = HadiNearestMasjid.reply(
          mosques: const <Mosque>[], lat: 1, lon: 1, friday: true);
      expect(r, contains('found no masjid'));
      expect(r, contains('[GO:/masajid]'));
    });
  });
}
