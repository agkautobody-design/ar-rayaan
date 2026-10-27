import 'dart:io';

import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/data/offline_hadi_provider.dart';
import 'package:flutter_test/flutter_test.dart';

Future<String> ask(String q) =>
    const OfflineHadiProvider().ask(q, const <HadiMessage>[]);

final RegExp _cite = RegExp(
  r"(?:(bukhari)|((?<!new\s)muslim)(?![a-z])|((?:abu|abi)\s+da[wu]*[ou]*d)|(tirmidhi)|(nasa['’ʿʼ]?i)|(ibn\s+maja?h?)|((?:musnad\s+)?ahmad))"
  r"(?:\s*\)?\s*[:#]?\s*\(?\s*(?:no\.?\s*|hadith\s+)?)"
  r"(\d{1,5}(?:\s*(?:,|&|/|and|;)\s*\d{1,5}(?!\d|:\d))*)"
  r"(?!\d|:\d|\s*(?:days?|times|years|minutes|rak))",
  caseSensitive: false,
);

final RegExp _attribution = RegExp(
  r'(?:[Tt]he Prophet(?! [A-Z])|Prophet ﷺ|Messenger of Allah|Rasulullah|ﷺ)'
  r'[^.\n]{0,50}?\b(?:said|says|taught|told|reported|called|forbade|praised|'
  r'advised|promised|warned|likened|described|named|asked|saw|heard|recited|'
  r'used to|commanded|ordered|made|affirmed|prescribed|declared|counselled|'
  r'stated|mentioned|cursed|raised|permitted|prohibited)\b'
  r'|\b(?:[Ii]t is reported|is reported|[Aa] report|reported that|narrated|'
  r'reports? (?:in|from|that))\b',
);

final RegExp _literal = RegExp(
  r"'((?:\\.|[^'\\])*)'|"
  r'"((?:\\.|[^"\\])*)"',
);

List<String> shelfAnswers(String src) {
  final String body = src
      .substring(src.indexOf('const List<_Entry> _knowledge'))
      .split('\n')
      .where((String l) => !l.trimLeft().startsWith('//'))
      .join('\n');
  final List<String> out = <String>[];
  for (final String block in body.split('_Entry(').skip(1)) {
    final String rest = block.substring(block.indexOf('],') + 2);
    final StringBuffer text = StringBuffer();
    for (final RegExpMatch m in _literal.allMatches(rest)) {
      final String raw = m.group(1) ?? m.group(2) ?? '';
      text.write(raw.replaceAllMapped(RegExp(r'\\(.)'),
          (Match e) => e[1] == 'n' ? '\n' : e[1]!));
    }
    out.add(text.toString());
  }
  return out;
}

/// The attributions in [answer] that no citation follows before the next
/// group of attributions.
List<String> uncited(String answer) {
  final List<int> starts = <int>[
    for (final RegExpMatch m in _attribution.allMatches(answer)) m.start,
  ];
  final List<int> cites = <int>[
    for (final RegExpMatch m in _cite.allMatches(answer)) m.start,
  ];
  // Attributions less than 120 characters apart form one group.
  final List<int> g = <int>[];
  int prev = -1000;
  for (final int s in starts) {
    if (g.isEmpty || s - prev >= 120) g.add(s);
    prev = s;
  }
  final List<String> bad = <String>[];
  for (int i = 0; i < g.length; i++) {
    final int end = i + 1 < g.length ? g[i + 1] : answer.length;
    if (!cites.any((int c) => c >= g[i] && c < end)) {
      bad.add(answer.substring(g[i], (g[i] + 70).clamp(0, answer.length)));
    }
  }
  return bad;
}

void main() {
  group('offline matcher: whole words, not substrings', () {
    test('"breakfast" is not a Ramadan-fasting question', () async {
      final String a = await ask('breakfast');
      expect(OfflineHadiProvider.isDecline(a), isTrue);
    });

    test('"business" is not a sin/zina/other keyword hit', () async {
      final String a = await ask('business');
      expect(OfflineHadiProvider.isDecline(a), isTrue);
    });

    test('"my husband beats me" gets safety help, not table manners',
        () async {
      final String a = await ask('my husband beats me');
      expect(a.toLowerCase().contains('right hand'), isFalse);
      expect(a.toLowerCase().contains('eating'), isFalse);
      expect(a, contains('not your fault'));
    });

    test('self-harm gets the crisis reply with help lines, not a quote',
        () async {
      final String a = await ask('I want to kill myself');
      expect(a, contains('emergency'));
      expect(a, contains('39:53'));
      expect(a.contains('Prayer Times'), isFalse);
    });

    test('ordinary questions still find their answer', () async {
      expect((await ask('How do I make wudu?')).toLowerCase(), contains('wudu'));
      expect(await ask('Tell me about fasting'), contains('pillar'));
      expect(await ask('What are your hadith sources?'),
          contains('Sihah Sitta'));
    });

    test('an unrelated question is declined, not matched to nonsense',
        () async {
      expect(OfflineHadiProvider.isDecline(await ask('Tell me about quantum entanglement')), isTrue);
    });

    test('a question about something else is told so, not sent to a scholar',
        () async {
      expect(OfflineHadiProvider.isDecline(await ask('Who will win the football match?')), isTrue);
      expect(OfflineHadiProvider.isDecline(await ask('Who won the world cup?')), isTrue);
    });
  });

  group('offline matcher: rulings are not guessed', () {
    test('"is a credit card halal" is answered by how it is used, not yes or no',
        () async {
      final String a = await ask('is a credit card halal');
      expect(a, contains('interest'));
      expect(a, contains('qualified scholar'));
      expect(a.startsWith('Yes'), isFalse);
      expect(a.startsWith('No'), isFalse);
    });

    test('a ruling-shaped question that matches gets the scholar note',
        () async {
      final String a = await ask('is music haram');
      expect(a, contains('qualified scholar'));
    });
  });

  group('offline knowledge base content', () {
    final String src = File(
      'lib/features/hadi/data/offline_hadi_provider.dart',
    ).readAsStringSync();

    test('al-Albani gradings only sit next to a citation checked on sunnah.com', () {
      // The citation checker (hadith_citations_test.dart) proves each cited
      // number has an ok verdict with a grade and grader; here we only make
      // sure no free-floating "al-Albani" grading appears without a number.
      final RegExp withNumber = RegExp(r'\d{2,5}.{0,160}Albani');
      for (final String line in src.split('\n')) {
        if (!line.contains('Albani')) continue;
        expect(withNumber.hasMatch(line), isTrue, reason: line);
      }
    });

    test('known wrong claims are gone', () {
      expect(src.contains('a Jew, a Christian, or a Persian'), isFalse);
      expect(src.contains('sixty days in the womb'), isFalse);
      expect(src.contains('is the greater jihad'), isFalse);
      expect(src.contains('differences among my Ummah are a mercy'), isFalse);
    });

    test('zakat nisab is 85 g gold / 595 g silver everywhere it appears', () {
      expect(src.contains('87.48'), isFalse);
      expect(src.contains('612.36'), isFalse);
      expect(src.contains('595 g'), isTrue);
      expect(src.contains('85 g'), isTrue);
    });

    test('the self-harm entry no longer points at a missing feature', () {
      expect(src.contains('Prayer Times screen can connect you'), isFalse);
    });
  });
  group('offline matcher: token-set, intent, stems, typos', () {
    test('word order and filler do not hide the topic', () async {
      for (final String q in <String>[
        'what breaks my wudu',
        'wudu breaks',
        'does sleeping break wudu',
      ]) {
        expect(await ask(q), contains('Wudu is broken by'), reason: q);
      }
    });

    test('how-to intent picks the how-to entry, not the what-is one',
        () async {
      expect(await ask('how do i perform wudu'), contains('The steps'));
      expect(await ask('what is zakat'), contains('third pillar'));
      expect(await ask('how do i pay zakat'), contains('third pillar'));
    });

    test('generic words lose to topic words', () async {
      final String a = await ask('should i pray istikhara');
      expect(a, contains('non-obligatory prayer'));
      expect(await ask('how do i stop sinning'), contains('mercy of Allah'));
    });

    test('spelling variants and a slipped key still find the topic', () async {
      expect(await ask('ramadhan'), contains('Ramadan'));
      expect(await ask('ramazan tips'), contains('Ramadan'));
      expect(await ask('tahajud'), contains('Tahajjud'));
      expect(await ask('how do i make wuduu'), contains('The steps'));
    });

    test('navigation requests still navigate', () async {
      expect(await ask('take me to the qibla'), contains('[GO:/qibla]'));
      expect(await ask('open the quran'), contains('[GO:/quran'));
    });

    test('fuzzy matching adds no false positives', () async {
      for (final String q in <String>[
        'breakfast',
        'business',
        'recipe for biryani',
        'sacred',
        'they',
        'how do i make coffee',
        'prayin',
      ]) {
        expect(OfflineHadiProvider.isDecline(await ask(q)), isTrue, reason: q);
      }
    });

    test('a long paste is bounded and answered quickly', () async {
      final String long = List<String>.filled(300, 'wudu').join(' ');
      final Stopwatch sw = Stopwatch()..start();
      await ask(long);
      expect(sw.elapsedMilliseconds, lessThan(2000));
    });
  });

  group('offline matcher: script handling', () {
    test('script is detected', () {
      expect(OfflineHadiProvider.scriptOf('how do i pray'), HadiScript.latin);
      expect(OfflineHadiProvider.scriptOf('ما حكم الصلاة'), HadiScript.arabic);
      expect(OfflineHadiProvider.scriptOf('مجھے نماز کا طریقہ بتائیں'),
          HadiScript.urdu);
      expect(OfflineHadiProvider.scriptOf('你好'), HadiScript.other);
    });

    test('Arabic and Urdu get a reply in their own language', () async {
      expect(await ask('ما حكم الصلاة'),
          OfflineHadiProvider.scriptReplyArabic);
      expect(await ask('مجھے نماز کا طریقہ بتائیں'),
          OfflineHadiProvider.scriptReplyUrdu);
      expect(await ask('你好'), OfflineHadiProvider.scriptReply);
    });

    test('the script replies contain no scripture', () {
      for (final String r in <String>[
        OfflineHadiProvider.scriptReplyArabic,
        OfflineHadiProvider.scriptReplyArabicKeyed,
        OfflineHadiProvider.scriptReplyUrdu,
        OfflineHadiProvider.scriptReplyUrduKeyed,
      ]) {
        // Plain prose carries a few vowel marks; vowelled scripture dozens.
        final int marks = RegExp(
          '[\u064B-\u0652\u0670\u06D6-\u06ED]',
        ).allMatches(r).length;
        expect(marks, lessThan(10));
        expect(r.contains('\uFD3F'), isFalse);
      }
    });
  });

  group('offline shelf: every saying carries a citation', () {
    final List<String> answers = shelfAnswers(
        File('lib/features/hadi/data/offline_hadi_provider.dart')
            .readAsStringSync());

    test('the shelf was parsed', () {
      expect(answers.length, greaterThan(250));
    });

    test('no attribution to the Prophet is left without a source', () {
      final List<String> bad = <String>[];
      for (int i = 0; i < answers.length; i++) {
        for (final String u in uncited(answers[i])) {
          bad.add('$i: ${u.replaceAll('\n', ' ')}');
        }
      }
      expect(bad, isEmpty);
    });
  });
}
