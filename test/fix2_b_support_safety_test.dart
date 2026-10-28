import 'package:ar_rayaan/features/academy/application/family_service.dart';
import 'package:ar_rayaan/features/academy/presentation/widgets/parent_gate.dart';
import 'package:ar_rayaan/features/academy/presentation/wasia_lessons.dart';
import 'package:ar_rayaan/features/kids/presentation/kids_pages.dart';
import 'package:ar_rayaan/features/sakina/domain/crisis_detector.dart';
import 'package:ar_rayaan/features/support/domain/child_distress.dart';
import 'package:ar_rayaan/features/support/domain/safe_replies.dart';
import 'package:ar_rayaan/features/support/presentation/support_pathway_screens.dart';
import 'package:ar_rayaan/features/support/presentation/teacher_guidance_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fix round 2, pass B: support, safety and kids / parent safety.
void main() {
  group('child distress wording', () {
    test('someone touched me has its own wording, with belief and no blame', () {
      expect(ChildDistress.detect('someone touched me and it felt wrong'),
          ChildDistressKind.touch);
      expect(ChildDistress.detect('the story where he touched the stone'),
          isNull);
      for (final String band in <String>['5-8', '9-12', '13-17']) {
        final String r = ChildDistress.reply(ChildDistressKind.touch, band);
        expect(r, contains('I believe you'));
        expect(r, contains('not your fault'));
      }
    });

    test('"I believe you" is for harm disclosures, not for a sad day', () {
      for (final String band in <String>['5-8', '9-12', '13-17']) {
        expect(ChildDistress.reply(ChildDistressKind.school, band),
            isNot(contains('I believe you')));
        expect(ChildDistress.reply(ChildDistressKind.school, band),
            isNot(contains('not your fault')));
      }
    });

    test('school unhappiness is not the same words twice', () {
      final Set<String> seen = <String>{
        for (int i = 0; i < 3; i++)
          ChildDistress.reply(ChildDistressKind.school, '9-12', prior: i),
      };
      expect(seen.length, 3);
    });

    test('the secrecy answers differ with the question', () {
      final String a = ChildDistress.reply(ChildDistressKind.secret, '9-12',
          text: 'will you tell my mum');
      final String b = ChildDistress.reply(ChildDistressKind.secret, '9-12',
          text: 'promise you will keep a secret');
      expect(a, isNot(b));
      expect(a.toLowerCase(), contains('i will not tell anyone'));
      expect(b.toLowerCase(), contains('i will not tell anyone'));
    });

    test('the self-harm card for a child is short and asks about safety',
        () {
      final String small = ChildDistress.selfHarmCard('5-8');
      expect(small, contains('Are you safe right now?'));
      expect(small, contains('grown-up you trust'));
      expect(small.contains('I believe you'), isFalse);
      expect(small.length,
          lessThan(ChildDistress.disclosureCard('5-8').length));
      expect(ChildDistress.cardFor(CrisisKind.selfHarm, '5-8'), small);
      expect(ChildDistress.cardFor(CrisisKind.abuse, '5-8'),
          ChildDistress.disclosureCard('5-8'));
    });
  });

  group('leaving, khula and 4:34 when not safe', () {
    test('a safety worry with khula or divorce gets the options reply', () {
      expect(LeavingQuestion.detect('Can a woman ask khula if she is not safe?'),
          isTrue);
      expect(LeavingQuestion.detect('my husband hits me, can I get a divorce'),
          isTrue);
      expect(LeavingQuestion.detect('does 4:34 allow him to hit me, I am afraid'),
          isTrue);
    });

    test('a plain question about khula is not the safety card', () {
      expect(LeavingQuestion.detect('What is khula?'), isFalse);
      expect(LeavingQuestion.detect('how do I make wudu'), isFalse);
    });

    test('the reply gives options, no ruling and no verse in place of safety',
        () {
      expect(LeavingQuestion.options, contains('Are you safe right now?'));
      expect(LeavingQuestion.options, contains('lawyer'));
      expect(LeavingQuestion.options, contains('scholar'));
      expect(RegExp(r'\d{4,}').hasMatch(LeavingQuestion.options), isFalse,
          reason: 'no phone number is typed in a reply');
    });
  });

  group('parent gate', () {
    test('the window is five minutes and slides while the parent is active',
        () {
      final ParentGateNotifier g = ParentGateNotifier();
      final DateTime t = DateTime(2026, 10, 27, 9);
      g.unlock(t);
      expect(g.isOpen(t.add(const Duration(minutes: 4))), isTrue);
      g.touch(t.add(const Duration(minutes: 4)));
      expect(g.isOpen(t.add(const Duration(minutes: 8))), isTrue);
      expect(g.isOpen(t.add(const Duration(minutes: 10))), isFalse);
    });

    test('a tap never opens a closed gate', () {
      final ParentGateNotifier g = ParentGateNotifier();
      g.touch(DateTime(2026, 10, 27, 9));
      expect(g.isOpen(DateTime(2026, 10, 27, 9)), isFalse);
    });
  });

  group('adding a child twice', () {
    test('the same name within seconds is one child', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final FamilyService f = FamilyService();
      final String a = await f.addChild('Amal');
      final String b = await f.addChild(' amal ');
      expect(b, a);
      expect((await f.children()).length, 1);
      await f.addChild('Bilal');
      expect((await f.children()).length, 2);
    });
  });

  group('pages and openers', () {
    test('the support opener names the page and starts with safety on an urgent one',
        () {
      final SupportPathway urgent = pathwayById('domestic-abuse')!;
      expect(hadiOpenerFor(urgent), contains(urgent.title));
      expect(hadiOpenerFor(urgent), contains('safe right now'));
      final SupportPathway calm = pathwayById('gambling')!;
      expect(hadiOpenerFor(calm), contains(calm.title));
      expect(hadiOpenerFor(calm).contains('Hello'), isFalse);
    });

    test('the porn page does not point at drug or alcohol lines', () {
      expect(pathwayById('porn')!.scope, 'compulsive');
    });

    test('the grown-ups page matches what the parent can see', () {
      final String all = kGrownupsCanSee.join(' ');
      expect(all, contains('nickname'));
      expect(all, contains('cannot see what you type to Wasia'));
      for (final String l in <String>[...kGrownupsCanSee, ...kGrownupsAdvice]) {
        expect(l.contains('—'), isFalse);
      }
    });

    test('the teacher page is guidance, with a source for its hadith', () {
      final String all = kTeacherGuidanceSections
          .expand((s) => s.points)
          .join(' ');
      expect(all, contains('Sahih al-Bukhari 5997'));
      expect(all.toLowerCase(), contains('safeguarding lead'));
      expect(all.toLowerCase(), contains('do not promise to keep it secret'));
    });

    test('a long teaching step is shortened for 5-8 only', () {
      const String t = 'One. Two. Three. Four.';
      expect(ageFitTeaching(t, '5-8'), 'One. Two.');
      expect(ageFitTeaching(t, '9-12'), t);
      expect(ageFitTeaching('Short one. Two.', '5-8'), 'Short one. Two.');
    });
  });
}
