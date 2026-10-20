import 'dart:io';
import 'dart:math';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/academy/application/family_service.dart';
import 'package:ar_rayaan/features/academy/application/wasia_controller.dart';
import 'package:ar_rayaan/features/academy/data/offline_wasia_provider.dart';
import 'package:ar_rayaan/features/academy/domain/children_privacy.dart';
import 'package:ar_rayaan/features/academy/presentation/academy_family.dart';
import 'package:ar_rayaan/features/academy/presentation/widgets/parent_gate.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Child-privacy package: parent gate (widget test), consent, delete-child,
/// no child name to Firestore or any AI service, Wasia safety.
void main() {
  group('ParentGateChallenge', () {
    test('accepts only the right product, ignoring spaces', () {
      const ParentGateChallenge c = ParentGateChallenge(14, 6);
      expect(c.answer, 84);
      expect(c.question, 'What is 14 × 6?');
      expect(c.accepts('84'), isTrue);
      expect(c.accepts(' 84 '), isTrue);
      expect(c.accepts('83'), isFalse);
      expect(c.accepts(''), isFalse);
      expect(c.accepts('eighty-four'), isFalse);
    });

    test('generated questions stay in range and vary', () {
      final Random rng = Random(7);
      final Set<int> answers = <int>{};
      for (int i = 0; i < 200; i++) {
        final ParentGateChallenge c = ParentGateChallenge.generate(rng);
        expect(c.a, inInclusiveRange(12, 19));
        expect(c.b, inInclusiveRange(3, 9));
        answers.add(c.answer);
      }
      expect(answers.length, greaterThan(10));
    });

    test('the gate opens for five minutes, then closes', () {
      final ParentGateNotifier g = ParentGateNotifier();
      final DateTime t = DateTime(2026, 10, 20, 12);
      expect(g.isOpen(t), isFalse);
      g.unlock(t);
      expect(g.isOpen(t.add(const Duration(minutes: 4))), isTrue);
      expect(g.isOpen(t.add(const Duration(minutes: 6))), isFalse);
      g.unlock(t);
      g.lock();
      expect(g.isOpen(t), isFalse);
    });
  });

  group('parent gate widget', () {
    Future<void> open(WidgetTester tester, List<bool> results) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark(),
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  results.add(await showParentGate(
                    context,
                    challenge: const ParentGateChallenge(12, 5),
                  ));
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows the question and passes on the right answer',
        (WidgetTester tester) async {
      final List<bool> results = <bool>[];
      await open(tester, results);
      expect(find.text('For parents'), findsOneWidget);
      expect(find.text('What is 12 × 5?'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '60');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(results, <bool>[true]);
      expect(find.text('For parents'), findsNothing);
    });

    testWidgets('a wrong answer keeps the gate shut and says so',
        (WidgetTester tester) async {
      final List<bool> results = <bool>[];
      await open(tester, results);
      await tester.enterText(find.byType(TextField), '61');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(results, isEmpty, reason: 'dialog still open');
      expect(find.textContaining('Not quite'), findsOneWidget);
      expect(find.text('For parents'), findsOneWidget);
      // Cancel closes it with false.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(results, <bool>[false]);
    });
  });

  group('Family Wing is behind the gate', () {
    Future<Widget> app({required bool unlocked}) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'ar.family.children':
            '[{"id":"c1","name":"Hidden Name","createdAt":"2026-10-20T10:00:00.000"}]',
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          parentGateProvider.overrideWith((Ref ref) {
            final ParentGateNotifier n = ParentGateNotifier();
            if (unlocked) n.unlock();
            return n;
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const FamilyScreen(),
        ),
      );
    }

    testWidgets('locked: no child name, no progress, only the parent prompt',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(430, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(await app(unlocked: false));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('I am a parent or guardian'), findsOneWidget);
      expect(find.textContaining('Hidden Name'), findsNothing);
      expect(find.text('Add child'), findsNothing);
    });

    testWidgets('unlocked: the child, the delete button and the privacy card',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(430, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(await app(unlocked: true));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Hidden Name'), findsOneWidget);
      expect(find.byTooltip('Delete Hidden Name'), findsOneWidget);
      expect(find.text('Add child'), findsOneWidget);
      expect(find.text('PRIVACY AND CONTROLS'), findsOneWidget);
    });
  });

  group('FamilyService privacy', () {
    setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

    test('consent is absent until a parent records it', () async {
      final FamilyService f = FamilyService();
      expect(await f.hasConsent(), isFalse);
      await f.recordConsent();
      expect(await f.hasConsent(), isTrue);
    });

    test('names are trimmed and capped at 30 characters', () async {
      final FamilyService f = FamilyService();
      await f.addChild('   ${'x' * 50}   ');
      final List<Map<String, dynamic>> kids = await f.children();
      expect((kids.single['name'] as String).length, 30);
    });

    test('deleteChild removes the child, their progress and the active pointer',
        () async {
      final FamilyService f = FamilyService();
      final String a = await f.addChild('Amal');
      final String b = await f.addChild('Bilal');
      await f.markLessonDone(a, 'letters-01', quizCorrect: true);
      await f.recordExam(a, 'u1-exam', score: 8, total: 10);
      expect(await f.activeChildId(), b, reason: 'last added is active');

      expect(await f.deleteChild(a), isTrue);
      final List<Map<String, dynamic>> kids = await f.children();
      expect(kids.map((Map<String, dynamic> c) => c['id']), <String>[b]);
      final Map<String, dynamic> gone = await f.progress(a);
      expect((gone['lessons'] as Map<dynamic, dynamic>), isEmpty);
      expect((gone['exams'] as Map<dynamic, dynamic>), isEmpty);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('ar.family.progress.$a'), isNull);

      expect(await f.deleteChild(b), isTrue);
      expect(await f.children(), isEmpty);
      expect(await f.activeChildId(), isNull);
      expect(await f.deleteChild('nobody'), isFalse);
    });

    test('deleting the active child hands the pointer to a remaining child',
        () async {
      final FamilyService f = FamilyService();
      final String a = await f.addChild('Amal');
      final String b = await f.addChild('Bilal');
      await f.setActiveChild(a);
      await f.deleteChild(a);
      expect(await f.activeChildId(), b);
    });

    test('deleteAllChildren wipes every trace and withdraws consent',
        () async {
      final FamilyService f = FamilyService();
      await f.recordConsent();
      final String a = await f.addChild('Amal');
      await f.markLessonDone(a, 'letters-01', quizCorrect: true);
      await f.deleteAllChildren();
      expect(await f.children(), isEmpty);
      expect(await f.activeChildId(), isNull);
      expect(await f.hasConsent(), isFalse);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> leftovers = prefs
          .getKeys()
          .where((String k) => k.startsWith('ar.family.'))
          .toList();
      expect(leftovers, isEmpty, reason: 'left behind: $leftovers');
    });

    test('cloud sync is off by default and the cloud document has no name',
        () async {
      final FamilyService f = FamilyService();
      expect(await f.cloudConsented(), isFalse);
      final Map<String, dynamic> doc = FamilyService.cloudChildDoc(
        <String, dynamic>{
          'id': 'c1',
          'name': 'Secret',
          'createdAt': '2026-10-20T10:00:00.000',
        },
      );
      expect(doc.containsKey('name'), isFalse);
      expect(doc.values.join(' ').contains('Secret'), isFalse);
    });

    test('the sync code never reads a child name', () {
      final String src =
          File('lib/features/academy/application/family_service.dart')
              .readAsStringSync();
      final String cloud = src.substring(src.indexOf('Future<void> _syncCloud'));
      expect(cloud.contains("['name']"), isFalse);
      expect(cloud.contains("'name'"), isFalse);
    });
  });

  group('no child name reaches an AI service', () {
    test('the parent prompt never contains the child name', () {
      final String p = personaPrompt(
        WasiaPersona.parent,
        childName: 'Rayaan',
        lessonsDone: 5,
        examsTaken: 1,
      );
      expect(p.contains('Rayaan'), isFalse);
      expect(p, contains('5 of 28'));
    });

    test('the student prompt carries progress only', () {
      final String p = personaPrompt(
        WasiaPersona.student,
        childName: 'Hadi',
        studentBlock: 'This student has completed 3 of 28 letter lessons.',
      );
      expect(p.contains('Hadi'), isFalse);
      expect(p, contains('3 of 28'));
    });

    test('the system prompt forbids asking for personal details', () {
      expect(kWasiaSystemPrompt, contains('Never ask for, repeat or use'));
      expect(kWasiaSystemPrompt, contains('Never give a religious ruling'));
    });
  });

  group('Wasia safety', () {
    Future<ProviderContainer> container() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return ProviderContainer(overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
    }

    test('a worrying message gets the fixed reply and no provider call',
        () async {
      final ProviderContainer c = await container();
      addTearDown(c.dispose);
      final String reply = await c
          .read(wasiaControllerProvider.notifier)
          .ask('I want to kill myself', persona: WasiaPersona.student);
      expect(reply, wasiaCrisisReply(WasiaPersona.student));
      expect(reply, contains('trust'));
      expect(RegExp(r'\d{3,}').hasMatch(reply), isFalse,
          reason: 'no phone number is ever invented');
      final List<HadiMessage> msgs = c.read(wasiaControllerProvider).messages;
      expect(msgs.length, 2);
      expect(msgs.every((HadiMessage m) => m.sensitive), isTrue);
      expect(msgs.last.crisis, isNotNull);
    });

    test('an adult hears a different, adult reply', () {
      expect(wasiaCrisisReply(WasiaPersona.parent),
          isNot(wasiaCrisisReply(WasiaPersona.student)));
    });

    test('a child is answered from the shelf by default (AI off)', () async {
      final ProviderContainer c = await container();
      addTearDown(c.dispose);
      expect(await WasiaController.childLlmAllowed(), isFalse);
      final String reply = await c
          .read(wasiaControllerProvider.notifier)
          .ask('tell me about the letter alif', persona: WasiaPersona.student);
      expect(reply, contains('Alif'));
    });

    test('the AI switch for children is stored and reversible', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await WasiaController.setChildLlmAllowed(true);
      expect(await WasiaController.childLlmAllowed(), isTrue);
      await WasiaController.setChildLlmAllowed(false);
      expect(await WasiaController.childLlmAllowed(), isFalse);
    });
  });

  group('offline Wasia matching', () {
    test('keywords match whole words only', () {
      final String q = OfflineWasiaProvider.normalise('Tell me about it!');
      expect(OfflineWasiaProvider.matches(q, 'ba'), isFalse,
          reason: '"ba" must not fire inside "about"');
      expect(OfflineWasiaProvider.matches(q, 'ta'), isFalse);
      expect(OfflineWasiaProvider.matches(q, 'about'), isTrue);
      expect(
        OfflineWasiaProvider.matches(
            OfflineWasiaProvider.normalise('what is the letter ba?'), 'ba'),
        isTrue,
      );
    });

    test('it no longer asks for a child’s name or describes the old screen',
        () async {
      const OfflineWasiaProvider p = OfflineWasiaProvider();
      final String progress =
          await p.ask('how is my child doing', const <HadiMessage>[]);
      expect(progress.toLowerCase().contains('name'), isFalse);
      final String add =
          await p.ask('how do I add a child', const <HadiMessage>[]);
      expect(add, contains('on this device only'));
    });

    test('an unknown question is declined honestly', () async {
      const OfflineWasiaProvider p = OfflineWasiaProvider();
      final String r =
          await p.ask('is it halal to trade shares', const <HadiMessage>[]);
      expect(r, OfflineWasiaProvider.decline);
    });
  });

  group('children’s privacy text', () {
    test('states what the app really does', () {
      expect(kChildrenPrivacySection, contains('only on the device'));
      expect(kChildrenPrivacySection, contains('never included'));
      expect(kChildrenPrivacySection, contains('parent'));
      expect(kChildrenPrivacySection.contains('scholar-reviewed'), isFalse);
      expect(kChildrenPrivacyBullets.length, greaterThanOrEqualTo(5));
    });
  });
}
