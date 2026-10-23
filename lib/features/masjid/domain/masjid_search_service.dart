import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

/// A masjid from open map data.
class Mosque {
  final String name;
  final double lat, lon;
  final String? addr, website, phone, denomination, hours;
  final bool wheelchair;
  const Mosque({
    required this.name,
    required this.lat,
    required this.lon,
    this.addr,
    this.website,
    this.phone,
    this.denomination,
    this.hours,
    this.wheelchair = false,
  });
}

/// Straight-line distance in metres.
double masjidDistanceMeters(double a1, double o1, double a2, double o2) {
  const double r = 6371000.0;
  double rad(double d) => d * math.pi / 180;
  final double dLa = rad(a2 - a1), dLo = rad(o2 - o1);
  final double h = math.sin(dLa / 2) * math.sin(dLa / 2) +
      math.cos(rad(a1)) *
          math.cos(rad(a2)) *
          math.sin(dLo / 2) *
          math.sin(dLo / 2);
  return 2 * r * math.asin(math.sqrt(h));
}

/// What a search produced. Exactly one of [mosques] / [foods] is used.
class MapSearchOutcome {
  final List<Mosque> mosques;
  final List<Map<String, dynamic>> foods;

  /// True when Overpass failed everywhere and the Nominatim backup answered.
  final bool fromBackup;
  const MapSearchOutcome({
    this.mosques = const <Mosque>[],
    this.foods = const <Map<String, dynamic>>[],
    this.fromBackup = false,
  });
}

/// Every source failed. [reason] is a short, reportable line.
class MapSearchFailure implements Exception {
  final String reason;
  const MapSearchFailure(this.reason);
  @override
  String toString() => 'MapSearchFailure($reason)';
}

const List<String> kOverpassServers = <String>[
  'https://overpass-api.de/api/interpreter',
  'https://overpass.private.coffee/api/interpreter',
  'https://overpass.kumi.systems/api/interpreter',
  'https://overpass.openstreetmap.fr/api/interpreter',
];

/// Runs every task at once; the first to finish without throwing wins and the
/// rest are ignored. If all throw, [MapSearchFailure] lists why.
Future<T> firstSuccess<T>(
  List<Future<T> Function()> tasks,
  String Function(Object error) describe,
) {
  final Completer<T> done = Completer<T>();
  final List<String> reasons = <String>[];
  int pending = tasks.length;
  if (pending == 0) {
    return Future<T>.error(const MapSearchFailure('no servers'));
  }
  for (final Future<T> Function() task in tasks) {
    Future<T> run;
    try {
      run = task();
    } catch (e) {
      run = Future<T>.error(e);
    }
    run.then((T v) {
      if (!done.isCompleted) done.complete(v);
    }, onError: (Object e) {
      reasons.add(describe(e));
      pending--;
      if (pending == 0 && !done.isCompleted) {
        done.completeError(MapSearchFailure(reasons.toSet().join(', ')));
      }
    });
  }
  return done.future;
}

String _describe(Object e) {
  if (e is TimeoutException) return 'timed out';
  if (e is _HttpStatus) return 'HTTP ${e.code}';
  if (e is _BadAnswer) return e.what;
  if (e is FormatException) return 'unreadable answer';
  return 'connection blocked';
}

class _HttpStatus implements Exception {
  final int code;
  const _HttpStatus(this.code);
}

class _BadAnswer implements Exception {
  final String what;
  const _BadAnswer(this.what);
}

double? _num(Object? v) => v is num ? v.toDouble() : null;

/// The Overpass query: light on purpose, so busy public servers answer.
String masjidOverpassQuery({
  required double lat,
  required double lon,
  required bool food,
  required int radius,
}) {
  final String tag = food
      ? 'nwr["diet:halal"~"^(yes|only)\$"](around:$radius,$lat,$lon);'
      : 'nwr["amenity"="place_of_worship"]["religion"="muslim"]'
          '(around:$radius,$lat,$lon);';
  return '[out:json][timeout:10];($tag);out center 100;';
}

/// Searches open map data near a point. Overpass servers are asked in
/// parallel; if all fail, Nominatim (a separate service) is tried.
/// Throws [MapSearchFailure] only when everything failed.
Future<MapSearchOutcome> searchNearby({
  required http.Client client,
  required double lat,
  required double lon,
  required bool food,
  List<String> servers = kOverpassServers,
  String nominatimBase = 'https://nominatim.openstreetmap.org/search',
  Duration timeout = const Duration(seconds: 12),
}) async {
  String reason = '';
  try {
    for (final int radius in <int>[4000, 12000]) {
      final String query = masjidOverpassQuery(
        lat: lat,
        lon: lon,
        food: food,
        radius: radius,
      );
      final List<dynamic> els = await firstSuccess<List<dynamic>>(
        <Future<List<dynamic>> Function()>[
          for (final String s in servers)
            () => _overpass(client, s, query, timeout),
        ],
        _describe,
      );
      final MapSearchOutcome out = _fromOverpass(els, lat, lon, food);
      if (out.mosques.isNotEmpty || out.foods.isNotEmpty) return out;
    }
    // Overpass answered, twice, with nothing: a real empty result.
    return const MapSearchOutcome();
  } on MapSearchFailure catch (e) {
    reason = e.reason;
  }
  try {
    return await _nominatim(
        client, nominatimBase, lat, lon, food, timeout);
  } catch (e) {
    final String backup = e is MapSearchFailure ? e.reason : _describe(e);
    throw MapSearchFailure('Overpass: $reason; backup: $backup');
  }
}

Future<List<dynamic>> _overpass(
  http.Client client,
  String server,
  String query,
  Duration timeout,
) async {
  // A plain form POST: no custom headers, so browsers send no preflight.
  final http.Response res = await client
      .post(Uri.parse(server), body: <String, String>{'data': query})
      .timeout(timeout);
  if (res.statusCode != 200) throw _HttpStatus(res.statusCode);
  final Object? decoded = json.decode(res.body);
  if (decoded is! Map<String, dynamic>) {
    throw const _BadAnswer('unreadable answer');
  }
  final Object? els = decoded['elements'];
  final Object? remark = decoded['remark'];
  // Overloaded servers can answer 200 with an empty list and a remark.
  if (els is! List<dynamic> ||
      (els.isEmpty && remark is String && remark.contains('error'))) {
    throw const _BadAnswer('server busy');
  }
  return els;
}

MapSearchOutcome _fromOverpass(
  List<dynamic> els,
  double lat,
  double lon,
  bool food,
) {
  if (!food) {
    final List<Mosque> out = <Mosque>[];
    for (final dynamic e in els) {
      if (e is! Map<String, dynamic>) continue;
      final Map<String, dynamic> tags =
          (e['tags'] as Map<dynamic, dynamic>?)?.cast<String, dynamic>() ??
              <String, dynamic>{};
      final double? la = _num(e['lat'] ?? (e['center'] as Map?)?['lat']);
      final double? lo = _num(e['lon'] ?? (e['center'] as Map?)?['lon']);
      if (la == null || lo == null) continue;
      final String? addr = tags['addr:street'] != null
          ? '${tags['addr:housenumber'] ?? ''} ${tags['addr:street']}, '
                  '${tags['addr:city'] ?? ''}'
              .trim()
          : null;
      out.add(Mosque(
        name: tags['name'] as String? ?? 'Masjid',
        lat: la,
        lon: lo,
        addr: addr?.isEmpty == true ? null : addr,
        website:
            tags['website'] as String? ?? tags['contact:website'] as String?,
        phone: tags['phone'] as String? ?? tags['contact:phone'] as String?,
        denomination: tags['denomination'] as String?,
        hours: tags['opening_hours'] as String?,
        wheelchair: tags['wheelchair'] == 'yes',
      ));
    }
    return MapSearchOutcome(mosques: _nearestMosques(out, lat, lon));
  }
  final List<Map<String, dynamic>> foods = <Map<String, dynamic>>[];
  for (final dynamic e in els) {
    if (e is! Map<String, dynamic>) continue;
    final Map<String, dynamic> m =
        (e['tags'] as Map<dynamic, dynamic>?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final double? la = _num(e['lat'] ?? (e['center'] as Map?)?['lat']);
    final double? lo = _num(e['lon'] ?? (e['center'] as Map?)?['lon']);
    if (la == null || lo == null) continue;
    foods.add(<String, dynamic>{
      'name': m['name'] ?? 'Restaurant',
      'lat': la,
      'lon': lo,
      'cuisine': m['cuisine'],
      'addr': m['addr:street'],
      'phone': m['phone'],
      'website': m['website'],
      'only': m['diet:halal'] == 'only',
    });
  }
  return MapSearchOutcome(foods: _nearestFoods(foods, lat, lon));
}

List<Mosque> _nearestMosques(List<Mosque> l, double lat, double lon) {
  l.sort((a, b) => masjidDistanceMeters(lat, lon, a.lat, a.lon)
      .compareTo(masjidDistanceMeters(lat, lon, b.lat, b.lon)));
  return l.take(50).toList();
}

List<Map<String, dynamic>> _nearestFoods(
  List<Map<String, dynamic>> l,
  double lat,
  double lon,
) {
  l.sort((a, b) => masjidDistanceMeters(
          lat, lon, a['lat'] as double, a['lon'] as double)
      .compareTo(masjidDistanceMeters(
          lat, lon, b['lat'] as double, b['lon'] as double)));
  return l.take(50).toList();
}

Future<MapSearchOutcome> _nominatim(
  http.Client client,
  String base,
  double lat,
  double lon,
  bool food,
  Duration timeout,
) async {
  // About 8 km each way; longitude degrees shrink away from the equator.
  const double dLat = 0.07;
  final double dLon =
      dLat / math.max(0.2, math.cos(lat * math.pi / 180));
  final String viewbox = '${lon - dLon},${lat + dLat},'
      '${lon + dLon},${lat - dLat}';
  final Uri uri = Uri.parse(base).replace(queryParameters: <String, String>{
    'format': 'jsonv2',
    'q': food ? 'halal restaurant' : 'mosque',
    'viewbox': viewbox,
    'bounded': '1',
    'limit': '40',
    'addressdetails': '1',
    'extratags': '1',
  });
  final http.Response res = await client.get(uri).timeout(timeout);
  if (res.statusCode != 200) throw _HttpStatus(res.statusCode);
  final Object? decoded = json.decode(res.body);
  if (decoded is! List<dynamic>) throw const _BadAnswer('unreadable answer');
  final List<Mosque> mosques = <Mosque>[];
  final List<Map<String, dynamic>> foods = <Map<String, dynamic>>[];
  for (final dynamic e in decoded) {
    if (e is! Map<String, dynamic>) continue;
    final double? la = double.tryParse('${e['lat']}');
    final double? lo = double.tryParse('${e['lon']}');
    if (la == null || lo == null) continue;
    final Map<String, dynamic> extra =
        (e['extratags'] as Map<dynamic, dynamic>?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final Map<String, dynamic> a =
        (e['address'] as Map<dynamic, dynamic>?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final String? name = (e['name'] as String?)?.trim();
    final String? road = a['road'] as String?;
    final String? city = (a['city'] ?? a['town'] ?? a['village']) as String?;
    final String? addr = road == null
        ? null
        : '${a['house_number'] ?? ''} $road${city == null ? '' : ', $city'}'
            .trim();
    if (food) {
      foods.add(<String, dynamic>{
        'name': (name == null || name.isEmpty) ? 'Restaurant' : name,
        'lat': la,
        'lon': lo,
        'cuisine': extra['cuisine'],
        'addr': road,
        'phone': extra['phone'],
        'website': extra['website'],
        'only': extra['diet:halal'] == 'only',
      });
    } else {
      mosques.add(Mosque(
        name: (name == null || name.isEmpty) ? 'Masjid' : name,
        lat: la,
        lon: lo,
        addr: addr,
        website: (extra['website'] ?? extra['contact:website']) as String?,
        phone: (extra['phone'] ?? extra['contact:phone']) as String?,
        denomination: extra['denomination'] as String?,
        hours: extra['opening_hours'] as String?,
        wheelchair: extra['wheelchair'] == 'yes',
      ));
    }
  }
  return MapSearchOutcome(
    mosques: _nearestMosques(mosques, lat, lon),
    foods: _nearestFoods(foods, lat, lon),
    fromBackup: true,
  );
}
