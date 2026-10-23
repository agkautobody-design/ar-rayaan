import 'package:shared_preferences/shared_preferences.dart';

import '../domain/tasbeeh_counter.dart';

/// What the counter screen remembers between visits. Everything stays on the
/// device.
class TasbeehSettings {
  const TasbeehSettings({this.volumeMode = false, this.keepAwake = false});

  /// "Count with volume buttons" (Android only).
  final bool volumeMode;

  /// "Keep screen on while counting".
  final bool keepAwake;
}

class TasbeehStore {
  const TasbeehStore(this._prefs);

  final SharedPreferences _prefs;

  static const String kCount = 'ar.tasbeeh.count';
  static const String kRounds = 'ar.tasbeeh.rounds';
  static const String kTarget = 'ar.tasbeeh.target';
  static const String kLabel = 'ar.tasbeeh.label';
  static const String kVolume = 'ar.tasbeeh.volume';
  static const String kAwake = 'ar.tasbeeh.awake';

  TasbeehState loadCounter() {
    try {
      return TasbeehLogic.sanitize(
        TasbeehState(
          count: _prefs.getInt(kCount) ?? 0,
          rounds: _prefs.getInt(kRounds) ?? 0,
          target: _prefs.getInt(kTarget) ?? kTasbeehDefaultTarget,
          label: _prefs.getString(kLabel) ?? '',
        ),
      );
    } catch (_) {
      return const TasbeehState();
    }
  }

  TasbeehSettings loadSettings() {
    try {
      return TasbeehSettings(
        volumeMode: _prefs.getBool(kVolume) ?? false,
        keepAwake: _prefs.getBool(kAwake) ?? false,
      );
    } catch (_) {
      return const TasbeehSettings();
    }
  }

  Future<void> saveCounter(TasbeehState s) async {
    try {
      await _prefs.setInt(kCount, s.count);
      await _prefs.setInt(kRounds, s.rounds);
      await _prefs.setInt(kTarget, s.target);
      await _prefs.setString(kLabel, s.label);
    } catch (_) {
      // In memory only for this visit.
    }
  }

  Future<void> saveSettings(TasbeehSettings s) async {
    try {
      await _prefs.setBool(kVolume, s.volumeMode);
      await _prefs.setBool(kAwake, s.keepAwake);
    } catch (_) {
      // In memory only for this visit.
    }
  }
}
