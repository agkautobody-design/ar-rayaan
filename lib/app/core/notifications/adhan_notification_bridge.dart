import 'package:flutter/foundation.dart' show ValueNotifier, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Connects a tapped prayer notification to the full adhan inside the app.
///
/// The phone's own notification can only carry a short clip of the adhan
/// (the Android channel sound); the full recording plays here, when the person
/// opens the app from the notification. [WorshipBoot] listens to [tapped] and
/// starts the adhan service.
class AdhanNotificationBridge {
  /// Counts prayer-notification taps; listeners play the adhan on change.
  static final ValueNotifier<int> tapped = ValueNotifier<int>(0);

  /// True when [payload] belongs to a prayer-time notification.
  static bool isPrayerPayload(String? payload) =>
      payload != null &&
      (payload.startsWith('prayer_') || payload.startsWith('adhan_'));

  /// Handler given to the notification plugin at initialisation (the same one
  /// everywhere, so a second initialisation never drops it).
  static void onResponse(NotificationResponse response) {
    if (isPrayerPayload(response.payload)) tapped.value++;
  }

  /// Kept for the boot sequence; the scheduler registers [onResponse] itself.
  static void register() {
    if (kIsWeb) return;
  }
}
