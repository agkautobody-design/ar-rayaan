import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_voice.dart';
import 'package:ar_rayaan/features/hadi/data/hadi_core.dart';
import 'package:ar_rayaan/features/hadi/data/user_knows.dart';
import 'package:flutter_test/flutter_test.dart';

CoreEntry _entry(String id) =>
    HadiCore.entries.firstWhere((CoreEntry e) => e.id == id);

String _body(CoreEntry e) => HadiCore.bodyOf(e.answer);

String _dress(String q, CoreEntry e,
        {List<HadiMessage> history = const <HadiMessage>[],
        UserKnows knows = UserKnows.empty}) =>
    HadiVoice.dress(
      question: q,
      entry: e,
      answer: e.answer.replaceAll(RegExp(r'\s*\[GO:[^\]]*\]'), ''),
      history: history,
      knows: knows,
      now: DateTime(2026, 11, 21),
    );

void main() {
  final CoreEntry tarawih = _entry('tarawih-prayer');

  test('the checked text is never changed, only surrounded', () {
    final String q = 'How do I pray tarawih?';
    final String out = _dress(q, tarawih);
    expect(HadiCore.bodyOf(out).contains(_body(tarawih)), isTrue);
  });

  test('the same question in different conversations is not always dressed alike', () {
    final Set<String> heads = <String>{};
    for (int n = 0; n < 24; n++) {
      final List<HadiMessage> h = <HadiMessage>[
        for (int i = 0; i < n; i++) ...<HadiMessage>[
          const HadiMessage(fromHadi: false, text: 'x'),
          const HadiMessage(fromHadi: true, text: 'y'),
        ],
      ];
      heads.add(_dress('How do I pray tarawih?', tarawih, history: h).split('\n').first);
    }
    expect(heads.length, greaterThan(4));
  });

  test('an opening used in the last replies is not used again', () {
    String? first;
    for (int n = 0; n < 40 && first == null; n++) {
      final List<HadiMessage> h = <HadiMessage>[
        for (int i = 0; i < n; i++) ...<HadiMessage>[
          const HadiMessage(fromHadi: false, text: 'x'),
          const HadiMessage(fromHadi: true, text: 'y'),
        ],
      ];
      final String out = _dress('How do I pray tarawih?', tarawih, history: h);
      final String head = out.split('\n').first;
      if (!out.startsWith(tarawih.answer.substring(0, 20))) first = head;
      if (first != null) {
        final String again = _dress('How do I pray tarawih?', tarawih,
            history: <HadiMessage>[
              ...h,
              const HadiMessage(fromHadi: false, text: 'How do I pray tarawih?'),
              HadiMessage(fromHadi: true, text: out),
            ]);
        expect(again.split('\n').first == first, isFalse);
      }
    }
    expect(first, isNotNull);
  });

  test('a grave subject gets the plain answer only', () {
    final CoreEntry grave = _entry('munkar-nakir-grave');
    expect(_dress('What happens in the grave?', grave),
        grave.answer.replaceAll(RegExp(r'\s*\[GO:[^\]]*\]'), ''));
  });

  test('a short follow-up is answered straight', () {
    final String out = _dress('why?', tarawih, history: const <HadiMessage>[
      HadiMessage(fromHadi: false, text: 'How do I pray tarawih?'),
      HadiMessage(fromHadi: true, text: 'Something said before.'),
    ]);
    expect(out.startsWith(tarawih.answer.substring(0, 20)), isTrue);
  });

  test('an answer given before is acknowledged as such', () {
    final UserKnows knows = UserKnows(covered: <String, KnownTopic>{
      'tarawih-prayer': const KnownTopic(count: 1, last: '2026-11-10'),
    });
    final String out = _dress('How do I pray tarawih?', tarawih, knows: knows);
    expect(
      out.startsWith('We went over this') ||
          out.startsWith('You asked me this') ||
          out.startsWith('This one came up') ||
          out.startsWith('We have been through'),
      isTrue,
    );
  });

  test('it never dresses a reply twice, nor a multi-part reply', () {
    final String once = _dress('How do I pray tarawih?', tarawih);
    expect(
      HadiVoice.dress(
        question: 'How do I pray tarawih?',
        entry: tarawih,
        answer: once,
        history: const <HadiMessage>[],
      ),
      once,
    );
    expect(
      HadiVoice.dress(
        question: 'x y z w',
        entry: tarawih,
        answer: '**One**\n\n${tarawih.answer}',
        history: const <HadiMessage>[],
      ),
      startsWith('**One**'),
    );
  });

  test('a dressed reply is still recognised as the built-in answer', () {
    for (int n = 0; n < 12; n++) {
      final List<HadiMessage> h = <HadiMessage>[
        for (int i = 0; i < n; i++) ...<HadiMessage>[
          const HadiMessage(fromHadi: false, text: 'x'),
          const HadiMessage(fromHadi: true, text: 'y'),
        ],
      ];
      final String out = _dress('How do I pray tarawih?', tarawih, history: h);
      expect(HadiCore.isCoreAnswer(out), isTrue);
      expect(
        HadiCore.answer('why', <HadiMessage>[
          const HadiMessage(fromHadi: false, text: 'How do I pray tarawih?'),
          HadiMessage(fromHadi: true, text: out),
        ])?.entry.id,
        'tarawih-prayer',
      );
    }
  });

  test('every built-in answer survives being dressed', () {
    for (final CoreEntry e in HadiCore.entries) {
      final String out = _dress('How do I do ${e.id.replaceAll('-', ' ')}', e);
      expect(HadiCore.bodyOf(out).contains(_body(e)), isTrue, reason: e.id);
      expect(out.contains('{'), isFalse, reason: e.id);
    }
  });
}
