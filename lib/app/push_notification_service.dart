import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Handles Firebase Cloud Messaging for prayer reminders,
/// daily hadith, and academy notifications.
class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // FCM web push is not configured (no VAPID key, no
    // firebase-messaging-sw.js): getToken() throws in the browser, and a
    // person who once allowed notifications would otherwise be stuck on the
    // startup-error screen. Skip until web push is set up deliberately.
    if (kIsWeb) return;

    // Request permission (iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM token for targeting
      final token = await _messaging.getToken();
      debugPrint('FCM Token: $token');

      // Store token in user profile for targeted notifications
      // TODO: Send to backend when user is authenticated

      // Foreground message handler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Background/terminated handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    // Show local notification or in-app banner
    // TODO: Integrate with flutter_local_notifications
  }

  /// Subscribe to topic for daily hadith
  static Future<void> subscribeToDailyHadith() async {
    if (kIsWeb) return; // FCM web push is not configured (see initialize)
    await _messaging.subscribeToTopic('daily_hadith');
  }

  /// Subscribe to topic for prayer reminders
  static Future<void> subscribeToPrayerReminders() async {
    if (kIsWeb) return; // FCM web push is not configured (see initialize)
    await _messaging.subscribeToTopic('prayer_reminders');
  }

  /// Unsubscribe from all topics
  static Future<void> unsubscribeAll() async {
    if (kIsWeb) return; // FCM web push is not configured (see initialize)
    await _messaging.unsubscribeFromTopic('daily_hadith');
    await _messaging.unsubscribeFromTopic('prayer_reminders');
  }
}

/// Background message handler (must be top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.notification?.title}');
}
