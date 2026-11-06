import 'package:shared_preferences/shared_preferences.dart';

import 'countries.dart';

/// The community a person says they belong to: a country (fixed ISO list)
/// plus a city / town / province they type. Together they name one Majlis
/// room — `region-gb-birmingham` for Birmingham, United Kingdom — so the
/// people of a place can talk about their own events, masajid and news.
///
/// The room key pattern is mirrored exactly in `firestore.rules`
/// (knownRoom) and pinned by test/majlis_region_test.dart: change one and
/// the test makes you change the other.
class RegionSetting {
  const RegionSetting({required this.countryCode, required this.area});

  /// ISO 3166-1 alpha-2, upper-case, present in [kCountries].
  final String countryCode;

  /// City, town, province or state as the person typed it.
  final String area;

  /// The slug used inside the room key; null when the typed area can not
  /// become one (too short, or nothing but symbols).
  String? get areaSlug => slugify(area);

  bool get isValid => kCountries.containsKey(countryCode) && areaSlug != null;

  /// Firestore room id, e.g. `region-gb-birmingham`.
  String get roomKey =>
      'region-${countryCode.toLowerCase()}-${areaSlug ?? 'unset'}';

  /// "Birmingham, United Kingdom".
  String get label => '$area, ${kCountries[countryCode] ?? countryCode}';

  static const String countryKey = 'ar.region.country';
  static const String areaKey = 'ar.region.area';

  static Future<RegionSetting?> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? cc = prefs.getString(countryKey);
      final String? area = prefs.getString(areaKey);
      if (cc == null || area == null) return null;
      final RegionSetting r = RegionSetting(countryCode: cc, area: area);
      return r.isValid ? r : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> save() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(countryKey, countryCode);
      await prefs.setString(areaKey, area);
    } catch (_) {}
  }
}

/// The room ids the Firestore rules accept, besides 'courtyard'.
final RegExp roomKeyPattern =
    RegExp(r'^region-[a-z]{2}-[a-z0-9][a-z0-9-]{0,38}[a-z0-9]$');

/// A room id from a link (query parameter), or null when it is not a real
/// room — typed links can carry anything, and only real rooms may be used.
String? roomKeyOrNull(String? raw) {
  if (raw == 'courtyard') return 'courtyard';
  if (raw != null && roomKeyPattern.hasMatch(raw)) return raw;
  return null;
}

/// Turns a typed area into the slug part of a room key: lower-case ASCII
/// letters and digits joined by single dashes, 2 to 40 characters. Returns
/// null when nothing usable is left. Accents fold (São → sao), so "São
/// Paulo" and "Sao Paulo" land in the same room.
String? slugify(String area) {
  final String folded = area.toLowerCase().split('').map((String ch) {
    return _accentFold[ch] ?? ch;
  }).join();
  final String dashed = folded
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-{2,}'), '-');
  final String trimmed =
      dashed.replaceAll(RegExp(r'^-+'), '').replaceAll(RegExp(r'-+$'), '');
  if (trimmed.length < 2) return null;
  return trimmed.length > 40 ? trimmed.substring(0, 40) : trimmed;
}

const Map<String, String> _accentFold = <String, String>{
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'ā': 'a',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ī': 'i',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o', 'ō': 'o',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ū': 'u',
  'ç': 'c', 'ñ': 'n', 'ß': 'ss', 'æ': 'ae', 'œ': 'oe',
};
