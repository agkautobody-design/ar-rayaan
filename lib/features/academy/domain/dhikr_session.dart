/// The Dhikr Session — guided remembrance (Sonic System §4: the
/// signature). Meaning first, breath-paced counting, milestone pauses,
/// silence at the end. Pure state machine — the screen renders it.
library;

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
