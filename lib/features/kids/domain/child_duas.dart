/// The short duas a child can open in child mode, each with a meaning written
/// for a child (one or two short sentences, no rulings, no grades).
///
/// The Arabic, the transliteration and the sources are NOT written here: they
/// are the same as on the adult dua page (see assets/stories/dailyduas.json),
/// which a child's page opens by [storyId]. Only the plain meaning and the
/// moment to say it are for children.
///
/// Only duas whose wording is established are listed (not those whose exact
/// words are graded weak). Reviewed in the scholar register (child-mode duas).
class ChildDua {
  const ChildDua({
    required this.storyId,
    required this.title,
    required this.when,
    required this.meaning,
  });

  /// The id of the dua page (assets/stories/dailyduas.json).
  final String storyId;

  /// What a child calls it.
  final String title;

  /// When we say it, in a few words.
  final String when;

  /// What it means, for a child.
  final String meaning;
}

const List<ChildDua> kChildDuas = <ChildDua>[
  ChildDua(
    storyId: 'dua-waking',
    title: 'When we wake up',
    when: 'First thing in the morning',
    meaning:
        'We thank Allah for waking us up again after sleep, and we remember '
        'that we will all go back to Him.',
  ),
  ChildDua(
    storyId: 'dua-eat-before',
    title: 'Before we eat',
    when: 'At the start of a meal',
    meaning:
        'We say Allah’s name before we eat. If we forget at the start, '
        'we say: in the name of Allah, at the beginning and at the end.',
  ),
  ChildDua(
    storyId: 'dua-exit-home',
    title: 'When we leave the house',
    when: 'At the door, on the way out',
    meaning:
        'We say Allah’s name and ask Him to look after us. We trust Him, '
        'and we remember that all strength comes from Allah.',
  ),
  ChildDua(
    storyId: 'dua-parents',
    title: 'For mum and dad',
    when: 'Any time you like',
    meaning:
        'We ask Allah to be kind to our mum and dad, as they were kind to us '
        'when we were very small.',
  ),
  ChildDua(
    storyId: 'dua-rain',
    title: 'When it rains',
    when: 'When rain falls',
    meaning: 'We ask Allah to make the rain good and useful for everyone.',
  ),
];

/// The child's own meaning for a dua page, or null when there is none.
String? childMeaningFor(String storyId) {
  for (final ChildDua d in kChildDuas) {
    if (d.storyId == storyId) return d.meaning;
  }
  return null;
}

/// The credit line for a transliteration, in plain words. A source written as
/// a file or package name (for example an open-source collection and its
/// licence) is shown as a sentence a parent can read.
String transliterationCreditLine(String raw) {
  if (raw.contains('fitrahive/dua-dhikr')) {
    return 'Transliteration: from the open dua-dhikr collection (MIT licence), '
        'based on Hisn al-Muslim, and checked against the Arabic shown.';
  }
  return 'Transliteration: $raw';
}
