import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../auth/application/auth_repository.dart';
import '../domain/family_models.dart';
import 'family_repository.dart';

/// Live Firebase implementation of family management.
/// Creates real child auth accounts and stores family data in Firestore.
class FirebaseFamilyRepository implements FamilyRepository {
  FirebaseFamilyRepository({
    FirebaseFirestore? firestore,
    fb.FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? fb.FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final fb.FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _families =>
      _firestore.collection('families');

  @override
  Future<Family?> getFamily(String parentUid) async {
    final doc = await _families.doc(parentUid).get();
    if (!doc.exists || doc.data() == null) return null;
    return Family.fromJson(doc.data()!);
  }

  @override
  Future<void> saveFamily(Family family) async {
    await _families.doc(family.parentUid).set(family.toJson());
  }

  @override
  Future<Child> addChild({
    required String parentUid,
    required String name,
    String? grade,
  }) async {
    // Generate a unique child email under the family domain
    final random = Random.secure();
    final suffix = List.generate(6, (_) => random.nextInt(10)).join();
    final childEmail = 'child.$suffix@ar-rayaan.family';
    final password = _generatePassword();

    // Create the child auth account
    final cred = await _auth.createUserWithEmailAndPassword(
      email: childEmail,
      password: password,
    );

    final childUid = cred.user!.uid;

    // Store the plaintext password temporarily so the parent can share it
    // In production, consider encrypting or using a one-time link
    await _firestore.collection('family_secrets').doc(childUid).set({
      'parentUid': parentUid,
      'password': password,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final child = Child(
      id: childUid,
      name: name,
      email: childEmail,
      createdAt: DateTime.now(),
      grade: grade,
    );

    // Append to family document
    final family = await getFamily(parentUid);
    if (family == null) {
      final parentEmail = _auth.currentUser?.email ?? '';
      await saveFamily(Family(
        parentUid: parentUid,
        parentEmail: parentEmail,
        children: [child],
        createdAt: DateTime.now(),
      ));
    } else {
      final updated = Family(
        parentUid: family.parentUid,
        parentEmail: family.parentEmail,
        children: [...family.children, child],
        createdAt: family.createdAt,
      );
      await saveFamily(updated);
    }

    return child;
  }

  @override
  Future<void> removeChild(String parentUid, String childId) async {
    final family = await getFamily(parentUid);
    if (family == null) return;
    final updated = Family(
      parentUid: family.parentUid,
      parentEmail: family.parentEmail,
      children: family.children.where((c) => c.id != childId).toList(),
      createdAt: family.createdAt,
    );
    await saveFamily(updated);
    await _firestore.collection('family_secrets').doc(childId).delete();
  }

  @override
  Future<void> updateChild(String parentUid, Child child) async {
    final family = await getFamily(parentUid);
    if (family == null) return;
    final updated = Family(
      parentUid: family.parentUid,
      parentEmail: family.parentEmail,
      children: family.children.map((c) => c.id == child.id ? child : c).toList(),
      createdAt: family.createdAt,
    );
    await saveFamily(updated);
  }

  /// Retrieves the child's login credentials for SMS sharing.
  Future<Map<String, String>?> getChildCredentials(String childId) async {
    final doc = await _firestore.collection('family_secrets').doc(childId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return {
      'email': data['email'] as String? ?? '',
      'password': data['password'] as String? ?? '',
    };
  }

  String _generatePassword() {
    const chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(10, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
