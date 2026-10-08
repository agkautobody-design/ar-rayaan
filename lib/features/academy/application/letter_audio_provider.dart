/// Letter audio — "Hear it" plays each letter's example ayah.
/// Cache-first (repository resolves cached file → per-ayah URL → surah
/// fallback), through the same AudioplayersAyahPlayer the recitation
/// player uses. One shared backend instance.
library;

import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../data/audioplayers_ayah_player.dart';
import '../data/recitation_audio_repository.dart';
import '../domain/letters_data.dart';
import '../domain/recitation_audio.dart';

class LetterAudioProvider {
  LetterAudioProvider._();
  static final LetterAudioProvider instance = LetterAudioProvider._();

  final AudioplayersAyahPlayer _player = AudioplayersAyahPlayer();
  bool _busy = false;

  Future<void> play(LetterEntry letter) async {
    if (_busy) {
      await _player.stop();
    }
    _busy = true;
    try {
      final Directory base = await getApplicationSupportDirectory();
      final Directory dir = Directory('${base.path}/recitation/husary');
      await dir.create(recursive: true);
      final PlaybackSource src =
          await RecitationAudioRepository.resolve(
        pack: ReciterPack.alHusary,
        ref: letter.exampleAyah,
        cacheDir: dir,
      );
      final String path = switch (src) {
        AyahFileSource(path: final p) => p,
        SurahFileSource(url: final u) => u,
      };
      await _player.play(path);
    } finally {
      _busy = false;
    }
  }
}
