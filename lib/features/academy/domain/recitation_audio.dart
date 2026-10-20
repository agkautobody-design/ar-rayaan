/// Recitation audio — domain models for the reciter packs.
///
/// Every reciter streams per-ayah files from everyayah.com (checked in a
/// browser on 20 Oct 2026: these hosts answer cross-origin requests from
/// the web app, see docs in the PR). Terms of use of everyayah.com are NOT
/// stated on its site and have not been confirmed with the host: the
/// courtesy request is a pending owner action. mp3quran.net is used only
/// for whole-surah files of Al-Husary; no licence statement was found
/// there either, so nothing here claims one.
library;

/// A location in the mushaf: surah (1-114) + ayah (1-based).
class AyahRef {
  const AyahRef(this.surah, this.ayah);

  final int surah;
  final int ayah;

  /// mp3quran per-ayah filename: zero-padded 3+3, e.g. 002255.mp3
  String get fileName =>
      '${surah.toString().padLeft(3, '0')}${ayah.toString().padLeft(3, '0')}.mp3';

  @override
  bool operator ==(Object other) =>
      other is AyahRef && other.surah == surah && other.ayah == ayah;

  @override
  int get hashCode => Object.hash(surah, ayah);

  @override
  String toString() => '$surah:$ayah';
}

/// A recitation source: one reciter and style, streamed per ayah.
///
/// Source of truth for the folder names is everyayah.com/data/recitations.js
/// (read 20 Oct 2026). Reciter names are shown on screen whenever audio
/// plays. No female reciter is available from this host.
class ReciterPack {
  const ReciterPack({
    required this.id,
    required this.displayName,
    required this.ayahBaseUrl,
    this.surahBaseUrl = '',
    this.style = 'Murattal',
  });

  /// Al-Husary murattal (the default; the original single reciter).
  static const ReciterPack alHusary = ReciterPack(
    id: 'husary-mp3quran',
    displayName: 'Sheikh Mahmoud Khalil Al-Husary',
    // Per-ayah files: everyayah.com (mp3quran hosts whole surahs only;
    // its per-ayah paths 404).
    ayahBaseUrl: 'https://everyayah.com/data/Husary_128kbps',
    surahBaseUrl: 'https://server13.mp3quran.net/husr',
  );

  static const ReciterPack husaryMuallim = ReciterPack(
    id: 'husary-muallim',
    displayName: 'Sheikh Mahmoud Khalil Al-Husary (Muallim, teaching)',
    ayahBaseUrl: 'https://everyayah.com/data/Husary_Muallim_128kbps',
    style: 'Muallim (slow, for learners)',
  );

  static const ReciterPack alafasy = ReciterPack(
    id: 'alafasy',
    displayName: 'Sheikh Mishary Rashid Alafasy',
    ayahBaseUrl: 'https://everyayah.com/data/Alafasy_128kbps',
  );

  static const ReciterPack minshawy = ReciterPack(
    id: 'minshawy-murattal',
    displayName: 'Sheikh Muhammad Siddiq Al-Minshawi',
    ayahBaseUrl: 'https://everyayah.com/data/Minshawy_Murattal_128kbps',
  );

  static const ReciterPack abdulBasit = ReciterPack(
    id: 'abdul-basit-murattal',
    displayName: 'Sheikh Abdul Basit Abdus-Samad',
    ayahBaseUrl: 'https://everyayah.com/data/Abdul_Basit_Murattal_192kbps',
  );

  static const ReciterPack sudais = ReciterPack(
    id: 'sudais',
    displayName: 'Sheikh Abdur-Rahman As-Sudais',
    ayahBaseUrl: 'https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps',
  );

  static const ReciterPack shuraym = ReciterPack(
    id: 'shuraym',
    displayName: 'Sheikh Saud Ash-Shuraym',
    ayahBaseUrl: 'https://everyayah.com/data/Saood_ash-Shuraym_128kbps',
  );

  static const ReciterPack hudhaify = ReciterPack(
    id: 'hudhaify',
    displayName: 'Sheikh Ali Al-Hudhaify',
    ayahBaseUrl: 'https://everyayah.com/data/Hudhaify_128kbps',
  );

  static const ReciterPack muaiqly = ReciterPack(
    id: 'muaiqly',
    displayName: 'Sheikh Maher Al-Muaiqly',
    ayahBaseUrl: 'https://everyayah.com/data/MaherAlMuaiqly128kbps',
  );

  /// Every selectable reciter, default first.
  static const List<ReciterPack> all = <ReciterPack>[
    alHusary,
    husaryMuallim,
    alafasy,
    minshawy,
    abdulBasit,
    sudais,
    shuraym,
    hudhaify,
    muaiqly,
  ];

  /// The pack saved under [id], or the default when unknown.
  static ReciterPack byId(String? id) {
    for (final ReciterPack p in all) {
      if (p.id == id) return p;
    }
    return alHusary;
  }

  final String id;
  final String displayName;
  final String ayahBaseUrl;

  /// Whole-surah files, only where a host provides them ('' otherwise).
  final String surahBaseUrl;
  final String style;

  /// Full URL for one ayah's audio file.
  String ayahUrl(AyahRef ref) => '$ayahBaseUrl/${ref.fileName}';

  /// Full URL for a full-surah file (hifz whole-surah loop). Empty when this
  /// reciter has no whole-surah host.
  String surahUrl(int surah) => surahBaseUrl.isEmpty
      ? ''
      : '$surahBaseUrl/${surah.toString().padLeft(3, '0')}.mp3';
}

/// One unit of sound in a playback plan: an ayah to fetch + how many
/// times to say it, and the pause after it.
class PlaybackEvent {
  const PlaybackEvent({
    required this.ref,
    required this.repeats,
    required this.gapAfterMs,
    this.useSurahFallback = false,
  });

  final AyahRef ref;
  final int repeats;
  final int gapAfterMs;

  /// True when the per-ayah file was unavailable and the whole-surah
  /// file should be used instead (range loop still applies; per-ayah
  /// repeat degrades to whole-range — honesty over fake precision).
  final bool useSurahFallback;
}

abstract final class RecitationPlanEngine {
  /// Build the play sequence for a verse range.
  ///
  /// [perAyahRepeat] N — each ayah plays N times before advancing (1-5).
  /// [gapMs] silence between utterances (500-5000, founder default 2000).
  /// [loopRange] how many times the whole range repeats (1-10).
  /// Ranges may span surahs; the plan is flat, in recitation order.
  static List<PlaybackEvent> buildPlan({
    required List<AyahRef> range,
    required int perAyahRepeat,
    required int gapMs,
    required int loopRange,
  }) {
    assert(range.isNotEmpty);
    assert(perAyahRepeat >= 1 && perAyahRepeat <= 5);
    assert(loopRange >= 1 && loopRange <= 10);
    final List<PlaybackEvent> events = <PlaybackEvent>[];
    for (int loop = 0; loop < loopRange; loop++) {
      for (int i = 0; i < range.length; i++) {
        final bool lastOfRange = i == range.length - 1;
        // Gap between every utterance EXCEPT a clean hand-off at the
        // exact end of the final loop — no trailing silence.
        final bool finalEvent =
            loop == loopRange - 1 && lastOfRange;
        events.add(
          PlaybackEvent(
            ref: range[i],
            repeats: perAyahRepeat,
            gapAfterMs: finalEvent ? 0 : gapMs,
          ),
        );
      }
    }
    return events;
  }

  /// Total ayah-utterances in a plan (for UI progress display).
  static int totalUtterances(List<PlaybackEvent> plan) {
    int n = 0;
    for (final PlaybackEvent e in plan) {
      n += e.repeats;
    }
    return n;
  }
}

/// Expand a surah:ayah range into ordered refs (ayat within one surah,
/// inclusive both ends). Cross-surah ranges are built by the caller
/// concatenating per-surah expansions — the Quran data layer owns
/// per-surah ayah counts, never this engine.
class AyahRange {
  const AyahRange._(this.refs);

  final List<AyahRef> refs;

  factory AyahRange.withinSurah({
    required int surah,
    required int fromAyah,
    required int toAyah,
  }) {
    assert(fromAyah >= 1 && toAyah >= fromAyah);
    return AyahRange._(<AyahRef>[
      for (int a = fromAyah; a <= toAyah; a++) AyahRef(surah, a),
    ]);
  }

  factory AyahRange.concat(List<AyahRange> parts) => AyahRange._(
        <AyahRef>[for (final AyahRange p in parts) ...p.refs],
      );
}


/// Backend seam: one utterance of one ayah, then completion.
/// Lives in the domain layer so data (backends) and application (the
/// player notifier) both depend on it — never on each other.
abstract class AyahAudioPlayer {
  /// Play the source at [pathOrUrl]; the returned future completes when
  /// the utterance ends (or is stopped).
  Future<void> play(String pathOrUrl);

  /// Stop the current utterance; any pending [play] future must complete.
  Future<void> stop();
}
