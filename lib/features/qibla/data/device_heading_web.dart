import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../domain/compass_math.dart';

/// The browser's orientation event (read-only view of the fields we use).
extension type _OrientationEvent._(JSObject _) implements JSObject {
  external JSNumber? get alpha;
  external JSNumber? get beta;
  external JSNumber? get gamma;
  external JSBoolean? get absolute;

  /// iOS Safari only: magnetic heading, already tilt-compensated.
  external JSNumber? get webkitCompassHeading;
}

/// iOS 13+ gates motion sensors behind this static call; elsewhere it does
/// not exist and calling it throws.
@JS('DeviceOrientationEvent.requestPermission')
external JSPromise<JSString> _requestOrientationPermission();

/// Live compass for browsers on phones (the PWA). Android Chrome delivers
/// absolute orientation via `deviceorientationabsolute`; iOS Safari delivers
/// `webkitCompassHeading`. Needs a secure context (https) and, on iOS, a
/// permission prompt triggered by a tap.
abstract final class DeviceHeading {
  static bool get isSupported => true;

  static Future<bool> requestPermission() async {
    try {
      final String result = (await _requestOrientationPermission().toDart)
          .toDart;
      return result == 'granted';
    } catch (_) {
      // No permission API (Android, desktop): nothing to ask for.
      return true;
    }
  }

  static Stream<double> headings() {
    late final StreamController<double> controller;
    JSFunction? listener;

    void onEvent(web.Event event) {
      try {
        final _OrientationEvent e = _OrientationEvent._(event);
        final double? ios = e.webkitCompassHeading?.toDartDouble;
        if (ios != null) {
          controller.add(CompassMath.normalize(ios));
          return;
        }
        final bool absolute =
            event.type == 'deviceorientationabsolute' ||
            (e.absolute?.toDart ?? false);
        if (!absolute) return; // relative alpha is not a compass
        final double? alpha = e.alpha?.toDartDouble;
        if (alpha == null) return;
        controller.add(
          CompassMath.headingFromOrientation(
            alpha: alpha,
            beta: e.beta?.toDartDouble ?? 0,
            gamma: e.gamma?.toDartDouble ?? 0,
          ),
        );
      } catch (_) {
        // Ignore a malformed event.
      }
    }

    controller = StreamController<double>(
      onListen: () {
        final JSFunction fn = onEvent.toJS;
        listener = fn;
        web.window.addEventListener('deviceorientationabsolute', fn);
        web.window.addEventListener('deviceorientation', fn);
      },
      onCancel: () {
        final JSFunction? fn = listener;
        if (fn != null) {
          web.window.removeEventListener('deviceorientationabsolute', fn);
          web.window.removeEventListener('deviceorientation', fn);
        }
        listener = null;
      },
    );
    return controller.stream;
  }
}
