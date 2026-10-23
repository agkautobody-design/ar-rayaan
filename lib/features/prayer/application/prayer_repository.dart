import '../domain/prayer_times.dart';
import '../domain/prayer_zone.dart';

/// Location used for prayer-time calculation. O-11: coordinates come from
/// device GPS (geolocator) or a curated offline city directory; the city
/// label is display metadata.
class PrayerLocation {
  const PrayerLocation({
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.zone,
    this.isPlaceholder = false,
  });

  final String city;
  final String country;

  /// WGS-84 coordinates used by the offline astronomical calculation.
  final double latitude;
  final double longitude;

  /// Time zone of a manually chosen city. Null for a GPS fix, where the
  /// device zone is the user's zone.
  final PrayerZone? zone;

  /// True only for the built-in stand-in used before the person has set a
  /// location. Coordinates of a placeholder are NOT the person's place:
  /// screens must ask for a location instead of presenting times or a Qibla
  /// bearing computed from it as fact.
  final bool isPlaceholder;

  /// A location the person chose or the device reported.
  bool get isSet => !isPlaceholder;

  /// The city name stored for a GPS fix, which has no city of its own.
  static const String gpsCity = 'My Location';

  /// True for a GPS fix (no city name is known for it).
  bool get isGps => !isPlaceholder && (city.isEmpty || city == gpsCity);

  String get label {
    if (isPlaceholder) return 'No location set';
    if (isGps) {
      // There is no city name for a GPS fix (looking one up would need an
      // online service), so say what it is and show where it is.
      return 'Your location (GPS) \u00b7 $coordinates';
    }
    return country.isEmpty ? city : '$city, $country';
  }

  /// Short name for running text ("from your location to the Kaaba").
  String get placeName => isGps ? 'your location' : city;

  /// Coordinates rounded to two decimals, e.g. `43.65\u00b0N 79.38\u00b0W`.
  String get coordinates {
    final String ns = latitude >= 0 ? 'N' : 'S';
    final String ew = longitude >= 0 ? 'E' : 'W';
    return '${latitude.abs().toStringAsFixed(2)}\u00b0$ns '
        '${longitude.abs().toStringAsFixed(2)}\u00b0$ew';
  }

  PrayerLocation copyWith({
    String? city,
    String? country,
    double? latitude,
    double? longitude,
    PrayerZone? zone,
  }) {
    return PrayerLocation(
      city: city ?? this.city,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      zone: zone ?? this.zone,
    );
  }
}

/// Prayer-times contract. Default implementation is fully offline
/// astronomical calculation (batoulapps adhan port); the seam allows
/// caching or another source without UI changes.
abstract interface class PrayerRepository {
  Future<PrayerTimes> timingsForToday(PrayerLocation location);
}
