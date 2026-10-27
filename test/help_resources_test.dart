import 'package:ar_rayaan/features/sakina/domain/crisis_detector.dart';
import 'package:ar_rayaan/features/sakina/domain/sakina_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime parse(String s) => DateTime.parse(s);

  group('help line data', () {
    test('a verified row names the page it was read on and the day', () {
      for (final HelpResource r in HelpResources.all) {
        if (!r.verified) continue;
        expect(r.source!.startsWith('https://'), isTrue, reason: r.name);
        expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(r.verifiedOn!), isTrue,
            reason: r.name);
      }
      expect(
        HelpResources.all.where((HelpResource r) => r.verified).length,
        greaterThanOrEqualTo(30),
      );
    });

    test('STALENESS: no verified row is older than nine months', () {
      final DateTime limit = DateTime.now().subtract(const Duration(days: 274));
      final List<String> stale = <String>[
        for (final HelpResource r in HelpResources.all)
          if (r.verified && parse(r.verifiedOn!).isBefore(limit)) r.name,
      ];
      expect(stale, isEmpty,
          reason: 'Re-check these on the operators\' own pages, then update '
              'verifiedOn and HelpResources.checked: $stale');
      expect(parse(HelpResources.checked).isBefore(limit), isFalse);
    });

    test('numbers that could not be verified are not on screen', () {
      expect(HelpResources.unverified, isNotEmpty);
      for (final HelpResource u in HelpResources.unverified) {
        expect(HelpResources.all.any((HelpResource r) => r.contact == u.contact && r.region == u.region),
            isFalse,
            reason: '${u.name} is unverified and must stay out of all');
        expect(u.verified, isFalse);
      }
    });

    test('rows can be acted on and dial digits only', () {
      for (final HelpResource r in HelpResources.all) {
        expect(r.dial != null || r.url != null, isTrue, reason: r.name);
        if (r.dial != null) {
          expect(RegExp(r'^\d{2,11}$').hasMatch(r.dial!), isTrue, reason: r.name);
        }
      }
    });

    test('a worldwide row never dials a country-specific number', () {
      for (final HelpResource r in HelpResources.all) {
        if (r.countries.isNotEmpty || r.dial == null) continue;
        expect(r.dial, isNot('911'), reason: r.name);
        expect(r.dial, isNot('988'), reason: r.name);
      }
    });

    test('every kind of moment has at least one row for an unknown country',
        () {
      for (final CrisisKind k in CrisisKind.values) {
        expect(CrisisResponses.resourcesFor(k, null), isNotEmpty,
            reason: k.name);
      }
    });

    test('child-safety readers in the US see a child line', () {
      final List<HelpResource> rows =
          CrisisResponses.resourcesFor(CrisisKind.childSafety, 'US');
      expect(rows.any((HelpResource r) => r.kinds.contains(HelpKind.child)),
          isTrue);
    });
  });
}
