import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/quran/application/quran_marks_controller.dart';
import 'package:ar_rayaan/features/quran/domain/quran_marks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ProviderContainer> make([Map<String, Object>? initial]) async {
    SharedPreferences.setMockInitialValues(initial ?? <String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('bookmarks', () {
    test('toggle on, toggle off, and the store stays empty after', () async {
      final ProviderContainer c = await make();
      final QuranMarksController m = c.read(quranMarksProvider.notifier);
      expect(c.read(quranMarksProvider).marks, isEmpty);
      await m.toggleBookmark(2, 255);
      expect(c.read(quranMarksProvider).of(2, 255)?.bookmarked, isTrue);
      await m.toggleBookmark(2, 255);
      expect(c.read(quranMarksProvider).of(2, 255), isNull);
      expect(c.read(quranMarksProvider).marks, isEmpty);
    });

    test('survives a restart', () async {
      final ProviderContainer first = await make();
      await first.read(quranMarksProvider.notifier).toggleBookmark(18, 10);
      await first.read(quranMarksProvider.notifier).setNote(18, 10, '  the cave  ');
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      final ProviderContainer second = ProviderContainer(
        overrides: <Override>[sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(second.dispose);
      final AyahMark? m = second.read(quranMarksProvider).of(18, 10);
      expect(m?.bookmarked, isTrue);
      expect(m?.note, 'the cave', reason: 'notes are trimmed');
    });

    test('corrupt stored data opens as empty instead of failing', () async {
      final ProviderContainer c =
          await make(<String, Object>{QuranMarksController.prefsKey: '{nope'});
      expect(c.read(quranMarksProvider).marks, isEmpty);
    });
  });

  group('notes', () {
    test('a note works without a bookmark and is listed', () async {
      final ProviderContainer c = await make();
      final QuranMarksController m = c.read(quranMarksProvider.notifier);
      await m.setNote(1, 2, 'praise');
      final QuranMarks s = c.read(quranMarksProvider);
      expect(s.of(1, 2)?.bookmarked, isFalse);
      expect(s.list().map((AyahMark x) => x.key), <String>['1:2']);
    });

    test('clearing the note of an unbookmarked ayah removes the entry', () async {
      final ProviderContainer c = await make();
      final QuranMarksController m = c.read(quranMarksProvider.notifier);
      await m.setNote(1, 2, 'praise');
      await m.setNote(1, 2, '   ');
      expect(c.read(quranMarksProvider).marks, isEmpty);
    });

    test('removing a bookmark keeps the note', () async {
      final ProviderContainer c = await make();
      final QuranMarksController m = c.read(quranMarksProvider.notifier);
      await m.toggleBookmark(3, 8);
      await m.setNote(3, 8, 'dua');
      await m.toggleBookmark(3, 8);
      expect(c.read(quranMarksProvider).of(3, 8)?.note, 'dua');
      expect(c.read(quranMarksProvider).of(3, 8)?.bookmarked, isFalse);
    });
  });

  group('collections', () {
    test('create, add, filter, delete keeps the bookmark', () async {
      final ProviderContainer c = await make();
      final QuranMarksController m = c.read(quranMarksProvider.notifier);
      final String id = await m.createCollection('To memorise');
      expect(id, isNotEmpty);
      expect(await m.createCollection('to MEMORISE'), id,
          reason: 'same name, ignoring case, reuses the collection');
      expect(await m.createCollection('   '), isEmpty);

      await m.toggleInCollection(112, 1, id);
      await m.toggleBookmark(1, 1);
      QuranMarks s = c.read(quranMarksProvider);
      expect(s.of(112, 1)?.bookmarked, isTrue, reason: 'adding bookmarks');
      expect(s.list(collectionId: id).map((AyahMark x) => x.key), <String>['112:1']);
      expect(s.list().map((AyahMark x) => x.key), <String>['1:1', '112:1']);

      await m.deleteCollection(id);
      s = c.read(quranMarksProvider);
      expect(s.collections, isEmpty);
      expect(s.of(112, 1)?.bookmarked, isTrue);
      expect(s.of(112, 1)?.collections, isEmpty);
    });

    test('unknown collection ids are ignored', () async {
      final ProviderContainer c = await make();
      await c.read(quranMarksProvider.notifier).toggleInCollection(1, 1, 'ghost');
      expect(c.read(quranMarksProvider).marks, isEmpty);
    });

    test('un-bookmarking drops the ayah from its collections', () async {
      final ProviderContainer c = await make();
      final QuranMarksController m = c.read(quranMarksProvider.notifier);
      final String id = await m.createCollection('Reflect');
      await m.toggleInCollection(2, 286, id);
      await m.toggleBookmark(2, 286);
      expect(c.read(quranMarksProvider).of(2, 286), isNull);
    });
  });

  group('export', () {
    test('lists reference, text, note and credit', () async {
      final ProviderContainer c = await make();
      final QuranMarksController m = c.read(quranMarksProvider.notifier);
      await m.toggleBookmark(112, 1);
      await m.setNote(112, 1, 'tawhid');
      final String out = exportMarks(
        c.read(quranMarksProvider),
        lookup: (int s, int a) => (
          arabic: 'AR $s:$a',
          english: 'EN $s:$a',
          surahName: 'Al-Ikhlas',
        ),
      );
      expect(out, contains('Al-Ikhlas 112:1'));
      expect(out, contains('AR 112:1'));
      expect(out, contains('EN 112:1'));
      expect(out, contains('Note: tawhid'));
      expect(out, contains('Tanzil'));
      expect(out, contains('Saheeh International'));
    });
  });
}
