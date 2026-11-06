import 'package:shared_preferences/shared_preferences.dart';

import '../../majlis/domain/countries.dart';
import 'hijri_date.dart';

/// Who a community follows for the start of an Islamic month.
///
/// The scholarly difference is real and old: some countries sight the
/// crescent themselves (Morocco, South Asia), many follow the Saudi Royal
/// Court announcement (the Gulf, Egypt, Jordan, Palestine), and some use
/// astronomical criteria (FCNA in North America, Diyanet in Türkiye,
/// Singapore). Communities inside one country can differ — the UK has both
/// a Saudi-following camp and a local-sighting camp (ICOUK, often backed by
/// Morocco's announcement). So this is a CHOICE the person makes, with the
/// usual national practice only pre-filled, never asserted.
enum SightingConvention {
  /// The country's own committees sight the crescent (often a day later
  /// than the Umm al-Qura table).
  localSighting,

  /// Follow the Saudi Royal Court announcement (the Umm al-Qura calendar
  /// tracks it closely).
  saudi,

  /// Astronomical criteria (FCNA/ISNA in North America, Diyanet, MUIS).
  calculated,
}

String sightingConventionLabel(SightingConvention c) {
  switch (c) {
    case SightingConvention.localSighting:
      return 'Local moon sighting';
    case SightingConvention.saudi:
      return 'Saudi announcement';
    case SightingConvention.calculated:
      return 'Astronomical criteria';
  }
}

String sightingConventionHint(SightingConvention c) {
  switch (c) {
    case SightingConvention.localSighting:
      return 'Your country sights the crescent itself. Months often begin a '
          'day later than the Umm al-Qura table, so the calendar shifts +1 '
          'day — your masjid\u2019s announcement still decides.';
    case SightingConvention.saudi:
      return 'You follow the Saudi Royal Court announcement, which the Umm '
          'al-Qura calendar usually matches with no shift.';
    case SightingConvention.calculated:
      return 'You follow a council that sets dates by astronomical criteria '
          '(like FCNA in North America or Diyanet in T\u00fcrkiye); the Umm '
          'al-Qura table is the closest built-in match.';
  }
}

/// The usual practice per country — a PRE-FILL, not a ruling. Countries
/// whose communities are split (the UK, most of Europe, Australia…) are
/// deliberately absent so the person chooses.
const Map<String, SightingConvention> kNationalConvention =
    <String, SightingConvention>{
  // Saudi announcement is the norm.
  'SA': SightingConvention.saudi,
  'AE': SightingConvention.saudi,
  'QA': SightingConvention.saudi,
  'KW': SightingConvention.saudi,
  'BH': SightingConvention.saudi,
  'OM': SightingConvention.saudi,
  'YE': SightingConvention.saudi,
  'JO': SightingConvention.saudi,
  'PS': SightingConvention.saudi,
  'LB': SightingConvention.saudi,
  'EG': SightingConvention.saudi,
  'SD': SightingConvention.saudi,
  'PH': SightingConvention.saudi,
  // National committees sight locally.
  'MA': SightingConvention.localSighting,
  'DZ': SightingConvention.localSighting,
  'TN': SightingConvention.localSighting,
  'LY': SightingConvention.localSighting,
  'IN': SightingConvention.localSighting,
  'PK': SightingConvention.localSighting,
  'BD': SightingConvention.localSighting,
  'LK': SightingConvention.localSighting,
  'NP': SightingConvention.localSighting,
  'AF': SightingConvention.localSighting,
  'IR': SightingConvention.localSighting,
  'ID': SightingConvention.localSighting,
  'MY': SightingConvention.localSighting,
  'BN': SightingConvention.localSighting,
  // Astronomical criteria by the national council.
  'TR': SightingConvention.calculated,
  'SG': SightingConvention.calculated,
  'US': SightingConvention.calculated,
  'CA': SightingConvention.calculated,
};

/// The person's moon-sighting choice: their country plus the authority
/// their community follows. Drives the calendar basis and day-shift, and
/// labels every key date as subject to the real announcement.
class MoonSightingChoice {
  const MoonSightingChoice({required this.countryCode, required this.convention});

  final String countryCode;
  final SightingConvention convention;

  String get countryName => kCountries[countryCode] ?? countryCode;

  /// "United Kingdom · Local moon sighting".
  String get label => '$countryName · ${sightingConventionLabel(convention)}';

  /// What the choice does to the calendar: Saudi and calculated track the
  /// Umm al-Qura table as-is; local sighting typically runs a day later, so
  /// the dates shift +1 (the person can still fine-tune the shift by hand).
  HijriConfig get hijriEffect {
    switch (convention) {
      case SightingConvention.localSighting:
        return const HijriConfig(basis: HijriBasis.ummAlQura, adjustDays: 1);
      case SightingConvention.saudi:
      case SightingConvention.calculated:
        return const HijriConfig(basis: HijriBasis.ummAlQura, adjustDays: 0);
    }
  }

  static const String countryKey = 'ar.moon.country';
  static const String conventionKey = 'ar.moon.convention';

  static Future<MoonSightingChoice?> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? cc = prefs.getString(countryKey);
      final String? conv = prefs.getString(conventionKey);
      if (cc == null || conv == null || !kCountries.containsKey(cc)) {
        return null;
      }
      for (final SightingConvention c in SightingConvention.values) {
        if (c.name == conv) {
          return MoonSightingChoice(countryCode: cc, convention: c);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> save() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(countryKey, countryCode);
      await prefs.setString(conventionKey, convention.name);
    } catch (_) {}
  }
}
