import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/notifications/prayer_notification_scheduler.dart';
import '../../../app/core/providers.dart';
import '../../calendar/application/hijri_settings.dart';
import '../../prayer/application/prayer_providers.dart';
import '../domain/zakat_reminders.dart';
import 'hawl_provider.dart';

/// Which zakat reminders the user switched on. Both start off: nothing is
/// scheduled until they choose, and turning one on asks for notification
/// permission at that moment.
class ZakatReminderSettings {
  const ZakatReminderSettings({this.hawl = false, this.fitr = false});

  final bool hawl;
  final bool fitr;

  ZakatReminderSettings copyWith({bool? hawl, bool? fitr}) =>
      ZakatReminderSettings(hawl: hawl ?? this.hawl, fitr: fitr ?? this.fitr);
}

class ZakatReminderController extends Notifier<ZakatReminderSettings> {
  static const String _hawlKey = 'ar.zakat.remind.hawl';
  static const String _fitrKey = 'ar.zakat.remind.fitr';

  @override
  ZakatReminderSettings build() {
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      return ZakatReminderSettings(
        hawl: prefs.getBool(_hawlKey) ?? false,
        fitr: prefs.getBool(_fitrKey) ?? false,
      );
    } catch (_) {
      return const ZakatReminderSettings();
    }
  }

  /// Returns false when the user turned a reminder on but the phone refused
  /// notifications (the switch stays on; the reminder simply cannot show).
  Future<bool> setHawl(bool on) async {
    state = state.copyWith(hawl: on);
    try {
      await ref.read(sharedPreferencesProvider).setBool(_hawlKey, on);
    } catch (_) {}
    return on ? _permission() : true;
  }

  Future<bool> setFitr(bool on) async {
    state = state.copyWith(fitr: on);
    try {
      await ref.read(sharedPreferencesProvider).setBool(_fitrKey, on);
    } catch (_) {}
    return on ? _permission() : true;
  }

  Future<bool> _permission() async {
    final PrayerNotificationScheduler s = ref.read(
      prayerNotificationSchedulerProvider,
    );
    if (!s.supported) return false;
    return s.requestPermission();
  }
}

final NotifierProvider<ZakatReminderController, ZakatReminderSettings>
zakatReminderProvider =
    NotifierProvider<ZakatReminderController, ZakatReminderSettings>(
      ZakatReminderController.new,
    );

/// Keeps the OS reminders equal to the plan. A no-op where notifications
/// are unsupported; kept alive by the app shell like the prayer plan.
final Provider<void> zakatReminderSyncProvider = Provider<void>((ref) {
  final PrayerNotificationScheduler scheduler = ref.watch(
    prayerNotificationSchedulerProvider,
  );
  if (!scheduler.supported) return;
  final ZakatReminderSettings settings = ref.watch(zakatReminderProvider);
  final DateTime? start = ref.watch(hawlStartProvider);
  // The dates come from the Hijri calendar the user chose, and roll with
  // the day.
  ref.watch(hijriSettingsProvider);
  ref.watch(prayerDayKeyProvider);
  unawaited(
    scheduler.replaceReminders(
      planZakatReminders(
        now: DateTime.now(),
        hawlOn: settings.hawl,
        fitrOn: settings.fitr,
        hawlStart: start,
      ),
    ),
  );
});
