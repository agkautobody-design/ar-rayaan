import 'package:ar_rayaan/features/zakat/domain/live_prices.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LivePrices.isUsd', () {
    test('accepts the usual ways of writing dollars', () {
      for (final String s in <String>['USD', 'usd', ' Usd ', r'$', 'US\$', 'U.S.D', 'US dollars']) {
        expect(LivePrices.isUsd(s), isTrue, reason: s);
      }
    });

    test('rejects other currencies and an empty box', () {
      for (final String s in <String>['', '  ', 'PKR', 'GBP', 'CAD', 'EUR', 'USDT']) {
        expect(LivePrices.isUsd(s), isFalse, reason: s);
      }
    });
  });

  group('LivePrices.blockedReason', () {
    test('allows dollars', () {
      expect(LivePrices.blockedReason('USD'), isNull);
    });

    test('an empty currency is not assumed to be dollars', () {
      final String? r = LivePrices.blockedReason('');
      expect(r, isNotNull);
      expect(r, contains('type USD'));
    });

    test('names the currency the person chose', () {
      final String? r = LivePrices.blockedReason('pkr');
      expect(r, contains('PKR'));
      expect(r, contains('yourself'));
    });
  });

  group('LivePrices.perGram', () {
    test('converts dollars per ounce to dollars per gram', () {
      final p = LivePrices.perGram('{"price": 3110.35}', '{"price": 31.1035}');
      expect((p.gold - 100).abs() < 1e-9, isTrue);
      expect((p.silver - 1).abs() < 1e-9, isTrue);
    });

    test('refuses a body that is not a price', () {
      for (final String bad in <String>[
        '[]',
        '{}',
        '{"price": "2650"}',
        '{"price": 0}',
        '{"price": -4}',
        '{"price": null}',
        'not json',
      ]) {
        var threw = false;
        try {
          LivePrices.perGram(bad, '{"price": 30}');
        } on FormatException {
          threw = true;
        }
        expect(threw, isTrue, reason: bad);
      }
    });
  });
}
