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
/// the same minute/day. Rebuilt (emptied) whenever the calendar day changes
/// in the active location's zone, so every alert re-arms for the new day.
class FiredAlertsController extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    ref.watch(prayerDayKeyProvider);
    return <String>{};
  }

  void markFired(String key) => state = <String>{...state, key};
}

final NotifierProvider<FiredAlertsController, Set<String>>
firedAlertsProvider =
    NotifierProvider<FiredAlertsController, Set<String>>(
      FiredAlertsController.new,
    );

/// How long after its time a prayer still counts as "just arrived". The
/// ticker runs every 30 s, but browsers throttle background tabs to about
/// once a minute, so a one-minute window could be missed entirely.
const Duration kAlertWindow = Duration(minutes: 2);

/// The alerted prayer whose time arrived within [kAlertWindow] of [now] and
/// that has not fired yet, or null. Pure; [now] is a real instant.
String? dueAlert({
  required PrayerTimes times,
  required DateTime now,
  required Set<String> enabled,
  required Set<String> fired,
}) {
  if (enabled.isEmpty) return null;
  final DateTime w = times.wallClock(now);
  for (final (String name, DateTime time) in times.prayers) {
    if (!enabled.contains(name)) continue;
    final bool arrived = !time.isAfter(w) && w.difference(time) < kAlertWindow;
    if (!arrived) continue;
    if (fired.contains(alertKey(w, name))) continue;
    return name;
  }
  return null;
}

/// "y-m-d:Prayer" key for a wall-clock day.
String alertKey(DateTime wallClock, String prayer) =>
    '${wallClock.year}-${wallClock.month}-${wallClock.day}:$prayer';

/// The prayer whose alerted time has just arrived, or null. Fires once per
/// prayer per day while the app is open.
final Provider<String?> activeAlertProvider = Provider<String?>((ref) {
  final AsyncValue<PrayerTimes> times = ref.watch(prayerTimesProvider);
  final DateTime now =
      ref.watch(nowTickerProvider).valueOrNull ?? DateTime.now();
  final Set<String> enabled = ref.watch(prayerAlertsProvider);
  final Set<String> fired = ref.watch(firedAlertsProvider);

  final PrayerTimes? t = times.valueOrNull;
  if (t == null) return null;
  // Pure — the screen marks it fired when it reacts.
  return dueAlert(times: t, now: now, enabled: enabled, fired: fired);
});

/// The prayer whose alert banner is on screen. Unlike [activeAlertProvider]
/// (which goes null the moment the alert is marked fired) this stays until
/// the user dismisses it.
class AlertBannerController extends Notifier<String?> {
  @override
  String? build() => null;

  void show(String prayer) => state = prayer;

  void dismiss() => state = null;
}

final NotifierProvider<AlertBannerController, String?> alertBannerProvider =
    NotifierProvider<AlertBannerController, String?>(
      AlertBannerController.new,
    );

/// How long before each alerted prayer an extra "Asr in 15 minutes"
/// notification is delivered (0 = none). Saved on this device.
class NotificationLeadController extends Notifier<int> {
  static const String _key = 'ar.prayer.leadMinutes';

  /// The choices offered.
  static const List<int> options = <int>[0, 5, 10, 15, 30];

  @override
  int build() {
    try {
      final int? v = ref.watch(sharedPreferencesProvider).getInt(_key);
      if (v != null && options.contains(v)) return v;
    } catch (_) {
      // Default: none.
    }
    return 0;
  }

  Future<void> set(int minutes) async {
    if (!options.contains(minutes)) return;
    state = minutes;
    try {
      await ref.read(sharedPreferencesProvider).setInt(_key, minutes);
    } catch (_) {
      // In-memory only.
    }
  }
}

final NotifierProvider<NotificationLeadController, int>
notificationLeadProvider =
    NotifierProvider<NotificationLeadController, int>(
      NotificationLeadController.new,
    );
