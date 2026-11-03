import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:just_audio/just_audio.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../domain/prayer_times.dart';

/// Schedules local notifications for each prayer time and plays Adhan audio.
///
/// Call [initialize] in main(), then [scheduleForToday] whenever prayer times
/// are calculated (e.g., after location is set or at midnight).
class AdhanNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _initialized = false;

  /// Initialize notification channels and timezone data.
  static Future<void> initialize() async {
    // flutter_local_notifications has no web implementation; calling into it
    // (or Platform.isIOS below) throws and takes the whole app down at boot.
    if (kIsWeb) return;
    if (_initialized) return;
    _initialized = true;

    tz_data.initializeTimeZones();

    // Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'adhan_channel',
      'Adhan Notifications',
      description: 'Plays Adhan at prayer times',
      importance: Importance.high,
      playSound: false, // We play custom Adhan audio
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);

    // Initialize plugin
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Adhan notification tapped: ${response.payload}');
      },
    );

    // Request iOS permissions
    if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// Schedule Adhan notifications for today's prayer times.
  static Future<void> scheduleForToday(PrayerTimes times) async {
    if (kIsWeb) return; // no local notifications on web
    await cancelAll();

    final prayers = <(String, DateTime)>[
      ('Fajr', times.fajr),
      ('Dhuhr', times.dhuhr),
      ('Asr', times.asr),
      ('Maghrib', times.maghrib),
      ('Isha', times.isha),
    ];

    for (final (name, time) in prayers) {
      if (time.isAfter(DateTime.now())) {
        await _schedulePrayer(name, time);
      }
    }
  }

  static Future<void> _schedulePrayer(String name, DateTime time) async {
    final tz.TZDateTime scheduled = tz.TZDateTime.from(time, tz.local);

    await _notifications.zonedSchedule(
      id: name.hashCode,
      title: '$name Adhan',
      body: 'It is time for $name prayer',
      scheduledDate: scheduled,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'adhan_channel',
          'Adhan Notifications',
          channelDescription: 'Plays Adhan at prayer times',
          importance: Importance.high,
          priority: Priority.high,
          playSound: false,
          enableVibration: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: false,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: name,
    );

    debugPrint('Scheduled $name Adhan at $time');
  }

  /// Play Adhan audio. Call this when notification fires.
  static Future<void> playAdhan({bool isFajr = false}) async {
    try {
      // One bundled adhan recording serves both slots until a dedicated
      // Fajr recording (with as-salatu khayrun min an-nawm) is licensed.
      const String asset = 'assets/audio/adhan_mecca.mp3';
      debugPrint('Playing Adhan (Fajr slot: $isFajr) from $asset');
      await _audioPlayer.setAsset(asset);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Failed to play Adhan: $e');
    }
  }

  /// Cancel all scheduled Adhan notifications.
  static Future<void> cancelAll() async {
    if (kIsWeb) return; // no local notifications on web
    await _notifications.cancelAll();
  }

  /// Cancel a specific prayer notification.
  static Future<void> cancelPrayer(String name) async {
    if (kIsWeb) return; // no local notifications on web
    await _notifications.cancel(id: name.hashCode);
  }
}
