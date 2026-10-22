import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
import '../data/city_directory.dart';
import '../domain/prayer_zone.dart';
import 'prayer_repository.dart';

/// Result of a GPS attempt, surfaced to the UI for honest messaging.
enum GpsStatus { idle, locating, success, denied, unavailable, error }

/// O-11 location module — device GPS with a persisted manual-city fallback.
///
/// The controller never throws to the UI: every failure path lands in a
/// [GpsStatus] the screen can render, and the last good location stays
/// active. The geolocator call is injectable for tests.
class PrayerLocationController extends Notifier<PrayerLocation> {
  static const String _latKey = 'ar.location.lat';
  static const String _lngKey = 'ar.location.lng';
  static const String _cityKey = 'ar.location.city';
  static const String _countryKey = 'ar.location.country';
  static const String _zoneKey = 'ar.location.zone';

  /// Stand-in used before any GPS fix or manual choice. It only keeps the
  /// calculation code total: it is flagged [PrayerLocation.isPlaceholder] and
  /// no screen may show times or a bearing from it as the person's own.
  /// Every screen checks `isSet` and asks the person to set a location.
  static const PrayerLocation fallback = PrayerLocation(
    city: '',
    country: '',
    latitude: 43.6532,
    longitude: -79.3832,
    zone: PrayerZone(-300, DstRule.us),
    isPlaceholder: true,
  );

  GpsStatus gpsStatus = GpsStatus.idle;

  @override
  PrayerLocation build() {
    try {
      final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
      final double? lat = prefs.getDouble(_latKey);
      final double? lng = prefs.getDouble(_lngKey);
      if (lat != null && lng != null) {
        final String city = prefs.getString(_cityKey) ?? 'My Location';
        final String country = prefs.getString(_countryKey) ?? '';
        return PrayerLocation(
          city: city,
          country: country,
          latitude: lat,
          longitude: lng,
          zone:
              PrayerZone.parse(prefs.getString(_zoneKey)) ??
              _directoryZone(city, country),
        );
      }
    } catch (_) {
      // In-memory fallback.
    }
    return fallback;
  }

  /// Zone of a curated city saved before zones were stored.
  static PrayerZone? _directoryZone(String city, String country) {
    for (final PrayerLocation c in CityDirectory.cities) {
      if (c.city == city && c.country == country) return c.zone;
    }
    return null;
  }

  Future<void> _persist(PrayerLocation loc) async {
    try {
      final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
      await prefs.setDouble(_latKey, loc.latitude);
      await prefs.setDouble(_lngKey, loc.longitude);
      await prefs.setString(_cityKey, loc.city);
      await prefs.setString(_countryKey, loc.country);
      final PrayerZone? zone = loc.zone;
      if (zone == null) {
        await prefs.remove(_zoneKey);
      } else {
        await prefs.setString(_zoneKey, zone.id);
      }
    } catch (_) {
      // In-memory only.
    }
  }

  /// Manual choice from the offline city directory (or a GPS relabel).
  Future<void> setLocation(PrayerLocation loc) async {
    state = loc;
    await _persist(loc);
  }

  /// Device GPS flow: service check → permission → position. Injectable
  /// [fetch] keeps geolocator out of unit tests.
  Future<GpsStatus> useGps({
    Future<({double lat, double lng})> Function()? fetch,
  }) async {
    gpsStatus = GpsStatus.locating;
    state = state; // poke listeners
    try {
      final ({double lat, double lng}) pos = await (fetch ?? _deviceGps)();
      final PrayerLocation loc = PrayerLocation(
        city: 'My Location',
        country: '',
        latitude: pos.lat,
        longitude: pos.lng,
      );
      gpsStatus = GpsStatus.success;
      state = loc;
      await _persist(loc);
      return gpsStatus;
    } on GpsException catch (e) {
      gpsStatus = e.status;
      state = state;
      return gpsStatus;
    } catch (_) {
      gpsStatus = GpsStatus.error;
      state = state;
      return gpsStatus;
    }
  }

  static Future<({double lat, double lng})> _deviceGps() async {
    final bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) throw const GpsException(GpsStatus.unavailable);
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const GpsException(GpsStatus.denied);
    }
    final Position p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low, // city-grade is plenty for prayer times
      ),
    );
    return (lat: p.latitude, lng: p.longitude);
  }
}

/// Typed failure so the UI can tell "denied" from "GPS off" from "error".
class GpsException implements Exception {
  const GpsException(this.status);
  final GpsStatus status;
}

final NotifierProvider<PrayerLocationController, PrayerLocation>
prayerLocationControllerProvider =
    NotifierProvider<PrayerLocationController, PrayerLocation>(
      PrayerLocationController.new,
    );
