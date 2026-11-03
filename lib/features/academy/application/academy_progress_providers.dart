import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/academy_progress_repository.dart';

final Provider<AcademyProgressRepository> academyProgressRepositoryProvider =
    Provider<AcademyProgressRepository>((ref) => FirebaseAcademyProgressRepository());

final StreamProviderFamily<List<AcademyProgressEntry>, String> childProgressProvider =
    StreamProvider.family<List<AcademyProgressEntry>, String>((ref, childUid) {
  return ref.watch(academyProgressRepositoryProvider).watchProgress(childUid);
});

final FutureProviderFamily<AcademyProgressEntry?, String> childLatestProgressProvider =
    FutureProvider.family<AcademyProgressEntry?, String>((ref, childUid) {
  return ref.watch(academyProgressRepositoryProvider).getLatestProgress(childUid);
});
