import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static Map<String, dynamic> _fingerprint() => <String, dynamic>{};

  Future<DriftReport> scan() async {
    final drifts = <String>[];
    var checks = 0;
    final prefs = await SharedPreferences.getInstance();

    // 1. AI key presence (Hadi/Wasia/Doctor share it)
    final keyPresent =
        (prefs.getString('ar.hadi.apikey') ?? '').trim().isNotEmpty;
    checks++;

    // 2. Core packs load
    const packs = <String>[
      'assets/stories/prophets.json', 'assets/stories/women.json',
      'assets/stories/seerah.json', 'assets/stories/companions.json',
      'assets/stories/ghayb.json', 'assets/stories/dailyduas.json',
      'assets/academy/letters_curriculum.json',
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

    // 3. Curriculum depth (Wasia's classroom must be complete)
    try {
      final cur = json.decode(
          await rootBundle.loadString('assets/academy/letters_curriculum.json'))
          as Map<String, dynamic>;
      final lessons = (cur['units'] as List<dynamic>)
          .fold<int>(0, (a, u) => a + ((u as Map)['lessons'] as List).length);
      checks++;
      if (lessons < 28) drifts.add('curriculum thinned: $lessons/28 lessons');
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
      final cur = json.decode(
          await rootBundle.loadString('assets/academy/letters_curriculum.json'))
          as Map<String, dynamic>;
      now['lessons'] = (cur['units'] as List<dynamic>)
          .fold<int>(0, (a, u) => a + ((u as Map)['lessons'] as List).length);
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
