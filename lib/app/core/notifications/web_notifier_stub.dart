/// Non-web stub — browser notifications don't exist off the web.
class WebNotifier {
  static Future<bool> ensurePermission() async => false;
  static void show(String title, String body) {}
  static bool get isSupported => false;
}
