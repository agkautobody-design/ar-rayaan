import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'platform_scheduler.dart';

/// Notification ids below this value belong to the prayer plan; ids at or
/// above it belong to reminders (hawl, Zakat al-Fitr, Academy). All stay
/// under the 32-bit limit Android and iOS accept. Each `replace*` call
/// cancels and replaces only its own range.
const int kReminderIdBase = 1500000000;

/// Academy reminders (the daily lesson, lessons to revisit) sit in their own
/// block of 1000 ids above the zakat reminders, so the two never cancel each
/// other: [kReminderIdBase] up to here is zakat.
const int kAcademyReminderIdBase = kReminderIdBase + 1000;

/// Lead-time notifications ("Asr in 15 minutes") sit above the exact-time
/// ones so the two never share an id.
const int kLeadIdOffset = 1000000000;

/// One prayer notification to be delivered by the operating system at a
/// fixed moment, even when the app is closed.
class PlannedPrayerNotification {
  const PlannedPrayerNotification({
    required this.id,
    required this.prayer,
    required this.at,
    required this.title,
    required this.body,
  });

  /// Stable id (yyyymmdd * 10 + prayer index, plus [kLeadIdOffset] for a
  /// lead-time notification), so re-planning replaces rather than
  /// duplicates.
  final int id;

  /// 'Fajr' | 'Dhuhr' | 'Asr' | 'Maghrib' | 'Isha'.
  final String prayer;

  /// The real instant (UTC) to deliver at.
  final DateTime at;
  final String title;
  final String body;

  @override
  String toString() => 'PlannedPrayerNotification($id, $prayer, $at)';
}

/// A one-off dated reminder that is not a prayer time (the hawl year ending,
/// Zakat al-Fitr before Eid). Ids are in the reminder range.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
  });

  /// At least [kReminderIdBase].
  final int id;

  /// The real instant (UTC) to deliver at.
  final DateTime at;
  final String title;
  final String body;

  @override
  String toString() => 'PlannedReminder($id, $at)';
}

/// Whether the operating system lets the app fire at an exact minute.
enum ExactAlarmStatus {
  /// This platform has no separate exact-alarm permission (iOS).
  notNeeded,

  /// Android: the user allowed "Alarms and reminders".
  granted,

  /// Android 12+: not allowed; notifications fall back to inexact timing and
  /// can arrive minutes late until the user allows it.
  denied,

  /// Could not be determined.
  unknown,
}

/// Seam for OS-level prayer notifications.
///
/// The app plans the next days of notifications (see
/// `planPrayerNotifications` in the prayer feature) and hands the whole plan
/// to a scheduler, which must make the OS hold exactly that set (cancelling
/// anything it scheduled before). The platform implementation lives behind a
/// conditional import (`platform_scheduler.dart`): Android and iOS use
/// `flutter_local_notifications`; the web, desktop and the test VM get
/// [NoopPrayerNotificationScheduler], so the web build never touches the
/// plugin. Call sites do not change.
abstract interface class PrayerNotificationScheduler {
  /// False when this platform cannot deliver notifications while the app is
  /// closed; the app then keeps its in-app alerts only.
  bool get supported;

  /// Ask the user for notification permission. Returns whether granted.
  Future<bool> requestPermission();

  /// Android exact-alarm state (always [ExactAlarmStatus.notNeeded] on iOS).
  Future<ExactAlarmStatus> exactAlarmStatus();

  /// Open the system screen where the user allows exact alarms (Android
  /// "Alarms and reminders"). A no-op elsewhere.
  Future<void> openExactAlarmSettings();

  /// Make the OS hold exactly [plan] among the prayer notifications
  /// (ids below [kReminderIdBase]), cancelling every earlier prayer plan.
  Future<void> replaceAll(List<PlannedPrayerNotification> plan);

  /// Make the OS hold exactly [reminders] among the zakat reminder range
  /// (ids from [kReminderIdBase] up to [kAcademyReminderIdBase]), leaving the
  /// prayer plan and the Academy reminders untouched.
  Future<void> replaceReminders(List<PlannedReminder> reminders);

  /// Make the OS hold exactly [reminders] among the Academy reminder range
  /// (ids from [kAcademyReminderIdBase] up), leaving everything else
  /// untouched.
  Future<void> replaceAcademyReminders(List<PlannedReminder> reminders);
}

/// Does nothing; used on the web, desktop and in tests.
class NoopPrayerNotificationScheduler implements PrayerNotificationScheduler {
  const NoopPrayerNotificationScheduler();

  @override
  bool get supported => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<ExactAlarmStatus> exactAlarmStatus() async =>
      ExactAlarmStatus.notNeeded;

  @override
  Future<void> openExactAlarmSettings() async {}

  @override
  Future<void> replaceAll(List<PlannedPrayerNotification> plan) async {}

  @override
  Future<void> replaceReminders(List<PlannedReminder> reminders) async {}

  @override
  Future<void> replaceAcademyReminders(
    List<PlannedReminder> reminders,
  ) async {}
}

final Provider<PrayerNotificationScheduler>
prayerNotificationSchedulerProvider = Provider<PrayerNotificationScheduler>(
  (ref) => createPlatformScheduler(),
);
