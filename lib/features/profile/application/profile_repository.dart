import '../../auth/application/auth_repository.dart';
import '../domain/user_profile.dart';

/// Profile storage contract. Local implementation today; Firestore
/// implementation swaps in with O-4 without touching the UI.
abstract interface class ProfileRepository {
  /// Returns the profile for [user], creating one on first sign-in.
  Future<UserProfile> ensureProfile(AuthUser user);

  /// Persists an updated profile.
  Future<void> save(UserProfile profile);
}
