import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'notification_ids.dart';
import 'prayer_notification_scheduler.dart';

/// Android and iOS implementation of [PrayerNotificationScheduler] on
/// `flutter_local_notifications` 22.3.2.
///
/// Times arrive as absolute UTC instants (the planner already resolved the
/// prayer location's zone), so scheduling uses `TZDateTime.utc` and needs no
/// time-zone database and no device-zone lookup. Every plugin call is wrapped:
/// a failure leaves the in-app alerts working and never throws into the UI.
///
/// What the OS notification does and does not do:
///  * It fires with the app closed, with the phone's default alert sound.
///    The long adhan recording plays only inside the app (an iOS
///    notification sound may not exceed 30 seconds and the bundled recording
///    is 3 minutes 24 seconds).
///  * Android 12+ needs the "Alarms and reminders" permission for exact
///    timing; without it notifications are scheduled inexactly and can be
///    late by minutes. [exactAlarmStatus] / [openExactAlarmSettings] drive
///    the prompt in the Prayer Times screen.
///  * Some phone makers (Xiaomi, Huawei, Oppo and others) kill scheduled
///    alarms of apps that are not exempt from battery optimisation.
class LocalNotificationsScheduler implements PrayerNotificationScheduler {
  LocalNotificationsScheduler([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  static const String _prayerChannel = 'prayer_times';
  static const String _reminderChannel = 'zakat_reminders';
  static const String _academyChannel = 'academy_reminders';

  @override
  bool get supported => Platform.isAndroid || Platform.isIOS;

  Future<bool> _init() async {
    if (_ready) return true;
    if (!supported) return false;
    try {
      await _plugin.initialize(
        settings: InitializationSettings(
          android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            // The permission prompt is shown only when the user turns an
            // alert on, never at launch.
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _ready = true;
    } catch (_) {
      _ready = false;
    }
    return _ready;
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  @override
  Future<bool> requestPermission() async {
    if (!await _init()) return false;
    try {
      if (Platform.isAndroid) {
        return (await _android?.requestNotificationsPermission()) ?? false;
      }
      return (await _ios?.requestPermissions(alert: true, sound: true)) ??
          false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<ExactAlarmStatus> exactAlarmStatus() async {
    if (!await _init()) return ExactAlarmStatus.unknown;
    if (!Platform.isAndroid) return ExactAlarmStatus.notNeeded;
    try {
      final bool? ok = await _android?.canScheduleExactNotifications();
      if (ok == null) return ExactAlarmStatus.unknown;
      return ok ? ExactAlarmStatus.granted : ExactAlarmStatus.denied;
    } catch (_) {
      return ExactAlarmStatus.unknown;
    }
  }

  @override
  Future<void> openExactAlarmSettings() async {
    if (!await _init() || !Platform.isAndroid) return;
    try {
      await _android?.requestExactAlarmsPermission();
    } catch (_) {
      // The settings screen could not be opened; nothing else to do.
    }
  }

  Future<AndroidScheduleMode> _mode() async {
    final ExactAlarmStatus s = await exactAlarmStatus();
    // Exact when allowed (or when the platform has no such permission);
    // otherwise inexact, which Android always accepts.
    return s == ExactAlarmStatus.denied
        ? AndroidScheduleMode.inexactAllowWhileIdle
        : AndroidScheduleMode.exactAllowWhileIdle;
  }

  NotificationDetails _details(String channel) {
    final bool prayer = channel == _prayerChannel;
    final bool academy = channel == _academyChannel;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel,
        prayer
            ? 'Prayer times'
            : (academy ? 'Academy reminders' : 'Zakat reminders'),
        channelDescription: prayer
            ? 'A notification at each prayer time you switched on.'
            : (academy
                ? 'A quiet daily reminder for the Academy lesson or lessons '
                    'to revisit, only if a parent switched it on.'
                : 'Reminders for your zakat year and Zakat al-Fitr.'),
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: false,
      ),
    );
  }

  /// A UTC instant as the time-zone-library value the plugin expects.
  static tz.TZDateTime _zoned(DateTime at) {
    final DateTime u = at.toUtc();
    return tz.TZDateTime.utc(
      u.year,
      u.month,
      u.day,
      u.hour,
      u.minute,
      u.second,
    );
  }

  Future<void> _cancelStale({
    required Set<int> wanted,
    required bool Function(int id) inRange,
  }) async {
    final List<PendingNotificationRequest> pending = await _plugin
        .pendingNotificationRequests();
    final List<int> stale = staleIds(
      pending: pending.map((PendingNotificationRequest r) => r.id),
      wanted: wanted,
      inRange: inRange,
    );
    for (final int id in stale) {
      await _plugin.cancel(id: id);
    }
  }

  @override
  Future<void> replaceAll(List<PlannedPrayerNotification> plan) async {
    if (!await _init()) return;
    try {
      await _cancelStale(
        wanted: <int>{for (final PlannedPrayerNotification p in plan) p.id},
        inRange: isPrayerId,
      );
      final AndroidScheduleMode mode = await _mode();
      final DateTime now = DateTime.now().toUtc();
      for (final PlannedPrayerNotification p in plan) {
        if (!p.at.toUtc().isAfter(now)) continue;
        await _plugin.zonedSchedule(
          id: p.id,
          title: p.title,
          body: p.body,
          scheduledDate: _zoned(p.at),
          notificationDetails: _details(_prayerChannel),
          androidScheduleMode: mode,
        );
      }
    } catch (_) {
      // Leave whatever was scheduled before; the in-app alert still works.
    }
  }

  @override
  Future<void> replaceReminders(List<PlannedReminder> reminders) async {
    if (!await _init()) return;
    try {
      await _cancelStale(
        wanted: <int>{for (final PlannedReminder r in reminders) r.id},
        inRange: isReminderId,
      );
      final AndroidScheduleMode mode = await _mode();
      final DateTime now = DateTime.now().toUtc();
      for (final PlannedReminder r in reminders) {
        if (!r.at.toUtc().isAfter(now)) continue;
        await _plugin.zonedSchedule(
          id: r.id,
          title: r.title,
          body: r.body,
          scheduledDate: _zoned(r.at),
          notificationDetails: _details(_reminderChannel),
          androidScheduleMode: mode,
        );
      }
    } catch (_) {
      // Reminders are best effort.
    }
  }

  @override
  Future<void> replaceAcademyReminders(List<PlannedReminder> reminders) async {
    if (!await _init()) return;
    try {
      await _cancelStale(
        wanted: <int>{for (final PlannedReminder r in reminders) r.id},
        inRange: isAcademyReminderId,
      );
      final AndroidScheduleMode mode = await _mode();
      final DateTime now = DateTime.now().toUtc();
      for (final PlannedReminder r in reminders) {
        if (!r.at.toUtc().isAfter(now)) continue;
        await _plugin.zonedSchedule(
          id: r.id,
          title: r.title,
          body: r.body,
          scheduledDate: _zoned(r.at),
          notificationDetails: _details(_academyChannel),
          androidScheduleMode: mode,
        );
      }
    } catch (_) {
      // Reminders are best effort.
    }
  }
}
