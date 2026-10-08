/// Journey stamps (M2 / 2.5) — the user's own record that they completed
/// Umrah or Hajj. Dignity-first BY DESIGN: the API is add/remove/list only.
/// There are no counts, no streaks, no comparisons, no gamification hooks —
/// the domain cannot express them. Each stamp is self-attested and carries an
/// honesty label on screen ("self-recorded"). UI + review pending; the domain
/// is task-list wording verbatim, so it survives scope review.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum JourneyType { umrah, hajj }

class JourneyStamp {
  const JourneyStamp({
    required this.id,
    required this.type,
    required this.completedAt,
  });

  final String id;
  final JourneyType type;
  final DateTime completedAt;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'type': type.name,
        'completedAt': completedAt.toIso8601String(),
      };

  static JourneyStamp fromJson(Map<String, Object?> j) => JourneyStamp(
        id: (j['id'] ?? '') as String,
        type: JourneyType.values.asNameMap()[(j['type'] ?? '') as String] ??
            JourneyType.umrah,
        completedAt: DateTime.tryParse((j['completedAt'] ?? '') as String) ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class JourneyStampRepository {
  static const String kKey = 'ar.journey.stamps.v1';

  static List<JourneyStamp> load(SharedPreferences prefs) {
    final String? raw = prefs.getString(kKey);
    if (raw == null || raw.isEmpty) return <JourneyStamp>[];
    try {
      final List<Object?> list = jsonDecode(raw) as List<Object?>;
      return list
          .whereType<Map<String, Object?>>()
          .map(JourneyStamp.fromJson)
          .toList();
    } catch (_) {
      return <JourneyStamp>[]; // absent != corrupt (§8.20)
    }
  }

  static Future<void> save(
      SharedPreferences prefs, List<JourneyStamp> stamps) async {
    final String raw =
        jsonEncode(stamps.map((JourneyStamp s) => s.toJson()).toList());
    await prefs.setString(kKey, raw);
  }
}
