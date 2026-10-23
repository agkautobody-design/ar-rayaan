/// A small on-device copy of bundled text files (the Qur'an, hadith, story
/// packs), so that a library fetched once keeps opening with no connection.
///
/// Only the browser needs this. The Android and iPhone apps carry the files
/// inside the install, so their implementation is a no-op ([persistent] is
/// false). See `asset_text_cache_web.dart` for the browser version.
abstract interface class AssetTextCache {
  /// True when this cache really stores text between visits (browser only).
  bool get persistent;

  /// The stored text for [key], or null when it was never stored.
  Future<String?> read(String key);

  /// Stores [text] under [key]. Failures are swallowed by the implementation.
  Future<void> write(String key, String text);

  /// Whether [key] is stored.
  Future<bool> has(String key);
}
