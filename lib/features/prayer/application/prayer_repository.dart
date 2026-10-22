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

  String get label {
    if (isPlaceholder) return 'No location set';
    return country.isEmpty ? city : '$city, $country';
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
