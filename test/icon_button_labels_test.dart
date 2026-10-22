import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// P1-10: an icon-only button with no tooltip has no name for a screen
/// reader (and no hint on hover). Every `IconButton(` and plain
/// `FloatingActionButton(` in lib/ must carry a `tooltip:` (an extended FAB
/// has its own text label, and `IconButton.styleFrom` is a style, not a
/// button).
void main() {
  test('every icon button in lib/ has a tooltip', () {
    final RegExp start = RegExp(r'\b(IconButton|FloatingActionButton)\(');
    final List<String> missing = <String>[];
    for (final FileSystemEntity f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final String src = f.readAsStringSync();
      for (final RegExpMatch m in start.allMatches(src)) {
        var depth = 1;
        var i = m.end;
        while (depth > 0 && i < src.length) {
          final String c = src[i];
          if (c == '(') depth++;
          if (c == ')') depth--;
          i++;
        }
        final String call = src.substring(m.start, i);
        if (!call.contains('tooltip:')) {
          final int line = '\n'.allMatches(src.substring(0, m.start)).length + 1;
          missing.add('${f.path}:$line');
        }
      }
    }
    expect(missing, isEmpty, reason: 'icon buttons without a tooltip:\n${missing.join('\n')}');
  });
}
