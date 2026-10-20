/// Recitation player state — executes a [RecitationPlanEngine] plan.
///
/// The audio backend is an interface so tests run silent: production
/// wires [AudioplayersAyahPlayer], tests use a fake that completes
/// instantly. Timing gaps use an injectable sleeper for the same reason.
library;

import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';

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
    this.paused = false,
    this.failed = false,
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
  /// (Per-ayah events no longer fall back to a whole-surah file; the flag
  /// is kept for API compatibility and stays false.)
  final bool fallbackActive;

  /// True between [RecitationPlayerNotifier.pause] and the next resume /
  /// stop / new plan — the UI resumes instead of restarting.
  final bool paused;

  /// True when an ayah's audio could not be loaded or played; playback
  /// stopped at that ayah instead of playing something else.
  final bool failed;

  RecitationPlaybackState copyWith({
    List<PlaybackEvent>? plan,
    int? eventIndex,
    int? utteranceInEvent,
    bool? playing,
    bool? finished,
    bool? fallbackActive,
    bool? paused,
    bool? failed,
  }) =>
      RecitationPlaybackState(
        plan: plan ?? this.plan,
        eventIndex: eventIndex ?? this.eventIndex,
        utteranceInEvent: utteranceInEvent ?? this.utteranceInEvent,
        playing: playing ?? this.playing,
        finished: finished ?? this.finished,
        fallbackActive: fallbackActive ?? this.fallbackActive,
        paused: paused ?? this.paused,
        failed: failed ?? this.failed,
      );
}

typedef Sleeper = Future<void> Function(int ms);

class RecitationPlayerNotifier
    extends StateNotifier<RecitationPlaybackState> {
  RecitationPlayerNotifier({
    required AyahAudioPlayer audio,
    required Future<String> Function(PlaybackEvent event) sourceResolver,
    Sleeper? sleeper,
    Future<void> Function(double speed)? speedSetter,
  })  : _audio = audio,
        _speedSetter = speedSetter,
        _resolve = sourceResolver,
        _sleep = sleeper ?? ((int ms) => Future<void>.delayed(Duration(milliseconds: ms))),
        super(const RecitationPlaybackState());

  final AyahAudioPlayer _audio;
  final Future<String> Function(PlaybackEvent event) _resolve;
  final Sleeper _sleep;
  final Future<void> Function(double speed)? _speedSetter;
  double _speed = 1.0;
  bool _stopped = true;

  /// Bumped by every [_runFrom]; a superseded loop (e.g. one still
  /// sleeping through a gap when the user paused and resumed) exits
  /// instead of running in parallel with its replacement.
  int _run = 0;

  /// Playback speed (0.75-1.25x). Applied to the current and every later
  /// utterance. No-op for backends without a speed control.
  Future<void> setSpeed(double speed) async {
    _speed = speed;
    await _applySpeed();
  }

  Future<void> _applySpeed() async {
    final Future<void> Function(double speed)? setter = _speedSetter;
    if (setter == null) return;
    try {
      await setter(_speed);
    } catch (_) {
      // Speed is best-effort; never break playback over it.
    }
  }

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
    final int token = ++_run;
    final List<PlaybackEvent> plan = state.plan;
    for (int e = eventIndex; e < plan.length; e++) {
      final PlaybackEvent event = plan[e];
      for (int u = (e == eventIndex ? utterance : 0); u < event.repeats; u++) {
        if (_stopped || token != _run) return;
        state = state.copyWith(eventIndex: e, utteranceInEvent: u);
        try {
          final String source = await _resolve(event);
          if (_stopped || token != _run) return;
          await _applySpeed();
          await _audio.play(source);
        } catch (_) {
          // This ayah's audio could not be fetched or played. Stop here and
          // say so; never substitute a different recording.
          if (!_stopped && token == _run) {
            _stopped = true;
            state = state.copyWith(playing: false, failed: true);
          }
          return;
        }
        if (_stopped || token != _run) return;
        if (event.gapAfterMs > 0) {
          await _sleep(event.gapAfterMs);
          if (_stopped || token != _run) return;
        }
      }
    }
    if (!_stopped && token == _run) {
      state = state.copyWith(playing: false, finished: true, paused: false);
    }
  }

  /// Pause: stop audio, remember position for [resume].
  Future<void> pause() async {
    _stopped = true;
    await _audio.stop();
    state = state.copyWith(playing: false, paused: true);
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
      paused: false,
    );
  }

  /// Continue after [pause] from the current event/utterance.
  Future<void> resume() async {
    if (state.playing || state.plan.isEmpty || state.finished) return;
    _stopped = false;
    state = state.copyWith(playing: true, paused: false, failed: false);
    await _runFrom(state.eventIndex, state.utteranceInEvent);
  }
}


// ---------------------------------------------------------------------------
// Production wiring (web + mobile). Tests override these with fakes.
// ---------------------------------------------------------------------------

/// The reciter the person chose, saved on this device. One setting for the
/// whole app: the reader, the range bar and every ayah button use it.
class ReciterController extends Notifier<ReciterPack> {
  static const String prefsKey = 'ar.quran.reciter';

  @override
  ReciterPack build() {
    try {
      final SharedPreferences p = ref.watch(sharedPreferencesProvider);
      return ReciterPack.byId(p.getString(prefsKey));
    } catch (_) {
      return ReciterPack.alHusary;
    }
  }

  Future<void> select(ReciterPack pack) async {
    state = pack;
    try {
      await ref
          .read(sharedPreferencesProvider)
          .setString(prefsKey, pack.id);
    } catch (_) {
      // Kept for this session only.
    }
  }
}

final NotifierProvider<ReciterController, ReciterPack> selectedReciterProvider =
    NotifierProvider<ReciterController, ReciterPack>(ReciterController.new);

/// On-device cache directory for one reciter's ayah files. Created on first
/// use. Al-Husary keeps its original folder so cached files stay valid.
final FutureProviderFamily<Directory, String> audioCacheDirProvider =
    FutureProvider.family<Directory, String>((Ref ref, String reciterId) async {
  final Directory base = await getApplicationSupportDirectory();
  final String name =
      reciterId == ReciterPack.alHusary.id ? 'husary' : reciterId;
  final Directory dir = Directory('${base.path}/recitation/$name');
  await dir.create(recursive: true);
  return dir;
});

/// The live recitation player: THE one audio engine for Qur'an recitation
/// (reader ayah buttons, the range bar, Madinah view). UI watches
/// [StateNotifier] state; controls call playPlan/pause/resume/stop.
final recitationPlayerProvider =
    StateNotifierProvider<RecitationPlayerNotifier, RecitationPlaybackState>(
        (Ref ref) {
  final AudioplayersAyahPlayer audio = AudioplayersAyahPlayer();
  ref.onDispose(() => audio.dispose());
  final notifier = RecitationPlayerNotifier(
    audio: audio,
    speedSetter: audio.setSpeed,
    sourceResolver: (PlaybackEvent event) async {
      final ReciterPack pack = ref.read(selectedReciterProvider);
      // Web has no file system: stream the per-ayah file directly.
      if (kIsWeb) return pack.ayahUrl(event.ref);
      final Directory dir = await ref.read(audioCacheDirProvider(pack.id).future);
      return resolvePlaybackSource(
        event: event,
        pack: pack,
        cacheDir: dir,
      );
    },
  );
  return notifier;
});
