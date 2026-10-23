import 'asset_text_cache.dart';

/// Non-web: the files ship inside the app, nothing to cache.
class _NoCache implements AssetTextCache {
  const _NoCache();

  @override
  bool get persistent => false;

  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String text) async {}

  @override
  Future<bool> has(String key) async => false;
}

AssetTextCache createPlatformAssetCache() => const _NoCache();
