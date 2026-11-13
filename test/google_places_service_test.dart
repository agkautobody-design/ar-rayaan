import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ar_rayaan/features/masjid/domain/google_places_service.dart';
import 'package:ar_rayaan/features/masjid/domain/masjid_search_service.dart';

const String _body = '''
{"places":[
 {"displayName":{"text":"Far Masjid"},"formattedAddress":"9 Far Rd",
  "location":{"latitude":40.9,"longitude":-74.0},"googleMapsUri":"https://maps.google.com/?cid=2",
  "rating":4.5,"userRatingCount":80,"currentOpeningHours":{"openNow":true}},
 {"displayName":{"text":"Near Halal Grill"},"location":{"latitude":40.71,"longitude":-74.0},
  "googleMapsUri":"https://maps.google.com/?cid=1","websiteUri":"https://grill.example"},
 {"displayName":{"text":"No location"}},
 {"location":{"latitude":1,"longitude":1}}
]}''';

void main() {
  test('parse skips malformed places and reads optional fields', () {
    final List<GooglePlace> l = parsePlacesResponse(_body);
    expect(l.map((p) => p.name), <String>['Far Masjid', 'Near Halal Grill']);
    expect(l.first.rating, 4.5);
    expect(l.first.openNow, isTrue);
    expect(l.last.openNow, isNull);
    expect(parsePlacesResponse('[]'), isEmpty);
    expect(parsePlacesResponse('{}'), isEmpty);
  });

  test('no key: nothing is sent', () async {
    int calls = 0;
    final http.Client c = MockClient((r) async {
      calls++;
      return http.Response(_body, 200);
    });
    final List<GooglePlace> l = await searchGooglePlaces(
        client: c, lat: 40.7, lon: -74, food: false, key: '');
    expect(l, isEmpty);
    expect(calls, 0);
  });

  test('with a key: sends field mask, sorts nearest first', () async {
    late http.Request seen;
    final http.Client c = MockClient((r) async {
      seen = r;
      return http.Response(_body, 200);
    });
    final List<GooglePlace> l = await searchGooglePlaces(
        client: c, lat: 40.7, lon: -74, food: true, key: 'k');
    expect(l.first.name, 'Near Halal Grill');
    expect(seen.headers['X-Goog-Api-Key'], 'k');
    expect(seen.headers['X-Goog-FieldMask'], kPlacesFieldMask);
    expect((json.decode(seen.body) as Map)['textQuery'], 'halal restaurant');
  });

  test('HTTP error and network error become MapSearchFailure', () async {
    for (final http.Client c in <http.Client>[
      MockClient((r) async => http.Response('no', 403)),
      MockClient((r) async => throw Exception('offline')),
    ]) {
      expect(
          () => searchGooglePlaces(
              client: c, lat: 1, lon: 1, food: false, key: 'k'),
          throwsA(isA<MapSearchFailure>()));
    }
  });
}
