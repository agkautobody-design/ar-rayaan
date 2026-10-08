import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sound in Ar-Rayaan (Founder directive: "the whole app needs to be
/// communicative verbally"):
///
/// * [AmbientService] — gentle soundscape on Splash & NOOR (off-switch in
///   Settings, per the locked splash artwork).
/// * [AdhanService] — real Mecca adhan (MIT-licensed Muezzin recording)
///   playable from Prayer Times.
/// * [RecitationService] — real reciter audio (Mishary Alafasy) streamed
///   per ayah in the Qur'an reader. Never AI-generated voices for Qur'an.
/// * [SpeechService] — device voices (flutter_tts) read English content
///   aloud: NOOR, Hādi answers, du'a translations.
///
/// Every platform call is wrapped so widget tests (no plugins) never fail.

// ---------------------------------------------------------------------------
// Settings — persisted "Sound can be turned off in settings" (locked splash).
// ---------------------------------------------------------------------------

class SoundSettings {
  const SoundSettings({required this.ambient});

  final bool ambient;

  SoundSettings copyWith({bool? ambient}) =>
      SoundSettings(ambient: ambient ?? this.ambient);
}

class SoundSettingsController extends Notifier<SoundSettings> {
  static const String _ambientKey = 'ar.sound.ambient';

  @override
  SoundSettings build() {
    _load();
    return const SoundSettings(ambient: true);
  }

  Future<void> _load() async {
    try {
      final bool? v = await SharedPreferencesAsync().getBool(_ambientKey);
      if (v != null) state = SoundSettings(ambient: v);
    } catch (_) {}
  }

  Future<void> setAmbient(bool value) async {
    state = state.copyWith(ambient: value);
    try {
      await SharedPreferencesAsync().setBool(_ambientKey, value);
    } catch (_) {}
  }
}

final NotifierProvider<SoundSettingsController, SoundSettings>
soundSettingsProvider =
    NotifierProvider<SoundSettingsController, SoundSettings>(
      SoundSettingsController.new,
    );

/// Creates an [AudioPlayer] without crashing plugin-less environments
/// (widget tests): audioplayers initializes its global scope asynchronously
/// and reports MissingPluginException on the zone, outside any try/catch.
AudioPlayer? _tryCreatePlayer() {
  AudioPlayer? player;
  runZonedGuarded(() => player = AudioPlayer(), (_, _) {});
  return player;
}

/// Runs a platform audio call fire-and-forget: errors are swallowed and
/// no timers are created (future.timeout would trip the widget-test
/// "timers pending" invariant).
void _swallow(Future<dynamic> future) {
  future.then((_) {}, onError: (_) {}).ignore();
}

// ---------------------------------------------------------------------------
// Ambient soundscape (Splash & NOOR). Web autoplay requires a user gesture,
// so playback arms on [unlock] (first tap anywhere in the app).
// ---------------------------------------------------------------------------

class AmbientService {
  AudioPlayer? _player;
  bool _unlocked = false;
  int _requests = 0;
  bool _enabled = true;
  bool _playing = false;

  void setEnabled(bool enabled) {
    _enabled = enabled;
    _sync();
  }

  /// First user gesture unlocks web audio.
  void unlock() {
    _unlocked = true;
    _sync();
  }

  /// A screen that wants ambience calls [request] on entry and [release]
  /// on exit (reference-counted so navigation doesn't flicker the audio).
  void request() {
    _requests++;
    _sync();
  }

  void release() {
    if (_requests > 0) _requests--;
    _sync();
  }

  void _sync() {
    final bool want = _unlocked && _enabled && _requests > 0;
    if (want && !_playing) {
      _playing = true;
      _play();
    } else if (!want && _playing) {
      _playing = false;
      _stop();
    }
  }

  void _play() {
    _player ??= _tryCreatePlayer();
    final AudioPlayer? player = _player;
    if (player == null) {
      _playing = false;
      return;
    }
    _swallow(
      Future(() async {
        try {
          unawaited(player.setReleaseMode(ReleaseMode.loop));
          await player.setVolume(0.45);
          await player.play(AssetSource('audio/ambient.mp3'));
        } catch (_) {
          _playing = false;
        }
      }),
    );
  }

  void _stop() {
    final AudioPlayer? player = _player;
    if (player != null) _swallow(player.stop());
  }
}

final Provider<AmbientService> ambientServiceProvider =
    Provider<AmbientService>((Ref ref) {
      final AmbientService service = AmbientService();
      ref.onDispose(() => service._stop());
      return service;
    });

/// Mixin for screens that host the ambient soundscape (Splash, NOOR).
mixin AmbientHost<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  AmbientService? _ambient;

  @override
  void initState() {
    super.initState();
    // Captured here: ref is no longer readable once dispose begins.
    final AmbientService service = ref.read(ambientServiceProvider);
    service.request();
    _ambient = service;
  }

  @override
  void dispose() {
    _ambient?.release();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Adhan — real Mecca recording, bundled. Played on demand from Prayer Times.
// ---------------------------------------------------------------------------

class AdhanService extends Notifier<bool> {
  AudioPlayer? _player;

  @override
  bool build() => false; // true while playing

  Future<void> toggle() async => state ? stop() : play();

  Future<void> play() async {
    _player ??= _tryCreatePlayer();
    final AudioPlayer? player = _player;
    if (player == null) return;
    state = true; // optimistic; resets on completion or failure
    _swallow(
      Future(() async {
        try {
          await player.stop();
          await player.play(AssetSource('audio/adhan_mecca.mp3'));
        } catch (_) {
          state = false;
        }
      }),
    );
    _swallow(player.onPlayerComplete.first.then((_) => state = false));
  }

  Future<void> stop() async {
    state = false;
    final AudioPlayer? player = _player;
    if (player != null) _swallow(player.stop());
  }
}

final NotifierProvider<AdhanService, bool> adhanServiceProvider =
    NotifierProvider<AdhanService, bool>(AdhanService.new);

// ---------------------------------------------------------------------------
// Qur'an recitation — Mishary Alafasy, streamed per ayah (AlQuran Cloud CDN).
// ---------------------------------------------------------------------------

class RecitationState {
  const RecitationState({required this.surah, required this.ayah});

  final int surah;
  final int ayah;

  static const RecitationState idle = RecitationState(surah: 0, ayah: 0);

  bool get isIdle => surah == 0;
}

/// Ayah counts of the 114 surahs (standard Madani numbering, matches Tanzil).
const List<int> kSurahAyahCounts = <int>[
  7, 286, 200, 176, 120, 165, 206, 75, 129, 109, //
  123, 111, 43, 52, 99, 128, 111, 110, 98, 135, //
  112, 78, 118, 64, 77, 227, 93, 88, 69, 60, //
  34, 30, 73, 54, 45, 83, 182, 88, 75, 85, //
  54, 53, 89, 59, 37, 35, 38, 29, 18, 45, //
  60, 49, 62, 55, 78, 96, 29, 22, 24, 13, //
  14, 11, 11, 18, 12, 12, 30, 52, 52, 44, //
  28, 28, 20, 56, 40, 31, 50, 40, 46, 42, //
  29, 19, 36, 25, 22, 17, 19, 26, 30, 20, //
  15, 21, 11, 8, 8, 19, 5, 8, 8, 11, //
  11, 8, 3, 9, 5, 4, 7, 3, 6, 3, //
  5, 4, 5, 6,
];

int globalAyahNumber(int surah, int ayah) {
  int offset = 0;
  for (int i = 0; i < surah - 1; i++) {
    offset += kSurahAyahCounts[i];
  }
  return offset + ayah;
}

class RecitationService extends Notifier<RecitationState> {
  static const String _cdn =
      'https://cdn.islamic.network/quran/audio/128/ar.alafasy';

  AudioPlayer? _player;

  @override
  RecitationState build() => RecitationState.idle;

  bool isPlaying(int surah, int ayah) =>
      state.surah == surah && state.ayah == ayah;

  Future<void> toggle(int surah, int ayah) async {
    if (isPlaying(surah, ayah)) {
      await stop();
    } else {
      await play(surah, ayah);
    }
  }

  Future<void> play(int surah, int ayah) async {
    state = RecitationState(surah: surah, ayah: ayah);
    _player ??= _tryCreatePlayer();
    final AudioPlayer? player = _player;
    if (player == null) return;
    _swallow(
      Future(() async {
        try {
          await player.stop();
          await player.play(
            UrlSource('$_cdn/${globalAyahNumber(surah, ayah)}.mp3'),
          );
        } catch (_) {
          state = RecitationState.idle;
        }
      }),
    );
    _swallow(player.onPlayerComplete.first.then((_) => _advance()));
  }

  /// Auto-advance through the surah for continuous listening.
  void _advance() {
    if (state.isIdle) return;
    final int next = state.ayah + 1;
    if (next <= kSurahAyahCounts[state.surah - 1]) {
      unawaited(play(state.surah, next));
    } else {
      state = RecitationState.idle;
    }
  }

  Future<void> stop() async {
    state = RecitationState.idle;
    final AudioPlayer? player = _player;
    if (player != null) _swallow(player.stop());
  }
}

final NotifierProvider<RecitationService, RecitationState>
recitationServiceProvider =
    NotifierProvider<RecitationService, RecitationState>(RecitationService.new);

// ---------------------------------------------------------------------------
// Speech — device voices read English content aloud (NOOR, Hādi, du'as).
// ---------------------------------------------------------------------------

class SpeechService {
  FlutterTts? _tts;
  bool _busy = false;
  bool _voiceTuned = false;

  /// Natural-sounding voices by platform (mobile-webview pitfall: the
  /// default browser voice "sounds like a robot"). Best-effort: picks the
  /// first available from the list, else any English voice.
  static const List<String> _preferredVoices = <String>[
    'Samantha', // iOS
    'Google US English', // Android / Chrome
    'Microsoft Aria', // Edge
    'Karen',
    'Daniel',
  ];

  Future<void> _tuneVoice() async {
    if (_voiceTuned || _tts == null) return;
    _voiceTuned = true;
    try {
      final dynamic raw = await _tts!.getVoices;
      final List<dynamic> voices = raw is List ? raw : <dynamic>[];
      final List<Map<dynamic, dynamic>> english = voices
          .whereType<Map<dynamic, dynamic>>()
          .where((Map<dynamic, dynamic> v) =>
              (v['locale'] ?? '').toString().startsWith('en'))
          .toList();
      Map<dynamic, dynamic>? chosen;
      for (final String want in _preferredVoices) {
        chosen = english.firstWhere(
          (Map<dynamic, dynamic> v) =>
              (v['name'] ?? '').toString().contains(want),
          orElse: () => <dynamic, dynamic>{},
        );
        if (chosen.isNotEmpty) break;
        chosen = null;
      }
      chosen ??= english.isNotEmpty ? english.first : null;
      if (chosen != null) {
        await _tts!.setVoice(<String, String>{
          'name': chosen['name'].toString(),
          'locale': chosen['locale'].toString(),
        });
      }
    } catch (_) {}
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    try {
      _tts ??= FlutterTts();
      await _tts!.setLanguage('en-US');
      await _tts!.setSpeechRate(0.48);
      await _tuneVoice();
      if (_busy) await _tts!.stop();
      _busy = true;
      await _tts!.speak(text);
      _busy = false;
    } catch (_) {
      _busy = false;
    }
  }

  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {}
    _busy = false;
  }
}

final Provider<SpeechService> speechServiceProvider = Provider<SpeechService>((
  Ref ref,
) {
  final SpeechService service = SpeechService();
  ref.onDispose(() => service.stop());
  return service;
});
