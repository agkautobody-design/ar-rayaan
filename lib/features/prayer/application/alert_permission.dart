import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/notifications/prayer_notification_scheduler.dart';
import '../../../app/core/notifications/web_notifier.dart';

/// Asks for notification permission (the browser's, or the phone's) and
/// returns one honest sentence about what will happen. [on] is the opening
/// clause, for example "Maghrib alert is on". Used by the prayer bells and by
/// the invitation on Home, so both say the same true thing.
Future<String> askAlertPermission(WidgetRef ref, String on) async {
  final PrayerNotificationScheduler scheduler = ref.read(
    prayerNotificationSchedulerProvider,
  );
  final bool browserOk = await WebNotifier.ensurePermission();
  if (scheduler.supported) {
    final bool ok = await scheduler.requestPermission();
    return ok
        ? '$on. It rings even when the app is closed.'
        : '$on, but notifications are blocked for Ar-Rayaan. Allow them in '
              'your phone’s settings.';
  }
  return browserOk
      ? '$on. In a browser it rings only while this page is open; the '
            'Android and iPhone apps ring when closed.'
      : '$on. Your browser is blocking notifications, so you get the banner '
            'and adhan only while this page is open.';
}
