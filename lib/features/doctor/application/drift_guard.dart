import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../hadi/data/api_key_vault.dart';

/// THE WATCHDOG. Scans the app's vitals on launch (and on demand), records
/// a baseline, and flags drift: anything that changed for the worse since
/// the last good scan. The Doctor menu shows an amber light while drift
/// stands unresolved.
class DriftReport {
  final DateTime at;
  final int checks;
  final List<String> drifts;
  final bool keyPresent;
  const DriftReport(this.at, this.checks, this.drifts, this.keyPresent);

  bool get healthy => drifts.isEmpty;
}

class DriftGuard {
  static const _baselinePref = 'ar.doctor.baseline';
  static const _lastPref = 'ar.doctor.last';

  /// Letters v1 (28 lessons) + Letters v2 (12 lessons).
  static const int minLetterLessons = 40;
  static const List<String> letterCurricula = <String>[
    'assets/academy/letters_curriculum.json',
    'assets/academy/letters_v2_curriculum.json',
  ];

  /// Number of lessons in one letters curriculum file's JSON text.
  static int lessonsIn(String raw) {
    final Map<String, dynamic> cur = json.decode(raw) as Map<String, dynamic>;
    return (cur['units'] as List<dynamic>).fold<int>(
      0,
      (int a, dynamic u) => a + ((u as Map<String, dynamic>)['lessons'] as List<dynamic>).length,
    );
  }

  Future<int> _letterLessonCount() async {
    int total = 0;
    for (final String path in letterCurricula) {
      total += lessonsIn(await rootBundle.loadString(path));
    }
    return total;
  }


  Future<DriftReport> scan() async {
    final drifts = <String>[];
    var checks = 0;
    final prefs = await SharedPreferences.getInstance();

    // 1. AI key presence (Hadi/Wasia/Doctor share it)
    final keyPresent = (ApiKeyVault.read(prefs) ?? '').trim().isNotEmpty;
    checks++;

    // 2. Core packs load
    const packs = <String>[
      'assets/stories/prophets.json', 'assets/stories/women.json',
      'assets/stories/seerah.json', 'assets/stories/companions.json',
      'assets/stories/ghayb.json', 'assets/stories/dailyduas.json',
      'assets/academy/letters_curriculum.json',
      'assets/academy/letters_v2_curriculum.json',
      'assets/academy/player_catalog.json', 'assets/feelings/feelings.json',
    ];
    var loaded = 0;
    for (final p in packs) {
      try {
        final raw = await rootBundle.loadString(p);
        if (raw.isNotEmpty) loaded++;
      } catch (_) {}
    }
    checks += packs.length;
    if (loaded < packs.length) {
      drifts.add('${packs.length - loaded} content pack(s) failed to load');
    }

    // 3. Curriculum depth (Wasia's classroom must be complete): v1 has 28
    // lessons, Letters v2 adds 12, so 40 across both files.
    try {
      final lessons = await _letterLessonCount();
      checks++;
      if (lessons < minLetterLessons) {
        drifts.add('curriculum thinned: $lessons/$minLetterLessons lessons');
      }
    } catch (_) {
      drifts.add('curriculum unreadable');
    }

    // 4. Catalog armed (checksum-gated pack must be present)
    try {
      final cat = json.decode(await rootBundle
              .loadString('assets/academy/player_catalog.json'))
          as Map<String, dynamic>;
      checks++;
      if ((cat['tracks'] as List).length < 200) {
        drifts.add('player library thinned');
      }
    } catch (_) {
      drifts.add('player catalog unreadable');
    }

    // 5. Drift vs baseline: record structural counts once, compare after
    final baseline = prefs.getString(_baselinePref);
    final now = <String, int>{
      'packs': loaded, 'lessons': 0, 'tracks': 0,
    };
    try {
      now['lessons'] = await _letterLessonCount();
      final cat = json.decode(await rootBundle
              .loadString('assets/academy/player_catalog.json'))
          as Map<String, dynamic>;
      now['tracks'] = (cat['tracks'] as List).length;
    } catch (_) {}
    if (baseline == null) {
      await prefs.setString(_baselinePref, json.encode(now));
    } else {
      final base = Map<String, int>.from(
          (json.decode(baseline) as Map).map((k, v) => MapEntry(k, (v as num).toInt())));
      for (final e in now.entries) {
        if ((base[e.key] ?? 0) > e.value) {
          drifts.add('${e.key} shrank since baseline '
              '(${base[e.key]} -> ${e.value})');
        }
      }
    }

    final report = DriftReport(DateTime.now(), checks, drifts, keyPresent);
    await prefs.setString(_lastPref, json.encode(<String, dynamic>{
      'at': report.at.toIso8601String(),
      'checks': checks,
      'drifts': drifts,
    }));
    return report;
  }
}

final driftGuardProvider = Provider<DriftGuard>((ref) => DriftGuard());

final driftReportProvider = FutureProvider<DriftReport>((ref) async {
  return ref.watch(driftGuardProvider).scan();
});
