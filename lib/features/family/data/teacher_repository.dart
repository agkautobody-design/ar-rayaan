import 'package:cloud_firestore/cloud_firestore.dart';
import 'teacher_models.dart';

abstract interface class TeacherRepository {
  Stream<List<Submission>> watchPendingSubmissions(String teacherUid);
  Stream<List<TeacherReview>> watchReviewsForChild(String childUid);
  Future<void> submitReview(TeacherReview review);
  Future<void> recordSubmission(Submission submission);
  Stream<List<TeacherMessage>> watchChat(String chatId);
  Future<void> sendMessage(String chatId, TeacherMessage message);
}

class FirebaseTeacherRepository implements TeacherRepository {
  FirebaseTeacherRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<Submission>> watchPendingSubmissions(String teacherUid) {
    return _firestore
        .collection('submissions')
        .where('status', isEqualTo: 'pending')
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Submission.fromJson(d.data()))
            .toList());
  }

  @override
  Stream<List<TeacherReview>> watchReviewsForChild(String childUid) {
    return _firestore
        .collection('teacher_reviews')
        .where('childUid', isEqualTo: childUid)
        .orderBy('reviewedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => TeacherReview.fromJson(d.data()))
            .toList());
  }

  @override
  Future<void> submitReview(TeacherReview review) async {
    await _firestore
        .collection('teacher_reviews')
        .doc(review.id)
        .set(review.toJson());
    // Mark submission as reviewed
    await _firestore
        .collection('submissions')
        .doc(review.submissionId)
        .update({'status': 'reviewed'});
  }

  @override
  Future<void> recordSubmission(Submission submission) async {
    await _firestore
        .collection('submissions')
        .doc(submission.id)
        .set(submission.toJson());
  }

  @override
  Stream<List<TeacherMessage>> watchChat(String chatId) {
    return _firestore
        .collection('teacher_parent_chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => TeacherMessage.fromJson(d.data()))
            .toList());
  }

  @override
  Future<void> sendMessage(String chatId, TeacherMessage message) async {
    await _firestore
        .collection('teacher_parent_chats')
        .doc(chatId)
        .collection('messages')
        .doc(message.id)
        .set(message.toJson());
  }
}
