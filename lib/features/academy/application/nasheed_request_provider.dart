/// Request channel provider (1b.4). Mirrors the personal-library pattern:
/// SharedPreferences injected via sharedPreferencesProvider, synchronous
/// initial load in the super() initializer (§8.18 — no constructor race).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
import '../data/nasheed_request_repository.dart';
import '../domain/nasheed_request.dart';

final nasheedRequestProvider =
    StateNotifierProvider<NasheedRequestNotifier, List<NasheedRequest>>(
        (Ref ref) {
  return NasheedRequestNotifier(ref.watch(sharedPreferencesProvider));
});

class NasheedRequestNotifier extends StateNotifier<List<NasheedRequest>> {
  NasheedRequestNotifier(this._prefs)
      : super(NasheedRequestRepository(_prefs).load());

  final SharedPreferences _prefs;
  late final NasheedRequestRepository _repo = NasheedRequestRepository(_prefs);

  Future<NasheedRequest> add({
    required String title,
    String? artist,
    String? url,
    String? note,
  }) async {
    final String t = title.trim();
    if (t.isEmpty) {
      throw ArgumentError.value(title, 'title', 'title is required');
    }
    final NasheedRequest r = NasheedRequest(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: t,
      artist: (artist == null || artist.trim().isEmpty) ? null : artist.trim(),
      url: (url == null || url.trim().isEmpty) ? null : url.trim(),
      note: (note == null || note.trim().isEmpty) ? null : note.trim(),
      createdAt: DateTime.now(),
    );
    state = <NasheedRequest>[r, ...state];
    await _repo.save(state);
    return r;
  }

  Future<void> remove(String id) async {
    state = state.where((NasheedRequest r) => r.id != id).toList();
    await _repo.save(state);
  }
}
