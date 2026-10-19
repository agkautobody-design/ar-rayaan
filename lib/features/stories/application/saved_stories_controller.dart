import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';

/// Stories the user asked Hādi to bookmark. Deliberately small: a set of
/// story ids, persisted on-device. The Bookmarks surface in My Journey
/// reads this same provider, so Hādi's hand and the UI stay in sync.
class SavedStoriesController extends Notifier<Set<String>> {
  static const String key = 'ar.stories.saved';

  @override
  Set<String> build() {
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      return prefs.getStringList(key)?.toSet() ?? <String>{};
    } catch (_) {
      return <String>{}; // stateless fallback (widget tests)
    }
  }

  Future<void> save(String id) async {
    if (state.contains(id)) return;
    state = <String>{...state, id};
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setStringList(key, state.toList());
    } catch (_) {}
  }

  Future<void> toggle(String id) async {
    state = state.contains(id)
        ? (state..remove(id))
        : <String>{...state, id};
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setStringList(key, state.toList());
    } catch (_) {}
  }
}

final savedStoriesProvider =
    NotifierProvider<SavedStoriesController, Set<String>>(
        SavedStoriesController.new);
