/// Non-web stub: no sensor package is a dependency yet, so native builds
/// have no live compass (the static dial and sun method still work).
abstract final class DeviceHeading {
  /// Whether this platform can supply a live compass heading.
  static bool get isSupported => false;

  /// Ask for motion/orientation permission (iOS requires a user gesture).
  static Future<bool> requestPermission() async => false;

  /// Magnetic compass headings in degrees clockwise from magnetic north,
  /// where the top edge of the device points.
  static Stream<double> headings() => const Stream<double>.empty();
}
