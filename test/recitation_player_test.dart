import 'dart:async';
import 'dart:io';

import 'package:ar_rayaan/features/academy/application/recitation_player_provider.dart';
import 'package:ar_rayaan/features/academy/domain/recitation_audio.dart';
import 'package:ar_rayaan/features/academy/data/recitation_audio_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Silent audio backend for player-state tests. See field [hold].
    class _FakeAudio implements AyahAudioPlayer {
  _FakeAudio(this.log, {this.hold = false});
final List<String> log;

/// hold=true: each play() waits for releaseCurrent() — pause tests.
/// hold=false: play() completes on the next microtask — order tests.
final bool hold;
  Completer<void>? _current;

@override
Future<void> play(String pathOrUrl) async {
  log.add(pathOrUrl);
  if (hold) {
    _current = Completer<void>();
    return _current!.future;
  }
  await Future<void>.delayed(Duration.zero);
}

@override
Future<void> stop() async {
  _current?.complete();
  _current = null;
}

void releaseCurrent() {
  _current?.complete();
  _current = null;
}
    }

void main() {
  final pack = ReciterPack.alHusary;
  const ref = AyahRef(1, 1);

  group('RecitationAudioRepository', () {
    test('fetches, caches, and returns local path on second call', () async {
      int calls = 0;
      final client = MockClient((req) async {
        calls++;
        return http.Response.bytes(List<int>.filled(512, 7), 200);
      });
      final dir = await Directory.systemTemp.createTemp('ar_audio');
      addTearDown(() => dir.delete(recursive: true));

      final first = await RecitationAudioRepository.resolve(
        pack: pack, ref: ref, cacheDir: dir, client: client,
      );
      expect(first, isA<AyahFileSource>());
      expect(File((first as AyahFileSource).path).existsSync(), isTrue);

      final second = await RecitationAudioRepository.resolve(
        pack: pack, ref: ref, cacheDir: dir, client: client,
      );
      expect((second as AyahFileSource).path, first.path);
      expect(calls, 1, reason: 'cache hit — no second network call');
    });

    test('404 degrades honestly to the surah file', () async {
      final client = MockClient((req) async => http.Response('nf', 404));
      final dir = await Directory.systemTemp.createTemp('ar_audio');
      addTearDown(() => dir.delete(recursive: true));

      final s = await RecitationAudioRepository.resolve(
        pack: pack, ref: ref, cacheDir: dir, client: client,
      );
      expect(s, isA<SurahFileSource>());
      expect((s as SurahFileSource).surah, 1);
      expect(s.url, pack.surahUrl(1));
    });

    test('offline with no cache degrades to surah file (no crash)', () async {
      final client = MockClient((req) async =>
          throw const SocketException('offline'));
      final dir = await Directory.systemTemp.createTemp('ar_audio');
      addTearDown(() => dir.delete(recursive: true));

      final s = await RecitationAudioRepository.resolve(
        pack: pack, ref: ref, cacheDir: dir, client: client,
      );
      expect(s, isA<SurahFileSource>());
    });
  });

  group('RecitationPlayerNotifier', () {
    late List<String> played;
    late List<int> sleeps;
    late _FakeAudio? holding;

    PlaybackEvent ev(int ayah, {int repeats = 1, int gap = 0}) =>
        PlaybackEvent(
          ref: AyahRef(1, ayah),
          repeats: repeats,
          gapAfterMs: gap,
        );

    RecitationPlayerNotifier makeNotifier({bool hold = false}) {
      final audio = _FakeAudio(played, hold: hold);
      if (hold) holding = audio;
      return RecitationPlayerNotifier(
        audio: audio,
        sourceResolver: (e) async => 'src:${e.ref.ayah}',
        sleeper: (ms) async => sleeps.add(ms),
      );
    }

    setUp(() {
      played = <String>[];
      sleeps = <int>[];
      holding = null;
    });

    test('plays events in order with per-ayah repeats', () async {
      final notifier = makeNotifier();
      await notifier.playPlan(<PlaybackEvent>[ev(1, repeats: 2), ev(2)]);
      expect(played, <String>['src:1', 'src:1', 'src:2']);
    });

    test('gap sleeps only when gapMs > 0', () async {
      final notifier = makeNotifier();
      await notifier.playPlan(<PlaybackEvent>[
        ev(1, gap: 1500), ev(2, gap: 0),
      ]);
      expect(sleeps, <int>[1500]);
    });

    test('plan completes with finished=true', () async {
      final notifier = makeNotifier();
      await notifier.playPlan(<PlaybackEvent>[ev(1), ev(2)]);
      expect(played, <String>['src:1', 'src:2']);
      expect(notifier.state.finished, isTrue);
      expect(notifier.state.playing, isFalse);
    });

    test('pause then resume continues from exact utterance', () async {
      final notifier = makeNotifier(hold: true);
      final done = notifier.playPlan(<PlaybackEvent>[
        ev(1, repeats: 1), ev(2, repeats: 1), ev(3, repeats: 1),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(played, <String>['src:1']);
      await notifier.pause();
      final pausedAt = notifier.state.utteranceIndex;
      await done;
      expect(notifier.state.finished, isFalse);

      final resumed = notifier.resume();
      await Future<void>.delayed(Duration.zero);
      holding!.releaseCurrent();
      await Future<void>.delayed(Duration.zero);
      holding!.releaseCurrent();
      await Future<void>.delayed(Duration.zero);
      holding!.releaseCurrent();
      await resumed;
      expect(notifier.state.finished, isTrue);
      expect(played.where((p) => p == 'src:1').length, 2);
      expect(pausedAt, 0);
    });

    test('stop halts playback; stopped, not completed', () async {
      final notifier = makeNotifier(hold: true);
      final done = notifier.playPlan(<PlaybackEvent>[ev(1), ev(2)]);
      await Future<void>.delayed(Duration.zero);
      await notifier.stop();
      await done;
      expect(notifier.state.playing, isFalse);
      expect(notifier.state.finished, isFalse);
    });

    test('utteranceIndex counts repeats across events', () async {
      final notifier = makeNotifier();
      await notifier.playPlan(<PlaybackEvent>[
        ev(1, repeats: 3), ev(2, repeats: 2), ev(3),
      ]);
      expect(played.length, 6);
    });
  });
}
