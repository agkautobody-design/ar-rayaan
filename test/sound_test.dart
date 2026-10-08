import 'package:ar_rayaan/app/core/sound/sound_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Recitation numbering', () {
    test('surah ayah counts total 6236 (standard mushaf)', () {
      final int total = kSurahAyahCounts.fold(0, (int a, int b) => a + b);
      expect(total, 6236);
      expect(kSurahAyahCounts.length, 114);
    });

    test('global ayah numbers map correctly', () {
      expect(globalAyahNumber(1, 1), 1); // Al-Fatihah 1
      expect(globalAyahNumber(1, 7), 7);
      expect(globalAyahNumber(2, 1), 8); // Al-Baqarah 1
      expect(globalAyahNumber(2, 286), 293);
      expect(globalAyahNumber(114, 6), 6236); // An-Nas 6 — last ayah
    });
  });

  group('Sound settings', () {
    test('ambient defaults to on and persists when toggled', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final SoundSettings initial = container.read(soundSettingsProvider);
      expect(initial.ambient, isTrue);

      await container.read(soundSettingsProvider.notifier).setAmbient(false);
      expect(container.read(soundSettingsProvider).ambient, isFalse);

      await container.read(soundSettingsProvider.notifier).setAmbient(true);
      expect(container.read(soundSettingsProvider).ambient, isTrue);
    });
  });

  group('Services degrade gracefully without platform plugins', () {
    test('ambient request/unlock never throws', () {
      final AmbientService service = AmbientService();
      service.request();
      service.unlock();
      service.setEnabled(false);
      service.release();
    });

    test('adhan state machine: play marks playing, stop resets', () async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(adhanServiceProvider), isFalse);
      await container.read(adhanServiceProvider.notifier).play();
      expect(container.read(adhanServiceProvider), isTrue);
      await container.read(adhanServiceProvider.notifier).stop();
      expect(container.read(adhanServiceProvider), isFalse);
    });

    test('recitation state machine: play, toggle off, idle', () async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(recitationServiceProvider).isIdle, isTrue);
      await container.read(recitationServiceProvider.notifier).play(2, 255);
      expect(container.read(recitationServiceProvider).surah, 2);
      expect(container.read(recitationServiceProvider).ayah, 255);
      // Toggling the same ayah stops recitation.
      await container.read(recitationServiceProvider.notifier).toggle(2, 255);
      expect(container.read(recitationServiceProvider).isIdle, isTrue);
    });

    test('speech speak/stop never throws', () async {
      final SpeechService service = SpeechService();
      await service.speak('As-Salaamu Alaikum');
      await service.stop();
    });
  });
}
