import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';

/// The look of the boards and cards in the learning games.
enum GameCardTheme { night, parchment, contrast }

extension GameCardThemeLabel on GameCardTheme {
  String get label => switch (this) {
        GameCardTheme.night => 'Night gold',
        GameCardTheme.parchment => 'Parchment',
        GameCardTheme.contrast => 'High contrast',
      };
}

/// What a person can set for the games. Kept on this device only.
class GameSettings {
  const GameSettings({
    this.sound = false,
    this.vibration = true,
    this.showHints = true,
    this.theme = GameCardTheme.night,
  });

  /// Off unless the person turns it on. No game sounds are shipped yet, so
  /// the switch is kept for when they are.
  final bool sound;
  final bool vibration;

  /// Whether the free hints are offered. Off hides every hint button and
  /// starts new quizzes without hints.
  final bool showHints;
  final GameCardTheme theme;

  GameSettings copyWith({
    bool? sound,
    bool? vibration,
    bool? showHints,
    GameCardTheme? theme,
  }) =>
      GameSettings(
        sound: sound ?? this.sound,
        vibration: vibration ?? this.vibration,
        showHints: showHints ?? this.showHints,
        theme: theme ?? this.theme,
      );
}

/// Where the settings are kept.
abstract final class GameSettingsKeys {
  static const String sound = 'ar.games.settings.sound';
  static const String vibration = 'ar.games.settings.vibration';
  static const String showHints = 'ar.games.settings.hints';
  static const String theme = 'ar.games.settings.theme';
}

/// Reads and writes [GameSettings]. Safe without storage: it then keeps the
/// choices for this visit only.
class GameSettingsController extends Notifier<GameSettings> {
  SharedPreferences? _prefs() {
    try {
      return ref.read(sharedPreferencesProvider);
    } catch (_) {
      return null;
    }
  }

  @override
  GameSettings build() {
    final SharedPreferences? p = _prefs();
    if (p == null) return const GameSettings();
    try {
      return GameSettings(
        sound: p.getBool(GameSettingsKeys.sound) ?? false,
        vibration: p.getBool(GameSettingsKeys.vibration) ?? true,
        showHints: p.getBool(GameSettingsKeys.showHints) ?? true,
        theme: GameCardTheme.values.asNameMap()[
                p.getString(GameSettingsKeys.theme)] ??
            GameCardTheme.night,
      );
    } catch (_) {
      return const GameSettings();
    }
  }

  void _write(Future<bool> Function(SharedPreferences p) w) {
    final SharedPreferences? p = _prefs();
    if (p == null) return;
    try {
      unawaited(w(p).catchError((Object _) => false));
    } catch (_) {}
  }

  void setSound(bool v) {
    state = state.copyWith(sound: v);
    _write((SharedPreferences p) => p.setBool(GameSettingsKeys.sound, v));
  }

  void setVibration(bool v) {
    state = state.copyWith(vibration: v);
    _write((SharedPreferences p) => p.setBool(GameSettingsKeys.vibration, v));
  }

  void setShowHints(bool v) {
    state = state.copyWith(showHints: v);
    _write((SharedPreferences p) => p.setBool(GameSettingsKeys.showHints, v));
  }

  void setTheme(GameCardTheme t) {
    state = state.copyWith(theme: t);
    _write((SharedPreferences p) => p.setString(GameSettingsKeys.theme, t.name));
  }

  /// Puts every setting back to its default.
  void reset() {
    state = const GameSettings();
    _write((SharedPreferences p) async {
      await p.remove(GameSettingsKeys.sound);
      await p.remove(GameSettingsKeys.vibration);
      await p.remove(GameSettingsKeys.showHints);
      await p.remove(GameSettingsKeys.theme);
      return true;
    });
  }
}

final NotifierProvider<GameSettingsController, GameSettings>
    gameSettingsProvider =
    NotifierProvider<GameSettingsController, GameSettings>(
  GameSettingsController.new,
);
