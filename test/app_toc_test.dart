import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// P1-11: Hādi's table of contents (assets/share/app_toc.json) is what the
/// live model is told the app contains. It drifted: 28 stories and 4 guides
/// were missing and one guide id had a typo. `tool/sync_app_toc.py` appends
/// what is missing; this test fails when a pack gains an item the table of
/// contents does not list.
void main() {
  Map<String, dynamic> readMap(String path) =>
      json.decode(File(path).readAsStringSync()) as Map<String, dynamic>;
  List<dynamic> readList(String path) =>
      json.decode(File(path).readAsStringSync()) as List<dynamic>;

  final Map<String, dynamic> rooms =
      readMap('assets/share/app_toc.json')['rooms'] as Map<String, dynamic>;

  Set<String> tocIds(String room) => <String>{
        for (final dynamic e in rooms[room] as List<dynamic>)
          (e as Map<String, dynamic>)['id'] as String,
      };

  test('every story and guide is listed in its room', () {
    final List<String> missing = <String>[];
    for (final String room in rooms.keys) {
      if (room == 'games') continue;
      final String path =
          room == 'huda' ? 'assets/guides/guides.json' : 'assets/stories/$room.json';
      final Set<String> listed = tocIds(room);
      for (final dynamic item in readList(path)) {
        final String id = (item as Map<String, dynamic>)['id'] as String;
        if (!listed.contains(id)) missing.add('$room/$id');
      }
    }
    expect(missing, isEmpty,
        reason: 'run: python3 tool/sync_app_toc.py\n${missing.join('\n')}');
  });

  test('no room lists an id its pack does not have', () {
    final List<String> stale = <String>[];
    for (final String room in rooms.keys) {
      if (room == 'games') continue;
      final String path =
          room == 'huda' ? 'assets/guides/guides.json' : 'assets/stories/$room.json';
      final Set<String> real = <String>{
        for (final dynamic item in readList(path))
          (item as Map<String, dynamic>)['id'] as String,
      };
      for (final String id in tocIds(room)) {
        if (!real.contains(id)) stale.add('$room/$id');
      }
    }
    expect(stale, isEmpty);
  });

  test('the funeral-washing guide id has no typo', () {
    final Set<String> ids = <String>{
      for (final dynamic g in readList('assets/guides/guides.json'))
        (g as Map<String, dynamic>)['id'] as String,
    };
    expect(ids.contains('ghuda-janazah-wash'), isFalse);
    expect(ids.contains('huda-janazah-wash'), isTrue);
    expect(tocIds('huda').contains('huda-janazah-wash'), isTrue);
    expect(tocIds('huda').contains('ghuda-janazah-wash'), isFalse);
  });

  test('no id is listed twice in one room', () {
    for (final String room in rooms.keys) {
      final List<dynamic> list = rooms[room] as List<dynamic>;
      expect(tocIds(room).length, list.length, reason: room);
    }
  });
}
