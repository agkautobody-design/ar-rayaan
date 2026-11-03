import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../domain/family_models.dart';
import 'family_repository.dart';
import 'firebase_family_repository.dart';

final Provider<FamilyRepository> familyRepositoryProvider =
    Provider<FamilyRepository>((ref) => FirebaseFamilyRepository());

/// The signed-in parent's family, or null.
final FutureProvider<Family?> familyProvider = FutureProvider<Family?>((ref) async {
  final user = await ref.watch(authStateProvider.future);
  if (user == null) return null;
  return ref.watch(familyRepositoryProvider).getFamily(user.uid);
});

/// The list of children for the signed-in parent.
final FutureProvider<List<Child>> childrenProvider = FutureProvider<List<Child>>((ref) async {
  final family = await ref.watch(familyProvider.future);
  return family?.children ?? [];
});

/// Controller for family management actions.
class FamilyController extends AsyncNotifier<Family?> {
  FamilyRepository get _repo => ref.read(familyRepositoryProvider);

  @override
  Future<Family?> build() async {
    final user = await ref.watch(authStateProvider.future);
    if (user == null) return null;
    return _repo.getFamily(user.uid);
  }

  Future<Child?> addChild(String name, {String? grade}) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return null;
    state = const AsyncLoading();
    try {
      final child = await _repo.addChild(
        parentUid: user.uid,
        name: name,
        grade: grade,
      );
      final family = await _repo.getFamily(user.uid);
      state = AsyncData(family);
      return child;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<void> removeChild(String childId) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    state = const AsyncLoading();
    try {
      await _repo.removeChild(user.uid, childId);
      final family = await _repo.getFamily(user.uid);
      state = AsyncData(family);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final AsyncNotifierProvider<FamilyController, Family?> familyControllerProvider =
    AsyncNotifierProvider<FamilyController, Family?>(FamilyController.new);
