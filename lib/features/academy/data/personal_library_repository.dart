/// Personal library repository — on-device only (Amanah: the app is a
/// player for the user's files, never a distributor). Prefs-backed JSON.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/personal_library.dart';

abstract final class PersonalLibraryRepository {
  static const String _key = 'ar.player.personal.v1';
  static const String _hiddenKey = 'ar.player.personal.hidden';

  static List<PersonalTrack> load(SharedPreferences prefs) {
    final String? raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <PersonalTrack>[];
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return <PersonalTrack>[
      for (final Map<String, dynamic> j in decoded.cast<Map<String, dynamic>>())
        PersonalTrack.fromJson(j),
    ];
  }

  static Future<void> save(
      SharedPreferences prefs, List<PersonalTrack> tracks) async {
    await prefs.setString(_key,
        jsonEncode(tracks.map((PersonalTrack t) => t.toJson()).toList()));
  }

  static bool isHidden(SharedPreferences prefs) =>
      prefs.getBool(_hiddenKey) ?? false;

  static Future<void> setHidden(SharedPreferences prefs, bool hidden) async {
    await prefs.setBool(_hiddenKey, hidden);
  }
}
