import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// How a person says they are, in one tap. No score, no streak, no
/// diagnosis: a private note to themselves.
enum Mood {
  heavy('Heavy', 'h'),
  low('Low', 'l'),
  okay('Okay', 'o'),
  good('Good', 'g'),
  grateful('Grateful', 'a');

  const Mood(this.label, this.code);
  final String label;
  final String code;

  static Mood? fromCode(String? c) {
    for (final Mood m in Mood.values) {
      if (m.code == c) return m;
    }
    return null;
  }
}

class MoodEntry {
  const MoodEntry(this.day, this.mood);

  /// `yyyy-MM-dd`
  final String day;
  final Mood mood;
}

/// Mood check-ins, on this device only. One entry per day; a second tap the
/// same day replaces the first.
class MoodStore {
  MoodStore(this._prefs);

  final SharedPreferences _prefs;

  static const String key = 'ar.sakina.mood';
  static const int maxDays = 400;

  static String dayOf(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<MoodEntry> get all {
    try {
      final String? raw = _prefs.getString(key);
      if (raw == null || raw.isEmpty) return <MoodEntry>[];
      final List<MoodEntry> out = <MoodEntry>[];
      for (final dynamic e in json.decode(raw) as List<dynamic>) {
        final List<dynamic> row = e as List<dynamic>;
        final Mood? m = Mood.fromCode(row[1] as String?);
        if (m != null) out.add(MoodEntry(row[0] as String, m));
      }
      return out;
    } catch (_) {
      return <MoodEntry>[];
    }
  }

  Future<void> record(Mood mood, {DateTime? now}) async {
    final String today = dayOf(now ?? DateTime.now());
    final List<MoodEntry> next = <MoodEntry>[
      for (final MoodEntry e in all)
        if (e.day != today) e,
      MoodEntry(today, mood),
    ];
    final List<MoodEntry> tail =
        next.length > maxDays ? next.sublist(next.length - maxDays) : next;
    await _prefs.setString(
      key,
      json.encode(<List<String>>[
        for (final MoodEntry e in tail) <String>[e.day, e.mood.code],
      ]),
    );
  }

  /// Entries from the last [days] days (including today), oldest first.
  List<MoodEntry> lastDays(int days, {DateTime? now}) {
    final DateTime n = now ?? DateTime.now();
    final String from = dayOf(n.subtract(Duration(days: days - 1)));
    return <MoodEntry>[
      for (final MoodEntry e in all)
        if (e.day.compareTo(from) >= 0) e,
    ];
  }

  Future<void> clear() async {
    await _prefs.remove(key);
  }

  /// Plain text a person can copy out of the app.
  String exportText() {
    final StringBuffer b = StringBuffer('Date, How I was\n');
    for (final MoodEntry e in all) {
      b.writeln('${e.day}, ${e.mood.label}');
    }
    return b.toString();
  }
}

/// A short written plan for a hard moment, in the order used in
/// Stanley-Brown safety planning. Written by the person, stored only on this
/// device. It has NOT yet been reviewed by a clinician, and says so.
class SafetyPlan {
  const SafetyPlan({
    this.warningSigns = '',
    this.copingSteps = '',
    this.distractionPeople = '',
    this.peopleToAsk = '',
    this.professionals = '',
    this.safeSpace = '',
    this.reasons = '',
  });

  final String warningSigns;
  final String copingSteps;
  final String distractionPeople;
  final String peopleToAsk;
  final String professionals;
  final String safeSpace;
  final String reasons;

  bool get isEmpty =>
      warningSigns.trim().isEmpty &&
      copingSteps.trim().isEmpty &&
      distractionPeople.trim().isEmpty &&
      peopleToAsk.trim().isEmpty &&
      professionals.trim().isEmpty &&
      safeSpace.trim().isEmpty &&
      reasons.trim().isEmpty;

  Map<String, String> toMap() => <String, String>{
        'warningSigns': warningSigns,
        'copingSteps': copingSteps,
        'distractionPeople': distractionPeople,
        'peopleToAsk': peopleToAsk,
        'professionals': professionals,
        'safeSpace': safeSpace,
        'reasons': reasons,
      };

  static SafetyPlan fromMap(Map<String, dynamic> m) => SafetyPlan(
        warningSigns: m['warningSigns'] as String? ?? '',
        copingSteps: m['copingSteps'] as String? ?? '',
        distractionPeople: m['distractionPeople'] as String? ?? '',
        peopleToAsk: m['peopleToAsk'] as String? ?? '',
        professionals: m['professionals'] as String? ?? '',
        safeSpace: m['safeSpace'] as String? ?? '',
        reasons: m['reasons'] as String? ?? '',
      );

  String exportText() => 'My safety plan\n\n'
      '1. Signs that a hard moment is starting:\n$warningSigns\n\n'
      '2. Things I can do on my own:\n$copingSteps\n\n'
      '3. People and places that help me think of something else:\n'
      '$distractionPeople\n\n'
      '4. People I can ask for help:\n$peopleToAsk\n\n'
      '5. Professionals and lines I can contact:\n$professionals\n\n'
      '6. Making my space safer:\n$safeSpace\n\n'
      '7. What I am living for:\n$reasons\n';
}

class SafetyPlanStore {
  SafetyPlanStore(this._prefs);

  final SharedPreferences _prefs;
  static const String key = 'ar.sakina.safetyplan';

  SafetyPlan load() {
    try {
      final String? raw = _prefs.getString(key);
      if (raw == null || raw.isEmpty) return const SafetyPlan();
      return SafetyPlan.fromMap(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const SafetyPlan();
    }
  }

  Future<void> save(SafetyPlan p) async {
    await _prefs.setString(key, json.encode(p.toMap()));
  }

  Future<void> clear() async {
    await _prefs.remove(key);
  }
}
