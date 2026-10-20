import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';

/// "Days you returned" — Sakina's counter. Not a streak (a streak shames
/// when it breaks); a count of every day the user came back, which only
/// ever grows. On-device only.
class DaysReturnedController extends Notifier<int> {
  static const String _key = 'ar.sakina.days_returned';

  static String _dayStamp(DateTime d) => '${d.year}-${d.month}-${d.day}';

  @override
  int build() {
    try {
      final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
      final List<String> days = prefs.getStringList(_key) ?? <String>[];
      return _recordToday(days, prefs);
    } catch (_) {
      return 1;
    }
  }

  int _recordToday(List<String> days, SharedPreferences prefs) {
    final String today = _dayStamp(DateTime.now());
    if (!days.contains(today)) {
      final List<String> next = <String>[...days, today];
      prefs.setStringList(_key, next);
      return next.length;
    }
    return days.length;
  }
}

final NotifierProvider<DaysReturnedController, int> daysReturnedProvider =
    NotifierProvider<DaysReturnedController, int>(DaysReturnedController.new);

/// The country (ISO 3166-1 alpha-2, upper case) of the device's locale, used
/// only to put the right help lines first. Null when the locale carries no
/// country. Never sent anywhere.
final Provider<String?> deviceCountryProvider = Provider<String?>(
  (_) => ui.PlatformDispatcher.instance.locale.countryCode,
);
