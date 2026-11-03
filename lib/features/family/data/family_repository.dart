import '../domain/family_models.dart';

abstract interface class FamilyRepository {
  Future<Family?> getFamily(String familyId);
  Future<Family?> getFamilyForUser(String uid);
  Future<void> saveFamily(Family family);
  Future<Family> createFamily({required String parentUid, String? name});

  Future<Child> addChild({
    required String familyId,
    required String name,
    String? grade,
  });

  Future<void> removeChild(String familyId, String childId);
  Future<void> updateChild(String familyId, Child child);

  Future<void> inviteParent({
    required String familyId,
    required String email,
    required String invitedByUid,
  });

  Future<void> inviteTeacher({
    required String familyId,
    required String email,
    required String invitedByUid,
  });

  Future<Family?> acceptInvite(String inviteId, String uid);
  Future<Map<String, String>?> getChildCredentials(String childId);
}
