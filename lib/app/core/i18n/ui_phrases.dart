/// Phrase translation for interface text that is written in English at the
/// call site (a screen title, a button, a helper sentence).
///
/// Every phrase in [kUiPhrases] (ui_phrases_data.dart) is a MACHINE-DRAFTED
/// translation into Arabic, Urdu and Bangla and has NOT been read by a native
/// speaker. The app says so on every screen that carries support, safety or
/// religious content (NativeReviewNote), and the phrases are listed for review
/// in docs/SCHOLAR_REVIEW_REGISTER.md and docs/OWNER_ACTIONS.md.
///
/// Rules this file keeps:
///  * Qur'an, hadith and du'a text is never translated here. A string that
///    quotes scripture is not in the table and shows as written.
///  * Anything not in the table is shown in English. Nothing is guessed.
///  * A phrase may hold `{}` slots for numbers, names and times; the
///    translation names them `{1}`, `{2}` in the order they appear in the
///    English. A slot is itself translated when it is a known phrase (a
///    prayer name, say).
///
/// Pure Dart (no Flutter import) so it can be unit tested alone.
library;

import 'bidi.dart';
import 'ui_labels.dart';
import 'ui_phrases_data.dart';

/// The languages the phrase table covers, in column order of [kUiPhrases].
const List<String> kPhraseLanguages = <String>['ar', 'ur', 'bn'];

/// Languages written right-to-left among [kPhraseLanguages].
const Set<String> kPhraseRtl = <String>{'ar', 'ur'};

/// True when [lang] has translated phrases.
bool hasPhraseLanguage(String lang) => kPhraseLanguages.contains(lang);

int _col(String lang) => kPhraseLanguages.indexOf(lang);

class _Pattern {
  _Pattern(this.key, this.values)
      : slots = '{}'.allMatches(key).length,
        regex = _compile(key),
        head = key.substring(0, key.indexOf('{}'));

  final String key;
  final List<String> values;
  final int slots;
  final RegExp regex;
  final String head;

  static RegExp _compile(String key) {
    final List<String> parts = key.split('{}');
    final StringBuffer b = StringBuffer('^');
    for (int i = 0; i < parts.length; i++) {
      b.write(RegExp.escape(parts[i]));
      if (i < parts.length - 1) b.write(r'([\s\S]+?)');
    }
    b.write(r'$');
    return RegExp(b.toString());
  }
}

List<_Pattern>? _patternsCache;

List<_Pattern> get _patterns => _patternsCache ??= (<_Pattern>[
      for (final MapEntry<String, List<String>> e in kUiPhrases.entries)
        if (e.key.contains('{}')) _Pattern(e.key, e.value),
    ]..sort((_Pattern a, _Pattern b) => b.key.replaceAll('{}', '').length
        .compareTo(a.key.replaceAll('{}', '').length)));

/// The English phrase keys that have `{}` slots.
Iterable<String> get patternKeys =>
    kUiPhrases.keys.where((String k) => k.contains('{}'));

String _fillSlot(String value, String lang, int depth) {
  if (looksLikeClockTime(value) && kPhraseRtl.contains(lang)) {
    return isolateLtr(value.trim());
  }
  return _translate(value, lang, depth + 1);
}

String _translate(String s, String lang, int depth) {
  final int c = _col(lang);
  if (c < 0 || s.isEmpty || depth > 3) return s;
  final List<String>? exact = kUiPhrases[s];
  if (exact != null) return exact[c];
  final String label = uiLabelForEnglish(s, lang);
  if (label != s) return label;
  if (s.length > 400) return s;
  for (final _Pattern p in _patterns) {
    if (!s.startsWith(p.head)) continue;
    final RegExpMatch? m = p.regex.firstMatch(s);
    if (m == null) continue;
    String out = p.values[c];
    for (int i = 1; i <= p.slots; i++) {
      out = out.replaceAll('{$i}', _fillSlot(m.group(i)!, lang, depth));
    }
    return out;
  }
  return s;
}

/// [english] in [lang] (`ar`, `ur` or `bn`) when the table has it; the same
/// English text otherwise. Always safe to call.
String translatePhrase(String english, String lang) =>
    hasPhraseLanguage(lang) ? _translate(english, lang, 0) : english;

/// True when [translatePhrase] would change [english] for [lang].
bool hasPhrase(String english, String lang) =>
    translatePhrase(english, lang) != english;

/// Gregorian month names (1 = January) in [lang]; null for other languages.
List<String>? gregorianMonths(String lang) => _months[lang];

const Map<String, List<String>> _months = <String, List<String>>{
  'ar': <String>['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو',
    'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'],
  'ur': <String>['جنوری', 'فروری', 'مارچ', 'اپریل', 'مئی', 'جون', 'جولائی',
    'اگست', 'ستمبر', 'اکتوبر', 'نومبر', 'دسمبر'],
  'bn': <String>['জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
    'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'],
};
