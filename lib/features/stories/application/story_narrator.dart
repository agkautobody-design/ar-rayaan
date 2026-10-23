/// Read-aloud for a story chapter: Listen / Pause and a slow or normal pace.
///
/// The device voice sits behind [TtsEngine] so the controller can be tested
/// with a fake and so a device without a voice fails quietly (the button then
/// says Listen is not available here) instead of throwing.
///
/// The text is spoken one piece at a time. Pause stops the voice and keeps
/// the piece it was on, so Resume starts again from the beginning of that
/// piece. (Not every platform can truly pause speech, and this way it behaves
/// the same everywhere.)
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Speech rates in flutter_tts units. Normal matches the rest of the app.
const double kNarratorNormalRate = 0.48;
const double kNarratorSlowRate = 0.3;

/// Splits [text] into pieces to speak one after another: whole sentences,
/// joined up to about [maxChars] characters. A sentence longer than that is
/// kept whole. Empty or blank text gives no pieces.
List<String> splitForSpeech(String text, {int maxChars = 280}) {
  final String clean = text.replaceAll(RegExp(r'[ \t]+'), ' ').trim();
  if (clean.isEmpty) return const <String>[];
  final List<String> sentences = <String>[];
  for (final String paragraph in clean.split(RegExp(r'\n+'))) {
    final String p = paragraph.trim();
    if (p.isEmpty) continue;
    final Iterable<RegExpMatch> found = RegExp(
      r'[^.!?]+[.!?]+["”’)\]]*\s*|[^.!?]+$',
    ).allMatches(p);
    for (final RegExpMatch m in found) {
      final String s = m.group(0)!.trim();
      if (s.isNotEmpty) sentences.add(s);
    }
  }
  final List<String> out = <String>[];
  StringBuffer cur = StringBuffer();
  for (final String s in sentences) {
    if (cur.isNotEmpty && cur.length + 1 + s.length > maxChars) {
      out.add(cur.toString());
      cur = StringBuffer();
    }
    if (cur.isNotEmpty) cur.write(' ');
    cur.write(s);
  }
  if (cur.isNotEmpty) out.add(cur.toString());
  return out;
}

/// The device voice, as the narrator needs it.
abstract class TtsEngine {
  /// Speaks [text] at [rate] and completes when it has finished or has been
  /// stopped. Returns false when there is no voice to speak with.
  Future<bool> speak(String text, {required double rate});

  /// Stops speaking now. Completes any speak() that is waiting.
  Future<void> stop();
}

/// [TtsEngine] over the flutter_tts plugin (Android, iOS and the browser's
/// speech synthesis). Every call is guarded: a missing plugin or voice makes
/// speak() return false.
class FlutterTtsEngine implements TtsEngine {
  FlutterTts? _tts;
  Completer<void>? _done;
  bool _wired = false;

  void _finish() {
    final Completer<void>? c = _done;
    if (c != null && !c.isCompleted) c.complete();
  }

  @override
  Future<bool> speak(String text, {required double rate}) async {
    try {
      final FlutterTts tts = _tts ??= FlutterTts();
      if (!_wired) {
        _wired = true;
        tts.setCompletionHandler(_finish);
        tts.setCancelHandler(_finish);
        tts.setErrorHandler((dynamic _) => _finish());
      }
      await tts.setLanguage('en-US');
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

/// The engine the narrator uses. Tests override this with a fake.
final Provider<TtsEngine> storyTtsEngineProvider = Provider<TtsEngine>(
  (Ref ref) => FlutterTtsEngine(),
);

enum NarratorStatus { idle, playing, paused }

class NarratorState {
  const NarratorState({
    this.status = NarratorStatus.idle,
    this.slow = false,
    this.text = '',
    this.chunk = 0,
    this.total = 0,
    this.unavailable = false,
  });

  final NarratorStatus status;

  /// Slow pace chosen.
  final bool slow;

  /// The text being read (or paused on); empty when idle.
  final String text;

  /// Index of the piece being spoken, and how many pieces there are.
  final int chunk;
  final int total;

  /// The device has no voice to read with.
  final bool unavailable;

  NarratorState copyWith({
    NarratorStatus? status,
    bool? slow,
    String? text,
    int? chunk,
    int? total,
    bool? unavailable,
  }) => NarratorState(
    status: status ?? this.status,
    slow: slow ?? this.slow,
    text: text ?? this.text,
    chunk: chunk ?? this.chunk,
    total: total ?? this.total,
    unavailable: unavailable ?? this.unavailable,
  );
}

class StoryNarrator extends AutoDisposeNotifier<NarratorState> {
  late TtsEngine _engine;
  List<String> _chunks = const <String>[];
  int _gen = 0;
  bool _disposed = false;

  @override
  NarratorState build() {
    _engine = ref.read(storyTtsEngineProvider);
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _gen++;
      unawaited(_engine.stop());
    });
    return const NarratorState();
  }

  void _set(NarratorState next) {
    if (!_disposed) state = next;
  }

  /// Listen / Pause / Resume for [text], one button.
  Future<void> toggle(String text) async {
    final bool same = state.text == text;
    if (same && state.status == NarratorStatus.playing) return pause();
    if (same && state.status == NarratorStatus.paused) {
      return _run(state.chunk);
    }
    _chunks = splitForSpeech(text);
    if (_chunks.isEmpty) return;
    _gen++;
    await _engine.stop();
    _set(
      NarratorState(
        slow: state.slow,
        text: text,
        total: _chunks.length,
      ),
    );
    return _run(0);
  }

  Future<void> pause() async {
    if (state.status != NarratorStatus.playing) return;
    _gen++;
    _set(state.copyWith(status: NarratorStatus.paused));
    await _engine.stop();
  }

  /// Stops and forgets the place (the chapter changed or the person left).
  Future<void> stop() async {
    _gen++;
    _chunks = const <String>[];
    _set(NarratorState(slow: state.slow));
    await _engine.stop();
  }

  /// Slow or normal pace. While reading, the current piece starts again at
  /// the new pace.
  Future<void> setSlow(bool slow) async {
    final bool wasPlaying = state.status == NarratorStatus.playing;
    _set(state.copyWith(slow: slow));
    if (!wasPlaying) return;
    _gen++;
    await _engine.stop();
    return _run(state.chunk);
  }

  Future<void> _run(int from) async {
    final int gen = ++_gen;
    _set(
      state.copyWith(
        status: NarratorStatus.playing,
        chunk: from,
        total: _chunks.length,
        unavailable: false,
      ),
    );
    for (int i = from; i < _chunks.length; i++) {
      if (gen != _gen) return;
      _set(state.copyWith(chunk: i));
      final bool ok = await _engine.speak(
        _chunks[i],
        rate: state.slow ? kNarratorSlowRate : kNarratorNormalRate,
      );
      if (gen != _gen) return;
      if (!ok) {
        _set(NarratorState(slow: state.slow, unavailable: true));
        return;
      }
    }
    if (gen == _gen) _set(NarratorState(slow: state.slow));
  }
}

final AutoDisposeNotifierProvider<StoryNarrator, NarratorState>
storyNarratorProvider =
    NotifierProvider.autoDispose<StoryNarrator, NarratorState>(
      StoryNarrator.new,
    );
