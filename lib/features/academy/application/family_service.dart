import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/children_privacy.dart';
import 'cloud_handles.dart';

/// The family wing: children under a parent's care, progress per child, shown
/// on the parent dashboard.
///
/// CHILD PRIVACY (wave 2):
///  * Everything lives on this device. Cloud sync is OFF unless a parent has
///    recorded cloud consent ([cloudConsented], never offered in the UI yet:
///    anonymous accounts are lost with app data, so syncing would only
///    create orphaned records).
///  * Even with consent, a child's NAME never leaves the device: the cloud
///    document holds only the pseudonymous child id and progress
///    ([cloudChildDoc]).
///  * A parent can delete one child ([deleteChild]) or all of them
///    ([deleteAllChildren]); progress, the active-child pointer and any
///    cloud copy go with them.
///  * Adding a child records a dated parent consent ([recordConsent]).
class FamilyService {
  /// With no arguments the service picks up Firebase if `main.dart`
  /// initialised it (see [CloudHandles.current]) and stays on-device
  /// otherwise. Tests may pass explicit handles (or none).
  FamilyService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? CloudHandles.current().db,
        _auth = auth ?? CloudHandles.current().auth;

  final FirebaseFirestore? _db;
  final FirebaseAuth? _auth;

  static const _childrenPref = 'ar.family.children';
  static const _progressPref = 'ar.family.progress';
  static const _activePref = 'ar.family.active';
  static const _consentPref = 'ar.family.consent';
  static const _cloudConsentPref = 'ar.family.cloud_consent';
  static const _onlineGamesPref = 'ar.family.online_games';

  /// Version of the children's privacy text the parent agreed to.
  static const int consentVersion = kChildrenPrivacyVersion;

  /// What would be written to the cloud for a child: the pseudonymous id's
  /// document body. Deliberately has NO name (see class doc).
  static Map<String, dynamic> cloudChildDoc(Map<String, dynamic> child) =>
      <String, dynamic>{'createdAt': child['createdAt']};

  // ---- consent ----
  Future<bool> hasConsent() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_consentPref);
    if (raw == null || raw.isEmpty) return false;
    try {
      final m = json.decode(raw) as Map<String, dynamic>;
      return (m['version'] as num?)?.toInt() == consentVersion;
    } catch (_) {
      return false;
    }
  }

  /// Record that a parent or guardian agreed to the children's privacy text.
  Future<void> recordConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _consentPref,
      json.encode(<String, dynamic>{
        'version': consentVersion,
        'at': DateTime.now().toIso8601String(),
        'by': 'parent_or_guardian',
      }),
    );
  }

  // ---- online game tables (guardian switch, per child, default OFF) ----

  /// Whether a guardian has switched online game tables on for [childId].
  /// Off unless explicitly set; stored on this device only.
  Future<bool> onlineGamesAllowed(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_onlineGamesPref.$childId') ?? false;
  }

  Future<void> setOnlineGamesAllowed(String childId, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setBool('$_onlineGamesPref.$childId', true);
    } else {
      await prefs.remove('$_onlineGamesPref.$childId');
    }
  }

  /// Cloud sync is opt-in and not offered in the UI yet.
  Future<bool> cloudConsented() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_cloudConsentPref) ?? false;
  }

  Future<void> setCloudConsent(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cloudConsentPref, value);
  }

  Future<bool> cloudReady() async {
    try {
      if (_db == null || _auth == null) return false;
      final u = _auth.currentUser ?? (await _auth.signInAnonymously()).user;
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
    // Unique even when two children are added in the same millisecond.
    final Set<Object?> taken = <Object?>{for (final c in list) c['id']};
    String id = 'c${DateTime.now().millisecondsSinceEpoch}';
    for (int n = 2; taken.contains(id); n++) {
      id = 'c${DateTime.now().millisecondsSinceEpoch}_$n';
    }
    final String clean = name.trim();
    list.add({
      'id': id,
      'name': clean.length > 30 ? clean.substring(0, 30) : clean,
      'createdAt': DateTime.now().toIso8601String(),
    });
    await prefs.setString(_childrenPref, json.encode(list));
    await setActiveChild(id);
    unawaited(_syncCloud());
    return id;
  }

  /// Delete one child: their record, progress and active-child pointer on
  /// this device, and any cloud copy. Returns false when no such child.
  Future<bool> deleteChild(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await children();
    final before = list.length;
    list.removeWhere((c) => c['id'] == id);
    if (list.length == before) return false;
    await prefs.setString(_childrenPref, json.encode(list));
    await prefs.remove('$_progressPref.$id');
    await prefs.remove('$_onlineGamesPref.$id');
    if (prefs.getString(_activePref) == id) {
      if (list.isEmpty) {
        await prefs.remove(_activePref);
      } else {
        await prefs.setString(_activePref, list.last['id'] as String);
      }
    }
    unawaited(_deleteCloud(id));
    return true;
  }

  /// Delete every child and all their progress, and withdraw consent.
  Future<void> deleteAllChildren() async {
    for (final c in await children()) {
      await deleteChild(c['id'] as String);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_childrenPref);
    await prefs.remove(_activePref);
    await prefs.remove(_consentPref);
  }

  Future<void> _deleteCloud(String childId) async {
    try {
      if (!await cloudConsented() || !await cloudReady()) return;
      final uid = _auth!.currentUser!.uid;
      final child =
          _db!.collection('families').doc(uid).collection('children').doc(childId);
      for (final sub in const ['exams', 'lessons', 'mastery']) {
        final snap = await child.collection(sub).get();
        for (final d in snap.docs) {
          await d.reference.delete();
        }
      }
      await child.delete();
    } catch (_) {
      // Best effort: the device copy is already gone.
    }
  }

  Future<String?> activeChildId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activePref);
  }

  Future<void> setActiveChild(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activePref, id);
  }

  /// Nobody is learning: lessons and exams are no longer saved to a child.
  /// (The device-level lesson ticks are unaffected.)
  Future<void> clearActiveChild() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activePref);
  }

  // ---- progress (on-device, cloud-synced when ready) ----
  Future<Map<String, dynamic>> progress(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_progressPref.$childId');
    if (raw == null || raw.isEmpty) {
      return {
        'lessons': <String, dynamic>{},
        'exams': <String, dynamic>{},
        'mastery': <String, dynamic>{},
      };
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
    unawaited(_syncCloud());
  }

  /// Mastery levels — the no-fail model. Upgrade only: a lesson can move
  /// met -> walked -> mastered but never backwards. 'met' is set when the
  /// lesson is first completed; 'walked' when its try steps are passed;
  /// 'mastered' when the review queue sees it recalled later.
  static const Map<String, int> masteryRank = <String, int>{
    'met': 1,
    'walked': 2,
    'mastered': 3,
  };

  Future<void> recordMastery(String childId, String lessonId, String level) async {
    final p = await progress(childId);
    final m = (p['mastery'] as Map?) ?? <String, dynamic>{};
    final prev = m[lessonId] as String?;
    if (prev != null &&
        (masteryRank[prev] ?? 0) >= (masteryRank[level] ?? 0)) {
      return; // never downgrade
    }
    m[lessonId] = level;
    p['mastery'] = m;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_progressPref.$childId', json.encode(p));
    unawaited(_syncCloud());
  }

  Future<String> masteryOf(String childId, String lessonId) async {
    final p = await progress(childId);
    final m = (p['mastery'] as Map?) ?? <String, dynamic>{};
    return (m[lessonId] as String?) ?? 'new';
  }

  /// Records an exam attempt. The stored result is the BEST attempt: a
  /// weaker retake never overwrites a better score (it only bumps
  /// `attempts` and the last-attempt time).
  Future<void> recordExam(String childId, String examId,
      {required int score, required int total}) async {
    final p = await progress(childId);
    final Map<dynamic, dynamic> exams = p['exams'] as Map<dynamic, dynamic>;
    final Map<dynamic, dynamic>? prev = exams[examId] as Map<dynamic, dynamic>?;
    final int prevScore = (prev?['score'] as num?)?.toInt() ?? -1;
    final int attempts = ((prev?['attempts'] as num?)?.toInt() ?? 0) + 1;
    exams[examId] = {
      'at': DateTime.now().toIso8601String(),
      'score': score > prevScore ? score : prevScore,
      'total': total,
      'attempts': attempts,
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_progressPref.$childId', json.encode(p));
    unawaited(_syncCloud());
  }

  Future<void> _syncCloud() async {
    // Off unless a parent opted in; never signs a child's family in silently.
    if (!await cloudConsented()) return;
    if (!await cloudReady()) return;
    try {
      final uid = _auth!.currentUser!.uid;
      final list = await children();
      final fam = _db!.collection('families').doc(uid);
      await fam.set({'updatedAt': Timestamp.now()});
      for (final c in list) {
        await fam
            .collection('children')
            .doc(c['id'] as String)
            .set(cloudChildDoc(c));
        final p = await progress(c['id'] as String);
        for (final e in (p['exams'] as Map).entries) {
          await fam.collection('children').doc(c['id'] as String)
              .collection('exams').doc(e.key as String)
              .set(Map<String, dynamic>.from(e.value as Map));
        }
        for (final l in (p['lessons'] as Map).entries) {
          await fam.collection('children').doc(c['id'] as String)
              .collection('lessons').doc(l.key as String)
              .set(Map<String, dynamic>.from(l.value as Map));
        }
        for (final mv in ((p['mastery'] as Map?) ?? <String, dynamic>{}).entries) {
          await fam.collection('children').doc(c['id'] as String)
              .collection('mastery').doc(mv.key as String)
              .set(<String, dynamic>{'level': mv.value});
        }
      }
    } catch (_) {
      // Sync is best-effort; the device always holds the truth.
    }
  }
}

final familyServiceProvider =
    Provider<FamilyService>((Ref ref) => FamilyService());

final childrenProvider =
    FutureProvider<List<Map<String, dynamic>>>((Ref ref) async {
  return ref.watch(familyServiceProvider).children();
});

final progressProvider = FutureProvider.family<Map<String, dynamic>, String>(
    (Ref ref, String childId) async {
  return ref.watch(familyServiceProvider).progress(childId);
});

/// The child lessons and exams are being saved to right now (null = nobody).
/// Invalidate after [FamilyService.setActiveChild] / [FamilyService.clearActiveChild].
final activeChildProvider =
    FutureProvider<Map<String, dynamic>?>((Ref ref) async {
  final FamilyService fam = ref.watch(familyServiceProvider);
  final List<Map<String, dynamic>> kids =
      await ref.watch(childrenProvider.future);
  final String? id = await fam.activeChildId();
  if (id == null) return null;
  for (final Map<String, dynamic> c in kids) {
    if (c['id'] == id) return c;
  }
  return null;
});

/// True once someone has confirmed "who is learning" in this app session.
final learnerConfirmedProvider = StateProvider<bool>((Ref ref) => false);
