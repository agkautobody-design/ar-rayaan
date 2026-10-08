/// Personal library provider + household filter state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
import '../data/personal_library_repository.dart';
import '../domain/personal_library.dart';

final personalLibraryProvider =
    StateNotifierProvider<PersonalLibraryNotifier, List<PersonalTrack>>(
        (Ref ref) {
  return PersonalLibraryNotifier(ref.watch(sharedPreferencesProvider));
});

final personalHiddenProvider =
    StateNotifierProvider<PersonalHiddenNotifier, bool>((Ref ref) {
  return PersonalHiddenNotifier(ref.watch(sharedPreferencesProvider));
});

class PersonalLibraryNotifier extends StateNotifier<List<PersonalTrack>> {
  PersonalLibraryNotifier(this._prefs)
      : super(PersonalLibraryRepository.load(_prefs));

  final SharedPreferences _prefs;
  int _seq = 0;

  Future<void> add({required String title, required String source}) async {
    _seq++;
    final PersonalTrack t = PersonalTrack(
      id: 'p_${DateTime.now().millisecondsSinceEpoch}_$_seq',
      title: title,
      source: source,
      addedAt: DateTime.now(),
    );
    state = <PersonalTrack>[...state, t];
    await PersonalLibraryRepository.save(_prefs, state);
  }

  Future<void> remove(String id) async {
    state = state.where((PersonalTrack t) => t.id != id).toList();
    await PersonalLibraryRepository.save(_prefs, state);
  }
}

class PersonalHiddenNotifier extends StateNotifier<bool> {
  PersonalHiddenNotifier(this._prefs)
      : super(PersonalLibraryRepository.isHidden(_prefs));

  final SharedPreferences _prefs;

  Future<void> set(bool hidden) async {
    state = hidden;
    await PersonalLibraryRepository.setHidden(_prefs, hidden);
  }
}
