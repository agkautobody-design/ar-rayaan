import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
import '../domain/prayer_times.dart';
import 'prayer_providers.dart';

/// O-11 prayer alerts — per-prayer toggles, persisted. When a toggled
/// prayer's time arrives while the app is open, [activeAlertProvider]
/// surfaces it once (banner + adhan sound + browser notification).
class PrayerAlertController extends Notifier<Set<String>> {
  static const String _key = 'ar.prayer.alerts';

  /// The five prayers (Sunrise is a boundary marker, not a prayer).
  static const List<String> alertable = <String>[
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  @override
  Set<String> build() {
    try {
      final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
      final List<String>? saved = prefs.getStringList(_key);
      if (saved != null) {
        return saved.where(alertable.contains).toSet();
      }
    } catch (_) {
      // In-memory only.
    }
    return <String>{};
  }

  Future<void> _persist() async {
    try {
      final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
      await prefs.setStringList(_key, state.toList());
    } catch (_) {
      // In-memory only.
    }
  }

  Future<void> toggle(String prayer) async {
    if (!alertable.contains(prayer)) return;
    final Set<String> next = <String>{...state};
    next.contains(prayer) ? next.remove(prayer) : next.add(prayer);
    state = next;
    await _persist();
  }

  bool isEnabled(String prayer) => state.contains(prayer);
}

final NotifierProvider<PrayerAlertController, Set<String>>
prayerAlertsProvider =
    NotifierProvider<PrayerAlertController, Set<String>>(
      PrayerAlertController.new,
    );

/// Alert keys already fired ("yyyy-m-d:Fajr") — prevents repeats within
/// the same minute/day, resets naturally with the date.
class FiredAlertsController extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void markFired(String key) => state = <String>{...state, key};
}

final NotifierProvider<FiredAlertsController, Set<String>>
firedAlertsProvider =
    NotifierProvider<FiredAlertsController, Set<String>>(
      FiredAlertsController.new,
    );

/// The prayer whose alerted time has just arrived, or null. Fires once per
/// prayer per day while the app is open.
final Provider<String?> activeAlertProvider = Provider<String?>((ref) {
  final AsyncValue<PrayerTimes> times = ref.watch(prayerTimesProvider);
  final DateTime now =
      ref.watch(nowTickerProvider).valueOrNull ?? DateTime.now();
  final Set<String> enabled = ref.watch(prayerAlertsProvider);
  final Set<String> fired = ref.watch(firedAlertsProvider);

  final PrayerTimes? t = times.valueOrNull;
  if (t == null || enabled.isEmpty) return null;

  for (final (String name, DateTime time) in t.ordered) {
    if (!enabled.contains(name)) continue;
    final bool arrived =
        !time.isAfter(now) && now.difference(time).inMinutes < 1;
    if (!arrived) continue;
    final String key = '${now.year}-${now.month}-${now.day}:$name';
    if (fired.contains(key)) continue;
    return name; // pure — the screen marks it fired when it reacts
  }
  return null;
});
