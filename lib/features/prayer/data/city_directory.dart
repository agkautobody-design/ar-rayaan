import '../application/prayer_repository.dart';

/// Curated offline city directory — the manual fallback when GPS is denied
/// or unavailable. Coordinates are city-centre WGS-84; calculation happens
/// on-device, so no geocoding service is ever needed.
abstract final class CityDirectory {
  static const List<PrayerLocation> cities = <PrayerLocation>[
    PrayerLocation(
      city: 'Makkah',
      country: 'Saudi Arabia',
      latitude: 21.4225,
      longitude: 39.8262,
    ),
    PrayerLocation(
      city: 'Madinah',
      country: 'Saudi Arabia',
      latitude: 24.4672,
      longitude: 39.6111,
    ),
    PrayerLocation(
      city: 'Riyadh',
      country: 'Saudi Arabia',
      latitude: 24.7136,
      longitude: 46.6753,
    ),
    PrayerLocation(
      city: 'Jeddah',
      country: 'Saudi Arabia',
      latitude: 21.4858,
      longitude: 39.1925,
    ),
    PrayerLocation(
      city: 'Dubai',
      country: 'UAE',
      latitude: 25.2048,
      longitude: 55.2708,
    ),
    PrayerLocation(
      city: 'Doha',
      country: 'Qatar',
      latitude: 25.2854,
      longitude: 51.5310,
    ),
    PrayerLocation(
      city: 'Kuwait City',
      country: 'Kuwait',
      latitude: 29.3759,
      longitude: 47.9774,
    ),
    PrayerLocation(
      city: 'Istanbul',
      country: 'Türkiye',
      latitude: 41.0082,
      longitude: 28.9784,
    ),
    PrayerLocation(
      city: 'Cairo',
      country: 'Egypt',
      latitude: 30.0444,
      longitude: 31.2357,
    ),
    PrayerLocation(
      city: 'Amman',
      country: 'Jordan',
      latitude: 31.9454,
      longitude: 35.9284,
    ),
    PrayerLocation(
      city: 'Karachi',
      country: 'Pakistan',
      latitude: 24.8607,
      longitude: 67.0011,
    ),
    PrayerLocation(
      city: 'Lahore',
      country: 'Pakistan',
      latitude: 31.5204,
      longitude: 74.3587,
    ),
    PrayerLocation(
      city: 'Dhaka',
      country: 'Bangladesh',
      latitude: 23.8103,
      longitude: 90.4125,
    ),
    PrayerLocation(
      city: 'Jakarta',
      country: 'Indonesia',
      latitude: -6.2088,
      longitude: 106.8456,
    ),
    PrayerLocation(
      city: 'Kuala Lumpur',
      country: 'Malaysia',
      latitude: 3.1390,
      longitude: 101.6869,
    ),
    PrayerLocation(
      city: 'London',
      country: 'United Kingdom',
      latitude: 51.5074,
      longitude: -0.1278,
    ),
    PrayerLocation(
      city: 'Birmingham',
      country: 'United Kingdom',
      latitude: 52.4862,
      longitude: -1.8904,
    ),
    PrayerLocation(
      city: 'Toronto',
      country: 'Canada',
      latitude: 43.6532,
      longitude: -79.3832,
    ),
    PrayerLocation(
      city: 'New York',
      country: 'United States',
      latitude: 40.7128,
      longitude: -74.0060,
    ),
    PrayerLocation(
      city: 'Chicago',
      country: 'United States',
      latitude: 41.8781,
      longitude: -87.6298,
    ),
    PrayerLocation(
      city: 'Los Angeles',
      country: 'United States',
      latitude: 34.0522,
      longitude: -118.2437,
    ),
    PrayerLocation(
      city: 'Sydney',
      country: 'Australia',
      latitude: -33.8688,
      longitude: 151.2093,
    ),
    PrayerLocation(
      city: 'Lagos',
      country: 'Nigeria',
      latitude: 6.5244,
      longitude: 3.3792,
    ),
    PrayerLocation(
      city: 'Nairobi',
      country: 'Kenya',
      latitude: -1.2921,
      longitude: 36.8219,
    ),
  ];
}
