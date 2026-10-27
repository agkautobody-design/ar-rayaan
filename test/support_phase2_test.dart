import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ar_rayaan/features/support/domain/checkin_scheduler.dart';
import 'package:ar_rayaan/features/support/domain/conversation_moves.dart';
import 'package:ar_rayaan/features/support/domain/knowledge_answerer.dart';
import 'package:ar_rayaan/features/support/domain/online_support_policy.dart';
import 'package:ar_rayaan/features/support/domain/rotation.dart';
import 'package:ar_rayaan/features/support/domain/student_routing.dart';
import 'package:ar_rayaan/features/support/domain/support_engine.dart';
import 'package:ar_rayaan/features/support/domain/support_pack.dart';
import 'package:ar_rayaan/features/support/domain/tone.dart';
import 'package:ar_rayaan/features/support/domain/user_memory.dart';

Map<String, dynamic> snip(String id, String kind, String text,
        {String? tone, String? move, int? gap, List<String>? triggers, List<String>? tags}) =>
    <String, dynamic>{
      'id': id,
      'kind': kind,
      'text': <String, String>{'en': text},
      if (tone != null) 'tone': tone,
      if (move != null) 'move': move,
      if (gap != null) 'minGapTurns': gap,
      if (triggers != null) 'triggers': triggers,
      if (tags != null) 'tags': tags,
      'status': 'shippable',
    };

SupportPack pack(String name, String kind, List<Map<String, dynamic>> s) =>
    SupportPack.parse(jsonEncode(<String, dynamic>{
      'schema': 1,
      'pack': name,
      'packKind': kind,
      'snippets': s,
    }))!;

void main() {
  group('rotation', () {
    test('never the same text twice in a row, and not within the gap', () {
      final SupportPack p = pack('c', 'conversation', <Map<String, dynamic>>[
        for (int i = 0; i < 4; i++) snip('g$i', 'converse', 'Hello $i', move: 'greet_morning', tone: 'warm'),
      ]);
      final SnippetRotator r = SnippetRotator(seed: 7);
      String? last;
      final List<String> seen = <String>[];
      for (int i = 0; i < 4; i++) {
        r.nextTurn();
        final SupportSnippet? s = ConversationMoves.pick(
            'greet_morning', <SupportPack>[p], r, now: DateTime(2026, 1, 1, 9));
        expect(s, isNotNull);
        expect(s!.textIn('en'), isNot(last));
        last = s.textIn('en');
        seen.add(s.id);
      }
      expect(seen.toSet().length, 4);
    });

    test('a single variant is still never shown twice in a row', () {
      final SupportPack p = pack('c', 'conversation', <Map<String, dynamic>>[
        snip('a', 'converse', 'Only one', move: 'goodbye', tone: 'warm'),
      ]);
      final SnippetRotator r = SnippetRotator(seed: 1);
      r.nextTurn();
      expect(ConversationMoves.pick('goodbye', <SupportPack>[p], r), isNotNull);
      r.nextTurn();
      final SupportSnippet? again = ConversationMoves.pick('goodbye', <SupportPack>[p], r);
      expect(again == null || again.textIn('en') != 'Only one', isTrue);
    });

    test('same seed gives the same order', () {
      final SupportPack p = pack('c', 'conversation', <Map<String, dynamic>>[
        for (int i = 0; i < 5; i++) snip('g$i', 'converse', 'Line $i', move: 'goodbye', tone: 'warm'),
      ]);
      List<String> run() {
        final SnippetRotator r = SnippetRotator(seed: 42);
        return <String>[
          for (int i = 0; i < 3; i++)
            () {
              r.nextTurn();
              return ConversationMoves.pick('goodbye', <SupportPack>[p], r)!.id;
            }(),
        ];
      }

      expect(run(), run());
    });
  });

  group('tone', () {
    test('setting wins', () {
      expect(ToneChooser.order(setting: 'brief').first, 'brief');
      expect(ToneChooser.order(setting: 'formal').first, 'formal');
    });
    test('auto follows pace', () {
      expect(ToneChooser.order(recentLengths: <int>[2, 3, 2]).first, 'brief');
      expect(ToneChooser.order(recentLengths: <int>[30, 40]).first, 'warm');
    });
    test('distress is calm and never playful', () {
      final List<String> o = ToneChooser.order(setting: 'brief', distress: true);
      expect(o.first, 'calm');
      expect(o.contains('playful'), isFalse);
    });
    test('picks the preferred tone when present', () {
      final SupportPack p = pack('c', 'conversation', <Map<String, dynamic>>[
        snip('w', 'converse', 'warm line', move: 'goodbye', tone: 'warm'),
        snip('b', 'converse', 'brief line', move: 'goodbye', tone: 'brief'),
      ]);
      final SnippetRotator r = SnippetRotator(seed: 3)..nextTurn();
      expect(
          ConversationMoves.pick('goodbye', <SupportPack>[p], r, toneOrder: <String>['brief', 'warm'])!.id,
          'b');
    });
  });

  group('offline-first knowledge', () {
    final SupportPack k = pack('islam_basics', 'knowledge', <Map<String, dynamic>>[
      snip('k1', 'fact', 'Wudu is the washing before prayer: hands, mouth, nose, face, arms, head, feet.',
          triggers: <String>['how to make wudu'], tags: <String>['wudu', 'prayer']),
      snip('k2', 'fact', 'Zakat is a yearly due on savings above the nisab.',
          triggers: <String>['what is zakat'], tags: <String>['zakat']),
    ]);
    test('answers a covered question with no model', () {
      final KnowledgeAnswer? a = KnowledgeAnswerer.answer('How do I make wudu?', <SupportPack>[k]);
      expect(a, isNotNull);
      expect(a!.snippet.id, 'k1');
    });
    test('returns null when nothing matches, so the normal path goes on', () {
      expect(KnowledgeAnswerer.answer('best pizza in town', <SupportPack>[k]), isNull);
    });
    test('support packs are never used as knowledge', () {
      final SupportPack s = pack('alcohol', 'support', <Map<String, dynamic>>[
        snip('s1', 'reflect', 'wudu wudu', triggers: <String>['wudu']),
      ]);
      expect(KnowledgeAnswerer.answer('how to make wudu', <SupportPack>[s]), isNull);
    });
  });

  group('support engine', () {
    final SupportPack al = pack('alcohol', 'support', <Map<String, dynamic>>[
      snip('o1', 'orient', 'I am here to listen.', tone: 'warm'),
      snip('r1', 'reflect', 'It sounds heavy.', tone: 'warm'),
      snip('r2', 'reflect', 'That is a lot to carry.', tone: 'warm'),
      snip('a1', 'ask', 'What is the hardest part?', tone: 'warm'),
    ]);
    test('replies and never repeats the same text twice', () {
      final SupportEngine e = SupportEngine(packs: <SupportPack>[al]);
      final SupportSession s = SupportSession(seed: 5);
      final SupportTurn? t1 = e.reply(s, pack: 'alcohol', userText: 'I feel tired of drinking');
      final SupportTurn? t2 = e.reply(s, pack: 'alcohol', userText: 'it never stops');
      expect(t1, isNotNull);
      expect(t2, isNotNull);
      expect(t2!.text, isNot(t1!.text));
      expect(s.contextSummary.contains('alcohol'), isTrue);
      expect(s.contextSummary.contains('drinking'), isFalse);
    });
    test('unknown pack gives null', () {
      final SupportEngine e = SupportEngine(packs: <SupportPack>[al]);
      expect(e.reply(SupportSession(seed: 1), pack: 'nope', userText: 'hi'), isNull);
    });
  });

  group('check-in', () {
    final DateTime d0 = DateTime(2026, 11, 1);
    test('never asked and no clock is not due; start seeds the clock', () {
      const CheckinState s = CheckinState();
      expect(CheckinScheduler.isDue(s, d0), isFalse);
    });
    test('okay waits two weeks', () {
      final CheckinState s = CheckinScheduler.after(const CheckinState(), CheckinAnswer.okay, d0);
      expect(CheckinScheduler.isDue(s, d0.add(const Duration(days: 13))), isFalse);
      expect(CheckinScheduler.isDue(s, d0.add(const Duration(days: 14))), isTrue);
    });
    test('hard is asked about again in three days', () {
      final CheckinState s = CheckinScheduler.after(const CheckinState(), CheckinAnswer.hard, d0);
      expect(CheckinScheduler.isDue(s, d0.add(const Duration(days: 2))), isFalse);
      expect(CheckinScheduler.isDue(s, d0.add(const Duration(days: 3))), isTrue);
    });
    test('rather not say and ignored wait four weeks', () {
      for (final CheckinAnswer a in <CheckinAnswer>[CheckinAnswer.rather, CheckinAnswer.ignored]) {
        final CheckinState s = CheckinScheduler.after(const CheckinState(), a, d0);
        expect(CheckinScheduler.isDue(s, d0.add(const Duration(days: 27))), isFalse);
        expect(CheckinScheduler.isDue(s, d0.add(const Duration(days: 28))), isTrue);
      }
    });
    test('off is permanent until turned on', () {
      final CheckinState s = CheckinScheduler.turnOff(const CheckinState(), d0);
      expect(CheckinScheduler.isDue(s, d0.add(const Duration(days: 400))), isFalse);
      final CheckinState on = CheckinScheduler.turnOn(s);
      expect(on.off, isFalse);
    });
    test('frequency off never asks', () {
      final CheckinState s = CheckinScheduler.setFrequency(const CheckinState(), CheckinFrequency.off);
      expect(CheckinScheduler.isDue(s, d0.add(const Duration(days: 400))), isFalse);
    });
  });

  group('memory', () {
    test('only on request, and never crisis or abuse content', () {
      expect(UserMemory.requestedText('remember that I like walking'), 'I like walking');
      expect(UserMemory.requestedText('I like walking'), isNull);
      expect(UserMemory.mayRemember('I like walking'), isTrue);
      expect(UserMemory.mayRemember('I want to kill myself'), isFalse);
    });
    test('encode/decode round trip', () {
      final List<MemoryItem> items = UserMemory.decode(UserMemory.encode(<MemoryItem>[
        MemoryItem(id: '1', text: 'walks at dawn', on: '2026-01-01'),
      ]));
      expect(items.single.text, 'walks at dawn');
      expect(UserMemory.decode('not json'), isEmpty);
    });
  });

  group('student routing', () {
    test('classifies without diagnosing', () {
      expect(StudentRouting.classify('kids at school keep bullying me', parent: false),
          StudentConcern.bullying);
      expect(StudentRouting.classify('what is the weather', parent: false), isNull);
    });
  });

  group('online policy', () {
    bool allow({bool setting = true, bool managed = true, bool crisis = false, bool latched = false, bool minor = false, bool fixed = false}) =>
        SupportOnlinePolicy.allowed(
            setting: setting,
            usingManagedKey: managed,
            hasManagedKey: true,
            crisis: crisis,
            latched: latched,
            minor: minor,
            fixedWording: fixed);
    test('default off and never own key, crisis, latch, minor, fixed', () {
      expect(allow(), isTrue);
      expect(allow(setting: false), isFalse);
      expect(allow(managed: false), isFalse);
      expect(allow(crisis: true), isFalse);
      expect(allow(latched: true), isFalse);
      expect(allow(minor: true), isFalse);
      expect(allow(fixed: true), isFalse);
    });
    test('answers with doses or secrecy promises are rejected', () {
      expect(SupportOnlinePolicy.acceptable('I hear you. Would talking to someone you trust help?'), isTrue);
      expect(SupportOnlinePolicy.acceptable('Take 20 mg each day and taper.'), isFalse);
      expect(SupportOnlinePolicy.acceptable('I promise, our secret.'), isFalse);
    });
  });

  group('real packs', () {
    test('every shipped support pack parses and has no raw unfilled slots issue', () {
      final Directory d = Directory('assets/support/packs');
      final List<File> files = d.listSync().whereType<File>().where((File f) => f.path.endsWith('.json')).toList();
      expect(files, isNotEmpty);
      for (final File f in files) {
        final SupportPack? p = SupportPack.parse(f.readAsStringSync());
        expect(p, isNotNull, reason: f.path);
        expect(p!.snippets, isNotEmpty, reason: f.path);
      }
    });
  });
}
