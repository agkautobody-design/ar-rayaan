import 'dart:math' as math;

/// A geographic coordinate (decimal degrees).
typedef LatLng = ({double lat, double lng});

/// Qibla direction math — initial great-circle bearing from a location to the
/// Kaaba in Makkah. Pure math, works fully offline.
///
/// Location strategy is pending (O-11); until then the app defaults to
/// Toronto, matching the Prayer Times module.
abstract final class QiblaDirection {
  /// The Kaaba, Masjid al-Haram, Makkah.
  static const LatLng kaaba = (lat: 21.4224779, lng: 39.8251832);

  /// Default location while O-11 (GPS vs city picker) is undecided.
  static const LatLng defaultLocation = (lat: 43.6532, lng: -79.3832);
  static const String defaultLocationName = 'Toronto';

  /// Initial bearing in degrees (0–360, clockwise from true North) from
  /// [from] to the Kaaba.
  static double bearingToKaaba(LatLng from) {
    final double phi1 = _rad(from.lat);
    final double phi2 = _rad(kaaba.lat);
    final double dLambda = _rad(kaaba.lng - from.lng);
    final double y = math.sin(dLambda);
    final double x =
        math.cos(phi1) * math.tan(phi2) - math.sin(phi1) * math.cos(dLambda);
    final double deg = _deg(math.atan2(y, x));
    return (deg + 360) % 360;
  }

  /// Great-circle distance from [from] to the Kaaba, in kilometers
  /// (haversine, Earth radius 6371 km). For the Haramain card's
  /// "distance to Makkah" line (M2 / 2.1).
  static double distanceToKaabaKm(LatLng from) {
    const double earthRadiusKm = 6371.0;
    final double phi1 = _rad(from.lat);
    final double phi2 = _rad(kaaba.lat);
    final double dPhi = _rad(kaaba.lat - from.lat);
    final double dLam = _rad(kaaba.lng - from.lng);
    final double a = math.sin(dPhi / 2) * math.sin(dPhi / 2) +
        math.cos(phi1) *
            math.cos(phi2) *
            math.sin(dLam / 2) *
            math.sin(dLam / 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /// Compass point label (16-wind) for a bearing, e.g. 54.7 → 'NE'.
  static String compassPoint(double bearing) {
    const List<String> points = <String>[
      'N',
      'NNE',
      'NE',
      'ENE',
      'E',
      'ESE',
      'SE',
      'SSE',
      'S',
      'SSW',
      'SW',
      'WSW',
      'W',
      'WNW',
      'NW',
      'NNW',
    ];
    final int index = ((bearing + 11.25) / 22.5).floor() % 16;
    return points[index];
  }

  static double _rad(double deg) => deg * math.pi / 180;
  static double _deg(double rad) => rad * 180 / math.pi;
}
