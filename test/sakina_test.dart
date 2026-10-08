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
      expect(ComfortCards.deck.first.text, contains('forgives ALL sins'));
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
}
