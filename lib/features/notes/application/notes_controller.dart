import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
import '../domain/notes.dart';

/// The person's notes, newest first, kept in this device's preferences. All
/// edits go through here so the stored list is always valid.
class NotesController extends Notifier<List<NoteItem>> {
  static const String prefsKey = 'ar.notes';

  DateTime Function() clock = DateTime.now;

  @override
  List<NoteItem> build() {
    try {
      final SharedPreferences p = ref.watch(sharedPreferencesProvider);
      return decodeNotes(p.getString(prefsKey));
    } catch (_) {
      return const <NoteItem>[];
    }
  }

  Future<void> _commit(List<NoteItem> next) async {
    state = next;
    try {
      await ref
          .read(sharedPreferencesProvider)
          .setString(prefsKey, encodeNotes(next));
    } catch (_) {
      // No storage in this context: the edit lives for this session.
    }
  }

  /// Saves a new note and returns it. A note with only a body is kept; only
  /// a note with neither a title nor a body is refused (returns null).
  Future<NoteItem?> add({required String title, required String body}) async {
    final NoteItem? n = buildNote(title: title, body: body, now: clock());
    if (n == null) return null;
    await _commit(<NoteItem>[n, ...state]);
    return n;
  }

  /// Rewrites the note [at]. Returns the saved note, or null when nothing
  /// was saved (the note is gone, or both boxes are empty).
  Future<NoteItem?> edit(
    String at, {
    required String title,
    required String body,
  }) async {
    final int i = state.indexWhere((NoteItem n) => n.at == at);
    if (i < 0) return null;
    final NoteItem? n =
        buildNote(title: title, body: body, now: clock(), at: at);
    if (n == null) return null;
    final List<NoteItem> next = List<NoteItem>.of(state);
    next[i] = n;
    await _commit(next);
    return n;
  }

  Future<void> remove(String at) =>
      _commit(<NoteItem>[for (final NoteItem n in state) if (n.at != at) n]);

  /// Puts a deleted note back where it was (the Undo of a delete).
  Future<void> restore(NoteItem note, int index) {
    if (state.any((NoteItem n) => n.at == note.at)) return Future<void>.value();
    final List<NoteItem> next = List<NoteItem>.of(state);
    final int at = index < 0 ? 0 : (index > next.length ? next.length : index);
    next.insert(at, note);
    return _commit(next);
  }
}

final NotifierProvider<NotesController, List<NoteItem>> notesProvider =
    NotifierProvider<NotesController, List<NoteItem>>(NotesController.new);
