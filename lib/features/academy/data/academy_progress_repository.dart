import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../app/analytics.dart';

class AcademyProgressEntry {
  const AcademyProgressEntry({
    required this.lessonId,
    required this.lessonTitle,
    required this.completedAt,
    this.score,
    this.timeSpentMinutes,
    this.notes,
  });

  final String lessonId;
  final String lessonTitle;
  final DateTime completedAt;
  final int? score;
  final int? timeSpentMinutes;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'lessonId': lessonId,
    'lessonTitle': lessonTitle,
    'completedAt': completedAt.toIso8601String(),
    if (score != null) 'score': score,
    if (timeSpentMinutes != null) 'timeSpentMinutes': timeSpentMinutes,
    if (notes != null) 'notes': notes,
  };

  factory AcademyProgressEntry.fromJson(Map<String, dynamic> j) => AcademyProgressEntry(
    lessonId: j['lessonId'] as String,
    lessonTitle: j['lessonTitle'] as String,
    completedAt: DateTime.parse(j['completedAt'] as String),
    score: j['score'] as int?,
    timeSpentMinutes: j['timeSpentMinutes'] as int?,
    notes: j['notes'] as String?,
  );
}

abstract interface class AcademyProgressRepository {
  Stream<List<AcademyProgressEntry>> watchProgress(String childUid);
  Future<void> recordProgress(String childUid, AcademyProgressEntry entry);
  Future<AcademyProgressEntry?> getLatestProgress(String childUid);
}

class FirebaseAcademyProgressRepository implements AcademyProgressRepository {
  FirebaseAcademyProgressRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _progress(String childUid) =>
      _firestore.collection('academy_progress').doc(childUid).collection('entries');

  @override
  Stream<List<AcademyProgressEntry>> watchProgress(String childUid) {
    return _progress(childUid)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AcademyProgressEntry.fromJson(d.data()))
            .toList());
  }

  @override
  Future<void> recordProgress(String childUid, AcademyProgressEntry entry) async {
    AppAnalytics.logAcademyLessonCompleted(
      entry.lessonId.split('/').first,
      entry.lessonId,
      entry.score,
    );
    await _progress(childUid).doc(entry.lessonId).set(entry.toJson());
  }

  @override
  Future<AcademyProgressEntry?> getLatestProgress(String childUid) async {
    final snap = await _progress(childUid)
        .orderBy('completedAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return AcademyProgressEntry.fromJson(snap.docs.first.data());
  }
}
