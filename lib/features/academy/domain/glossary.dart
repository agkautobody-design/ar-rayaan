/// A small inline glossary for the words the lessons use without explaining
/// (taqwa, nisab, riba, qada, tawaf ...).
///
/// RULE: every definition here is the plain, widely agreed meaning of the
/// word, in one or two sentences. It decides nothing about a ruling and
/// quotes no Qur'an or hadith. Where schools of law differ on a detail, the
/// definition leaves the detail out rather than choose a side. A word is only
/// added when its meaning can be stated that safely; anything contested stays
/// out and is left to Hadi and a scholar.
///
/// Pure Dart: [findGlossaryTerms] is what the lesson player uses to underline
/// the words in a step's text.
library;

class GlossaryEntry {
  const GlossaryEntry({
    required this.term,
    required this.definition,
    this.aliases = const <String>[],
  });

  /// The word as shown in the glossary sheet.
  final String term;

  /// The plain meaning, one or two sentences.
  final String definition;

  /// Other spellings the lessons use (matched the same way as [term]).
  final List<String> aliases;
}

/// A glossary word found in a piece of text.
class GlossaryMatch {
  const GlossaryMatch(this.start, this.end, this.entry);

  /// Offsets into the text: [start] inclusive, [end] exclusive.
  final int start;
  final int end;
  final GlossaryEntry entry;
}

const List<GlossaryEntry> kGlossary = <GlossaryEntry>[
  GlossaryEntry(
    term: 'taqwa',
    definition: 'Being mindful of Allah: doing what pleases Him and staying '
        'away from what displeases Him, in public and in private.',
  ),
  GlossaryEntry(
    term: 'nisab',
    definition: 'The minimum amount of wealth a person must hold before zakat '
        'is due on it.',
  ),
  GlossaryEntry(
    term: 'hawl',
    definition: 'The lunar year that wealth is held for. Zakat on savings is '
        'due once the nisab has been held for a full hawl.',
  ),
  GlossaryEntry(
    term: 'zakat',
    aliases: <String>['zakah'],
    definition: 'The yearly giving of a set share of one’s savings to '
        'people in need. It is one of the five pillars of Islam.',
  ),
  GlossaryEntry(
    term: 'riba',
    definition: 'Interest or usury: an extra amount charged on a loan. Islam '
        'forbids it. Scholars discuss its exact limits in detail.',
  ),
  GlossaryEntry(
    term: 'qada',
    definition: 'Making up a prayer or a fast that was missed.',
  ),
  GlossaryEntry(
    term: 'tawaf',
    definition: 'Walking around the Kaaba seven times as an act of worship, '
        'in Hajj and in Umrah.',
  ),
  GlossaryEntry(
    term: 'sa\'i',
    aliases: <String>['sa’i'],
    definition: 'Walking seven times between the hills of Safa and Marwah, '
        'in Hajj and in Umrah.',
  ),
  GlossaryEntry(
    term: 'Arafat',
    definition: 'The plain near Makkah where pilgrims stand in prayer on the '
        'ninth day of Dhul-Hijjah. It is the high point of Hajj.',
  ),
  GlossaryEntry(
    term: 'Muzdalifah',
    definition: 'A place between Arafat and Mina where pilgrims stop on the '
        'night after Arafat during Hajj.',
  ),
  GlossaryEntry(
    term: 'Mina',
    definition: 'A valley near Makkah where pilgrims stay for some days '
        'during Hajj.',
  ),
  GlossaryEntry(
    term: 'ihram',
    definition: 'The state a pilgrim enters, with the intention for Hajj or '
        'Umrah, which begins the pilgrimage.',
  ),
  GlossaryEntry(
    term: 'Umrah',
    definition: 'The smaller pilgrimage to Makkah, which can be made at any '
        'time of the year.',
  ),
  GlossaryEntry(
    term: 'barakah',
    definition: 'Blessing: goodness and increase that Allah places in '
        'something, beyond what can be counted.',
  ),
  GlossaryEntry(
    term: 'halal',
    definition: 'Permitted in Islam.',
  ),
  GlossaryEntry(
    term: 'haram',
    definition: 'Forbidden in Islam.',
  ),
  GlossaryEntry(
    term: 'niyyah',
    definition: 'Intention: the decision in the heart to do an act for the '
        'sake of Allah.',
  ),
  GlossaryEntry(
    term: 'sadaqah',
    definition: 'Voluntary charity: any giving or kindness offered for the '
        'sake of Allah, beyond the required zakat.',
  ),
  GlossaryEntry(
    term: 'wudu',
    definition: 'The washing a Muslim does before prayer.',
  ),
  GlossaryEntry(
    term: 'salah',
    definition: 'Prayer, above all the five daily prayers, the second pillar '
        'of Islam.',
  ),
  GlossaryEntry(
    term: 'dhikr',
    definition: 'Remembrance of Allah, for example by repeating His praise.',
  ),
  GlossaryEntry(
    term: 'sunnah',
    definition: 'The way of the Prophet ﷺ: what he said, did and approved.',
  ),
];

final RegExp _letter = RegExp(r'\p{L}', unicode: true);

bool _isLetter(String ch) => _letter.hasMatch(ch);

/// The glossary words in [text], left to right, never overlapping. Whole
/// words only (the word "zakatable" does not match "zakat"), any letter case.
/// A word that appears several times is found every time.
List<GlossaryMatch> findGlossaryTerms(
  String text, {
  List<GlossaryEntry> glossary = kGlossary,
}) {
  final String lower = text.toLowerCase();
  final List<GlossaryMatch> found = <GlossaryMatch>[];
  for (final GlossaryEntry e in glossary) {
    for (final String form in <String>[e.term, ...e.aliases]) {
      final String needle = form.toLowerCase();
      int from = 0;
      while (true) {
        final int at = lower.indexOf(needle, from);
        if (at < 0) break;
        final int end = at + needle.length;
        from = at + 1;
        final bool leftOk = at == 0 || !_isLetter(lower[at - 1]);
        final bool rightOk = end >= lower.length || !_isLetter(lower[end]);
        if (leftOk && rightOk) found.add(GlossaryMatch(at, end, e));
      }
    }
  }
  found.sort((GlossaryMatch a, GlossaryMatch b) {
    final int byStart = a.start.compareTo(b.start);
    return byStart != 0 ? byStart : b.end.compareTo(a.end);
  });
  final List<GlossaryMatch> out = <GlossaryMatch>[];
  int lastEnd = 0;
  for (final GlossaryMatch m in found) {
    if (m.start < lastEnd) continue;
    out.add(m);
    lastEnd = m.end;
  }
  return out;
}

/// The distinct entries found in [text], in order of first appearance.
List<GlossaryEntry> glossaryEntriesIn(String text) {
  final List<GlossaryEntry> out = <GlossaryEntry>[];
  for (final GlossaryMatch m in findGlossaryTerms(text)) {
    if (!out.contains(m.entry)) out.add(m.entry);
  }
  return out;
}
