import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
import '../domain/hijri_date.dart';

/// The user's Hijri calendar choice, saved on this device.
///
/// There is exactly one source of truth: [HijriDate.config]. This controller
/// loads it from preferences when first read and keeps it in step with the
/// state, so the calendar, Ramadan, the hawl tracker, fasting markers and
/// the Umm al-Qura Ramadan Isha rule all read the same calendar. Screens
/// that show dates `watch` this provider so they rebuild when it changes.
class HijriSettingsController extends Notifier<HijriConfig> {
  static const String _basisKey = 'ar.hijri.basis';
  static const String _adjustKey = 'ar.hijri.adjust';

  @override
  HijriConfig build() {
    HijriConfig cfg = const HijriConfig();
    try {
      final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
      final String? basis = prefs.getString(_basisKey);
      final int adjust = prefs.getInt(_adjustKey) ?? 0;
      cfg = HijriConfig(
        basis: HijriBasis.values.firstWhere(
          (HijriBasis b) => b.name == basis,
          orElse: () => HijriBasis.ummAlQura,
        ),
      ).copyWith(adjustDays: adjust);
    } catch (_) {
      // Defaults: Umm al-Qura, no shift.
    }
    HijriDate.config = cfg;
    return cfg;
  }

  Future<void> setBasis(HijriBasis basis) async {
    await _apply(state.copyWith(basis: basis));
  }

  Future<void> setAdjustDays(int days) async {
    await _apply(state.copyWith(adjustDays: days));
  }

  Future<void> _apply(HijriConfig next) async {
    HijriDate.config = next;
    state = next;
    try {
      final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(_basisKey, next.basis.name);
      await prefs.setInt(_adjustKey, next.adjustDays);
    } catch (_) {
      // Kept in memory for this session.
    }
  }
}

final NotifierProvider<HijriSettingsController, HijriConfig>
hijriSettingsProvider =
    NotifierProvider<HijriSettingsController, HijriConfig>(
      HijriSettingsController.new,
    );
