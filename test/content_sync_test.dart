import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/app/core/content/content_sync.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _path = 'stories/prophets.json';

String _pack(int n) => json.encode(<String, dynamic>{
      'stories': <dynamic>[
        for (var i = 0; i < n; i++) <String, dynamic>{'id': i, 'text': 'story $i'},
      ],
    });

String _manifest(String body, {int version = 5, String? sha}) =>
    json.encode(<String, dynamic>{
      'schema': 1,
      'files': <String, dynamic>{
        _path: <String, dynamic>{
          'version': version,
          'sha256': sha ?? ContentIntegrity.sha256Of(utf8.encode(body)),
        },
      },
    });

MockClient _server({required String manifest, required String body}) =>
    MockClient((http.Request r) async {
      if (r.url.path.endsWith('content_manifest.json')) {
        return http.Response.bytes(utf8.encode(manifest), 200);
      }
      if (r.url.path.endsWith(_path)) {
        return http.Response.bytes(utf8.encode(body), 200);
      }
      return http.Response('nope', 404);
    });

void main() {
  late String bundled;
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    ContentSync.resetForTest();
    bundled = _pack(10);
  });

  Future<String> run(MockClient c) async => ContentSync.loadWith(
        assetPath: _path,
        bundled: bundled,
        client: c,
        prefs: await SharedPreferences.getInstance(),
      );

  group('ContentIntegrity', () {
    test('allowlist accepts shipped dirs and rejects tricks', () {
      expect(ContentIntegrity.isAllowedPath('stories/prophets.json'), isTrue);
      expect(ContentIntegrity.isAllowedPath('guides/guides.json'), isTrue);
      expect(ContentIntegrity.isAllowedPath('../secrets.json'), isFalse);
      expect(ContentIntegrity.isAllowedPath('stories/../x.json'), isFalse);
      expect(ContentIntegrity.isAllowedPath('/etc/passwd'), isFalse);
      expect(ContentIntegrity.isAllowedPath('stories/x.js'), isFalse);
      expect(ContentIntegrity.isAllowedPath('quran/quran.json'), isFalse);
      expect(ContentIntegrity.isAllowedPath('content_version.json'), isFalse);
    });

    test('weight counts nodes', () {
      expect(ContentIntegrity.weight(json.decode(_pack(3))), greaterThan(3));
      expect(ContentIntegrity.weight(<dynamic>[]), 1);
    });

    test('manifest parser rejects junk and skips bad rows', () {
      expect(ContentManifest.parse('not json'), isNull);
      expect(ContentManifest.parse('[]'), isNull);
      expect(ContentManifest.parse('{"schema":2,"files":{}}'), isNull);
      final m = ContentManifest.parse(json.encode(<String, dynamic>{
        'schema': 1,
        'files': <String, dynamic>{
          _path: <String, dynamic>{'version': 2, 'sha256': 'a' * 64},
          'stories/bad.json': <String, dynamic>{'version': 2, 'sha256': 'xyz'},
          '../evil.json': <String, dynamic>{'version': 2, 'sha256': 'a' * 64},
        },
      }));
      expect(m, isNotNull);
      expect(m!.files.keys, <String>[_path]);
    });

    test('shrink guard and shape checks', () {
      expect(
        ContentIntegrity.checkShape(
            path: _path, body: _pack(10), bundled: bundled),
        isNull,
      );
      expect(
        ContentIntegrity.checkShape(
            path: _path, body: _pack(2), bundled: bundled),
        contains('shrank'),
      );
      expect(
        ContentIntegrity.checkShape(path: _path, body: '[]', bundled: bundled),
        isNotNull,
      );
      expect(
        ContentIntegrity.checkShape(
            path: _path, body: '{"other": []}', bundled: bundled),
        contains('missing section'),
      );
      expect(
        ContentIntegrity.checkShape(
            path: _path, body: '{oops', bundled: bundled),
        'invalid json',
      );
    });
  });

  group('ContentSync.loadWith', () {
    test('accepts a larger pack whose digest matches', () async {
      final remote = _pack(12);
      final got = await run(_server(manifest: _manifest(remote), body: remote));
      expect(got, remote);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('cp_$_path'), remote);
    });

    test('rejects a pack whose digest does not match the manifest', () async {
      final remote = _pack(12);
      final got = await run(_server(
        manifest: _manifest(remote, sha: 'b' * 64),
        body: remote,
      ));
      expect(got, bundled);
    });

    test('never replaces bundled content with a drastically smaller pack',
        () async {
      final remote = _pack(2);
      final got = await run(_server(manifest: _manifest(remote), body: remote));
      expect(got, bundled);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('cp_$_path'), isNull);
    });

    test('never uses a pack that is not JSON', () async {
      const remote = '<html>502 Bad Gateway</html>';
      final got = await run(_server(manifest: _manifest(remote), body: remote));
      expect(got, bundled);
    });

    test('keeps last-known-good when the next pack fails', () async {
      final good = _pack(12);
      expect(
        await run(_server(manifest: _manifest(good), body: good)),
        good,
      );
      final bad = _pack(1);
      final got = await run(
        _server(manifest: _manifest(bad, version: 6), body: bad),
      );
      expect(got, good);
    });

    test('offline falls back to last-known-good, then bundle', () async {
      final good = _pack(12);
      await run(_server(manifest: _manifest(good), body: good));
      final offline = MockClient((_) async => throw http.ClientException('x'));
      expect(await run(offline), good);
      SharedPreferences.setMockInitialValues(<String, Object>{});
      expect(await run(offline), bundled);
    });

    test('a cached pack is dropped when the app ships new bundled content',
        () async {
      final good = _pack(12);
      await run(_server(manifest: _manifest(good), body: good));
      bundled = _pack(20);
      final offline = MockClient((_) async => throw http.ClientException('x'));
      expect(await run(offline), bundled);
    });

    test('ignores a manifest without the file', () async {
      final remote = _pack(12);
      final empty = json.encode(<String, dynamic>{
        'schema': 1,
        'files': <String, dynamic>{},
      });
      expect(await run(_server(manifest: empty, body: remote)), bundled);
    });

    test('does not fetch disallowed paths', () async {
      var fetched = false;
      final c = MockClient((_) async {
        fetched = true;
        return http.Response('{}', 200);
      });
      final got = await ContentSync.loadWith(
        assetPath: '../outside.json',
        bundled: bundled,
        client: c,
        prefs: await SharedPreferences.getInstance(),
      );
      expect(got, bundled);
      expect(fetched, isFalse);
    });
  });

  test('shipped manifest is well-formed and lists real packs', () {
    final m = ContentManifest.parse(
        File('assets/content_manifest.json').readAsStringSync());
    expect(m, isNotNull);
    expect(m!.files, isNotEmpty);
    for (final p in m.files.keys) {
      expect(File('assets/$p').existsSync(), isTrue, reason: p);
    }
  });
}
