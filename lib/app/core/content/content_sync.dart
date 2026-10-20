import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart' show kReleaseMode, visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Content Sync — Ar-Rayaan's live content layer.
///
/// GitHub's raw file service acts as the content server (the repo is public,
/// reads are free and keyless). On launch, release builds read
/// `assets/content_manifest.json`; a pack whose manifest version is higher
/// than what the device already holds is downloaded and used only if it
/// passes every check in [ContentIntegrity]:
///
///  * the path is on the allowlist (no arbitrary file names),
///  * the body's SHA-256 equals the manifest's digest (catches truncation
///    and a pack pushed without its manifest entry),
///  * it parses as JSON of the same shape as the bundled copy,
///  * it is not drastically smaller than the bundled copy (a failing or
///    emptied pack must never replace shipped religious content).
///
/// The last pack that passed is kept on-device as the last-known-good copy
/// and is re-checked on every launch. Offline, on any failure, or when the
/// app ships newer bundled content, the bundled copy is used — the app
/// never shows a dead screen because of a network.
///
/// This is integrity, not authenticity: the manifest comes from the same
/// repository as the packs. Content still needs human review before it is
/// merged to `main`.
///
/// Debug/test builds always use the bundled assets so tests stay hermetic.
class ContentSync {
  static const remoteBase =
      'https://raw.githubusercontent.com/agkautobody-design/ar-rayaan/main/assets';

  static ContentManifest? _manifest;

  /// Loads the content at `assets/<assetPath>`.
  static Future<String> load(String assetPath) async {
    final bundled = await rootBundle.loadString('assets/$assetPath');
    if (!kReleaseMode) return bundled;
    return loadWith(
      assetPath: assetPath,
      bundled: bundled,
      client: http.Client(),
    );
  }

  /// The release-mode path, with its collaborators injected so tests can
  /// drive every outcome.
  @visibleForTesting
  static Future<String> loadWith({
    required String assetPath,
    required String bundled,
    required http.Client client,
    SharedPreferences? prefs,
    bool useMemoizedManifest = false,
  }) async {
    SharedPreferences? p = prefs;
    try {
      p ??= await SharedPreferences.getInstance();
    } catch (_) {
      return bundled;
    }
    final bundledSha = ContentIntegrity.sha256Of(utf8.encode(bundled));
    final good = _lastKnownGood(p, assetPath, bundled, bundledSha);

    try {
      if (!ContentIntegrity.isAllowedPath(assetPath)) return good ?? bundled;
      final manifest = await _fetchManifest(client, useMemoizedManifest);
      final entry = manifest?.files[assetPath];
      if (entry == null) return good ?? bundled;

      final localVer = good == null ? 0 : (p.getInt('cv_$assetPath') ?? 0);
      if (entry.version <= localVer) return good ?? bundled;

      final res = await client
          .get(Uri.parse('$remoteBase/$assetPath'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return good ?? bundled;
      final problem = ContentIntegrity.check(
        path: assetPath,
        bodyBytes: res.bodyBytes,
        bundled: bundled,
        expectedSha256: entry.sha256,
      );
      if (problem != null) return good ?? bundled;

      final body = utf8.decode(res.bodyBytes);
      await p.setString('cp_$assetPath', body);
      await p.setInt('cv_$assetPath', entry.version);
      await p.setString('cb_$assetPath', bundledSha);
      return body;
    } catch (_) {
      // Offline / GitHub down / malformed — last-known-good or bundle.
      return good ?? bundled;
    }
  }

  /// The cached pack, if it is still trustworthy: it was stored against the
  /// same bundled content as this build ships, and it still passes the
  /// shape and size checks. Anything else is dropped.
  static String? _lastKnownGood(
    SharedPreferences p,
    String assetPath,
    String bundled,
    String bundledSha,
  ) {
    try {
      final cached = p.getString('cp_$assetPath');
      if (cached == null || cached.isEmpty) return null;
      final storedAgainst = p.getString('cb_$assetPath');
      final ok = storedAgainst == bundledSha &&
          ContentIntegrity.checkShape(
                path: assetPath,
                body: cached,
                bundled: bundled,
              ) ==
              null;
      if (ok) return cached;
      p.remove('cp_$assetPath');
      p.remove('cv_$assetPath');
      p.remove('cb_$assetPath');
    } catch (_) {}
    return null;
  }

  static Future<ContentManifest?> _fetchManifest(
    http.Client client,
    bool memoize,
  ) async {
    if (memoize && _manifest != null) return _manifest;
    final res = await client
        .get(Uri.parse('$remoteBase/content_manifest.json'))
        .timeout(const Duration(seconds: 6));
    if (res.statusCode != 200) return null;
    final m = ContentManifest.parse(utf8.decode(res.bodyBytes));
    if (memoize) _manifest = m;
    return m;
  }

  @visibleForTesting
  static void resetForTest() => _manifest = null;
}

/// One pack's entry in `content_manifest.json`.
class ManifestEntry {
  const ManifestEntry({
    required this.version,
    required this.sha256,
    this.bytes,
  });

  final int version;
  final String sha256;
  final int? bytes;
}

/// `assets/content_manifest.json`: `{ "schema": 1, "files": { path: {...} } }`
/// (generated by `tool/gen_content_manifest.py`).
class ContentManifest {
  const ContentManifest(this.files);

  final Map<String, ManifestEntry> files;

  /// Returns null unless the document is a well-formed schema-1 manifest.
  /// Entries that are malformed or whose path is not allowed are skipped.
  static ContentManifest? parse(String source) {
    try {
      final dynamic root = json.decode(source);
      if (root is! Map<String, dynamic>) return null;
      if (root['schema'] != 1) return null;
      final dynamic files = root['files'];
      if (files is! Map<String, dynamic>) return null;
      final out = <String, ManifestEntry>{};
      for (final e in files.entries) {
        final dynamic v = e.value;
        if (v is! Map<String, dynamic>) continue;
        final dynamic ver = v['version'];
        final dynamic sha = v['sha256'];
        if (ver is! int || sha is! String) continue;
        if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(sha)) continue;
        if (!ContentIntegrity.isAllowedPath(e.key)) continue;
        final dynamic bytes = v['bytes'];
        out[e.key] = ManifestEntry(
          version: ver,
          sha256: sha,
          bytes: bytes is int ? bytes : null,
        );
      }
      return ContentManifest(out);
    } catch (_) {
      return null;
    }
  }
}

/// The checks a downloaded or cached pack must pass. Pure functions, so they
/// are tested directly.
class ContentIntegrity {
  const ContentIntegrity._();

  /// Directories that may carry remotely updated packs.
  static const Set<String> allowedDirs = <String>{
    'stories',
    'family',
    'guides',
    'games',
    'feelings',
    'share',
    'finance',
    'system',
    'qa',
    'academy',
  };

  /// A pack must be at least this fraction of the bundled copy's weight.
  static const double minRetainedFraction = 0.7;

  static final RegExp _pathPattern = RegExp(r'^[a-z0-9_]+(/[a-z0-9_]+)*\.json$');

  static bool isAllowedPath(String path) {
    if (path.contains('..') || path.startsWith('/')) return false;
    if (!_pathPattern.hasMatch(path)) return false;
    return allowedDirs.contains(path.split('/').first) && path.contains('/');
  }

  static String sha256Of(List<int> bytes) =>
      crypto.sha256.convert(bytes).toString();

  /// Number of nodes in a decoded JSON tree: a stable measure of how much
  /// content a pack holds, regardless of formatting.
  static int weight(Object? node) {
    if (node is List<dynamic>) {
      var n = 1;
      for (final dynamic c in node) {
        n += weight(c);
      }
      return n;
    }
    if (node is Map<String, dynamic>) {
      var n = 1;
      for (final dynamic c in node.values) {
        n += weight(c);
      }
      return n;
    }
    return 1;
  }

  /// Full check for a freshly downloaded pack. Returns null when it may be
  /// used, otherwise a short reason.
  static String? check({
    required String path,
    required List<int> bodyBytes,
    required String bundled,
    required String expectedSha256,
  }) {
    if (!isAllowedPath(path)) return 'path not allowed';
    if (bodyBytes.isEmpty) return 'empty body';
    if (sha256Of(bodyBytes) != expectedSha256.toLowerCase()) {
      return 'sha256 mismatch';
    }
    final String body;
    try {
      body = utf8.decode(bodyBytes);
    } catch (_) {
      return 'not utf-8';
    }
    return checkShape(path: path, body: body, bundled: bundled);
  }

  /// Schema and shrink checks against the bundled copy.
  static String? checkShape({
    required String path,
    required String body,
    required String bundled,
  }) {
    final dynamic candidate;
    try {
      candidate = json.decode(body);
    } catch (_) {
      return 'invalid json';
    }
    if (candidate == null) return 'null document';
    dynamic shipped;
    try {
      shipped = json.decode(bundled);
    } catch (_) {
      shipped = null;
    }
    if (shipped == null) return null;
    final bool shippedIsList = shipped is List<dynamic>;
    final bool candidateIsList = candidate is List<dynamic>;
    if (shippedIsList != candidateIsList) return 'top-level shape changed';
    if (shipped is Map<String, dynamic>) {
      if (candidate is! Map<String, dynamic>) return 'top-level shape changed';
      // Every top-level collection the app ships must still be present.
      for (final e in shipped.entries) {
        final dynamic was = e.value;
        final dynamic now = candidate[e.key];
        if (was is List<dynamic> && now is! List<dynamic>) {
          return 'missing section ${e.key}';
        }
        if (was is Map<String, dynamic> && now is! Map<String, dynamic>) {
          return 'missing section ${e.key}';
        }
      }
    }
    final shippedWeight = weight(shipped);
    final candidateWeight = weight(candidate);
    if (shippedWeight > 8 &&
        candidateWeight < (shippedWeight * minRetainedFraction)) {
      return 'pack shrank from $shippedWeight to $candidateWeight';
    }
    return null;
  }
}
