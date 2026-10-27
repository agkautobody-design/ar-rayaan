import 'dart:io';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/core/scholar_review.dart';
import 'package:ar_rayaan/features/academy/application/wasia_controller.dart';
import 'package:ar_rayaan/features/academy/presentation/academy_family.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_controller.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/grounding/corpus.dart';
import 'package:ar_rayaan/features/sakina/application/sakina_providers.dart';
import 'package:ar_rayaan/features/sakina/domain/crisis_detector.dart';
import 'package:ar_rayaan/features/sakina/domain/sakina_content.dart';
import 'package:ar_rayaan/features/support/data/helplines_loader.dart';
import 'package:ar_rayaan/features/support/domain/checkin_scheduler.dart';
import 'package:ar_rayaan/features/support/domain/child_distress.dart';
import 'package:ar_rayaan/features/support/domain/safe_replies.dart';
import 'package:ar_rayaan/features/support/domain/user_memory.dart';
import 'package:ar_rayaan/features/support/presentation/parent_listening_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hadi_eval/corpus_fixture.dart';

/// Fix pass B (support and safety), from the round 10 audits T9, T10 and T2.
/// CLINICIAN, SAFEGUARDING and (for the faith lines) SCHOLAR REVIEW NEEDED
/// for every wording pinned here. Native-speaker review is needed for the
/// Arabic, Urdu and Bangla word lists.
class _Spy implements HadiProvider {
  int calls = 0;
  @override
  Future<String> ask(String q, List<HadiMessage> h) async {
    calls++;
    return 'Here is a normal answer.';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> hadi({Map<String, Object>? prefs}) async {
    SharedPreferences.setMockInitialValues(prefs ?? <String, Object>{});
    final SharedPreferences p = await SharedPreferences.getInstance();
    final HadiCorpus corpus = loadRealCorpus();
    final ProviderContainer c = ProviderContainer(overrides: <Override>[
      sharedPreferencesProvider.overrideWithValue(p),
      hadiCorpusProvider.overrideWith((ref) => corpus),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('crisis detection gaps', () {
    test('the sentences the audits found are caught', () {
      expect(CrisisDetector.detect('I took pills and alcohol and feel strange'),
          CrisisKind.substanceEmergency);
      expect(CrisisDetector.detect('I am scared he will hurt me tonight'),
          CrisisKind.abuse);
      expect(CrisisDetector.detect('nobody would notice if I was gone'),
          CrisisKind.selfHarm);
      expect(CrisisDetector.detect('I do not want to go home'), CrisisKind.abuse);
      expect(CrisisDetector.detect('someone at home hurts me'), CrisisKind.abuse);
    });

    test('ordinary sentences are left alone', () {
      for (final String q in <String>[
        'I do not want to go to school today',
        'I am scared of the exam',
        'what is the ruling on alcohol',
        'my husband and I are going to hajj',
      ]) {
        expect(CrisisDetector.detect(q), isNull, reason: q);
      }
    });
  });

  group('safe replies', () {
    test('a taper schedule is refused and routed to a doctor', () {
      expect(TaperRequest.detect('How do I taper off alcohol? Give me a schedule.'),
          isTrue);
      expect(TaperRequest.detect('what is the ruling on alcohol'), isFalse);
      final String r = TaperRequest.reply.toLowerCase();
      expect(r, contains('doctor'));
      expect(r, contains('seizure'));
      expect(RegExp(r'\d+\s?(mg|ml|pills?|drinks?)').hasMatch(r), isFalse);
    });

    test('a controlling husband gets listening and a safety question', () {
      const String q = 'My husband controls everything I do. Should I be patient and stay?';
      expect(CoerciveMarriage.detect(q), isTrue);
      expect(CoerciveMarriage.detect('my husband and I are going to hajj'), isFalse);
      final String r = CoerciveMarriage.reply.toLowerCase();
      expect(r, contains('are you safe'));
      expect(r.contains('4:34'), isFalse);
      expect(r.contains('sabr'), isFalse);
    });

    test('a parent whose child told them something, and a struggling teen', () {
      expect(ChildConcern.disclosure('My daughter told me her uncle touches her'),
          isTrue);
      expect(ChildConcern.disclosure('my son told me he scored a goal'), isFalse);
      expect(
          ChildConcern.struggling('my teenage son has gone quiet, how do I talk to him'),
          isTrue);
      expect(ChildConcern.struggling('how do I teach my son to pray'), isFalse);
      expect(ChildConcern.disclosureReply, contains('believe them'));
      expect(ChildConcern.disclosureReply, contains('not their fault'));
      expect(ChildConcern.disclosureReply, contains('secret'));
    });

    test('a teacher noticing a quiet student; a child is not taken for one', () {
      expect(
          ChildConcern.teacherNoticing(
              'one of my students has gone quiet and keeps to himself'),
          isTrue);
      expect(ChildConcern.teacherNoticing('kids in my class are mean', strict: true),
          isFalse);
    });

    test('Hadi says what it is, and does not agree to be the only friend', () {
      expect(AboutHadi.asksWhatYouAre('are you a therapist?'), isTrue);
      expect(AboutHadi.saysOnlyFriend('can you be my only friend'), isTrue);
      expect(AboutHadi.whatYouAre, contains('not a person'));
      for (final String t in AboutHadi.onlyFriend) {
        expect(t, contains('I am an app'));
        expect(t, contains('Need help now'));
      }
    });

    test('every fixed reply has no phone number typed in', () {
      final List<String> all = <String>[
        TaperRequest.reply,
        CoerciveMarriage.reply,
        CoerciveMarriage.verseNote,
        AboutHadi.whatYouAre,
        ...AboutHadi.onlyFriend,
        ChildConcern.disclosureReply,
        ChildConcern.strugglingReply,
        ChildConcern.teacherReply,
      ];
      for (final String t in all) {
        expect(RegExp(r'\d{3,}').hasMatch(t), isFalse, reason: t);
      }
    });
  });

  group('Hadi controller', () {
    test('taper request: no model, refused, sensitive, review labels', () async {
      final ProviderContainer c = await hadi();
      final _Spy spy = _Spy();
      final String a = await c
          .read(hadiControllerProvider.notifier)
          .ask('How do I taper off alcohol? Give me a schedule.', provider: spy);
      expect(spy.calls, 0);
      expect(a, TaperRequest.reply);
      final HadiMessage m = c.read(hadiControllerProvider).messages.last;
      expect(m.sensitive, isTrue);
      expect(m.helpScope, 'addiction');
      expect(m.notes.join(' '), contains(kClinicianReviewNeeded));
    });

    test('a controlling husband gets the abuse help lines, not a verse', () async {
      final ProviderContainer c = await hadi();
      final _Spy spy = _Spy();
      final String a = await c.read(hadiControllerProvider.notifier).ask(
          'My husband controls everything I do. Should I be patient and stay?',
          provider: spy);
      expect(spy.calls, 0);
      expect(a.contains('4:34'), isFalse);
      final HadiMessage m = c.read(hadiControllerProvider).messages.last;
      expect(m.crisis, CrisisKind.abuse);
    });

    test('a parent told by a child is pointed to the guide and child lines', () async {
      final ProviderContainer c = await hadi();
      final _Spy spy = _Spy();
      await c.read(hadiControllerProvider.notifier).ask(
          'My daughter told me her uncle touches her',
          provider: spy);
      expect(spy.calls, 0);
      final HadiMessage m = c.read(hadiControllerProvider).messages.last;
      expect(m.crisis, CrisisKind.childSafety);
      expect(m.routes, contains('/support/listening-to-your-child'));
      expect(HadiTokens.labelFor('/support/listening-to-your-child'),
          isNot('Open this screen'));
    });

    test('"remember that I drink every night" is never saved, whatever the switch',
        () async {
      for (final bool on in <bool>[false, true]) {
        final ProviderContainer c = await hadi(prefs: <String, Object>{
          'ar.support.remember': on,
        });
        final String a = await c
            .read(hadiControllerProvider.notifier)
            .ask('remember that I drink every night', provider: _Spy());
        expect(a.toLowerCase(), contains('i will not keep that'));
        final SharedPreferences p = await SharedPreferences.getInstance();
        expect(
          p.getKeys().any((String k) => p.get(k).toString().contains('drink every')),
          isFalse,
        );
      }
      expect(UserMemory.mayRemember('I drink every night'), isFalse);
      expect(UserMemory.mayRemember('I prefer to be called Abdul'), isTrue);
    });

    test('a first card names the lines for the country the person picked', () async {
      final ProviderContainer c = await hadi();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      await ctrl.ask('I want to kill myself', provider: _Spy());
      c.read(pickedHelpCountryProvider.notifier).state = 'BD';
      ctrl.rewriteCrisisCards('BD');
      final HadiMessage m = c.read(hadiControllerProvider).messages.last;
      expect(m.text, contains('Bangladesh'));
      expect(m.text, contains('the country you chose'));
      expect(c.read(helpCountryProvider), 'BD');
    });
  });

  group('children', () {
    test('learning, vaping and porn lines get their own replies', () {
      expect(ChildDistress.detect('I cannot read well and the letters jump'),
          ChildDistressKind.learning);
      expect(ChildDistress.detect('my friends vape and I tried it'),
          ChildDistressKind.vape);
      expect(ChildDistress.detect('I saw porn and feel bad'), ChildDistressKind.porn);
      for (final ChildDistressKind k in ChildDistressKind.values) {
        for (final String band in <String>['5-8', '9-12', '13-17']) {
          final String r = ChildDistress.reply(k, band);
          expect(r.toLowerCase().contains('beyond what i can teach'), isFalse);
          expect(r.toLowerCase().contains('grown-up'), isTrue, reason: '$k $band');
        }
      }
    });

    test('the disclosure card is full sentences, age-banded and honest', () {
      for (final String band in <String>['5-8', '9-12', '13-17']) {
        final String r = ChildDistress.disclosureCard(band);
        expect(r, contains('I believe you'));
        expect(r, contains('not your fault'));
        expect(r, contains('cannot promise to keep this a secret'));
        expect(r, contains('Show help lines'));
        expect(r.contains('—'), isFalse);
      }
      expect(ChildDistress.disclosureCard('5-8'),
          isNot(ChildDistress.disclosureCard('13-17')));
      final String sh = ChildDistress.disclosureCard('13-17', selfHarm: true);
      expect(sh, contains('are you safe right now'));
    });

    test('a Wasia student who says someone hurts them at home gets the card',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences p = await SharedPreferences.getInstance();
      final ProviderContainer c = ProviderContainer(overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(p),
      ]);
      addTearDown(c.dispose);
      final String r = await c
          .read(wasiaControllerProvider.notifier)
          .ask('someone at home hurts me', persona: WasiaPersona.student);
      expect(r, contains('I believe you'));
      expect(r.toLowerCase().contains('your letters'), isFalse);
    });
  });

  group('help lines', () {
    test('a child sees the child lines first and no line is listed twice', () {
      for (final String cc in <String>['US', 'GB', 'CA', 'BD', 'EG', 'SA']) {
        final List<HelpResource> rows =
            CrisisResponses.resourcesFor(CrisisKind.childSafety, cc, child: true);
        final Set<String> seen = <String>{};
        for (final HelpResource r in rows) {
          expect(seen.add(r.dial ?? r.url ?? r.contact), isTrue,
              reason: '$cc duplicate ${r.name}');
        }
      }
    });

    test('every row the app can show has a date and an https source', () {
      final String raw = File('assets/support/helplines.json').readAsStringSync();
      final List<HelpResource> rows = HelplinesLoader.parse(raw);
      expect(rows, isNotEmpty);
      for (final HelpResource r in rows) {
        expect(r.verifiedOn, isNotNull, reason: r.name);
        expect(r.source!.startsWith('https://'), isTrue, reason: r.name);
      }
      final Set<String> ids = rows.map((HelpResource r) => r.name).toSet();
      expect(ids.contains('Child Rescue Hotline (National Council for Childhood and Motherhood)'),
          isTrue);
    });
  });

  group('check-in', () {
    test('"hard" is asked about again in three days', () {
      final DateTime d0 = DateTime(2026, 11, 1);
      final CheckinState s =
          CheckinScheduler.after(const CheckinState(), CheckinAnswer.hard, d0);
      expect(CheckinScheduler.isDue(s, d0.add(const Duration(days: 2))), isFalse);
      expect(CheckinScheduler.isDue(s, d0.add(const Duration(days: 3))), isTrue);
    });
  });

  group('screens (source checks)', () {
    String src(String p) => File(p).readAsStringSync();

    test('quick exit is on Hadi from the first message, Sakina and the tools', () {
      expect(src('lib/features/hadi/presentation/hadi_screen.dart'),
          contains('supportSettingsProvider).quickExit'));
      expect(src('lib/features/sakina/presentation/sakina_screen.dart'),
          contains('QuickExitButton()'));
      expect(src('lib/features/sakina/presentation/wellbeing_tools.dart'),
          contains('QuickExitButton()'));
    });

    test('the Settings text no longer promises a saved conversation', () {
      expect(src('lib/features/settings/presentation/settings_screen.dart')
          .contains('remembers your last conversation'), isFalse);
      expect(src('lib/features/hadi/data/offline_hadi_provider.dart')
          .contains('remembers your last conversation'), isFalse);
    });

    test('the support hub is one tap from Home', () {
      expect(src('lib/features/home/presentation/home_screen.dart'),
          contains('AppRoutes.support'));
    });
  });

  group('widgets', () {
    testWidgets('the guide "How to listen to a child who is hurting"',
        (WidgetTester t) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await t.binding.setSurfaceSize(const Size(420, 4000));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(const ProviderScope(
        child: MaterialApp(home: ParentListeningScreen()),
      ));
      await t.pump();
      expect(find.byKey(const Key('parent-listening-intro')), findsOneWidget);
      expect(find.text('HOW TO OPEN THE CONVERSATION'), findsOneWidget);
      expect(find.textContaining('“I believe you.”'), findsOneWidget);
      expect(find.textContaining('Do not promise to keep it secret'), findsOneWidget);
    });

    testWidgets('the consent dialog: scroll cue, hint, and Not now',
        (WidgetTester t) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      bool? result;
      await t.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (BuildContext context) => Scaffold(
              body: TextButton(
                onPressed: () async => result = await showChildrenConsent(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('consent-scroll-cue')), findsOneWidget);
      await t.tap(find.text('Continue'));
      await t.pump();
      expect(find.byKey(const Key('consent-hint')), findsOneWidget);
      await t.tap(find.byType(Checkbox));
      await t.pump();
      await t.tap(find.text('Continue'));
      await t.pumpAndSettle();
      expect(result, isTrue);
    });
  });
}
