/// The Sound of Ar-Rayaan — sonic core (infrastructure).
/// Tiered, user-owned, haptic-twin-first per the Sonic Design System.
/// Audio assets (bead click, parchment, rain beds) land in a later asset
/// pass; this core ships the settings, the twins, and the consumers.
library;

/// Every sound the app can make. Each has a haptic twin that plays at
/// ALL tiers (silent users lose nothing) and an audio asset slot that
/// plays only when assets exist AND the tier allows.
enum Sfx {
  tasbihTap,
  dhikrMilestone,
  stepTurn,
  wordGraded,
  packDownloaded,
  dayComplete,
  errorSoft,
}

enum SoundTier { off, gentle, full }

class SoundSettings {
  const SoundSettings({this.tier = SoundTier.off});

  final SoundTier tier;

  /// Sound Off is the DEFAULT (Sonic System law: the app introduces its
  /// voice only when invited).
  bool get hapticsAlways => true;

  SoundSettings copyWith({SoundTier? tier}) =>
      SoundSettings(tier: tier ?? this.tier);

  String get storageValue => tier.name;

  static SoundTier tierFrom(String? name) => SoundTier.values.asNameMap()[name] ?? SoundTier.off;
}
