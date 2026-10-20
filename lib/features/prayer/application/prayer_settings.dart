import 'dart:convert';

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
  // The presets below are not in the `adhan` package; each is built from
  // the angles the AlAdhan prayer-times API publishes for that authority
  // (api.aladhan.com/v1/methods, read 20 Oct 2026).
  PrayerMethodOption('jafari', 'Shia Ithna-Ashari (Leva Institute, Qum)', 'Fajr 16° · Maghrib 4° · Isha 14°'),
  PrayerMethodOption('morocco', 'Morocco', 'Fajr 19° · Isha 17°'),
  PrayerMethodOption('algeria', 'Algeria', 'Fajr 18° · Isha 17°'),
  PrayerMethodOption('tunisia', 'Tunisia', 'Fajr 18° · Isha 18°'),
  PrayerMethodOption('france_uoif', 'Union des organisations islamiques de France', 'Fajr 12° · Isha 12°'),
  PrayerMethodOption('russia', 'Spiritual Administration of Muslims of Russia', 'Fajr 16° · Isha 15°'),
  PrayerMethodOption('jakim', 'JAKIM (Malaysia)', 'Fajr 20° · Isha 18°'),
  PrayerMethodOption('kemenag', 'Kemenag (Indonesia)', 'Fajr 20° · Isha 18°'),
];

/// One way to treat twilight when the sun never sinks far enough below the
/// horizon (summer at high latitudes). `auto` follows the `adhan` library's
/// recommendation.
class HighLatitudeOption {
  const HighLatitudeOption(this.key, this.label, this.detail);

  final String key;
  final String label;
  final String detail;
}

const List<HighLatitudeOption> kHighLatitudeRules = <HighLatitudeOption>[
  HighLatitudeOption(
    'auto',
    'Automatic',
    'Middle of the night up to 48°; seventh of the night beyond it '
        '(the adhan library\u2019s recommendation)',
  ),
  HighLatitudeOption(
    'middle_of_the_night',
    'Middle of the night',
    'Fajr is never earlier, and Isha never later, than the middle of the night',
  ),
  HighLatitudeOption(
    'seventh_of_the_night',
    'Seventh of the night',
    'Fajr no earlier than the last seventh, Isha no later than the first '
        'seventh of the night',
  ),
  HighLatitudeOption(
    'twilight_angle',
    'Twilight angle',
    'Like seventh of the night, but the fraction is the method\u2019s angle '
        'divided by 60',
  ),
];

/// The times a minute offset can be applied to.
const List<String> kOffsetPrayers = <String>[
  'Fajr',
  'Sunrise',
  'Dhuhr',
  'Asr',
  'Maghrib',
  'Isha',
];

/// Largest manual offset either way, in minutes.
const int kMaxOffsetMinutes = 30;

/// The user's prayer-time choices.
class PrayerSettings {
  const PrayerSettings({
    this.method = 'auto',
    this.hanafiAsr = false,
    this.highLatitude = 'auto',
    this.offsets = const <String, int>{},
  });

  /// A key from [kPrayerMethods].
  final String method;

  /// Hanafi Asr (shadow twice the object's length) instead of the standard
  /// Shafi'i / Maliki / Hanbali time.
  final bool hanafiAsr;

  /// A key from [kHighLatitudeRules].
  final String highLatitude;

  /// Manual minute offsets per time ([kOffsetPrayers]), each within
  /// +/- [kMaxOffsetMinutes]. Missing means zero. A mosque timetable that
  /// differs by a few minutes is the usual reason to set one.
  final Map<String, int> offsets;

  PrayerSettings copyWith({
    String? method,
    bool? hanafiAsr,
    String? highLatitude,
    Map<String, int>? offsets,
  }) => PrayerSettings(
    method: method ?? this.method,
    hanafiAsr: hanafiAsr ?? this.hanafiAsr,
    highLatitude: highLatitude ?? this.highLatitude,
    offsets: offsets ?? this.offsets,
  );

  /// Offset in minutes for [prayer] (zero when unset).
  int offsetFor(String prayer) => offsets[prayer] ?? 0;

  /// True when any offset is non-zero.
  bool get hasOffsets => offsets.values.any((int v) => v != 0);

  /// [raw] offsets with unknown names dropped, zeros removed and every value
  /// clamped to +/- [kMaxOffsetMinutes].
  static Map<String, int> cleanOffsets(Map<String, int> raw) => <String, int>{
    for (final MapEntry<String, int> e in raw.entries)
      if (kOffsetPrayers.contains(e.key) && e.value != 0)
        e.key: e.value.clamp(-kMaxOffsetMinutes, kMaxOffsetMinutes).toInt(),
  };

  /// The high-latitude rule that applies at [location].
  adhan.HighLatitudeRule highLatitudeRuleFor(PrayerLocation location) =>
      switch (highLatitude) {
        'middle_of_the_night' => adhan.HighLatitudeRule.middle_of_the_night,
        'seventh_of_the_night' => adhan.HighLatitudeRule.seventh_of_the_night,
        'twilight_angle' => adhan.HighLatitudeRule.twilight_angle,
        _ =>
          location.latitude.abs() > 48
              ? adhan.HighLatitudeRule.seventh_of_the_night
              : adhan.HighLatitudeRule.middle_of_the_night,
      };

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
    final String offs = hasOffsets ? ' · your minute offsets' : '';
    final String lat = highLatitude == 'auto'
        ? ''
        : ' · ${kHighLatitudeRules.firstWhere((HighLatitudeOption r) => r.key == highLatitude, orElse: () => kHighLatitudeRules.first).label.toLowerCase()} rule';
    return '${method == 'auto' ? '$name (auto)' : name} · $asr$ramadan$offs$lat';
  }

  /// adhan parameters for [location]. Pass the civil [date] so date-dependent
  /// rules (Umm al-Qura's Ramadan Isha) can apply.
  adhan.CalculationParameters parameters(
    PrayerLocation location, {
    DateTime? date,
  }) {
    final adhan.CalculationParameters p = _baseParameters(
      resolvedMethod(location),
    );
    p.madhab = hanafiAsr ? adhan.Madhab.hanafi : adhan.Madhab.shafi;
    p.adjustments.fajr = offsetFor('Fajr');
    p.adjustments.sunrise = offsetFor('Sunrise');
    p.adjustments.dhuhr = offsetFor('Dhuhr');
    p.adjustments.asr = offsetFor('Asr');
    p.adjustments.maghrib = offsetFor('Maghrib');
    p.adjustments.isha =
        offsetFor('Isha') + (ramadanIshaExtra(location, date) ? 30 : 0);
    // Far north or south, twilight can last all night in summer; the rule
    // decides how the night is split instead of returning no Fajr/Isha.
    p.highLatitudeRule = highLatitudeRuleFor(location);
    return p;
  }

  static adhan.CalculationParameters _baseParameters(String key) =>
      switch (key) {
        // Angle-only presets from the AlAdhan methods list.
        'jafari' => adhan.CalculationParameters(
          fajrAngle: 16,
          maghribAngle: 4,
          ishaAngle: 14,
        ),
        'morocco' => adhan.CalculationParameters(fajrAngle: 19, ishaAngle: 17),
        'algeria' => adhan.CalculationParameters(fajrAngle: 18, ishaAngle: 17),
        'tunisia' => adhan.CalculationParameters(fajrAngle: 18, ishaAngle: 18),
        'france_uoif' => adhan.CalculationParameters(
          fajrAngle: 12,
          ishaAngle: 12,
        ),
        'russia' => adhan.CalculationParameters(fajrAngle: 16, ishaAngle: 15),
        'jakim' => adhan.CalculationParameters(fajrAngle: 20, ishaAngle: 18),
        'kemenag' => adhan.CalculationParameters(fajrAngle: 20, ishaAngle: 18),
        _ => _methodFor(key).getParameters(),
      };

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
  static const String _highLatKey = 'ar.prayer.highLat';
  static const String _offsetsKey = 'ar.prayer.offsets';

  @override
  PrayerSettings build() {
    try {
      final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
      final String method = prefs.getString(_methodKey) ?? 'auto';
      final bool known =
          kPrayerMethods.any((PrayerMethodOption m) => m.key == method);
      final String lat = prefs.getString(_highLatKey) ?? 'auto';
      final bool latKnown =
          kHighLatitudeRules.any((HighLatitudeOption r) => r.key == lat);
      return PrayerSettings(
        method: known ? method : 'auto',
        hanafiAsr: prefs.getBool(_asrKey) ?? false,
        highLatitude: latKnown ? lat : 'auto',
        offsets: _readOffsets(prefs.getString(_offsetsKey)),
      );
    } catch (_) {
      return const PrayerSettings();
    }
  }

  static Map<String, int> _readOffsets(String? raw) {
    if (raw == null) return const <String, int>{};
    try {
      final Object? j = jsonDecode(raw);
      if (j is! Map<String, dynamic>) return const <String, int>{};
      return PrayerSettings.cleanOffsets(<String, int>{
        for (final MapEntry<String, dynamic> e in j.entries)
          if (e.value is num) e.key: (e.value as num).toInt(),
      });
    } catch (_) {
      return const <String, int>{};
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

  Future<void> setHighLatitude(String rule) async {
    if (!kHighLatitudeRules.any((HighLatitudeOption r) => r.key == rule)) {
      return;
    }
    state = state.copyWith(highLatitude: rule);
    try {
      await ref.read(sharedPreferencesProvider).setString(_highLatKey, rule);
    } catch (_) {}
  }

  /// Sets one minute offset (clamped to +/- [kMaxOffsetMinutes]); zero
  /// clears it.
  Future<void> setOffset(String prayer, int minutes) async {
    if (!kOffsetPrayers.contains(prayer)) return;
    final Map<String, int> next = PrayerSettings.cleanOffsets(
      <String, int>{...state.offsets, prayer: minutes},
    );
    state = state.copyWith(offsets: next);
    try {
      await ref
          .read(sharedPreferencesProvider)
          .setString(_offsetsKey, jsonEncode(next));
    } catch (_) {}
  }

  Future<void> clearOffsets() async {
    state = state.copyWith(offsets: const <String, int>{});
    try {
      await ref.read(sharedPreferencesProvider).remove(_offsetsKey);
    } catch (_) {}
  }
}

final NotifierProvider<PrayerSettingsController, PrayerSettings>
    prayerSettingsProvider =
    NotifierProvider<PrayerSettingsController, PrayerSettings>(
        PrayerSettingsController.new);
