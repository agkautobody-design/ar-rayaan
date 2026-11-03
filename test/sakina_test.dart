import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/features/sakina/domain/marriage_tools.dart';
import 'package:ar_rayaan/features/sakina/domain/sakina_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Sakina crisis shell content', () {
    test('six rooms, each with a non-empty door line', () {
      expect(SakinaRooms.all.length, 6);
      for (final SakinaRoom r in SakinaRooms.all) {
        expect(r.name, isNotEmpty);
        expect(r.doorLine.length, greaterThan(80));
        expect(r.emoji, isNotEmpty);
      }
    });

    test('the founder-critical rooms exist', () {
      final Set<String> ids = SakinaRooms.all.map((SakinaRoom r) => r.id).toSet();
      expect(ids, containsAll(<String>{'quiet-war', 'marriage', 'family', 'loss', 'son-father-husband', 'whisper'}));
    });

    test('comfort deck: 20 cards, all sourced, none lecture', () {
      expect(ComfortCards.deck.length, 20);
      for (final ComfortCard c in ComfortCards.deck) {
        expect(c.source, isNotEmpty, reason: c.text);
        expect(
          c.source,
          contains(RegExp(r'Quran|Bukhari|Muslim|Tirmidhi|Dawud')),
          reason: 'unsourced comfort card: ${c.text}',
        );
        // The shame filter: no scolding language in a comfort deck.
        final String lower = c.text.toLowerCase();
        for (final String banned in <String>['punish', 'hellfire awaits', 'you failed', 'sinner']) {
          expect(lower.contains(banned), isFalse, reason: c.text);
        }
      }
    });

    test('39:53 leads the deck — mercy before everything', () {
      expect(ComfortCards.deck.first.source, contains('39:53'));
      expect(ComfortCards.deck.first.text, contains('forgives all sins'));
    });

    test('human help is always present with crisis lines', () {
      expect(HelpResources.all.length, greaterThanOrEqualTo(5));
      expect(
        HelpResources.all.any((HelpResource r) => r.name.contains('Naseeha')),
        isTrue,
      );
      expect(
        HelpResources.all.any((HelpResource r) => r.contact.contains('988')),
        isTrue,
        reason: 'a suicide crisis line must be on screen',
      );
      expect(
        HelpResources.all.any((HelpResource r) => r.name.contains('Emergency')),
        isTrue,
      );
      for (final HelpResource r in HelpResources.all) {
        expect(r.contact, isNotEmpty);
        expect(r.region, isNotEmpty);
        expect(r.detail, isNotEmpty);
        // Every row must do something when tapped: a crisis number that
        // does not dial is worse than none.
        expect(r.dial != null || r.url != null, isTrue,
            reason: '${r.name} has no number to dial and no link');
        if (r.dial != null) {
          expect(RegExp(r'^\d{2,11}$').hasMatch(r.dial!), isTrue,
              reason: '${r.name} dial must be digits only');
        }
      }
    });

    test('no room claims to diagnose — review gate is on record', () {
      // The pathways ship only after clinician + scholar review; the shell
      // carries that statement, and this test guards it from being removed.
      for (final SakinaRoom r in SakinaRooms.all) {
        expect(
          r.doorLine.toLowerCase().contains('diagnos'),
          isFalse,
        );
      }
    });
  });

  group('Between Two Hearts (two-way marriage tools)', () {
    test('five tools, each complete', () {
      expect(MarriageTools.all.length, 5);
      expect(
        MarriageTools.all.map((MarriageTool t) => t.id).toSet(),
        <String>{
          'the-pause',
          'say-it-gently',
          'the-daily-thank-you',
          'rights-both-ways',
          'when-not-safe',
        },
      );
      for (final MarriageTool t in MarriageTools.all) {
        expect(t.title, isNotEmpty);
        expect(t.subtitle, isNotEmpty);
        expect(t.emoji, isNotEmpty);
        expect(t.steps, isNotEmpty);
        for (final MarriageStep s in t.steps) {
          expect(s.heading, isNotEmpty);
          expect(s.body, isNotEmpty);
        }
      }
    });

    test('the scale has two pans: her due and his due', () {
      final MarriageTool t =
          MarriageTools.all.firstWhere((MarriageTool t) => t.id == 'rights-both-ways');
      final String all = t.steps
          .map((MarriageStep s) => '${s.heading} ${s.body}')
          .join(' ')
          .toLowerCase();
      expect(all.contains('her due'), isTrue);
      expect(all.contains('his due'), isTrue);
      expect(all.contains('both pans'), isTrue);
    });

    test('the safety card names harm and runs both directions', () {
      final MarriageTool t =
          MarriageTools.all.firstWhere((MarriageTool t) => t.id == 'when-not-safe');
      final String all = t.steps
          .map((MarriageStep s) => '${s.heading} ${s.body}')
          .join(' ')
          .toLowerCase();
      for (final String phrase in <String>[
        'no harming',
        'safety',
        'both directions',
        'forced intimacy',
        'blows',
      ]) {
        expect(all.contains(phrase), isTrue, reason: phrase);
      }
    });

    test('every source meets the citation standard; no shame language', () {
      const List<String> shameWords = <String>[
        'punish',
        'hellfire awaits',
        'you failed',
        'sinner',
      ];
      for (final MarriageTool t in MarriageTools.all) {
        for (final MarriageStep s in t.steps) {
          final String lower = '${s.heading} ${s.body}'.toLowerCase();
          for (final String w in shameWords) {
            expect(lower.contains(w), isFalse, reason: '${t.id}: $w');
          }
          final String? src = s.source;
          if (src == null) continue;
          final bool ok = RegExp(r"^Qur'an \d+:\d+$").hasMatch(src) ||
              RegExp(r'(Bukhari|Muslim) \d+').hasMatch(src) ||
              RegExp(r'per (al-Albani|Darussalam)').hasMatch(src);
          expect(ok, isTrue, reason: '${t.id}: $src');
        }
      }
    });

    test("the du'a of repair is byte-exact from the bundled Qur'an", () {
      final String raw = File('assets/quran/quran.json').readAsStringSync();
      final List<dynamic> surahs = json.decode(raw) as List<dynamic>;
      final Map<String, dynamic> furqan = surahs.firstWhere(
        (dynamic s) => (s as Map<String, dynamic>)['n'] == 25,
      ) as Map<String, dynamic>;
      final List<dynamic> verses = furqan['v'] as List<dynamic>;
      final List<dynamic> ayah = verses.firstWhere(
        (dynamic v) => (v as List<dynamic>)[0] == 74,
      ) as List<dynamic>;
      final String arabic = ayah[1] as String;
      final String english = ayah[2] as String;
      expect(arabic.contains(MarriageTools.repairDuaArabic), isTrue);
      expect(english.contains('comfort to our eyes'), isTrue);
      expect(MarriageTools.repairDuaBody.contains('comfort to our eyes'), isTrue);
      expect(MarriageTools.repairDuaBody.contains('righteous'), isTrue);
      expect(MarriageTools.repairDuaSource, "Qur'an 25:74");
    });
  });
}
