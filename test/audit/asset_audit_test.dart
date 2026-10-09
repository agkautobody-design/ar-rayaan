import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// WAVE 6 — ASSET INTEGRITY. Every asset path referenced in shipped
/// Dart code must exist in the repo.
void main() {
  test('W6 all referenced asset files exist', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    final referenced = <String>{};
    final re = RegExp(
        r"assets/[A-Za-z0-9_\-/]+\.(?:jpg|png|json|ttf)");
    for (final f in files) {
      for (final m in re.allMatches(f.readAsStringSync())) {
        referenced.add(m.group(0)!);
      }
    }
    expect(referenced, isNotEmpty);
    final missing = referenced
        .where((p) => !File(p).existsSync())
        .toList();
    expect(missing, isEmpty,
        reason: 'missing assets referenced in code: \$missing');
  });
}
