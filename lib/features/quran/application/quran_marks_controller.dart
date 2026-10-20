import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
import '../domain/quran_marks.dart';

/// Bookmarks, collections and notes for ayahs, kept in this device's
/// preferences. All edits go through here so the store is always valid.
class QuranMarksController extends Notifier<QuranMarks> {
  static const String prefsKey = 'ar.quran.marks.v1';

  int Function() clock = () => DateTime.now().millisecondsSinceEpoch;

  @override
  QuranMarks build() {
    try {
      final SharedPreferences p = ref.watch(sharedPreferencesProvider);
      return QuranMarks.decode(p.getString(prefsKey));
    } catch (_) {
      return const QuranMarks();
    }
  }

  Future<void> _commit(QuranMarks next) async {
    state = next;
    try {
      await ref
          .read(sharedPreferencesProvider)
          .setString(prefsKey, next.encode());
    } catch (_) {
      // No storage in this context: the edit lives for this session.
    }
  }

  QuranMarks _with(AyahMark mark) {
    final Map<String, AyahMark> marks =
        Map<String, AyahMark>.of(state.marks);
    if (mark.isEmpty) {
      marks.remove(mark.key);
    } else {
      marks[mark.key] = mark.copyWith(updatedMs: clock());
    }
    return QuranMarks(marks: marks, collections: state.collections);
  }

  AyahMark _current(int surah, int ayah) =>
      state.of(surah, ayah) ?? AyahMark(surah: surah, ayah: ayah);

  /// Bookmark on/off. Switching a bookmark off also takes the ayah out of
  /// every collection; its note, if any, is kept.
  Future<void> toggleBookmark(int surah, int ayah) {
    final AyahMark m = _current(surah, ayah);
    return _commit(
      _with(
        m.bookmarked
            ? m.copyWith(bookmarked: false, collections: const <String>[])
            : m.copyWith(bookmarked: true),
      ),
    );
  }

  Future<void> setNote(int surah, int ayah, String note) {
    return _commit(_with(_current(surah, ayah).copyWith(note: note.trim())));
  }

  /// Adds or removes the ayah from a collection. Adding also bookmarks it.
  Future<void> toggleInCollection(int surah, int ayah, String collectionId) {
    final AyahMark m = _current(surah, ayah);
    final List<String> next = List<String>.of(m.collections);
    if (next.contains(collectionId)) {
      next.remove(collectionId);
      return _commit(_with(m.copyWith(collections: next)));
    }
    if (state.collection(collectionId) == null) return Future<void>.value();
    next.add(collectionId);
    return _commit(_with(m.copyWith(bookmarked: true, collections: next)));
  }

  /// Makes a collection and returns its id (an existing one with the same
  /// name, ignoring case, is reused).
  Future<String> createCollection(String name) async {
    final String clean = name.trim();
    if (clean.isEmpty) return '';
    for (final QuranCollection c in state.collections) {
      if (c.name.toLowerCase() == clean.toLowerCase()) return c.id;
    }
    final String id = 'c${clock()}-${state.collections.length}';
    await _commit(
      QuranMarks(
        marks: state.marks,
        collections: <QuranCollection>[
          ...state.collections,
          QuranCollection(id: id, name: clean),
        ],
      ),
    );
    return id;
  }

  /// Deletes a collection. The ayahs stay bookmarked; only the grouping goes.
  Future<void> deleteCollection(String id) {
    final Map<String, AyahMark> marks = <String, AyahMark>{};
    state.marks.forEach((String k, AyahMark m) {
      marks[k] = m.collections.contains(id)
          ? m.copyWith(
              collections: <String>[
                for (final String c in m.collections)
                  if (c != id) c,
              ],
            )
          : m;
    });
    return _commit(
      QuranMarks(
        marks: marks,
        collections: <QuranCollection>[
          for (final QuranCollection c in state.collections)
            if (c.id != id) c,
        ],
      ),
    );
  }
}

final NotifierProvider<QuranMarksController, QuranMarks> quranMarksProvider =
    NotifierProvider<QuranMarksController, QuranMarks>(
      QuranMarksController.new,
    );
