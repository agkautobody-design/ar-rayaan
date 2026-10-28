import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'kids_mode.dart';

/// Child mode: the whole app, on this device, is a children's app until a
/// parent turns it off with the PIN.
///
/// While it is on: there is no bottom navigation, no Settings, no Ask Hadi,
/// no marriage / family-life, finance or community screens, and no Qur'an
/// screen except the short surahs in [kChildSurahs].
/// Only Kids Corner and what it opens (Arabic letters, the stories, a short
/// list of surahs and duas, and a few offline games) are
/// reachable; the router sends every other address to Kids Corner. It is saved
/// on the device, so a reload does not end it.
///
/// A plain notifier rather than a provider so the router (its refresh
/// listenable) and widgets outside a ProviderScope can listen to it.
final ValueNotifier<bool> kChildMode = ValueNotifier<bool>(false);

const String kChildModePref = 'ar.childMode.v1';

/// Reads the saved state at start-up.
void loadChildMode(SharedPreferences prefs) {
  kChildMode.value = prefs.getBool(kChildModePref) ?? false;
  if (kChildMode.value) kKidsMode.value = true;
}

/// Turns child mode on or off and saves it.
Future<void> setChildMode(SharedPreferences prefs, bool on) async {
  kChildMode.value = on;
  kKidsMode.value = on;
  await prefs.setBool(kChildModePref, on);
}

/// Where child mode sends everything that is not for children.
const String kChildHome = '/kids';

/// The addresses a child can reach: Kids Corner, the letters lessons and the
/// stories school with its story reader.
const List<String> kChildAllowed = <String>[
  '/kids',
  '/academy/letters',
  '/academy/stories',
  '/stories/read',
  // Games with no chat and no online play (the hub is exact, and a game
  // page must be one of [kChildGameIds]; see [childModeAllows]).
  '/games',
  '/games/memory',
  '/games/names99',
  '/games/g',
  // Short surahs and duas, as lists made for children.
  '/kids/surahs',
  '/kids/duas',
];

/// The games a child is shown (and can open) in child mode: a short, curated
/// list. Each runs on this device with no chat and no online table. Hifz
/// practice, the Seerah challenges, Ludo and chess (which have online play)
/// and the adult question banks are left for a grown-up.
/// Reviewed in the scholar register (child-mode games).
const List<String> kChildGameIds = <String>[
  'arabic-words',
  'memory',
  'names99',
  'salah-wudu',
  'prophets-order',
];

/// The short surahs a child can open and listen to in child mode. Each is a
/// short, well-known surah children learn first; the long ones and the ones
/// that name people in a warning (for example Al-Masad) are left for a grown-up.
/// Reviewed in the scholar register (child-mode surah set).
const List<int> kChildSurahs = <int>[1, 103, 105, 106, 107, 108, 109, 110, 112, 113, 114];

/// True when [path] is for children.
bool childModeAllows(String path) {
  final String bare = path.split('?').first;
  if (bare.startsWith('/quran/')) {
    final int? n = int.tryParse(bare.substring('/quran/'.length));
    return n != null && kChildSurahs.contains(n);
  }
  // The Games hub is exact: its other tables (Ludo, chess, online rooms) are not
  // for a child on their own.
  if (path == '/games') return true;
  if (bare.startsWith('/games/g/')) {
    final List<String> parts = bare.split('/');
    // /games/g/<id>[/setup|/play|/results]
    return parts.length >= 4 && kChildGameIds.contains(parts[3]);
  }
  for (final String p in kChildAllowed) {
    if (p == '/games' || p == '/games/g') continue;
    if (path == p || path.startsWith('$p/')) return true;
  }
  return false;
}

/// The router redirect: null (stay) when child mode is off or [path] is
/// allowed, otherwise Kids Corner.
String? childModeRedirect(String path) {
  if (!kChildMode.value) return null;
  return childModeAllows(path) ? null : kChildHome;
}
