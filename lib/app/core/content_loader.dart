import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'asset_text_cache.dart';
import 'asset_text_cache_stub.dart'
    if (dart.library.js_interop) 'asset_text_cache_web.dart';

/// Loads a bundled text file, keeping a copy on the device in the browser.
///
/// On the web a bundled asset is a network request every time (the service
/// worker is intentionally a self-removing stub, see `web/index.html`). The
/// first load is fetched and stored; every later one, including with no
/// connection, comes from the stored copy. On Android and iPhone the file is
/// inside the app and this is a plain `rootBundle.loadString`.
abstract final class ContentLoader {
  /// Replaced in tests.
  static AssetTextCache cache = createPlatformAssetCache();

  static Future<String> loadString(String key, {AssetBundle? bundle}) async {
    try {
      final String? hit = await cache.read(key);
      if (hit != null) return hit;
    } catch (_) {
      // Unreadable cache: fetch normally.
    }
    final String raw = await (bundle ?? rootBundle).loadString(key);
    try {
      await cache.write(key, raw);
    } catch (_) {
      // Not stored; still usable now.
    }
    return raw;
  }

  /// True when [key] opens with no connection: always on the native apps,
  /// and in the browser only once it has been stored by [loadString].
  static Future<bool> isAvailableOffline(String key) async {
    if (!cache.persistent) return true;
    try {
      return await cache.has(key);
    } catch (_) {
      return false;
    }
  }
}

/// The Qur'an's one data file (Arabic, English and transliteration).
const String kQuranAsset = 'assets/quran/quran.json';

/// Rough download size of [kQuranAsset], for the first-load message.
const String kQuranSizeHint = 'about 2 MB';

/// Whether the Qur'an opens without internet. Re-checked each time a screen
/// that shows it is built fresh; does not start loading the Qur'an itself.
final AutoDisposeFutureProvider<bool> quranOfflineReadyProvider =
    FutureProvider.autoDispose<bool>(
      (ref) => ContentLoader.isAvailableOffline(kQuranAsset),
    );

/// Text for the Home Qur'an tile. Adds the first-time internet note only
/// when [offlineReady] is explicitly false (never while still unknown).
String quranTileSubtitle(String base, {required bool? offlineReady}) =>
    offlineReady == false ? '$base · Needs internet the first time' : base;
