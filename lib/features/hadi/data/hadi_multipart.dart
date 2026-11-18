/// Splits a question that asks several things into its parts.
///
/// Pure Dart. It splits only on clear markers (a question mark followed by
/// more text, a semicolon, or a new "tell me / explain / what about"), keeps
/// at most three parts, and drops greetings and "I want to learn" lead-ins.
/// A single question comes back as an empty list: the caller then answers it
/// whole, as before.
library;

abstract final class HadiMultiPart {
  static final RegExp _cut = RegExp(
      r'(?<=[?;])\s+|\s+(?=(?:(?:and|also|then)\s+)*'
      r'(?:tell me|explain|teach me|show me|what about)\b)',
      caseSensitive: false);
  static final RegExp _lead = RegExp(
      r'^(?:hi|hello|hey|salam|assalamu? ?alaikum|as-?salamu? ?alaykum|'
      r'i want to learn(?: about islam)?|i would like to learn(?: about islam)?|'
      r'please)\W*$',
      caseSensitive: false);
  static final RegExp _modifier = RegExp(
      r'\b(?:sources?|references?|evidence|proof|cite|citation|dalil)\b',
      caseSensitive: false);
  static final RegExp _trail =
      RegExp(r'(?:\s+(?:and|also|then))+$', caseSensitive: false);
  static final RegExp _joiner =
      RegExp(r'^(?:(?:and|also|then)\s+)+', caseSensitive: false);

  static List<String> split(String q) {
    final List<String> out = <String>[];
    for (final String raw in q.trim().split(_cut)) {
      String p = raw.trim().replaceAll(RegExp(r'[;?]+$'), '').trim();
      p = p.replaceFirst(_joiner, '').replaceFirst(_trail, '').trim();
      if (p.isEmpty || _lead.hasMatch(p)) continue;
      final int words = p.split(RegExp(r'\s+')).length;
      if (words < 3) continue;
      // "Give me the source" modifies the question before it; it is not a
      // second question.
      if (words <= 6 && _modifier.hasMatch(p)) continue;
      out.add(p);
      if (out.length == 3) break;
    }
    return out.length >= 2 ? out : <String>[];
  }

  /// A short heading for a part: the part itself, cut at 70 characters.
  static String label(String part) {
    final String t = part.trim();
    final String cut = t.length <= 70 ? t : '${t.substring(0, 67)}...';
    return cut.isEmpty ? cut : cut[0].toUpperCase() + cut.substring(1);
  }
}
