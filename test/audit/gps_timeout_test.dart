import 'dart:async';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/prayer/application/location_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "My location" must never wait forever: a browser permission prompt that
/// is closed without an answer (or a device with no fix) used to leave
/// "Locating..." on screen with the button disabled for good.
void main() {
  test('a location request that never answers ends as an error', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(c.dispose);
    final PrayerLocationController ctl =
        c.read(prayerLocationControllerProvider.notifier);
    final Completer<({double lat, double lng})> never =
        Completer<({double lat, double lng})>();
    final GpsStatus status = await ctl.useGps(
      fetch: () => never.future,
      timeout: const Duration(milliseconds: 30),
    );
    expect(status, GpsStatus.error);
    expect(c.read(prayerLocationControllerProvider).isSet, isFalse,
        reason: 'no place is invented when the request times out');
    expect(ctl.gpsStatus, isNot(GpsStatus.locating));
  });
}
