import 'dart:js_interop';

import '../../academy/domain/recitation_audio.dart';
import 'audio_file_store.dart';

/// The browser's Cache Storage (`window.caches`), declared here directly so
/// this file depends on nothing but `dart:js_interop`.
@JS('caches')
external _CacheStorage? get _cacheStorage;

extension type _CacheStorage._(JSObject _) implements JSObject {
  external JSPromise<_Cache> open(JSString name);
}

extension type _Cache._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> add(JSString url);
  external JSPromise<_Resp?> match(JSString url);
  external JSPromise<JSBoolean> delete(JSString url);
  external JSPromise<JSArray<_Req>> keys();
}

extension type _Req._(JSObject _) implements JSObject {
  external JSString get url;
}

extension type _Resp._(JSObject _) implements JSObject {
  external JSPromise<JSObject> blob();
}

@JS('URL.createObjectURL')
external JSString _createObjectUrl(JSObject blob);

@JS('URL.revokeObjectURL')
external void _revokeObjectUrl(JSString url);

/// Recitation saved in the browser, in a cache named `ar-dl-audio-v1`. The
/// page's cache clean-up on a new build leaves caches starting with `ar-dl-`
/// alone (recorded audio does not change with the app version).
///
/// Needs https (or localhost) and site data that is not blocked; otherwise
/// [supported] is false and every call quietly does nothing.
class WebAudioFileStore implements AudioFileStore {
  WebAudioFileStore();

  static const String _name = 'ar-dl-audio-v1';

  /// Temporary addresses handed to the player; the oldest are released so
  /// they do not pile up over a long listening session.
  final List<String> _live = <String>[];

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
  bool get supported {
    try {
      return _cacheStorage != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Set<String>> storedFiles(ReciterPack pack) async {
    try {
      final _Cache? c = await _open();
      if (c == null) return <String>{};
      final List<_Req> keys = (await c.keys().toDart).toDart;
      final String prefix = '${pack.ayahBaseUrl}/';
      final Set<String> out = <String>{};
      for (final _Req k in keys) {
        final String u = k.url.toDart;
        if (u.startsWith(prefix)) out.add(u.substring(prefix.length));
      }
      return out;
    } catch (_) {
      return <String>{};
    }
  }

  @override
  Future<SaveOutcome> save(ReciterPack pack, AyahRef ref) async {
    try {
      final _Cache? c = await _open();
      if (c == null) return SaveOutcome.failed;
      final JSString url = pack.ayahUrl(ref).toJS;
      if (await c.match(url).toDart != null) return SaveOutcome.stored;
      // add() fetches the file and keeps it; it rejects on a failed request
      // or a full store.
      await c.add(url).toDart;
      return await c.match(url).toDart != null
          ? SaveOutcome.stored
          : SaveOutcome.failed;
    } catch (e) {
      return e.toString().contains('Quota')
          ? SaveOutcome.storageFull
          : SaveOutcome.failed;
    }
  }

  @override
  Future<void> remove(ReciterPack pack, Iterable<AyahRef> refs) async {
    try {
      final _Cache? c = await _open();
      if (c == null) return;
      for (final AyahRef r in refs) {
        try {
          await c.delete(pack.ayahUrl(r).toJS).toDart;
        } catch (_) {}
      }
    } catch (_) {}
  }

  @override
  Future<String?> playable(ReciterPack pack, AyahRef ref) async {
    try {
      final _Cache? c = await _open();
      if (c == null) return null;
      final _Resp? r = await c.match(pack.ayahUrl(ref).toJS).toDart;
      if (r == null) return null;
      final JSObject blob = await r.blob().toDart;
      final String url = _createObjectUrl(blob).toDart;
      _live.add(url);
      while (_live.length > 6) {
        _revokeObjectUrl(_live.removeAt(0).toJS);
      }
      return url;
    } catch (_) {
      return null;
    }
  }
}

AudioFileStore createPlatformAudioStore() => WebAudioFileStore();

/// A browser cannot tell Wi-Fi from mobile data reliably.
Future<bool?> platformOnWifi() async => null;

const bool platformCanDetectWifi = false;
