import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/features/hadi/application/hadi_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// The three guides added in round 4 (tahajjud, what is Islam, the four
/// schools) are only allowed while they stay honestly labelled and every
/// reference in them is in docs/content_needed/VERIFICATION_LOG.md.
void main() {
  const List<String> ids = <String>[
    'huda-tahajjud',
    'huda-what-is-islam',
    'huda-madhhab-overview',
  ];

  final Map<String, Map<String, dynamic>> byId = <String, Map<String, dynamic>>{
    for (final dynamic g in json.decode(
      File('assets/guides/guides.json').readAsStringSync(),
    ) as List<dynamic>)
      (g as Map<String, dynamic>)['id'] as String: g,
  };
  final String log =
      File('docs/content_needed/VERIFICATION_LOG.md').readAsStringSync();

  for (final String id in ids) {
    group(id, () {
      test('exists with steps, sources and a madhhab note', () {
        final Map<String, dynamic>? g = byId[id];
        expect(g, isNotNull);
        expect((g!['steps'] as List<dynamic>).length, greaterThanOrEqualTo(3));
        expect((g['madhhabNote'] as String).trim(), isNotEmpty);
      });

      test('says it is scholar review needed', () {
        final List<dynamic> sources = byId[id]!['sources'] as List<dynamic>;
        expect(sources.first as String,
            startsWith('Status: scholar review needed'));
      });

      test('Hadi may open it', () {
        expect(kHadiGuideNames.containsKey(id), isTrue);
      });

      test('every hadith and Qur’an reference is in the log', () {
        final String text = <String>[
          ...(byId[id]!['steps'] as List<dynamic>).cast<String>(),
          ...(byId[id]!['sources'] as List<dynamic>).cast<String>(),
        ].join('\n');
        final RegExp hadith = RegExp(
          r'(Bukhari|Muslim)\s+(\d{1,4})',
        );
        for (final RegExpMatch m in hadith.allMatches(text)) {
          expect(log.contains('${m.group(1)} ${m.group(2)}'), isTrue,
              reason: m.group(0));
        }
        final RegExp quran = RegExp(r'Qur’an (\d{1,3}):(\d{1,3})');
        for (final RegExpMatch m in quran.allMatches(text)) {
          expect(log.contains('${m.group(1)}:${m.group(2)}'), isTrue,
              reason: m.group(0));
        }
      });
    });
  }

  test('the witr line is cited to the verified number', () {
    final String witr =
        (byId['huda-witr']!['steps'] as List<dynamic>).join('\n');
    expect(witr, contains('(Bukhari 998)'));
    // Bukhari 990 (one rak'ah of witr if the dawn is feared) is also cited
    // correctly in the rewritten guide.
    expect(witr, contains('Bukhari 990'));
  });
}
