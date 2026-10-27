/// What can be downloaded to the device, and how big it is.
///
/// Pure data and arithmetic (no storage, no network), so the whole catalogue
/// can be checked in plain tests.
///
/// Two kinds of pack:
///  * recitation audio: the per-ayah files of ONE reciter, for the whole
///    Qur'an, one juz or one surah (the files are the same ones the reader
///    plays, so a downloaded ayah plays with no connection);
///  * text: bundled JSON files that the browser copy of the app keeps in its
///    own storage (the phone apps already carry them inside the install).
library;

import '../../academy/domain/recitation_audio.dart';
import '../../quran/domain/quran_index.dart';
import '../../quran/domain/quran_models.dart';

/// Number of surahs and juz.
const int kSurahCount = 114;
const int kJuzCount = 30;

/// Where each of the 30 juz (parts) begins, as surah and ayah (the standard
/// 30-part division of the Madani mushaf). Juz N runs from here up to the
/// ayah before juz N+1 begins; juz 30 runs to the end of An-Nas.
const List<(int, int)> kJuzStarts = <(int, int)>[
  (1, 1), (2, 142), (2, 253), (3, 93), (4, 24), //
  (4, 148), (5, 82), (6, 111), (7, 88), (8, 41), //
  (9, 93), (11, 6), (12, 53), (15, 1), (17, 1), //
  (18, 75), (21, 1), (23, 1), (25, 21), (27, 56), //
  (29, 46), (33, 31), (36, 28), (39, 32), (41, 47), //
  (46, 1), (51, 31), (58, 1), (67, 1), (78, 1), //
];

/// Ayahs in [surah] (1-114).
int ayahCountOf(int surah) => kSurahIndex[surah - 1].ayahCount;

/// Every ayah of [surah], in order.
List<AyahRef> surahRefs(int surah) => <AyahRef>[
  for (int a = 1; a <= ayahCountOf(surah); a++) AyahRef(surah, a),
];

/// Every ayah of [juz] (1-30), in order, crossing surah borders as needed.
List<AyahRef> juzRefs(int juz) {
  final (int, int) start = kJuzStarts[juz - 1];
  final (int, int) end = juz < kJuzCount
      ? kJuzStarts[juz]
      : (kSurahCount, ayahCountOf(kSurahCount) + 1);
  final List<AyahRef> out = <AyahRef>[];
  int s = start.$1;
  int a = start.$2;
  while (s < end.$1 || (s == end.$1 && a < end.$2)) {
    out.add(AyahRef(s, a));
    a++;
    if (a > ayahCountOf(s)) {
      s++;
      a = 1;
    }
  }
  return out;
}

/// All 6,236 ayahs, in order.
List<AyahRef> allRefs() => <AyahRef>[
  for (int s = 1; s <= kSurahCount; s++) ...surahRefs(s),
];

/// A stable integer for an ayah (surah * 1000 + ayah), for fast set lookups.
int ayahKey(AyahRef r) => r.surah * 1000 + r.ayah;

/// The ayah behind a file name like `002255.mp3`, or null when it is not one.
AyahRef? refFromFileName(String name) {
  final RegExpMatch? m = RegExp(r'^(\d{3})(\d{3})\.mp3$').firstMatch(name);
  if (m == null) return null;
  final int s = int.parse(m.group(1)!);
  final int a = int.parse(m.group(2)!);
  if (s < 1 || s > kSurahCount || a < 1 || a > ayahCountOf(s)) return null;
  return AyahRef(s, a);
}

// ---------------------------------------------------------------------------
// Sizes. These are ESTIMATES and are always shown as "about".
// ---------------------------------------------------------------------------

/// Average recited seconds per ayah across the Qur'an, used only to estimate
/// download size (short ayahs and long ones average out over a surah).
const double kEstimatedSecondsPerAyah = 5.5;

/// Bit rate in kilobits per second, read from the reciter's folder name
/// (`..._192kbps`); 128 when the name does not say.
int bitrateKbps(ReciterPack pack) {
  final RegExpMatch? m = RegExp(
    r'(\d{2,3})kbps',
    caseSensitive: false,
  ).firstMatch(pack.ayahBaseUrl);
  return m == null ? 128 : int.parse(m.group(1)!);
}

/// Estimated bytes for [refs] of [pack]. Muallim (teaching) recitation is
/// slower, so it is counted at 1.6 times the length.
int estimateAudioBytes(ReciterPack pack, int ayahCount) {
  final double slow = pack.id == ReciterPack.husaryMuallim.id ? 1.6 : 1.0;
  final double bytesPerSecond = bitrateKbps(pack) * 125.0;
  return (ayahCount * kEstimatedSecondsPerAyah * slow * bytesPerSecond).round();
}

/// "about 3.2 MB" style sizes. Always one decimal above 1 MB, whole KB below.
String formatBytes(int bytes) {
  if (bytes < 1000 * 1000) {
    final int kb = (bytes / 1000).round();
    return '${kb < 1 ? 1 : kb} KB';
  }
  if (bytes < 1000 * 1000 * 1000) {
    return '${(bytes / (1000 * 1000)).toStringAsFixed(bytes < 10 * 1000 * 1000 ? 1 : 0)} MB';
  }
  return '${(bytes / (1000 * 1000 * 1000)).toStringAsFixed(1)} GB';
}

// ---------------------------------------------------------------------------
// Pack ids
// ---------------------------------------------------------------------------

/// Id of the whole-Qur'an recitation pack for [pack]'s reciter.
String audioAllId(ReciterPack pack) => 'audio:${pack.id}:all';

/// Id of the recitation pack for one juz.
String audioJuzId(ReciterPack pack, int juz) => 'audio:${pack.id}:juz:$juz';

/// Id of the recitation pack for one surah.
String audioSurahId(ReciterPack pack, int surah) =>
    'audio:${pack.id}:surah:$surah';

/// A downloadable recitation range for one reciter.
class AudioPack {
  const AudioPack({
    required this.id,
    required this.title,
    required this.refs,
    required this.estimatedBytes,
  });

  final String id;
  final String title;
  final List<AyahRef> refs;
  final int estimatedBytes;
}

AudioPack audioPackAll(ReciterPack pack) {
  final List<AyahRef> refs = allRefs();
  return AudioPack(
    id: audioAllId(pack),
    title: 'The whole Qur’an',
    refs: refs,
    estimatedBytes: estimateAudioBytes(pack, refs.length),
  );
}

AudioPack audioPackJuz(ReciterPack pack, int juz) {
  final List<AyahRef> refs = juzRefs(juz);
  return AudioPack(
    id: audioJuzId(pack, juz),
    title: 'Juz $juz',
    refs: refs,
    estimatedBytes: estimateAudioBytes(pack, refs.length),
  );
}

AudioPack audioPackSurah(ReciterPack pack, int surah) {
  final List<AyahRef> refs = surahRefs(surah);
  final SurahMeta meta = kSurahIndex[surah - 1];
  return AudioPack(
    id: audioSurahId(pack, surah),
    title: '$surah. ${meta.transliteration}',
    refs: refs,
    estimatedBytes: estimateAudioBytes(pack, refs.length),
  );
}

/// The pack with [id] for [reciter], or null when [id] is not an audio pack
/// of that reciter.
AudioPack? audioPackById(ReciterPack reciter, String id) {
  if (id == audioAllId(reciter)) return audioPackAll(reciter);
  final String prefix = 'audio:${reciter.id}:';
  if (!id.startsWith(prefix)) return null;
  final List<String> parts = id.substring(prefix.length).split(':');
  if (parts.length != 2) return null;
  final int? n = int.tryParse(parts[1]);
  if (n == null) return null;
  if (parts[0] == 'juz' && n >= 1 && n <= kJuzCount) {
    return audioPackJuz(reciter, n);
  }
  if (parts[0] == 'surah' && n >= 1 && n <= kSurahCount) {
    return audioPackSurah(reciter, n);
  }
  return null;
}

// ---------------------------------------------------------------------------
// Text packs
// ---------------------------------------------------------------------------

/// A group of bundled text files. Only files that the app really reads
/// through its on-device text copy are listed, so "saved" always means the
/// screen will open with no connection.
class TextPackSpec {
  const TextPackSpec({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.estimatedBytes,
    required this.entries,
  });

  final String id;
  final String title;
  final String subtitle;
  final int estimatedBytes;

  /// Exact asset paths, or folders ending in `/` (every `.json` inside).
  final List<String> entries;

  /// The concrete asset paths for this pack, given every asset in the app.
  List<String> resolve(Iterable<String> allAssets) {
    final Set<String> out = <String>{};
    for (final String e in entries) {
      if (e.endsWith('/')) {
        for (final String a in allAssets) {
          if (a.startsWith(e) && a.endsWith('.json')) out.add(a);
        }
      } else {
        out.add(e);
      }
    }
    return out.toList()..sort();
  }
}

/// Every text pack, in the order the Downloads screen lists them.
const List<TextPackSpec> kTextPackSpecs = <TextPackSpec>[
  TextPackSpec(
    id: 'text-quran',
    title: 'Qur’an text',
    subtitle: 'Arabic, English and transliteration',
    estimatedBytes: 2300000,
    entries: <String>[
      'assets/quran/quran.json',
      'assets/quran/transliteration.json',
      'assets/quran/texts.json',
    ],
  ),
  TextPackSpec(
    id: 'text-guides',
    title: 'Huda worship guides',
    subtitle: 'Step-by-step guides',
    estimatedBytes: 200000,
    entries: <String>['assets/guides/guides.json'],
  ),
  TextPackSpec(
    id: 'text-seerah',
    title: 'Seerah',
    subtitle: 'The life of the Prophet, in stories',
    estimatedBytes: 70000,
    entries: <String>['assets/stories/seerah.json'],
  ),
  TextPackSpec(
    id: 'text-prophets',
    title: 'Stories of the prophets',
    subtitle: 'Every prophet’s story and its deeper layers',
    estimatedBytes: 300000,
    entries: <String>[
      'assets/stories/prophets.json',
      'assets/stories/earlier/',
      'assets/stories/layers/',
    ],
  ),
  TextPackSpec(
    id: 'text-stories',
    title: 'More stories',
    subtitle:
        'Companions, women of faith, tales, the unseen, signs, '
        'new Muslims and khutbahs',
    estimatedBytes: 320000,
    entries: <String>[
      'assets/stories/companions.json',
      'assets/stories/women.json',
      'assets/stories/tales.json',
      'assets/stories/ghayb.json',
      'assets/stories/signs.json',
      'assets/stories/newmuslim.json',
      'assets/stories/khutbahs.json',
    ],
  ),
  TextPackSpec(
    id: 'text-duas',
    title: 'Duas and adhkar',
    subtitle: 'Daily duas and the adhkar library',
    estimatedBytes: 115000,
    entries: <String>[
      'assets/stories/dailyduas.json',
      'assets/adhkar/adhkar.json',
    ],
  ),
  TextPackSpec(
    id: 'text-hadith',
    title: 'Hadith',
    subtitle: 'The Forty and Hadiths for Our Times',
    estimatedBytes: 130000,
    entries: <String>[
      'assets/hadith/nawawi40.json',
      'assets/stories/modernhadith.json',
    ],
  ),
  TextPackSpec(
    id: 'text-learn',
    title: 'Family tree, feelings, games and Q&A',
    subtitle:
        'The prophets’ family tree, guided paths, trivia, the 99 '
        'Names and the question bank',
    estimatedBytes: 260000,
    entries: <String>[
      'assets/family/tree.json',
      'assets/feelings/feelings.json',
      'assets/games/trivia.json',
      'assets/games/names99.json',
      'assets/qa/qa_bank.json',
    ],
  ),
];

TextPackSpec? textPackById(String id) {
  for (final TextPackSpec s in kTextPackSpecs) {
    if (s.id == id) return s;
  }
  return null;
}

/// What works with no connection and what does not, in plain words. Shown at
/// the top of the Downloads screen so nobody has to find out by trying.
const String kOfflineStatusNote =
    'Already part of the app, no download needed: the Academy lessons and '
    'Arabic letters, Hadi\u2019s built-in library of sourced answers, prayer '
    'times and Qibla (worked out on the device from a location you share or '
    'a city you pick), and the adhan and rain sound.\n\n'
    'Works offline only once saved here: the Qur\u2019an text, the text '
    'packs below and recitation you downloaded. In a browser the saved copy '
    'is kept for this site only.\n\n'
    'Needs a connection: recitation you have not downloaded, nasheeds, '
    'online game tables, the community, the masjid finder, and any answer '
    'from an AI service. In a browser the app itself also needs a '
    'connection to open.';

/// Why nasheeds have no download button. Shown on the Downloads screen and
/// on the player.
const String kNasheedNoDownloadNote =
    'Nasheeds and naats are streamed or opened on the artist’s own '
    'official channel. The app holds no licence to copy those recordings, '
    'so they cannot be downloaded here. Only the adhan and the rain sound '
    'that come inside the app work with no internet.';

// ---------------------------------------------------------------------------
// The audio catalogue for one reciter
// ---------------------------------------------------------------------------

/// Every recitation pack of one reciter: the whole Qur'an, 30 juz, 114 surahs.
class AudioCatalog {
  AudioCatalog._(this.reciter)
    : all = audioPackAll(reciter),
      juz = <AudioPack>[
        for (int j = 1; j <= kJuzCount; j++) audioPackJuz(reciter, j),
      ],
      surahs = <AudioPack>[
        for (int s = 1; s <= kSurahCount; s++) audioPackSurah(reciter, s),
      ];

  final ReciterPack reciter;
  final AudioPack all;
  final List<AudioPack> juz;
  final List<AudioPack> surahs;

  static final Map<String, AudioCatalog> _byReciter = <String, AudioCatalog>{};

  /// Built once per reciter and reused (the packs are constant).
  static AudioCatalog of(ReciterPack reciter) =>
      _byReciter.putIfAbsent(reciter.id, () => AudioCatalog._(reciter));

  /// The pack with [id], or null.
  AudioPack? byId(String id) {
    if (id == all.id) return all;
    for (final AudioPack p in juz) {
      if (p.id == id) return p;
    }
    for (final AudioPack p in surahs) {
      if (p.id == id) return p;
    }
    return null;
  }
}
