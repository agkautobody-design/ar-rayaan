/// The Ar-Rayaan Player — queue state machine (M1b.1).
/// Backend is the same [AyahAudioPlayer] seam the recitation engine uses;
/// tests inject a silent fake.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/nasheed_player.dart';
import '../domain/recitation_audio.dart';

class NasheedPlayerState {
  const NasheedPlayerState({
    this.queue = const <NasheedTrack>[],
    this.index = 0,
    this.playing = false,
  });

  final List<NasheedTrack> queue;
  final int index;
  final bool playing;

  NasheedTrack? get current =>
      queue.isEmpty ? null : queue[index.clamp(0, queue.length - 1)];

  NasheedPlayerState copyWith({
    List<NasheedTrack>? queue,
    int? index,
    bool? playing,
  }) =>
      NasheedPlayerState(
        queue: queue ?? this.queue,
        index: index ?? this.index,
        playing: playing ?? this.playing,
      );
}

class NasheedPlayerNotifier extends StateNotifier<NasheedPlayerState> {
  NasheedPlayerNotifier({required AyahAudioPlayer audio, this.repeat = RepeatMode.off})
      : _audio = audio,
        super(const NasheedPlayerState());

  final AyahAudioPlayer _audio;
  RepeatMode repeat;
  bool _stopped = true;

  Future<void> playQueue(List<NasheedTrack> queue, {int startAt = 0}) async {
    if (queue.isEmpty) return;
    await stop();
    _stopped = false;
    state = NasheedPlayerState(queue: queue, index: startAt, playing: true);
    await _playCurrent();
  }

  Future<void> _playCurrent() async {
    final NasheedTrack? t = state.current;
    if (t == null || _stopped) return;
    await _audio.play(t.playableRef);
    if (_stopped) return;
    // Track finished naturally → advance per repeat mode.
    final int? n = QueueEngine.next(state.index, state.queue.length, repeat);
    if (n == null) {
      state = state.copyWith(playing: false);
    } else {
      state = state.copyWith(index: n);
      await _playCurrent();
    }
  }

  Future<void> toggle() async {
    if (state.playing) {
      await pause();
    } else if (state.queue.isNotEmpty) {
      _stopped = false;
      state = state.copyWith(playing: true);
      await _playCurrent();
    }
  }

  Future<void> pause() async {
    _stopped = true;
    await _audio.stop();
    state = state.copyWith(playing: false);
  }

  Future<void> stop() async {
    _stopped = true;
    await _audio.stop();
  }

  Future<void> next() async {
    final int? n = QueueEngine.next(state.index, state.queue.length, repeat);
    if (n == null) {
      await pause();
      return;
    }
    await _audio.stop();
    _stopped = false;
    state = state.copyWith(index: n, playing: true);
    await _playCurrent();
  }

  Future<void> previous() async {
    await _audio.stop();
    _stopped = false;
    state = state.copyWith(index: QueueEngine.prev(state.index, state.queue.length), playing: true);
    await _playCurrent();
  }
}
