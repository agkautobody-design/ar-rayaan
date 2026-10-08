
// Contract lock for the Player catalog pack loader (1b.5 prep).
// Only the empty-checksum branch is testable today: kCatalogSha256 is
// compile-time '' and Pack 1 has not shipped, so load() must return null
// BEFORE touching the asset bundle. The full-pack branches (asset present,
// checksum match -> Catalog; mismatch -> StateError, same house contract as
// mushaf_layout_pack) unlock when Pack 1 lands and the checksum is filled.
import 'package:ar_rayaan/features/academy/data/player_catalog_pack.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('empty checksum hides the catalog until an authentic pack ships', () async {
    expect(kCatalogSha256, isEmpty);
    final Object? catalog = await PlayerCatalogPack.load();
    expect(catalog, isNull);
  });
}
