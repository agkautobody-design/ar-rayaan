import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../domain/family_models.dart';
import 'family_repository.dart';

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

  CollectionReference<Map<String, dynamic>> get _invites =>
      _firestore.collection('family_invites');

  CollectionReference<Map<String, dynamic>> get _memberIndex =>
      _firestore.collection('family_members');

  @override
  Future<Family?> getFamily(String familyId) async {
    final doc = await _families.doc(familyId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Family.fromJson(doc.data()!);
  }

  @override
  Future<Family?> getFamilyForUser(String uid) async {
    final idx = await _memberIndex.doc(uid).get();
    if (!idx.exists) return null;
    final familyId = idx.data()?['familyId'] as String?;
    if (familyId == null) return null;
    return getFamily(familyId);
  }

  @override
  Future<void> saveFamily(Family family) async {
    await _families.doc(family.familyId).set(family.toJson());
    // Update reverse index for all members
    for (final m in family.members) {
      await _memberIndex.doc(m.uid).set({
        'familyId': family.familyId,
        'role': m.role,
      });
    }
    for (final c in family.children) {
      await _memberIndex.doc(c.id).set({
        'familyId': family.familyId,
        'role': 'child',
      });
    }
  }

  @override
  Future<Family> createFamily({required String parentUid, String? name}) async {
    final familyId = 'fam_${_randomId()}';
    final user = _auth.currentUser;
    final member = FamilyMember(
      uid: parentUid,
      role: 'parent',
      email: user?.email ?? '',
      name: user?.displayName,
    );
    final family = Family(
      familyId: familyId,
      name: name,
      members: [member],
      children: [],
      createdAt: DateTime.now(),
    );
    await saveFamily(family);
    return family;
  }

  @override
  Future<Child> addChild({
    required String familyId,
    required String name,
    String? grade,
  }) async {
    final random = Random.secure();
    final suffix = List.generate(6, (_) => random.nextInt(10)).join();
    final childEmail = 'child.$suffix@ar-rayaan.family';
    final password = _generatePassword();

    final cred = await _auth.createUserWithEmailAndPassword(
      email: childEmail,
      password: password,
    );
    final childUid = cred.user!.uid;

    await _firestore.collection('family_secrets').doc(childUid).set({
      'familyId': familyId,
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

    final family = await getFamily(familyId);
    if (family == null) throw Exception('Family not found');
    final updated = Family(
      familyId: family.familyId,
      name: family.name,
      members: family.members,
      children: [...family.children, child],
      createdAt: family.createdAt,
    );
    await saveFamily(updated);
    return child;
  }

  @override
  Future<void> removeChild(String familyId, String childId) async {
    final family = await getFamily(familyId);
    if (family == null) return;
    final updated = Family(
      familyId: family.familyId,
      name: family.name,
      members: family.members,
      children: family.children.where((c) => c.id != childId).toList(),
      createdAt: family.createdAt,
    );
    await saveFamily(updated);
    await _firestore.collection('family_secrets').doc(childId).delete();
    await _memberIndex.doc(childId).delete();
  }

  @override
  Future<void> updateChild(String familyId, Child child) async {
    final family = await getFamily(familyId);
    if (family == null) return;
    final updated = Family(
      familyId: family.familyId,
      name: family.name,
      members: family.members,
      children: family.children.map((c) => c.id == child.id ? child : c).toList(),
      createdAt: family.createdAt,
    );
    await saveFamily(updated);
  }

  @override
  Future<void> inviteParent({
    required String familyId,
    required String email,
    required String invitedByUid,
  }) async {
    final inviteId = '${familyId}_${_randomId()}';
    await _invites.doc(inviteId).set({
      'familyId': familyId,
      'email': email,
      'role': 'parent',
      'invitedBy': invitedByUid,
      'invitedAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  @override
  Future<void> inviteTeacher({
    required String familyId,
    required String email,
    required String invitedByUid,
  }) async {
    final inviteId = '${familyId}_${_randomId()}';
    await _invites.doc(inviteId).set({
      'familyId': familyId,
      'email': email,
      'role': 'teacher',
      'invitedBy': invitedByUid,
      'invitedAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  @override
  Future<Family?> acceptInvite(String inviteId, String uid) async {
    final doc = await _invites.doc(inviteId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    if (data['status'] != 'pending') return null;

    final familyId = data['familyId'] as String;
    final role = data['role'] as String;
    final email = data['email'] as String;

    final family = await getFamily(familyId);
    if (family == null) return null;

    // Check not already a member
    if (family.hasMember(uid)) return family;

    final user = _auth.currentUser;
    final newMember = FamilyMember(
      uid: uid,
      role: role,
      email: user?.email ?? email,
      name: user?.displayName,
      invitedBy: data['invitedBy'] as String?,
      invitedAt: DateTime.now(),
    );

    final updated = Family(
      familyId: family.familyId,
      name: family.name,
      members: [...family.members, newMember],
      children: family.children,
      createdAt: family.createdAt,
    );
    await saveFamily(updated);
    await _invites.doc(inviteId).update({'status': 'accepted', 'acceptedBy': uid});
    return updated;
  }

  @override
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

  String _randomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
