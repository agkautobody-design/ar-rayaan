import 'dart:io';

import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/data/offline_hadi_provider.dart';
import 'package:flutter_test/flutter_test.dart';

Future<String> ask(String q) =>
    const OfflineHadiProvider().ask(q, const <HadiMessage>[]);

void main() {
  group('offline matcher: whole words, not substrings', () {
    test('"breakfast" is not a Ramadan-fasting question', () async {
      final String a = await ask('breakfast');
      expect(a, OfflineHadiProvider.decline);
    });

    test('"business" is not a sin/zina/other keyword hit', () async {
      final String a = await ask('business');
      expect(a, OfflineHadiProvider.decline);
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
      expect(await ask('Who will win the football match?'),
          OfflineHadiProvider.decline);
    });
  });

  group('offline matcher: rulings are not guessed', () {
    test('"is a credit card halal" does not return a generic halal answer',
        () async {
      final String a = await ask('is a credit card halal');
      expect(a, OfflineHadiProvider.rulingDecline);
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
}
