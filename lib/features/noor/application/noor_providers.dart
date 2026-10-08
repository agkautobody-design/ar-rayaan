import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
import '../data/bundled_noor_repository.dart';
import '../domain/noor_entry.dart';

/// Repository provider — bundled, offline.
final Provider<BundledNoorRepository> noorRepositoryProvider =
    Provider<BundledNoorRepository>((ref) => BundledNoorRepository());

/// Today's NOOR entry.
final FutureProvider<NoorEntry> todayNoorProvider = FutureProvider<NoorEntry>((
  ref,
) {
  return ref.watch(noorRepositoryProvider).entryFor(DateTime.now());
});

/// The user's saved reflections — persisted locally (syncs to the profile
/// record after O-4). Newest first, capped at 50.
final NotifierProvider<NoorReflectionsController, List<String>>
noorReflectionsProvider =
    NotifierProvider<NoorReflectionsController, List<String>>(
      NoorReflectionsController.new,
    );

class NoorReflectionsController extends Notifier<List<String>> {
  static const String _key = 'ar.noor.reflections';
  static const int _cap = 50;

  @override
  List<String> build() {
    try {
      final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
      final String? raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return <String>[];
      return (jsonDecode(raw) as List<dynamic>).cast<String>();
    } catch (_) {
      return <String>[];
    }
  }

  Future<void> add(String text) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final List<String> next = <String>[trimmed, ...state];
    if (next.length > _cap) next.removeRange(_cap, next.length);
    state = next;
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(_key, jsonEncode(state));
    } catch (_) {
      // Preferences unavailable (e.g. tests) — state stays in memory.
    }
  }
}
