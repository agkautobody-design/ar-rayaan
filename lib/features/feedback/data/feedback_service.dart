import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A feedback message the policy refused before it left the device.
/// [message] is safe to show to the person.
class FeedbackRejected implements Exception {
  const FeedbackRejected(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Beta feedback: "something is broken / missing / confusing".
///
/// Unlike community places, feedback may come from someone who never made
/// an account, so the anonymous Firebase sign-in is enough here — a message
/// goes only to the founders' queue, never anywhere public, so the abuse
/// surface is junk documents, which cost a read the founder can ignore.
/// The rules bound every field and stamp the server time.
class FeedbackService {
  FeedbackService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  /// Shown next to feedback so the founders know which build misbehaved.
  /// Bump with pubspec.yaml `version:`.
  static const String appVersion = '0.8.0+8';

  static const int messageMin = 10;
  static const int messageMax = 2000;
  static const int emailMax = 120;
  static const int maxErrors = 20;

  /// Null when the message may be sent, otherwise a message to show.
  static String? validate(String message, String? email) {
    final String t = message.trim();
    if (t.length < messageMin) {
      return 'A few words more, please — what happened, or what is missing?';
    }
    if (t.length > messageMax) {
      return 'Messages can be at most $messageMax characters.';
    }
    final String e = (email ?? '').trim();
    if (e.isNotEmpty && (e.length > emailMax || !e.contains('@'))) {
      return 'That email address does not look right — or leave it empty.';
    }
    return null;
  }

  Future<String> _uid() async {
    User? user = _auth.currentUser;
    user ??= (await _auth.signInAnonymously()).user;
    return user!.uid;
  }

  /// Sends feedback to the founders' queue. [errors] are the app's recent
  /// error notes (type and message only, never user data) when the person
  /// chose to attach them.
  /// Newest feedback — founders only (the rules say so).
  static const int feedbackLimit = 50;

  Stream<QuerySnapshot<Map<String, dynamic>>> feedback() => _db
      .collection('app_feedback')
      .orderBy('createdAt', descending: true)
      .limit(feedbackLimit)
      .snapshots();

  Future<void> send({
    required String message,
    String? email,
    required List<String> errors,
    required String platform,
  }) async {
    final String? problem = validate(message, email);
    if (problem != null) throw FeedbackRejected(problem);
    final String uid = await _uid();
    final List<String> safeErrors = errors
        .map((e) => e.length > 300 ? e.substring(0, 300) : e)
        .take(maxErrors)
        .toList();
    final String e = (email ?? '').trim();
    await _db.collection('app_feedback').add(<String, dynamic>{
      'body': message.trim(),
      if (e.isNotEmpty) 'email': e,
      'errors': safeErrors,
      'platform': platform,
      'appVersion': appVersion,
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
