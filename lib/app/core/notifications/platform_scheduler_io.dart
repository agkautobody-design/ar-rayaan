import 'dart:io' show Platform;

import 'local_notifications_scheduler.dart';
import 'prayer_notification_scheduler.dart';

/// Native build. Only Android and iOS get the real scheduler; desktop and the
/// test VM (which also have `dart:io`) stay on the no-op so no plugin channel
/// is ever called where it has no implementation.
PrayerNotificationScheduler createPlatformScheduler() {
  if (Platform.isAndroid || Platform.isIOS) {
    return LocalNotificationsScheduler();
  }
  return const NoopPrayerNotificationScheduler();
}
