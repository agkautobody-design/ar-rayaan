/// Word Deck state — the learner's deck, persisted, plus today queue.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
import '../data/word_deck_repository.dart';
import '../domain/recitation_audio.dart';
import '../domain/spaced_repetition.dart';
import '../domain/word_deck.dart';

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

/// Count for the Academy home today-strip.
final wordsDueProvider = Provider<int>((Ref ref) {
  return ref.watch(todaySessionProvider).length;
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
    }
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
  }) async {
    final String key =
        '${sourceAyah.surah}:${sourceAyah.ayah}:$arabic';
    if (state.containsKey(key)) return;
    final WordCard card = WordCard(
      key: key,
      arabic: arabic,
      gloss: gloss,
      root: root,
      sourceAyah: sourceAyah,
      review: ReviewCard(wordKey: key, dueDate: DateTime.now()),
    );
    state = WordDeckEngine.addCard(state, card);
    await _save();
  }

  /// Apply a self-grade; SM-2 reschedules and persists.
  Future<void> grade(String key, ReviewGrade grade) async {
    state = WordDeckEngine.grade(
      deck: state,
      key: key,
      grade: grade,
      now: DateTime.now(),
    );
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
