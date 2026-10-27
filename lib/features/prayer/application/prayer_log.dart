import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/providers.dart';
import '../../habits/application/habits_providers.dart';

/// How one of the five prayers went on one day.
enum PrayerMark {
  /// Prayed within its time.
  prayed('On time'),

  /// Prayed, but after its time had passed.
  prayedLate('Late'),

  /// Not prayed; added once to the make-up (qada) list on the Gentle Ledger.
  missed('Not prayed — add to my make-up list'),

  /// Not required or not possible that day (for example menstruation,
  /// postnatal bleeding or illness). Never counted, never added to the
  /// make-up list, never shown as a number: the app does not rule on who is
  /// excused, it only refuses to count it against anyone.
  excused('Excused');

  const PrayerMark(this.label);

  final String label;
}

/// The five-prayer log: a quiet record of what the user chose to write down,
/// on this device only. My log adds up the prayers marked prayed, as plain
/// totals for a week, a month or all time; an empty day is just empty. The
/// only other thing a mark does elsewhere is a "not prayed" mark adding one
/// prayer to the make-up list (and removing it again if the mark is changed
/// or cleared).
class PrayerLogState {
  const PrayerLogState({
    this.days = const <String, Map<String, PrayerMark>>{},
    this.qadaAdded = const <String>{},
  });

  /// `yyyy-mm-dd` -> prayer name -> mark.
  final Map<String, Map<String, PrayerMark>> days;

  /// `yyyy-mm-dd:Prayer` keys of missed marks that already added one to the
  /// make-up list.
  final Set<String> qadaAdded;

  PrayerMark? markFor(String day, String prayer) => days[day]?[prayer];
}

class PrayerLogController extends Notifier<PrayerLogState> {
  static const String _key = 'ar.prayer.log.v1';

  /// Marks older than this many days are dropped on the next save.
  static const int keepDays = 3650;

  static const List<String> prayers = QadaController.prayers;

  /// Zero-padded `yyyy-mm-dd` for a civil day.
  static String dayKey(DateTime d) => FastingLogController.stamp(d);

  @override
  PrayerLogState build() {
    try {
      final String? raw = ref.watch(sharedPreferencesProvider).getString(_key);
      if (raw == null) return const PrayerLogState();
      final Object? j = jsonDecode(raw);
      if (j is! Map<String, dynamic>) return const PrayerLogState();
      final Map<String, Map<String, PrayerMark>> days =
          <String, Map<String, PrayerMark>>{};
      final Object? d = j['days'];
      if (d is Map<String, dynamic>) {
        for (final MapEntry<String, dynamic> e in d.entries) {
          final Object? row = e.value;
          if (row is! Map<String, dynamic>) continue;
          final Map<String, PrayerMark> marks = <String, PrayerMark>{};
          for (final MapEntry<String, dynamic> m in row.entries) {
            if (!prayers.contains(m.key)) continue;
            for (final PrayerMark pm in PrayerMark.values) {
              if (pm.name == m.value) marks[m.key] = pm;
            }
          }
          if (marks.isNotEmpty) days[e.key] = marks;
        }
      }
      final Object? q = j['qada'];
      final Set<String> qada = <String>{
        if (q is List<dynamic>)
          for (final dynamic k in q)
            if (k is String) k,
      };
      return PrayerLogState(days: days, qadaAdded: qada);
    } catch (_) {
      return const PrayerLogState();
    }
  }

  Future<void> _save() async {
    try {
      // Drop marks older than the window (their qada flags go with them).
      final DateTime now = DateTime.now();
      final String cutoff = dayKey(
        DateTime(now.year, now.month, now.day - keepDays),
      );
      final Map<String, Map<String, PrayerMark>> kept =
          <String, Map<String, PrayerMark>>{
            for (final MapEntry<String, Map<String, PrayerMark>> e
                in state.days.entries)
              if (e.key.compareTo(cutoff) >= 0) e.key: e.value,
          };
      final Set<String> keptQada = <String>{
        for (final String k in state.qadaAdded)
          if (k.split(':').first.compareTo(cutoff) >= 0) k,
      };
      state = PrayerLogState(days: kept, qadaAdded: keptQada);
      await ref
          .read(sharedPreferencesProvider)
          .setString(
            _key,
            jsonEncode(<String, Object>{
              'days': <String, Object>{
                for (final MapEntry<String, Map<String, PrayerMark>> e
                    in kept.entries)
                  e.key: <String, String>{
                    for (final MapEntry<String, PrayerMark> m in e.value.entries)
                      m.key: m.value.name,
                  },
              },
              'qada': keptQada.toList(),
            }),
          );
    } catch (_) {
      // Kept in memory for this session.
    }
  }

  /// Sets [prayer]'s mark for [day]; choosing the mark it already has clears
  /// it. A first "missed" adds one to the make-up list; changing or clearing
  /// it takes that one off again.
  Future<void> mark(String day, String prayer, PrayerMark mark) async {
    if (!prayers.contains(prayer)) return;
    final PrayerMark? before = state.markFor(day, prayer);
    final PrayerMark? after = before == mark ? null : mark;
    final String flag = '$day:$prayer';
    final bool hadFlag = state.qadaAdded.contains(flag);

    final Map<String, PrayerMark> row = <String, PrayerMark>{
      ...?state.days[day],
    };
    if (after == null) {
      row.remove(prayer);
    } else {
      row[prayer] = after;
    }
    final Map<String, Map<String, PrayerMark>> days =
        <String, Map<String, PrayerMark>>{...state.days};
    if (row.isEmpty) {
      days.remove(day);
    } else {
      days[day] = row;
    }

    final Set<String> flags = <String>{...state.qadaAdded};
    final QadaController qada = ref.read(qadaProvider.notifier);
    if (after == PrayerMark.missed && !hadFlag) {
      flags.add(flag);
      await qada.adjust(prayer, 1);
    } else if (after != PrayerMark.missed && hadFlag) {
      flags.remove(flag);
      await qada.adjust(prayer, -1);
    }
    state = PrayerLogState(days: days, qadaAdded: flags);
    await _save();
  }
}

final NotifierProvider<PrayerLogController, PrayerLogState> prayerLogProvider =
    NotifierProvider<PrayerLogController, PrayerLogState>(
      PrayerLogController.new,
    );
