import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/providers.dart';
import '../data/tasbeeh_platform.dart';
import '../data/tasbeeh_store.dart';
import '../domain/tasbeeh_counter.dart';

/// Overridden with a fake in tests.
final Provider<VolumeCounterChannel> volumeCounterChannelProvider =
    Provider<VolumeCounterChannel>((ref) => createVolumeCounterChannel());

/// Overridden with a fake in tests.
final Provider<ScreenAwake> screenAwakeProvider = Provider<ScreenAwake>(
  (ref) => const WakelockScreenAwake(),
);

class TasbeehViewState {
  const TasbeehViewState({
    required this.counter,
    this.volumeMode = false,
    this.keepAwake = false,
    this.notice,
  });

  final TasbeehState counter;

  /// Counting with the volume buttons is on (Android only).
  final bool volumeMode;

  /// "Keep screen on while counting" is on.
  final bool keepAwake;

  /// A short plain message for the screen, e.g. when the service could not
  /// start. Null when there is nothing to say.
  final String? notice;

  TasbeehViewState copyWith({
    TasbeehState? counter,
    bool? volumeMode,
    bool? keepAwake,
    String? notice,
    bool clearNotice = false,
  }) {
    return TasbeehViewState(
      counter: counter ?? this.counter,
      volumeMode: volumeMode ?? this.volumeMode,
      keepAwake: keepAwake ?? this.keepAwake,
      notice: clearNotice ? null : (notice ?? this.notice),
    );
  }
}

final AutoDisposeNotifierProvider<TasbeehController, TasbeehViewState>
tasbeehControllerProvider =
    NotifierProvider.autoDispose<TasbeehController, TasbeehViewState>(
      TasbeehController.new,
    );

/// Owns the counter. The count and settings are saved on every change. With
/// "volume buttons" on, presses made while the screen was off are collected
/// by the Android service and folded in here (on a ping, and when the screen
/// is opened again).
class TasbeehController extends AutoDisposeNotifier<TasbeehViewState> {
  bool _disposed = false;
  late TasbeehStore _store;
  late VolumeCounterChannel _channel;
  late ScreenAwake _awake;
  StreamSubscription<void>? _sub;

  @override
  TasbeehViewState build() {
    _disposed = false;
    _store = TasbeehStore(ref.read(sharedPreferencesProvider));
    _channel = ref.read(volumeCounterChannelProvider);
    _awake = ref.read(screenAwakeProvider);

    if (_channel.isSupported) {
      _sub = _channel.pings.listen((_) => unawaited(syncFromNative()));
    }
    final ScreenAwake awake = _awake;
    ref.onDispose(() {
      _disposed = true;
      final StreamSubscription<void>? sub = _sub;
      if (sub != null) unawaited(sub.cancel());
      // The screen lock is released when the screen is left. The volume
      // service is NOT stopped: it keeps counting in the background.
      unawaited(awake.set(on: false));
    });

    final TasbeehSettings settings = _store.loadSettings();
    final TasbeehViewState initial = TasbeehViewState(
      counter: _store.loadCounter(),
      volumeMode: settings.volumeMode && _channel.isSupported,
      keepAwake: settings.keepAwake,
    );
    if (initial.volumeMode || initial.keepAwake) {
      unawaited(Future<void>.microtask(_resume));
    }
    return initial;
  }

  Future<void> _resume() async {
    if (_disposed) return;
    if (state.keepAwake) await _awake.set(on: true);
    if (_disposed || !state.volumeMode) return;
    await syncFromNative();
    if (_disposed) return;
    final bool ok = await _channel.start(state.counter);
    if (_disposed || ok) return;
    state = state.copyWith(
      volumeMode: false,
      notice: 'Counting with the volume buttons could not start on this phone.',
    );
    await _saveSettings();
  }

  /// Folds in button presses made while the screen was off.
  Future<void> syncFromNative() async {
    if (_disposed || !_channel.isSupported) return;
    final int delta = await _channel.takePendingDelta();
    if (_disposed || delta == 0) return;
    // The service applied the same presses to its own copy already, so the
    // screen's copy is saved but not pushed back.
    final TasbeehState next = TasbeehLogic.applyDelta(state.counter, delta);
    state = state.copyWith(counter: next);
    await _store.saveCounter(next);
  }

  void _setCounter(TasbeehState next) {
    state = state.copyWith(counter: next);
    unawaited(_store.saveCounter(next));
    if (state.volumeMode) unawaited(_channel.update(next));
  }

  /// One tap. True when it completed a round.
  bool tap() {
    final TasbeehStep step = TasbeehLogic.increment(state.counter);
    _setCounter(step.state);
    return step.reachedTarget;
  }

  void undo() => _setCounter(TasbeehLogic.undo(state.counter));

  void reset() => _setCounter(TasbeehLogic.reset(state.counter));

  void setTarget(int target) =>
      _setCounter(TasbeehLogic.setTarget(state.counter, target));

  void setLabel(String label) =>
      _setCounter(TasbeehLogic.setLabel(state.counter, label));

  void clearNotice() => state = state.copyWith(clearNotice: true);

  Future<void> _saveSettings() => _store.saveSettings(
    TasbeehSettings(
      volumeMode: state.volumeMode,
      keepAwake: state.keepAwake,
    ),
  );

  Future<void> setVolumeMode({required bool on}) async {
    if (!_channel.isSupported) return;
    if (on) {
      final bool ok = await _channel.start(state.counter);
      if (_disposed) return;
      if (!ok) {
        state = state.copyWith(
          notice:
              'Counting with the volume buttons could not start on this phone.',
        );
        return;
      }
      state = state.copyWith(volumeMode: true, clearNotice: true);
    } else {
      await syncFromNative();
      await _channel.stop();
      if (_disposed) return;
      state = state.copyWith(volumeMode: false);
    }
    await _saveSettings();
  }

  Future<void> setKeepAwake({required bool on}) async {
    state = state.copyWith(keepAwake: on);
    await _saveSettings();
    await _awake.set(on: on);
  }
}
