import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
import '../data/bundled_adhkar_repository.dart';
import '../domain/adhkar_models.dart';
import 'adhkar_repository.dart';

final Provider<AdhkarRepository> adhkarRepositoryProvider =
    Provider<AdhkarRepository>((ref) => BundledAdhkarRepository());

final FutureProvider<List<AdhkarSet>> adhkarSetsProvider =
    FutureProvider<List<AdhkarSet>>((ref) {
      return ref.watch(adhkarRepositoryProvider).sets();
    });

/// Completed repetitions per set → dhikr number. Resets daily.
class AdhkarProgressController extends Notifier<Map<String, Map<int, int>>> {
  static String _todayKey() {
    final DateTime d = DateTime.now();
    return 'ar.adhkar.${d.year}-${d.month}-${d.day}';
  }

  @override
  Map<String, Map<int, int>> build() {
    try {
      final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
      final String? raw = prefs.getString(_todayKey());
      if (raw != null) {
        final Map<String, dynamic> j = jsonDecode(raw) as Map<String, dynamic>;
        return <String, Map<int, int>>{
          for (final MapEntry<String, dynamic> e in j.entries)
            e.key: <int, int>{
              for (final MapEntry<String, dynamic> i
                  in (e.value as Map<String, dynamic>).entries)
                int.parse(i.key): i.value as int,
            },
        };
      }
    } catch (_) {
      // In-memory only.
    }
    return <String, Map<int, int>>{};
  }

  Future<void> _persist() async {
    try {
      final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(
        _todayKey(),
        jsonEncode(<String, dynamic>{
          for (final MapEntry<String, Map<int, int>> e in state.entries)
            e.key: <String, dynamic>{
              for (final MapEntry<int, int> i in e.value.entries)
                '${i.key}': i.value,
            },
        }),
      );
    } catch (_) {
      // In-memory only.
    }
  }

  /// One repetition completed (capped at [max]).
  Future<void> increment(String setId, int dhikrNumber, int max) async {
    final Map<String, Map<int, int>> next = <String, Map<int, int>>{
      ...state,
      setId: <int, int>{...?state[setId]},
    };
    final int current = next[setId]![dhikrNumber] ?? 0;
    if (current >= max) return;
    next[setId]![dhikrNumber] = current + 1;
    state = next;
    await _persist();
  }

  int doneFor(String setId, int dhikrNumber) => state[setId]?[dhikrNumber] ?? 0;

  /// Repetitions completed across a whole set.
  int completedInSet(AdhkarSet set) {
    final Map<int, int> counts = state[set.id] ?? const <int, int>{};
    int total = 0;
    for (final Dhikr d in set.items) {
      final int c = counts[d.number] ?? 0;
      total += c > d.count ? d.count : c;
    }
    return total;
  }

  Future<void> resetSet(String setId) async {
    if (!state.containsKey(setId)) return;
    state = <String, Map<int, int>>{...state}..remove(setId);
    await _persist();
  }
}

final NotifierProvider<AdhkarProgressController, Map<String, Map<int, int>>>
adhkarProgressProvider =
    NotifierProvider<AdhkarProgressController, Map<String, Map<int, int>>>(
      AdhkarProgressController.new,
    );
