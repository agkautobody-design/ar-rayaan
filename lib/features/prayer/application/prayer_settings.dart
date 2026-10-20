import 'package:adhan/adhan.dart' as adhan;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
import '../../calendar/domain/hijri_date.dart';
import 'prayer_repository.dart';

/// One calculation convention the user can pick.
class PrayerMethodOption {
  const PrayerMethodOption(this.key, this.label, this.detail);

  final String key;
  final String label;
  final String detail;
}

/// The conventions offered, in the order shown. `auto` picks the one most
/// mosques use in the user's region.
const List<PrayerMethodOption> kPrayerMethods = <PrayerMethodOption>[
  PrayerMethodOption('auto', 'Automatic', 'The convention most mosques use where you are'),
  PrayerMethodOption('north_america', 'ISNA (North America)', 'Fajr 15° · Isha 15°'),
  PrayerMethodOption('muslim_world_league', 'Muslim World League', 'Fajr 18° · Isha 17°'),
  PrayerMethodOption('umm_al_qura', 'Umm al-Qura (Makkah)', 'Fajr 18.5° · Isha 90 min after Maghrib'),
  PrayerMethodOption('egyptian', 'Egyptian General Authority', 'Fajr 19.5° · Isha 17.5°'),
  PrayerMethodOption('karachi', 'University of Islamic Sciences, Karachi', 'Fajr 18° · Isha 18°'),
  PrayerMethodOption('moon_sighting_committee', 'Moonsighting Committee', 'Seasonal adjustment, common in the UK'),
  PrayerMethodOption('dubai', 'Dubai', 'Fajr 18.2° · Isha 18.2°'),
  PrayerMethodOption('qatar', 'Qatar', 'Fajr 18° · Isha 90 min'),
  PrayerMethodOption('kuwait', 'Kuwait', 'Fajr 18° · Isha 17.5°'),
  PrayerMethodOption('singapore', 'Singapore', 'Fajr 20° · Isha 18°'),
  PrayerMethodOption('turkey', 'Diyanet (Turkey)', 'Fajr 18° · Isha 17°'),
  PrayerMethodOption('tehran', 'Institute of Geophysics, Tehran', 'Fajr 17.7° · Isha 14°'),
];

/// The user's prayer-time choices.
class PrayerSettings {
  const PrayerSettings({this.method = 'auto', this.hanafiAsr = false});

  /// A key from [kPrayerMethods].
  final String method;

  /// Hanafi Asr (shadow twice the object's length) instead of the standard
  /// Shafi'i / Maliki / Hanbali time.
  final bool hanafiAsr;

  PrayerSettings copyWith({String? method, bool? hanafiAsr}) => PrayerSettings(
        method: method ?? this.method,
        hanafiAsr: hanafiAsr ?? this.hanafiAsr,
      );

  /// The concrete method for [location] (resolves `auto`).
  String resolvedMethod(PrayerLocation location) =>
      method == 'auto' ? autoMethodFor(location) : method;

  /// True when Umm al-Qura's Ramadan rule applies on [date]: the method
  /// fixes Isha at 90 minutes after Maghrib, and the adhan package's own
  /// guidance is to add a +30 minute adjustment for Isha during Ramadan
  /// (120 minutes), as the official Saudi timetable does.
  bool ramadanIshaExtra(PrayerLocation location, DateTime? date) {
    if (date == null || resolvedMethod(location) != 'umm_al_qura') {
      return false;
    }
    return HijriDate.fromGregorian(date).month == 9;
  }

  /// The label shown under the times.
  String label(PrayerLocation location, {DateTime? date}) {
    final String key = resolvedMethod(location);
    final String name = kPrayerMethods
        .firstWhere((PrayerMethodOption m) => m.key == key,
            orElse: () => kPrayerMethods[2])
        .label;
    final String asr = hanafiAsr ? 'Hanafi Asr' : 'Standard Asr';
    final String ramadan = ramadanIshaExtra(location, date)
        ? ' · Isha +30 min (Ramadan)'
        : '';
    return '${method == 'auto' ? '$name (auto)' : name} · $asr$ramadan';
  }

  /// adhan parameters for [location]. Pass the civil [date] so date-dependent
  /// rules (Umm al-Qura's Ramadan Isha) can apply.
  adhan.CalculationParameters parameters(
    PrayerLocation location, {
    DateTime? date,
  }) {
    final adhan.CalculationParameters p =
        _methodFor(resolvedMethod(location)).getParameters();
    p.madhab = hanafiAsr ? adhan.Madhab.hanafi : adhan.Madhab.shafi;
    if (ramadanIshaExtra(location, date)) {
      p.adjustments.isha = 30;
    }
    // Far north or south, twilight can last all night in summer; split the
    // night instead of returning no Fajr/Isha.
    if (location.latitude.abs() >= 48) {
      p.highLatitudeRule = adhan.HighLatitudeRule.middle_of_the_night;
    }
    return p;
  }

  static adhan.CalculationMethod _methodFor(String key) => switch (key) {
        'north_america' => adhan.CalculationMethod.north_america,
        'umm_al_qura' => adhan.CalculationMethod.umm_al_qura,
        'egyptian' => adhan.CalculationMethod.egyptian,
        'karachi' => adhan.CalculationMethod.karachi,
        'moon_sighting_committee' => adhan.CalculationMethod.moon_sighting_committee,
        'dubai' => adhan.CalculationMethod.dubai,
        'qatar' => adhan.CalculationMethod.qatar,
        'kuwait' => adhan.CalculationMethod.kuwait,
        'singapore' => adhan.CalculationMethod.singapore,
        'turkey' => adhan.CalculationMethod.turkey,
        'tehran' => adhan.CalculationMethod.tehran,
        _ => adhan.CalculationMethod.muslim_world_league,
      };
}

/// Regional default by coordinates — a coarse map of which convention most
/// mosques follow. The user can always override it.
String autoMethodFor(PrayerLocation l) {
  final double lat = l.latitude;
  final double lng = l.longitude;
  bool box(double s, double n, double w, double e) =>
      lat >= s && lat <= n && lng >= w && lng <= e;

  if (box(14, 72, -170, -50)) return 'north_america'; // US, Canada, Mexico
  if (box(16, 32.5, 34.5, 56)) {
    // Arabian Peninsula: specific Gulf conventions, else Umm al-Qura.
    // Qatar's box lies inside the UAE box, so it must be tested first or
    // Doha would resolve to Dubai.
    if (box(24.4, 26.3, 50.7, 51.7)) return 'qatar';
    if (box(22.5, 26.5, 51, 56.5)) return 'dubai';
    if (box(28.5, 30.2, 46.5, 48.5)) return 'kuwait';
    return 'umm_al_qura';
  }
  if (box(36, 42.5, 26, 45)) return 'turkey';
  if (box(25, 40, 44, 63)) return 'tehran'; // Iran
  if (box(22, 32, 24.5, 37)) return 'egyptian'; // Egypt
  if (box(5, 37.5, 60, 92.5)) return 'karachi'; // Pakistan, India, Bangladesh
  if (box(-11, 7, 95, 141)) return 'singapore'; // Malaysia, Indonesia, Singapore
  if (box(49.5, 61, -11, 2)) return 'moon_sighting_committee'; // UK, Ireland
  return 'muslim_world_league';
}

class PrayerSettingsController extends Notifier<PrayerSettings> {
  static const String _methodKey = 'ar.prayer.method';
  static const String _asrKey = 'ar.prayer.hanafiAsr';

  @override
  PrayerSettings build() {
    try {
      final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
      final String method = prefs.getString(_methodKey) ?? 'auto';
      final bool known =
          kPrayerMethods.any((PrayerMethodOption m) => m.key == method);
      return PrayerSettings(
        method: known ? method : 'auto',
        hanafiAsr: prefs.getBool(_asrKey) ?? false,
      );
    } catch (_) {
      return const PrayerSettings();
    }
  }

  Future<void> setMethod(String method) async {
    state = state.copyWith(method: method);
    try {
      await ref.read(sharedPreferencesProvider).setString(_methodKey, method);
    } catch (_) {}
  }

  Future<void> setHanafiAsr(bool value) async {
    state = state.copyWith(hanafiAsr: value);
    try {
      await ref.read(sharedPreferencesProvider).setBool(_asrKey, value);
    } catch (_) {}
  }
}

final NotifierProvider<PrayerSettingsController, PrayerSettings>
    prayerSettingsProvider =
    NotifierProvider<PrayerSettingsController, PrayerSettings>(
        PrayerSettingsController.new);
