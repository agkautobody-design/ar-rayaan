import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/children_privacy.dart';
import '../domain/letters_meta.dart';
import 'cloud_handles.dart';

/// The family wing: children under a parent's care, progress per child, shown
/// on the parent dashboard.
///
/// CHILD PRIVACY (wave 2):
///  * Everything lives on this device. Cloud sync is OFF unless a parent
///    signed in with a REAL account and switched it on in the Family Wing
///    ([cloudConsented]). Anonymous accounts never sync: they are lost with
///    app data, and could never be read from the parent's own phone.
///  * Even with consent, a child's NAME never leaves the device: the cloud
///    document holds only the pseudonymous child id and a progress summary
///    ([cloudChildDoc], [cloudSummary]).
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
  static const _bandPref = 'ar.family.age_band';

  /// The age bands a parent can choose for a child. Used only to pick the
  /// words Wasia uses with that child (never to profile them).
  static const List<String> ageBands = <String>['5-8', '9-12', '13-17'];

  /// Used when the parent has not chosen one.
  static const String defaultAgeBand = '9-12';

  /// Version of the children's privacy text the parent agreed to.
  static const int consentVersion = kChildrenPrivacyVersion;

  /// What would be written to the cloud for a child: the pseudonymous id's
  /// document body. Deliberately has NO name (see class doc).
  static Map<String, dynamic> cloudChildDoc(Map<String, dynamic> child) =>
      <String, dynamic>{'createdAt': child['createdAt']};

  /// The progress summary a parent reads from another phone: counts, a level
  /// and the last time something was done. No name, no answers, no text.
  static Map<String, dynamic> cloudSummary({
    required Map<String, dynamic> progress,
    required int lettersTotal,
    int? surah,
    int? ayah,
  }) {
    final lessons = (progress['lessons'] as Map?) ?? const {};
    final exams = (progress['exams'] as Map?) ?? const {};
    final mastery = (progress['mastery'] as Map?) ?? const {};
    var best = 0;
    var last = '';
    void seen(Object? v) {
      if (v is Map && v['at'] is String && (v['at'] as String).compareTo(last) > 0) {
        last = v['at'] as String;
      }
    }

    for (final v in lessons.values) {
      seen(v);
    }
    for (final v in exams.values) {
      seen(v);
      if (v is Map) {
        final sc = (v['score'] as num? ?? 0).toInt();
        final tot = (v['total'] as num? ?? 0).toInt();
        if (tot > 0) {
          final pct = (sc * 100 / tot).round();
          if (pct > best) best = pct;
        }
      }
    }
    return <String, dynamic>{
      'lessonsDone': lessons.length,
      'lettersTotal': lettersTotal,
      'examsTaken': exams.length,
      'bestPct': best,
      'masteredCount': mastery.values.where((v) => v == 'mastered').length,
      if (last.isNotEmpty) 'lastActiveAt': last,
      if (surah != null && ayah != null)
        'quran': <String, dynamic>{'surah': surah, 'ayah': ayah},
    };
  }

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

  /// The parent-set age band for [childId], or the default.
  Future<String> ageBand(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? v = prefs.getString('$_bandPref.$childId');
    return (v != null && ageBands.contains(v)) ? v : defaultAgeBand;
  }

  Future<void> setAgeBand(String childId, String band) async {
    if (!ageBands.contains(band)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_bandPref.$childId', band);
  }

  /// Cloud sync is opt-in: a signed-in parent switches it on in the Family Wing.
  Future<bool> cloudConsented() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_cloudConsentPref) ?? false;
  }

  Future<void> setCloudConsent(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cloudConsentPref, value);
  }

  /// True only for a signed-in REAL account (email, Google or Apple). Never
  /// signs anyone in silently, and an anonymous sign-in does not count.
  Future<bool> cloudReady() async {
    try {
      if (_db == null || _auth == null) return false;
      final u = _auth.currentUser;
      return u != null && !u.isAnonymous;
    } catch (_) {
      return false;
    }
  }

  /// What the parent's phone reads: one summary per child on the account.
  /// Holds no name; the app shows "Child 1", "Child 2" or a label the parent
  /// typed on that phone ([cloudLabels]).
  Future<List<Map<String, dynamic>>> cloudChildren() async {
    if (!await cloudReady()) return const <Map<String, dynamic>>[];
    final uid = _auth!.currentUser!.uid;
    final snap = await _db!
        .collection('families')
        .doc(uid)
        .collection('children')
        .get();
    final out = <Map<String, dynamic>>[
      for (final d in snap.docs) <String, dynamic>{...d.data(), 'id': d.id},
    ];
    out.sort((a, b) => '${a['createdAt']}'.compareTo('${b['createdAt']}'));
    return out;
  }

  /// Parent's own labels for children seen in the cloud, kept on THIS phone.
  static const _cloudLabelsPref = 'ar.family.cloud_labels';

  Future<Map<String, String>> cloudLabels() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cloudLabelsPref);
    if (raw == null || raw.isEmpty) return <String, String>{};
    try {
      final m = json.decode(raw) as Map;
      return <String, String>{
        for (final e in m.entries) '${e.key}': '${e.value}',
      };
    } catch (_) {
      return <String, String>{};
    }
  }

  Future<void> setCloudLabel(String childId, String label) async {
    final prefs = await SharedPreferences.getInstance();
    final m = await cloudLabels();
    final t = label.trim();
    if (t.isEmpty) {
      m.remove(childId);
    } else {
      m[childId] = t.length > 30 ? t.substring(0, 30) : t;
    }
    await prefs.setString(_cloudLabelsPref, json.encode(m));
  }

  /// Parent turns sync off: the cloud copy is deleted first, then consent.
  Future<void> turnCloudSyncOff() async {
    try {
      for (final c in await cloudChildren()) {
        await _deleteCloud(c['id'] as String);
      }
    } catch (_) {}
    await setCloudConsent(false);
  }

  /// Parent turns sync on (after the plain-words confirmation) and the first
  /// copy is written at once.
  Future<void> turnCloudSyncOn() async {
    await setCloudConsent(true);
    await _syncCloud();
  }

  /// Writes the summary now (used when the Family Wing opens).
  Future<void> syncNow() => _syncCloud();

  static DateTime? _lastSoon;

  /// A throttled sync for frequent events such as saving a reading place.
  void syncSoon() {
    final now = DateTime.now();
    final last = _lastSoon;
    if (last != null && now.difference(last) < const Duration(seconds: 20)) {
      return;
    }
    _lastSoon = now;
    unawaited(_syncCloud());
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
    // The same name added again within seconds (a double tap, or the dialog
    // coming back after a lock) is the same child, not a second one.
    final String key = (clean.length > 30 ? clean.substring(0, 30) : clean)
        .toLowerCase();
    for (final Map<String, dynamic> c in list) {
      final DateTime? made = DateTime.tryParse('${c['createdAt']}');
      if ('${c['name']}'.toLowerCase() == key &&
          made != null &&
          DateTime.now().difference(made).inSeconds.abs() < 15) {
        await setActiveChild(c['id'] as String);
        return c['id'] as String;
      }
    }
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
    await prefs.remove('$_bandPref.$id');
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
    // Off unless a signed-in parent opted in; never signs anyone in silently.
    try {
      if (!await cloudConsented()) return;
      if (!await cloudReady()) return;
      final uid = _auth!.currentUser!.uid;
      final prefs = await SharedPreferences.getInstance();
      final String? active = await activeChildId();
      int? surah;
      int? ayah;
      final raw = prefs.getString('ar.quran.lastRead');
      if (raw != null) {
        try {
          final m = json.decode(raw) as Map;
          surah = (m['surah'] as num).toInt();
          ayah = (m['ayah'] as num).toInt();
        } catch (_) {}
      }
      final fam = _db!.collection('families').doc(uid);
      await fam.set(<String, dynamic>{'updatedAt': Timestamp.now()},
          SetOptions(merge: true));
      for (final c in await children()) {
        final id = c['id'] as String;
        final p = await progress(id);
        final data = <String, dynamic>{
          ...cloudChildDoc(c),
          ...cloudSummary(
            progress: p,
            lettersTotal: kLettersLessonCount,
            surah: id == active ? surah : null,
            ayah: id == active ? ayah : null,
          ),
          'updatedAt': Timestamp.now(),
        };
        await fam
            .collection('children')
            .doc(id)
            .set(data, SetOptions(merge: true));
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
