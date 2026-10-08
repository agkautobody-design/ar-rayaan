/// Adhkar domain models. Bundled content: Hisn al-Muslim (Fortress of the
/// Muslim) — morning/evening set and after-prayer set, Arabic with repeat
/// counts (rn0x/Adhkar-json). English meanings (O-12): established
/// Darussalam rendering, abridged to match the bundled Arabic.
class Dhikr {
  const Dhikr({
    required this.number,
    required this.arabic,
    required this.count,
    this.translation,
  });

  final int number;
  final String arabic;

  /// Repetitions prescribed (1, 3, 7, 10, 100…).
  final int count;

  /// English meaning of the dhikr (O-12). Null for legacy data.
  final String? translation;
}

class AdhkarSet {
  const AdhkarSet({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.items,
  });

  /// "morning" | "evening" | "after-prayer"
  final String id;
  final String titleEn;
  final String titleAr;
  final List<Dhikr> items;

  /// Total repetitions across the set (progress denominator).
  int get totalRepetitions => items.fold(0, (sum, d) => sum + d.count);
}
