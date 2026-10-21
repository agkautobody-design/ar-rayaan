/// The Dhikr Session — guided remembrance (Sonic System §4: the
/// signature). Meaning first, breath-paced counting, milestone pauses,
/// silence at the end. Pure state machine — the screen renders it.
library;

import 'dart:convert';

class DhikrSet {
  const DhikrSet({
    required this.id,
    required this.arabic,
    required this.meaning,
    required this.target,
  });

  final String id;
  final String arabic;
  final String meaning;
  final int target;

  static const List<DhikrSet> classics = <DhikrSet>[
    DhikrSet(id: 'subhan', arabic: 'سُبْحَانَ اللَّهِ', meaning: 'Glory be to Allah', target: 33),
    DhikrSet(id: 'hamd', arabic: 'الْحَمْدُ لِلَّهِ', meaning: 'All praise is for Allah', target: 33),
    DhikrSet(id: 'akbar', arabic: 'اللَّهُ أَكْبَرُ', meaning: 'Allah is Greatest', target: 33),
    DhikrSet(id: 'istighfar', arabic: 'أَسْتَغْفِرُ اللَّهَ', meaning: 'I seek Allah’s forgiveness', target: 100),
  ];
}

enum DhikrPhase { counting, milestonePause, complete }

class DhikrSessionState {
  const DhikrSessionState({
    required this.set,
    this.count = 0,
    this.phase = DhikrPhase.counting,
  });

  final DhikrSet set;
  final int count;
  final DhikrPhase phase;

  double get progress => set.target == 0 ? 0 : count / set.target;

  bool get isMilestone =>
      phase == DhikrPhase.milestonePause;

  DhikrSessionState copyWith({int? count, DhikrPhase? phase}) =>
      DhikrSessionState(
        set: set,
        count: count ?? this.count,
        phase: phase ?? this.phase,
      );
}

abstract final class DhikrSessionEngine {
  /// One tap of the tasbih. Milestone rule (Sonic §4): at each 33 the
  /// session PAUSES (phase = milestonePause); the next tap resumes AND
  /// counts, so a 100-count set takes exactly 100 taps.
  /// Completing the target ends in silence (phase = complete).
  static DhikrSessionState tap(DhikrSessionState s) {
    if (s.phase == DhikrPhase.complete) return s;
    final DhikrSessionState base = s.phase == DhikrPhase.milestonePause
        ? s.copyWith(phase: DhikrPhase.counting)
        : s;
    final int next = base.count + 1;
    if (next >= base.set.target) {
      return base.copyWith(count: next, phase: DhikrPhase.complete);
    }
    if (next % 33 == 0) {
      return base.copyWith(count: next, phase: DhikrPhase.milestonePause);
    }
    return base.copyWith(count: next);
  }

  /// What to say during a milestone pause: the real position, never a
  /// fraction that is only true once ("a third of the way" at 66 or 99
  /// was wrong).
  static String milestoneMessage(DhikrSessionState s) =>
      '${s.count} of ${s.set.target}. Breathe \u2014 then continue.';

  static DhikrSessionState reset(DhikrSet set) =>
      DhikrSessionState(set: set);
}

/// A half-finished session, kept on this device so leaving the screen (or
/// the app) does not lose it. One snapshot, for today only: a session left
/// from another day starts again rather than pretending it is still going.
abstract final class DhikrSnapshot {
  static const String prefKey = 'ar.academy.dhikr.session.v1';

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// The text to store for [s]. Null when there is nothing to keep (nothing
  /// counted yet, or the set is complete).
  static String? encode(DhikrSessionState s, DateTime now) {
    if (s.count <= 0 || s.phase == DhikrPhase.complete) return null;
    return jsonEncode(<String, Object>{
      'set': s.set.id,
      'count': s.count,
      'day': _day(now),
    });
  }

  /// The session stored in [raw], or null when there is none, it is from
  /// another day, its set is unknown or its count does not fit the set.
  static DhikrSessionState? decode(String? raw, DateTime now) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final Object? j = jsonDecode(raw);
      if (j is! Map<String, dynamic>) return null;
      if (j['day'] != _day(now)) return null;
      final Object? id = j['set'];
      final Object? count = j['count'];
      if (id is! String || count is! int) return null;
      for (final DhikrSet set in DhikrSet.classics) {
        if (set.id != id) continue;
        if (count <= 0 || count >= set.target) return null;
        return DhikrSessionState(
          set: set,
          count: count,
          phase: count % 33 == 0
              ? DhikrPhase.milestonePause
              : DhikrPhase.counting,
        );
      }
    } catch (_) {}
    return null;
  }
}
