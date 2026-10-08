import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/nasheed_request.dart';

class NasheedRequestRepository {
  NasheedRequestRepository(this._prefs);
  final SharedPreferences _prefs;
  static const String kKey = 'ar.player.requests.v1';

  List<NasheedRequest> load() {
    final String? raw = _prefs.getString(kKey);
    if (raw == null || raw.isEmpty) return <NasheedRequest>[];
    try {
      final List<Object?> list = jsonDecode(raw) as List<Object?>;
      return list
          .whereType<Map<String, Object?>>()
          .map(NasheedRequest.fromJson)
          .toList();
    } catch (_) {
      return <NasheedRequest>[]; // absent != corrupt: start clean (§8.20)
    }
  }

  Future<void> save(List<NasheedRequest> requests) async {
    final String raw = jsonEncode(
        requests.map((NasheedRequest r) => r.toJson()).toList());
    await _prefs.setString(kKey, raw);
  }
}
