/// A daily NOOR — one authentic text (Qur'an or hadith) plus a short
/// reflection prompt. Texts are bundled verbatim from the app's vetted
/// offline datasets (Tanzil/Saheeh Qur'an, the Forty Hadith).
class NoorEntry {
  const NoorEntry({
    required this.kind,
    required this.reference,
    required this.arabic,
    required this.english,
    required this.source,
    required this.prompt,
  });

  factory NoorEntry.fromJson(Map<String, dynamic> json) => NoorEntry(
    kind: json['k'] == 'hadith' ? NoorKind.hadith : NoorKind.quran,
    reference: json['ref'] as String,
    arabic: json['ar'] as String,
    english: json['en'] as String,
    source: json['src'] as String,
    prompt: json['prompt'] as String,
  );

  final NoorKind kind;

  /// '13:28' for Qur'an, '13' for a hadith number.
  final String reference;

  final String arabic;
  final String english;

  /// Display attribution, e.g. "Qur'an 13:28" or "Forty Hadith 13".
  final String source;

  /// One-line reflection prompt (Ar-Rayaan editorial, not scripture).
  final String prompt;
}

enum NoorKind { quran, hadith }
