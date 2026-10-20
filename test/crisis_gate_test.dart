import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/features/sakina/domain/crisis_detector.dart';
import 'package:flutter_test/flutter_test.dart';

/// The crisis release gate. test/data/crisis_golden.json is the golden set:
/// every case with an expected kind MUST be detected as that kind, and every
/// case with null MUST NOT fire. 100% or the build fails.
///
/// Non-English phrases in the set need review by native speakers before a
/// release; the gate proves the code does what the set says, not that the set
/// is complete.
void main() {
  final Map<String, dynamic> golden = json.decode(
    File('test/data/crisis_golden.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final List<Map<String, dynamic>> cases = <Map<String, dynamic>>[
    for (final dynamic c in golden['cases'] as List<dynamic>)
      c as Map<String, dynamic>,
  ];

  test('the golden set is large and covers every kind and a benign side', () {
    expect(cases.length, greaterThanOrEqualTo(200));
    final Map<String?, int> byKind = <String?, int>{};
    for (final Map<String, dynamic> c in cases) {
      final String? k = c['expect'] as String?;
      byKind[k] = (byKind[k] ?? 0) + 1;
    }
    for (final CrisisKind k in CrisisKind.values) {
      expect(byKind[k.name] ?? 0, greaterThanOrEqualTo(5), reason: k.name);
    }
    expect(byKind[null] ?? 0, greaterThanOrEqualTo(50),
        reason: 'the gate needs benign cases to catch over-triggering');
    final Set<String> ids = <String>{
      for (final Map<String, dynamic> c in cases) c['id'] as String,
    };
    expect(ids.length, cases.length, reason: 'duplicate case ids');
  });

  test('100% of golden cases get the expected result', () {
    final List<String> failures = <String>[];
    for (final Map<String, dynamic> c in cases) {
      final String? want = c['expect'] as String?;
      final CrisisKind? got = CrisisDetector.detect(c['q'] as String);
      if (got?.name != want) {
        failures.add('${c['id']}: "${c['q']}" expected $want, got ${got?.name}');
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}
