import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Browser Notification API wrapper (web only). Every call is guarded —
/// permission prompts and Notification construction can throw in webviews.
class WebNotifier {
  static bool get isSupported {
    try {
      return web.Notification.permission.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> ensurePermission() async {
    try {
      if (web.Notification.permission == 'granted') return true;
      if (web.Notification.permission == 'denied') return false;
      final String result =
          (await web.Notification.requestPermission().toDart).toDart;
      return result == 'granted';
    } catch (_) {
      return false;
    }
  }

  static void show(String title, String body) {
    try {
      if (web.Notification.permission != 'granted') return;
      web.Notification(title, web.NotificationOptions(body: body));
    } catch (_) {
      // Silently skip — the in-app banner still carries the alert.
    }
  }
}
