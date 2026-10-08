import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/local_profile_repository.dart';
import '../domain/user_profile.dart';
import 'profile_repository.dart';

final Provider<ProfileRepository> profileRepositoryProvider =
    Provider<ProfileRepository>(
      (ref) => LocalProfileRepository(ref.watch(sharedPreferencesProvider)),
    );

/// The signed-in user's profile, or null for guests.
final FutureProvider<UserProfile?> userProfileProvider =
    FutureProvider<UserProfile?>((ref) async {
      final user = await ref.watch(authStateProvider.future);
      if (user == null) return null;
      return ref.watch(profileRepositoryProvider).ensureProfile(user);
    });
