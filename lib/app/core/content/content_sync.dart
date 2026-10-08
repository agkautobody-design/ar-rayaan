import 'dart:convert';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Content Sync — Ar-Rayaan's live content layer.
///
/// GitHub's raw file service acts as the content server (the repo is public,
/// reads are free and keyless). On launch, release builds check
/// assets/content_version.json; any pack with a higher remote version is
/// downloaded once, cached on-device, and used from then on. Offline or on
/// failure, the device cache or the originally bundled copy is used — the
/// app never shows a dead screen because of a network.
///
/// Debug/test builds always use the bundled assets so tests stay hermetic.
class ContentSync {
  static const _remoteBase =
      'https://raw.githubusercontent.com/agkautobody-design/ar-rayaan/main/assets';

  static Map<String, int>? _versions;

  static Future<String> load(String assetPath) async {
    final bundled = await rootBundle.loadString('assets/$assetPath');
    if (!kReleaseMode) return bundled;

    try {
      final prefs = await SharedPreferences.getInstance();
      final versions = await _fetchVersions();
      final remoteVer = versions[assetPath] ?? 0;
      final localVer = prefs.getInt('cv_$assetPath') ?? 0;

      if (remoteVer > localVer) {
        final res = await http
            .get(Uri.parse('$_remoteBase/$assetPath'))
            .timeout(const Duration(seconds: 10));
        if (res.statusCode == 200 && res.body.isNotEmpty) {
          await prefs.setString('cp_$assetPath', res.body);
          await prefs.setInt('cv_$assetPath', remoteVer);
          return res.body;
        }
      }
      final cached = prefs.getString('cp_$assetPath');
      if (cached != null && cached.isNotEmpty) return cached;
    } catch (_) {
      // Offline / GitHub down — fall through to cache or bundle.
      try {
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getString('cp_$assetPath');
        if (cached != null && cached.isNotEmpty) return cached;
      } catch (_) {}
    }
    return bundled;
  }

  static Future<Map<String, int>> _fetchVersions() async {
    final cached = _versions;
    if (cached != null) return cached;
    final res = await http
        .get(Uri.parse('$_remoteBase/content_version.json'))
        .timeout(const Duration(seconds: 6));
    if (res.statusCode != 200) return const {};
    final map = json.decode(res.body) as Map<String, dynamic>;
    _versions = map.map((k, v) => MapEntry(k, (v as num).toInt()));
    return _versions!;
  }
}
