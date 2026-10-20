import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  /// Stable id (yyyymmdd * 10 + prayer index), so re-planning replaces
  /// rather than duplicates.
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

/// Seam for OS-level prayer notifications.
///
/// The app plans the next days of notifications (see
/// `planPrayerNotifications` in the prayer feature) and hands the whole plan
/// to a scheduler, which must make the OS hold exactly that set (cancelling
/// anything it scheduled before). The default is [NoopPrayerNotificationScheduler]
/// because no notification plugin is a dependency yet; a real implementation
/// (for example on `flutter_local_notifications` with the `timezone`
/// package, exact alarms on Android and the notification entitlement on iOS)
/// only has to implement this interface and override
/// [prayerNotificationSchedulerProvider]. No call site changes.
abstract interface class PrayerNotificationScheduler {
  /// False when this platform cannot deliver notifications while the app is
  /// closed; the app then keeps its in-app alerts only.
  bool get supported;

  /// Ask the user for notification permission. Returns whether granted.
  Future<bool> requestPermission();

  /// Make the OS hold exactly [plan], cancelling every earlier plan.
  Future<void> replaceAll(List<PlannedPrayerNotification> plan);
}

/// Does nothing; used until a platform implementation is provided.
class NoopPrayerNotificationScheduler implements PrayerNotificationScheduler {
  const NoopPrayerNotificationScheduler();

  @override
  bool get supported => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> replaceAll(List<PlannedPrayerNotification> plan) async {}
}

final Provider<PrayerNotificationScheduler>
prayerNotificationSchedulerProvider = Provider<PrayerNotificationScheduler>(
  (ref) => const NoopPrayerNotificationScheduler(),
);
