import 'dart:async';

import 'package:ar_rayaan/features/tasbeeh/data/tasbeeh_platform.dart';
import 'package:ar_rayaan/features/tasbeeh/domain/tasbeeh_counter.dart';

/// Stands in for the Android service: no platform channel is touched.
class FakeVolumeCounterChannel implements VolumeCounterChannel {
  FakeVolumeCounterChannel({this.supported = true, this.startResult = true});

  final bool supported;
  bool startResult;

  bool running = false;
  int startCalls = 0;
  int stopCalls = 0;
  int pending = 0;
  TasbeehState? lastBase;
  final List<TasbeehState> updates = <TasbeehState>[];
  final StreamController<void> _pings = StreamController<void>.broadcast();

  @override
  bool get isSupported => supported;

  @override
  Stream<void> get pings => _pings.stream;

  @override
  Future<bool> start(TasbeehState state) async {
    startCalls++;
    if (!startResult) return false;
    running = true;
    lastBase = state;
    return true;
  }

  @override
  Future<void> update(TasbeehState state) async {
    updates.add(state);
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    running = false;
  }

  @override
  Future<int> takePendingDelta() async {
    final int d = pending;
    pending = 0;
    return d;
  }

  /// A hardware press while the screen is off: +1 or -1.
  void press(int delta, {bool ping = true}) {
    pending += delta;
    if (ping) _pings.add(null);
  }
}

class FakeScreenAwake implements ScreenAwake {
  final List<bool> calls = <bool>[];

  @override
  Future<void> set({required bool on}) async {
    calls.add(on);
  }
}
