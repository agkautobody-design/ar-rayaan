import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'router_source.dart';

/// Every in-app link must land on a real route. Dead links used to slip in
/// unnoticed (/names99, /guides/read, /academy/the-path, 'None').
void main() {
  test('every route path in the router is declared exactly once', () {
    // Duplicate paths used to hide a screen: Home was declared both at the
    // top level and inside the bottom-nav shell, so the shell copy (and its
    // bottom nav) was unreachable. /stories (x3) and /share (x2) too.
    final RouterSource router = RouterSource.read();
    final Map<String, int> seen = <String, int>{};
    for (final String p in router.absolutePaths) {
      seen[p] = (seen[p] ?? 0) + 1;
    }
    final List<String> dupes = <String>[
      for (final MapEntry<String, int> e in seen.entries)
        if (e.value > 1) '${e.key} x${e.value}',
    ];
    expect(dupes, isEmpty, reason: 'duplicate route paths:\n${dupes.join('\n')}');
    expect(router.absolutePaths.length, greaterThan(80));
    expect(router.paths.any((String p) => p.startsWith('?')), isFalse,
        reason: 'an AppRoutes constant in the router did not resolve');
  });

  test('Home lives once, inside the bottom-nav shell', () {
    final String src = RouterSource.read().source;
    // Exactly one HomeScreen page builder in the router...
    expect(RegExp(r'_fade\(const HomeScreen\(\)').allMatches(src).length, 1);
    // ...and it sits after the shell route begins.
    final int shell = src.indexOf('StatefulShellRoute.indexedStack');
    final int home = src.indexOf('_fade(const HomeScreen()');
    expect(shell, greaterThan(0));
    expect(home, greaterThan(shell));
  });

  test('every literal in-app link resolves to a router path', () {
    final String router = File('lib/app/router.dart').readAsStringSync();
    final Map<String, String> consts = <String, String>{
      for (final RegExpMatch m in RegExp(
        r"static const String (\w+)\s*=\s*'([^']+)'",
      ).allMatches(router))
        m.group(1)!: m.group(2)!,
    };
    final Set<String> paths = <String>{
      for (final RegExpMatch m
          in RegExp(r"path:\s*'([^']+)'").allMatches(router))
        m.group(1)!,
      for (final RegExpMatch m
          in RegExp(r'path:\s*AppRoutes\.(\w+)').allMatches(router))
        consts[m.group(1)!] ?? '',
    };

    bool resolves(String link) {
      final String p = link.split('?').first;
      if (paths.contains(p)) return true;
      for (final String q in paths.where((String q) => q.contains(':'))) {
        final RegExp rx =
            RegExp('^${q.replaceAll(RegExp(r':\w+'), r'[^/]+')}\$');
        if (rx.hasMatch(p)) return true;
      }
      // Nested child route under /academy/letters.
      return p.startsWith('/academy/letters/lesson/');
    }

    final RegExp link = RegExp(
      r"(?:context\.(?:go|push)\(|route:\s*|actionRoute:\s*|\[GO:)'?(/[a-zA-Z0-9\-_/]+)(['\]$])",
    );
    final List<String> dead = <String>[];
    for (final FileSystemEntity f
        in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final String src = f.readAsStringSync();
      for (final RegExpMatch m in link.allMatches(src)) {
        final String p = m.group(1)!;
        // A trailing slash means an id is interpolated after it.
        if (p.endsWith('/')) continue;
        // Placeholders in docs and the prompt's token syntax.
        if (p == '/path' || p == '/the/path') continue;
        if (!resolves(p)) dead.add('${f.path}: $p');
      }
    }
    expect(dead, isEmpty, reason: 'links with no route:\n${dead.join('\n')}');
  });
}
