/// TranslationPack: one complete Qur'an translation as a single versioned,
/// checksummed JSON file, with its own licence metadata.
///
/// The app never carries a translation's words in code. A pack is a data file
/// that is read from `assets/quran/translations/` (bundled) or from the
/// device's download storage, so a licensed text drops in with no code change
/// and an unlicensed one cannot be bundled by accident.
///
/// File shape (schema 1):
/// ```
/// {
///   "schema": 1,
///   "id": "en.clear-quran",          // <language>.<slug>
///   "language": "en",                // BCP-47 primary tag
///   "rtl": false,
///   "version": "1.0.0",
///   "title": "...",                  // shown in Settings
///   "translator": "...",
///   "publisher": "...",
///   "licenseId": "...",              // the publisher's permission reference
///   "attribution": "...",            // the exact credit line to display
///   "url": "https://...",            // where the credit links to
///   "sha256": "<hex>",               // see [translationTextsSha256]
///   "surahs": [["ayah 1 of surah 1", ...], ["ayah 1 of surah 2", ...], ...]
/// }
/// ```
/// Pure Dart: no Flutter, no storage. The Python tool
/// `tool/translation_pack.py` implements the same checks and checksum.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'quran_index.dart';
import 'quran_models.dart';

/// Pack file format version this code reads.
const int kTranslationPackSchema = 1;

/// Total ayahs in the Qur'an; every pack must carry exactly this many.
const int kQuranAyahTotal = 6236;

/// The English translation the owner chose as the default. Its pack file is
/// `assets/quran/translations/en.clear-quran.json` once it is supplied.
const String kClearQuranId = 'en.clear-quran';

/// What is shown until a pack for the chosen translation is present: the
/// translation inside `assets/quran/quran.json` (Saheeh International).
const String kInterimEnglishId = 'en.saheeh-interim';

/// Default translation id per language. Only English has a default today;
/// other languages show only what a person has chosen and installed.
const Map<String, String> kDefaultTranslationByLanguage = <String, String>{
  'en': kClearQuranId,
};

/// Folder (inside the app's assets) that holds bundled packs and the manifest.
const String kTranslationPackDir = 'assets/quran/translations/';

/// Why a pack was rejected.
class TranslationPackException implements Exception {
  const TranslationPackException(this.message);
  final String message;
  @override
  String toString() => 'TranslationPackException: $message';
}

/// Number of ayahs in each surah, 1..114, from the bundled index.
List<int> get kAyahCounts => <int>[
  for (final SurahMeta s in kSurahIndex) s.ayahCount,
];

/// SHA-256 (hex) of the canonical text: for every ayah in order,
/// `"<surah>:<ayah>\t<text>\n"`, UTF-8. [surahs] holds the ayah texts.
String translationTextsSha256(List<List<String>> surahs) {
  final StringBuffer b = StringBuffer();
  for (int s = 0; s < surahs.length; s++) {
    for (int a = 0; a < surahs[s].length; a++) {
      b.write('${s + 1}:${a + 1}\t${surahs[s][a]}\n');
    }
  }
  return sha256.convert(utf8.encode(b.toString())).toString();
}

/// "1.2.10" > "1.2.9". Non-numeric parts count as 0.
int compareVersions(String a, String b) {
  final List<int> x = _parts(a);
  final List<int> y = _parts(b);
  final int n = x.length > y.length ? x.length : y.length;
  for (int i = 0; i < n; i++) {
    final int p = i < x.length ? x[i] : 0;
    final int q = i < y.length ? y[i] : 0;
    if (p != q) return p < q ? -1 : 1;
  }
  return 0;
}

List<int> _parts(String v) => <int>[
  for (final String p in v.split('.')) int.tryParse(p) ?? 0,
];

/// A licence is only usable when it names the permission it rests on.
bool isRealLicenceId(String id) {
  final String t = id.trim().toLowerCase();
  if (t.isEmpty) return false;
  const Set<String> placeholders = <String>{
    'pending',
    'unknown',
    'none',
    'tbd',
    'todo',
    'n/a',
    'na',
    'unlicensed',
    'placeholder',
  };
  return !placeholders.contains(t);
}

class TranslationPack {
  const TranslationPack({
    required this.id,
    required this.language,
    required this.rtl,
    required this.version,
    required this.title,
    required this.translator,
    required this.publisher,
    required this.licenseId,
    required this.attribution,
    required this.url,
    required this.sha256,
    required this.surahs,
  });

  final String id;
  final String language;
  final bool rtl;
  final String version;
  final String title;
  final String translator;
  final String publisher;
  final String licenseId;
  final String attribution;
  final String url;
  final String sha256;

  /// Ayah texts: `surahs[s - 1][a - 1]` is ayah `a` of surah `s`.
  final List<List<String>> surahs;

  String textOf(int surah, int ayah) => surahs[surah - 1][ayah - 1];

  /// Parses and fully validates [raw]. Throws [TranslationPackException] with
  /// the first problem found; never returns a pack that failed a check.
  static TranslationPack parse(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (e) {
      throw TranslationPackException('not valid JSON (${e.message})');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const TranslationPackException('top level must be an object');
    }
    final Map<String, dynamic> j = decoded;

    String str(String key, {bool allowEmpty = false}) {
      final Object? v = j[key];
      if (v is! String) {
        throw TranslationPackException('"$key" must be a string');
      }
      if (!allowEmpty && v.trim().isEmpty) {
        throw TranslationPackException('"$key" must not be empty');
      }
      return v;
    }

    if (j['schema'] != kTranslationPackSchema) {
      throw TranslationPackException(
        'unsupported schema ${j['schema']} (this app reads '
        '$kTranslationPackSchema)',
      );
    }
    final String id = str('id');
    if (!RegExp(r'^[a-z]{2,3}\.[a-z0-9][a-z0-9\-]*$').hasMatch(id)) {
      throw TranslationPackException(
        'id "$id" must look like <language>.<slug>, e.g. en.clear-quran',
      );
    }
    final String language = str('language');
    if (!id.startsWith('$language.')) {
      throw TranslationPackException(
        'id "$id" must start with the language "$language."',
      );
    }
    final String version = str('version');
    if (!RegExp(r'^\d+(\.\d+)*$').hasMatch(version)) {
      throw TranslationPackException('version "$version" must be 1.2.3 style');
    }
    final Object? rtl = j['rtl'];
    if (rtl != null && rtl is! bool) {
      throw const TranslationPackException('"rtl" must be true or false');
    }
    final String licenseId = str('licenseId');
    if (!isRealLicenceId(licenseId)) {
      throw TranslationPackException(
        'licenseId "$licenseId" is a placeholder: a pack must name the '
        'permission it rests on',
      );
    }
    final String url = str('url');
    if (!url.startsWith('https://')) {
      throw const TranslationPackException('"url" must start with https://');
    }

    final Object? rawSurahs = j['surahs'];
    if (rawSurahs is! List<dynamic> || rawSurahs.length != 114) {
      throw const TranslationPackException('"surahs" must list 114 surahs');
    }
    final List<int> counts = kAyahCounts;
    final List<List<String>> surahs = <List<String>>[];
    int total = 0;
    for (int s = 0; s < 114; s++) {
      final Object? row = rawSurahs[s];
      if (row is! List<dynamic>) {
        throw TranslationPackException('surah ${s + 1} must be a list');
      }
      if (row.length != counts[s]) {
        throw TranslationPackException(
          'surah ${s + 1} has ${row.length} ayahs, expected ${counts[s]}',
        );
      }
      final List<String> texts = <String>[];
      for (int a = 0; a < row.length; a++) {
        final Object? t = row[a];
        if (t is! String || t.trim().isEmpty) {
          throw TranslationPackException('${s + 1}:${a + 1} is empty');
        }
        if (t != t.trim()) {
          throw TranslationPackException(
            '${s + 1}:${a + 1} has leading or trailing spaces',
          );
        }
        if (t.contains('\n') || t.contains('\r') || t.contains('\t')) {
          throw TranslationPackException(
            '${s + 1}:${a + 1} contains a line break or tab',
          );
        }
        texts.add(t);
      }
      total += texts.length;
      surahs.add(texts);
    }
    if (total != kQuranAyahTotal) {
      throw TranslationPackException('$total ayahs, expected $kQuranAyahTotal');
    }

    final String declared = str('sha256').toLowerCase();
    final String actual = translationTextsSha256(surahs);
    if (declared != actual) {
      throw const TranslationPackException(
        'checksum mismatch: the text does not match its "sha256"',
      );
    }

    return TranslationPack(
      id: id,
      language: language,
      rtl: rtl == true,
      version: version,
      title: str('title'),
      translator: str('translator'),
      publisher: str('publisher'),
      licenseId: licenseId,
      attribution: str('attribution'),
      url: url,
      sha256: declared,
      surahs: surahs,
    );
  }
}

/// One line of `assets/quran/translations/manifest.json`.
class TranslationPackEntry {
  const TranslationPackEntry({
    required this.id,
    required this.language,
    required this.title,
    required this.file,
    required this.version,
    required this.sha256,
    required this.licenseId,
    required this.licenceStatus,
  });

  factory TranslationPackEntry.fromJson(Map<String, dynamic> j) =>
      TranslationPackEntry(
        id: j['id'] as String,
        language: j['language'] as String,
        title: j['title'] as String,
        file: j['file'] as String,
        version: j['version'] as String,
        sha256: (j['sha256'] as String).toLowerCase(),
        licenseId: j['licenseId'] as String,
        licenceStatus: j['licenceStatus'] as String,
      );

  final String id;
  final String language;
  final String title;

  /// File name inside [kTranslationPackDir].
  final String file;
  final String version;

  /// Must equal the pack's own "sha256".
  final String sha256;
  final String licenseId;

  /// "granted" is the only value that may ship in the app.
  final String licenceStatus;

  bool get isGranted => licenceStatus == 'granted' && isRealLicenceId(licenseId);
}

/// The list of bundled packs. Empty until a licensed text is imported.
class TranslationManifest {
  const TranslationManifest(this.packs);

  factory TranslationManifest.parse(String raw) {
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic> ||
        decoded['schema'] != kTranslationPackSchema ||
        decoded['packs'] is! List<dynamic>) {
      throw const TranslationPackException('manifest has the wrong shape');
    }
    return TranslationManifest(<TranslationPackEntry>[
      for (final Map<String, dynamic> e
          in (decoded['packs'] as List<dynamic>).cast<Map<String, dynamic>>())
        TranslationPackEntry.fromJson(e),
    ]);
  }

  static const TranslationManifest empty = TranslationManifest(
    <TranslationPackEntry>[],
  );

  final List<TranslationPackEntry> packs;

  TranslationPackEntry? byId(String id) {
    for (final TranslationPackEntry e in packs) {
      if (e.id == id) return e;
    }
    return null;
  }
}

/// What the reader shows: the pack in use, or none (interim) with the id that
/// was wanted so the screens can say honestly why.
class ActiveTranslation {
  const ActiveTranslation({required this.wantedId, required this.pack});

  /// The translation chosen (or the default for English).
  final String wantedId;

  /// Its pack, when present and valid; null means the interim translation.
  final TranslationPack? pack;

  bool get isInterim => pack == null;
  bool get rtl => pack?.rtl ?? false;
}
