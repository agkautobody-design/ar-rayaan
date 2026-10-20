import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/majlis_policy.dart';

/// A write the policy refused before it left the device. [message] is safe
/// to show to the person.
class MajlisRejected implements Exception {
  const MajlisRejected(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The Courtyard — phase 1 of the Majlis. Public read, authenticated write.
/// Posts are not reviewed before they appear; people can report them, and
/// Firestore rules enforce server timestamps, size limits, reserved names and
/// a minimum gap between writes.
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

  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('majlis_reports');

  DocumentReference<Map<String, dynamic>> _rateDoc(String uid) =>
      _db.collection('majlis_rate').doc(uid);

  /// Recent write times are kept on this device so the client can explain a
  /// wait; the server enforces its own minimum gap regardless.
  static const String _recentKey = 'ar.majlis.recent';

  Future<List<DateTime>> _recentWrites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(_recentKey) ?? const <String>[])
          .map(DateTime.tryParse)
          .whereType<DateTime>()
          .toList();
    } catch (_) {
      return <DateTime>[];
    }
  }

  Future<void> _checkAllowedToWrite() async {
    final wait =
        MajlisPolicy.waitBeforeNextPost(await _recentWrites(), DateTime.now());
    if (wait != null) {
      throw MajlisRejected(
        'Please wait ${wait.inSeconds + 1} seconds before posting again.',
      );
    }
  }

  Future<void> _noteWrite() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hourAgo = DateTime.now().subtract(const Duration(hours: 1));
      final kept = (await _recentWrites()).where((t) => t.isAfter(hourAgo));
      await prefs.setStringList(
        _recentKey,
        <String>[
          ...kept.map((t) => t.toIso8601String()),
          DateTime.now().toIso8601String(),
        ],
      );
    } catch (_) {}
  }

  Future<String> createThread({
    required String title,
    required String authorName,
    required String firstPost,
  }) async {
    final nameProblem = MajlisPolicy.validateName(authorName);
    final problem = nameProblem ??
        MajlisPolicy.validateTitle(title) ??
        MajlisPolicy.validateBody(firstPost);
    if (problem != null) throw MajlisRejected(problem);
    await _checkAllowedToWrite();
    final String uid = await _uid();
    final threadRef = _threads.doc();
    final postRef = threadRef.collection('posts').doc();
    final batch = _db.batch();
    batch.set(threadRef, <String, dynamic>{
      'title': title.trim(),
      'authorName': authorName.trim(),
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActivity': FieldValue.serverTimestamp(),
      'replyCount': 1,
      'lastPostId': postRef.id,
    });
    batch.set(postRef, <String, dynamic>{
      'body': firstPost.trim(),
      'authorName': authorName.trim(),
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(_rateDoc(uid), <String, dynamic>{
      'lastPostAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    await _noteWrite();
    return threadRef.id;
  }

  Future<void> reply({
    required String threadId,
    required String body,
    required String authorName,
  }) async {
    final problem =
        MajlisPolicy.validateName(authorName) ?? MajlisPolicy.validateBody(body);
    if (problem != null) throw MajlisRejected(problem);
    await _checkAllowedToWrite();
    final String uid = await _uid();
    final threadRef = _threads.doc(threadId);
    final postRef = threadRef.collection('posts').doc();
    final batch = _db.batch();
    batch.set(postRef, <String, dynamic>{
      'body': body.trim(),
      'authorName': authorName.trim(),
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(threadRef, <String, dynamic>{
      'replyCount': FieldValue.increment(1),
      'lastActivity': FieldValue.serverTimestamp(),
      'lastPostId': postRef.id,
    });
    batch.set(_rateDoc(uid), <String, dynamic>{
      'lastPostAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    await _noteWrite();
  }

  /// Sends a report to the moderators' queue. One report per person per
  /// target (the document id enforces it). [postId] is null when reporting
  /// a whole thread.
  Future<void> report({
    required String threadId,
    String? postId,
    required String reason,
    String? note,
  }) async {
    if (!MajlisPolicy.reportReasons.contains(reason)) {
      throw const MajlisRejected('Please choose a reason.');
    }
    final String uid = await _uid();
    final target = postId == null ? threadId : '${threadId}_$postId';
    final trimmed = (note ?? '').trim();
    await _reports.doc('${uid}_$target').set(<String, dynamic>{
      'threadId': threadId,
      if (postId != null) 'postId': postId,
      'target': target,
      'reason': reason,
      if (trimmed.isNotEmpty)
        'note': trimmed.length > 300 ? trimmed.substring(0, 300) : trimmed,
      'reporterUid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Founder tool, NOT called by the app: Firestore rules deny client writes
  /// to rooms and seed threads, so this only works from an admin context.
  /// `assets/majlis/seed.json` holds invented example people; do not seed it
  /// into a live forum without replacing them.
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
