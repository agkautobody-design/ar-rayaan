/// Sfx provider — tier state + play() with haptic twins.
library;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
import '../domain/sfx.dart';

final soundSettingsProvider =
    StateNotifierProvider<SoundSettingsNotifier, SoundSettings>((Ref ref) {
  return SoundSettingsNotifier(ref.watch(sharedPreferencesProvider));
});

class SoundSettingsNotifier extends StateNotifier<SoundSettings> {
  SoundSettingsNotifier(this._prefs)
      : super(SoundSettings(tier: SoundSettings.tierFrom(_prefs.getString(_key))));

  static const String _key = 'ar.sound.tier.v1';
  final SharedPreferences _prefs;

  Future<void> setTier(SoundTier tier) async {
    state = state.copyWith(tier: tier);
    await _prefs.setString(_key, tier.name);
  }
}

abstract final class SfxPlayer {
  /// Play a sound. Haptic twin fires at every tier (accessibility law);
  /// audio fires only when assets exist AND tier != off. Safe to call
  /// from anywhere — never throws, never blocks.
  static Future<void> play(Sfx sfx, SoundTier tier) async {
    // Haptic twin — always.
    switch (sfx) {
      case Sfx.tasbihTap:
      case Sfx.wordGraded:
        await HapticFeedback.lightImpact();
      case Sfx.dhikrMilestone:
      case Sfx.packDownloaded:
      case Sfx.dayComplete:
        await HapticFeedback.mediumImpact();
      case Sfx.stepTurn:
        await HapticFeedback.selectionClick();
      case Sfx.errorSoft:
        await HapticFeedback.heavyImpact();
    }
    // Audio layer — asset pass pending; hook preserved here so every
    // consumer is final the day the assets land.
    if (tier == SoundTier.off) return;
    // await _playAsset(sfx); // lands with the SFX asset pack
  }
}
