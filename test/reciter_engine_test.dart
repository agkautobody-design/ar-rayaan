import 'dart:async';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/core/sound/sound_services.dart';
import 'package:ar_rayaan/features/academy/application/recitation_player_provider.dart';
import 'package:ar_rayaan/features/academy/domain/recitation_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records every source it is asked to play and holds each utterance open
/// until [release] (or [stop]) so tests can watch the engine move.
class _HoldingAudio implements AyahAudioPlayer {
  final List<String> played = <String>[];
  Completer<void>? _c;

  @override
  Future<void> play(String pathOrUrl) {
    played.add(pathOrUrl);
    _c = Completer<void>();
    return _c!.future;
  }

  @override
  Future<void> stop() async {
    _c?.complete();
    _c = null;
  }

  void release() {
    _c?.complete();
    _c = null;
  }
}

class _BrokenAudio implements AyahAudioPlayer {
  @override
  Future<void> play(String pathOrUrl) => Future<void>.error(StateError('x'));
  @override
  Future<void> stop() async {}
}

void main() {
  group('reciter catalogue', () {
    test('ids are unique and the default comes first', () {
      final Set<String> ids = ReciterPack.all.map((ReciterPack p) => p.id).toSet();
      expect(ids.length, ReciterPack.all.length);
      expect(ReciterPack.all.first, ReciterPack.alHusary);
      expect(ReciterPack.all.length, greaterThanOrEqualTo(6));
    });

    test('every reciter streams per-ayah files from the same host layout', () {
      for (final ReciterPack p in ReciterPack.all) {
        expect(p.displayName, isNotEmpty);
        expect(
          p.ayahUrl(const AyahRef(2, 255)),
          matches(RegExp(r'^https://everyayah\.com/data/[A-Za-z0-9_\-]+/002255\.mp3$')),
          reason: p.id,
        );
      }
    });

    test('only Al-Husary has a whole-surah host; others return empty', () {
      expect(ReciterPack.alHusary.surahUrl(2), endsWith('/002.mp3'));
      expect(ReciterPack.alafasy.surahUrl(2), isEmpty);
    });

    test('byId falls back to the default for unknown or missing ids', () {
      expect(ReciterPack.byId(null), ReciterPack.alHusary);
      expect(ReciterPack.byId('nobody'), ReciterPack.alHusary);
      expect(ReciterPack.byId('alafasy'), ReciterPack.alafasy);
    });
  });

  group('one engine for every play button', () {
    late _HoldingAudio audio;
    late ProviderContainer c;

    Future<void> boot([Map<String, Object>? prefs]) async {
      SharedPreferences.setMockInitialValues(prefs ?? <String, Object>{});
      final SharedPreferences sp = await SharedPreferences.getInstance();
      audio = _HoldingAudio();
      c = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(sp),
          recitationPlayerProvider.overrideWith(
            (ref) => RecitationPlayerNotifier(
              audio: audio,
              sourceResolver: (PlaybackEvent e) async =>
                  ref.read(selectedReciterProvider).ayahUrl(e.ref),
              sleeper: (int ms) async {},
            ),
          ),
        ],
      );
      addTearDown(c.dispose);
    }

    test('an ayah button plays on the shared engine and carries on', () async {
      await boot();
      await c.read(recitationServiceProvider.notifier).play(2, 285);
      await pumpEventQueue();
      expect(audio.played, hasLength(1));
      expect(audio.played.single, endsWith('/002285.mp3'));
      expect(c.read(recitationServiceProvider).ayah, 285);
      expect(c.read(recitationPlayerProvider).playing, isTrue,
          reason: 'the range bar sees the same playback');

      audio.release();
      await pumpEventQueue();
      expect(audio.played, hasLength(2));
      expect(audio.played.last, endsWith('/002286.mp3'));
      expect(c.read(recitationServiceProvider).ayah, 286,
          reason: 'the highlighted ayah follows the engine');

      audio.release();
      await pumpEventQueue();
      expect(c.read(recitationServiceProvider).isIdle, isTrue,
          reason: 'end of surah');
    });

    test('starting a second ayah replaces the first, never overlaps', () async {
      await boot();
      final RecitationService s = c.read(recitationServiceProvider.notifier);
      await s.play(1, 1);
      await pumpEventQueue();
      await s.play(1, 4);
      await pumpEventQueue();
      expect(audio.played.map((String u) => u.split('/').last).toList(),
          <String>['001001.mp3', '001004.mp3']);
      expect(c.read(recitationServiceProvider).ayah, 4);
    });

    test('stop silences the engine and clears the highlight', () async {
      await boot();
      await c.read(recitationServiceProvider.notifier).play(1, 1);
      await pumpEventQueue();
      await c.read(recitationServiceProvider.notifier).stop();
      await pumpEventQueue();
      expect(c.read(recitationServiceProvider).isIdle, isTrue);
      expect(c.read(recitationPlayerProvider).playing, isFalse);
    });

    test('the chosen reciter is used and is remembered', () async {
      await boot();
      await c.read(selectedReciterProvider.notifier).select(ReciterPack.alafasy);
      await c.read(recitationServiceProvider.notifier).play(1, 1);
      await pumpEventQueue();
      expect(audio.played.single, contains('/Alafasy_128kbps/'));

      final SharedPreferences sp = await SharedPreferences.getInstance();
      expect(sp.getString(ReciterController.prefsKey), 'alafasy');
      final ProviderContainer again = ProviderContainer(
        overrides: <Override>[sharedPreferencesProvider.overrideWithValue(sp)],
      );
      addTearDown(again.dispose);
      expect(again.read(selectedReciterProvider), ReciterPack.alafasy);
    });

    test('out-of-range requests do nothing', () async {
      await boot();
      final RecitationService s = c.read(recitationServiceProvider.notifier);
      await s.play(0, 1);
      await s.play(1, 8);
      await s.play(115, 1);
      await pumpEventQueue();
      expect(audio.played, isEmpty);
      expect(c.read(recitationServiceProvider).isIdle, isTrue);
    });
  });

  test('a failing ayah stops with a failure and never plays something else',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        recitationPlayerProvider.overrideWith(
          (ref) => RecitationPlayerNotifier(
            audio: _BrokenAudio(),
            sourceResolver: (PlaybackEvent e) async => 'src',
            sleeper: (int ms) async {},
          ),
        ),
      ],
    );
    addTearDown(c.dispose);
    await c.read(recitationServiceProvider.notifier).play(1, 1);
    await pumpEventQueue();
    expect(c.read(recitationPlayerProvider).failed, isTrue);
    expect(c.read(recitationPlayerProvider).playing, isFalse);
    expect(c.read(recitationServiceProvider).isIdle, isTrue);
  });
}
