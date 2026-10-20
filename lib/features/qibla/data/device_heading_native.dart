import 'dart:io' show Platform;

import 'package:flutter_compass/flutter_compass.dart';

import '../domain/compass_math.dart';

/// Live compass on the Android and iPhone apps, from the phone's own
/// magnetic sensors through `flutter_compass` 0.8.1. The heading is relative
/// to MAGNETIC north; the Qibla screen adds the declination.
///
/// Only Android and iOS use the plugin. Desktop builds and the test VM also
/// have `dart:io` but no sensor, so they report "not supported" instead of
/// calling a plugin that is not there.
abstract final class DeviceHeading {
  static bool get isSupported => Platform.isAndroid || Platform.isIOS;

  /// Neither platform needs a separate motion permission for the magnetic
  /// heading (the iOS location prompt is the prayer-location screen's).
  static Future<bool> requestPermission() async => isSupported;

  static Stream<double> headings() {
    if (!isSupported) return const Stream<double>.empty();
    final Stream<CompassEvent>? events = FlutterCompass.events;
    if (events == null) return const Stream<double>.empty();
    return events
        .handleError((Object _) {})
        .map<double?>((CompassEvent e) => e.heading)
        .where((double? h) => h != null)
        .map<double>((double? h) => CompassMath.normalize(h!));
  }
}
