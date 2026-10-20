import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/features/sakina/domain/crisis_detector.dart';
import 'package:ar_rayaan/features/sakina/domain/sakina_content.dart';
import 'package:flutter_test/flutter_test.dart';

import 'hadi_eval/corpus_fixture.dart';

void main() {
  final RegExp quranSource =
      RegExp(r'^Quran (\d+):(\d+)(?:[-–](\d+))?');

  group('comfort deck', () {
    test('every Qur\'an card is the bundled translation, word for word', () {
      int checked = 0;
      for (final ComfortCard c in ComfortCards.deck) {
        final RegExpMatch? m = quranSource.firstMatch(c.source);
        if (m == null) continue;
        final int s = int.parse(m.group(1)!);
        final int a = int.parse(m.group(2)!);
        final int b = m.group(3) == null ? a : int.parse(m.group(3)!);
        final String full = condenseText(quranEnglish(s, a, b));
        for (final String seg in c.text.split('…')) {
          final String n = condenseText(seg);
          if (n.isEmpty) continue;
          expect(full.contains(n), isTrue,
              reason: '${c.source}: "$seg" is not in the bundled text');
        }
        checked++;
      }
      expect(checked, greaterThanOrEqualTo(10));
    });

    test('every hadith card names a hadith that Hādi\'s library holds', () {
      final Map<String, dynamic> corpus = readCorpusJson();
      final Set<String> have = <String>{
        for (final dynamic h in corpus['hadith'] as List<dynamic>)
          '${(h as Map<String, dynamic>)['number']}',
      };
      for (final ComfortCard c in ComfortCards.deck) {
        if (quranSource.hasMatch(c.source)) continue;
        final RegExpMatch? m = RegExp(r'(\d{3,5})').firstMatch(c.source);
        expect(m, isNotNull, reason: c.source);
        expect(have.contains(m!.group(1)), isTrue,
            reason: '${c.source} is not in assets/noor/hadi_corpus.json');
      }
    });

    test('the weak Tirmidhi card is withheld, not shown', () {
      expect(ComfortCards.withheld, isNotEmpty);
      for (final ComfortCard w in ComfortCards.withheld) {
        expect(
          ComfortCards.deck.any((ComfortCard c) => c.text == w.text),
          isFalse,
        );
      }
      expect(
        ComfortCards.deck.any((ComfortCard c) => c.source.contains('2499')),
        isFalse,
      );
    });

    test('the word of the day never comes from a hardship-meaning card', () {
      expect(ComfortCards.daily, isNotEmpty);
      for (final ComfortCard c in ComfortCards.daily) {
        expect(c.meaning, isFalse);
      }
    });

    test('no card promises more than its source says', () {
      for (final ComfortCard c in ComfortCards.deck) {
        final String l = c.text.toLowerCase();
        expect(l.contains('guaranteed'), isFalse, reason: c.text);
        expect(l.contains('every sin is erased'), isFalse, reason: c.text);
      }
    });
  });

  group('crisis replies', () {
    test('every Qur\'an quotation in a reply is the bundled text', () {
      final RegExp quote =
          RegExp(r'“([^”]+)”\s*\(Qur’an (\d+):(\d+)');
      int checked = 0;
      for (final CrisisKind k in CrisisKind.values) {
        final String t = CrisisResponses.textFor(k, countryCode: 'US');
        for (final RegExpMatch m in quote.allMatches(t)) {
          final String full = condenseText(quranEnglish(
            int.parse(m.group(2)!),
            int.parse(m.group(3)!),
            int.parse(m.group(3)!),
          ));
          for (final String seg in m.group(1)!.split('…')) {
            final String n = condenseText(seg);
            if (n.isEmpty) continue;
            expect(full.contains(n), isTrue,
                reason: '$k: "$seg" is not in the bundled text');
          }
          checked++;
        }
      }
      expect(checked, greaterThanOrEqualTo(4));
    });

    test('the self-harm follow-up quotation (93:3) is the bundled text', () {
      final String src = File(
        'lib/features/hadi/application/hadi_controller.dart',
      ).readAsStringSync();
      expect(src.contains('(Qur’an 93:3)'), isTrue);
      final String full = condenseText(quranEnglish(93, 3, 3));
      expect(
        full.contains(condenseText(
          'Your Lord has not taken leave of you, [O Muhammad], nor has He '
          'detested [you].',
        )),
        isTrue,
      );
    });
  });

  group('noor', () {
    final List<dynamic> entries = (json.decode(
      File('assets/noor/noor.json').readAsStringSync(),
    ) as Map<String, dynamic>)['entries'] as List<dynamic>;

    test('Qur\'an entries are the bundled Arabic and English', () {
      final List<dynamic> quran = json.decode(
        File('assets/quran/quran.json').readAsStringSync(),
      ) as List<dynamic>;
      int checked = 0;
      for (final dynamic e in entries) {
        final Map<String, dynamic> m = e as Map<String, dynamic>;
        if (m['k'] != 'quran') continue;
        final RegExpMatch r =
            RegExp(r'^(\d+):(\d+)(?:-(\d+))?$').firstMatch(m['ref'] as String)!;
        final int s = int.parse(r.group(1)!);
        final int a = int.parse(r.group(2)!);
        final int b = r.group(3) == null ? a : int.parse(r.group(3)!);
        final List<dynamic> verses =
            (quran[s - 1] as Map<String, dynamic>)['v'] as List<dynamic>;
        final String ar = <String>[
          for (int i = a; i <= b; i++) (verses[i - 1] as List<dynamic>)[1] as String,
        ].join(' ');
        expect((m['ar'] as String).trim(), ar.trim(), reason: m['ref'] as String);
        expect(
          condenseText(quranEnglish(s, a, b)).contains(condenseText(m['en'] as String)),
          isTrue,
          reason: m['ref'] as String,
        );
        checked++;
      }
      expect(checked, greaterThanOrEqualTo(20));
    });

    test('Forty Hadith entries are the bundled Forty Hadith', () {
      final List<dynamic> forty = json.decode(
        File('assets/hadith/nawawi40.json').readAsStringSync(),
      ) as List<dynamic>;
      for (final dynamic e in entries) {
        final Map<String, dynamic> m = e as Map<String, dynamic>;
        if (m['k'] != 'hadith') continue;
        final int n = int.parse(
          RegExp(r'(\d+)$').firstMatch(m['src'] as String)!.group(1)!,
        );
        final Map<String, dynamic> h = forty
            .cast<Map<String, dynamic>>()
            .firstWhere((Map<String, dynamic> x) => x['n'] == n);
        expect(m['en'], h['en'], reason: m['src'] as String);
        expect(m['ar'], h['ar'], reason: m['src'] as String);
      }
    });
  });
}
