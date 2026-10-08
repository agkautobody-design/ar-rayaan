/// Recitation player state — executes a [RecitationPlanEngine] plan.
///
/// The audio backend is an interface so tests run silent: production
/// wires [AudioplayersAyahPlayer], tests use a fake that completes
/// instantly. Timing gaps use an injectable sleeper for the same reason.
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../data/audioplayers_ayah_player.dart';

import '../domain/recitation_audio.dart';

/// What the UI shows right now.
class RecitationPlaybackState {
  const RecitationPlaybackState({
    this.plan = const <PlaybackEvent>[],
    this.eventIndex = 0,
    this.utteranceInEvent = 0,
    this.playing = false,
    this.finished = false,
    this.fallbackActive = false,
  });

  final List<PlaybackEvent> plan;
  final int eventIndex;
  final int utteranceInEvent;

  /// Current position in utterances (for progress display).
  int get utteranceIndex {
    int n = 0;
    for (int i = 0; i < eventIndex && i < plan.length; i++) {
      n += plan[i].repeats;
    }
    final int cap = plan.isEmpty ? 0 : plan[eventIndex].repeats - 1;
    return n + utteranceInEvent.clamp(0, cap).toInt();
  }

  final bool playing;
  final bool finished;

  /// True once any event degraded to the surah fallback this session.
  final bool fallbackActive;

  RecitationPlaybackState copyWith({
    List<PlaybackEvent>? plan,
    int? eventIndex,
    int? utteranceInEvent,
    bool? playing,
    bool? finished,
    bool? fallbackActive,
  }) =>
      RecitationPlaybackState(
        plan: plan ?? this.plan,
        eventIndex: eventIndex ?? this.eventIndex,
        utteranceInEvent: utteranceInEvent ?? this.utteranceInEvent,
        playing: playing ?? this.playing,
        finished: finished ?? this.finished,
        fallbackActive: fallbackActive ?? this.fallbackActive,
      );
}

typedef Sleeper = Future<void> Function(int ms);

class RecitationPlayerNotifier
    extends StateNotifier<RecitationPlaybackState> {
  RecitationPlayerNotifier({
    required AyahAudioPlayer audio,
    required Future<String> Function(PlaybackEvent event) sourceResolver,
    Sleeper? sleeper,
  })  : _audio = audio,
        _resolve = sourceResolver,
        _sleep = sleeper ?? ((int ms) => Future<void>.delayed(Duration(milliseconds: ms))),
        super(const RecitationPlaybackState());

  final AyahAudioPlayer _audio;
  final Future<String> Function(PlaybackEvent event) _resolve;
  final Sleeper _sleep;
  bool _stopped = true;

  /// Start (or restart) [plan]. Sources are resolved event by event so a
  /// fallback mid-plan degrades only what follows it.
  Future<void> playPlan(List<PlaybackEvent> plan) async {
    if (plan.isEmpty) return;
    await stop();
    _stopped = false;
    state = RecitationPlaybackState(plan: plan, playing: true);
    await _runFrom(0, 0);
  }

  Future<void> _runFrom(int eventIndex, int utterance) async {
    final List<PlaybackEvent> plan = state.plan;
    for (int e = eventIndex; e < plan.length; e++) {
      final PlaybackEvent event = plan[e];
      for (int u = (e == eventIndex ? utterance : 0); u < event.repeats; u++) {
        if (_stopped) return;
        state = state.copyWith(eventIndex: e, utteranceInEvent: u);
        final String source = await _resolve(event);
        if (_stopped) return;
        await _audio.play(source);
        if (_stopped) return;
        if (event.gapAfterMs > 0) {
          await _sleep(event.gapAfterMs);
          if (_stopped) return;
        }
      }
    }
    if (!_stopped) {
      state = state.copyWith(playing: false, finished: true);
    }
  }

  /// Pause: stop audio, remember position for [resume].
  Future<void> pause() async {
    _stopped = true;
    await _audio.stop();
    state = state.copyWith(playing: false);
  }

  /// Stop entirely: playback halts and position resets — the next
  /// [playPlan] (or [resume]) starts from the beginning.
  Future<void> stop() async {
    _stopped = true;
    await _audio.stop();
    state = state.copyWith(
      playing: false,
      finished: false,
      eventIndex: 0,
      utteranceInEvent: 0,
    );
  }

  /// Continue after [pause] from the current event/utterance.
  Future<void> resume() async {
    if (state.playing || state.plan.isEmpty || state.finished) return;
    _stopped = false;
    state = state.copyWith(playing: true);
    await _runFrom(state.eventIndex, state.utteranceInEvent);
  }
}


// ---------------------------------------------------------------------------
// Production wiring (web + mobile). Tests override these with fakes.
// ---------------------------------------------------------------------------

/// On-device cache directory for ayah audio files. Created on first use.
final audioCacheDirProvider = FutureProvider<Directory>((Ref ref) async {
  final Directory base = await getApplicationSupportDirectory();
  final Directory dir = Directory('${base.path}/recitation/husary');
  await dir.create(recursive: true);
  return dir;
});

/// The live recitation player. UI watches [StateNotifier] state;
/// controls call playPlan/pause/resume/stop.
final recitationPlayerProvider =
    StateNotifierProvider<RecitationPlayerNotifier, RecitationPlaybackState>(
        (Ref ref) {
  final notifier = RecitationPlayerNotifier(
    audio: AudioplayersAyahPlayer(),
    sourceResolver: (PlaybackEvent event) async {
      final Directory dir = await ref.watch(audioCacheDirProvider.future);
      return resolvePlaybackSource(
        event: event,
        pack: ReciterPack.alHusary,
        cacheDir: dir,
      );
    },
  );
  return notifier;
});
