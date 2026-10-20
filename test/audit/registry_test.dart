import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'router_source.dart';

/// WAVE 9 - THE REGISTRY LAW. The Master Module Registry must be whole, its
/// statuses legal, and every module that claims a door must have that door in
/// the router. (The first version of this test ended in
/// `|| router.contains('AppRoutes.')`, which is always true - it verified
/// nothing. Routes now come from the registry itself and are matched against
/// the paths the router really declares.)
void main() {
  Map<String, dynamic> read(String p) =>
      json.decode(File(p).readAsStringSync()) as Map<String, dynamic>;

  List<Map<String, dynamic>> modules() =>
      (read('assets/system/module_registry.json')['modules'] as List<dynamic>)
          .map((dynamic e) => e as Map<String, dynamic>)
          .toList();

  const Set<String> legal = <String>{'live', 'walled', 'unbuilt', 'gated'};

  test('W9.1 registry: every module present, unique and legally labeled', () {
    final List<Map<String, dynamic>> mods = modules();
    expect(mods.length, greaterThanOrEqualTo(41),
        reason: 'the registry is the complete memory of the app - '
            'it must not shrink');
    final Set<String> ids = <String>{};
    for (final Map<String, dynamic> mm in mods) {
      expect(ids.add(mm['id'] as String), isTrue,
          reason: 'duplicate id ${mm['id']}');
      expect((mm['title'] as String).isNotEmpty, isTrue);
      expect((mm['doc'] as String).isNotEmpty, isTrue,
          reason: '${mm['id']} must cite its design source');
      expect(legal.contains(mm['status']), isTrue,
          reason: '${mm['id']} has an illegal status');
    }
  });

  test('W9.2 every live/gated/walled module names a route that exists', () {
    final RouterSource router = RouterSource.read();
    final List<String> problems = <String>[];
    for (final Map<String, dynamic> m in modules()) {
      final String id = m['id'] as String;
      final String status = m['status'] as String;
      final String? route = m['route'] as String?;
      final String? surface = m['surface'] as String?;
      if (status == 'unbuilt') {
        if (route != null) {
          problems.add('$id is unbuilt but declares route $route');
        }
        continue;
      }
      if (route == null && surface == null) {
        problems.add('$id ($status) has neither a route nor a surface note');
        continue;
      }
      if (route != null && !router.absolutePaths.contains(route)) {
        problems.add('$id -> $route is not declared in router.dart');
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('W9.3 a module behind a founder-only route is never labeled live', () {
    final RouterSource router = RouterSource.read();
    expect(router.founderOnly, contains('/founder'),
        reason: 'the router no longer gates /founder behind kFounderTools');
    final List<String> problems = <String>[];
    for (final Map<String, dynamic> m in modules()) {
      final String? route = m['route'] as String?;
      if (route != null &&
          router.founderOnly.contains(route) &&
          m['status'] == 'live') {
        problems.add('${m['id']} is live but $route is compiled out of the '
            'production build');
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('W9.4 routed screens that are not in the registry are known', () {
    // Every module-level door in the registry resolves; this guards the other
    // direction for the doors the bottom nav and Home rely on.
    final RouterSource router = RouterSource.read();
    final Set<String> claimed = <String>{
      for (final Map<String, dynamic> m in modules())
        if (m['route'] != null) m['route'] as String,
    };
    for (final String must in const <String>[
      '/prayer',
      '/quran',
      '/adhkar',
      '/hadith',
      '/noor',
      '/hadi',
      '/calendar',
      '/academy/gate',
    ]) {
      expect(router.absolutePaths, contains(must));
      expect(claimed, contains(must),
          reason: '$must is a Home tile but no registry module claims it');
    }
  });
}
