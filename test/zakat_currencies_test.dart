import 'package:ar_rayaan/features/zakat/domain/zakat_currencies.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the currency list', () {
    test('has at least 40 currencies, no repeats, and the ones asked for', () {
      final List<String> codes =
          ZakatCurrencies.all.map((ZakatCurrency c) => c.code).toList();
      expect(codes.length, greaterThanOrEqualTo(40));
      expect(codes.toSet().length, codes.length);
      for (final String c in <String>[
        'CAD', 'USD', 'GBP', 'EUR', 'AUD', 'PKR', 'INR', 'BDT', 'SAR', 'AED',
        'EGP', 'TRY', 'IDR', 'MYR', 'NGN', 'ZAR', 'SGD', 'QAR', 'KWD', 'OMR',
        'JOD', 'MAD', 'DZD',
      ]) {
        expect(codes, contains(c), reason: c);
      }
      for (final ZakatCurrency c in ZakatCurrencies.all) {
        expect(RegExp(r'^[A-Z]{3}$').hasMatch(c.code), isTrue, reason: c.code);
        expect(c.name.trim(), isNotEmpty);
      }
    });

    test('currencies whose official and street rates part ways are left out',
        () {
      for (final String c in <String>['IRR', 'LBP', 'SYP', 'YER', 'SDG', 'VES']) {
        expect(ZakatCurrencies.byCode(c), isNull, reason: c);
      }
    });
  });

  group('reading the currency box', () {
    test('codes in any case, dollar signs and English names', () {
      expect(ZakatCurrencies.codeFromLabel('cad'), 'CAD');
      expect(ZakatCurrencies.codeFromLabel(' Pkr '), 'PKR');
      expect(ZakatCurrencies.codeFromLabel(r'$'), 'USD');
      expect(ZakatCurrencies.codeFromLabel('US dollars'), 'USD');
      expect(ZakatCurrencies.codeFromLabel('Canadian dollar'), 'CAD');
    });

    test('empty, unknown or not-offered stays null', () {
      for (final String s in <String>['', '  ', 'XYZ', 'IRR', 'USDT', 'rupee']) {
        expect(ZakatCurrencies.codeFromLabel(s), isNull, reason: s);
      }
      expect(ZakatCurrencies.codeFromLabel(null), isNull);
    });
  });

  group('regional detection', () {
    test('from the device region', () {
      final Map<String, String> expected = <String, String>{
        'CA': 'CAD', 'US': 'USD', 'GB': 'GBP', 'DE': 'EUR', 'FR': 'EUR',
        'AU': 'AUD', 'PK': 'PKR', 'IN': 'INR', 'BD': 'BDT', 'SA': 'SAR',
        'AE': 'AED', 'EG': 'EGP', 'TR': 'TRY', 'ID': 'IDR', 'MY': 'MYR',
        'NG': 'NGN', 'ZA': 'ZAR', 'SG': 'SGD', 'QA': 'QAR', 'KW': 'KWD',
        'OM': 'OMR', 'JO': 'JOD', 'MA': 'MAD', 'DZ': 'DZD', 'BG': 'EUR',
        'SN': 'XOF', 'CM': 'XAF',
      };
      expected.forEach((String cc, String cur) {
        final DetectedCurrency? d =
            ZakatCurrencies.detect(deviceCountryCode: cc);
        expect(d?.code, cur, reason: cc);
        expect(d!.reason, contains('device region'));
      });
      expect(ZakatCurrencies.detect(deviceCountryCode: 'ca')?.code, 'CAD');
    });

    test('from the country of the saved prayer-times city', () {
      final Map<String, String> expected = <String, String>{
        'Canada': 'CAD', 'United States': 'USD', 'United Kingdom': 'GBP',
        'Saudi Arabia': 'SAR', 'UAE': 'AED', 'Türkiye': 'TRY',
        'The Netherlands': 'EUR', 'Pakistan': 'PKR', 'Indonesia': 'IDR',
        'Côte d\'Ivoire': 'XOF', 'Germany': 'EUR', 'Bangladesh': 'BDT',
      };
      expected.forEach((String name, String cur) {
        final DetectedCurrency? d =
            ZakatCurrencies.detect(placeCountryName: name);
        expect(d?.code, cur, reason: name);
        expect(d!.reason, contains('prayer-times location'));
        expect(d.reason, contains(name));
      });
    });

    test('every country in the prayer-times city list either maps to a '
        'listed currency or gives no guess, never a wrong one', () {
      for (final String name in <String>[
        'Iran', 'Yemen', 'Syria', 'Sudan', 'Somalia', 'Venezuela', 'Atlantis', '',
      ]) {
        expect(ZakatCurrencies.detect(placeCountryName: name), isNull,
            reason: name);
      }
    });

    test('the saved city wins over the device region; the device region is '
        'used when there is no city', () {
      expect(
          ZakatCurrencies.detect(
                  placeCountryName: 'Pakistan', deviceCountryCode: 'CA')
              ?.code,
          'PKR');
      expect(
          ZakatCurrencies.detect(placeCountryName: '', deviceCountryCode: 'CA')
              ?.code,
          'CAD');
      expect(
          ZakatCurrencies.detect(
                  placeCountryName: 'Iran', deviceCountryCode: 'CA')
              ?.code,
          'CAD');
    });

    test('nothing known gives null', () {
      expect(ZakatCurrencies.detect(), isNull);
      expect(ZakatCurrencies.detect(deviceCountryCode: ''), isNull);
      expect(ZakatCurrencies.detect(deviceCountryCode: 'IR'), isNull);
    });

    test('every currency a country maps to is in the list', () {
      for (final String cc in <String>[
        'US', 'CA', 'GB', 'AU', 'NZ', 'PK', 'IN', 'BD', 'LK', 'NP', 'AF', 'SA',
        'AE', 'QA', 'KW', 'OM', 'BH', 'JO', 'IQ', 'EG', 'TR', 'MA', 'DZ', 'TN',
        'LY', 'ID', 'MY', 'SG', 'BN', 'TH', 'PH', 'NG', 'ZA', 'KE', 'GH', 'ET',
        'TZ', 'UG', 'CH', 'SE', 'NO', 'DK', 'PL', 'RU', 'KZ', 'UZ', 'AZ', 'JP',
        'CN', 'HK', 'MX', 'BR', 'MV', 'ES', 'IT', 'NL',
      ]) {
        final String? cur = ZakatCurrencies.forCountryCode(cc);
        expect(ZakatCurrencies.byCode(cur), isNotNull, reason: cc);
      }
    });
  });
}
