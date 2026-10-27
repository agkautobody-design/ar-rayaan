import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/academy/application/word_deck_provider.dart';
import 'package:ar_rayaan/features/academy/domain/spaced_repetition.dart';
import 'package:ar_rayaan/features/academy/domain/word_deck.dart';
import 'package:ar_rayaan/features/academy/domain/word_gloss.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<WordCard> _pack() {
  final Map<String, dynamic> d = json.decode(
          File('assets/academy/word_pack.json').readAsStringSync())
      as Map<String, dynamic>;
  return (d['cards'] as List<dynamic>)
      .map((dynamic e) => WordCard.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

Map<String, WordGloss> _glosses() => parseWordGlosses(
    File('assets/academy/word_glosses.json').readAsStringSync());

void main() {
  test('every one of the 300 pack words has a meaning in word_glosses.json',
      () {
    final Map<String, WordGloss> g = _glosses();
    final List<WordCard> pack = _pack();
    expect(pack, hasLength(300));
    for (final WordCard c in pack) {
      expect(g.containsKey(c.key), isTrue, reason: c.key);
      expect(g[c.key]!.gloss.trim(), isNotEmpty, reason: c.key);
      expect(g[c.key]!.gloss, isNot(contains('(in context)')), reason: c.key);
    }
    expect(g, hasLength(300));
  });

  test('merging gives every pack card a sourced meaning', () {
    final Map<String, WordGloss> g = _glosses();
    for (final WordCard c in _pack()) {
      final WordCard m = withGloss(c, g);
      expect(m.hasMeaning, isTrue, reason: c.key);
      expect(m.glossSource, kWordGlossSource);
      // The ayah, rank and review state are untouched.
      expect(m.sourceAyah?.surah, c.sourceAyah?.surah);
      expect(m.frequencyRank, c.frequencyRank);
    }
  });

  test('a learner-sourced meaning is not replaced', () {
    final Map<String, WordGloss> g = _glosses();
    final WordCard base = _pack().first;
    final WordCard own = WordCard(
      key: base.key,
      arabic: base.arabic,
      gloss: 'learner note',
      glossSource: 'learner',
      review: base.review,
    );
    expect(identical(withGloss(own, g), own), isTrue);
  });

  test('blank or key-less entries are never merged', () {
    final Map<String, WordGloss> g = parseWordGlosses(json.encode(<String, Object>{
      'glosses': <Map<String, String>>[
        <String, String>{'key': 'a', 'gloss': ''},
        <String, String>{'key': '', 'gloss': 'x'},
        <String, String>{'key': 'b', 'gloss': 'y'},
      ],
    }));
    expect(g.keys, <String>['b']);
  });

  test('a deck saved before the meanings existed is upgraded, progress kept',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final ProviderContainer c = ProviderContainer(overrides: <Override>[
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    final WordDeckNotifier n = c.read(wordDeckProvider.notifier);
    await n.seedPack(_pack());
    final String key = _pack().first.key;
    expect(c.read(wordDeckProvider)[key]!.hasMeaning, isFalse);
    await n.grade(key, ReviewGrade.good);
    final int interval = c.read(wordDeckProvider)[key]!.review.intervalDays;

    await n.applyGlosses(_glosses());
    final WordCard after = c.read(wordDeckProvider)[key]!;
    expect(after.hasMeaning, isTrue);
    expect(after.review.intervalDays, interval);
    expect(c.read(wordDeckProvider).values.every((WordCard w) => w.hasMeaning),
        isTrue);
    c.dispose();
  });
}
