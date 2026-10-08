import 'package:ar_rayaan/features/academy/application/word_deck_provider.dart';
import 'package:ar_rayaan/features/academy/domain/recitation_audio.dart';
import 'package:ar_rayaan/features/academy/domain/spaced_repetition.dart';
import 'package:ar_rayaan/features/academy/domain/word_deck.dart';
import 'package:ar_rayaan/app/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<ProviderContainer> makeContainer() async {
    // NOTE: setMockInitialValues is called once in setUp — calling it
    // again would wipe the store and defeat the persistence test.
    final prefs = await SharedPreferences.getInstance();
    return ProviderContainer(overrides: <Override>[
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
  }

  test('deck persists across notifier instances (on-device only)', () async {
    final c1 = await makeContainer();
    await c1.read(wordDeckProvider.notifier).addFromReader(
          arabic: 'كِتَاب',
          gloss: 'book',
          sourceAyah: const AyahRef(2, 2),
          root: 'ك ت ب',
        );
    c1.dispose();

    final c2 = await makeContainer();
    final deck = c2.read(wordDeckProvider);
    expect(deck.length, 1);
    expect(deck['2:2:كِتَاب']!.arabic, 'كِتَاب');
    c2.dispose();
  });

  test('addFromReader never duplicates a word', () async {
    final c = await makeContainer();
    final n = c.read(wordDeckProvider.notifier);
    await n.addFromReader(
        arabic: 'رَبّ', gloss: 'lord', sourceAyah: const AyahRef(1, 2));
    await n.addFromReader(
        arabic: 'رَبّ', gloss: 'lord', sourceAyah: const AyahRef(1, 2));
    expect(c.read(wordDeckProvider).length, 1);
    c.dispose();
  });

  test('grade reschedules and persists', () async {
    final c = await makeContainer();
    final n = c.read(wordDeckProvider.notifier);
    await n.addFromReader(
        arabic: 'رَبّ', gloss: 'lord', sourceAyah: const AyahRef(1, 2));
    await n.grade('1:2:رَبّ', ReviewGrade.good);
    expect(c.read(wordDeckProvider)['1:2:رَبّ']!.review.intervalDays, 1);
    c.dispose();
  });

  test('todaySession is empty on a fresh deck; wordsDue counts the queue',
      () async {
    final c = await makeContainer();
    expect(c.read(todaySessionProvider), isEmpty);
    expect(c.read(wordsDueProvider), 0);
    c.dispose();
  });

  test('pack seeding adds only new cards', () async {
    final c = await makeContainer();
    final n = c.read(wordDeckProvider.notifier);
    await n.addFromReader(
        arabic: 'كِتَاب', gloss: 'book', sourceAyah: const AyahRef(2, 2));
    final DateTime now = DateTime.now();
    await n.seedPack(<WordCard>[
      WordCard(
        key: '2:2:كِتَاب',
        arabic: 'كِتَاب',
        gloss: 'book',
        review: ReviewCard(wordKey: '2:2:كِتَاب', dueDate: now),
      ),
      WordCard(
        key: '1:1:بِسْمِ',
        arabic: 'بِسْمِ',
        gloss: 'in the name',
        review: ReviewCard(wordKey: '1:1:بِسْمِ', dueDate: now),
      ),
    ]);
    expect(c.read(wordDeckProvider).length, 2,
        reason: 'existing learner card untouched, new one added');
    c.dispose();
  });
}
