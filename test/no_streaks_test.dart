import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Owner ruling (Oct 2026): no streaks anywhere in the app, on any act. This
/// scans the code (not comments) for the word, so a streak cannot come back
/// in a string, a title or a route by accident.
void main() {
  // Files that must mention the word in code, and why.
  const Set<String> allowed = <String>{
    // What a person might type to Hadi; the answers never use the word.
    'lib/features/hadi/data/hadi_core_data.dart',
    'lib/features/hadi/data/hadi_core.dart',
    'lib/features/hadi/data/hadi_finder.dart',
    // The validator that keeps the word out of lesson text.
    'lib/features/academy/domain/v3/lessons_v3.dart',
    // The storage key an earlier release used; read once, never shown.
    'lib/features/tracking/application/tracking_providers.dart',
    'lib/features/tracking/presentation/tracking_card.dart',
  };

  test('no streak word in the code outside the allowed files', () {
    final List<String> found = <String>[];
    for (final FileSystemEntity e in Directory('lib').listSync(recursive: true)) {
      if (e is! File || !e.path.endsWith('.dart')) continue;
      final String path = e.path.replaceAll('\\', '/');
      if (allowed.contains(path)) continue;
      int n = 0;
      for (final String line in e.readAsLinesSync()) {
        n++;
        final String t = line.trimLeft();
        if (t.startsWith('//')) continue;
        if (line.toLowerCase().contains('streak')) found.add('$path:$n');
      }
    }
    expect(found, isEmpty, reason: found.join('\n'));
  });

  test('the allowed files never show the word to a person', () {
    // Hadi's built-in answer and pointer text must not use the word.
    final String finder = File(
      'lib/features/hadi/data/hadi_finder.dart',
    ).readAsStringSync();
    final RegExp literal = RegExp(r"'[^'\n]*'");
    for (final RegExpMatch m in literal.allMatches(finder)) {
      final String s = m.group(0)!.toLowerCase();
      if (!s.contains('streak')) continue;
      // Only the short trigger-word list may hold it.
      expect(<String>["'streak'", "'streaks'"], contains(s), reason: s);
    }
    final String core = File(
      'lib/features/hadi/data/hadi_core_data.dart',
    ).readAsStringSync();
    final RegExp answer = RegExp(r"answer: '(?:[^'\\]|\\.)*'");
    for (final RegExpMatch m in answer.allMatches(core)) {
      expect(m.group(0)!.toLowerCase().contains('streak'), isFalse);
    }
  });

  test('the Streaks screen, card and route are gone', () {
    expect(Directory('lib/features/streaks').existsSync(), isFalse);
    expect(File('test/streaks_test.dart').existsSync(), isFalse);
  });
}
