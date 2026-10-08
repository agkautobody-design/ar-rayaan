import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/academy/application/sfx_provider.dart';
import 'package:ar_rayaan/features/academy/domain/sfx.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // KNOWN TRAP (handoff rule): the mock reset lives HERE, once per
    // test — never inside a helper that a test calls twice (it would
    // wipe the store between containers and defeat persistence tests).
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<ProviderContainer> container() async {
    final prefs = await SharedPreferences.getInstance();
    return ProviderContainer(overrides: <Override>[
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
  }

  test('default tier is off (the app is silent until invited)', () async {
    final c = await container();
    expect(c.read(soundSettingsProvider).tier, SoundTier.off);
    c.dispose();
  });

  test('tier persists across instances', () async {
    final c1 = await container();
    await c1.read(soundSettingsProvider.notifier).setTier(SoundTier.full);
    c1.dispose();
    final c2 = await container();
    expect(c2.read(soundSettingsProvider).tier, SoundTier.full);
    c2.dispose();
  });

  test('play() never throws at any tier (haptic twin safe in tests)', () async {
    final c = await container();
    for (final Sfx sfx in Sfx.values) {
      for (final SoundTier tier in SoundTier.values) {
        await SfxPlayer.play(sfx, tier); // must complete without throwing
      }
    }
    c.dispose();
  });

  test('unknown stored tier degrades to off', () {
    expect(SoundSettings.tierFrom('loud'), SoundTier.off);
    expect(SoundSettings.tierFrom(null), SoundTier.off);
    expect(SoundSettings.tierFrom('full'), SoundTier.full);
  });
}
