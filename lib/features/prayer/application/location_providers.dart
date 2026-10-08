import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
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

  /// Default before any GPS fix or manual choice (previous behaviour).
  static const PrayerLocation fallback = PrayerLocation(
    city: 'Toronto',
    country: 'Canada',
    latitude: 43.6532,
    longitude: -79.3832,
  );

  GpsStatus gpsStatus = GpsStatus.idle;

  @override
  PrayerLocation build() {
    try {
      final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
      final double? lat = prefs.getDouble(_latKey);
      final double? lng = prefs.getDouble(_lngKey);
      if (lat != null && lng != null) {
        return PrayerLocation(
          city: prefs.getString(_cityKey) ?? 'My Location',
          country: prefs.getString(_countryKey) ?? '',
          latitude: lat,
          longitude: lng,
        );
      }
    } catch (_) {
      // In-memory fallback.
    }
    return fallback;
  }

  Future<void> _persist(PrayerLocation loc) async {
    try {
      final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
      await prefs.setDouble(_latKey, loc.latitude);
      await prefs.setDouble(_lngKey, loc.longitude);
      await prefs.setString(_cityKey, loc.city);
      await prefs.setString(_countryKey, loc.country);
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
