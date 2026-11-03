import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/teacher_repository.dart';
import '../domain/teacher_models.dart';

final Provider<TeacherRepository> teacherRepositoryProvider =
    Provider<TeacherRepository>((ref) => FirebaseTeacherRepository());

final StreamProviderFamily<List<Submission>, String> pendingSubmissionsProvider =
    StreamProvider.family<List<Submission>, String>((ref, teacherUid) {
  return ref.watch(teacherRepositoryProvider).watchPendingSubmissions(teacherUid);
});

final StreamProviderFamily<List<TeacherReview>, String> childReviewsProvider =
    StreamProvider.family<List<TeacherReview>, String>((ref, childUid) {
  return ref.watch(teacherRepositoryProvider).watchReviewsForChild(childUid);
});

final StreamProviderFamily<List<TeacherMessage>, String> teacherChatProvider =
    StreamProvider.family<List<TeacherMessage>, String>((ref, chatId) {
  return ref.watch(teacherRepositoryProvider).watchChat(chatId);
});
