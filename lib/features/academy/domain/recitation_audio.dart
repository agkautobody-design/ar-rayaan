/// Recitation audio — domain models for the Al-Husary pack (mp3quran).
///
/// Licensing: mp3quran.net library, free for app integration; founder
/// courtesy-confirmation email drafted in the Wave 3 notes.
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

/// The licensed reciter pack. ONE reciter at launch (parity rule);
/// the picker is a stub until Phase 4.
class ReciterPack {
  const ReciterPack({
    required this.id,
    required this.displayName,
    required this.ayahBaseUrl,
    required this.surahBaseUrl,
  });

  /// Al-Husary murattal via mp3quran.
  static const ReciterPack alHusary = ReciterPack(
    id: 'husary-mp3quran',
    displayName: 'Sheikh Mahmoud Khalil Al-Husary',
    // Per-ayah files (muyawil server). Defensive fallback to surah files
    // is handled by the repository when a per-ayah request 404s.
    ayahBaseUrl: 'https://server13.mp3quran.net/husr',
    surahBaseUrl: 'https://server13.mp3quran.net/husr',
  );

  final String id;
  final String displayName;
  final String ayahBaseUrl;
  final String surahBaseUrl;

  /// Full URL for one ayah's audio file.
  String ayahUrl(AyahRef ref) => '$ayahBaseUrl/${ref.fileName}';

  /// Full URL for a full-surah file (fallback + hifz whole-surah loop).
  String surahUrl(int surah) =>
      '$surahBaseUrl/${surah.toString().padLeft(3, '0')}.mp3';
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
