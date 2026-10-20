import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';

/// The day the user's wealth first reached nisab (the start of their hawl),
/// saved on this device. One provider so the Hawl card and the reminder
/// planner always see the same date.
class HawlStartController extends Notifier<DateTime?> {
  static const String _key = 'ar.zakat.hawl.start';

  /// 'yyyy-mm-dd', zero padded.
  static String stamp(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  DateTime? build() {
    try {
      final String? raw = ref.watch(sharedPreferencesProvider).getString(_key);
      if (raw == null) return null;
      final DateTime? parsed = DateTime.tryParse(raw);
      if (parsed == null) return null;
      return DateTime(parsed.year, parsed.month, parsed.day);
    } catch (_) {
      return null;
    }
  }

  Future<void> set(DateTime day) async {
    final DateTime d = DateTime(day.year, day.month, day.day);
    state = d;
    try {
      final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(_key, stamp(d));
    } catch (_) {
      // In memory only.
    }
  }

  Future<void> clear() async {
    state = null;
    try {
      await ref.read(sharedPreferencesProvider).remove(_key);
    } catch (_) {
      // In memory only.
    }
  }
}

final NotifierProvider<HawlStartController, DateTime?> hawlStartProvider =
    NotifierProvider<HawlStartController, DateTime?>(HawlStartController.new);
