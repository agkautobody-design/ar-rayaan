import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/notifications/notification_ids.dart';
import '../../../app/core/notifications/prayer_notification_scheduler.dart';
import '../../calendar/application/hijri_settings.dart';
import '../data/adhan_calc_prayer_repository.dart';
import '../domain/prayer_times.dart';
import '../domain/prayer_zone.dart';
import 'prayer_alerts.dart';
import 'prayer_providers.dart';
import 'prayer_repository.dart';
import 'prayer_settings.dart';

/// Order used for notification ids.
const List<String> _kPrayerOrder = <String>[
  'Fajr',
  'Dhuhr',
  'Asr',
  'Maghrib',
  'Isha',
];

/// The notifications to hand to the OS: for each of the next [days] civil
/// days in the location's zone, one per enabled prayer whose time is still
/// in the future at [now]. Pure and fully offline (the calculation is the
/// same on-device math as the Prayer Times screen, including the user's
/// method, minute offsets and high-latitude rule).
///
/// With [leadMinutes] above zero, each enabled prayer also gets an earlier
/// "Asr in 15 minutes" notification. The result is the soonest
/// [maxCount] entries in time order (iOS holds at most 64 pending local
/// notifications; the plan is rebuilt on every launch, resume and change, so
/// the window rolls forward).
///
/// Lock-screen privacy: the text carries the prayer name and the app name
/// only, never the place.
List<PlannedPrayerNotification> planPrayerNotifications({
  required PrayerLocation location,
  required PrayerSettings settings,
  required Set<String> enabled,
  required DateTime now,
  int days = 7,
  int leadMinutes = 0,
  int maxCount = kMaxPrayerNotifications,
}) {
  if (enabled.isEmpty) return <PlannedPrayerNotification>[];
  final AdhanCalcPrayerRepository repo = AdhanCalcPrayerRepository(
    settings: settings,
  );
  final DateTime today = PrayerZone.wallClock(location.zone, now);
  final List<PlannedPrayerNotification> plan = <PlannedPrayerNotification>[];
  for (int i = 0; i < days; i++) {
    // Local noon of day i, as a real instant.
    final DateTime noon = PrayerZone.instantOf(
      location.zone,
      DateTime(today.year, today.month, today.day + i, 12),
    );
    final PrayerTimes t = repo.timingsAt(location, noon);
    final int dayCode = t.fajr.year * 10000 + t.fajr.month * 100 + t.fajr.day;
    for (final (String name, DateTime wall) in t.prayers) {
      if (!enabled.contains(name)) continue;
      final DateTime at = PrayerZone.instantOf(location.zone, wall);
      final int id = dayCode * 10 + _kPrayerOrder.indexOf(name);
      if (at.isAfter(now.toUtc())) {
        plan.add(
          PlannedPrayerNotification(
            id: id,
            prayer: name,
            at: at,
            title: 'It is now $name time',
            body: 'Ar-Rayaan',
          ),
        );
      }
      if (leadMinutes > 0) {
        final DateTime early = at.subtract(Duration(minutes: leadMinutes));
        if (early.isAfter(now.toUtc())) {
          plan.add(
            PlannedPrayerNotification(
              id: kLeadIdOffset + id,
              prayer: name,
              at: early,
              title: '$name in $leadMinutes minutes',
              body: 'Ar-Rayaan',
            ),
          );
        }
      }
    }
  }
  plan.sort(
    (PlannedPrayerNotification a, PlannedPrayerNotification b) =>
        a.at.compareTo(b.at),
  );
  return plan.length <= maxCount ? plan : plan.sublist(0, maxCount);
}

/// Keeps the OS notification plan in step with the alert toggles, the
/// location, the calculation settings, the lead time and the calendar day
/// (so the horizon rolls forward every day). A no-op on platforms whose
/// scheduler is unsupported (web, desktop, tests); the app shell
/// (`WorshipBoot`) keeps it alive from launch and re-runs it on resume.
final Provider<void> prayerNotificationSyncProvider = Provider<void>((ref) {
  final PrayerNotificationScheduler scheduler = ref.watch(
    prayerNotificationSchedulerProvider,
  );
  if (!scheduler.supported) return;
  final Set<String> enabled = ref.watch(prayerAlertsProvider);
  final PrayerLocation location = ref.watch(prayerLocationProvider);
  final PrayerSettings settings = ref.watch(prayerSettingsProvider);
  final int lead = ref.watch(notificationLeadProvider);
  // Date arithmetic below also depends on the Hijri choice (the Umm al-Qura
  // Ramadan Isha rule), so re-plan when it changes.
  ref.watch(hijriSettingsProvider);
  ref.watch(prayerDayKeyProvider);
  unawaited(
    scheduler.replaceAll(
      planPrayerNotifications(
        location: location,
        settings: settings,
        enabled: enabled,
        now: DateTime.now(),
        leadMinutes: lead,
      ),
    ),
  );
});
