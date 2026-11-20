/// The poems the person added: kept on this device only.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart' show sharedPreferencesProvider;
import '../domain/user_poem.dart';

const String kUserPoemsKey = 'ar.naat.mine.v1';

final StateNotifierProvider<UserPoemsNotifier, List<UserPoem>>
userPoemsProvider =
    StateNotifierProvider<UserPoemsNotifier, List<UserPoem>>((Ref ref) {
      SharedPreferences? prefs;
      try {
        prefs = ref.read(sharedPreferencesProvider);
      } catch (_) {
        prefs = null; // built without preferences (tests): empty and unsaved
      }
      return UserPoemsNotifier(prefs);
    });

class UserPoemsNotifier extends StateNotifier<List<UserPoem>> {
  UserPoemsNotifier(this._prefs)
    : super(
        decodeUserPoems(
          (() {
            try {
              return _prefs?.getString(kUserPoemsKey);
            } catch (_) {
              return null;
            }
          })(),
        ),
      );

  final SharedPreferences? _prefs;
  int _seq = 0;

  /// Adds a poem and returns its id.
  Future<String> add({
    required String title,
    required String lang,
    required List<String> lines,
    String? meaningLang,
    List<String> meanings = const <String>[],
    String? audioUrl,
  }) async {
    _seq++;
    final String id = 'mine-${DateTime.now().millisecondsSinceEpoch}-$_seq';
    state = <UserPoem>[
      ...state,
      UserPoem(
        id: id,
        title: title.trim(),
        lang: lang,
        lines: lines,
        meaningLang: meanings.isEmpty ? null : meaningLang,
        meanings: meanings,
        audioUrl: (audioUrl == null || !audioUrl.trim().startsWith('http'))
            ? null
            : audioUrl.trim(),
      ),
    ];
    await _save();
    return id;
  }

  Future<void> remove(String id) async {
    state = state.where((UserPoem p) => p.id != id).toList();
    await _save();
  }

  Future<void> _save() async {
    try {
      await _prefs?.setString(kUserPoemsKey, encodeUserPoems(state));
    } catch (_) {
      // Kept for this session at least.
    }
  }
}
