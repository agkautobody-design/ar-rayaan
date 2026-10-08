/// Production [AyahAudioPlayer] backed by the `audioplayers` package.
///
/// One instance owns one AudioPlayer. [play] resolves its future when the
/// utterance finishes naturally OR when [stop] interrupts it — the
/// notifier relies on both paths.
library;

import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart' as ap;

import '../domain/recitation_audio.dart';
import 'recitation_audio_repository.dart';

class AudioplayersAyahPlayer implements AyahAudioPlayer {
  AudioplayersAyahPlayer() {
    _player = ap.AudioPlayer();
    _player.setReleaseMode(ap.ReleaseMode.stop);
    _sub = _player.onPlayerComplete.listen((_) {
      _current?.complete();
      _current = null;
    });
  }

  late final ap.AudioPlayer _player;
  late final StreamSubscription<void> _sub;
  Completer<void>? _current;

  @override
  Future<void> play(String pathOrUrl) async {
    // A new utterance replaces any pending completion — a stale
    // completion must never advance the plan.
    _current = Completer<void>();
    final Completer<void> mine = _current!;
    final bool isUrl = pathOrUrl.startsWith('http');
    final ap.Source source = isUrl
        ? ap.UrlSource(pathOrUrl)
        : ap.DeviceFileSource(pathOrUrl);
    await _player.play(source);
    return mine.future;
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _current?.complete();
    _current = null;
  }

  Future<void> setSpeed(double speed) => _player.setPlaybackRate(speed);

  Future<void> dispose() async {
    await _sub.cancel();
    await _player.dispose();
  }
}

/// Resolve one playback event to a playable source string, preferring the
/// cached per-ayah file and degrading honestly to the surah URL.
Future<String> resolvePlaybackSource({
  required PlaybackEvent event,
  required ReciterPack pack,
  required Directory cacheDir,
}) async {
  final PlaybackSource s = await RecitationAudioRepository.resolve(
    pack: pack,
    ref: event.ref,
    cacheDir: cacheDir,
  );
  return switch (s) {
    AyahFileSource(path: final p) => p,
    SurahFileSource(url: final u) => u,
  };
}
