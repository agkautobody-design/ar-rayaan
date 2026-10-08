import 'dart:io';

import 'package:ar_rayaan/features/academy/application/audio_packs_provider.dart';
import 'package:ar_rayaan/features/academy/data/recitation_audio_repository.dart';
import 'package:ar_rayaan/features/academy/domain/recitation_audio.dart';
import 'package:ar_rayaan/app/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('downloadSurah', () {
    test('downloads with progress and returns local path', () async {
      final List<double> progress = <double>[];
      final client = MockClient((req) async {
        final body = List<int>.filled(4096, 9);
        return http.Response.bytes(body, 200);
      });
      final dir = await Directory.systemTemp.createTemp('ar_pack');
      addTearDown(() => dir.delete(recursive: true));

      final path = await RecitationAudioRepository.downloadSurah(
        pack: ReciterPack.alHusary,
        surah: 1,
        cacheDir: dir,
        onProgress: progress.add,
        client: client,
      );
      expect(path, isNotNull);
      expect(File(path!).existsSync(), isTrue);
      expect(path.endsWith('surah_001.mp3'), isTrue);
      expect(progress, isNotEmpty);
      expect(progress.last, closeTo(1.0, 0.001));

      // Cached: second call returns without network (client would throw).
      final again = await RecitationAudioRepository.downloadSurah(
        pack: ReciterPack.alHusary,
        surah: 1,
        cacheDir: dir,
        client: MockClient((_) async => throw StateError('no net')),
      );
      expect(again, path);
    });

    test('failure returns null, does not crash', () async {
      final client = MockClient((_) async => http.Response('x', 404));
      final dir = await Directory.systemTemp.createTemp('ar_pack');
      addTearDown(() => dir.delete(recursive: true));
      final path = await RecitationAudioRepository.downloadSurah(
        pack: ReciterPack.alHusary,
        surah: 2,
        cacheDir: dir,
        client: client,
      );
      expect(path, isNull);
    });
  });

  group('AudioPacksNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    Future<ProviderContainer> container() async {
      // setMockInitialValues runs once per test in setUp — calling it
      // again here would wipe the store and defeat the persistence test.
      final prefs = await SharedPreferences.getInstance();
      return ProviderContainer(overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
    }

    test('download marks surah downloaded and persists', () async {
      final c = await container();
      final notifier = c.read(audioPacksProvider.notifier);
      // Simulate a successful download by injecting state (network-free test):
      await notifier.markDownloaded(1);
      expect(c.read(audioPacksProvider), contains(1));
      c.dispose();

      final c2 = await container();
      expect(c2.read(audioPacksProvider), contains(1),
          reason: 'loaded from prefs');
      c2.dispose();
    });

    test('remove deletes from state', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      final n = c.read(audioPacksProvider.notifier);
      n.state = <int>{1, 2, 3};
      await n.remove(2);
      expect(c.read(audioPacksProvider), <int>{1, 3});
      c.dispose();
    });

    test('pruneTo keeps most recent N', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      final n = c.read(audioPacksProvider.notifier);
      n.state = <int>{1, 2, 3, 4, 5};
      await n.pruneTo(2);
      expect(c.read(audioPacksProvider).length, 2);
      c.dispose();
    });
  });
}
