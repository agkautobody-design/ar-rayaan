/// What the Hifz planner keeps on this device: the plan (which surah, how
/// many new ayat a day) and the ranges of ayat the learner marks as
/// memorised. Nothing is graded and nothing leaves the device.
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

class HifzState {
  const HifzState({
    this.targetSurah = 18,
    this.dailyNewAyat = 3,
    this.memorised = const <int, List<AyahRange>>{},
  });

  /// The surah being worked on (1-114).
  final int targetSurah;

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

  /// Ayat of the target surah still to do.
  int get remainingInTarget {
    final int left = ayatInSurah(targetSurah) - memorisedIn(targetSurah);
    return left < 0 ? 0 : left;
  }

  HifzState withPlan({int? surah, int? daily}) => HifzState(
        targetSurah: (surah ?? targetSurah).clamp(1, 114),
        dailyNewAyat: (daily ?? dailyNewAyat).clamp(1, 20),
        memorised: memorised,
      );

  /// Mark ayat [from] to [to] of [surah] as memorised. A range outside the
  /// surah, or backwards, is ignored.
  HifzState addRange(int surah, int from, int to) {
    final int max = ayatInSurah(surah);
    if (max == 0 || from < 1 || to < from || to > max) return this;
    final Map<int, List<AyahRange>> next = <int, List<AyahRange>>{
      ...memorised,
      surah: mergeRanges(<AyahRange>[
        ...(memorised[surah] ?? const <AyahRange>[]),
        AyahRange(from, to),
      ]),
    };
    return HifzState(
      targetSurah: targetSurah,
      dailyNewAyat: dailyNewAyat,
      memorised: next,
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
    return HifzState(
      targetSurah: targetSurah,
      dailyNewAyat: dailyNewAyat,
      memorised: next,
    );
  }

  String encode() => jsonEncode(<String, Object>{
        'surah': targetSurah,
        'daily': dailyNewAyat,
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
      HifzState state = const HifzState().withPlan(
        surah: (j['surah'] as num?)?.toInt(),
        daily: (j['daily'] as num?)?.toInt(),
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
      return state;
    } catch (_) {
      return const HifzState();
    }
  }
}
