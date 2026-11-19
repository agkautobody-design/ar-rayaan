import 'dart:async' show unawaited;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/child_mode.dart';
import '../../../app/core/kids_mode.dart';
import '../../../app/core/providers.dart';
import '../../academy/application/child_age_band.dart';
import '../../support/application/support_settings.dart';
import '../data/user_knows.dart';

/// "What Hadi has noticed about me": the subjects a person keeps asking
/// about and a few plain things they said about themselves, kept so Hadi can
/// put the right suggestions first. It builds by itself while it is on (it is
/// on unless the person turns it off), and:
///
///  * it learns nothing in Private mode, in Child mode or Kids Corner, or
///    while a child profile is active (those stay with the parent);
///  * it learns nothing from a question about health, safety, support or a
///    crisis, or one that carries a link, an e-mail address or a long number
///    ([UserKnowsRules.mayLearnFrom]);
///  * it stays on the device, and, only for a signed-in grown-up with sync
///    on, is copied to their own account document, which only they can read
///    (`users/{uid}/private/hadi_knows`);
///  * the person can see every line, delete one, delete all (this device and
///    the account copy) or switch it off.
///
/// It is never part of what the shared library learns ("Help Hādi learn").
class UserKnowsNotifier extends Notifier<UserKnows> {
  static const String dataPref = 'ar.hadi.knows';
  static const String onPref = 'ar.hadi.knows_on';
  static const String syncPref = 'ar.hadi.knows_sync';
  static const String noticePref = 'ar.hadi.knows_notice';

  bool _pulled = false;

  SharedPreferences get _p => ref.read(sharedPreferencesProvider);

  @override
  UserKnows build() =>
      UserKnowsRules.tidy(UserKnows.decode(_p.getString(dataPref)), DateTime.now());

  /// Whether noticing is switched on (it is, unless the person turned it off).
  bool get on => _p.getBool(onPref) ?? true;

  /// Whether the account copy is used for a signed-in grown-up.
  bool get sync => _p.getBool(syncPref) ?? true;

  /// Whether the one-time first-use note has been answered.
  bool get noticeSeen => _p.getBool(noticePref) ?? false;

  Future<bool> _allowedHere() async {
    if (!on) return false;
    try {
      if (ref.read(supportSettingsProvider).privateMode) return false;
    } catch (_) {}
    if (kChildMode.value || kKidsMode.value) return false;
    if (await ChildAgeBand.activeId() != null) return false;
    return true;
  }

  Future<void> _save(UserKnows k) async {
    state = k;
    try {
      if (k.isEmpty && k.asked == 0) {
        await _p.remove(dataPref);
      } else {
        await _p.setString(dataPref, k.encode());
      }
    } catch (_) {}
  }

  /// Learns from a question Hadi answered. Never throws.
  Future<void> noteQuestion(String question) async {
    try {
      if (!await _allowedHere()) return;
      final UserKnows next = UserKnowsRules.learn(state, question, DateTime.now());
      if (identical(next, state)) return;
      await _save(next);
      unawaited(_syncUp());
    } catch (_) {}
  }

  Future<void> setOn(bool v) async {
    try {
      await _p.setBool(onPref, v);
      if (!v) await _p.setBool(noticePref, true);
    } catch (_) {}
    ref.invalidateSelf();
  }

  Future<void> setSync(bool v) async {
    try {
      await _p.setBool(syncPref, v);
    } catch (_) {}
    if (v) {
      unawaited(syncNow());
    } else {
      unawaited(_deleteAccountCopy());
    }
    ref.invalidateSelf();
  }

  Future<void> markNoticeSeen() async {
    try {
      await _p.setBool(noticePref, true);
    } catch (_) {}
    ref.invalidateSelf();
  }

  Future<void> forgetTopic(String key) async {
    await _save(state.withoutTopic(key));
    unawaited(_syncUp());
  }

  Future<void> forgetRole(String key) async {
    await _save(state.withoutRole(key));
    unawaited(_syncUp());
  }

  /// Deletes everything noticed: this device and the account copy.
  Future<void> forgetAll() async {
    await _save(UserKnows.empty);
    await _deleteAccountCopy();
  }

  // ── Account copy (signed-in grown-ups only) ─────────────────────────────

  User? _account() {
    try {
      if (Firebase.apps.isEmpty) return null;
      final User? u = FirebaseAuth.instance.currentUser;
      if (u == null || u.isAnonymous || (u.email ?? '').isEmpty) return null;
      return u;
    } catch (_) {
      return null;
    }
  }

  DocumentReference<Map<String, dynamic>> _doc(String uid) => FirebaseFirestore
      .instance
      .collection('users')
      .doc(uid)
      .collection('private')
      .doc('hadi_knows');

  /// Pulls the account copy and merges it with this device's, then writes the
  /// merge back, so a second device picks up what the first learned. Safe to
  /// call often: it does nothing without a signed-in account, or when this is
  /// a child or private session.
  Future<void> syncNow() async {
    try {
      if (!sync || !await _allowedHere()) return;
      final User? u = _account();
      if (u == null) return;
      final DocumentSnapshot<Map<String, dynamic>> snap = await _doc(u.uid).get();
      final UserKnows theirs = UserKnows.fromJson(snap.data()?['data']);
      final UserKnows merged = UserKnowsRules.merge(state, theirs, DateTime.now());
      await _save(merged);
      await _doc(u.uid).set(<String, Object?>{
        'data': merged.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _pulled = true;
    } catch (_) {}
  }

  Future<void> _syncUp() async {
    try {
      if (!sync) return;
      if (!_pulled) {
        await syncNow();
        return;
      }
      final User? u = _account();
      if (u == null) return;
      await _doc(u.uid).set(<String, Object?>{
        'data': state.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> _deleteAccountCopy() async {
    try {
      final User? u = _account();
      if (u == null) return;
      await _doc(u.uid).delete();
    } catch (_) {}
  }
}

final NotifierProvider<UserKnowsNotifier, UserKnows> userKnowsProvider =
    NotifierProvider<UserKnowsNotifier, UserKnows>(UserKnowsNotifier.new);

/// What the screens may use: the notes, or nothing while the person has
/// switched noticing off (nothing is shown or applied, though the notes stay
/// until they delete them).
UserKnows activeKnows(WidgetRef ref) {
  final UserKnows k = ref.watch(userKnowsProvider);
  return ref.read(userKnowsProvider.notifier).on ? k : UserKnows.empty;
}
