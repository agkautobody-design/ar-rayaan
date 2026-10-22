import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/app/core/content/content_sync.dart';
import 'package:ar_rayaan/app/core/storage/safe_prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _path = 'stories/prophets.json';

String _pack(int n, {bool withTitle = true}) =>
    json.encode(<dynamic>[
      for (var i = 0; i < n; i++)
        <String, dynamic>{
          'id': 'p$i',
          if (withTitle) 'title': 'Story $i',
          'chapters': <dynamic>[
            <String, dynamic>{'heading': 'h$i', 'body': 'b$i'},
          ],
        },
    ]);

String _manifest(String body, {int version = 5}) =>
    json.encode(<String, dynamic>{
      'schema': 1,
      'files': <String, dynamic>{
        _path: <String, dynamic>{
          'version': version,
          'sha256': ContentIntegrity.sha256Of(utf8.encode(body)),
        },
      },
    });

MockClient _server(String body, {int version = 5}) {
  return MockClient((http.Request r) async {
    if (r.url.path.endsWith('content_manifest.json')) {
      return http.Response.bytes(
          utf8.encode(_manifest(body, version: version)), 200);
    }
    if (r.url.path.endsWith(_path)) {
      return http.Response.bytes(utf8.encode(body), 200);
    }
    return http.Response('nope', 404);
  });
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    ContentSync.resetForTest();
  });

  group('remote packs can not touch what gates features', () {
    test('system/ is not an allowed remote path', () {
      expect(
          ContentIntegrity.isAllowedPath('system/module_registry.json'), isFalse);
      expect(
          ContentIntegrity.isAllowedPath('system/subscription.json'), isFalse);
      expect(ContentIntegrity.allowedDirs.contains('system'), isFalse);
    });

    test('a manifest row for system/ is ignored', () {
      final m = ContentManifest.parse(json.encode(<String, dynamic>{
        'schema': 1,
        'files': <String, dynamic>{
          'system/module_registry.json': <String, dynamic>{
            'version': 99,
            'sha256': 'a' * 64,
          },
          _path: <String, dynamic>{'version': 1, 'sha256': 'b' * 64},
        },
      }));
      expect(m!.files.keys, <String>[_path]);
    });

    test('loadWith never fetches system/module_registry.json', () async {
      var fetched = false;
      final c = MockClient((_) async {
        fetched = true;
        return http.Response('{}', 200);
      });
      const bundled = '{"modules": []}';
      final got = await ContentSync.loadWith(
        assetPath: 'system/module_registry.json',
        bundled: bundled,
        client: c,
        prefs: await SharedPreferences.getInstance(),
      );
      expect(got, bundled);
      expect(fetched, isFalse);
    });

    test('the shipped manifest and version file carry no system/ rows', () {
      final m = json.decode(
              File('assets/content_manifest.json').readAsStringSync())
          as Map<String, dynamic>;
      final v = json.decode(
              File('assets/content_version.json').readAsStringSync())
          as Map<String, dynamic>;
      expect(
          (m['files'] as Map<String, dynamic>)
              .keys
              .where((String k) => k.startsWith('system/')),
          isEmpty);
      expect(v.keys.where((String k) => k.startsWith('system/')), isEmpty);
    });

    test('no code loads system/ through ContentSync', () {
      final offenders = <String>[];
      for (final f in Directory('lib').listSync(recursive: true)) {
        if (f is! File || !f.path.endsWith('.dart')) continue;
        final src = f.readAsStringSync();
        if (RegExp(r'''ContentSync\s*\.\s*load\w*\s*(<[^>]*>)?\(\s*['"]system/''')
            .hasMatch(src)) {
          offenders.add(f.path);
        }
      }
      expect(offenders, isEmpty);
    });
  });

  group('ContentSync with a drifted remote pack', () {
    test('a pack whose items lost a key never replaces the bundled one',
        () async {
      final bundled = _pack(6);
      final remote = _pack(8, withTitle: false);
      final got = await ContentSync.loadWith(
        assetPath: _path,
        bundled: bundled,
        client: _server(remote),
        prefs: await SharedPreferences.getInstance(),
      );
      expect(got, bundled);
    });
  });

  group('storage that is full or blocked', () {
    test('a verified pack still serves this session and is not re-downloaded',
        () async {
      ContentSync.storeOverride = (p, path, body, version, sha) async => false;
      final bundled = _pack(6);
      final remote = _pack(8);
      var packFetches = 0;
      final c = MockClient((http.Request r) async {
        if (r.url.path.endsWith('content_manifest.json')) {
          return http.Response.bytes(utf8.encode(_manifest(remote)), 200);
        }
        packFetches++;
        return http.Response.bytes(utf8.encode(remote), 200);
      });
      final prefs = await SharedPreferences.getInstance();
      Future<String> run() => ContentSync.loadWith(
            assetPath: _path,
            bundled: bundled,
            client: c,
            prefs: prefs,
          );
      expect(await run(), remote);
      expect(await run(), remote);
      expect(packFetches, 1);
      expect(prefs.getString('cp_$_path'), isNull);
    });

    test('a store that throws is survived', () async {
      ContentSync.storeOverride = (p, path, body, version, sha) =>
          Future<bool>.error(StateError('QuotaExceededError'));
      final bundled = _pack(6);
      final remote = _pack(8);
      final got = await ContentSync.loadWith(
        assetPath: _path,
        bundled: bundled,
        client: _server(remote),
        prefs: await SharedPreferences.getInstance(),
      );
      expect(got, remote);
    });
  });

  group('parseOrFallback', () {
    test('uses the first copy when it parses', () {
      expect(
        ContentSync.parseOrFallback<int>('1', '2', int.parse),
        1,
      );
    });

    test('falls back to the bundled copy and reports the rejection', () {
      var rejected = 0;
      final got = ContentSync.parseOrFallback<int>(
        'not a number',
        '7',
        int.parse,
        onRejected: () => rejected++,
      );
      expect(got, 7);
      expect(rejected, 1);
    });

    test('rethrows when the bundled copy is the bad one', () {
      expect(
        () => ContentSync.parseOrFallback<int>('x', 'x', int.parse),
        throwsFormatException,
      );
    });
  });

  group('reportRejected', () {
    test('drops the cached pack and skips that version next time', () async {
      final bundled = _pack(6);
      final remote = _pack(8);
      final prefs = await SharedPreferences.getInstance();
      await ContentSync.loadWith(
        assetPath: _path,
        bundled: bundled,
        client: _server(remote),
        prefs: prefs,
      );
      expect(prefs.getString('cp_$_path'), remote);
      await ContentSync.reportRejected(_path);
      final after = await SharedPreferences.getInstance();
      expect(after.getString('cp_$_path'), isNull);
      expect(after.getInt('cx_$_path'), 5);
      var fetched = false;
      final c = MockClient((http.Request r) async {
        if (r.url.path.endsWith('content_manifest.json')) {
          return http.Response.bytes(utf8.encode(_manifest(remote)), 200);
        }
        fetched = true;
        return http.Response.bytes(utf8.encode(remote), 200);
      });
      ContentSync.resetForTest();
      final got = await ContentSync.loadWith(
        assetPath: _path,
        bundled: bundled,
        client: c,
        prefs: after,
      );
      expect(got, bundled);
      expect(fetched, isFalse);
      // A newer manifest version is tried again.
      ContentSync.resetForTest();
      final newer = await ContentSync.loadWith(
        assetPath: _path,
        bundled: bundled,
        client: _server(remote, version: 6),
        prefs: after,
      );
      expect(newer, remote);
    });
  });

  group('SafePrefs', () {
    test('opens normally when storage works', () async {
      SafePrefs.fellBack = false;
      final p = await SafePrefs.open();
      await p.setString('k', 'v');
      expect(p.getString('k'), 'v');
      expect(SafePrefs.fellBack, isFalse);
    });

    test('falls back to memory when storage throws, and the app can go on',
        () async {
      SafePrefs.fellBack = false;
      final p = await SafePrefs.open(
        loader: () async => throw StateError('SecurityError: storage blocked'),
      );
      expect(SafePrefs.fellBack, isTrue);
      await p.setBool('ar.onboarded.v1', true);
      expect(p.getBool('ar.onboarded.v1'), isTrue);
      // Later getInstance() calls elsewhere in the app keep working too.
      final again = await SharedPreferences.getInstance();
      expect(again.getBool('ar.onboarded.v1'), isTrue);
      SafePrefs.fellBack = false;
    });
  });
}
