import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/bundled_hadith_repository.dart';
import '../domain/hadith_models.dart';
import 'hadith_repository.dart';

final Provider<HadithRepository> hadithRepositoryProvider =
    Provider<HadithRepository>((ref) => BundledHadithRepository());

/// The full bundled collection (Forty Hadith of an-Nawawi).
final FutureProvider<List<Hadith>> hadithCollectionProvider =
    FutureProvider<List<Hadith>>((ref) {
      return ref.watch(hadithRepositoryProvider).collection();
    });
