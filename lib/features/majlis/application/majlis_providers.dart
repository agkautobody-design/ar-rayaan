import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/application/auth_providers.dart';
import '../data/majlis_service.dart';
import '../domain/region.dart';

/// Null when this build has no Firebase project (local mode and tests):
/// the Majlis screens then show a "not connected" card instead of touching
/// Firestore, exactly like the community map does.
final Provider<MajlisService?> majlisServiceProvider =
    Provider<MajlisService?>((ref) {
  if (Firebase.apps.isEmpty) return null;
  return MajlisService();
});

final displayNameProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('ar.majlis.name') ?? 'Guest of the Courtyard';
});

/// The signed-in person's id, or null when signed out or when this build
/// has no Firebase. Drives "delete my own post" buttons.
final Provider<String?> majlisUidProvider = Provider<String?>((ref) {
  if (Firebase.apps.isEmpty) return null;
  return ref.watch(authStateProvider).value?.uid;
});

/// The community room the person chose (country + city/area); null until
/// loaded from the device, or when never set. MajlisScreen fills it.
final StateProvider<RegionSetting?> regionSettingProvider =
    StateProvider<RegionSetting?>((ref) => null);

/// An explicit room pick from the switcher; null means "automatic" — the
/// person's community room when they have one, else the Courtyard.
final StateProvider<String?> majlisRoomChoiceProvider =
    StateProvider<String?>((ref) => null);

/// The room the Majlis list is showing right now.
final Provider<String> currentRoomProvider = Provider<String>((ref) {
  final String? choice = ref.watch(majlisRoomChoiceProvider);
  if (choice != null) return choice;
  final RegionSetting? region = ref.watch(regionSettingProvider);
  if (region != null && region.isValid) return region.roomKey;
  return MajlisService.roomId;
});
