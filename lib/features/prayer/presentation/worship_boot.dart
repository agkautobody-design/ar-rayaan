import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/notifications/adhan_notification_bridge.dart';
import '../../../app/core/notifications/web_notifier.dart';
import '../../../app/core/sound/sound_services.dart';
import '../../calendar/application/hijri_settings.dart';
import '../../academy/application/academy_reminder_providers.dart';
import '../../zakat/application/zakat_reminder_providers.dart';
import '../application/prayer_alerts.dart';
import '../application/prayer_notification_plan.dart';
import '../application/prayer_providers.dart';
import '../domain/prayer_times.dart';

/// Keeps the worship services alive for the whole life of the app, whichever
/// screen is open:
///  * applies the saved Hijri calendar choice before any date is shown;
///  * keeps the operating system's prayer notifications and zakat reminders in
///    step with the user's toggles, location, calculation settings and the
///    calendar day (both are no-ops where notifications are unsupported:
///    the web, desktop and tests);
///  * rebuilds the plan every time the app comes back to the foreground, so
///    the rolling window (iOS keeps at most 64 pending notifications) always
///    starts from now, and a changed time zone or date is picked up.
///
/// Sits just above the app widget in `main.dart`; it renders [child] as is.
class WorshipBoot extends ConsumerStatefulWidget {
  const WorshipBoot({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<WorshipBoot> createState() => _WorshipBootState();
}

class _WorshipBootState extends ConsumerState<WorshipBoot>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AdhanNotificationBridge.tapped.addListener(_onNotificationTap);
  }

  /// The person opened the app from a prayer notification: play the full adhan.
  void _onNotificationTap() {
    ref.read(adhanServiceProvider.notifier).playAdhan();
  }

  /// A toggled prayer's time arrived while the app is open, on any screen:
  /// banner state, the adhan, and the browser notification (web).
  void _onAlert(String? prayer) {
    if (prayer == null) return;
    final PrayerTimes? data = ref.read(prayerTimesProvider).valueOrNull;
    if (data == null) return;
    ref
        .read(firedAlertsProvider.notifier)
        .markFired(alertKey(data.wallClock(DateTime.now()), prayer));
    ref.read(alertBannerProvider.notifier).show(prayer);
    ref.read(adhanServiceProvider.notifier).playAdhan();
    WebNotifier.show(
      'It is now $prayer time',
      '$prayer · ${data.locationLabel} — Ar-Rayaan',
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AdhanNotificationBridge.tapped.removeListener(_onNotificationTap);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(prayerNotificationSyncProvider);
      ref.invalidate(zakatReminderSyncProvider);
      ref.invalidate(academyReminderSyncProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(hijriSettingsProvider);
    ref.listen(activeAlertProvider, (_, String? next) => _onAlert(next));
    ref.watch(prayerNotificationSyncProvider);
    ref.watch(zakatReminderSyncProvider);
    ref.watch(academyReminderSyncProvider);
    return widget.child;
  }
}
