/// Plain-word glosses for terms that appear in the Huda guides.
///
/// Every gloss here is a neutral, literal translation of the word (or the
/// name the app already gives it, such as the guide titles "The Purifying
/// Wash" and "Dry Purification"). Nothing here states a ruling, a
/// requirement or a condition: the guide's own steps do that, with sources.
class GlossaryEntry {
  const GlossaryEntry(this.term, this.gloss, this.patterns);

  /// How the term is shown to the reader.
  final String term;

  /// A short, literal meaning.
  final String gloss;

  /// Lower-case spellings that count as a mention (apostrophes normalised
  /// to a plain ').
  final List<String> patterns;
}

const List<GlossaryEntry> kGuideGlossary = <GlossaryEntry>[
  GlossaryEntry('niyyah', 'intention', <String>['niyyah', 'niyyat']),
  GlossaryEntry(
    'sahih',
    'authentic: a grade given to a hadith',
    <String>['sahih'],
  ),
  GlossaryEntry('madhhab', 'a school of Islamic law', <String>['madhhab']),
  GlossaryEntry('sunnah', 'the way of the Prophet ﷺ', <String>['sunnah']),
  GlossaryEntry('siwak', 'a tooth-cleaning stick', <String>['siwak', 'miswak']),
  GlossaryEntry('suhoor', 'the meal before dawn', <String>['suhoor', 'sahur']),
  GlossaryEntry('fidyah', 'compensation', <String>['fidyah']),
  GlossaryEntry(
    'qunut',
    'a supplication (du’a) said in the prayer',
    <String>['qunut'],
  ),
  GlossaryEntry('thana’', 'praise', <String>["thana'", 'thana']),
  GlossaryEntry(
    'tashahhud',
    'the words said while sitting in the prayer',
    <String>['tashahhud', 'tashahud'],
  ),
  GlossaryEntry('takbir', 'saying “Allahu akbar”', <String>['takbir']),
  GlossaryEntry('ruku’', 'bowing', <String>["ruku'", 'ruku']),
  GlossaryEntry('sujud', 'prostration', <String>['sujud']),
  GlossaryEntry(
    'qibla',
    'the direction faced in prayer',
    <String>['qibla', 'qiblah'],
  ),
  GlossaryEntry(
    'wudu',
    'the washing before prayer, “the purifying wash”',
    <String>['wudu'],
  ),
  GlossaryEntry('ghusl', 'the full-body wash', <String>['ghusl']),
  GlossaryEntry('tayammum', 'dry purification', <String>['tayammum']),
  GlossaryEntry('imam', 'the one who leads the prayer', <String>['imam']),
  GlossaryEntry('adhan', 'the call to prayer', <String>['adhan']),
  GlossaryEntry('khutbah', 'sermon', <String>['khutbah']),
];

String _normalise(String s) => s
    .toLowerCase()
    .replaceAll('’', "'")
    .replaceAll('‘', "'")
    .replaceAll('ʼ', "'");

bool _isLetter(int c) => (c >= 0x61 && c <= 0x7A) || c > 0x7F;

bool _mentions(String text, String pattern) {
  int from = 0;
  while (true) {
    final int at = text.indexOf(pattern, from);
    if (at < 0) return false;
    final int end = at + pattern.length;
    final bool startOk = at == 0 || !_isLetter(text.codeUnitAt(at - 1));
    final bool endOk = end >= text.length || !_isLetter(text.codeUnitAt(end));
    if (startOk && endOk) return true;
    from = at + 1;
  }
}

/// The glossary entries whose words appear in [text], in glossary order.
List<GlossaryEntry> glossaryFor(String text) {
  final String t = _normalise(text);
  return <GlossaryEntry>[
    for (final GlossaryEntry e in kGuideGlossary)
      if (e.patterns.any((String p) => _mentions(t, p))) e,
  ];
}
