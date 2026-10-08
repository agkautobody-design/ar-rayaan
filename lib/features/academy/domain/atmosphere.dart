/// The Living Art Layer — Phase A: the atmosphere engine.
/// Art = f(content, emotion, time). This engine resolves WHICH atmosphere
/// a screen should show; the scene assets attach to these keys when the
/// art packs land. Per the Living Art doc: emotion first, time second,
/// PEACE the eternal fallback; the app's own palette everywhere.
library;

enum AtmosphereEmotion {
  awe,
  peace,
  hope,
  longing,
  joy,
  solemn,
  morning,
  night,
}

/// The resolved atmosphere a screen renders. [sceneKey] names the scene
/// family; [lightState] its light; art packs ship scenes per key.
class Atmosphere {
  const Atmosphere({
    required this.emotion,
    required this.sceneKey,
    required this.lightState,
    required this.tint,
  });

  final AtmosphereEmotion emotion;

  /// e.g. 'horizon', 'arch-lattice', 'ornament', 'calligraphy',
  /// 'night-sky', 'courtyard', 'garden', 'lattice-rain'
  final String sceneKey;
  final String lightState;

  /// The color wash the atmosphere layer paints over the scene
  /// (ARGB int; consumed by AtmosphereLayer).
  final int tint;
}

abstract final class AtmosphereEngine {
  /// Resolve the atmosphere: the screen's emotion wins (accepted as
  /// [emotion] or [contentEmotion]); when the screen is neutral, the hour
  /// of day carries the mood ([hour] or [now]; defaults to the real clock).
  static Atmosphere resolve({
    AtmosphereEmotion? emotion,
    AtmosphereEmotion? contentEmotion,
    int? hour,
    DateTime? now,
  }) {
    final AtmosphereEmotion? e = emotion ?? contentEmotion;
    final int h = hour ?? now?.hour ?? DateTime.now().hour;
    if (e != null) return _forEmotion(e);
    if (h >= 4 && h < 7) return _forEmotion(AtmosphereEmotion.morning);
    if (h >= 7 && h < 16) return _forEmotion(AtmosphereEmotion.peace);
    if (h >= 16 && h < 19) return _forEmotion(AtmosphereEmotion.hope);
    if (h >= 19 && h < 23) return _forEmotion(AtmosphereEmotion.solemn);
    return _forEmotion(AtmosphereEmotion.night);
  }

  static Atmosphere _forEmotion(AtmosphereEmotion e) => switch (e) {
        AtmosphereEmotion.awe => const Atmosphere(
            emotion: AtmosphereEmotion.awe,
            sceneKey: 'horizon',
            lightState: 'dawn-breaking',
            tint: 0xFFE9C46A),
        AtmosphereEmotion.peace => const Atmosphere(
            emotion: AtmosphereEmotion.peace,
            sceneKey: 'arch-lattice',
            lightState: 'lamplight',
            tint: 0xFFE8D8B3),
        AtmosphereEmotion.hope => const Atmosphere(
            emotion: AtmosphereEmotion.hope,
            sceneKey: 'garden',
            lightState: 'clearing-gold',
            tint: 0xFFF6E7C8),
        AtmosphereEmotion.longing => const Atmosphere(
            emotion: AtmosphereEmotion.longing,
            sceneKey: 'mihrab',
            lightState: 'blue-hour',
            tint: 0xFF5C6B8F),
        AtmosphereEmotion.joy => const Atmosphere(
            emotion: AtmosphereEmotion.joy,
            sceneKey: 'ornament',
            lightState: 'full-gold',
            tint: 0xFFF1C40F),
        AtmosphereEmotion.solemn => const Atmosphere(
            emotion: AtmosphereEmotion.solemn,
            sceneKey: 'night-desert',
            lightState: 'low-moon',
            tint: 0xFF24406E),
        AtmosphereEmotion.morning => const Atmosphere(
            emotion: AtmosphereEmotion.morning,
            sceneKey: 'courtyard',
            lightState: 'first-light',
            tint: 0xFFF9E4BC),
        AtmosphereEmotion.night => const Atmosphere(
            emotion: AtmosphereEmotion.night,
            sceneKey: 'night-sky',
            lightState: 'moon-silver',
            tint: 0xFF16233F),
      };
}
