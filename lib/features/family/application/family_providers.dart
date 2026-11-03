import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;

import '../../auth/application/auth_providers.dart';
import '../domain/family_models.dart';
import '../data/family_repository.dart';
import '../data/firebase_family_repository.dart';
import '../../../app/analytics.dart';

final Provider<FamilyRepository> familyRepositoryProvider =
    Provider<FamilyRepository>((ref) => FirebaseFamilyRepository());

/// The signed-in user's family, looked up by their UID.
final FutureProvider<Family?> familyProvider = FutureProvider<Family?>((ref) async {
  final user = await ref.watch(authStateProvider.future);
  if (user == null) return null;
  return ref.watch(familyRepositoryProvider).getFamilyForUser(user.uid);
});

/// The list of children for the signed-in user's family.
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
    // Try to find existing family, or create one
    var family = await _repo.getFamilyForUser(user.uid);
    if (family == null) {
      family = await _repo.createFamily(parentUid: user.uid);
      AppAnalytics.logFamilyCreated();
    }
    return family;
  }

  Future<Child?> addChild(String name, {String? grade}) async {
    final family = state.valueOrNull;
    if (family == null) return null;
    state = const AsyncLoading();
    try {
      final child = await _repo.addChild(
        familyId: family.familyId,
        name: name,
        grade: grade,
      );
      final updated = await _repo.getFamily(family.familyId);
      state = AsyncData(updated);
      AppAnalytics.logFamilyChildAdded(family.children.length + 1);
      return child;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<void> removeChild(String childId) async {
    final family = state.valueOrNull;
    if (family == null) return;
    state = const AsyncLoading();
    try {
      await _repo.removeChild(family.familyId, childId);
      final updated = await _repo.getFamily(family.familyId);
      state = AsyncData(updated);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> inviteParent(String email) async {
    final family = state.valueOrNull;
    final user = ref.read(authStateProvider).valueOrNull;
    if (family == null || user == null) return;
    AppAnalytics.logFamilyParentInvited();
    await _repo.inviteParent(
      familyId: family.familyId,
      email: email,
      invitedByUid: user.uid,
    );
  }

  Future<void> inviteTeacher(String email) async {
    final family = state.valueOrNull;
    final user = ref.read(authStateProvider).valueOrNull;
    if (family == null || user == null) return;
    AppAnalytics.logFamilyTeacherInvited();
    await _repo.inviteTeacher(
      familyId: family.familyId,
      email: email,
      invitedByUid: user.uid,
    );
  }
}

final AsyncNotifierProvider<FamilyController, Family?> familyControllerProvider =
    AsyncNotifierProvider<FamilyController, Family?>(FamilyController.new);
