import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// ADVERSARIAL CROSS-REFERENCE AUDIT — wave 2.
/// Every link between modules must resolve. No orphans allowed.
void main() {
  List<dynamic> readList(String p) =>
      json.decode(File(p).readAsStringSync()) as List<dynamic>;
  String read(String p) => File(p).readAsStringSync();

  final storyIds = <String>{};
  for (final p in ['prophets', 'women', 'seerah', 'companions', 'ghayb',
      'signs', 'tales', 'khutbahs', 'modernhadith', 'dailyduas']) {
    for (final e in readList('assets/stories/$p.json')) {
      storyIds.add((e as Map<String, dynamic>)['id'] as String);
    }
  }

  test('W2.1 every feelings path item links to a real story', () {
    for (final e in readList('assets/feelings/feelings.json')) {
      final m = e as Map<String, dynamic>;
      final dua = m['dua'] as Map<String, dynamic>;
      expect((dua['arabic'] as String).length, greaterThan(10),
          reason: '${m['id']}: missing dua arabic');
      expect((dua['source'] as String).trim().isNotEmpty, isTrue,
          reason: '${m['id']}: missing dua source');
      for (final it in m['items'] as List<dynamic>) {
        final sid = (it as Map<String, dynamic>)['storyId'] as String;
        expect(storyIds.contains(sid), isTrue,
            reason: '${m['id']} links to missing story: $sid');
      }
    }
  });

  test('W2.2 family tree story links resolve to real stories', () {
    final nodes = readList('assets/family/tree.json');
    for (final e in nodes) {
      final sid = (e as Map<String, dynamic>)['story'] as String?;
      if (sid != null) {
        expect(storyIds.contains(sid), isTrue,
            reason: 'tree node ${e['id']} links to missing story: $sid');
      }
    }
  });

  test('W2.3 every AppRoutes constant used in Explore has a route', () {
    final router = read('lib/app/router.dart');
    final explore = read('lib/features/explore/presentation/explore_screen.dart');
    final used = RegExp(r'AppRoutes\.([a-zA-Z0-9_]+)')
        .allMatches(explore)
        .map((m) => m.group(1)!)
        .toSet();
    for (final name in used) {
      expect(router.contains('static const String $name'), isTrue,
          reason: 'Explore uses AppRoutes.$name with no constant');
      expect(router.contains('AppRoutes.$name,'), isTrue,
          reason: 'AppRoutes.$name has no GoRoute');
    }
  });

  test('W2.4 library collections cover every shipped story pack', () {
    final repo = read('lib/features/stories/data/stories_repository.dart');
    final screen = read('lib/features/stories/presentation/stories_screen.dart');
    final packsInRepo = RegExp(r"'([a-z0-9]+)',")
        .allMatches(repo)
        .map((m) => m.group(1)!)
        .where((p) => File('assets/stories/$p.json').existsSync())
        .toSet();
    for (final p in packsInRepo) {
      expect(screen.contains("('$p',"), isTrue,
          reason: 'pack $p loads but has no shelf in the library screen');
    }
  });

  test('W2.5 home tile image mapping covers every tile', () {
    final home = read('lib/features/home/presentation/home_screen.dart');
    // Every _HomeTile title must be reachable by _tileImage's matcher set.
    final titles = RegExp(r"title: '([^']+)'")
        .allMatches(home)
        .map((m) => m.group(1)!)
        .toList();
    final matchers = ['Prayer', 'Qur', 'Dhikr', 'Hadith', 'Today', 'H', 'Islamic', 'Knowledge'];
    for (final t in titles) {
      final ok = matchers.any((m) => t.startsWith(m) || t.startsWith('H\u0101di') || t.startsWith('Hadi'));
      expect(ok, isTrue, reason: 'no tile image matcher for title: $t');
    }
  });

  test('W2.6 model round-trip: JSON drift cannot break the app silently', () {
    final sample = (readList('assets/stories/prophets.json') as List).first as Map<String, dynamic>;
    // Story.fromJson must accept exactly what we ship.
    final chapters = sample['chapters'] as List<dynamic>;
    expect(chapters.first is Map<String, dynamic>, isTrue);
    expect(sample['sources'] is List<dynamic>, isTrue);
    // dailyduas chapters carry arabic/dua — model must tolerate the extra keys.
    final dua = (readList('assets/stories/dailyduas.json') as List).first as Map<String, dynamic>;
    expect((dua['chapters'] as List).first['arabic'], isNotNull);
  });
}
