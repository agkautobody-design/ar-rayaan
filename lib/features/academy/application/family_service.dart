import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The family wing: children under a parent's account, progress per child,
/// shared with the parent dashboard. Cloud (Firestore) when Firebase's
/// switches are on; on-device otherwise so the wing is never dead.
class FamilyService {
  FamilyService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db, _auth = auth;

  final FirebaseFirestore? _db;
  final FirebaseAuth? _auth;

  static const _childrenPref = 'ar.family.children';
  static const _progressPref = 'ar.family.progress';
  static const _activePref = 'ar.family.active';

  Future<bool> cloudReady() async {
    try {
      if (_db == null || _auth == null) return false;
      final u = _auth!.currentUser ?? (await _auth!.signInAnonymously()).user;
      return u != null;
    } catch (_) {
      return false;
    }
  }

  // ---- children ----
  Future<List<Map<String, dynamic>>> children() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_childrenPref);
    if (raw == null || raw.isEmpty) return [];
    return (json.decode(raw) as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<String> addChild(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await children();
    final id = 'c${DateTime.now().millisecondsSinceEpoch}';
    list.add({'id': id, 'name': name.trim(), 'createdAt': DateTime.now().toIso8601String()});
    await prefs.setString(_childrenPref, json.encode(list));
    await setActiveChild(id);
    await _syncCloud();
    return id;
  }

  Future<String?> activeChildId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activePref);
  }

  Future<void> setActiveChild(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activePref, id);
  }

  // ---- progress (on-device, cloud-synced when ready) ----
  Future<Map<String, dynamic>> progress(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_progressPref.$childId');
    if (raw == null || raw.isEmpty) {
      return {'lessons': <String, dynamic>{}, 'exams': <String, dynamic>{}};
    }
    return Map<String, dynamic>.from(json.decode(raw) as Map);
  }

  Future<void> markLessonDone(String childId, String lessonId,
      {required bool quizCorrect}) async {
    final p = await progress(childId);
    (p['lessons'] as Map)[lessonId] = {
      'at': DateTime.now().toIso8601String(),
      'quizCorrect': quizCorrect,
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_progressPref.$childId', json.encode(p));
    await _syncCloud();
  }

  Future<void> recordExam(String childId, String examId,
      {required int score, required int total}) async {
    final p = await progress(childId);
    (p['exams'] as Map)[examId] = {
      'at': DateTime.now().toIso8601String(),
      'score': score,
      'total': total,
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_progressPref.$childId', json.encode(p));
    await _syncCloud();
  }

  Future<void> _syncCloud() async {
    if (!await cloudReady()) return;
    try {
      final uid = _auth!.currentUser!.uid;
      final list = await children();
      final fam = _db!.collection('families').doc(uid);
      await fam.set({'updatedAt': Timestamp.now()});
      for (final c in list) {
        await fam.collection('children').doc(c['id'] as String).set({
          'name': c['name'],
          'createdAt': c['createdAt'],
        });
        final p = await progress(c['id'] as String);
        for (final e in (p['exams'] as Map).entries) {
          await fam.collection('children').doc(c['id'] as String)
              .collection('exams').doc(e.key)
              .set(Map<String, dynamic>.from(e.value as Map));
        }
        for (final l in (p['lessons'] as Map).entries) {
          await fam.collection('children').doc(c['id'] as String)
              .collection('lessons').doc(l.key)
              .set(Map<String, dynamic>.from(l.value as Map));
        }
      }
    } catch (_) {
      // Sync is best-effort; the device always holds the truth.
    }
  }
}
