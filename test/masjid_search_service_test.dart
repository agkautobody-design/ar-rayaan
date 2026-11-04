import 'dart:async';
import 'dart:convert';

import 'package:ar_rayaan/features/masjid/domain/masjid_search_service.dart';
import 'package:ar_rayaan/features/masjid/domain/masjid_search_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const List<String> _servers = <String>[
  'https://a.example/api/interpreter',
  'https://b.example/api/interpreter',
];

http.Response _json(Object body, [int code = 200]) => http.Response(
      jsonEncode(body),
      code,
      headers: <String, String>{'content-type': 'application/json'},
    );

final Map<String, Object> _overpassOk = <String, Object>{
  'elements': <Object>[
    <String, Object>{
      'type': 'node',
      'lat': 43.51,
      'lon': -79.88,
      'tags': <String, String>{'name': 'Far Masjid'},
    },
    <String, Object>{
      'type': 'way',
      'center': <String, double>{'lat': 43.5, 'lon': -79.88},
      'tags': <String, String>{'name': 'Near Masjid'},
    },
  ],
};

Future<MapSearchOutcome> _run(
  MockClient c, {
  bool food = false,
}) =>
    searchNearby(
      client: c,
      lat: 43.5,
      lon: -79.88,
      food: food,
      servers: _servers,
      nominatimBase: 'https://nom.example/search',
      timeout: const Duration(milliseconds: 200),
      nominatimGap: Duration.zero,
    );

void main() {
  test('first server fails, second answers: its results are used', () async {
    final MockClient c = MockClient((http.Request r) async {
      if (r.url.host == 'a.example') return http.Response('busy', 504);
      if (r.url.host == 'b.example') return _json(_overpassOk);
      return http.Response('no', 500);
    });
    final MapSearchOutcome out = await _run(c);
    expect(out.fromBackup, isFalse);
    expect(out.mosques.map((Mosque m) => m.name),
        <String>['Near Masjid', 'Far Masjid']);
  });

  test('the request is a plain form post with no custom headers', () async {
    late http.Request seen;
    final MockClient c = MockClient((http.Request r) async {
      seen = r;
      return _json(_overpassOk);
    });
    await _run(c);
    expect(seen.method, 'POST');
    expect(seen.bodyFields['data'], contains('[timeout:15]'));
    expect(seen.bodyFields['data'], contains('around:4000'));
    expect(seen.bodyFields['data'], contains('out center 100'));
    expect(seen.headers.keys.map((String k) => k.toLowerCase()),
        everyElement(anyOf('content-type', 'content-length')));
  });

  test('a hung server does not hold up a fast one', () async {
    final MockClient c = MockClient((http.Request r) async {
      if (r.url.host == 'a.example') {
        await Completer<void>().future; // never answers
      }
      return _json(_overpassOk);
    });
    final MapSearchOutcome out = await _run(c);
    expect(out.mosques, hasLength(2));
  });

  test('every Overpass server fails: Nominatim backup is used', () async {
    final MockClient c = MockClient((http.Request r) async {
      if (r.url.host == 'nom.example') {
        expect(kNominatimMosqueTerms, contains(r.url.queryParameters['q']));
        expect(r.url.queryParameters['bounded'], '1');
        if (r.url.queryParameters['q'] == 'mosque') {
          return _json(<Object>[
            <String, Object>{
              'lat': '43.5',
              'lon': '-79.88',
              'name': 'Backup Masjid',
              'address': <String, String>{'road': 'Main St', 'city': 'Milton'},
            },
          ]);
        }
        return _json(<Object>[]);
      }
      return http.Response('slow down', 429);
    });
    final MapSearchOutcome out = await _run(c);
    expect(out.fromBackup, isTrue);
    expect(out.mosques.single.name, 'Backup Masjid');
    expect(out.mosques.single.addr, 'Main St, Milton');
  });

  test('food tab backup asks for halal restaurants', () async {
    final MockClient c = MockClient((http.Request r) async {
      if (r.url.host == 'nom.example') {
        expect(kNominatimFoodTerms, contains(r.url.queryParameters['q']));
        if (r.url.queryParameters['q'] == 'halal restaurant') {
          return _json(<Object>[
            <String, Object>{'lat': '43.5', 'lon': '-79.88', 'name': 'Grill'},
          ]);
        }
        return _json(<Object>[]);
      }
      throw http.ClientException('blocked');
    });
    final MapSearchOutcome out = await _run(c, food: true);
    expect(out.fromBackup, isTrue);
    expect(out.foods.single['name'], 'Grill');
  });

  test('the mosque query covers every denomination and mosque buildings', () {
    final String q = masjidOverpassQuery(
        lat: 43.5, lon: -79.88, food: false, radius: 4000);
    expect(q, contains('"religion"="muslim"'));
    expect(q, contains('"building"="mosque"'));
    expect(q, isNot(contains('denomination')));
  });

  test('the food query accepts any halal tag but "no", plus halal cuisine', () {
    final String q = masjidOverpassQuery(
        lat: 43.5, lon: -79.88, food: true, radius: 4000);
    expect(q, contains('"diet:halal"!="no"'));
    expect(q, contains('"cuisine"'));
  });

  test('the backup merges its terms and drops duplicate places', () async {
    final MockClient c = MockClient((http.Request r) async {
      if (r.url.host == 'nom.example') {
        final String? q = r.url.queryParameters['q'];
        if (q == 'mosque') {
          return _json(<Object>[
            <String, Object>{'lat': '43.5', 'lon': '-79.88', 'name': 'Same Masjid'},
          ]);
        }
        if (q == 'masjid') {
          return _json(<Object>[
            <String, Object>{'lat': '43.5', 'lon': '-79.88', 'name': 'Same Masjid'},
            <String, Object>{'lat': '43.52', 'lon': '-79.9', 'name': 'Second Masjid'},
          ]);
        }
        return _json(<Object>[]);
      }
      return http.Response('busy', 504);
    });
    final MapSearchOutcome out = await _run(c);
    expect(out.fromBackup, isTrue);
    expect(out.mosques, hasLength(2));
    expect(out.mosques.map((Mosque m) => m.name),
        containsAll(<String>['Same Masjid', 'Second Masjid']));
  });

  test('everything fails: a reportable reason is thrown', () async {
    final MockClient c = MockClient((http.Request r) async {
      if (r.url.host == 'nom.example') return http.Response('x', 503);
      return http.Response('x', 504);
    });
    await expectLater(
      _run(c),
      throwsA(
        isA<MapSearchFailure>().having(
          (MapSearchFailure f) => f.reason,
          'reason',
          allOf(contains('HTTP 504'), contains('backup: HTTP 503')),
        ),
      ),
    );
  });

  test('timeouts are reported as timed out', () async {
    final MockClient c = MockClient((http.Request r) async {
      await Completer<void>().future;
      return http.Response('', 200);
    });
    await expectLater(
      _run(c),
      throwsA(isA<MapSearchFailure>().having(
          (MapSearchFailure f) => f.reason, 'reason', contains('timed out'))),
    );
  });

  test('a real empty answer is empty, not a failure', () async {
    final MockClient c = MockClient(
      (http.Request r) async => _json(<String, Object>{'elements': <Object>[]}),
    );
    final MapSearchOutcome out = await _run(c);
    expect(out.mosques, isEmpty);
    expect(out.fromBackup, isFalse);
  });

  test('geo link for Android map apps', () {
    expect(
      masjidGeoUri(lat: 1.5, lon: 2.5, food: false).toString(),
      'geo:1.5,2.5?q=mosque',
    );
  });
}
