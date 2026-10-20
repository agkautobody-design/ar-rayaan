import 'prayer_notification_scheduler.dart';

/// Web build: no plugin is imported at all. The browser keeps the in-app
/// alert and the Notification API wrapper in `web_notifier_web.dart`.
PrayerNotificationScheduler createPlatformScheduler() =>
    const NoopPrayerNotificationScheduler();
