/// Reads a poem aloud one line at a time, in the app's own voice, so the line
/// being said can be lit up for the reader to follow.
///
/// This is a recitation, not a sung recording: the app holds no licence to
/// copy anyone's recording. The voice sits behind [RecitalVoice] so it can be
/// tested with a fake, and a phone without a voice for the language says so
/// instead of failing.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart' show sharedPreferencesProvider;
import '../../../app/core/sound/voice_book.dart';
import '../../../app/core/sound/voice_picker.dart';

const double kRecitalNormalRate = 0.42;
const double kRecitalSlowRate = 0.28;

abstract class RecitalVoice {
  /// Speaks [text] in [lang] (`ar`, `ur`, `en`, `bn`) and completes when it
  /// has finished or been stopped. False when this device has no voice for it.
  Future<bool> speak(String text, {required String lang, required double rate});

  Future<void> stop();
}

class FlutterRecitalVoice implements RecitalVoice {
  FlutterRecitalVoice([this._book]);

  final VoiceBook? _book;
  FlutterTts? _tts;
  Completer<void>? _done;
  bool _wired = false;

  void _finish() {
    final Completer<void>? c = _done;
    if (c != null && !c.isCompleted) c.complete();
  }

  @override
  Future<bool> speak(
    String text, {
    required String lang,
    required double rate,
  }) async {
    try {
      final FlutterTts tts = _tts ??= FlutterTts();
      if (!_wired) {
        _wired = true;
        tts.setCompletionHandler(_finish);
        tts.setCancelHandler(_finish);
        tts.setErrorHandler((dynamic _) => _finish());
      }
      if (lang == 'ar' && _book != null) {
        if (!await _book.apply(tts, VoiceProfile.hadi, arabic: true)) {
          return false;
        }
      } else {
        final String locale = switch (lang) {
          'ar' => 'ar',
          'ur' => 'ur-PK',
          'bn' => 'bn-BD',
          'hi' => 'hi-IN',
          'pa' => 'pa-PK',
          _ => 'en-US',
        };
        final dynamic ok = await tts.isLanguageAvailable(locale);
        if (ok != true && ok != 1) return false;
        await tts.setLanguage(locale);
      }
      await tts.setSpeechRate(rate);
      final Completer<void> done = Completer<void>();
      _done = done;
      await tts.speak(text);
      await done.future;
      return true;
    } catch (_) {
      _finish();
      return false;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {
      // Nothing to stop.
    }
    _finish();
  }
}

final Provider<RecitalVoice> recitalVoiceProvider = Provider<RecitalVoice>((
  Ref ref,
) {
  SharedPreferences? prefs;
  try {
    prefs = ref.read(sharedPreferencesProvider);
  } catch (_) {
    prefs = null;
  }
  return FlutterRecitalVoice(VoiceBook(prefs));
});

class RecitalState {
  const RecitalState({
    this.playing = false,
    this.index = -1,
    this.total = 0,
    this.slow = false,
    this.unavailable = false,
  });

  final bool playing;

  /// The line being said (or paused on); -1 when nothing has started.
  final int index;
  final int total;
  final bool slow;

  /// This device has no voice for the poem's language.
  final bool unavailable;

  RecitalState copyWith({
    bool? playing,
    int? index,
    int? total,
    bool? slow,
    bool? unavailable,
  }) => RecitalState(
    playing: playing ?? this.playing,
    index: index ?? this.index,
    total: total ?? this.total,
    slow: slow ?? this.slow,
    unavailable: unavailable ?? this.unavailable,
  );
}

class NaatRecital extends AutoDisposeNotifier<RecitalState> {
  late RecitalVoice _voice;
  List<String> _lines = const <String>[];
  String _lang = 'ar';
  int _gen = 0;

  @override
  RecitalState build() {
    _voice = ref.read(recitalVoiceProvider);
    ref.onDispose(() {
      _gen++;
      unawaited(_voice.stop());
    });
    return const RecitalState();
  }

  /// Starts [lines] in [lang] at line [from].
  Future<void> play(List<String> lines, String lang, {int from = 0}) async {
    _lines = lines;
    _lang = lang;
    await _run(from);
  }

  Future<void> _run(int from) async {
    if (_lines.isEmpty) return;
    final int start = from.clamp(0, _lines.length - 1);
    final int gen = ++_gen;
    await _voice.stop();
    if (gen != _gen) return;
    state = state.copyWith(
      playing: true,
      index: start,
      total: _lines.length,
      unavailable: false,
    );
    for (int i = start; i < _lines.length; i++) {
      if (gen != _gen) return;
      state = state.copyWith(index: i);
      final bool ok = await _voice.speak(
        _lines[i],
        lang: _lang,
        rate: state.slow ? kRecitalSlowRate : kRecitalNormalRate,
      );
      if (gen != _gen) return;
      if (!ok) {
        state = state.copyWith(playing: false, unavailable: true);
        return;
      }
    }
    if (gen == _gen) state = state.copyWith(playing: false, index: -1);
  }

  /// Stops, keeping the line it was on.
  Future<void> pause() async {
    _gen++;
    state = state.copyWith(playing: false);
    await _voice.stop();
  }

  Future<void> resume() => _run(state.index < 0 ? 0 : state.index);

  Future<void> next() => _run((state.index < 0 ? 0 : state.index + 1));

  Future<void> previous() => _run((state.index <= 0 ? 0 : state.index - 1));

  void toggleSlow() => state = state.copyWith(slow: !state.slow);
}

final AutoDisposeNotifierProvider<NaatRecital, RecitalState>
naatRecitalProvider =
    NotifierProvider.autoDispose<NaatRecital, RecitalState>(NaatRecital.new);
