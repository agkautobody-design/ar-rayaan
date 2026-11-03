import '../../auth/application/auth_repository.dart';
import '../domain/family_models.dart';

/// Family storage contract.
abstract interface class FamilyRepository {
  /// Returns the family for [parentUid], or null if none exists.
  Future<Family?> getFamily(String parentUid);

  /// Creates or updates the family record.
  Future<void> saveFamily(Family family);

  /// Adds a child to the family and returns the created child record.
  Future<Child> addChild({
    required String parentUid,
    required String name,
    String? grade,
  });

  /// Removes a child from the family (does NOT delete the auth account).
  Future<void> removeChild(String parentUid, String childId);

  /// Updates a child's profile fields.
  Future<void> updateChild(String parentUid, Child child);
}
