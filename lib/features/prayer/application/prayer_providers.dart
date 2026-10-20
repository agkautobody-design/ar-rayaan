import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/adhan_calc_prayer_repository.dart';
import '../domain/prayer_times.dart';
import '../domain/prayer_zone.dart';
import 'location_providers.dart';
import 'prayer_repository.dart';
import 'prayer_settings.dart';

/// Active location for prayer times — device GPS or manual city (O-11),
/// persisted by the controller.
final Provider<PrayerLocation> prayerLocationProvider =
    Provider<PrayerLocation>(
      (ref) => ref.watch(prayerLocationControllerProvider),
    );

/// Data source (O-11): fully offline astronomical calculation — the
/// batoulapps adhan math running on-device for every flavor. No network,
/// no rate limits, location never leaves the device.
final Provider<PrayerRepository> prayerRepositoryProvider =
    Provider<PrayerRepository>((ref) => AdhanCalcPrayerRepository(
          settings: ref.watch(prayerSettingsProvider),
        ));

/// The civil day ("y-m-d") in the ACTIVE LOCATION's zone. It changes at that
/// zone's midnight, and everything that is per-day (the schedule, fired
/// alerts, notification plans) depends on it so it refreshes by itself.
/// Only a changed string notifies dependents, so the 30 s ticker does not
/// cause rebuild storms.
final Provider<String> prayerDayKeyProvider = Provider<String>((ref) {
  final PrayerLocation loc = ref.watch(prayerLocationProvider);
  final DateTime now = ref.watch(
    nowTickerProvider.select(
      (AsyncValue<DateTime> v) => v.valueOrNull ?? DateTime.now(),
    ),
  );
  final DateTime w = PrayerZone.wallClock(loc.zone, now);
  return '${w.year}-${w.month}-${w.day}';
});

/// Today's schedule for the active location. Re-computed when the location,
/// the settings or the calendar day (in the location's zone) change, so an
/// app left open past midnight shows the new day's times.
final FutureProvider<PrayerTimes> prayerTimesProvider =
    FutureProvider<PrayerTimes>((ref) {
      ref.watch(prayerDayKeyProvider);
      return ref
          .watch(prayerRepositoryProvider)
          .timingsForToday(ref.watch(prayerLocationProvider));
    });

/// Ticks every 30s so the countdown text stays fresh without rebuild storms.
final StreamProvider<DateTime> nowTickerProvider = StreamProvider<DateTime>((
  ref,
) async* {
  yield DateTime.now();
  yield* Stream<DateTime>.periodic(
    const Duration(seconds: 30),
    (_) => DateTime.now(),
  );
});
