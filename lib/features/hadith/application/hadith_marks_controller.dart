import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
import '../domain/hadith_marks.dart';

/// Bookmarks and notes for The Forty Hadith, kept in this device's
/// preferences (the same way the Qur'an reader keeps ayah marks). All edits go
/// through here so the stored value is always valid.
class HadithMarksController extends Notifier<HadithMarks> {
  static const String prefsKey = 'ar.hadith.marks.v1';

  int Function() clock = () => DateTime.now().millisecondsSinceEpoch;

  @override
  HadithMarks build() {
    try {
      final SharedPreferences p = ref.watch(sharedPreferencesProvider);
      return HadithMarks.decode(p.getString(prefsKey));
    } catch (_) {
      return const HadithMarks();
    }
  }

  Future<void> _commit(HadithMarks next) async {
    state = next;
    try {
      await ref
          .read(sharedPreferencesProvider)
          .setString(prefsKey, next.encode());
    } catch (_) {
      // No storage in this context: the edit lives for this session.
    }
  }

  HadithMarks _with(HadithMark mark) {
    final Map<int, HadithMark> marks = Map<int, HadithMark>.of(state.marks);
    if (mark.isEmpty) {
      marks.remove(mark.number);
    } else {
      marks[mark.number] = mark.copyWith(updatedMs: clock());
    }
    return HadithMarks(marks: marks);
  }

  HadithMark _current(int number) =>
      state.of(number) ?? HadithMark(number: number);

  /// Bookmark on/off. Switching a bookmark off keeps the note, if any.
  Future<void> toggleBookmark(int number) {
    final HadithMark m = _current(number);
    return _commit(_with(m.copyWith(bookmarked: !m.bookmarked)));
  }

  /// Saves [note] for the hadith; an empty note removes it.
  Future<void> setNote(int number, String note) {
    return _commit(_with(_current(number).copyWith(note: note.trim())));
  }
}

final NotifierProvider<HadithMarksController, HadithMarks>
hadithMarksProvider =
    NotifierProvider<HadithMarksController, HadithMarks>(
      HadithMarksController.new,
    );
