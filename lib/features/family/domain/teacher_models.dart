/// Teacher domain: reviews, submissions, and parent-teacher chat.

class Submission {
  const Submission({
    required this.id,
    required this.childUid,
    required this.childName,
    required this.lessonId,
    required this.lessonTitle,
    required this.submittedAt,
    this.answers,
    this.timeSpentMinutes,
    this.status = 'pending',
  });

  final String id;
  final String childUid;
  final String childName;
  final String lessonId;
  final String lessonTitle;
  final DateTime submittedAt;
  final List<Map<String, dynamic>>? answers;
  final int? timeSpentMinutes;
  final String status; // 'pending', 'reviewed'

  Map<String, dynamic> toJson() => {
    'id': id,
    'childUid': childUid,
    'childName': childName,
    'lessonId': lessonId,
    'lessonTitle': lessonTitle,
    'submittedAt': submittedAt.toIso8601String(),
    if (answers != null) 'answers': answers,
    if (timeSpentMinutes != null) 'timeSpentMinutes': timeSpentMinutes,
    'status': status,
  };

  factory Submission.fromJson(Map<String, dynamic> j) => Submission(
    id: j['id'] as String,
    childUid: j['childUid'] as String,
    childName: j['childName'] as String,
    lessonId: j['lessonId'] as String,
    lessonTitle: j['lessonTitle'] as String,
    submittedAt: DateTime.parse(j['submittedAt'] as String),
    answers: (j['answers'] as List<dynamic>?)
        ?.map((e) => e as Map<String, dynamic>)
        .toList(),
    timeSpentMinutes: j['timeSpentMinutes'] as int?,
    status: j['status'] as String? ?? 'pending',
  );
}

class TeacherReview {
  const TeacherReview({
    required this.id,
    required this.submissionId,
    required this.childUid,
    required this.teacherUid,
    required this.teacherName,
    required this.reviewedAt,
    this.score,
    this.feedback,
    this.strengths,
    this.improvements,
  });

  final String id;
  final String submissionId;
  final String childUid;
  final String teacherUid;
  final String teacherName;
  final DateTime reviewedAt;
  final int? score;
  final String? feedback;
  final List<String>? strengths;
  final List<String>? improvements;

  Map<String, dynamic> toJson() => {
    'id': id,
    'submissionId': submissionId,
    'childUid': childUid,
    'teacherUid': teacherUid,
    'teacherName': teacherName,
    'reviewedAt': reviewedAt.toIso8601String(),
    if (score != null) 'score': score,
    if (feedback != null) 'feedback': feedback,
    if (strengths != null) 'strengths': strengths,
    if (improvements != null) 'improvements': improvements,
  };

  factory TeacherReview.fromJson(Map<String, dynamic> j) => TeacherReview(
    id: j['id'] as String,
    submissionId: j['submissionId'] as String,
    childUid: j['childUid'] as String,
    teacherUid: j['teacherUid'] as String,
    teacherName: j['teacherName'] as String,
    reviewedAt: DateTime.parse(j['reviewedAt'] as String),
    score: j['score'] as int?,
    feedback: j['feedback'] as String?,
    strengths: (j['strengths'] as List<dynamic>?)?.cast<String>(),
    improvements: (j['improvements'] as List<dynamic>?)?.cast<String>(),
  );
}

class TeacherMessage {
  const TeacherMessage({
    required this.id,
    required this.senderUid,
    required this.senderRole,
    required this.text,
    required this.sentAt,
    this.childId,
  });

  final String id;
  final String senderUid;
  final String senderRole; // 'parent' or 'teacher'
  final String text;
  final DateTime sentAt;
  final String? childId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderUid': senderUid,
    'senderRole': senderRole,
    'text': text,
    'sentAt': sentAt.toIso8601String(),
    if (childId != null) 'childId': childId,
  };

  factory TeacherMessage.fromJson(Map<String, dynamic> j) => TeacherMessage(
    id: j['id'] as String,
    senderUid: j['senderUid'] as String,
    senderRole: j['senderRole'] as String,
    text: j['text'] as String,
    sentAt: DateTime.parse(j['sentAt'] as String),
    childId: j['childId'] as String?,
  );
}
