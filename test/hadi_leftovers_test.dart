import 'dart:io';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_controller.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/data/offline_hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/grounding/answer_verifier.dart';
import 'package:ar_rayaan/features/hadi/grounding/corpus.dart';
import 'package:ar_rayaan/features/hadi/grounding/madhhab.dart';
import 'package:ar_rayaan/features/hadi/grounding/passage.dart';
import 'package:ar_rayaan/features/hadi/presentation/hadi_markdown.dart';
import 'package:ar_rayaan/features/hadi/presentation/hadi_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hadi_eval/corpus_fixture.dart';

class _Stub implements HadiProvider {
  _Stub(this.reply);
  final String reply;

  @override
  Future<String> ask(String q, List<HadiMessage> h) async => reply;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final HadiCorpus corpus = loadRealCorpus();

  Future<ProviderContainer> container() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
        hadiCorpusProvider.overrideWith((ref) => corpus),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('reply language (live prompt)', () {
    test('the prompt tells the model to answer in the user\'s language', () {
      expect(kHadiSystemPrompt, contains('REPLY LANGUAGE'));
      expect(kHadiSystemPrompt, contains('Arabic, Urdu'));
    });

    test('and still sends scripture only through [[src:]] IDs', () {
      final int at = kHadiSystemPrompt.indexOf('REPLY LANGUAGE');
      final String rule = kHadiSystemPrompt.substring(at);
      expect(rule, contains('[[src:'));
      expect(rule, contains('never type a verse'));
      // The older pins stay.
      expect(kHadiSystemPrompt, contains('NEVER invent'));
      expect(kHadiSystemPrompt, contains('SCRIPTURE COMES FROM THE APP'));
      expect(kHadiSystemPrompt, contains('adults'));
    });
  });

  group('verifier notes (no inline placeholders)', () {
    test('a removed reference leaves no marker in the reply', () {
      final VerifiedAnswer v = AnswerVerifier.verify(
        'This is in Sahih Bukhari 99999. Ease follows hardship.',
        corpus,
      );
      expect(v.removedReferences, 1);
      expect(v.changed, isTrue);
      expect(v.text.contains('reference removed'), isFalse);
      expect(v.text.contains('99999'), isFalse);
      expect(v.text.contains('()'), isFalse);
      expect(v.text, contains('Ease follows hardship.'));
    });

    test('a removed verse reference and a removed quotation leave no marker',
        () {
      final VerifiedAnswer a = AnswerVerifier.verify(
        'Allah says so (Quran 999:1). Be patient.',
        corpus,
      );
      expect(a.removedReferences, 1);
      expect(a.text.contains('removed'), isFalse);
      expect(a.text.contains('999'), isFalse);
      final VerifiedAnswer b = AnswerVerifier.verify(
        'He said "this is a long invented quotation that no passage '
        'contains at all" and then left.',
        corpus,
      );
      expect(b.removedQuotes, 1);
      expect(b.text.contains('could not verify'), isFalse);
      expect(b.text.contains('invented'), isFalse);
      expect(b.text.contains('""'), isFalse);
    });

    test('closing a gap before punctuation never writes a literal \$1', () {
      final VerifiedAnswer v = AnswerVerifier.verify(
        'Take it slowly , and breathe . Sahih Bukhari 99999 .',
        corpus,
      );
      expect(v.text.contains('\$'), isFalse);
      expect(v.text, startsWith('Take it slowly, and breathe.'));
    });

    test('the controller still gives the person a note to open', () async {
      final ProviderContainer c = await container();
      final String shown = await c.read(hadiControllerProvider.notifier).ask(
            'I feel anxious and worried',
            provider: _Stub('Sahih Bukhari 99999 says so. [[src:q:94:5-6]]'),
          );
      expect(shown.contains('removed'), isFalse);
      final HadiMessage m = c.read(hadiControllerProvider).messages.last;
      expect(m.notes, isNotEmpty);
      expect(m.notes.first, contains('removed'));
    });
  });

  group('citations in the text', () {
    test('a Qur\'an reference, a bracketed one and a library hadith resolve',
        () {
      final List<String> ids = AnswerVerifier.citedIds(
        'Fasting is written (Qur\'an 2:183-185). Ease follows hardship '
        '(94:6). See Sahih Muslim 2749.',
        corpus,
      );
      expect(ids, <String>['q:2:183-185', 'q:94:6', 'h:muslim-2749']);
    });

    test('a hadith that is not in the library, or an impossible ayah, gets no card',
        () {
      expect(AnswerVerifier.citedIds('See Sahih Muslim 2018.', corpus), isEmpty);
      expect(AnswerVerifier.citedIds('See Qur\'an 2:9999.', corpus), isEmpty);
      expect(AnswerVerifier.citedIds('It was 5:30 in the evening.', corpus),
          isEmpty);
    });

    test('duplicates are folded and the list is capped', () {
      final List<String> ids = AnswerVerifier.citedIds(
        'Qur\'an 94:5, Qur\'an 94:5, Qur\'an 94:6, Qur\'an 2:255, '
        'Qur\'an 3:97, Qur\'an 4:43, Qur\'an 4:48, Qur\'an 4:58.',
        corpus,
      );
      expect(ids.length, 5);
      expect(ids.first, 'q:94:5');
      expect(ids.toSet().length, 5);
    });

    test('every shelf answer cites only what it names, and it resolves', () {
      final List<String> answers = OfflineHadiProvider.shelfAnswers;
      expect(answers.length, greaterThan(250));
      int withCards = 0;
      for (final String a in answers) {
        final List<String> ids = AnswerVerifier.citedIds(a, corpus);
        if (ids.isNotEmpty) withCards++;
        for (final String id in ids) {
          final Passage? p = corpus.resolve(id);
          expect(p, isNotNull, reason: id);
          if (id.startsWith('q:')) {
            final List<String> parts = id.substring(2).split(':');
            final String first = parts[1].split('-').first;
            expect(a.contains('${parts[0]}:$first'), isTrue,
                reason: '$id is not named in: $a');
            expect(p!.arabic, isNotNull);
          } else {
            expect(a.contains(p!.number!), isTrue,
                reason: '$id is not named in: $a');
            expect(p.gradeLine, isNotNull);
          }
        }
      }
      expect(withCards, greaterThan(30));
    });
  });

  group('offline answers print scripture cards', () {
    test('a shelf answer that cites the Qur\'an carries its card IDs',
        () async {
      final ProviderContainer c = await container();
      await c
          .read(hadiControllerProvider.notifier)
          .ask('How do I start fasting?',
              provider: const OfflineHadiProvider());
      final HadiMessage m = c.read(hadiControllerProvider).messages.last;
      expect(m.live, isFalse);
      // One verse, not the whole 2:183-185 run: the answer must not end in
      // a wall of Qur'an.
      expect(m.sources, contains('q:2:183'));
      expect(m.sources.contains('q:2:183-185'), isFalse);
      final Passage p = corpus.resolve('q:2:183')!;
      expect(p.arabic, isNotEmpty);
      // Saved with the thread, so the card is there after a restart.
      final String saved =
          c.read(sharedPreferencesProvider).getString('ar.hadi.thread') ?? '';
      expect(saved, contains('q:2:183'));
    });

    test('a library hadith in a shelf answer gets a card with its grade',
        () async {
      final ProviderContainer c = await container();
      await c
          .read(hadiControllerProvider.notifier)
          .ask('why me', provider: const OfflineHadiProvider());
      final HadiMessage m = c.read(hadiControllerProvider).messages.last;
      expect(m.sources, contains('h:bukhari-5641'));
      final Passage p = corpus.resolve('h:bukhari-5641')!;
      expect(p.gradeLine, isNotNull);
      expect(p.english, isNotEmpty);
    });

    test('a live reply keeps only the IDs the model pointed at', () async {
      final ProviderContainer c = await container();
      await c.read(hadiControllerProvider.notifier).ask(
            'tell me about repentance',
            provider: _Stub('Allah is Most Forgiving. (Qur\'an 2:183)'),
          );
      final HadiMessage live = c.read(hadiControllerProvider).messages.last;
      expect(live.live, isTrue);
      // A verse the reply names is printed from the library (as before).
      expect(live.sources, <String>['q:2:183']);
    });

    test('a navigation reply has no card, and a decline has none', () async {
      final ProviderContainer c = await container();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      await ctrl.ask('Take me to the Stories',
          provider: const OfflineHadiProvider());
      expect(c.read(hadiControllerProvider).messages.last.sources, isEmpty);
      await ctrl.ask('Tell me about quantum entanglement',
          provider: const OfflineHadiProvider());
      expect(c.read(hadiControllerProvider).messages.last.sources, isEmpty);
    });

    test('a crisis exchange never gets a card', () async {
      final ProviderContainer c = await container();
      await c
          .read(hadiControllerProvider.notifier)
          .ask('I want to die', provider: const OfflineHadiProvider());
      final HadiMessage m = c.read(hadiControllerProvider).messages.last;
      expect(m.sources, isEmpty);
      expect(m.sensitive, isTrue);
    });
  });

  group('the school of law on the built-in shelf', () {
    test('a fiqh answer says plainly it is the general view and offers a scholar',
        () async {
      final ProviderContainer c = await container();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      await ctrl.setMadhhab(Madhhab.hanafi);
      final String a =
          await ctrl.ask('Is music haram?', provider: const OfflineHadiProvider());
      expect(a, contains('You follow the Hanafi school'));
      expect(a, contains('general view'));
      expect(a, contains('qualified scholar of your school'));
      final HadiMessage m = c.read(hadiControllerProvider).messages.last;
      expect(m.routes, contains('/sources'));
      // It never states what the school holds.
      expect(a.contains('the Hanafi view is'), isFalse);
      expect(a.contains('Hanafis hold'), isFalse);
    });

    test('without a chosen school there is no school line', () async {
      final ProviderContainer c = await container();
      final String a = await c
          .read(hadiControllerProvider.notifier)
          .ask('Is music haram?', provider: const OfflineHadiProvider());
      expect(a.contains('You follow the'), isFalse);
    });

    test('an answer that is not about a ruling gets no school line', () async {
      final ProviderContainer c = await container();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      await ctrl.setMadhhab(Madhhab.shafii);
      final String a = await ctrl.ask('Who is Wasia?',
          provider: const OfflineHadiProvider());
      expect(a.contains('You follow the'), isFalse);
      final String nav = await ctrl.ask('Take me to the Stories',
          provider: const OfflineHadiProvider());
      expect(nav.contains('You follow the'), isFalse);
    });

    test('a ruling the shelf cannot answer gets no school line either',
        () async {
      final ProviderContainer c = await container();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      await ctrl.setMadhhab(Madhhab.hanafi);
      final String a = await ctrl.ask('Is bitcoin halal?',
          provider: const OfflineHadiProvider());
      expect(a, contains(OfflineHadiProvider.rulingDecline));
      expect(a.contains('You follow the'), isFalse);
    });

    test('a fixed reply with a line in front still gets none', () {
      expect(
        OfflineHadiProvider.schoolNote(
          question: 'is it halal',
          answer: 'Your live questions for today are finished.\n\n'
              '${OfflineHadiProvider.rulingDecline}',
          schoolLabel: 'Hanafi',
        ),
        isNull,
      );
    });

    test('fixed replies never get the line', () {
      for (final String fixed in <String>[
        OfflineHadiProvider.decline,
        OfflineHadiProvider.declineKeyed,
        OfflineHadiProvider.rulingDecline,
        OfflineHadiProvider.offTopicReply,
        OfflineHadiProvider.scriptReply,
        OfflineHadiProvider.scriptReplyArabic,
        OfflineHadiProvider.scriptReplyUrdu,
        ...OfflineHadiProvider.rudeReplies,
        ...OfflineHadiProvider.distressReplies,
      ]) {
        expect(
          OfflineHadiProvider.schoolNote(
            question: 'is it halal',
            answer: fixed,
            schoolLabel: 'Hanafi',
          ),
          isNull,
        );
      }
    });

    test('the overview of the four schools is not treated as a ruling', () {
      final String overview = OfflineHadiProvider.shelfAnswers.firstWhere(
        (String a) => a.contains('four major'),
      );
      expect(
        OfflineHadiProvider.schoolNote(
          question: 'what is fiqh',
          answer: overview,
          schoolLabel: 'Maliki',
        ),
        isNull,
      );
    });

    test('a live reply is not given the shelf line', () async {
      final ProviderContainer c = await container();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      await ctrl.setMadhhab(Madhhab.hanbali);
      final String a = await ctrl.ask('Is music haram?',
          provider: _Stub('Scholars differ on this.'));
      expect(a.contains('You follow the'), isFalse);
    });
  });

  group('basic markdown', () {
    test('bold, italic, bullets, numbers and headings', () {
      final List<MdBlock> b = HadiMarkdown.parse(
        'Hello **world** and *you*.\n\n- one\n- **two** x\n1. first\n'
        '2) second\n# Title',
      );
      expect(b.length, 6);
      expect(b[0].spans, const <MdSpan>[
        MdSpan('Hello '),
        MdSpan('world', bold: true),
        MdSpan(' and '),
        MdSpan('you', italic: true),
        MdSpan('.'),
      ]);
      expect(b[1].kind, MdKind.bullet);
      expect(b[1].blankBefore, isTrue);
      expect(b[2].spans.first, const MdSpan('two', bold: true));
      expect(b[3].marker, '1.');
      expect(b[4].marker, '2.');
      expect(b[5].kind, MdKind.heading);
      expect(b[5].spans.single.bold, isTrue);
    });

    test('stray stars, sums and percentages are left alone', () {
      const String t = '2*3*4 is not italic, nor 5 * 6. Zakat is 2.5%.';
      expect(HadiMarkdown.plain(t), t);
      expect(HadiMarkdown.plain('**unterminated and *odd'),
          '**unterminated and *odd');
    });

    test('plain text keeps its list markers and paragraph breaks', () {
      expect(
        HadiMarkdown.plain('**Hi**\n\n- a\n- b'),
        'Hi\n\n• a\n• b',
      );
    });

    test('no shelf answer changes when it is read as markdown', () {
      for (final String a in OfflineHadiProvider.shelfAnswers) {
        final String want = a.trim().replaceAll(RegExp(r'\n{3,}'), '\n\n');
        expect(HadiMarkdown.plain(a), want, reason: a);
      }
    });

    test('right-to-left only when Arabic script is most of the letters', () {
      expect(HadiMarkdown.isMostlyRtl('مرحبا بكم'), isTrue);
      expect(HadiMarkdown.isMostlyRtl('مجھے نماز کا طریقہ بتائیں'), isTrue);
      expect(HadiMarkdown.isMostlyRtl('How do I pray?'), isFalse);
      expect(
        HadiMarkdown.isMostlyRtl(
          'اللَّهُمَّ — O Allah, I seek refuge in You from worry and grief.',
        ),
        isFalse,
      );
      expect(HadiMarkdown.isMostlyRtl(''), isFalse);
    });
  });

  group('reply widgets', () {
    Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

    testWidgets('a reply is selectable and shows bold and bullets',
        (WidgetTester tester) async {
      await tester.pumpWidget(host(
        const HadiRichText(
          text: 'Peace **be** with you.\n- one\n- two',
          style: TextStyle(fontSize: 14),
        ),
      ));
      expect(find.byType(SelectableText), findsOneWidget);
      final SelectableText t =
          tester.widget<SelectableText>(find.byType(SelectableText));
      final String flat = t.textSpan!.toPlainText();
      expect(flat, contains('Peace be with you.'));
      expect(flat, contains('•  one'));
      expect(flat.contains('**'), isFalse);
    });

    testWidgets('an Arabic reply is laid out right to left',
        (WidgetTester tester) async {
      await tester.pumpWidget(host(
        const HadiRichText(
          text: 'السلام عليكم ورحمة الله',
          style: TextStyle(fontSize: 14),
        ),
      ));
      final SelectableText t =
          tester.widget<SelectableText>(find.byType(SelectableText));
      expect(t.textDirection, TextDirection.rtl);
    });

    testWidgets('the note under a reply is closed until it is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(host(
        const HadiNotesPanel(
          notes: <String>['Hādi removed a reference it could not check.'],
        ),
      ));
      expect(find.text('Hādi checked this reply · 1 note'), findsOneWidget);
      expect(find.textContaining('removed a reference'), findsNothing);
      await tester.tap(find.text('Hādi checked this reply · 1 note'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('removed a reference'), findsOneWidget);
    });

    testWidgets('no notes, no panel', (WidgetTester tester) async {
      await tester.pumpWidget(host(const HadiNotesPanel(notes: <String>[])));
      expect(find.byType(HadiDisclosure), findsNothing);
    });

    testWidgets('the heading of a section is at least 48 dp tall',
        (WidgetTester tester) async {
      await tester.pumpWidget(host(
        const HadiDisclosure(title: 'Where your key is kept', child: Text('x')),
      ));
      final Size s = tester.getSize(find.byType(InkWell));
      expect(s.height, greaterThanOrEqualTo(48));
    });

    testWidgets('the typing indicator animates and announces itself',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const HadiTypingIndicator()));
      expect(find.bySemanticsLabel('Hādi is answering'), findsOneWidget);
      List<double> dots() => tester
          .widgetList<Opacity>(
            find.descendant(
              of: find.byType(HadiTypingIndicator),
              matching: find.byType(Opacity),
            ),
          )
          .map((Opacity o) => o.opacity)
          .toList();
      final List<double> before = dots();
      expect(before.length, 3);
      await tester.pump(const Duration(milliseconds: 400));
      expect(dots(), isNot(equals(before)));
      handle.dispose();
    });
  });

  group('screen source keeps the accessibility pass', () {
    final String screen =
        File('lib/features/hadi/presentation/hadi_screen.dart')
            .readAsStringSync();

    test('48 dp targets, labels, live region, multi-line input', () {
      expect(screen, contains('minTapTarget: 48'));
      expect(screen, contains("semanticLabel: 'Read this reply aloud'"));
      expect(screen, contains('liveRegion: isLatest'));
      expect(screen, contains('maxLines: 5'));
      expect(screen, contains('TextInputAction.send'));
      expect(screen, contains('width: 48,'));
      expect(screen, contains("tooltip: 'Copy this reply'"));
      expect(screen, contains('HadiTypingIndicator()'));
      expect(screen.contains("'· · ·'"), isFalse);
    });

    test('the key sheet sits under Advanced, with expandable privacy notes',
        () {
      expect(screen, contains('Your own AI account (optional, advanced)'));
      expect(screen, contains('_PrivacyNote('));
      expect(screen, contains('What is sent with a key'));
      expect(screen, contains('Where your key is kept'));
      expect(screen, contains('What never leaves your device'));
      expect(screen.contains('tap the key icon'), isFalse);
    });

    test('the header pill grows with the text size', () {
      expect(screen, contains('BoxConstraints(minHeight: 40)'));
    });
  });
}
