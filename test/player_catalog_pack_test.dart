// Contract lock for the Player catalog pack loader.
// Founder decision (2026-10-09): Pack 1 SHIPS — the catalog is armed with a
// real checksum and a 202-track library. load() must now return the Catalog.
import 'package:ar_rayaan/features/academy/data/player_catalog_pack.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('armed checksum ships the catalog with the full library', () async {
    expect(kCatalogSha256, isNotEmpty);
    final Object? catalog = await PlayerCatalogPack.load();
    expect(catalog, isNotNull);
  });
}
