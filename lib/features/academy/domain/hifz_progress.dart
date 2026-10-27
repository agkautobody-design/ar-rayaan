/// What the Hifz planner keeps on this device: the plan (which surah, how
/// many new ayat a day) and the ranges of ayat the learner marks as
/// memorised. Nothing is graded and nothing leaves the device.
///
/// The planner also keeps a short log of what was written down and when, so
/// that "recent" revision can be the last week and "older" revision can cycle
/// through the rest. Nothing here is a score: no streaks, no points.
///
/// The ranges are the learner's own word. The app does not check that an
/// ayah is really memorised (a teacher or checker does that); it only keeps
/// the list the learner chose to write down.
library;

import 'dart:convert';

import 'hifz_planner.dart';

const String kHifzPref = 'ar.academy.hifz.v1';

/// Ayat [from] to [to] of one surah, both included.
class AyahRange {
  const AyahRange(this.from, this.to);

  final int from;
  final int to;

  int get length => to - from + 1;

  @override
  bool operator ==(Object other) =>
      other is AyahRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => from == to ? '$from' : '$from–$to';
}

/// [ranges] sorted, with overlapping and touching ranges joined.
List<AyahRange> mergeRanges(Iterable<AyahRange> ranges) {
  final List<AyahRange> sorted = ranges.toList()
    ..sort((AyahRange a, AyahRange b) => a.from.compareTo(b.from));
  final List<AyahRange> out = <AyahRange>[];
  for (final AyahRange r in sorted) {
    if (out.isNotEmpty && r.from <= out.last.to + 1) {
      final AyahRange last = out.removeLast();
      out.add(AyahRange(last.from, r.to > last.to ? r.to : last.to));
    } else {
      out.add(r);
    }
  }
  return out;
}

/// Ayat [from] to [to] of [surah]: one piece of a day's work.
class AyahChunk {
  const AyahChunk(this.surah, this.from, this.to);

  final int surah;
  final int from;
  final int to;

  int get length => to - from + 1;

  @override
  bool operator ==(Object other) =>
      other is AyahChunk &&
      other.surah == surah &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(surah, from, to);

  @override
  String toString() => '$surah:$from-$to';
}

/// One line of the log: ayat [from] to [to] of [surah] were written down as
/// memorised on day number [day] (see [hifzDayNumber]).
class HifzLogEntry {
  const HifzLogEntry(this.day, this.surah, this.from, this.to);

  final int day;
  final int surah;
  final int from;
  final int to;
}

/// What to do today, in the three lanes. Worked out from what the learner
/// has written down; nothing is invented.
class HifzDay {
  const HifzDay({
    required this.fresh,
    required this.recent,
    required this.older,
  });

  /// The new ayat for today (sabaq); null when the plan has nothing left.
  final AyahChunk? fresh;

  /// What was written down in the last [kRecentDays] days (sabqi).
  final List<AyahChunk> recent;

  /// One older section for today (manzil); null while everything written
  /// down is still recent.
  final AyahChunk? older;
}

/// Days counted as recent revision (sabqi).
const int kRecentDays = 7;

/// Longest older section revised in one day, in ayat.
const int kOlderSectionAyat = 20;

/// Whole days since 1970-01-01 for the calendar date of [d] (local date
/// read as UTC, so the number changes at local midnight).
int hifzDayNumber(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ 86400000;

class HifzState {
  const HifzState({
    this.targetSurah = kJuzAmmaLastSurah,
    this.dailyNewAyat = 3,
    this.memorised = const <int, List<AyahRange>>{},
    this.juzAmma = true,
    this.log = const <HifzLogEntry>[],
  });

  /// The surah being worked on (1-114) when the plan is one surah.
  final int targetSurah;

  /// True when the plan is all of Juz Amma (surahs 78 to 114), learned from
  /// An-Nas back to An-Naba: the short surahs most people already pray first.
  final bool juzAmma;

  /// What was written down and when (newest last).
  final List<HifzLogEntry> log;

  /// New ayat per day (1-20).
  final int dailyNewAyat;

  /// Memorised ranges by surah number, each list sorted and merged.
  final Map<int, List<AyahRange>> memorised;

  /// Ayat marked memorised in [surah].
  int memorisedIn(int surah) => (memorised[surah] ?? const <AyahRange>[])
      .fold<int>(0, (int a, AyahRange r) => a + r.length);

  /// Ayat marked memorised in all surahs.
  int get totalMemorised =>
      memorised.keys.fold<int>(0, (int a, int s) => a + memorisedIn(s));

  /// Ayat of Juz Amma written down as memorised.
  int get juzAmmaMemorised {
    int n = 0;
    for (int s = kJuzAmmaFirstSurah; s <= kJuzAmmaLastSurah; s++) {
      n += memorisedIn(s);
    }
    return n;
  }

  /// The first surah of Juz Amma, from An-Nas backwards, that is not fully
  /// written down; null when all of Juz Amma is.
  int? get juzAmmaNextSurah {
    for (int s = kJuzAmmaLastSurah; s >= kJuzAmmaFirstSurah; s--) {
      if (memorisedIn(s) < ayatInSurah(s)) return s;
    }
    return null;
  }

  /// The surah the new-ayat lane is working on: the next unfinished surah
  /// of Juz Amma for that plan, otherwise [targetSurah].
  int get workingSurah => juzAmma
      ? (juzAmmaNextSurah ?? kJuzAmmaFirstSurah)
      : targetSurah;

  /// Ayat still to do: in the working surah, or in all of Juz Amma for
  /// that plan.
  int get remainingInTarget {
    if (juzAmma) {
      final int left = juzAmmaAyat() - juzAmmaMemorised;
      return left < 0 ? 0 : left;
    }
    final int left = ayatInSurah(targetSurah) - memorisedIn(targetSurah);
    return left < 0 ? 0 : left;
  }

  bool _isMemorised(int surah, int ayah) {
    for (final AyahRange r in memorised[surah] ?? const <AyahRange>[]) {
      if (ayah >= r.from && ayah <= r.to) return true;
    }
    return false;
  }

  /// The first ayah of [surah] not written down, or 0 when all are.
  int firstUnmemorised(int surah) {
    final int max = ayatInSurah(surah);
    for (int a = 1; a <= max; a++) {
      if (!_isMemorised(surah, a)) return a;
    }
    return 0;
  }

  HifzState _with({
    int? targetSurah,
    int? dailyNewAyat,
    Map<int, List<AyahRange>>? memorised,
    bool? juzAmma,
    List<HifzLogEntry>? log,
  }) =>
      HifzState(
        targetSurah: targetSurah ?? this.targetSurah,
        dailyNewAyat: dailyNewAyat ?? this.dailyNewAyat,
        memorised: memorised ?? this.memorised,
        juzAmma: juzAmma ?? this.juzAmma,
        log: log ?? this.log,
      );

  /// Change the plan. Choosing a [surah] without saying otherwise switches to
  /// the one-surah plan.
  HifzState withPlan({int? surah, int? daily, bool? juzAmma}) => _with(
        targetSurah: (surah ?? targetSurah).clamp(1, 114),
        dailyNewAyat: (daily ?? dailyNewAyat).clamp(1, 20),
        juzAmma: juzAmma ?? (surah != null ? false : this.juzAmma),
      );

  /// Mark ayat [from] to [to] of [surah] as memorised. A range outside the
  /// surah, or backwards, is ignored. Pass [day] (see [hifzDayNumber]) to
  /// remember when, for the recent-revision lane.
  HifzState addRange(int surah, int from, int to, {int? day}) {
    final int max = ayatInSurah(surah);
    if (max == 0 || from < 1 || to < from || to > max) return this;
    final Map<int, List<AyahRange>> next = <int, List<AyahRange>>{
      ...memorised,
      surah: mergeRanges(<AyahRange>[
        ...(memorised[surah] ?? const <AyahRange>[]),
        AyahRange(from, to),
      ]),
    };
    List<HifzLogEntry> nextLog = log;
    if (day != null) {
      nextLog = <HifzLogEntry>[
        ...log.where((HifzLogEntry e) => day - e.day < 30),
        HifzLogEntry(day, surah, from, to),
      ];
      if (nextLog.length > 100) {
        nextLog = nextLog.sublist(nextLog.length - 100);
      }
    }
    return _with(memorised: next, log: nextLog);
  }

  /// Group [keys] (surah * 1000 + ayah, any order) into runs of neighbouring
  /// ayat of one surah, each at most [maxLen] long.
  static List<AyahChunk> _chunks(Iterable<int> keys, int maxLen) {
    final List<int> sorted = keys.toList()..sort();
    final List<AyahChunk> out = <AyahChunk>[];
    int? s;
    int from = 0;
    int to = 0;
    for (final int k in sorted) {
      final int surah = k ~/ 1000;
      final int ayah = k % 1000;
      if (s == surah && ayah == to + 1 && ayah - from + 1 <= maxLen) {
        to = ayah;
        continue;
      }
      if (s != null) out.add(AyahChunk(s, from, to));
      s = surah;
      from = ayah;
      to = ayah;
    }
    if (s != null) out.add(AyahChunk(s, from, to));
    return out;
  }

  /// Today's three lanes, worked out from what has been written down.
  /// Deterministic: the same state and the same date give the same day.
  HifzDay dayFor(DateTime now) {
    final int today = hifzDayNumber(now);

    // New: the next [dailyNewAyat] ayat after what is written down.
    AyahChunk? fresh;
    final int surah = workingSurah;
    final int first = firstUnmemorised(surah);
    if (first != 0) {
      final int max = ayatInSurah(surah);
      final int to = first + dailyNewAyat - 1;
      fresh = AyahChunk(surah, first, to > max ? max : to);
    }

    // Recent: ayat written down in the last week that are still on the list.
    final Set<int> recentKeys = <int>{};
    for (final HifzLogEntry e in log) {
      if (today - e.day >= kRecentDays) continue;
      for (int a = e.from; a <= e.to; a++) {
        if (_isMemorised(e.surah, a)) recentKeys.add(e.surah * 1000 + a);
      }
    }

    // Older: everything else, in sections; one section a day, in turn.
    final Set<int> olderKeys = <int>{};
    for (final MapEntry<int, List<AyahRange>> e in memorised.entries) {
      for (final AyahRange r in e.value) {
        for (int a = r.from; a <= r.to; a++) {
          final int key = e.key * 1000 + a;
          if (!recentKeys.contains(key)) olderKeys.add(key);
        }
      }
    }
    final List<AyahChunk> sections = _chunks(olderKeys, kOlderSectionAyat);
    final AyahChunk? older =
        sections.isEmpty ? null : sections[today % sections.length];

    return HifzDay(
      fresh: fresh,
      recent: _chunks(recentKeys, 30),
      older: older,
    );
  }

  /// Un-mark the [index]th range of [surah].
  HifzState removeRange(int surah, int index) {
    final List<AyahRange> list = <AyahRange>[
      ...(memorised[surah] ?? const <AyahRange>[]),
    ];
    if (index < 0 || index >= list.length) return this;
    list.removeAt(index);
    final Map<int, List<AyahRange>> next = <int, List<AyahRange>>{
      ...memorised,
    };
    if (list.isEmpty) {
      next.remove(surah);
    } else {
      next[surah] = list;
    }
    return _with(memorised: next);
  }

  String encode() => jsonEncode(<String, Object>{
        'surah': targetSurah,
        'daily': dailyNewAyat,
        'juz': juzAmma,
        'log': <List<int>>[
          for (final HifzLogEntry e in log)
            <int>[e.day, e.surah, e.from, e.to],
        ],
        'memorised': <String, Object>{
          for (final MapEntry<int, List<AyahRange>> e in memorised.entries)
            '${e.key}': <List<int>>[
              for (final AyahRange r in e.value) <int>[r.from, r.to],
            ],
        },
      });

  /// The state stored in [raw]; the defaults when there is none or it cannot
  /// be read. Ranges that do not fit their surah are dropped.
  static HifzState decode(String? raw) {
    if (raw == null || raw.isEmpty) return const HifzState();
    try {
      final Object? j = jsonDecode(raw);
      if (j is! Map<String, dynamic>) return const HifzState();
      // A plan saved before Juz Amma existed has no "juz" and stays a
      // one-surah plan.
      HifzState state = const HifzState().withPlan(
        surah: (j['surah'] as num?)?.toInt(),
        daily: (j['daily'] as num?)?.toInt(),
        juzAmma: j['juz'] == true,
      );
      final Object? mem = j['memorised'];
      if (mem is Map<String, dynamic>) {
        for (final MapEntry<String, dynamic> e in mem.entries) {
          final int? surah = int.tryParse(e.key);
          final Object? list = e.value;
          if (surah == null || list is! List<dynamic>) continue;
          for (final dynamic pair in list) {
            if (pair is List<dynamic> &&
                pair.length == 2 &&
                pair[0] is num &&
                pair[1] is num) {
              state = state.addRange(
                  surah, (pair[0] as num).toInt(), (pair[1] as num).toInt());
            }
          }
        }
      }
      final Object? rawLog = j['log'];
      if (rawLog is List<dynamic>) {
        final List<HifzLogEntry> entries = <HifzLogEntry>[];
        for (final dynamic row in rawLog) {
          if (row is! List<dynamic> || row.length != 4) continue;
          if (row.any((dynamic v) => v is! num)) continue;
          final int day = (row[0] as num).toInt();
          final int surah = (row[1] as num).toInt();
          final int from = (row[2] as num).toInt();
          final int to = (row[3] as num).toInt();
          final int max = ayatInSurah(surah);
          if (max == 0 || from < 1 || to < from || to > max) continue;
          entries.add(HifzLogEntry(day, surah, from, to));
        }
        state = state._with(
          log: entries.length > 100
              ? entries.sublist(entries.length - 100)
              : entries,
        );
      }
      return state;
    } catch (_) {
      return const HifzState();
    }
  }
}
