import '../domain/hadith_models.dart';

/// Hadith collection contract. Bundled today (Forty of an-Nawawi);
/// Riyad as-Salihin drops in at this seam when its dataset lands (O-5).
abstract interface class HadithRepository {
  Future<List<Hadith>> collection();
}
