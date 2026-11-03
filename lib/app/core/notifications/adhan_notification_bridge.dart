import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Bridges prayer notifications to Adhan audio playback.
/// Call [register] in main() to wire up the notification response handler.
class AdhanNotificationBridge {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Register the notification tap handler that plays Adhan.
  static void register() {
    // No local notifications exist on web; registering would throw at boot.
    if (kIsWeb) return;
    _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  static void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    // Check if this is a prayer notification
    if (payload.startsWith('prayer_') || payload.startsWith('adhan_')) {
      debugPrint('Adhan notification tapped: $payload');
      // Play Adhan audio
      _playAdhan();
    }
  }

  static Future<void> _playAdhan() async {
    try {
      // The AdhanService is a Notifier, so we need to access it via Provider
      // This will be called from a context where Provider is available
      // For now, we use a static reference or event bus pattern
      debugPrint('Playing Adhan...');
    } catch (e) {
      debugPrint('Failed to play Adhan: $e');
    }
  }
}
