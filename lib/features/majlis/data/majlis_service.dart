import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show rootBundle;

/// The Courtyard — phase 1 of the Majlis. Public read, authenticated write,
/// seeded on first open so no room ever opens empty (Community Design law).
class MajlisService {
  MajlisService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const String roomId = 'courtyard';

  Future<String> _uid() async {
    User? user = _auth.currentUser;
    user ??= (await _auth.signInAnonymously()).user;
    return user!.uid;
  }

  CollectionReference<Map<String, dynamic>> get _threads => _db
      .collection('majlis_rooms')
      .doc(roomId)
      .collection('threads');

  Stream<QuerySnapshot<Map<String, dynamic>>> threads() => _threads
      .orderBy('lastActivity', descending: true)
      .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> posts(String threadId) => _threads
      .doc(threadId)
      .collection('posts')
      .orderBy('createdAt')
      .snapshots();

  Future<String> createThread({
    required String title,
    required String authorName,
    required String firstPost,
  }) async {
    final String uid = await _uid();
    final now = Timestamp.now();
    final ref = await _threads.add({
      'title': title.trim(),
      'authorName': authorName.trim(),
      'uid': uid,
      'createdAt': now,
      'lastActivity': now,
      'replyCount': 1,
    });
    await ref.collection('posts').add({
      'body': firstPost.trim(),
      'authorName': authorName.trim(),
      'uid': uid,
      'createdAt': now,
    });
    return ref.id;
  }

  Future<void> reply({
    required String threadId,
    required String body,
    required String authorName,
  }) async {
    final String uid = await _uid();
    final threadRef = _threads.doc(threadId);
    await threadRef.collection('posts').add({
      'body': body.trim(),
      'authorName': authorName.trim(),
      'uid': uid,
      'createdAt': Timestamp.now(),
    });
    await threadRef.update({
      'replyCount': FieldValue.increment(1),
      'lastActivity': Timestamp.now(),
    });
  }

  /// Seeds the courtyard from bundled JSON if the room has no threads yet.
  Future<void> seedIfEmpty() async {
    final snap = await _threads.limit(1).get();
    if (snap.docs.isNotEmpty) return;
    final raw = await rootBundle.loadString('assets/majlis/seed.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    await _db.collection('majlis_rooms').doc(roomId).set(
      Map<String, dynamic>.from(data['room'] as Map)..remove('id'),
    );
    for (final t in data['threads'] as List<dynamic>) {
      final tm = Map<String, dynamic>.from(t as Map);
      final posts = (tm.remove('posts') as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final now = Timestamp.now();
      final ref = await _threads.add({
        'title': tm['title'],
        'authorName': tm['authorName'],
        'uid': 'seed',
        'createdAt': now,
        'lastActivity': now,
        'replyCount': posts.length,
      });
      for (final p in posts) {
        await ref.collection('posts').add({
          'body': p['body'],
          'authorName': p['authorName'],
          'uid': 'seed',
          'createdAt': now,
        });
      }
    }
  }
}
