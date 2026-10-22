import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../academy/application/cloud_handles.dart';
import 'room_moves.dart';

/// The online hall — game rooms synced through Firestore.
/// Every game in the hall shares this: create a room, share the six-letter
/// code, play. Moves are appended by the side that makes them; both clients
/// listen and apply. Honest v1: dice rolled by the moving player are sent
/// with the move (server-authoritative dice arrives with Cloud Functions).
class GameRoomsService {
  /// With no arguments the hall uses Firebase if `main.dart` initialised it
  /// (see [CloudHandles.current]); otherwise [ready] is false and the lobby
  /// says so honestly. Tests may pass explicit handles.
  GameRoomsService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? CloudHandles.current().db,
        _auth = auth ?? CloudHandles.current().auth;

  final FirebaseFirestore? _db;
  final FirebaseAuth? _auth;

  Future<bool> get ready async {
    try {
      if (_db == null || _auth == null) return false;
      final u = _auth.currentUser ?? (await _auth.signInAnonymously()).user;
      return u != null;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _uid() async {
    try {
      if (_auth == null) return null;
      final u = _auth.currentUser ?? (await _auth.signInAnonymously()).user;
      return u?.uid;
    } catch (_) {
      return null;
    }
  }

  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// How long a network call may take before the lobby says so. An offline
  /// Firestore write waits for the connection forever; the caller must not.
  static const Duration netTimeout = Duration(seconds: 10);

  /// A table is deleted by a Firestore TTL policy on `expireAt` (see
  /// docs/OWNER_ACTIONS.md); until the owner turns that on, old tables just
  /// sit there, unreadable without their code.
  static const Duration roomLifetime = Duration(hours: 24);

  static String newCode([Random? rnd]) {
    final Random r = rnd ?? Random.secure();
    return List<String>.generate(
      6,
      (_) => _alphabet[r.nextInt(_alphabet.length)],
    ).join();
  }

  /// Creates a table. Returns null when online play is unavailable in this
  /// build. Throws (a timeout or a Firebase error) when the
  /// network or the server refuses: the lobby shows that and offers a retry.
  Future<Map<String, dynamic>?> createRoom(String game, String hostName) async {
    if (!await ready) return null;
    final uid = await _uid();
    if (uid == null) return null;
    final col = _db!.collection('game_rooms');
    // A code someone else already holds is skipped, not overwritten.
    String code = newCode();
    for (var i = 0; i < 5; i++) {
      final taken = await col.doc(code).get().timeout(netTimeout);
      if (!taken.exists) break;
      code = newCode();
    }
    final room = <String, dynamic>{
      'game': game,
      'status': 'waiting',
      'host': {'uid': uid, 'name': hostName},
      'guest': null,
      'turn': uid,
      'moves': <String, dynamic>{},
      'createdAt': FieldValue.serverTimestamp(),
      'lastTs': FieldValue.serverTimestamp(),
      'expireAt': Timestamp.fromDate(DateTime.now().add(roomLifetime)),
    };
    await col.doc(code).set(room).timeout(netTimeout);
    return {'code': code, 'side': 'host'};
  }

  /// Joins a waiting table. Returns null when online play is unavailable,
  /// `{'error': ...}` for a table that is missing or full, and throws like
  /// `createRoom` when the network or server fails.
  Future<Map<String, dynamic>?> joinRoom(String code, String guestName) async {
    if (!await ready) return null;
    final uid = await _uid();
    if (uid == null) return null;
    final clean = code.toUpperCase().trim();
    if (clean.length != 6) return {'error': 'A table code has six letters or digits'};
    final ref = _db!.collection('game_rooms').doc(clean);
    final snap = await ref.get().timeout(netTimeout);
    final room = snap.data();
    if (!snap.exists || room == null) return {'error': 'Room not found'};
    if (room['status'] != 'waiting') return {'error': 'Room is full'};
    final host = room['host'];
    if (host is Map<String, dynamic> && host['uid'] == uid) {
      return {'error': 'This is your own table: share the code with a friend'};
    }
    await ref.update({
      'guest': {'uid': uid, 'name': guestName},
      'status': 'playing',
      'lastTs': FieldValue.serverTimestamp(),
    }).timeout(netTimeout);
    return {'code': clean, 'side': 'guest'};
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>? watch(String code) {
    try {
      return _db!.collection('game_rooms').doc(code).snapshots();
    } catch (_) {
      return null;
    }
  }

  /// Writes move number [seq]. Idempotent: sending the same number again
  /// (a retry after a timeout) stores the same move, never a second one.
  /// The move is a field of the `moves` map, so two different numbers never
  /// overwrite each other and a repeated identical move is not dropped.
  Future<void> sendMove(String code, int seq, Map<String, dynamic> move) async {
    await _db!.collection('game_rooms').doc(code).update({
      'moves.${RoomMoves.keyOf(seq)}': move,
      'lastTs': FieldValue.serverTimestamp(),
    }).timeout(netTimeout);
  }

  Future<void> flipTurn(String code, String nextUid) async {
    await _db!.collection('game_rooms').doc(code).update({
      'turn': nextUid,
      'lastTs': FieldValue.serverTimestamp(),
    }).timeout(netTimeout);
  }

  Future<void> finish(String code, String result) async {
    await _db!.collection('game_rooms').doc(code).update({
      'status': 'done',
      'result': result,
      'lastTs': FieldValue.serverTimestamp(),
    }).timeout(netTimeout);
  }

  Future<void> leave(String code) async {
    try {
      await _db!.collection('game_rooms').doc(code).update({
        'status': 'left',
        'lastTs': FieldValue.serverTimestamp(),
      }).timeout(netTimeout);
    } catch (_) {}
  }
}
