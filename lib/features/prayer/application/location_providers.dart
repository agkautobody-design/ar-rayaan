import 'dart:math' as math;

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
        final String city = prefs.getString(_cityKey) ?? PrayerLocation.gpsCity;
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
    Duration timeout = kGpsTimeout,
  }) async {
    gpsStatus = GpsStatus.locating;
    state = state; // poke listeners
    try {
      // A browser permission prompt that is closed without an answer, or a
      // device that never gets a fix, would leave "Locating..." (and a
      // disabled button) on screen for good. Give up after a while and say so.
      final ({double lat, double lng}) pos =
          await (fetch ?? _deviceGps)().timeout(timeout);
      final PrayerLocation before = state;
      // A place the person named stays named while the new fix is still
      // within a few kilometres of it.
      final bool keepName = before.isSet &&
          !before.isGps &&
          before.zone == null &&
          _kmBetween(before.latitude, before.longitude, pos.lat, pos.lng) <
              kSamePlaceKm;
      final PrayerLocation loc = PrayerLocation(
        city: keepName ? before.city : PrayerLocation.gpsCity,
        country: keepName ? before.country : '',
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

  /// A new fix this close to a named place is the same place.
  static const double kSamePlaceKm = 8;

  static double _kmBetween(double la1, double lo1, double la2, double lo2) {
    const double rad = 3.141592653589793 / 180;
    final double dLat = (la2 - la1) * rad;
    final double dLon = (lo2 - lo1) * rad * math.cos((la1 + la2) / 2 * rad);
    return 6371 * math.sqrt(dLat * dLat + dLon * dLon);
  }

  /// Cleans a typed place name: no control characters, one space between
  /// words, at most [maxNameLength] characters.
  static String cleanName(String raw) {
    final String s = raw
        .replaceAll(RegExp(r'[\u0000-\u001F\u007F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return s.length > maxNameLength ? s.substring(0, maxNameLength).trim() : s;
  }

  static const int maxNameLength = 60;

  /// Saves the person's own place name for where they are. A city that is
  /// not in the directory is named here: the position comes from the device
  /// (a fresh fix unless the saved one is already a GPS fix or a named
  /// place), the time zone stays the device's, and the name and country are
  /// stored and kept. Returns [GpsStatus.success] when saved; any other
  /// status means nothing was changed.
  Future<GpsStatus> saveNamedPlace(
    String city,
    String country, {
    Future<({double lat, double lng})> Function()? fetch,
  }) async {
    final String name = cleanName(city);
    if (name.isEmpty) return GpsStatus.error;
    final PrayerLocation cur = state;
    final bool haveDevicePlace = cur.isSet && cur.zone == null;
    if (!haveDevicePlace) {
      final GpsStatus got = await useGps(fetch: fetch);
      if (got != GpsStatus.success) return got;
    }
    final PrayerLocation now = state;
    final PrayerLocation named = PrayerLocation(
      city: name,
      country: cleanName(country),
      latitude: now.latitude,
      longitude: now.longitude,
    );
    gpsStatus = GpsStatus.success;
    state = named;
    await _persist(named);
    return GpsStatus.success;
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

/// How long "My location" waits for the permission answer and a fix.
const Duration kGpsTimeout = Duration(seconds: 25);

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
