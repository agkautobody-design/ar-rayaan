/// How the My Journey ring is worked out. Pure Dart, so the arithmetic can
/// be tested and the screen can explain it in plain words.
///
/// The ring starts empty (a calm invitation, never a failure) and moves only when the person does something the
/// app can actually see: counting adhkar today, opening a surah, saving a
/// reflection, finishing a lesson, writing down memorised ayat.
library;

/// One slice of the ring.
class RingPart {
  const RingPart({
    required this.label,
    required this.weight,
    required this.fraction,
  });

  /// Plain-words name of the step ("Adhkar counted today").
  final String label;

  /// Share of the whole ring, 0..1. All parts add up to 1.
  final double weight;

  /// How much of this part is done, 0..1.
  final double fraction;

  bool get done => fraction >= 1;

  /// What this part adds to the ring, 0..1.
  double get contribution => weight * fraction;
}

/// What the ring counts. Everything here is recorded on this device.
class RingInputs {
  const RingInputs({
    this.adhkarDone = 0,
    this.adhkarTotal = 0,
    this.openedSurah = false,
    this.reflections = 0,
    this.lessonsDone = 0,
    this.ayatMemorised = 0,
    this.ayatPlanTotal = 0,
  });

  /// Adhkar repetitions counted today, and the total in all sets.
  final int adhkarDone;
  final int adhkarTotal;

  /// A surah has been opened in the Qur'an reader.
  final bool openedSurah;

  /// NOOR reflections saved.
  final int reflections;

  /// Academy lessons finished.
  final int lessonsDone;

  /// Ayat the learner has written down as memorised in the Hifz planner.
  final int ayatMemorised;

  /// Ayat in the learner's Hifz plan (564 for all of Juz Amma). The memorised
  /// part of the ring is the share of this plan written down; when no plan
  /// size is known, any ayah written down counts as the whole part.
  final int ayatPlanTotal;
}

/// The five parts of the ring, in the order the screen lists them.
List<RingPart> ringParts(RingInputs i) {
  final double adhkar = i.adhkarTotal <= 0
      ? 0
      : (i.adhkarDone / i.adhkarTotal).clamp(0.0, 1.0).toDouble();
  return <RingPart>[
    RingPart(label: 'Adhkar counted today', weight: 0.45, fraction: adhkar),
    RingPart(
      label: 'Opened a surah',
      weight: 0.10,
      fraction: i.openedSurah ? 1 : 0,
    ),
    RingPart(
      label: 'Saved a reflection',
      weight: 0.15,
      fraction: i.reflections > 0 ? 1 : 0,
    ),
    RingPart(
      label: 'Finished a lesson',
      weight: 0.15,
      fraction: i.lessonsDone > 0 ? 1 : 0,
    ),
    RingPart(
      label: 'Marked ayat as memorised',
      weight: 0.15,
      fraction: i.ayatPlanTotal > 0
          ? (i.ayatMemorised / i.ayatPlanTotal).clamp(0.0, 1.0).toDouble()
          : (i.ayatMemorised > 0 ? 1 : 0),
    ),
  ];
}

/// The ring value, 0..1. Exactly 0 when nothing has been done.
double ringValue(RingInputs i) {
  double sum = 0;
  for (final RingPart p in ringParts(i)) {
    sum += p.contribution;
  }
  return sum.clamp(0.0, 1.0).toDouble();
}

/// Text for the days-this-week line.
String daysThisWeekText(int days) =>
    days <= 0 ? 'Nothing yet, start whenever you like' : '$days of 7 days';

/// Plain sentence under the ring.
const String kRingEmptyLine = 'Start whenever you like.';

const String kRingExplanation =
    'This ring starts empty, and that is fine: start whenever you like. It '
    'fills as you do five things: count your adhkar today (the largest '
    'part), save a reflection, finish a lesson, open a surah, and write down '
    'ayat you have memorised (in proportion to the ayat in your Hifz plan, '
    'so 564 ayat of Juz Amma fill that part). It is a starting guide, not a '
    'score.';
