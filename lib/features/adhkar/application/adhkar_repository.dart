import '../domain/adhkar_models.dart';

/// Adhkar collection contract. Bundled (Hisn al-Muslim) today; further
/// categories (sleep, travel, ruqyah…) extend the same asset later.
abstract interface class AdhkarRepository {
  Future<List<AdhkarSet>> sets();
}
