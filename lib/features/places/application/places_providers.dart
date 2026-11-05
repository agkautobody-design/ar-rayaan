import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/community_places_service.dart';
import '../domain/community_place.dart';

/// Null when this build has no Firebase project (local mode): the screens
/// then hide every community-places control, exactly like the community
/// hub does when the backend is off.
final Provider<CommunityPlacesService?> communityPlacesServiceProvider =
    Provider<CommunityPlacesService?>((ref) {
  if (Firebase.apps.isEmpty) return null;
  return CommunityPlacesService();
});

/// Whether the map can take community submissions at all.
final Provider<bool> communityPlacesEnabledProvider = Provider<bool>(
  (ref) => ref.watch(communityPlacesServiceProvider) != null,
);

/// Newest community places (any state — the screens filter).
final StreamProvider<List<CommunityPlace>> communityPlacesProvider =
    StreamProvider<List<CommunityPlace>>((ref) {
  final CommunityPlacesService? svc =
      ref.watch(communityPlacesServiceProvider);
  if (svc == null) return Stream.value(const <CommunityPlace>[]);
  return svc.places();
});

/// Community events that have not ended yet.
final StreamProvider<List<CommunityEvent>> communityEventsProvider =
    StreamProvider<List<CommunityEvent>>((ref) {
  final CommunityPlacesService? svc =
      ref.watch(communityPlacesServiceProvider);
  if (svc == null) return Stream.value(const <CommunityEvent>[]);
  return svc.events();
});

/// True when the signed-in account is marked as a founder in Firestore.
/// Re-checks whenever the signed-in account changes.
final FutureProvider<bool> isFounderProvider = FutureProvider<bool>((ref) {
  final CommunityPlacesService? svc =
      ref.watch(communityPlacesServiceProvider);
  final auth = ref.watch(authStateProvider).value;
  if (svc == null || auth == null) return false;
  return svc.isFounder();
});
