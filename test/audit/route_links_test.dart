import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every in-app link must land on a real route. Dead links used to slip in
/// unnoticed (/names99, /guides/read, /academy/the-path, 'None').
void main() {
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
