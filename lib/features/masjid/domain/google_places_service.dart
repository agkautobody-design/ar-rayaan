import 'dart:convert';

import 'package:http/http.dart' as http;

import 'masjid_search_service.dart';

/// The Google Places key, passed at build time with
/// --dart-define=GOOGLE_PLACES_KEY=... Empty when the build has no key, and
/// then the Google section never appears and nothing is sent to Google.
const String kGooglePlacesKey = String.fromEnvironment('GOOGLE_PLACES_KEY');

/// One place from Google Places (New).
///
/// Google's terms: this data is shown in a list with a "Google Maps"
/// attribution and a link to [mapsUri]; it is never drawn as markers on the
/// OpenStreetMap map and never stored.
class GooglePlace {
  final String name;
  final double lat, lon;
  final String? address, mapsUri, website, phone;
  final double? rating;
  final int? ratingCount;
  final bool? openNow;
  const GooglePlace({
    required this.name,
    required this.lat,
    required this.lon,
    this.address,
    this.mapsUri,
    this.website,
    this.phone,
    this.rating,
    this.ratingCount,
    this.openNow,
  });
}

const String kPlacesEndpoint = 'https://places.googleapis.com/v1/places:searchText';

const String kPlacesFieldMask = 'places.displayName,places.formattedAddress,'
    'places.location,places.googleMapsUri,places.rating,'
    'places.userRatingCount,places.currentOpeningHours.openNow,'
    'places.nationalPhoneNumber,places.websiteUri';

/// The text asked of Google. "Halal" in a name or review is what Google
/// knows; it is not a certification, and the app says so.
String placesQuery({required bool food}) =>
    food ? 'halal restaurant' : 'mosque';

/// Reads a searchText answer. Anything malformed is skipped, never thrown.
List<GooglePlace> parsePlacesResponse(String body) {
  final Object? decoded = json.decode(body);
  if (decoded is! Map<String, dynamic>) return const <GooglePlace>[];
  final Object? list = decoded['places'];
  if (list is! List<dynamic>) return const <GooglePlace>[];
  final List<GooglePlace> out = <GooglePlace>[];
  for (final dynamic p in list) {
    if (p is! Map<String, dynamic>) continue;
    final Object? loc = p['location'];
    if (loc is! Map<String, dynamic>) continue;
    final Object? la = loc['latitude'], lo = loc['longitude'];
    if (la is! num || lo is! num) continue;
    final Object? dn = p['displayName'];
    final String? name = dn is Map<String, dynamic>
        ? (dn['text'] as String?)?.trim()
        : null;
    if (name == null || name.isEmpty) continue;
    final Object? hours = p['currentOpeningHours'];
    final Object? open = hours is Map<String, dynamic> ? hours['openNow'] : null;
    out.add(GooglePlace(
      name: name,
      lat: la.toDouble(),
      lon: lo.toDouble(),
      address: p['formattedAddress'] as String?,
      mapsUri: p['googleMapsUri'] as String?,
      website: p['websiteUri'] as String?,
      phone: p['nationalPhoneNumber'] as String?,
      rating: (p['rating'] as num?)?.toDouble(),
      ratingCount: (p['userRatingCount'] as num?)?.toInt(),
      openNow: open is bool ? open : null,
    ));
  }
  return out;
}

/// Asks Google for places near a point, nearest first. Returns an empty list
/// when there is no key; throws [MapSearchFailure] on any failure so the
/// caller can fall back to the open-data results it already has.
Future<List<GooglePlace>> searchGooglePlaces({
  required http.Client client,
  required double lat,
  required double lon,
  required bool food,
  String key = kGooglePlacesKey,
  String endpoint = kPlacesEndpoint,
  double radiusMeters = 15000,
  Duration timeout = const Duration(seconds: 12),
}) async {
  if (key.isEmpty) return const <GooglePlace>[];
  try {
    final http.Response res = await client
        .post(
          Uri.parse(endpoint),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': key,
            'X-Goog-FieldMask': kPlacesFieldMask,
          },
          body: json.encode(<String, Object>{
            'textQuery': placesQuery(food: food),
            'maxResultCount': 20,
            'rankPreference': 'DISTANCE',
            'locationBias': <String, Object>{
              'circle': <String, Object>{
                'center': <String, double>{'latitude': lat, 'longitude': lon},
                'radius': radiusMeters,
              },
            },
          }),
        )
        .timeout(timeout);
    if (res.statusCode != 200) {
      throw MapSearchFailure('Google HTTP ${res.statusCode}');
    }
    final List<GooglePlace> all = parsePlacesResponse(res.body);
    all.sort((a, b) => masjidDistanceMeters(lat, lon, a.lat, a.lon)
        .compareTo(masjidDistanceMeters(lat, lon, b.lat, b.lon)));
    return all;
  } on MapSearchFailure {
    rethrow;
  } catch (_) {
    throw const MapSearchFailure('Google unavailable');
  }
}
