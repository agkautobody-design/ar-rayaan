import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/academy/application/academy_strings.dart';
import 'package:ar_rayaan/features/academy/application/family_service.dart';
import 'package:ar_rayaan/features/academy/application/recall_checks.dart';
import 'package:ar_rayaan/features/academy/application/wasia_controller.dart';
import 'package:ar_rayaan/features/academy/application/word_deck_provider.dart';
import 'package:ar_rayaan/features/academy/data/offline_wasia_provider.dart';
import 'package:ar_rayaan/features/academy/domain/academy_models.dart';
import 'package:ar_rayaan/features/academy/domain/children_privacy.dart';
import 'package:ar_rayaan/features/academy/domain/continue_hero.dart';
import 'package:ar_rayaan/features/academy/domain/course_manifest.dart';
import 'package:ar_rayaan/features/academy/domain/daily_verse.dart';
import 'package:ar_rayaan/features/academy/domain/dhikr_session.dart';
import 'package:ar_rayaan/features/academy/domain/letter_drills.dart';
import 'package:ar_rayaan/features/academy/domain/letters_meta.dart';
import 'package:ar_rayaan/features/academy/domain/next_lesson.dart';
import 'package:ar_rayaan/features/academy/domain/recall_check.dart';
import 'package:ar_rayaan/features/academy/domain/spaced_repetition.dart';
import 'package:ar_rayaan/features/academy/domain/word_deck.dart';
import 'package:ar_rayaan/features/academy/presentation/academy_family.dart';
import 'package:ar_rayaan/features/academy/presentation/lesson_player_screen.dart';
import 'package:ar_rayaan/features/academy/presentation/wasia_lessons.dart';
import 'package:ar_rayaan/features/academy/presentation/widgets/active_child_banner.dart';
import 'package:ar_rayaan/features/academy/presentation/widgets/parent_gate.dart';
import 'package:ar_rayaan/features/academy/presentation/widgets/wasia_thread.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fixes from the 21 Oct Academy review (P0 1-10, P1 13/16/18, P2 23-25).
class _Stub implements HadiProvider {
  _Stub({this.fail = false});

  final bool fail;
  final List<String> asked = <String>[];

  @override
  Future<String> ask(String question, List<HadiMessage> history) async {
    asked.add(question);
    if (fail) throw StateError('boom');
    return 'stub answer';
  }
}

class _Rig {
  _Rig(this.container, this.stub);

  final ProviderContainer container;
  final _Stub stub;

  WasiaController get wasia =>
      container.read(wasiaControllerProvider.notifier);
}

Future<_Rig> _rig({
  bool key = true,
  bool childAi = false,
  bool fail = false,
  Map<String, Object> extra = const <String, Object>{},
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    if (key) 'ar.hadi.apikey': 'test-key',
    if (childAi) kWasiaChildLlmPref: true,
    ...extra,
  });
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final _Stub stub = _Stub(fail: fail);
  final ProviderContainer c = ProviderContainer(overrides: <Override>[
    sharedPreferencesProvider.overrideWithValue(prefs),
    wasiaControllerProvider.overrideWith(
      (Ref ref) => WasiaController(
        ref,
        providerFor: (String name, String apiKey) => stub,
      ),
    ),
  ]);
  addTearDown(c.dispose);
  return _Rig(c, stub);
}

List<Lesson> _realLetterLessons() {
  final Map<String, dynamic> base = json.decode(
          File('assets/academy/letters_curriculum.json').readAsStringSync())
      as Map<String, dynamic>;
  final Map<String, dynamic> v2 = json.decode(
          File('assets/academy/letters_v2_curriculum.json')
              .readAsStringSync())
      as Map<String, dynamic>;
  final Map<String, dynamic> cur = mergeLettersCurriculum(base, v2);
  return <Lesson>[
    for (final dynamic u in cur['units'] as List<dynamic>)
      for (final dynamic l in (u as Map<dynamic, dynamic>)['lessons']
          as List<dynamic>)
        Lesson.fromJson(Map<String, dynamic>.from(l as Map<dynamic, dynamic>)),
  ];
}

Future<Widget> _app(
  Widget child, {
  List<Override> overrides = const <Override>[],
}) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: <Override>[
      sharedPreferencesProvider.overrideWithValue(prefs),
      ...overrides,
    ],
    child: MaterialApp(theme: AppTheme.dark(), home: Scaffold(body: child)),
  );
}

void _tall(WidgetTester tester, {double height = 2400}) {
  tester.view.physicalSize = Size(430, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('1. the child AI switch cannot be bypassed (default-deny)', () {
    test('a child stays on the shelf even with a key, switch off', () async {
      final _Rig r = await _rig();
      final String reply = await r.wasia
          .ask('tell me about the letter alif', persona: WasiaPersona.student);
      expect(reply, contains('Alif'));
      expect(r.stub.asked, isEmpty);
    });

    test('the teacher voice never reaches an AI service', () async {
      final _Rig r = await _rig(childAi: true);
      await r.wasia.ask('how do I sequence the letters',
          persona: WasiaPersona.teacher, parentVerified: true);
      expect(r.stub.asked, isEmpty);
      expect(await r.wasia.aiAllowedFor(WasiaPersona.teacher), isFalse);
    });

    test('a parent question needs the parent check to reach an AI service',
        () async {
      final _Rig r = await _rig();
      await r.wasia.ask('how can we practise at home',
          persona: WasiaPersona.parent);
      expect(r.stub.asked, isEmpty, reason: 'gate not passed: shelf only');
      r.wasia.clear();
      await r.wasia.ask('how can we practise at home',
          persona: WasiaPersona.parent, parentVerified: true);
      expect(r.stub.asked, hasLength(1));
    });

    test('with the switch on a child reaches the AI, and only the question',
        () async {
      final _Rig r = await _rig(childAi: true, extra: <String, Object>{
        'ar.family.children':
            '[{"id":"c1","name":"Amal","createdAt":"2026-10-20T10:00:00.000"}]',
        'ar.family.active': 'c1',
        'ar.family.progress.c1':
            '{"lessons":{"letters-01":{"at":"x","quizCorrect":true}},'
                '"exams":{"u1-exam":{"score":8,"total":10}},"mastery":{}}',
      });
      await r.wasia.ask('how do I say it', persona: WasiaPersona.student);
      expect(r.stub.asked, hasLength(1));
      final String sent = r.stub.asked.single;
      expect(sent, contains('Student asks: how do I say it'));
      for (final String leak in <String>[
        'Amal',
        'completed',
        'Most recent',
        'Last exam',
        'letters-01',
        'Lesson 1',
        '8/10',
      ]) {
        expect(sent.contains(leak), isFalse, reason: leak);
      }
    });

    test('a thread never mixes voices', () async {
      final _Rig r = await _rig(childAi: true);
      await r.wasia.ask('first', persona: WasiaPersona.student);
      expect(r.container.read(wasiaControllerProvider).messages, hasLength(2));
      await r.wasia.ask('second', persona: WasiaPersona.parent);
      final List<HadiMessage> msgs =
          r.container.read(wasiaControllerProvider).messages;
      expect(msgs.first.text, 'second', reason: 'old thread was dropped');
    });

    test('the exam screen source no longer has a Teachers corner', () {
      final String src = File(
              'lib/features/academy/presentation/academy_family.dart')
          .readAsStringSync();
      expect(src.contains("TEACHERS' CORNER"), isFalse);
      expect(src.contains('WasiaPersona.teacher'), isFalse);
      expect(src.contains('_TeacherWasiaBox'), isFalse);
    });

    testWidgets('the exam screen has no free-text box', (tester) async {
      _tall(tester);
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.pumpWidget(await _app(
        const ExamScreen(examId: 't-exam'),
        overrides: <Override>[
          lettersCurriculumProvider.overrideWith(
            (Ref ref) async => <String, dynamic>{
              'units': <dynamic>[],
              'exams': <dynamic>[
                <String, dynamic>{
                  'id': 't-exam',
                  'title': 'Test exam',
                  'pass': 1,
                  'questions': <dynamic>[
                    <String, dynamic>{
                      'q': 'Which is first?',
                      'options': <String>['ا', 'ب', 'ت'],
                      'answer': 0,
                      'why': 'Alif.',
                    },
                  ],
                },
              ],
            },
          ),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.text('Which is first?'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.textContaining('TEACHERS'), findsNothing);
    });
  });

  group('2. the privacy text matches the code', () {
    test('no progress and no name is written into any prompt', () {
      for (final WasiaPersona p in WasiaPersona.values) {
        final String s = personaPrompt(p, childName: 'Zaynab');
        expect(s.contains('Zaynab'), isFalse);
        expect(s.contains('letter lessons'), isFalse);
        expect(s.contains('Progress so far'), isFalse);
        expect(s.contains('STUDENT PROGRESS'), isFalse);
      }
      expect(personaPrompt(WasiaPersona.student), contains('no progress'));
    });

    test('the controller source does not read the Family Wing', () {
      final String src =
          File('lib/features/academy/application/wasia_controller.dart')
              .readAsStringSync();
      expect(src.contains('FamilyService'), isFalse);
      expect(src.contains('lessonsDone'), isFalse);
      expect(src.contains('studentBlock'), isFalse);
    });

    test('the text says what is and is not sent', () {
      final String bullets = kChildrenPrivacyBullets.join('\n');
      expect(bullets, contains('never given a child’s name or progress'));
      expect(bullets, contains('off for children until you turn it on'));
      expect(bullets, contains('only the question the child types is sent'));
      expect(kChildrenPrivacyBody, contains('off for children by default'));
      expect(kChildrenPrivacyBody, contains('no lesson or exam progress'));
      expect(kChildrenPrivacyBody.contains('without other profile data'),
          isFalse);
      final String family = File(
              'lib/features/academy/presentation/academy_family.dart')
          .readAsStringSync();
      expect(family.contains('nothing is sent to our servers or to any AI'),
          isFalse);
    });

    test('changed text needs fresh consent: version 1 consent is not enough',
        () async {
      expect(kChildrenPrivacyVersion, 2);
      expect(FamilyService.consentVersion, kChildrenPrivacyVersion);
      SharedPreferences.setMockInitialValues(<String, Object>{
        'ar.family.consent':
            '{"version":1,"at":"2026-10-01T00:00:00.000","by":"parent_or_guardian"}',
      });
      final FamilyService f = FamilyService();
      expect(await f.hasConsent(), isFalse);
      await f.recordConsent();
      expect(await f.hasConsent(), isTrue);
    });
  });

  group('3. content corrections', () {
    final List<String> sources = <String>[
      for (final String f in <String>[
        'lib/features/academy/application/academy_strings.dart',
        'lib/features/academy/presentation/understanding_school_screen.dart',
        'lib/features/academy/presentation/womens_school_screen.dart',
        'lib/features/academy/presentation/health_school_screen.dart',
        'lib/features/academy/presentation/transactions_school_screen.dart',
        'lib/features/academy/presentation/youth_school_screen.dart',
        'lib/features/academy/presentation/history_school_screen.dart',
        'lib/features/academy/presentation/stories_school_screen.dart',
        'lib/features/academy/presentation/dua_school_screen.dart',
        'assets/guides/guides.json',
      ])
        File(f).readAsStringSync(),
    ];

    test('the claims that could not be sourced are gone', () {
      final String all = sources.join('\n');
      for (final String bad in <String>[
        'even when she opposed Islam',
        'about eight months',
        'roughly eight months',
        'last ten surahs',
        'entire Bible',
        'Imam Ghazali: the dunya',
        'Ghazali wrote nine hundred',
        'only woman whose submission',
        r'only woman in the Qur\u2019an whose',
        'city of knowledge',
        'Gate of Knowledge',
        'household at the fire',
        'dua of the Prophet ﷺ covers the gray',
        'command in the Qur\\\'an to accompany worship',
        'blowing lightly',
        'he would not pray the janazah',
      ]) {
        expect(all.contains(bad), isFalse, reason: bad);
      }
    });

    test('the page count and the arithmetic are right', () {
      // 604 pages at one a day: about 20 months (604 / 30.4).
      expect(AcademyStrings.get('und.u3.l1.s1.body'),
          contains('604 pages'));
      expect(AcademyStrings.get('und.u3.l1.s1.body'),
          contains('about twenty months'));
      expect((604 / 30.44).round(), 20);
    });

    test('the corrected lessons say what the verified citations say', () {
      expect(AcademyStrings.get('path.u9.s1.body'), contains('31:15'));
      expect(AcademyStrings.get('hlth.u2.l1.s1.body'),
          contains('hand on the spot'));
      expect(AcademyStrings.get('trx.u3.l2.s1.body'),
          contains('intending to repay'));
      expect(AcademyStrings.get('wmns.u4.l4.s1.body'), contains('27:23'));
    });

    test('flagged lessons get no generated check until a reviewer clears them',
        () {
      for (final String id in <String>[
        'path.u2.l1',
        'path.u7.l3',
        'path.u8.l2',
        'path.u9.l1',
        'und.u3.l1',
        'hfz.u1.l2',
        'yth.u1.l3',
        'yth.u2.l2',
        'wmns.u1.l3',
        'wmns.u4.l4',
        'hlth.u2.l1',
        'trx.u3.l2',
      ]) {
        expect(kRecallExcludedLessons, contains(id));
        final AcademyLesson? l = findLessonById(id);
        expect(l, isNotNull, reason: id);
        expect(RecallChecks.forLesson(l!), isNull, reason: id);
      }
    });
  });

  group('4. the Try prompt is never blank', () {
    test('every Try step in the manifest shows some text', () {
      int tries = 0;
      int fellBack = 0;
      for (final AcademyCourse c in kAcademyCourses) {
        for (final AcademyUnit u in c.units) {
          for (final AcademyLesson l in u.lessons) {
            for (final AcademyStep s in l.steps) {
              if (s.kind != AcademyStepKind.try_) continue;
              tries++;
              final String p = tryPromptFor(s);
              expect(p.trim(), isNotEmpty, reason: l.id);
              if (AcademyStrings.get(s.bodyKey).trim().isEmpty) fellBack++;
            }
          }
        }
      }
      expect(tries, greaterThan(100));
      expect(fellBack, greaterThanOrEqualTo(13),
          reason: 'the 13 lessons that used to show an empty box');
    });
  });

  group('5. a quiz cannot be skipped', () {
    final Lesson lesson = Lesson(
      id: 't-1',
      title: 'T',
      arabic: 'ا',
      steps: const <LessonStep>[
        LessonStep(type: 'teach', text: 'Welcome.'),
        LessonStep(
          type: 'quiz',
          question: 'Pick the second one',
          options: <String>['one', 'two', 'three'],
          answer: 1,
          why: 'Because it is second.',
        ),
        LessonStep(type: 'teach', text: 'Goodbye.'),
      ],
    );

    Future<void> open(WidgetTester tester) async {
      _tall(tester);
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.pumpWidget(await _app(
        const LessonRunnerScreen(lessonId: 't-1'),
        overrides: <Override>[
          lettersLessonsProvider
              .overrideWith((Ref ref) async => <Lesson>[lesson]),
        ],
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('Next is hidden until the right answer is picked',
        (tester) async {
      await open(tester);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Pick the second one'), findsOneWidget);
      expect(find.text('Next'), findsNothing, reason: 'unanswered quiz');

      await tester.tap(find.text('one'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('quiz-feedback')), findsOneWidget);
      expect(find.textContaining('try once more'), findsOneWidget);
      expect(find.text('Next'), findsNothing, reason: 'wrong pick: retry');

      await tester.tap(find.text('two'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Correct, ma sha Allah!'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Goodbye.'), findsOneWidget);
      expect(find.text('Finish'), findsOneWidget);
    });
  });

  group('6. Wasia says when she could not answer', () {
    test('a failed turn leaves a notice and no pending question', () async {
      final _Rig r = await _rig(childAi: true, fail: true);
      final String reply =
          await r.wasia.ask('how do I say it', persona: WasiaPersona.student);
      final WasiaState s = r.container.read(wasiaControllerProvider);
      expect(reply, contains('could not reach her voice'));
      expect(s.notice, reply);
      expect(s.isLoading, isFalse);
      expect(s.messages, isEmpty);
      expect(reply.contains('boom'), isFalse, reason: 'no error text leaks');
    });

    test('the next question clears the notice', () async {
      final _Rig r = await _rig(childAi: true, fail: true);
      await r.wasia.ask('first', persona: WasiaPersona.student);
      expect(r.container.read(wasiaControllerProvider).notice, isNotNull);
      await WasiaController.setChildLlmAllowed(false);
      await r.wasia.ask('tell me about the letter alif');
      expect(r.container.read(wasiaControllerProvider).notice, isNull);
    });

    testWidgets('the thread shows the notice', (tester) async {
      _tall(tester);
      final _Rig r = await _rig(childAi: true, fail: true);
      await r.wasia.ask('how do I say it', persona: WasiaPersona.student);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: r.container,
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: WasiaThread()),
        ),
      ));
      expect(find.byKey(const Key('wasia-notice')), findsOneWidget);
      expect(find.textContaining('could not reach her voice'),
          findsOneWidget);
    });
  });

  group('7. no promise the app cannot keep', () {
    test('the lesson screens do not promise a voice or recorded growth', () {
      final String src =
          File('lib/features/academy/presentation/wasia_lessons.dart')
              .readAsStringSync();
      expect(src.contains('tap the voice above'), isFalse);
      expect(src.contains('SAY IT WITH WASIA'), isFalse);
      expect(src.contains('records your child'), isFalse);
      expect(src.contains('recorded to your child'), isFalse);
    });

    test('the shelf does not say every letter has a hear-it', () async {
      const OfflineWasiaProvider p = OfflineWasiaProvider();
      for (final String q in <String>[
        'can I hear it',
        'audio not working',
        'tajweed pronunciation',
        'the word deck',
      ]) {
        final String a = await p.ask(q, const <HadiMessage>[]);
        expect(a.contains('Every letter lesson has'), isFalse, reason: q);
        expect(a.contains('a short verse you can hear'), isFalse, reason: q);
        expect(a.contains('always with meaning'), isFalse, reason: q);
      }
      final String a = await p.ask('can I hear it', const <HadiMessage>[]);
      expect(a, contains('do not play a recording'));
    });
  });

  group('8. shelf keywords no longer collide with English', () {
    const OfflineWasiaProvider p = OfflineWasiaProvider();

    test('everyday English is declined, not answered with a letter', () async {
      for (final String q in <String>[
        'is it a sin to miss a prayer',
        'what is the meaning of the sin of pride',
        'in other words what do I do',
        'when is the test of my patience',
        'we have seen it before in the news',
        'a nun lives in the convent over there',
        'the shin bone is long',
        'it ain’t easy to wake up for fajr',
      ]) {
        expect(await p.ask(q, const <HadiMessage>[]),
            OfflineWasiaProvider.decline,
            reason: q);
      }
    });

    test('a letter question with a cue, or just the name, still works',
        () async {
      expect(await p.ask('what is the letter sin', const <HadiMessage>[]),
          contains('Sīn'));
      expect(await p.ask('sin', const <HadiMessage>[]), contains('Sīn'));
      expect(
          await p.ask('how do I pronounce ta', const <HadiMessage>[]),
          contains('Tā'));
      expect(await p.ask('tell me about the letter ba', const <HadiMessage>[]),
          contains('Bā'));
    });

    test('the cue helper', () {
      expect(OfflineWasiaProvider.hasLetterCue(' is it a sin to sleep '),
          isFalse);
      expect(OfflineWasiaProvider.hasLetterCue(' sin '), isTrue);
      expect(OfflineWasiaProvider.hasLetterCue(' how to say this letter '),
          isTrue);
      expect(OfflineWasiaProvider.isGuardedKeyword('the sin'), isTrue);
      expect(OfflineWasiaProvider.isGuardedKeyword('letter sin'), isFalse);
      expect(OfflineWasiaProvider.isGuardedKeyword('alif'), isFalse);
    });
  });

  group('9. Quranic Arabic: not hidden behind a fake count', () {
    WordCard card(String key, DateTime now) => WordCard(
          key: key,
          arabic: 'كِتَاب',
          gloss: '',
          review: ReviewCard(wordKey: key, dueDate: now),
        );

    test('fresh cards are not "due"; a reviewed card is when its day comes',
        () {
      final DateTime now = DateTime(2026, 10, 21, 9);
      Map<String, WordCard> deck = <String, WordCard>{
        for (int i = 0; i < 300; i++) 'w$i': card('w$i', now),
      };
      expect(WordDeckEngine.dueCards(deck: deck, now: now), isEmpty);
      // The session still introduces fresh words (capped at 15).
      expect(WordDeckEngine.buildSession(deck: deck, now: now), hasLength(15));
      deck = WordDeckEngine.grade(
          deck: deck, key: 'w0', grade: ReviewGrade.good, now: now);
      final DateTime later = now.add(const Duration(days: 3));
      expect(WordDeckEngine.dueCards(deck: deck, now: later).map(
              (WordCard c) => c.key),
          <String>['w0']);
      expect(WordDeckEngine.dueCards(deck: deck, now: now), isEmpty);
    });

    test('the provider counts due cards only', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer c = ProviderContainer(overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      addTearDown(c.dispose);
      final DateTime now = DateTime.now();
      await c.read(wordDeckProvider.notifier).seedPack(<WordCard>[
        for (int i = 0; i < 20; i++) card('w$i', now),
      ]);
      expect(c.read(todaySessionProvider), hasLength(15));
      expect(c.read(wordsDueProvider), 0,
          reason: 'twenty never-seen cards are not twenty reviews due');
    });
  });

  group('10. who is learning', () {
    const String kids = '['
        '{"id":"a","name":"Amal","createdAt":"2026-10-20T10:00:00.000"},'
        '{"id":"b","name":"Bilal","createdAt":"2026-10-20T10:01:00.000"}'
        ']';

    Future<void> pump(WidgetTester tester,
        {required Map<String, Object> prefs, bool unlocked = true}) async {
      _tall(tester);
      SharedPreferences.setMockInitialValues(prefs);
      await tester.pumpWidget(await _app(
        const ActiveChildBanner(),
        overrides: <Override>[
          parentGateProvider.overrideWith((Ref ref) {
            final ParentGateNotifier n = ParentGateNotifier();
            if (unlocked) n.unlock();
            return n;
          }),
        ],
      ));
      await tester.pumpAndSettle();
    }

    String line(WidgetTester tester) =>
        tester.widget<Text>(find.byKey(const Key('active-child-line'))).data!;

    testWidgets('nothing shows before a child is added', (tester) async {
      await pump(tester, prefs: <String, Object>{});
      expect(find.byKey(const Key('active-child-line')), findsNothing);
    });

    testWidgets('two children: asks who is learning, then confirms',
        (tester) async {
      await pump(tester, prefs: <String, Object>{
        'ar.family.children': kids,
        'ar.family.active': 'b',
      });
      expect(line(tester), 'Who is learning? Saving to Bilal.');
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();
      expect(line(tester), 'Learning as Bilal.');
    });

    testWidgets('a parent can change the child, or choose nobody',
        (tester) async {
      await pump(tester, prefs: <String, Object>{
        'ar.family.children': kids,
        'ar.family.active': 'b',
      });
      await tester.tap(find.byKey(const Key('active-child-change')));
      await tester.pumpAndSettle();
      expect(find.text('Who is learning?'), findsOneWidget);
      await tester.tap(find.text('Amal'));
      await tester.pumpAndSettle();
      expect(line(tester), 'Learning as Amal.');
      expect(await FamilyService().activeChildId(), 'a');

      await tester.tap(find.byKey(const Key('active-child-change')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Nobody'));
      await tester.pumpAndSettle();
      expect(line(tester), contains('No child is chosen'));
      expect(await FamilyService().activeChildId(), isNull);
    });

    testWidgets('changing the child asks the parent check first',
        (tester) async {
      await pump(
        tester,
        prefs: <String, Object>{
          'ar.family.children': kids,
          'ar.family.active': 'b',
        },
        unlocked: false,
      );
      await tester.tap(find.byKey(const Key('active-child-change')));
      await tester.pumpAndSettle();
      expect(find.text('For parents'), findsOneWidget);
      expect(find.text('Who is learning?'), findsNothing);
    });
  });

  group('13. letter drills replace the one trivial question', () {
    final List<Lesson> real = _realLetterLessons();
    final List<Lesson> drilled = withLetterDrills(real);

    test('the first 28 lessons no longer end on the trivial question', () {
      expect(drilled.length, kLettersLessonCount);
      for (int i = 0; i < 28; i++) {
        final List<LessonStep> quizzes = drilled[i]
            .steps
            .where((LessonStep s) => s.type == 'quiz')
            .toList();
        expect(
            quizzes.any((LessonStep s) => s.question == kTrivialLetterQuestion),
            isFalse,
            reason: drilled[i].id);
        expect(quizzes.length, i == 0 ? 2 : (i == 1 ? 2 : 3),
            reason: drilled[i].id);
        // The lesson still opens with a teach step and closes with one.
        expect(drilled[i].steps.first.type, 'teach');
        expect(drilled[i].steps.last.type, 'teach');
      }
    });

    test('units 5-7 are untouched', () {
      for (int i = 28; i < 40; i++) {
        expect(identical(drilled[i], real[i]), isTrue, reason: real[i].id);
      }
    });

    test('every answer is the right letter, name or shape', () {
      final Map<String, String> arabicOf = <String, String>{};
      final Map<String, String> nameOf = <String, String>{};
      for (int i = 0; i < 28; i++) {
        final LessonStep card =
            real[i].steps.firstWhere((LessonStep s) => s.type == 'card');
        arabicOf[card.translit!] = card.arabic!;
        nameOf[card.arabic!] = card.translit!;
      }
      final RegExp which = RegExp(r'[Ww]hich one is (.+)\?$');
      for (int i = 0; i < 28; i++) {
        final LessonStep todayCard =
            real[i].steps.firstWhere((LessonStep s) => s.type == 'card');
        for (final LessonStep s
            in drilled[i].steps.where((LessonStep s) => s.type == 'quiz')) {
          final List<String> o = s.options!;
          expect(o.toSet().length, 3, reason: '${drilled[i].id} ${s.question}');
          expect(s.answer, inInclusiveRange(0, 2));
          if (s.glyph != null) {
            expect(o[s.answer!], nameOf[s.glyph!],
                reason: '${drilled[i].id} ${s.question}');
          } else {
            final RegExpMatch m = which.firstMatch(s.question!)!;
            expect(o[s.answer!], arabicOf[m.group(1)!],
                reason: '${drilled[i].id} ${s.question}');
          }
          if (s.question!.startsWith('From an earlier lesson')) {
            final String target = s.glyph != null
                ? nameOf[s.glyph!]!
                : which.firstMatch(s.question!)!.group(1)!;
            final int at = real.indexWhere((Lesson l) => l.steps.any(
                (LessonStep c) => c.type == 'card' && c.translit == target));
            expect(at, lessThan(i), reason: '${drilled[i].id}: $target');
          } else if (s.glyph != null) {
            expect(s.glyph, todayCard.arabic, reason: drilled[i].id);
          }
        }
      }
    });

    test('the same lesson always asks the same questions', () {
      final List<Lesson> again = withLetterDrills(real);
      for (int i = 0; i < 28; i++) {
        final List<List<String?>> a = <List<String?>>[
          for (final LessonStep s in drilled[i].steps)
            <String?>[s.question, s.options?.join('|'), '${s.answer}'],
        ];
        final List<List<String?>> b = <List<String?>>[
          for (final LessonStep s in again[i].steps)
            <String?>[s.question, s.options?.join('|'), '${s.answer}'],
        ];
        expect(a, b, reason: drilled[i].id);
      }
    });

    test('the correct answer is spread over all three positions', () {
      final Set<int> positions = <int>{
        for (int i = 0; i < 28; i++)
          for (final LessonStep s in drilled[i].steps)
            if (s.type == 'quiz') s.answer!,
      };
      expect(positions, <int>{0, 1, 2});
    });

    test('buildLetterDrills on a tiny alphabet stays in range', () {
      const List<LetterCardInfo> abc = <LetterCardInfo>[
        LetterCardInfo('ا', 'Alif'),
        LetterCardInfo('ب', 'Ba'),
        LetterCardInfo('ت', 'Ta'),
        LetterCardInfo('ث', 'Tha'),
      ];
      for (int i = 0; i < abc.length; i++) {
        final List<LetterDrill> d =
            buildLetterDrills(lessonId: 'x-$i', alphabet: abc, index: i);
        expect(d, isNotEmpty);
        for (final LetterDrill q in d) {
          expect(q.answer, inInclusiveRange(0, q.options.length - 1));
        }
      }
    });
  });

  group('16. leaving a lesson reached from review', () {
    test('the review "Open the lesson" button pushes, so a pop returns to it',
        () {
      final String src =
          File('lib/features/academy/presentation/review_session_screen.dart')
              .readAsStringSync();
      expect(src, contains('context.push(openRoute)'));
      final String player =
          File('lib/features/academy/presentation/lesson_player_screen.dart')
              .readAsStringSync();
      expect(player, contains('context.canPop()'));
    });
  });

  group('18. next lesson', () {
    test('nextLessonAfter walks a course in order and stops at its end', () {
      final AcademyCourse path =
          kAcademyCourses.firstWhere((AcademyCourse c) => c.id == 'the-path');
      final List<AcademyLesson> flat = <AcademyLesson>[
        for (final AcademyUnit u in path.units) ...u.lessons,
      ];
      expect(flat.length, greaterThan(5));
      for (int i = 0; i < flat.length - 1; i++) {
        expect(nextLessonAfter(flat[i].id)?.id, flat[i + 1].id);
      }
      expect(nextLessonAfter(flat.last.id), isNull);
      expect(nextLessonAfter('no.such.lesson'), isNull);
      expect(lessonRoute(flat.first),
          '/academy/lesson/the-path/${flat.first.unitId}/${flat.first.id}');
    });
  });

  group('23. smaller fixes', () {
    test('the daily verse rotates and is quoted word for word', () {
      final List<dynamic> quran = jsonDecode(
          File('assets/quran/quran.json').readAsStringSync()) as List<dynamic>;
      for (final DailyVerse v in kDailyVerses) {
        final Map<String, dynamic> s =
            quran[v.surah - 1] as Map<String, dynamic>;
        final List<dynamic> ayah =
            (s['v'] as List<dynamic>)[v.ayah - 1] as List<dynamic>;
        expect(ayah[0], v.ayah);
        expect((ayah[2] as String).contains(v.text), isTrue,
            reason: '${v.ref}: ${v.text}');
      }
      expect(kDailyVerses.any((DailyVerse v) => v.ref == '39:9'), isFalse);
      final Set<String> week = <String>{
        for (int d = 0; d < kDailyVerses.length; d++)
          dailyVerseFor(DateTime(2026, 10, 21 + d)).ref,
      };
      expect(week.length, kDailyVerses.length,
          reason: 'a full cycle shows every verse once');
      expect(dailyVerseFor(DateTime(2026, 10, 21, 1)).ref,
          dailyVerseFor(DateTime(2026, 10, 21, 23)).ref);
      expect(dailyVerseFor(DateTime(2026, 10, 21)).ref,
          isNot(dailyVerseFor(DateTime(2026, 10, 22)).ref));
    });

    test('dhikr: the resume tap counts, so 100 is 100 taps', () {
      DhikrSessionState s = DhikrSessionEngine.reset(const DhikrSet(
          id: 'big', arabic: 'x', meaning: 'y', target: 100));
      int taps = 0;
      while (s.phase != DhikrPhase.complete) {
        s = DhikrSessionEngine.tap(s);
        taps++;
        expect(taps, lessThanOrEqualTo(100));
      }
      expect(taps, 100);
      expect(s.count, 100);
    });

    test('dhikr: the pause message is true at 33, 66 and 99', () {
      DhikrSessionState s = DhikrSessionEngine.reset(const DhikrSet(
          id: 'big', arabic: 'x', meaning: 'y', target: 100));
      final List<String> said = <String>[];
      for (int i = 0; i < 100; i++) {
        s = DhikrSessionEngine.tap(s);
        if (s.phase == DhikrPhase.milestonePause) {
          said.add(DhikrSessionEngine.milestoneMessage(s));
        }
      }
      expect(said, hasLength(3));
      expect(said[0], startsWith('33 of 100.'));
      expect(said[1], startsWith('66 of 100.'));
      expect(said[2], startsWith('99 of 100.'));
      expect(said.join().contains('third'), isFalse);
    });
  });

  group('24. first-run hero and the fasting embed', () {
    test('a lesson nobody opened is a start, not a part-filled bar', () {
      expect(continueHeroFor(null, 4).started, isFalse);
      expect(continueHeroFor(null, 4).progress, 0);
      expect(continueHeroFor(const LessonProgress(), 4).progress, 0);
      final ContinueHero mid =
          continueHeroFor(const LessonProgress(lastStep: 2), 4);
      expect(mid.started, isTrue);
      expect(mid.progress, 0.75);
      expect(
          continueHeroFor(const LessonProgress(completed: true), 4).progress,
          1);
      expect(continueHeroFor(const LessonProgress(lastStep: 9), 4).progress, 1);
      expect(continueHeroFor(const LessonProgress(lastStep: 1), 0).progress, 0);
    });

    test('the fasting lesson opens the calendar the text names', () {
      final AcademyLesson l = findLessonById('path.u5.l1')!;
      final AcademyStep embed = l.steps
          .firstWhere((AcademyStep s) => s.kind == AcademyStepKind.embed);
      expect(embed.ref, 'calendar.sunnah');
      expect(kEmbedRoutes[embed.ref], '/calendar');
      expect(AcademyStrings.get(embed.bodyKey), contains('calendar'));
    });
  });

  group('25. rows say what they are', () {
    test('the home source has no hard-coded LIVE badge', () {
      final String src =
          File('lib/features/academy/presentation/academy_home_screen.dart')
              .readAsStringSync();
      expect(src.contains("'LIVE'"), isFalse);
      expect(src.contains('live: true'), isFalse);
      expect(src, contains("lessons('LESSONS')"));
      expect(src, contains("reading('READ')"));
      expect(src, contains("tool('TOOL')"));
      expect(src.contains("route: '/academy/quranic-arabic'"), isFalse,
          reason: 'row hidden until meanings carry a licensed source');
    });
  });
}
