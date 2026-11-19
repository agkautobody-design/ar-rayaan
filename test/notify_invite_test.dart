import 'package:ar_rayaan/app/core/notifications/prayer_notification_scheduler.dart';
import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/home/presentation/notify_invite.dart';
import 'package:ar_rayaan/features/prayer/application/prayer_alerts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Scheduler implements PrayerNotificationScheduler {
  _Scheduler({required this.supported, this.grant = true});

  @override
  final bool supported;
  final bool grant;
  int asked = 0;

  @override
  Future<bool> requestPermission() async {
    asked++;
    return grant;
  }

  @override
  Future<ExactAlarmStatus> exactAlarmStatus() async =>
      ExactAlarmStatus.notNeeded;

  @override
  Future<void> openExactAlarmSettings() async {}

  @override
  Future<void> replaceAll(List<PlannedPrayerNotification> plan) async {}

  @override
  Future<void> replaceReminders(List<PlannedReminder> r) async {}

  @override
  Future<void> replaceAcademyReminders(List<PlannedReminder> r) async {}
}

Future<(ProviderContainer, SharedPreferences, _Scheduler)> _boot(
  WidgetTester tester, {
  required bool supported,
  bool grant = true,
  Map<String, Object> prefs = const <String, Object>{},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final SharedPreferences p = await SharedPreferences.getInstance();
  final _Scheduler s = _Scheduler(supported: supported, grant: grant);
  final ProviderContainer c = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(p),
      prayerNotificationSchedulerProvider.overrideWithValue(s),
    ],
  );
  addTearDown(c.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: NotifyInvite())),
      ),
    ),
  );
  await tester.pump();
  return (c, p, s);
}

void main() {
  testWidgets('the invitation shows where notifications can work', (
    WidgetTester tester,
  ) async {
    await _boot(tester, supported: true);
    expect(find.text('Be reminded at each prayer time?'), findsOneWidget);
    expect(find.byKey(const Key('notify-invite-on')), findsOneWidget);
  });

  testWidgets('it is hidden where notifications cannot work', (
    WidgetTester tester,
  ) async {
    await _boot(tester, supported: false);
    expect(find.text('Be reminded at each prayer time?'), findsNothing);
  });

  testWidgets('Turn on switches all five alerts on, asks once, and is remembered', (
    WidgetTester tester,
  ) async {
    final (ProviderContainer c, SharedPreferences p, _Scheduler s) =
        await _boot(tester, supported: true);
    await tester.tap(find.byKey(const Key('notify-invite-on')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(s.asked, 1);
    expect(
      c.read(prayerAlertsProvider),
      <String>{'Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'},
    );
    expect(p.getString(NotifyInvite.prefKey), 'done');
    expect(find.text('Be reminded at each prayer time?'), findsNothing);
    expect(
      find.textContaining('It rings even when the app is closed'),
      findsOneWidget,
    );
  });

  testWidgets('a refusal is said plainly', (WidgetTester tester) async {
    await _boot(tester, supported: true, grant: false);
    await tester.tap(find.byKey(const Key('notify-invite-on')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('blocked for Ar-Rayaan'), findsOneWidget);
  });

  testWidgets('Not now is remembered and nothing is switched on', (
    WidgetTester tester,
  ) async {
    final (ProviderContainer c, SharedPreferences p, _Scheduler s) =
        await _boot(tester, supported: true);
    await tester.tap(find.byKey(const Key('notify-invite-later')));
    await tester.pump();
    expect(s.asked, 0);
    expect(c.read(prayerAlertsProvider), isEmpty);
    expect(p.getString(NotifyInvite.prefKey), 'done');
    expect(find.text('Be reminded at each prayer time?'), findsNothing);
  });

  testWidgets('it does not return once answered, or when an alert is on', (
    WidgetTester tester,
  ) async {
    await _boot(
      tester,
      supported: true,
      prefs: <String, Object>{NotifyInvite.prefKey: 'done'},
    );
    expect(find.text('Be reminded at each prayer time?'), findsNothing);
  });

  testWidgets('it stays out of the way when a prayer alert is already on', (
    WidgetTester tester,
  ) async {
    await _boot(
      tester,
      supported: true,
      prefs: <String, Object>{
        'ar.prayer.alerts': <String>['Fajr'],
      },
    );
    expect(find.text('Be reminded at each prayer time?'), findsNothing);
  });
}
