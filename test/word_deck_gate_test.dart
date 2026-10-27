import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/features/academy/domain/recitation_audio.dart';
import 'package:ar_rayaan/features/academy/domain/spaced_repetition.dart';
import 'package:ar_rayaan/features/academy/domain/word_deck.dart';
import 'package:ar_rayaan/features/academy/presentation/word_deck_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rule: never invent a word meaning or root. A meaning is shown only when a
/// named, licence-checked source is recorded on the card. The shipped pack
/// has no such source yet (the Quranic Arabic Corpus is GPL v3 with unstated
/// data terms; QUL lists no per-resource licence), so its meanings stay
/// hidden until one is chosen.
void main() {
  final DateTime now = DateTime(2026, 10, 20, 9);

  WordCard card({String? source, String gloss = 'book'}) => WordCard(
        key: 'k',
        arabic: 'x',
        gloss: gloss,
        root: 'ك ت ب',
        glossSource: source,
        sourceAyah: const AyahRef(2, 2),
        review: ReviewCard(wordKey: 'k', dueDate: now),
      );

  test('a gloss with no source is never a meaning', () {
    expect(card().hasMeaning, isFalse);
    expect(card(source: '  ').hasMeaning, isFalse);
    expect(card(source: 'Named Source v1, licence X').hasMeaning, isTrue);
  });

  test('a source does not rescue a truncated or empty gloss', () {
    expect(card(source: 's', gloss: '').hasMeaning, isFalse);
    expect(card(source: 's', gloss: 'a … (in context)').hasMeaning, isFalse);
  });

  test('glossSource survives a save and load', () {
    final WordCard back = WordCard.fromJson(
        card(source: 'Named Source v1').toJson());
    expect(back.glossSource, 'Named Source v1');
    expect(back.hasMeaning, isTrue);
    expect(WordCard.fromJson(card().toJson()).hasMeaning, isFalse);
  });

  test('every meaning in the shipped pack is either sourced or hidden', () {
    final Map<String, dynamic> d = json.decode(
            File('assets/academy/word_pack.json').readAsStringSync())
        as Map<String, dynamic>;
    int shown = 0;
    int hidden = 0;
    for (final dynamic c in d['cards'] as List<dynamic>) {
      final WordPackCard p =
          WordPackCard.fromJson(Map<String, dynamic>.from(c as Map));
      if (p.hasMeaning) {
        shown++;
        expect(p.glossSource, isNotEmpty);
      } else {
        hidden++;
      }
    }
    expect(shown + hidden, 300);
    // The pack itself is checksum-pinned and carries no source; the meanings
    // live in word_glosses.json (see word_gloss_test.dart).
    expect(shown, 0);
  });
}
