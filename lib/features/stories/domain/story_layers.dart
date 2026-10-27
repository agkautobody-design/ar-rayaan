/// Layered knowledge for a story (prophets and the unseen).
///
/// A story's own text stays as it is. Alongside it, a "layers" file can
/// carry what lies beneath, each kind kept apart and labelled so a reader
/// always knows what they are reading:
///
///  * Qur'an   - references only; the text is read from the app's bundled
///               Qur'an, never copied into these files.
///  * Hadith   - the six books only, each with its grade and WHO graded it.
///               The files hold our own one-line summary and the reference,
///               never the hadith text (sunnah.com forbids mirroring).
///  * Scholarly explanation - a named classical work, labelled as not
///               revelation.
///  * Disputed in the sources - where named works differ.
///
/// "Earlier accounts" (material from before the Qur'an: the Bible, Jewish
/// and Christian tradition) live in their own files and are always shown
/// under the fixed badge [kEarlierBadge] and the three-class rule.
library;

import '../../../app/core/scholar_review.dart';

/// Fixed badge on every earlier account. Never reworded per item.
const String kEarlierBadge = 'Not from the Qur’an';

/// Fixed review banner. There is no named reviewer yet, so the app only
/// ever states that review is still needed.
const String kReviewBanner = kScholarReviewNeeded;

/// Label printed on a disagreement between named works.
const String kDisputedLabel = 'Disputed in the sources';

/// The six books (Kutub al-Sittah) and how each is printed.
const Map<String, String> kHadithBooks = <String, String>{
  'bukhari': 'Sahih al-Bukhari',
  'muslim': 'Sahih Muslim',
  'abudawud': 'Sunan Abi Dawud',
  'tirmidhi': 'Jami’ at-Tirmidhi',
  'nasai': 'Sunan an-Nasa’i',
  'ibnmajah': 'Sunan Ibn Majah',
};

/// The three classes of earlier (isra'iliyyat) material.
enum EarlierClass {
  /// Confirmed by the Qur'an or sound hadith.
  confirmed,

  /// Neither confirmed nor contradicted: neither believe nor disbelieve.
  silent,

  /// Contradicts the Qur'an or sound hadith: named, explained, not told.
  contradicted;

  static EarlierClass parse(String raw) {
    switch (raw) {
      case 'confirmed':
        return EarlierClass.confirmed;
      case 'contradicted':
        return EarlierClass.contradicted;
      default:
        return EarlierClass.silent;
    }
  }

  String get label {
    switch (this) {
      case EarlierClass.confirmed:
        return 'Confirmed by our sources';
      case EarlierClass.silent:
        return 'Our sources are silent — neither believe nor disbelieve';
      case EarlierClass.contradicted:
        return 'Contradicts our sources — not told here';
    }
  }
}

class LayerQuranRef {
  const LayerQuranRef({
    required this.surah,
    required this.from,
    required this.to,
    this.note,
  });

  final int surah;
  final int from;
  final int to;
  final String? note;

  factory LayerQuranRef.fromJson(Map<String, dynamic> j) {
    final int from = j['from'] as int;
    return LayerQuranRef(
      surah: j['surah'] as int,
      from: from,
      to: (j['to'] as int?) ?? from,
      note: j['note'] as String?,
    );
  }

  String get label => from == to
      ? 'Qur’an $surah:$from'
      : 'Qur’an $surah:$from-$to';
}

class LayerHadith {
  const LayerHadith({
    required this.book,
    required this.number,
    required this.narrator,
    required this.grade,
    required this.grader,
    required this.summary,
    required this.verified,
    this.note,
  });

  /// One of the keys of [kHadithBooks].
  final String book;
  final String number;
  final String narrator;
  final String grade;

  /// WHO gave the grade ("Sahih al-Bukhari", "al-Albani", "Darussalam"...).
  final String grader;

  /// Our own words. Never the text of the hadith.
  final String summary;

  /// The day this reference was checked on sunnah.com.
  final String verified;
  final String? note;

  factory LayerHadith.fromJson(Map<String, dynamic> j) => LayerHadith(
        book: j['book'] as String,
        number: j['number'] as String,
        narrator: j['narrator'] as String,
        grade: j['grade'] as String,
        grader: j['grader'] as String,
        summary: j['summary'] as String,
        verified: j['verified'] as String,
        note: j['note'] as String?,
      );

  /// "Sahih al-Bukhari 3424" - the form the citation checker reads.
  String get reference => '${kHadithBooks[book] ?? book} $number';

  /// Where the full text can be read.
  String get sunnahUrl => 'https://sunnah.com/$book:$number';

  /// Bukhari and Muslim are the top tier; the other four are always shown
  /// with grade and grader.
  bool get isTopTier => book == 'bukhari' || book == 'muslim';
}

class LayerScholarly {
  const LayerScholarly({
    required this.work,
    required this.author,
    required this.locator,
    required this.summary,
  });

  /// The named work, with the edition actually read.
  final String work;
  final String author;

  /// Where in the work ("on 38:34").
  final String locator;

  /// Our paraphrase of what the work says.
  final String summary;

  factory LayerScholarly.fromJson(Map<String, dynamic> j) => LayerScholarly(
        work: j['work'] as String,
        author: j['author'] as String,
        locator: j['locator'] as String,
        summary: j['summary'] as String,
      );
}

class LayerView {
  const LayerView({required this.who, required this.work, required this.view});

  final String who;
  final String work;
  final String view;

  factory LayerView.fromJson(Map<String, dynamic> j) => LayerView(
        who: j['who'] as String,
        work: j['work'] as String,
        view: j['view'] as String,
      );
}

class LayerDifference {
  const LayerDifference({
    required this.question,
    required this.views,
    this.note,
  });

  final String question;
  final List<LayerView> views;
  final String? note;

  factory LayerDifference.fromJson(Map<String, dynamic> j) => LayerDifference(
        question: j['question'] as String,
        views: (j['views'] as List<dynamic>)
            .map((dynamic e) => LayerView.fromJson(e as Map<String, dynamic>))
            .toList(),
        note: j['note'] as String?,
      );
}

class EarlierAccount {
  const EarlierAccount({
    required this.id,
    required this.cls,
    required this.origin,
    required this.claim,
    required this.ruling,
    required this.basis,
  });

  final String id;
  final EarlierClass cls;

  /// Where the earlier account comes from ("Bible, 1 Samuel 17").
  final String origin;

  /// What that account says, in neutral words (kept short; for the
  /// contradicted class this is a pointer, not a retelling).
  final String claim;

  /// Why it is in this class.
  final String ruling;

  /// The named source of the ruling (a work actually read, or a Qur'an
  /// reference from the bundled text).
  final String basis;

  factory EarlierAccount.fromJson(Map<String, dynamic> j) => EarlierAccount(
        id: j['id'] as String,
        cls: EarlierClass.parse(j['class'] as String),
        origin: j['origin'] as String,
        claim: j['claim'] as String,
        ruling: j['ruling'] as String,
        basis: j['basis'] as String,
      );
}

/// Everything beneath one subject (a prophet, the jinn, the angels...).
class StoryLayers {
  const StoryLayers({
    required this.subject,
    required this.title,
    required this.kind,
    required this.quran,
    required this.hadith,
    required this.scholarly,
    required this.differences,
    required this.earlier,
  });

  final String subject;
  final String title;

  /// 'prophet' or 'unseen'.
  final String kind;
  final List<LayerQuranRef> quran;
  final List<LayerHadith> hadith;
  final List<LayerScholarly> scholarly;
  final List<LayerDifference> differences;
  final List<EarlierAccount> earlier;

  factory StoryLayers.fromJson(
    Map<String, dynamic> layers,
    Map<String, dynamic>? earlier,
  ) {
    List<T> list<T>(
      Map<String, dynamic> src,
      String key,
      T Function(Map<String, dynamic>) make,
    ) {
      final List<dynamic> raw = (src[key] as List<dynamic>?) ?? <dynamic>[];
      return raw.map((dynamic e) => make(e as Map<String, dynamic>)).toList();
    }

    return StoryLayers(
      subject: layers['subject'] as String,
      title: layers['title'] as String,
      kind: layers['kind'] as String,
      quran: list<LayerQuranRef>(layers, 'quran', LayerQuranRef.fromJson),
      hadith: list<LayerHadith>(layers, 'hadith', LayerHadith.fromJson),
      scholarly:
          list<LayerScholarly>(layers, 'scholarly', LayerScholarly.fromJson),
      differences: list<LayerDifference>(
          layers, 'differences', LayerDifference.fromJson),
      earlier: earlier == null
          ? const <EarlierAccount>[]
          : list<EarlierAccount>(earlier, 'items', EarlierAccount.fromJson),
    );
  }

  bool get isEmpty =>
      quran.isEmpty &&
      hadith.isEmpty &&
      scholarly.isEmpty &&
      differences.isEmpty &&
      earlier.isEmpty;
}
