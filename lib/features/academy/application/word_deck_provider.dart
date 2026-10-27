/// Word Deck state — the learner's deck, persisted, plus today queue.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
import '../data/word_deck_repository.dart';
import '../domain/fsrs.dart';
import '../domain/path_ux.dart';
import '../domain/recitation_audio.dart';
import '../domain/spaced_repetition.dart';
import '../domain/word_deck.dart';
import '../domain/word_gloss.dart';

/// The learner's deck. Loaded from device storage; every mutation
/// persists immediately (Amanah: on-device only, never synced).
final wordDeckProvider =
    StateNotifierProvider<WordDeckNotifier, Map<String, WordCard>>(
        (Ref ref) {
  return WordDeckNotifier(ref.watch(sharedPreferencesProvider));
});

/// Today's review session — due first, then fresh, capped.
final todaySessionProvider = Provider<List<WordCard>>((Ref ref) {
  final Map<String, WordCard> deck = ref.watch(wordDeckProvider);
  return WordDeckEngine.buildSession(deck: deck, now: DateTime.now());
});

/// Count for the Academy home today-strip: cards that are really DUE (seen
/// before, review date reached). The 300 fresh cards the pack seeds are
/// introductions, not due reviews, so they are never counted here.
final wordsDueProvider = Provider<int>((Ref ref) {
  final Map<String, WordCard> deck = ref.watch(wordDeckProvider);
  return WordDeckEngine.dueCards(deck: deck, now: DateTime.now()).length;
});

class WordDeckNotifier extends StateNotifier<Map<String, WordCard>> {
  WordDeckNotifier(SharedPreferences prefs)
      : _prefs = prefs,
        super(WordDeckRepository.loadDeck(prefs));

  final SharedPreferences _prefs;
  bool _seeded = false;

  /// Load the verified top-300 pack and seed cards not already in the
  /// learner's deck. Idempotent per app launch; learner progress always
  /// wins over the pack. Called from the Academy home after first frame.
  Future<void> seedFromPack() async {
    if (_seeded) return;
    _seeded = true;
    final List<WordCard>? pack = await WordDeckRepository.loadPack(
      isValidRef: _ayahExists,
    );
    if (pack != null && pack.isNotEmpty) {
      await seedPack(pack);
      await applyGlosses(await WordDeckRepository.loadGlosses());
    }
  }

  /// A deck saved by an older version holds the pack cards with no meaning.
  /// Give each such card its meaning (and root) from [glosses]; review
  /// progress is never touched, and a card that already has a sourced
  /// meaning is left alone.
  Future<void> applyGlosses(Map<String, WordGloss> glosses) async {
    if (glosses.isEmpty) return;
    bool changed = false;
    final Map<String, WordCard> next = <String, WordCard>{};
    for (final MapEntry<String, WordCard> e in state.entries) {
      final WordCard updated = withGloss(e.value, glosses);
      if (!identical(updated, e.value)) changed = true;
      next[e.key] = updated;
    }
    if (!changed) return;
    state = next;
    await _save();
  }

  static bool _ayahExists(AyahRef ref) {
    // Bounds check against the mushaf structure (114 surahs); the full
    // text verification happens at pack-build time in the asset
    // pipeline — this is the runtime existence gate.
    return ref.surah >= 1 && ref.surah <= 114 && ref.ayah >= 1;
  }

  Future<void> _save() async {
    await WordDeckRepository.saveDeck(_prefs, state);
  }

  /// The moat entry point: add a card from the reader's tap-a-word.
  /// Never duplicates; persists immediately.
  Future<void> addFromReader({
    required String arabic,
    required String gloss,
    required AyahRef sourceAyah,
    String? root,
    String? glossSource,
  }) async {
    final String key =
        '${sourceAyah.surah}:${sourceAyah.ayah}:$arabic';
    if (state.containsKey(key)) return;
    final WordCard card = WordCard(
      key: key,
      arabic: arabic,
      gloss: gloss,
      root: root,
      glossSource: glossSource,
      sourceAyah: sourceAyah,
      review: ReviewCard(wordKey: key, dueDate: DateTime.now()),
    );
    state = WordDeckEngine.addCard(state, card);
    await _save();
  }

  /// Apply a self-grade; FSRS reschedules, the answer is logged on-device
  /// and the deck persists.
  Future<void> grade(String key, ReviewGrade grade) async {
    final DateTime now = DateTime.now();
    state = WordDeckEngine.grade(
      deck: state,
      key: key,
      grade: grade,
      now: now,
    );
    final WordCard? updated = state[key];
    if (updated != null) {
      ActivityLog.record(_prefs, now);
      try {
        _prefs.setString(
          ReviewLog.prefKey,
          ReviewLog.append(
            _prefs.getString(ReviewLog.prefKey),
            ReviewLogEntry(
              cardId: key,
              grade: grade,
              at: now,
              scheduledDays: updated.review.intervalDays,
            ),
          ),
        );
      } catch (_) {}
    }
    await _save();
  }

  /// Seed the verified pack on first launch (skips existing keys —
  /// learner progress always wins over the pack).
  Future<void> seedPack(List<WordCard> pack) async {
    var next = state;
    for (final WordCard card in pack) {
      next = WordDeckEngine.addCard(next, card);
    }
    if (!identical(next, state)) {
      state = next;
      await _save();
    }
  }
}
