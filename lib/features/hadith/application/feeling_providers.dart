import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
import '../domain/daily_hadith.dart';

/// Feeling Check-in state — the feeling the user checked in with today,
/// plus the daily hadiths they have saved. On-device only (SharedPreferences);
/// mood data never leaves the device, per the privacy constitution.
class FeelingCheckInController extends Notifier<String?> {
  static const String _keyPrefix = 'ar.feeling';

  static String _todayKey() {
    final DateTime d = DateTime.now();
    return '$_keyPrefix.${d.year}-${d.month}-${d.day}';
  }

  @override
  String? build() {
    try {
      final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
      return prefs.getString(_todayKey());
    } catch (_) {
      return null; // prefs not initialized (tests) — stateless fallback
    }
  }

  Future<void> checkIn(String feelingId) async {
    state = feelingId;
    try {
      final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(_todayKey(), feelingId);
    } catch (_) {
      // On-device only; persistence is best-effort in tests.
    }
  }
}

final NotifierProvider<FeelingCheckInController, String?>
feelingCheckInProvider =
    NotifierProvider<FeelingCheckInController, String?>(
      FeelingCheckInController.new,
    );

/// Saved daily hadiths (the bookmark in the locked Hadith design).
class SavedDailyHadithsController extends Notifier<Set<String>> {
  static const String _key = 'ar.daily_hadith.saved';

  @override
  Set<String> build() {
    try {
      final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
      return (prefs.getStringList(_key) ?? <String>[]).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> toggle(String hadithText) async {
    final Set<String> next = <String>{...state};
    if (!next.remove(hadithText)) next.add(hadithText);
    state = next;
    try {
      final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
      await prefs.setStringList(_key, next.toList());
    } catch (_) {}
  }
}

final NotifierProvider<SavedDailyHadithsController, Set<String>>
savedDailyHadithsProvider =
    NotifierProvider<SavedDailyHadithsController, Set<String>>(
      SavedDailyHadithsController.new,
    );

/// Today's daily hadith (pure, day-seeded).
final Provider<DailyHadith> todaysHadithProvider = Provider<DailyHadith>(
  (ref) => DailyHadiths.forDate(DateTime.now()),
);
