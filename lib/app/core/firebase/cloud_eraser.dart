import 'package:cloud_firestore/cloud_firestore.dart';

/// Erases everything the app keeps in the cloud for one account.
///
/// Firestore does not delete sub-collections when their parent document is
/// deleted, so removing only `users/{uid}` and `families/{uid}` (as account
/// deletion used to) left every child's exams, lessons and mastery behind.
/// The client SDK cannot list sub-collections, so this walks the ones the
/// app is known to write:
///
///   users/{uid}
///   families/{uid}/children/{child}/exams | lessons | mastery
///
/// It is best effort: each step is attempted even if an earlier one failed,
/// and the number of failures is returned so the caller can say so. It can
/// not remove Majlis posts (the rules forbid deleting them; the Delete
/// Account screen says so) and it is no substitute for the server-side
/// "Delete User Data" extension listed in docs/OWNER_ACTIONS.md, which also
/// catches anything a future build adds.
class CloudEraser {
  const CloudEraser._();

  /// The sub-collections under each child document.
  static const List<String> childCollections = <String>[
    'exams',
    'lessons',
    'mastery',
  ];

  /// Deletes the account's cloud data. Returns how many steps failed.
  static Future<int> eraseUser(FirebaseFirestore db, String uid) async {
    var failures = 0;

    Future<void> attempt(Future<void> Function() step) async {
      try {
        await step();
      } catch (_) {
        failures++;
      }
    }

    Future<void> deleteAll(CollectionReference<Map<String, dynamic>> c) async {
      final QuerySnapshot<Map<String, dynamic>> snap = await c.get();
      for (var i = 0; i < snap.docs.length; i += 400) {
        final WriteBatch batch = db.batch();
        for (final QueryDocumentSnapshot<Map<String, dynamic>> d
            in snap.docs.skip(i).take(400)) {
          batch.delete(d.reference);
        }
        await batch.commit();
      }
    }

    final DocumentReference<Map<String, dynamic>> family =
        db.collection('families').doc(uid);
    QuerySnapshot<Map<String, dynamic>>? children;
    await attempt(() async {
      children = await family.collection('children').get();
    });
    for (final QueryDocumentSnapshot<Map<String, dynamic>> child
        in children?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
      for (final String sub in childCollections) {
        await attempt(() => deleteAll(child.reference.collection(sub)));
      }
      await attempt(() => child.reference.delete());
    }
    await attempt(() => family.delete());
    await attempt(() => db.collection('users').doc(uid).delete());
    return failures;
  }
}
