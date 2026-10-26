/// Reads translation packs from the bundled assets and from the device's
/// download storage, checks them, and installs new ones.
///
/// Nothing here ever shows unchecked text: a pack that fails any check
/// (schema, 6,236 ayahs, checksum, licence) is ignored, and the reader falls
/// back to the interim translation with an honest label.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/content_loader.dart';
import '../domain/translation_pack.dart';

/// The list of packs bundled with the app (empty until one is imported).
const String kTranslationManifestAsset =
    'assets/quran/translations/manifest.json';

/// A pack someone can choose, without its text.
class TranslationChoice {
  const TranslationChoice({
    required this.id,
    required this.language,
    required this.title,
    required this.version,
    required this.bundled,
  });

  final String id;
  final String language;
  final String title;
  final String version;

  /// True when it ships inside the app; false when it was downloaded.
  final bool bundled;
}

/// Where downloaded packs live on the device.
abstract interface class TranslationPackStore {
  /// The stored pack file for [id], or null.
  Future<String?> read(String id);

  /// Stores [raw] under [id], with enough detail to list it later.
  Future<void> write(TranslationPack pack, String raw);

  /// Packs that have been installed here.
  Future<List<TranslationChoice>> installed();

  Future<void> remove(String id);
}

/// Native: one file per pack in the app's support folder. Web: the browser
/// copy that [ContentLoader] keeps. A small index in SharedPreferences lists
/// what is installed either way.
class DeviceTranslationPackStore implements TranslationPackStore {
  DeviceTranslationPackStore(this._prefs);

  final SharedPreferences? _prefs;

  static const String indexKey = 'ar.quran.translationPacks.v1';

  String _webKey(String id) => 'downloads/translations/$id.json';

  Future<File> _file(String id) async {
    final Directory base = await getApplicationSupportDirectory();
    final Directory dir = Directory('${base.path}/translations');
    await dir.create(recursive: true);
    return File('${dir.path}/$id.json');
  }

  Map<String, dynamic> _index() {
    try {
      final String? raw = _prefs?.getString(indexKey);
      if (raw == null) return <String, dynamic>{};
      final Object? d = jsonDecode(raw);
      return d is Map<String, dynamic> ? d : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  @override
  Future<String?> read(String id) async {
    try {
      if (kIsWeb) return await ContentLoader.cache.read(_webKey(id));
      final File f = await _file(id);
      return await f.exists() ? await f.readAsString() : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(TranslationPack pack, String raw) async {
    if (kIsWeb) {
      await ContentLoader.cache.write(_webKey(pack.id), raw);
    } else {
      await (await _file(pack.id)).writeAsString(raw, flush: true);
    }
    final Map<String, dynamic> idx = _index();
    idx[pack.id] = <String, String>{
      'language': pack.language,
      'title': pack.title,
      'version': pack.version,
    };
    await _prefs?.setString(indexKey, jsonEncode(idx));
  }

  @override
  Future<List<TranslationChoice>> installed() async {
    final Map<String, dynamic> idx = _index();
    final List<TranslationChoice> out = <TranslationChoice>[];
    for (final MapEntry<String, dynamic> e in idx.entries) {
      final Object? v = e.value;
      if (v is! Map<String, dynamic>) continue;
      out.add(
        TranslationChoice(
          id: e.key,
          language: '${v['language']}',
          title: '${v['title']}',
          version: '${v['version']}',
          bundled: false,
        ),
      );
    }
    return out;
  }

  @override
  Future<void> remove(String id) async {
    try {
      if (!kIsWeb) {
        final File f = await _file(id);
        if (await f.exists()) await f.delete();
      }
    } catch (_) {
      // Already gone.
    }
    final Map<String, dynamic> idx = _index()..remove(id);
    await _prefs?.setString(indexKey, jsonEncode(idx));
  }
}

class TranslationPackLoader {
  TranslationPackLoader({
    required this.store,
    Future<String> Function(String key)? loadAsset,
  }) : _loadAsset = loadAsset ?? ContentLoader.loadString;

  final TranslationPackStore store;
  final Future<String> Function(String key) _loadAsset;

  static final RegExp _safeFile = RegExp(r'^[a-z0-9][a-z0-9.\-]*\.json$');

  /// The bundled manifest; empty when absent or unreadable.
  Future<TranslationManifest> manifest() async {
    try {
      return TranslationManifest.parse(
        await _loadAsset(kTranslationManifestAsset),
      );
    } catch (_) {
      return TranslationManifest.empty;
    }
  }

  /// Every pack that can be chosen: bundled ones whose licence is granted,
  /// plus downloaded ones.
  Future<List<TranslationChoice>> available() async {
    final TranslationManifest m = await manifest();
    final List<TranslationChoice> out = <TranslationChoice>[
      for (final TranslationPackEntry e in m.packs)
        if (e.isGranted)
          TranslationChoice(
            id: e.id,
            language: e.language,
            title: e.title,
            version: e.version,
            bundled: true,
          ),
    ];
    try {
      for (final TranslationChoice c in await store.installed()) {
        if (out.every((TranslationChoice o) => o.id != c.id)) out.add(c);
      }
    } catch (_) {
      // Storage unavailable: bundled packs only.
    }
    return out;
  }

  Future<TranslationPack?> _fromAssets(String id) async {
    try {
      final TranslationPackEntry? e = (await manifest()).byId(id);
      if (e == null || !e.isGranted || !_safeFile.hasMatch(e.file)) return null;
      final TranslationPack p = TranslationPack.parse(
        await _loadAsset('$kTranslationPackDir${e.file}'),
      );
      if (p.id != id || p.sha256 != e.sha256) return null;
      return p;
    } catch (_) {
      return null;
    }
  }

  Future<TranslationPack?> _fromStore(String id) async {
    try {
      final String? raw = await store.read(id);
      if (raw == null) return null;
      final TranslationPack p = TranslationPack.parse(raw);
      return p.id == id ? p : null;
    } catch (_) {
      return null;
    }
  }

  /// The pack for [id], or null when none is present and valid. When both a
  /// bundled and a downloaded copy exist, the newer version wins; a tie goes
  /// to the bundled one.
  Future<TranslationPack?> load(String id) async {
    final TranslationPack? bundled = await _fromAssets(id);
    final TranslationPack? downloaded = await _fromStore(id);
    if (bundled == null) return downloaded;
    if (downloaded == null) return bundled;
    return compareVersions(downloaded.version, bundled.version) > 0
        ? downloaded
        : bundled;
  }

  /// Validates [raw] (a pack file the person or a download supplied) and, only
  /// if every check passes, stores it. Throws [TranslationPackException].
  Future<TranslationPack> install(String raw) async {
    final TranslationPack p = TranslationPack.parse(raw);
    await store.write(p, raw);
    return p;
  }
}
