library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
import '../domain/journey_stamp.dart';

final journeyStampsProvider =
    StateNotifierProvider<JourneyStampNotifier, List<JourneyStamp>>((Ref ref) {
  return JourneyStampNotifier(ref.watch(sharedPreferencesProvider));
});

class JourneyStampNotifier extends StateNotifier<List<JourneyStamp>> {
  JourneyStampNotifier(this._prefs) : super(JourneyStampRepository.load(_prefs));

  final SharedPreferences _prefs;

  Future<JourneyStamp> add({
    required JourneyType type,
    required DateTime completedAt,
  }) async {
    final JourneyStamp s = JourneyStamp(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      completedAt: completedAt,
    );
    state = <JourneyStamp>[s, ...state];
    await JourneyStampRepository.save(_prefs, state);
    return s;
  }

  Future<void> remove(String id) async {
    state = state.where((JourneyStamp s) => s.id != id).toList();
    await JourneyStampRepository.save(_prefs, state);
  }
}
