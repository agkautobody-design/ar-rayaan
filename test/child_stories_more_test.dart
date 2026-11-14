import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ar_rayaan/features/kids/domain/child_stories.dart';
import 'package:ar_rayaan/features/kids/domain/child_stories_more.dart';

void main() {
  final List<dynamic> prophets =
      jsonDecode(File('assets/stories/prophets.json').readAsStringSync())
          as List<dynamic>;

  test('every child retelling has one paragraph per chapter', () {
    for (final Map<String, List<String>> m in <Map<String, List<String>>>[
      kChildStoryText,
      kChildStoryTextMore,
    ]) {
      m.forEach((String id, List<String> parts) {
        final Map<String, dynamic> s = prophets
            .cast<Map<String, dynamic>>()
            .firstWhere((e) => e['id'] == id, orElse: () => <String, dynamic>{});
        if (s.isEmpty) return; // tales live in another file
        expect(parts.length, (s['chapters'] as List).length, reason: id);
      });
    }
  });

  test('retellings are plain: no quotation marks, references or hadith', () {
    kChildStoryTextMore.forEach((String id, List<String> parts) {
      for (final String p in parts) {
        expect(p.contains('"'), isFalse, reason: id);
        expect(RegExp(r'\d+:\d+').hasMatch(p), isFalse, reason: id);
        expect(p.contains('Sahih'), isFalse, reason: id);
        expect(p.length < 600, isTrue, reason: '$id too long to read aloud');
      }
    });
  });

  test('childStoryChapter finds a story from the second file', () {
    expect(childStoryChapter('prophet-zakariya', 0), isNotNull);
    expect(childStoryChapter('prophet-zakariya', 9), isNull);
  });
}
