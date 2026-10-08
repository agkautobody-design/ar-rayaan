import 'package:cloud_firestore/cloud_firestore.dart';

/// O-4 cloud sync — profile and progress ride Firestore at
/// `users/{uid}` with a `data` map and `updatedAt` for last-write-wins.
///
/// Design rules: sync is *additive* — the app is fully functional in local
/// mode, and every sync failure is swallowed (offline-tolerant) so a bad
/// connection never breaks a screen.
class FirebaseSyncService {
  FirebaseSyncService([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) {
    return _db.collection('users').doc(uid);
  }

  /// Push a data map for [uid] (merge — never clobbers other fields).
  Future<void> push(String uid, Map<String, Object?> data) async {
    try {
      await _doc(uid).set(<String, Object?>{
        'data': data,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Offline-tolerant: local state remains the source of truth.
    }
  }

  /// Pull the data map for [uid], or null when absent/unreachable.
  Future<Map<String, Object?>?> pull(String uid) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> snap =
          await _doc(uid).get();
      final Map<String, dynamic>? data = snap.data();
      if (data == null) return null;
      final Object? inner = data['data'];
      return inner is Map<String, dynamic> ? inner : null;
    } catch (_) {
      return null;
    }
  }
}
