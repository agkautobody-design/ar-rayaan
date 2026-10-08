import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/adhan_calc_prayer_repository.dart';
import '../domain/prayer_times.dart';
import 'location_providers.dart';
import 'prayer_repository.dart';

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
    Provider<PrayerRepository>((ref) => AdhanCalcPrayerRepository());

/// Today's schedule for the active location.
final FutureProvider<PrayerTimes> prayerTimesProvider =
    FutureProvider<PrayerTimes>((ref) {
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
