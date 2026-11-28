import 'dart:io';

import 'package:ar_rayaan/features/support/data/pack_repository.dart';
import 'package:ar_rayaan/features/support/domain/knowledge_answerer.dart';
import 'package:ar_rayaan/features/support/domain/support_pack.dart';
import 'package:flutter_test/flutter_test.dart';

/// "I get that but what can I do to start feeling it" after an answer about
/// Allah being near must find the closeness how-to, not a dead end.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a feeling follow-up read with the thread finds the closeness how-to', () {
    final List<SupportPack> packs = <SupportPack>[
      for (final String n in <String>[
        'closeness_to_allah',
        'prayer_howto',
        'worship_better',
        'faith_and_heart',
      ])
        SupportPack.parse(File('assets/support/packs/$n.json').readAsStringSync())!,
    ];
    SupportPackRepository.setPacks(packs);
    addTearDown(SupportPackRepository.debugReset);

    const String ctx = 'how can i feel closer to allah and accomplish my goals '
        'Allah is with us in three ways. The Qur\'an says He is closer than '
        'the jugular vein.';
    expect(KnowledgeAnswerer.isFollowUp(
        'I get that but what can I do to start feeling it'), isTrue);
    final KnowledgeAnswer? ka = KnowledgeAnswerer.answer(
        '$ctx I get that but what can I do to start feeling it', packs);
    expect(ka, isNotNull);
    expect(ka!.snippet.pack, 'closeness_to_allah');
  });
}
