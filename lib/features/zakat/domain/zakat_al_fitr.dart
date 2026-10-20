/// Zakat al-Fitr (sadaqat al-fitr) — the head-count charity due before the
/// Eid prayer.
///
/// What the sunnah fixes is a measure of FOOD per person, not a sum of money:
/// Ibn Umar reported that the Prophet ﷺ enjoined zakat al-fitr as one sa'
/// of dates or one sa' of barley on every Muslim, slave or free, male or
/// female, young or old, and ordered that it be paid before the people go
/// out to the Eid prayer (Sahih al-Bukhari 1503). A sa' is a measure of
/// volume that scholars convert to a weight (commonly cited as roughly 2 to
/// 3 kg) that varies with the food and the school, and the schools differ on
/// whether its cash value may be paid. So the app does NOT invent a figure:
/// the per-person amount is the user's own, taken from their mosque, charity
/// or scholar, and the app only multiplies it by the household.
library;

abstract final class ZakatAlFitr {
  /// Source line shown beside the card.
  static const String source = 'Sahih al-Bukhari 1503';

  /// People in the household, clamped to 1–99.
  static int clampPeople(int people) => people < 1 ? 1 : (people > 99 ? 99 : people);

  /// Total due for [people] at [perPerson] each; never negative.
  static double total({required int people, required double perPerson}) {
    if (perPerson <= 0) return 0;
    return clampPeople(people) * perPerson;
  }

  /// Total when the user works from a staple food instead of a figure their
  /// mosque announced: [people] x [kgPerPerson] x [pricePerKg]. Every number
  /// is the user's own (the weight of a sa' differs between scholars and
  /// schools, so the app supplies none); this is multiplication only.
  static double totalFromStaple({
    required int people,
    required double kgPerPerson,
    required double pricePerKg,
  }) {
    if (kgPerPerson <= 0 || pricePerKg <= 0) return 0;
    return clampPeople(people) * kgPerPerson * pricePerKg;
  }
}
