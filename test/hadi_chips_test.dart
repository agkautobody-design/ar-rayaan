import 'package:ar_rayaan/features/hadi/application/hadi_controller.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_samples.dart';
import 'package:ar_rayaan/features/hadi/data/offline_hadi_provider.dart';
import 'package:flutter_test/flutter_test.dart';

Future<String> offline(String q) =>
    const OfflineHadiProvider().ask(q, const <HadiMessage>[]);

/// What each starter chip's answer must say. Every chip is sent as typed,
/// so the offline shelf has to land on the right entry.
const Map<String, String> kChipMustSay = <String, String>{
  'What is the virtue of Surah Al-Kahf?': 'Al-Kahf',
  "A du'a for anxiety": 'worry and grief',
  'How do I pray Witr?': 'Witr is prayed',
  'What can you do?': 'Three things',
  'Who is Wasia?': 'Wasia is the AI teacher',
  'Take me to the Stories': '[GO:/stories]',
  "A du'a before sleep": 'Bismika Allahumma amutu wa ahya',
  "How do I pray two rak'ahs?": 'two-rak',
  'Find the dua for leaving home': 'Leaving home',
  'I feel so alone': 'with you wherever you are',
  'How do I make wudu?': 'six obligatory steps',
  'What breaks my wudu?': 'nullified',
  'I want to memorize Quran': 'memoriz',
  'Dua for my parents': 'Rabbir hamhumaa',
  'I keep making the same sin': 'despair of the mercy of Allah',
  'What is zakat?': 'Zakat is the third pillar',
  'How do I start fasting?': 'fourth pillar',
  'I had a bad dream': 'shaytan',
  "Show me today's prayer times": '[GO:/prayer]',
};

void main() {
  final Set<String> fallbacks = <String>{
    OfflineHadiProvider.decline,
    OfflineHadiProvider.rulingDecline,
    OfflineHadiProvider.scriptReply,
    OfflineHadiProvider.scriptReplyArabic,
    OfflineHadiProvider.scriptReplyUrdu,
    ...OfflineHadiProvider.rudeReplies,
    ...OfflineHadiProvider.distressReplies,
  };

  group('starter chips', () {
    test('every chip has an expectation, and none is left out', () {
      final Set<String> chips = <String>{
        for (final HadiExchange e in kProposedHadiExchanges) e.question,
      };
      expect(chips, kChipMustSay.keys.toSet());
    });

    for (final HadiExchange e in kProposedHadiExchanges) {
      test('"${e.question}" gets its own real answer', () async {
        final String a = await offline(e.question);
        expect(fallbacks.contains(a), isFalse,
            reason: 'a chip must never land on a decline or a generic reply');
        expect(a, contains(kChipMustSay[e.question]!));
        expect(a.toLowerCase().contains('istikhara'), isFalse);
      });
    }

    test('no two chips give the same answer', () async {
      final List<String> answers = <String>[
        for (final HadiExchange e in kProposedHadiExchanges)
          await offline(e.question),
      ];
      expect(answers.toSet().length, answers.length);
    });

    test('a chip that moves the person offers a whitelisted button', () async {
      for (final HadiExchange e in kProposedHadiExchanges) {
        final String a = await offline(e.question);
        for (final String route in HadiTokens.routesOf(a)) {
          expect(kHadiNavWhitelist.contains(route), isTrue, reason: route);
        }
      }
      expect(HadiTokens.routesOf(await offline('Take me to the Stories')),
          <String>['/stories']);
      expect(HadiTokens.routesOf(await offline("Show me today's prayer times")),
          <String>['/prayer']);
    });

    test('only the opening few show first, and the rest wait behind More', () {
      expect(kHadiOpeningChipCount, inInclusiveRange(4, 5));
      expect(kProposedHadiExchanges.length, greaterThan(kHadiOpeningChipCount));
    });
  });

  group('next-question suggestions', () {
    test('never offer a question the person already asked', () {
      final List<String> next = hadiSuggestions(<String>[
        kProposedHadiExchanges[0].question,
        kProposedHadiExchanges[1].question.toUpperCase(),
      ]);
      expect(next.length, 3);
      expect(next.contains(kProposedHadiExchanges[0].question), isFalse);
      expect(next.contains(kProposedHadiExchanges[1].question), isFalse);
      expect(next.first, kProposedHadiExchanges[2].question);
    });

    test('run out gracefully', () {
      final List<String> all = <String>[
        for (final HadiExchange e in kProposedHadiExchanges) e.question,
      ];
      expect(hadiSuggestions(all), isEmpty);
      expect(hadiSuggestions(all.sublist(1), count: 5), <String>[all.first]);
    });
  });
}
