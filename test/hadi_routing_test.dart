import 'package:ar_rayaan/features/hadi/application/hadi_bookmark.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/data/hadi_routing.dart';
import 'package:ar_rayaan/features/hadi/data/offline_hadi_provider.dart';
import 'package:ar_rayaan/features/stories/domain/story.dart';
import 'package:flutter_test/flutter_test.dart';

Future<String> ask(String q, [List<HadiMessage> history = const <HadiMessage>[]]) =>
    const OfflineHadiProvider().ask(q, history);

/// The conversation so far as the controller hands it to the provider.
List<HadiMessage> thread(List<(String, String)> turns) => <HadiMessage>[
      for (final (String q, String a) in turns) ...<HadiMessage>[
        HadiMessage(fromHadi: false, text: q),
        HadiMessage(
          fromHadi: true,
          text: a.replaceAll(RegExp(r'\s*\[GO:[^\]]*\]'), '').trim(),
          routes: <String>[
            for (final RegExpMatch m in RegExp(r'\[GO:(/[a-z0-9\-/]+)\]')
                .allMatches(a))
              m.group(1)!,
          ],
        ),
      ],
    ];

Story story(String id, String title) => Story(
      id: id,
      collection: 'prophets',
      title: title,
      kicker: '',
      subtitle: '',
      sourceLabel: kLabelEstablished,
      sources: const <String>[],
      chapters: const <StoryChapter>[],
      familyQuestion: '',
    );

void main() {
  group('a newcomer is routed to the beginner content, not refused', () {
    test('"What is Islam?" and "What do Muslims believe?"', () async {
      for (final String q in <String>[
        'What is Islam?',
        'What do Muslims believe?',
        'what is islam please',
        'Tell me about Islam',
        'basic beliefs of islam',
        'I am new to Islam',
        'what are the six articles of faith',
      ]) {
        final String a = await ask(q);
        expect(a, contains('[GO:/new-muslim]'), reason: q);
        expect(a, contains('[GO:/huda/guide?id=huda-what-is-islam]'), reason: q);
        expect(a.contains('enough authentic knowledge'), isFalse, reason: q);
      }
    });

    test('a real question that merely mentions Islam is not captured',
        () async {
      expect(await ask('What are the pillars of Islam?'),
          isNot(contains('[GO:/new-muslim]')));
      expect(await ask('Is music allowed in Islam?'),
          isNot(contains('[GO:/new-muslim]')));
    });
  });

  group('a refusal always offers a next step and never repeats itself', () {
    test('the first refusal keeps its fixed text', () async {
      expect(OfflineHadiProvider.isDecline(await ask('Tell me about quantum entanglement')), isTrue);
    });

    test('three refusals in a row read differently and carry buttons',
        () async {
      final List<(String, String)> turns = <(String, String)>[];
      final List<String> replies = <String>[];
      for (final String q in <String>[
        'Tell me about quantum entanglement',
        'explain quantum entanglement in other words',
        'what about quantum entanglement then',
        'quantum entanglement one more time',
      ]) {
        final String a = await ask(q, thread(turns));
        replies.add(a);
        turns.add((q, a));
      }
      expect(replies.toSet().length, replies.length,
          reason: 'no two refusals may be the same text');
      for (int i = 1; i < replies.length; i++) {
        expect(HadiRouting.isRefusal(replies[i]), isTrue);
        expect(replies[i], contains('[GO:/search]'));
        expect(replies[i], contains('[GO:/academy/qa]'));
      }
      // The fourth try comes round to the first variant again, never to the
      // plain refusal.
      expect(replies[3], isNot(OfflineHadiProvider.decline));
    });

    test('the buttons follow the topic', () {
      expect(HadiRouting.topicRoute('how do I make wudu'), '/huda');
      expect(HadiRouting.topicRoute('what is a surah'), '/quran');
      expect(HadiRouting.topicRoute('a dua for travel'), '/academy/hisn');
      expect(HadiRouting.topicRoute('tell me a funny story'), '/stories');
      expect(HadiRouting.topicRoute('the weather'), '/academy/qa');
      expect(
        HadiRouting.refusalRoutes('is it halal to x', ruling: true),
        <String>['/sources', '/huda'],
      );
      expect(
        HadiRouting.refusalRoutes('quantum', ruling: false),
        <String>['/academy/qa', '/search'],
      );
    });

    test('a ruling refusal varies too', () async {
      final String first = await ask('Is it halal to do the thing');
      expect(first, OfflineHadiProvider.rulingDecline);
      final String second = await ask(
        'Is this haram to do',
        thread(<(String, String)>[('Is it halal to do the thing', first)]),
      );
      expect(second, isNot(first));
      expect(second, contains('[GO:/sources]'));
    });
  });

  group('a question is answered on its own topic or routed', () {
    test('a medical question goes to a doctor, with the du\'a offered apart',
        () async {
      for (final String q in <String>[
        'Is it allowed to take anxiety medication?',
        'Tell me about anxiety medication',
        'can I take antidepressants',
      ]) {
        final String a = await ask(q);
        expect(a, contains('doctor or pharmacist'), reason: q);
        expect(a.contains('seek refuge'), isFalse, reason: q);
        expect(a.contains('Sahih al-Bukhari 6369'), isFalse, reason: q);
      }
      expect(await ask('Is it allowed to take anxiety medication?'),
          contains('A du’a for anxiety'));
    });

    test('a fasting question about medicine still gets the fasting answer',
        () async {
      final String a = await ask('does medicine break the fast');
      expect(a, contains('breaks the fast'));
    });

    test('"interesting" is not riba', () async {
      final String a = await ask('Something interesting about Ramadan');
      expect(a.toLowerCase().contains('riba'), isFalse);
      expect(a, contains('Ramadan'));
    });

    test('a Ramadan plan goes to the Ramadan screen', () async {
      for (final String q in <String>[
        'Help me plan Ramadan',
        'Ramadan plan',
        'give me a ramadan schedule with suhoor times',
      ]) {
        final String a = await ask(q);
        expect(a, contains('[GO:/ramadan]'), reason: q);
      }
    });

    test('"funny from the sunnah" is not answered with a definition',
        () async {
      final String a = await ask('Something funny from the sunnah');
      expect(a.contains('muakkadah'), isFalse);
      expect(HadiRouting.isRefusal(a), isTrue);
    });

    test('a sleeping du\'a is the sleeping du\'a, with the pages named',
        () async {
      for (final String q in <String>[
        'sleeping dua',
        'bedtime dua',
        'dua before bed',
        'What is the dua before sleeping',
      ]) {
        final String a = await ask(q);
        expect(a, contains('Bismika Allahumma amutu wa ahya'), reason: q);
        expect(a, contains('[GO:/academy/hisn]'), reason: q);
      }
    });

    test('tahajjud steps and rak\'ah counts are never made up', () async {
      for (final String q in <String>[
        'How do I pray tahajjud',
        'How many rakah is tahajjud',
      ]) {
        final String a = await ask(q);
        expect(a, contains('[GO:/huda/guide?id=huda-tahajjud]'), reason: q);
        expect(a, contains('[GO:/prayer]'), reason: q);
        expect(RegExp(r'\b\d+\s*rak', caseSensitive: false).hasMatch(a),
            isFalse,
            reason: q);
      }
      // A plain question about what it is still gets the shelf answer.
      expect(await ask('what is tahajjud'), contains('night prayer'));
    });

    test('why scholars differ, and what the four schools are', () async {
      expect(await ask('why do scholars disagree'), contains('ijtihad'));
      expect(await ask('what are the four schools'), contains('Hanafi'));
    });
  });

  group('a short "yes" means what Hadi just offered', () {
    test('the du\'a for the deceased', () async {
      final String grief = OfflineHadiProvider.griefReply('my mother died')!;
      final List<HadiMessage> history =
          thread(<(String, String)>[('my mother died', grief)]);
      for (final String q in <String>[
        'Yes please',
        'Yes please, the dua for my mother',
        'ok yes',
      ]) {
        final String a = await ask(q, history);
        expect(a, contains('Allahumma ighfir li hayyina'), reason: q);
        expect(a.toLowerCase().contains('fight'), isFalse, reason: q);
      }
    });

    test('a bare yes after an offered screen opens that screen', () async {
      final List<HadiMessage> history = thread(<(String, String)>[
        ('take me somewhere', 'Shall I open it for you?\n[GO:/stories]'),
      ]);
      expect(await ask('yes please', history), contains('[GO:/stories]'));
    });

    test('a bare yes with nothing offered asks what is meant', () async {
      final String a = await ask('yes');
      expect(a, HadiRouting.clarifyReply);
      expect(a.contains('enough authentic knowledge'), isFalse);
    });

    test('a long question that starts with "yes" is an ordinary question',
        () async {
      final String a = await ask(
        'yes and also tell me what breaks the fast during the day please',
        thread(<(String, String)>[
          ('x', 'I can share the du’a for the deceased if you would like it.'),
        ]),
      );
      expect(a, contains('2:187'));
    });
  });

  group('a hadith number Hadi cannot confirm is never swapped silently', () {
    test('asked for the number of a saying, the closest match is labelled',
        () async {
      final String a = await ask(
          'What is the hadith number for seek knowledge even in China');
      expect(a, startsWith(HadiRouting.closestMatchNote));
      expect(a, contains('Ibn Majah 224'));
    });

    test('asked for a number the shelf does not hold, it says so', () async {
      final String a = await ask('Hadith 99999 ibn majah');
      expect(a, contains('[GO:/search]'));
      expect(a, contains('cannot confirm'));
    });

    test('an ordinary question that names no number has no note', () async {
      expect(await ask('how do i make wudu'),
          isNot(contains(HadiRouting.closestMatchNote)));
    });
  });

  group('what Hadi says about itself', () {
    test('what it will refuse is answered, not run through the shelf',
        () async {
      for (final String q in <String>[
        'What will you refuse to answer?',
        'what are your limits',
        'what can\'t you do',
      ]) {
        final String a = await ask(q);
        expect(a, HadiRouting.selfDescriptionReply, reason: q);
        expect(a.contains('specific thing is permitted'), isFalse);
      }
      expect(HadiRouting.selfDescriptionReply, contains('fatwa'));
      expect(HadiRouting.selfDescriptionReply, contains('medical advice'));
    });
  });

  group('the fixed replies are not shelf answers', () {
    test('none of them is given a school-of-law line', () {
      for (final String fixed in HadiRouting.fixedReplies) {
        expect(
          OfflineHadiProvider.schoolNote(
            question: 'is it halal',
            answer: fixed,
            schoolLabel: 'Hanafi',
          ),
          isNull,
        );
      }
      expect(
        OfflineHadiProvider.schoolNote(
          question: 'is it halal to take medicine',
          answer: HadiRouting.medicalReply('is it halal to take medicine'),
          schoolLabel: 'Hanafi',
        ),
        isNull,
      );
    });
  });

  group('bookmark requests', () {
    final List<Story> stories = <Story>[
      story('p-yusuf', 'Yusuf (Joseph)'),
      story('p-musa', 'Musa (Moses)'),
      story('s-1', 'The Cave of Hira'),
      story('s-2', 'The Cave of Thawr'),
    ];

    test('the words that name the story are found', () {
      expect(HadiBookmark.titleWords('Bookmark Yusuf'), <String>['yusuf']);
      expect(HadiBookmark.titleWords('please save the story of Musa'),
          <String>['musa']);
      expect(HadiBookmark.titleWords('Can you bookmark Yusuf to my bookmarks'),
          <String>['yusuf']);
      expect(HadiBookmark.titleWords('How do I make wudu'), isNull);
      expect(HadiBookmark.titleWords('bookmark'), isNull);
    });

    test('one story is chosen, several are listed, none is left alone', () {
      expect(
        HadiBookmark.match(<String>['yusuf'], stories).single.id,
        'p-yusuf',
      );
      expect(
        HadiBookmark.match(<String>['cave'], stories).length,
        2,
      );
      expect(HadiBookmark.match(<String>['money'], stories), isEmpty);
    });
  });
}
