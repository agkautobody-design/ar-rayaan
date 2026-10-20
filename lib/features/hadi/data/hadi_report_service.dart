import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Why a person is reporting a Hādi answer.
enum HadiReportReason {
  wrongQuote('wrong_quote', 'A quote or reference looks wrong'),
  wrongRuling('wrong_ruling', 'It gave a ruling it should not have'),
  unsafe('unsafe', 'It was unsafe or hurtful'),
  unhelpful('unhelpful', 'It did not help'),
  other('other', 'Something else');

  const HadiReportReason(this.code, this.label);
  final String code;
  final String label;
}

/// What goes into a report. No user id. The question is included only when
/// the person turned that on.
class HadiReport {
  const HadiReport({
    required this.reason,
    required this.answer,
    required this.sources,
    required this.live,
    this.question,
  });

  final HadiReportReason reason;
  final String answer;
  final String? question;
  final List<String> sources;
  final bool live;

  static String _cap(String s, int n) => s.length <= n ? s : s.substring(0, n);

  /// The document sent to Firestore (without the server timestamp).
  Map<String, Object> toMap() => <String, Object>{
        'reason': reason.code,
        'answer': _cap(answer, 1200),
        if (question != null && question!.trim().isNotEmpty)
          'question': _cap(question!.trim(), 500),
        'sources': sources.take(5).toList(),
        'live': live,
      };
}

/// Sends a report to Firestore when Firebase is running; otherwise keeps it
/// in a small queue on the device (at most [maxQueued]) so nothing is lost
/// and nothing is sent without a connection to the project.
class HadiReportService {
  HadiReportService(this._prefs);

  final SharedPreferences _prefs;

  static const String queuePref = 'ar.hadi.reports';
  static const int maxQueued = 20;

  List<Map<String, dynamic>> get queued {
    try {
      final String? raw = _prefs.getString(queuePref);
      if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
      return <Map<String, dynamic>>[
        for (final dynamic e in json.decode(raw) as List<dynamic>)
          Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
      ];
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> _enqueue(HadiReport r) async {
    final List<Map<String, dynamic>> q = queued
      ..add(<String, dynamic>{...r.toMap(), 'at': DateTime.now().toIso8601String()});
    final List<Map<String, dynamic>> tail =
        q.length > maxQueued ? q.sublist(q.length - maxQueued) : q;
    await _prefs.setString(queuePref, json.encode(tail));
  }

  /// Returns true when the report reached Firestore, false when it was kept
  /// on the device.
  Future<bool> submit(HadiReport r) async {
    try {
      if (Firebase.apps.isNotEmpty) {
        if (FirebaseAuth.instance.currentUser == null) {
          await FirebaseAuth.instance.signInAnonymously();
        }
        await FirebaseFirestore.instance.collection('hadi_reports').add(
          <String, Object>{...r.toMap(), 'createdAt': FieldValue.serverTimestamp()},
        );
        return true;
      }
    } catch (_) {
      // Fall through to the device queue.
    }
    try {
      await _enqueue(r);
    } catch (_) {}
    return false;
  }
}
