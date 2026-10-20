import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/providers.dart';

/// Congregation times the user enters by hand from their own mosque.
///
/// Ar-Rayaan does not fetch mosque timetables. Mawaqit (mawaqit.net), the
/// non-profit that publishes mosque-set times, offers no public programming
/// interface that this app has permission to use, and the app does not scrape
/// it; OpenStreetMap carries iqamah data for very few mosques. So the times
/// are typed in once and kept on this device.
class IqamahSettings {
  const IqamahSettings({
    this.minutesAfter = const <String, int>{},
    this.jumuahTime,
    this.mosque = '',
  });

  /// Minutes after the adhan time that the iqamah is held, per prayer
  /// (Fajr, Dhuhr, Asr, Maghrib, Isha). Missing or zero means "not set".
  final Map<String, int> minutesAfter;

  /// The Jumu'ah prayer time as `HH:mm` on the mosque's wall clock, or null.
  final String? jumuahTime;

  /// The mosque the times belong to (free text, optional).
  final String mosque;

  /// Largest gap accepted between adhan and iqamah, in minutes.
  static const int maxMinutes = 90;

  bool get isEmpty =>
      minutesAfter.values.every((int v) => v <= 0) && jumuahTime == null;

  int minutesFor(String prayer) => minutesAfter[prayer] ?? 0;

  IqamahSettings copyWith({
    Map<String, int>? minutesAfter,
    String? jumuahTime,
    bool clearJumuah = false,
    String? mosque,
  }) => IqamahSettings(
    minutesAfter: minutesAfter ?? this.minutesAfter,
    jumuahTime: clearJumuah ? null : (jumuahTime ?? this.jumuahTime),
    mosque: mosque ?? this.mosque,
  );

  /// `HH:mm` parsed into (hour, minute), or null when it is not a valid time.
  static (int, int)? parseTime(String? raw) {
    if (raw == null) return null;
    final List<String> p = raw.trim().split(':');
    if (p.length != 2) return null;
    final int? h = int.tryParse(p[0]);
    final int? m = int.tryParse(p[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return (h, m);
  }

  static String formatTime(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// The iqamah wall-clock time for [prayer], given its adhan time, or null
  /// when none is set.
  DateTime? iqamahFor(String prayer, DateTime adhan) {
    final int m = minutesFor(prayer);
    return m <= 0 ? null : adhan.add(Duration(minutes: m));
  }
}

class IqamahController extends Notifier<IqamahSettings> {
  static const String _key = 'ar.prayer.iqamah.v1';

  static const List<String> prayers = <String>[
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  @override
  IqamahSettings build() {
    try {
      final String? raw = ref.watch(sharedPreferencesProvider).getString(_key);
      if (raw == null) return const IqamahSettings();
      final Object? j = jsonDecode(raw);
      if (j is! Map<String, dynamic>) return const IqamahSettings();
      final Object? mins = j['min'];
      final Map<String, int> minutes = <String, int>{
        if (mins is Map<String, dynamic>)
          for (final MapEntry<String, dynamic> e in mins.entries)
            if (prayers.contains(e.key) && e.value is num)
              e.key: (e.value as num)
                  .toInt()
                  .clamp(0, IqamahSettings.maxMinutes)
                  .toInt(),
      };
      final Object? jt = j['jumuah'];
      return IqamahSettings(
        minutesAfter: minutes,
        jumuahTime: jt is String && IqamahSettings.parseTime(jt) != null
            ? jt
            : null,
        mosque: j['mosque'] is String ? j['mosque'] as String : '',
      );
    } catch (_) {
      return const IqamahSettings();
    }
  }

  Future<void> _save() async {
    try {
      await ref
          .read(sharedPreferencesProvider)
          .setString(
            _key,
            jsonEncode(<String, Object>{
              'min': state.minutesAfter,
              if (state.jumuahTime != null) 'jumuah': state.jumuahTime!,
              'mosque': state.mosque,
            }),
          );
    } catch (_) {
      // In memory only.
    }
  }

  Future<void> setMinutes(String prayer, int minutes) async {
    if (!prayers.contains(prayer)) return;
    final int v = minutes.clamp(0, IqamahSettings.maxMinutes).toInt();
    final Map<String, int> next = <String, int>{...state.minutesAfter};
    if (v == 0) {
      next.remove(prayer);
    } else {
      next[prayer] = v;
    }
    state = state.copyWith(minutesAfter: next);
    await _save();
  }

  /// Sets the Jumu'ah time; null or an invalid string clears it.
  Future<void> setJumuah(String? hhmm) async {
    final bool valid = IqamahSettings.parseTime(hhmm) != null;
    state = valid
        ? state.copyWith(jumuahTime: hhmm!.trim())
        : state.copyWith(clearJumuah: true);
    await _save();
  }

  Future<void> setMosque(String name) async {
    state = state.copyWith(mosque: name.trim());
    await _save();
  }
}

final NotifierProvider<IqamahController, IqamahSettings> iqamahProvider =
    NotifierProvider<IqamahController, IqamahSettings>(IqamahController.new);
