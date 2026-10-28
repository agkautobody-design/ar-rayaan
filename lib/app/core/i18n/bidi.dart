/// Small bidirectional-text helpers. Pure Dart (no Flutter import) so they
/// can be unit tested alone.
///
/// Two problems show up when English text sits inside a right-to-left screen
/// (Arabic or Urdu layout):
///  * a full stop, question mark or quote at the end of an English sentence
///    jumps to the wrong end (".it", "?How do you work");
///  * a clock time such as "4:39 AM" is drawn as "AM 4:39".
/// The first is fixed by giving Latin-script text a left-to-right paragraph
/// direction ([startsWithLatin]); the second by isolating the time
/// ([isolateLtr]) so the digits and AM/PM keep their order inside any
/// surrounding right-to-left sentence.
library;

/// Left-to-right isolate (U+2066) and pop directional isolate (U+2069).
const String kLri = '\u2066';
const String kPdi = '\u2069';

bool _isLatinLetter(int c) =>
    (c >= 0x41 && c <= 0x5A) ||
    (c >= 0x61 && c <= 0x7A) ||
    (c >= 0xC0 && c <= 0x24F && c != 0xD7 && c != 0xF7) ||
    (c >= 0x1E00 && c <= 0x1EFF);

bool _isRtlLetter(int c) =>
    (c >= 0x0590 && c <= 0x08FF) ||
    (c >= 0xFB1D && c <= 0xFDFF) ||
    (c >= 0xFE70 && c <= 0xFEFF);

bool _isOtherLetter(int c) =>
    // Bengali, Devanagari and other left-to-right non-Latin scripts.
    (c >= 0x0900 && c <= 0x0DFF) || (c >= 0x4E00 && c <= 0x9FFF);

/// True when the first letter in [text] is Latin script. Digits, spaces and
/// punctuation before it are skipped. False for Arabic, Urdu, Bangla or text
/// with no letters at all.
bool startsWithLatin(String text) {
  for (final int c in text.runes) {
    if (_isLatinLetter(c)) return true;
    if (_isRtlLetter(c) || _isOtherLetter(c)) return false;
  }
  return false;
}

/// True when the first letter in [text] is in an Arabic-script block.
bool startsWithRtlScript(String text) {
  for (final int c in text.runes) {
    if (_isRtlLetter(c)) return true;
    if (_isLatinLetter(c) || _isOtherLetter(c)) return false;
  }
  return false;
}

/// Wraps [text] in a left-to-right isolate so it keeps its own order inside a
/// right-to-left sentence.
String isolateLtr(String text) => '$kLri$text$kPdi';

/// Wraps every line of [text] in its own left-to-right isolate.
///
/// For English that follows a note written in Arabic or Urdu (a reply that has
/// no checked translation): the paragraph then starts with a right-to-left
/// letter, so the English inside it was laid out right-to-left and its
/// punctuation moved (an opening quotation mark next to the symbol after
/// "the Prophet", a full stop at the wrong end). An isolate closes at the end
/// of a line, so each line carries its own.
String isolateLtrLines(String text) => text
    .split('\n')
    .map((String line) => line.trim().isEmpty ? line : '$kLri$line$kPdi')
    .join('\n');

final RegExp _timeLike = RegExp(r'^\d{1,2}:\d{2}(\s?[AaPp]\.?[Mm]\.?)?$');

/// True for a bare clock time ("4:39", "4:39 AM", "16:05").
bool looksLikeClockTime(String s) => _timeLike.hasMatch(s.trim());
