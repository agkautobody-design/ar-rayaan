import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hadi_report_service.dart';
import 'hosted_cache.dart' show normaliseQuestion;

/// "Help Hādi learn": when switched on in Settings (off by default), the
/// words of a question Hādi could not answer are sent, with no user id, so
/// the next library update can cover it. Nothing else is sent: no answer, no
/// history. Crisis, support, minor and similar text never leaves the device
/// ([HadiReportPolicy.mayInclude]). Failed sends wait in a small queue.
class HadiMissService {
  HadiMissService(this._prefs);

  final SharedPreferences _prefs;

  static const String enabledPref = 'ar.hadi.share_misses';
  static const String queuePref = 'ar.hadi.misses';
  static const int maxQueued = 30;
  static const int maxChars = 300;

  /// Questions already recorded in this run, so a repeat is not sent twice.
  static final Set<String> _seen = <String>{};

  bool get enabled => _prefs.getBool(enabledPref) ?? false;

  /// The text that would be sent for [question], or null when nothing may be.
  static String? clean(String question) {
    final String q = question.trim();
    if (q.length < 6 || !HadiReportPolicy.mayInclude(q)) return null;
    // Long pasted text, links, e-mail addresses and numbers that look like
    // phone or card numbers are not questions for the library.
    if (q.length > 400 ||
        RegExp(r'https?://|www\.|@[a-z0-9.-]+\.[a-z]{2,}', caseSensitive: false)
            .hasMatch(q) ||
        RegExp(r'\d{7,}').hasMatch(q.replaceAll(RegExp(r'[\s-]'), ''))) {
      return null;
    }
    return q.length <= maxChars ? q : q.substring(0, maxChars);
  }

  List<String> get queued {
    try {
      final String? raw = _prefs.getString(queuePref);
      if (raw == null || raw.isEmpty) return <String>[];
      return <String>[
        for (final dynamic e in json.decode(raw) as List<dynamic>) e.toString(),
      ];
    } catch (_) {
      return <String>[];
    }
  }

  static Future<void> _send(String question) async {
    if (Firebase.apps.isEmpty) throw StateError('Firebase is not running');
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
    // The document id ends with the anonymous sign-in number, so the same
    // person asking the same thing twice is one document (create-only: the
    // second write is refused) and "asked by two different people" can be
    // counted without a name, an email or any account detail.
    final String uid = FirebaseAuth.instance.currentUser!.uid;
    final String id = '${crypto.sha256.convert(utf8.encode(normaliseQuestion(question))).toString().substring(0, 24)}_$uid';
    await FirebaseFirestore.instance.collection('hadi_misses').doc(id).set(
      <String, Object?>{
        'question': question,
        'kind': 'miss',
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
  }

  /// Records an unanswered question when sharing is on. Never throws.
  Future<void> record(String question) async {
    try {
      if (!enabled) return;
      final String? q = clean(question);
      if (q == null || !_seen.add(q.toLowerCase())) return;
      try {
        await _send(q);
        return;
      } catch (_) {}
      final List<String> list = queued..add(q);
      final List<String> tail =
          list.length > maxQueued ? list.sublist(list.length - maxQueued) : list;
      await _prefs.setString(queuePref, json.encode(tail));
    } catch (_) {}
  }

  /// Sends what is waiting; called when the app starts with Firebase running.
  Future<int> flush() async {
    try {
      final List<String> pending = queued;
      if (pending.isEmpty) return 0;
      if (!enabled || Firebase.apps.isEmpty) {
        // Switched off since: the queue is dropped, not sent.
        if (!enabled) await _prefs.remove(queuePref);
        return 0;
      }
      final List<String> left = <String>[];
      int sent = 0;
      for (final String q in pending) {
        if (clean(q) == null) continue;
        try {
          await _send(q);
          sent++;
        } catch (_) {
          left.add(q);
        }
      }
      if (left.isEmpty) {
        await _prefs.remove(queuePref);
      } else {
        await _prefs.setString(queuePref, json.encode(left));
      }
      return sent;
    } catch (_) {
      return 0;
    }
  }
}
