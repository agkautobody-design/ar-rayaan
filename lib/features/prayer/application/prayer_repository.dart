import '../domain/prayer_times.dart';

/// Location used for prayer-time calculation. O-11: coordinates come from
/// device GPS (geolocator) or a curated offline city directory; the city
/// label is display metadata.
class PrayerLocation {
  const PrayerLocation({
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  final String city;
  final String country;

  /// WGS-84 coordinates used by the offline astronomical calculation.
  final double latitude;
  final double longitude;

  String get label => '$city, $country';

  PrayerLocation copyWith({
    String? city,
    String? country,
    double? latitude,
    double? longitude,
  }) {
    return PrayerLocation(
      city: city ?? this.city,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

/// Prayer-times contract. Default implementation is fully offline
/// astronomical calculation (batoulapps adhan port); the seam allows
/// caching or another source without UI changes.
abstract interface class PrayerRepository {
  Future<PrayerTimes> timingsForToday(PrayerLocation location);
}
