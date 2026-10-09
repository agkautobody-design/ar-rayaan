import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// The online hall — game rooms synced through Firestore.
/// Every game in the hall shares this: create a room, share the six-letter
/// code, play. Moves are appended by the side that makes them; both clients
/// listen and apply. Honest v1: dice rolled by the moving player are sent
/// with the move (server-authoritative dice arrives with Cloud Functions).
class GameRoomsService {
  GameRoomsService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db, _auth = auth;

  final FirebaseFirestore? _db;
  final FirebaseAuth? _auth;

  Future<bool> get ready async {
    try {
      if (_db == null || _auth == null) return false;
      final u = _auth!.currentUser ?? (await _auth!.signInAnonymously()).user;
      return u != null;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _uid() async {
    try {
      final u = _auth!.currentUser ?? (await _auth!.signInAnonymously()).user;
      return u?.uid;
    } catch (_) {
      return null;
    }
  }

  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  Future<Map<String, dynamic>?> createRoom(String game, String hostName) async {
    if (!await ready) return null;
    final uid = await _uid();
    final rnd = Random();
    final code = List.generate(6, (_) => _alphabet[rnd.nextInt(_alphabet.length)]).join();
    final room = <String, dynamic>{
      'game': game,
      'status': 'waiting',
      'host': {'uid': uid, 'name': hostName},
      'guest': null,
      'turn': uid,
      'moves': <dynamic>[],
      'createdAt': Timestamp.now(),
      'lastTs': Timestamp.now(),
    };
    await _db!.collection('game_rooms').doc(code).set(room);
    return {'code': code, 'side': 'host', 'room': room};
  }

  Future<Map<String, dynamic>?> joinRoom(String code, String guestName) async {
    if (!await ready) return null;
    final uid = await _uid();
    final ref = _db!.collection('game_rooms').doc(code.toUpperCase().trim());
    final snap = await ref.get();
    if (!snap.exists) return {'error': 'Room not found'};
    final room = snap.data()!;
    if (room['status'] != 'waiting') return {'error': 'Room is full'};
    await ref.update({
      'guest': {'uid': uid, 'name': guestName},
      'status': 'playing',
      'lastTs': Timestamp.now(),
    });
    return {'code': code.toUpperCase().trim(), 'side': 'guest'};
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>? watch(String code) {
    try {
      return _db!.collection('game_rooms').doc(code).snapshots();
    } catch (_) {
      return null;
    }
  }

  Future<void> sendMove(String code, Map<String, dynamic> move) async {
    await _db!.collection('game_rooms').doc(code).update({
      'moves': FieldValue.arrayUnion([move]),
      'lastTs': Timestamp.now(),
    });
  }

  Future<void> flipTurn(String code, String nextUid) async {
    await _db!.collection('game_rooms').doc(code).update({
      'turn': nextUid,
      'lastTs': Timestamp.now(),
    });
  }

  Future<void> finish(String code, String result) async {
    await _db!.collection('game_rooms').doc(code).update({
      'status': 'done',
      'result': result,
      'lastTs': Timestamp.now(),
    });
  }

  Future<void> leave(String code) async {
    try {
      await _db!.collection('game_rooms').doc(code).update({'status': 'left'});
    } catch (_) {}
  }
}
