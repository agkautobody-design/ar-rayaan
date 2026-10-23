/// The two things the counter needs from the phone, each behind an interface
/// so tests and the web build never touch a platform channel:
///
///  * [VolumeCounterChannel] counts with the volume / headset buttons while
///    the screen is off. Android only: a foreground service holds a media
///    session so the system routes those buttons to the app. iOS forbids
///    this and a web page is suspended with the screen, so there the
///    channel reports `isSupported == false`.
///  * [ScreenAwake] keeps the screen on (wakelock_plus) as the alternative
///    where counting with the screen off is not possible.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../domain/tasbeeh_counter.dart';

abstract class VolumeCounterChannel {
  /// True only on an Android build.
  bool get isSupported;

  /// A bare signal: "buttons were pressed, call [takePendingDelta]".
  Stream<void> get pings;

  /// Starts the background service (or refreshes it when already running)
  /// with the counter as it is now. False when it could not start.
  Future<bool> start(TasbeehState state);

  /// Tells the running service the counter changed on screen, so its
  /// notification shows the same number.
  Future<void> update(TasbeehState state);

  /// Stops the service and removes its notification.
  Future<void> stop();

  /// Net button presses (+1 volume up / headset, -1 volume down) since the
  /// last call. Reading it clears it.
  Future<int> takePendingDelta();
}

/// iOS, web, desktop: nothing to start.
class UnsupportedVolumeCounterChannel implements VolumeCounterChannel {
  const UnsupportedVolumeCounterChannel();

  @override
  bool get isSupported => false;

  @override
  Stream<void> get pings => const Stream<void>.empty();

  @override
  Future<bool> start(TasbeehState state) async => false;

  @override
  Future<void> update(TasbeehState state) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<int> takePendingDelta() async => 0;
}

/// Android: talks to TasbeehService through MainActivity.
class AndroidVolumeCounterChannel implements VolumeCounterChannel {
  AndroidVolumeCounterChannel();

  static const MethodChannel _method = MethodChannel('app.arrayaan/tasbeeh');
  static const EventChannel _events = EventChannel(
    'app.arrayaan/tasbeeh/events',
  );

  Stream<void>? _pings;

  @override
  bool get isSupported => true;

  @override
  Stream<void> get pings => _pings ??= _events
      .receiveBroadcastStream()
      .map<void>((dynamic _) {})
      .handleError((Object _) {});

  Map<String, int> _args(TasbeehState s) => <String, int>{
    'count': s.count,
    'rounds': s.rounds,
    'target': s.target,
  };

  @override
  Future<bool> start(TasbeehState state) async {
    try {
      return (await _method.invokeMethod<bool>('start', _args(state))) ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> update(TasbeehState state) async {
    try {
      await _method.invokeMethod<void>('update', _args(state));
    } catch (_) {
      // The service is not running: nothing to refresh.
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _method.invokeMethod<void>('stop');
    } catch (_) {
      // Already stopped.
    }
  }

  @override
  Future<int> takePendingDelta() async {
    try {
      return (await _method.invokeMethod<int>('takePendingDelta')) ?? 0;
    } catch (_) {
      return 0;
    }
  }
}

/// The right channel for this build. Web and every non-Android platform get
/// the inert one, so tests and web builds never reach a MethodChannel.
VolumeCounterChannel createVolumeCounterChannel() {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return const UnsupportedVolumeCounterChannel();
  }
  return AndroidVolumeCounterChannel();
}

/// Keeps the screen on while counting.
abstract class ScreenAwake {
  Future<void> set({required bool on});
}

class WakelockScreenAwake implements ScreenAwake {
  const WakelockScreenAwake();

  @override
  Future<void> set({required bool on}) async {
    try {
      if (on) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (_) {
      // Best effort: some browsers and test hosts have no wake lock.
    }
  }
}
