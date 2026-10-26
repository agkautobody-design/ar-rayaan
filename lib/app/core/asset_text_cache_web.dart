import 'dart:js_interop';

import 'asset_text_cache.dart';

/// The browser's Cache Storage (`window.caches`). Declared here directly so
/// this file depends on nothing but `dart:js_interop`.
@JS('caches')
external _CacheStorage? get _cacheStorage;

extension type _CacheStorage._(JSObject _) implements JSObject {
  external JSPromise<_Cache> open(JSString name);
}

extension type _Cache._(JSObject _) implements JSObject {
  external JSPromise<_Resp?> match(JSString url);
  external JSPromise<JSAny?> put(JSString url, _Resp response);
  external JSPromise<JSBoolean> delete(JSString url);
}

@JS('Response')
extension type _Resp._(JSObject _) implements JSObject {
  external _Resp(JSString body);
  external JSPromise<JSString> text();
}

/// Cache Storage under a name of our own. `web/index.html` already deletes
/// every cache whenever a new build is detected, so a stored copy can never
/// outlive the build it came from. Needs https (or localhost); anywhere
/// else every call quietly does nothing and the file is simply fetched.
class _WebCache implements AssetTextCache, RemovableAssetCache {
  const _WebCache();

  static const String _name = 'ar-content-v1';

  /// A same-origin address that is never actually requested; it is only the
  /// key the browser files the text under.
  static String _url(String key) => 'ar-content/$key';

  Future<_Cache?> _open() async {
    try {
      final _CacheStorage? s = _cacheStorage;
      if (s == null) return null;
      return await s.open(_name.toJS).toDart;
    } catch (_) {
      return null;
    }
  }

  @override
  bool get persistent => true;

  @override
  Future<String?> read(String key) async {
    try {
      final _Cache? c = await _open();
      if (c == null) return null;
      final _Resp? r = await c.match(_url(key).toJS).toDart;
      if (r == null) return null;
      return (await r.text().toDart).toDart;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, String text) async {
    try {
      final _Cache? c = await _open();
      if (c == null) return;
      await c.put(_url(key).toJS, _Resp(text.toJS)).toDart;
    } catch (_) {
      // Storage full or blocked: the file is fetched again next time.
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      final _Cache? c = await _open();
      if (c == null) return;
      await c.delete(_url(key).toJS).toDart;
    } catch (_) {}
  }

  @override
  Future<bool> has(String key) async {
    try {
      final _Cache? c = await _open();
      if (c == null) return false;
      return await c.match(_url(key).toJS).toDart != null;
    } catch (_) {
      return false;
    }
  }
}

AssetTextCache createPlatformAssetCache() => const _WebCache();
