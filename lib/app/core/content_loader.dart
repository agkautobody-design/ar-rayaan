import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'asset_text_cache.dart';
import 'asset_text_cache_stub.dart'
    if (dart.library.js_interop) 'asset_text_cache_web.dart';

/// Loads a bundled text file, keeping a copy on the device in the browser.
///
/// On the web a bundled asset is a network request every time. The first
/// load is fetched and stored; every later one, including with no
/// connection, comes from the stored copy. (`web/ar_sw.js` keeps the app's
/// own shell separately, network first, so the app can reopen offline.) On Android and iPhone the file is
/// inside the app and this is a plain `rootBundle.loadString`.
abstract final class ContentLoader {
  /// Replaced in tests.
  static AssetTextCache cache = createPlatformAssetCache();

  /// Counts the times the Qur'an's main file was stored. The Home Qur'an
  /// tile and the Qur'an screen listen to it, so "Needs internet the first
  /// time" disappears as soon as the text is on the device instead of
  /// waiting for the screen to be rebuilt.
  static final ValueNotifier<int> quranStoredRevision = ValueNotifier<int>(0);

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
      if (key == kQuranAsset) quranStoredRevision.value++;
    } catch (_) {
      // Not stored; still usable now.
    }
    return raw;
  }

  /// Forgets the stored copy of [key] (browser only; a no-op on the phone
  /// apps, where the file is inside the install).
  static Future<void> remove(String key) async {
    final Object c = cache;
    if (c is RemovableAssetCache) {
      try {
        await c.remove(key);
      } catch (_) {}
    }
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
    FutureProvider.autoDispose<bool>((ref) {
      void recheck() => ref.invalidateSelf();
      ContentLoader.quranStoredRevision.addListener(recheck);
      ref.onDispose(
        () => ContentLoader.quranStoredRevision.removeListener(recheck),
      );
      return ContentLoader.isAvailableOffline(kQuranAsset);
    });

/// Text for the Home Qur'an tile. When [offlineReady] is explicitly false
/// (never while still unknown) the tile says so INSTEAD of its usual line: a
/// tile subtitle holds two short lines, and the warning used to be appended
/// and cut off by the ellipsis on phones.
String quranTileSubtitle(String base, {required bool? offlineReady}) =>
    offlineReady == false ? kQuranNeedsInternetNote : base;

/// The tile's first-time warning (short enough for two lines on a phone).
const String kQuranNeedsInternetNote = 'Needs internet the first time';
