import 'dart:math' as math;

/// A geographic coordinate (decimal degrees).
typedef LatLng = ({double lat, double lng});

/// Qibla direction math — initial great-circle bearing from a location to the
/// Kaaba in Makkah. Pure math, works fully offline.
///
/// The location always comes from the person (device location or a chosen
/// city); the app never assumes one.
abstract final class QiblaDirection {
  /// The Kaaba, Masjid al-Haram, Makkah.
  static const LatLng kaaba = (lat: 21.4224779, lng: 39.8251832);

  /// A fixed sample point (Toronto) for tests and worked examples only. It
  /// is never used as the person's location.
  static const LatLng sampleToronto = (lat: 43.6532, lng: -79.3832);

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

  /// Plain-words direction (8-wind) for a bearing, e.g. 136 -> 'south-east'.
  static String plainDirection(double bearing) {
    const List<String> names = <String>[
      'north',
      'north-east',
      'east',
      'south-east',
      'south',
      'south-west',
      'west',
      'north-west',
    ];
    final double b = ((bearing % 360) + 360) % 360;
    return names[((b + 22.5) / 45).floor() % 8];
  }

  /// One plain sentence for a first-time user, e.g.
  /// 'Face south-east, about 136°'.
  static String plainSentence(double bearing) {
    final int deg = (((bearing % 360) + 360) % 360).round() % 360;
    return 'Face ${plainDirection(bearing)}, about $deg°';
  }

  static double _rad(double deg) => deg * math.pi / 180;
  static double _deg(double rad) => rad * 180 / math.pi;
}
