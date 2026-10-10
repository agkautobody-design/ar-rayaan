import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// WAVE 9 - THE REGISTRY LAW. The Master Module Registry must be whole,
/// its statuses legal, and every 'live' module must actually have a route.
void main() {
  Map<String, dynamic> read(String p) =>
      json.decode(File(p).readAsStringSync()) as Map<String, dynamic>;

  test('W9.1 registry: every designed module present and legally labeled', () {
    final reg = read('assets/system/module_registry.json');
    final modules = reg['modules'] as List<dynamic>;
    expect(modules.length, greaterThan(25),
        reason: 'the registry is the complete memory of the app - it must not shrink');
    final ids = <String>{};
    for (final m in modules) {
      final mm = m as Map<String, dynamic>;
      expect(ids.add(mm['id'] as String), isTrue, reason: 'duplicate id');
      expect((mm['title'] as String).isNotEmpty, isTrue);
      expect((mm['doc'] as String).isNotEmpty, isTrue,
          reason: '${mm['id']} must cite its design source');
      expect(const ['live', 'walled', 'unbuilt', 'gated'].contains(mm['status']),
          isTrue, reason: '${mm['id']} has an illegal status');
    }
  });

  test('W9.2 every live module has a route in the router', () {
    final router = File('lib/app/router.dart').readAsStringSync();
    final modules = (read('assets/system/module_registry.json')['modules']
        as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .where((m) => m['status'] == 'live');
    // Known live modules and the route paths they own.
    const liveRoutes = <String, String>{
      'prayer': '/prayer', 'adhkar': '/adhkar', 'hadi': '/hadi',
      'lamha': '/lamha', 'daily-hadith': '/hadith', 'huda': '/huda',
      'academy': '/academy', 'stories': '/stories', 'family-tree': '/family-tree',
      'khutbahs': '/stories', 'sakina': '/sakina', 'noor': '/noor',
      'masajid': '/masajid', 'tayyib-finance': '/finance',
      'games': '/games', 'player': '/player', 'daily-duas': '/stories',
      'modern-hadith': '/stories', 'feelings': '/feelings',
      'family-wing': '/academy/family', 'elder': '/home/elder',
      'quick-access': '/home/quick', 'doctor': '/founder',
      'quran': '/quran', 'qibla': '/qibla', 'notes': '/notes',
      'downloads': '/downloads',
    };
    for (final m in modules) {
      final path = liveRoutes[m['id']];
      expect(path, isNotNull, reason: '${m['id']} is live but has no known route');
      expect(
          router.contains("path: '$path'") ||
              router.contains('AppRoutes.') ,
          isTrue,
          reason: '${m['id']} -> $path must exist in the router');
    }
  });
}
