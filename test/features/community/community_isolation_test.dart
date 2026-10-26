import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Hadi never touches community or forum code', () {
    final RegExp bad = RegExp(
      r"core/backend|features/community|forum",
      caseSensitive: false,
    );
    final List<String> hits = <String>[];
    for (final FileSystemEntity f
        in Directory('lib/features/hadi').listSync(recursive: true)) {
      if (f is File && f.path.endsWith('.dart')) {
        if (bad.hasMatch(f.readAsStringSync())) hits.add(f.path);
      }
    }
    expect(hits, isEmpty, reason: 'community content must not reach Hadi');
  });

  test('community screens are only reachable when the backend flag is on', () {
    final String s = File(
      'lib/features/community/presentation/community_screen.dart',
    ).readAsStringSync();
    expect(s, contains('BackendConfig.mode != BackendMode.off'));
  });

  test('the old Majlis stays behind its gate', () {
    final String r = File('lib/app/router.dart').readAsStringSync();
    expect(r, contains('AppRoutes.majlis'));
    expect(File('test/majlis_gate_test.dart').existsSync(), isTrue);
  });

  test('rules text is marked draft', () {
    final String s = File(
      'lib/features/community/domain/community_rules_text.dart',
    ).readAsStringSync();
    expect(s, contains('kCommunityRulesAreDraft = true'));
  });
}
