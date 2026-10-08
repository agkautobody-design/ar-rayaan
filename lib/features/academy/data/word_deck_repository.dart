/// Word Deck repository — persistence + corpus pack contract.
///
/// Two data sources, one owner each (§4E):
/// 1. THE LEARNER'S DECK — their cards + scheduling state. Persisted
///    on-device only (`ar.academy.deck.v1`), never synced (Amanah).
/// 2. THE TOP-300 PACK — the verified frequency list ships as
///    `assets/academy/word_pack.json`, SHA-256 gated exactly like the
///    Tanzil text and the Madinah layout pack. A word whose ayah
///    reference does not resolve in the verified Quran text is dropped
///    at load with a logged count — bad data never reaches a learner.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/recitation_audio.dart';
import '../domain/mushaf_layout.dart';
import '../domain/word_deck.dart';

/// Recorded when the verified pack ships. Empty = pack absent, deck
/// starts empty (the tap-a-word loop still works — cards can be added
/// from the reader before the pack lands).
const String kWordPackSha256 =
    'd679b86a7126635e2c9dabf4a8788b3a71d8964bd0f42de2cb1215e9f6f40ccb';

abstract final class WordDeckRepository {
  static const String _deckKey = 'ar.academy.deck.v1';

  /// Load the learner's deck from on-device storage.
  /// Synchronous by design: SharedPreferences.getString is sync, and a
  /// synchronous initial load removes the async-clobber race in the
  /// notifier's constructor.
  static Map<String, WordCard> loadDeck(SharedPreferences prefs) {
    final String? raw = prefs.getString(_deckKey);
    if (raw == null) return <String, WordCard>{};
    final Map<String, dynamic> decoded =
        jsonDecode(raw) as Map<String, dynamic>;
    return <String, WordCard>{
      for (final MapEntry<String, dynamic> e in decoded.entries)
        e.key: WordCard.fromJson(e.value as Map<String, dynamic>),
    };
  }

  /// Persist the deck. On-device only — nothing leaves the phone.
  static Future<void> saveDeck(
    SharedPreferences prefs,
    Map<String, WordCard> deck,
  ) async {
    final Map<String, dynamic> encoded = <String, dynamic>{
      for (final MapEntry<String, WordCard> e in deck.entries)
        e.key: e.value.toJson(),
    };
    await prefs.setString(_deckKey, jsonEncode(encoded));
  }

  /// Load the verified top-300 pack. Returns null when absent or
  /// unverified. [isValidRef] must confirm each card's source ayah
  /// resolves in the checksum-verified Quran text — the caller (data
  /// layer) owns that truth, this repository only enforces the gate.
  static Future<List<WordCard>?> loadPack({
    required bool Function(AyahRef ref) isValidRef,
  }) async {
    if (kWordPackSha256.isEmpty) return null;
    String raw;
    try {
      raw = await rootBundle
          .loadString('assets/academy/word_pack.json');
    } catch (_) {
      return null;
    }
    // Checksum gate — same constitution rule as the other packs.
    final String digest =
        sha256.convert(utf8.encode(raw)).toString();
    if (digest != kWordPackSha256) {
      throw LayoutFormatException('word_pack.json checksum mismatch: $digest');
    }
    final Map<String, dynamic> doc =
        jsonDecode(raw) as Map<String, dynamic>;
    final List<WordCard> cards = <WordCard>[];
    int dropped = 0;
    for (final Map<String, dynamic> j
        in (doc['cards'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      final WordCard card = WordCard.fromJson(j);
      if (card.sourceAyah != null && !isValidRef(card.sourceAyah!)) {
        dropped++;
        continue;
      }
      cards.add(card);
    }
    if (dropped > 0) {
      // Logged, not thrown: a partially verified pack still teaches;
      // the count feeds the QA report. Never silent, never crashing.
      // ignore: avoid_print
      print('word_pack: dropped $dropped unverifiable cards');
    }
    return cards;
  }
}
