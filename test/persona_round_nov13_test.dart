import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/app/core/region/device_time_zone.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_controller.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/data/hadi_prophets.dart';
import 'package:ar_rayaan/features/hadi/grounding/minor_signal.dart';
import 'package:ar_rayaan/features/hadi/data/hadi_routing.dart';
import 'package:ar_rayaan/features/hadi/data/offline_hadi_provider.dart';
import 'package:ar_rayaan/features/sakina/domain/sakina_content.dart';
import 'package:flutter_test/flutter_test.dart';

/// The persona test of 13 Nov 2026 (new convert, beginner, prophets,
/// comparative religion, Arabic learner, substance use in Canada). Each case
/// below failed on the live app before this round.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<String> ask(String q) =>
      const OfflineHadiProvider().ask(q, const <HadiMessage>[]);

  setUpAll(() {
    HadiProphets.debugSetStories(
      json.decode(File('assets/stories/prophets.json').readAsStringSync())
          as List<dynamic>,
    );
  });
  tearDownAll(() => HadiProphets.debugSetStories(null));

  group('prophet stories', () {
    test('the question names the prophet the reply tells', () {
      expect(HadiProphets.storyIdFor('Tell me the story of Prophet Yunus'),
          'prophet-yunus');
      expect(
          HadiProphets.storyIdFor(
              'Tell me about Prophet Hud and the people of Aad'),
          'prophet-hud');
      expect(HadiProphets.storyIdFor('what happened to the people of lut'),
          'prophet-lut');
      expect(HadiProphets.storyIdFor('who was prophet job'), 'prophet-ayyub');
      expect(HadiProphets.storyIdFor('Tell me about Musa and Harun'),
          'prophet-musa');
      expect(HadiProphets.storyIdFor('story of jesus'), 'prophet-isa');
      expect(HadiProphets.storyIdFor('who is yahya'), 'prophet-zakariya');
    });

    test('everyday words and other questions are left alone', () {
      expect(HadiProphets.storyIdFor('Why do Muslims believe Jesus is not God?'),
          isNull);
      expect(HadiProphets.storyIdFor('I lost my job, the prophet said patience'),
          isNull);
      expect(HadiProphets.storyIdFor('I have a lot of questions about the prophet'),
          isNull);
      expect(HadiProphets.storyIdFor('is it halal to name my son Musa'), isNull);
      expect(HadiProphets.storyIdFor('what is the dua of yunus'), isNull);
    });

    test('every prophet in the names list has a story in the pack', () {
      final List<dynamic> stories = json.decode(
              File('assets/stories/prophets.json').readAsStringSync())
          as List<dynamic>;
      final Set<String> ids = <String>{
        for (final dynamic s in stories) (s as Map<String, dynamic>)['id'] as String,
      };
      for (final String id in HadiProphets.names.keys) {
        expect(ids.contains(id), isTrue, reason: id);
      }
    });

    test('Yunus gets Yunus, never the life of the Prophet Muhammad', () async {
      final String a = await ask('Tell me the story of Prophet Yunus');
      expect(a, contains('Yunus'));
      expect(a, contains('[GO:/stories/read?id=prophet-yunus]'));
      expect(a, isNot(contains('Muhammad ibn Abdullah')));
      expect(HadiRouting.isFixed(a), isTrue);
    });

    test('Hud is answered from his story, not declined', () async {
      final String a = await ask('Tell me about Prophet Hud and the people of Aad');
      expect(a, contains('[GO:/stories/read?id=prophet-hud]'));
      expect(HadiRouting.isRefusal(a), isFalse);
    });

    test('the story button is allowed and labelled', () {
      expect(HadiTokens.isAllowed('/stories/read?id=prophet-yunus'), isTrue);
      expect(HadiTokens.labelFor('/stories/read?id=prophet-yunus'),
          'Open the full story');
      expect(HadiTokens.isAllowed('/stories/read?id=../../x'), isFalse);
    });

    test('excerpts are verbatim cuts of the chapter', () {
      const String body = 'One. Two words here. Three is longer than the rest.';
      expect(HadiProphets.excerpt(body, max: 1000), body);
      final String long = List<String>.filled(80, 'A sentence of words.').join(' ');
      final String cut = HadiProphets.excerpt(long);
      expect(long.startsWith(cut), isTrue);
      expect(cut.endsWith('.'), isTrue);
    });
  });

  group('new Muslim, beginner and Arabic learner', () {
    const String convert = "I just became Muslim yesterday. I don't know how "
        'to pray and my family is Christian and angry. What do I do first?';

    test('a new Muslim with an angry family is met about the family', () async {
      expect(HadiRouting.asksNewMuslimFamily(convert), isTrue);
      final String a = await ask(convert);
      expect(a, contains('31:15'));
      expect(a, contains('Bukhari 2620'));
      expect(a, contains('[GO:/new-muslim]'));
    });

    test('a beginner in their own words gets the beginner reply', () async {
      for (final String q in <String>[
        'I know nothing about Islam. Where do I start?',
        'How do I start learning about Islam?',
        "I'm curious about Islam",
        'I want to learn more about Islam',
      ]) {
        expect(HadiRouting.asksBeginnerLoose(q), isTrue, reason: q);
      }
      final String a = await ask('I know nothing about Islam. Where do I start?');
      expect(a, contains('[GO:/new-muslim]'));
    });

    test('someone who wants to learn Arabic is sent to the schools', () async {
      const String q = 'I want to learn Arabic so I can understand the Quran. How?';
      expect(HadiRouting.asksLearnArabic(q), isTrue);
      final String a = await ask(q);
      expect(a, contains('[GO:/academy/letters]'));
      expect(HadiRouting.asksLearnArabic("I can't read Arabic"), isTrue);
      expect(HadiRouting.asksLearnArabic('what does salam mean in arabic'),
          isFalse);
    });
  });

  group('parent', () {
    test('teaching a young child to pray gets the gentle guide', () async {
      const String q = 'How do I teach my 6 year old son to pray without forcing him?';
      expect(HadiRouting.asksTeachChildPrayer(q), isTrue);
      final String a = await ask(q);
      expect(a, contains('[GO:/huda/guide?id=huda-children-deen]'));
      expect(a, isNot(contains('17:31')));
      expect(HadiRouting.asksTeachChildPrayer('how do I get my kids to pray fajr'),
          isTrue);
    });
  });

  group('comparing religions', () {
    test('the right guides are chosen', () {
      expect(
        HadiRouting.faithGuidesFor(
            'How is Islam different from Christianity, Judaism, Hinduism and Buddhism?'),
        <String>[
          'huda-islam-other-faiths',
          'huda-islam-christianity',
          'huda-islam-judaism',
          'huda-islam-hinduism',
          'huda-islam-buddhism',
        ],
      );
      expect(
          HadiRouting.faithGuidesFor(
              'What do Hindus believe and how is it different from Islam?'),
          <String>['huda-islam-hinduism']);
      expect(HadiRouting.faithGuidesFor('which religion is true?'),
          <String>['huda-islam-other-faiths']);
      expect(HadiRouting.faithGuidesFor('can I marry a christian woman'),
          isEmpty);
      expect(HadiRouting.faithGuidesFor('Can I eat at a Hindu friend\'s house'),
          isEmpty);
    });

    test('the reply opens the guides', () async {
      final String a = await ask(
          'How is Islam different from Christianity, Judaism, Hinduism and Buddhism?');
      expect(a, startsWith('The app has guides for exactly this.'));
      expect(HadiTokens.routesOf(a),
          contains('/huda/guide?id=huda-islam-other-faiths'));
    });

    test('the five guides exist, are labelled and are known to Hadi', () {
      final List<dynamic> guides =
          json.decode(File('assets/guides/guides.json').readAsStringSync())
              as List<dynamic>;
      final String log =
          File('docs/content_needed/VERIFICATION_LOG.md').readAsStringSync();
      for (final String id in <String>[
        'huda-islam-other-faiths',
        'huda-islam-christianity',
        'huda-islam-judaism',
        'huda-islam-hinduism',
        'huda-islam-buddhism',
      ]) {
        final Map<String, dynamic> g = guides
            .cast<Map<String, dynamic>>()
            .firstWhere((Map<String, dynamic> x) => x['id'] == id);
        expect((g['sources'] as List<dynamic>).first as String,
            startsWith('Status: scholar review needed'));
        expect(kHadiGuideNames.containsKey(id), isTrue, reason: id);
        final String text = <String>[
          ...(g['steps'] as List<dynamic>).cast<String>(),
          ...(g['sources'] as List<dynamic>).cast<String>(),
        ].join('\n');
        for (final RegExpMatch m
            in RegExp(r'Qur’an (\d{1,3}):(\d{1,3})').allMatches(text)) {
          expect(log.contains('${m.group(1)}:${m.group(2)}'), isTrue,
              reason: '$id ${m.group(0)}');
        }
        for (final RegExpMatch m
            in RegExp(r'(Bukhari|Muslim)\s+(\d{1,4})').allMatches(text)) {
          expect(log.contains('${m.group(1)} ${m.group(2)}'), isTrue,
              reason: '$id ${m.group(0)}');
        }
      }
    });
  });

  group('help lines in Canada', () {
    test('a Toronto time zone is Canada, not the browser language', () {
      expect(countryForTimeZone('America/Toronto'), 'CA');
      expect(countryForTimeZone('America/New_York'), 'US');
      expect(countryForTimeZone('Australia/Sydney'), 'AU');
      expect(countryForTimeZone('Europe/Paris'), isNull);
      expect(countryForTimeZone(null), isNull);
    });

    test('Canada has a verified substance-use line', () {
      final List<HelpResource> rows = HelpResources.forCountry(
        'CA',
        kinds: const <HelpKind>{HelpKind.addiction},
      );
      expect(rows.first.countries, contains('CA'));
      expect(rows.first.verified, isTrue);
    });
  });

  group('round 2 fixes', () {
    test('"list all the prophets in order" gives all 25 with the stories shelf',
        () async {
      final String a = await ask('list all the prophets in order');
      expect(a, contains('Dhul-Kifl'));
      expect(a, contains('Muhammad'));
      expect(a, contains('[GO:/stories]'));
      expect(HadiProphets.isReply(a), isTrue);
    });

    test('what Muslims believe about Jesus tells the Isa story', () {
      expect(HadiProphets.storyIdFor('What do Muslims believe about Jesus?'),
          'prophet-isa');
    });

    test('compatibility questions reach the faith guide', () {
      expect(HadiRouting.faithGuidesFor('Is Buddhism compatible with Islam?'),
          contains('huda-islam-buddhism'));
    });

    test('a hidden conversion is a new-Muslim family question', () {
      expect(
          HadiRouting.asksNewMuslimFamily(
              "I converted last month but my parents don't know. I'm scared to tell them."),
          isTrue);
    });

    test('is God real has a Qur\'an-based shelf answer', () async {
      final String a = await ask('Why should I believe God exists at all?');
      expect(a, contains('Qur\'an'));
      expect(a, contains('[GO:/academy/aqeedah]'));
    });
  });

  group('round 3 (100 personas)', () {
    test('a parent asking for a child is not a child', () {
      expect(MinorSignal.isMinor('whats a good bedtime story from islam for a 5 year old'), isFalse);
      expect(MinorSignal.isMinor('tips for teaching a 7 year old to pray'), isFalse);
      expect(MinorSignal.isMinor('I am 15 years old and want to learn'), isTrue);
      expect(MinorSignal.isMinor("I'm a 14 year old and need help"), isTrue);
    });

    for (final (String q, String needle) in <(String, String)>[
      ('what is khushu and how do i get it', 'Qur\'an 23:2'),
      ('how do i pray when travelling', 'shortening the prayer'),
      ('can i pray at work if there is no prayer room', 'Sahih al-Bukhari 335'),
      ('i want to stop being angry', 'Sahih al-Bukhari 6114'),
      ('does islam oppress women', 'Qur\'an 33:35'),
      ('is the quran the same today as it was revealed', 'Qur\'an 15:9'),
      ('how to become a better muslim', 'Sahih al-Bukhari 6464'),
      ('i get intrusive thoughts about god', 'Sahih Muslim 132'),
    ]) {
      test('shelf answer for: $q', () async {
        expect(await ask(q), contains(needle));
      });
    }
  });
}
