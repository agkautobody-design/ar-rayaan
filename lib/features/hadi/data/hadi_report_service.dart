import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../sakina/domain/crisis_detector.dart';
import '../grounding/minor_signal.dart';
import '../grounding/support_signal.dart';

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

/// What may leave the device in a report. Text from a crisis exchange, from a
/// person talking about drinking, drugs, gambling, pornography, smoking or
/// someone close who is struggling, or from someone under 18 is health or
/// safety information: it is never uploaded and never queued, whatever the
/// person ticks. A report about such an exchange can still be made in words
/// of the person's own, outside the app.
abstract final class HadiReportPolicy {
  static bool mayInclude(String text) =>
      CrisisDetector.detect(text) == null &&
      SupportSignal.classify(text) == null &&
      !MinorSignal.isMinor(text);
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
        if (question != null &&
            question!.trim().isNotEmpty &&
            HadiReportPolicy.mayInclude(question!))
          'question': _cap(question!.trim(), 500),
        'sources': sources.take(5).toList(),
        'live': live,
      };
}

/// Sends a report to Firestore when Firebase is running; otherwise keeps it
/// in a small queue on the device (at most [maxQueued]) and sends it the next
/// time the app starts with a connection to the project ([flush]).
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

  /// Sends one report document. Throws when Firebase is not running or the
  /// write is refused.
  static Future<void> _send(Map<String, Object?> doc) async {
    if (Firebase.apps.isEmpty) throw StateError('Firebase is not running');
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
    await FirebaseFirestore.instance.collection('hadi_reports').add(
      <String, Object?>{...doc, 'createdAt': FieldValue.serverTimestamp()},
    );
  }

  /// Returns true when the report reached Firestore, false when it was kept
  /// on the device (it is sent later by [flush]).
  Future<bool> submit(HadiReport r) async {
    // Support and crisis text never leaves the device, not even in a queue.
    if (!HadiReportPolicy.mayInclude(r.answer)) return false;
    try {
      await _send(r.toMap());
      return true;
    } catch (_) {
      // Fall through to the device queue.
    }
    try {
      await _enqueue(r);
    } catch (_) {}
    return false;
  }

  /// Sends the reports kept on the device. Called when the app starts with
  /// Firebase running. A report that is sent leaves the queue; one that
  /// fails stays for the next start. Returns how many were sent. Only the
  /// fields the rules allow are sent ('at' is device-side bookkeeping).
  Future<int> flush() async {
    final List<Map<String, dynamic>> pending = queued;
    bool running;
    try {
      running = Firebase.apps.isNotEmpty;
    } catch (_) {
      running = false;
    }
    if (pending.isEmpty || !running) return 0;
    final List<Map<String, dynamic>> left = <Map<String, dynamic>>[];
    int sent = 0;
    for (final Map<String, dynamic> e in pending) {
      final String answer = (e['answer'] ?? '').toString();
      final String? question = e['question']?.toString();
      // A report queued by an older version may hold text that must not go.
      if (!HadiReportPolicy.mayInclude(answer)) continue;
      try {
        await _send(<String, Object?>{
          'reason': e['reason'],
          'answer': e['answer'],
          if (question != null && HadiReportPolicy.mayInclude(question))
            'question': e['question'],
          'sources': e['sources'] ?? <dynamic>[],
          'live': e['live'] ?? false,
        });
        sent++;
      } catch (_) {
        left.add(e);
      }
    }
    try {
      if (left.isEmpty) {
        await _prefs.remove(queuePref);
      } else {
        await _prefs.setString(queuePref, json.encode(left));
      }
    } catch (_) {}
    return sent;
  }
}
