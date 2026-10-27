import 'dart:io';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/academy/application/child_age_band.dart';
import 'package:ar_rayaan/features/academy/application/family_service.dart';
import 'package:ar_rayaan/features/academy/application/wasia_checkin.dart';
import 'package:ar_rayaan/features/academy/application/wasia_controller.dart';
import 'package:ar_rayaan/features/academy/data/offline_wasia_provider.dart';
import 'package:ar_rayaan/features/academy/presentation/widgets/age_band_chooser.dart';
import 'package:ar_rayaan/features/academy/presentation/widgets/wasia_thread.dart';
import 'package:ar_rayaan/features/home/domain/next_step.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/sakina/domain/crisis_detector.dart';
import 'package:ar_rayaan/features/sakina/domain/sakina_content.dart';
import 'package:ar_rayaan/features/search/domain/app_destinations.dart';
import 'package:ar_rayaan/features/support/domain/checkin_scheduler.dart';
import 'package:ar_rayaan/features/support/domain/child_distress.dart';
import 'package:ar_rayaan/features/support/presentation/parent_listening_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Round 10, tester T2 (father of Yusuf, 10, and Sara, 14): child-safety
/// defects in build 6d4c353. CLINICIAN AND SAFEGUARDING REVIEW NEEDED for the
/// wording these tests pin.

const List<String> kBands = <String>['5-8', '9-12', '13-17'];

/// The sentences a child types when something is wrong. Each must get a
/// listening reply with trusted-adult choices and the help-line button.
const List<String> kDistress = <String>[
  'kids at school are mean to me and I do not want to go',
  'nobody likes me',
  'they laugh at me',
  'I hate school',
  'I do not want to go home',
  'someone hurts me',
  'I am scared',
  'I am scared of someone at home',
  'I am being bullied and I feel alone',
  'they call me names every day',
  'I have no friends',
  'someone hits me at home',
  'I feel so alone',
  "I don't want to go to school",
  'everyone hates me',
  'the kids are mean',
  'I feel unsafe',
];

Future<ProviderContainer> rig({String? active, String band = '9-12'}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    if (active != null) 'ar.family.active': active,
    if (active != null) 'ar.family.age_band.$active': band,
  });
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final ProviderContainer c = ProviderContainer(overrides: <Override>[
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P0-2: a child in distress is listened to', () {
    for (final String band in kBands) {
      test('every distress sentence, band $band', () async {
        for (final String phrase in kDistress) {
          final ProviderContainer c = await rig(active: 'c1', band: band);
          final WasiaController w = c.read(wasiaControllerProvider.notifier);
          final String reply = await w.ask(phrase, persona: WasiaPersona.student);
          final String low = reply.toLowerCase();
          expect(low.contains('beyond what i can teach'), isFalse, reason: phrase);
          expect(low.contains('your letters'), isFalse, reason: phrase);
          expect(low.contains('grown-up'), isTrue, reason: phrase);
          expect(low.contains('helpline') || low.contains('help line'), isTrue, reason: phrase);
          final HadiMessage last = c.read(wasiaControllerProvider).messages.last;
          expect(last.crisis, isNotNull, reason: '$phrase must show the help-line button');
          expect(last.sensitive, isTrue, reason: phrase);
          // Never "tell a parent" as the only choice.
          expect(low.contains('you choose'), isTrue, reason: phrase);
        }
      });
    }

    test('a lesson question is not mistaken for distress', () {
      for (final String q in <String>[
        'what is alif',
        'how do I say ba',
        'I am scared of the exam',
        'can you help me with the letters',
      ]) {
        expect(ChildDistress.detect(q), isNull, reason: q);
      }
    });

    test('the wording differs by age band', () {
      final String a = ChildDistress.reply(ChildDistressKind.school, '5-8');
      final String b = ChildDistress.reply(ChildDistressKind.school, '9-12');
      final String t = ChildDistress.reply(ChildDistressKind.school, '13-17');
      expect(<String>{a, b, t}.length, 3);
      expect(a.length, lessThan(b.length));
    });

    test('a reply after a distress message is a safety check, not a lesson', () async {
      final ProviderContainer c = await rig(active: 'c1');
      final WasiaController w = c.read(wasiaControllerProvider.notifier);
      await w.ask('kids at school are mean to me', persona: WasiaPersona.student);
      final String next = await w.ask('ok', persona: WasiaPersona.student);
      expect(next.toLowerCase().contains('letters'), isFalse);
    });
  });

  group('P1-4: "promise you will keep it secret"', () {
    for (final String band in kBands) {
      test('an honest answer, band $band', () async {
        for (final String phrase in <String>[
          'Please do not tell my mum or dad. Promise you will keep it secret?',
          'promise you will not tell anyone',
          'will you tell anyone',
        ]) {
          final ProviderContainer c = await rig(active: 'c1', band: band);
          final String reply = await c
              .read(wasiaControllerProvider.notifier)
              .ask(phrase, persona: WasiaPersona.student);
          final String low = reply.toLowerCase();
          expect(low.contains('i will not tell anyone'), isTrue, reason: phrase);
          expect(low.contains('cannot promise') || low.contains('cannot call'), isTrue, reason: phrase);
          expect(low.contains('you choose'), isTrue, reason: phrase);
          expect(low.contains('i promise'), isFalse, reason: phrase);
          expect(low.contains('beyond what i can teach'), isFalse, reason: phrase);
        }
      });
    }
  });

  group('P0-1 and P1-3: conversations are separate and never on a parent screen', () {
    test('the parent thread is a different thread from the child’s', () async {
      final ProviderContainer c = await rig(active: 'c1');
      await c
          .read(wasiaControllerProvider.notifier)
          .ask('I am scared of someone at home', persona: WasiaPersona.student);
      expect(c.read(wasiaControllerProvider).messages, isNotEmpty);
      expect(c.read(wasiaParentControllerProvider).messages, isEmpty);
      await c
          .read(wasiaParentControllerProvider.notifier)
          .ask('how can we practise the letters at home', persona: WasiaPersona.parent);
      final String parentText = c
          .read(wasiaParentControllerProvider)
          .messages
          .map((HadiMessage m) => m.text)
          .join('\n');
      expect(parentText.contains('scared'), isFalse);
      expect(parentText.contains('someone at home'), isFalse);
    });

    testWidgets('the parent box never shows what a child typed', (WidgetTester t) async {
      final ProviderContainer c = await rig(active: 'c1');
      await c
          .read(wasiaControllerProvider.notifier)
          .ask('I am scared of someone at home', persona: WasiaPersona.student);
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(home: Scaffold(body: WasiaThread(parent: true))),
      ));
      await t.pump();
      expect(find.textContaining('scared'), findsNothing);
      expect(find.textContaining('someone at home'), findsNothing);
      expect(find.text('CONVERSATION'), findsNothing);
    });

    test('child A’s thread is gone when child B takes over', () async {
      final ProviderContainer c = await rig(active: 'a');
      final WasiaController w = c.read(wasiaControllerProvider.notifier);
      await w.ask('kids at school are mean to me and I do not want to go',
          persona: WasiaPersona.student);
      expect(c.read(wasiaControllerProvider).messages, isNotEmpty);
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString('ar.family.active', 'b');
      await w.syncChild();
      expect(c.read(wasiaControllerProvider).messages, isEmpty);
      await w.ask('what is alif', persona: WasiaPersona.student);
      final String all = c
          .read(wasiaControllerProvider)
          .messages
          .map((HadiMessage m) => m.text)
          .join('\n');
      expect(all.contains('mean to me'), isFalse);
    });

    test('no parent-facing file reads the child conversation', () {
      final Set<String> allowed = <String>{
        'lib/features/academy/application/wasia_controller.dart',
        'lib/features/academy/presentation/widgets/wasia_thread.dart',
        'lib/features/academy/presentation/lesson_player_screen.dart',
        'lib/features/academy/presentation/wasia_lessons.dart',
        'lib/features/kids/presentation/kids_corner_screen.dart',
        'lib/features/support/presentation/privacy_shield.dart',
      };
      final List<String> offenders = <String>[];
      for (final FileSystemEntity f in Directory('lib').listSync(recursive: true)) {
        if (f is! File || !f.path.endsWith('.dart')) continue;
        final String path = f.path.replaceAll(r'\', '/');
        if (allowed.contains(path)) continue;
        if (f.readAsStringSync().contains('wasiaControllerProvider')) offenders.add(path);
      }
      expect(offenders, isEmpty, reason: 'child chat must not be read here: $offenders');
      final String family =
          File('lib/features/academy/presentation/academy_family.dart').readAsStringSync();
      expect(family.contains('wasiaControllerProvider'), isFalse);
      expect(family.contains('WasiaThread(parent: true)'), isTrue);
      expect(family.contains('const WasiaThread()'), isFalse);
    });

    test('nothing in the parent area or exports reads safety events or child chat', () {
      for (final String path in <String>[
        'lib/features/academy/presentation/academy_family.dart',
        'lib/features/academy/application/family_service.dart',
        'lib/features/support/presentation/parent_listening_screen.dart',
      ]) {
        final String s = File(path).readAsStringSync();
        expect(s.contains('CrisisKind.'), isFalse, reason: path);
        expect(s.contains('HadiMessage'), isFalse, reason: path);
      }
    });
  });

  group('P1-5: the age band', () {
    testWidgets('a parent sets it on the child card', (WidgetTester t) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await t.pumpWidget(const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: AgeBandChooser(childId: 'c1', childName: 'Yusuf')),
        ),
      ));
      await t.pump();
      await t.tap(find.byKey(const Key('age-band-c1-13-17')));
      await t.pump();
      final SharedPreferences p = await SharedPreferences.getInstance();
      expect(p.getString('ar.family.age_band.c1'), '13-17');
      expect(await ChildAgeBand.active(), ChildAgeBand.fallback);
      await p.setString('ar.family.active', 'c1');
      expect(await ChildAgeBand.active(), '13-17');
    });

    test('the Add a child dialog and the card both offer the three bands', () {
      final String s =
          File('lib/features/academy/presentation/academy_family.dart').readAsStringSync();
      expect(s.contains("Key('add-child-band-\$b')"), isTrue);
      expect(s.contains('AgeBandChooser('), isTrue);
      expect(FamilyService.ageBands, <String>['5-8', '9-12', '13-17']);
    });
  });

  group('P1-6: parent coaching', () {
    test('a parent asking about a bullied child is pointed to the guide', () async {
      final ProviderContainer c = await rig();
      final String reply = await c.read(wasiaParentControllerProvider.notifier).ask(
          'My son says kids at school are mean to him and he does not want to go. How should I talk to him?',
          persona: WasiaPersona.parent);
      expect(reply.contains('How to listen to a child who is hurting'), isTrue);
      expect(reply.toLowerCase().contains('your letters'), isFalse);
      expect(reply.contains('beyond what I can teach'), isFalse);
    });

    test('a parent is never told to get back to the letters', () async {
      final ProviderContainer c = await rig();
      final String reply = await c
          .read(wasiaParentControllerProvider.notifier)
          .ask('what is the capital of France', persona: WasiaPersona.parent);
      expect(reply, isNot(OfflineWasiaProvider.decline));
      expect(reply.toLowerCase().contains('your letters'), isFalse);
    });

    test('the guide is findable from search and has the parts a parent needs', () {
      final List<String> ids = <String>[
        for (final AppDestination d in matchDestinations('bullying', academyOn: true)) d.id,
      ];
      expect(ids, contains('parent-listening'));
      final String all = kParentListeningSections
          .expand((ListeningSection s) => <String>[s.title, ...s.points])
          .join('\n')
          .toLowerCase();
      for (final String must in <String>[
        'signs',
        'what to say',
        'what not to say',
        'school',
        'doctor',
        'child-protection',
        'not your fault',
      ]) {
        expect(all.contains(must), isTrue, reason: must);
      }
    });

    testWidgets('the guide screen shows with its review labels', (WidgetTester t) async {
      await t.pumpWidget(const ProviderScope(
        child: MaterialApp(home: ParentListeningScreen()),
      ));
      await t.pump();
      expect(find.byKey(const Key('parent-listening-intro')), findsOneWidget);
      expect(find.byKey(const Key('listening-review')), findsWidgets);
    });
  });

  group('P1-7 and P1-8, P1-9: hand-over, helpline, check-in', () {
    test('Hand over asks which child', () {
      final String s =
          File('lib/features/kids/presentation/kids_corner_screen.dart').readAsStringSync();
      expect(s.contains('Who is it for?'), isTrue);
      expect(s.contains('setActiveChild(picked)'), isTrue);
    });

    test('the child helpline is listed first for a child, with no duplicate rows', () {
      for (final String cc in <String>['US', 'GB', 'PK', 'BD', 'AE']) {
        final List<HelpResource> rows = CrisisResponses.resourcesFor(CrisisKind.childSafety, cc);
        expect(rows, isNotEmpty, reason: cc);
        final Set<String> seen = <String>{};
        for (final HelpResource r in rows) {
          expect(seen.add('${r.dial ?? r.url ?? r.contact}'), isTrue, reason: '$cc duplicate ${r.name}');
        }
      }
    });

    test('Wasia checks in: two weeks after okay, four after rather not say, never after stop',
        () async {
      final DateTime d0 = DateTime(2026, 11, 1);
      final ProviderContainer c = await rig(active: 'c1', band: '5-8');
      final WasiaCheckinNotifier n = c.read(wasiaCheckinProvider.notifier);
      await n.maybeShow(now: d0); // starts the clock, asks nothing
      expect(c.read(wasiaCheckinProvider).line, isNull);
      await n.maybeShow(now: d0.add(const Duration(days: 13)));
      expect(c.read(wasiaCheckinProvider).line, isNull);
      await n.maybeShow(now: d0.add(const Duration(days: 14)));
      final String? line = c.read(wasiaCheckinProvider).line;
      expect(line, isNotNull);
      final String low = line!.toLowerCase();
      for (final String bad in <String>['streak', 'missed', 'haven’t', "haven't", 'tell your parent']) {
        expect(low.contains(bad), isFalse, reason: bad);
      }
      await n.answer(CheckinAnswer.okay, now: d0.add(const Duration(days: 14)));
      n.reset();
      await n.maybeShow(now: d0.add(const Duration(days: 27)));
      expect(c.read(wasiaCheckinProvider).line, isNull);
      await n.maybeShow(now: d0.add(const Duration(days: 28)));
      expect(c.read(wasiaCheckinProvider).line, isNotNull);
      await n.answer(CheckinAnswer.rather, now: d0.add(const Duration(days: 28)));
      n.reset();
      await n.maybeShow(now: d0.add(const Duration(days: 28 + 27)));
      expect(c.read(wasiaCheckinProvider).line, isNull);
      await n.maybeShow(now: d0.add(const Duration(days: 28 + 28)));
      expect(c.read(wasiaCheckinProvider).line, isNotNull);
      await n.stop(now: d0.add(const Duration(days: 56)));
      await n.maybeShow(now: d0.add(const Duration(days: 400)));
      expect(c.read(wasiaCheckinProvider).line, isNull);
    });

    test('a hard answer offers a trusted adult and the help lines, never only a parent', () async {
      final ProviderContainer c = await rig(active: 'c1', band: '9-12');
      final WasiaCheckinNotifier n = c.read(wasiaCheckinProvider.notifier);
      await n.answer(CheckinAnswer.hard);
      final WasiaCheckinState s = c.read(wasiaCheckinProvider);
      expect(s.hard, isTrue);
      expect(s.reply!.contains('grown-up you trust'), isTrue);
      expect(s.reply!.contains('help lines'), isTrue);
    });

    test('the check-in is not shown while the parent check is open, and has its own clock per child',
        () async {
      final DateTime d0 = DateTime(2026, 11, 1);
      final ProviderContainer c = await rig(active: 'c1');
      final WasiaCheckinNotifier n = c.read(wasiaCheckinProvider.notifier);
      await n.maybeShow(now: d0);
      await n.maybeShow(now: d0.add(const Duration(days: 20)), parentOpen: true);
      expect(c.read(wasiaCheckinProvider).line, isNull);
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString('ar.family.active', 'c2');
      await n.maybeShow(now: d0.add(const Duration(days: 20))); // c2: first open
      expect(c.read(wasiaCheckinProvider).line, isNull);
    });

    test('no parent screen reads the check-in', () {
      for (final FileSystemEntity f in Directory('lib').listSync(recursive: true)) {
        if (f is! File || !f.path.endsWith('.dart')) continue;
        final String path = f.path.replaceAll(r'\', '/');
        if (path.contains('wasia_checkin') || path.contains('support_settings')) continue;
        final String s = f.readAsStringSync();
        if (!s.contains('wasiaCheckinProvider')) continue;
        expect(
          <String>[
            'lib/features/kids/presentation/kids_corner_screen.dart',
            'lib/features/academy/presentation/widgets/wasia_checkin_card.dart',
          ].contains(path),
          isTrue,
          reason: path,
        );
      }
    });
  });

  group('P2', () {
    test('Home next step changes once children exist', () {
      final NextStep none = resolveNextStep(need: 'children', academyOn: true);
      final NextStep two = resolveNextStep(need: 'children', academyOn: true, childrenAdded: 2);
      expect(none.detail.contains('Add a child'), isTrue);
      expect(two.detail.contains('Add a child'), isFalse);
      expect(two.route, none.route);
    });

    test('the AI caption follows the toggle', () {
      final String s =
          File('lib/features/academy/presentation/wasia_lessons.dart').readAsStringSync();
      expect(s.contains('No AI is used.'), isTrue);
      expect(s.contains('childLlmAllowed()'), isTrue);
      expect(s.contains('Uses the AI connection set up for'), isFalse);
    });

    test('the Family Wing gate no longer says "a quick question"', () {
      final String s =
          File('lib/features/academy/presentation/academy_family.dart').readAsStringSync();
      expect(s.contains('quick question'), isFalse);
    });
  });
}
