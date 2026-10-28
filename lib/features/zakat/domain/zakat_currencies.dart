/// Currencies the Zakat calculator can fetch live gold and silver prices in,
/// and how the app guesses a person's currency from where they are.
///
/// Nothing here touches the network. The guess is made on the device from
/// two things the person already gave the app or the phone: the country of
/// their saved prayer-times city, and the region of the device language. It
/// is only ever a starting point: the person can pick another currency from
/// the list or type the prices themselves.
library;

class ZakatCurrency {
  const ZakatCurrency(this.code, this.name);

  /// ISO 4217 code, upper case.
  final String code;

  /// Plain English name.
  final String name;

  /// "CAD · Canadian dollar"
  String get label => '$code · $name';
}

/// A currency worked out from a place, with the reason in words.
class DetectedCurrency {
  const DetectedCurrency(this.code, this.reason);

  final String code;

  /// e.g. "your prayer-times location (Canada)".
  final String reason;
}

abstract final class ZakatCurrencies {
  /// The currencies offered. Left out on purpose: currencies whose official
  /// rate differs sharply from the rate people actually trade at (for
  /// example the Iranian rial, Lebanese pound, Syrian pound, Yemeni rial,
  /// Sudanese pound and Venezuelan bolivar). A published reference rate
  /// would mislead there, so those people type the prices themselves.
  static const List<ZakatCurrency> all = <ZakatCurrency>[
    ZakatCurrency('USD', 'US dollar'),
    ZakatCurrency('CAD', 'Canadian dollar'),
    ZakatCurrency('GBP', 'Pound sterling'),
    ZakatCurrency('EUR', 'Euro'),
    ZakatCurrency('AUD', 'Australian dollar'),
    ZakatCurrency('NZD', 'New Zealand dollar'),
    ZakatCurrency('PKR', 'Pakistani rupee'),
    ZakatCurrency('INR', 'Indian rupee'),
    ZakatCurrency('BDT', 'Bangladeshi taka'),
    ZakatCurrency('LKR', 'Sri Lankan rupee'),
    ZakatCurrency('NPR', 'Nepalese rupee'),
    ZakatCurrency('AFN', 'Afghan afghani'),
    ZakatCurrency('SAR', 'Saudi riyal'),
    ZakatCurrency('AED', 'UAE dirham'),
    ZakatCurrency('QAR', 'Qatari riyal'),
    ZakatCurrency('KWD', 'Kuwaiti dinar'),
    ZakatCurrency('OMR', 'Omani rial'),
    ZakatCurrency('BHD', 'Bahraini dinar'),
    ZakatCurrency('JOD', 'Jordanian dinar'),
    ZakatCurrency('IQD', 'Iraqi dinar'),
    ZakatCurrency('EGP', 'Egyptian pound'),
    ZakatCurrency('TRY', 'Turkish lira'),
    ZakatCurrency('MAD', 'Moroccan dirham'),
    ZakatCurrency('DZD', 'Algerian dinar'),
    ZakatCurrency('TND', 'Tunisian dinar'),
    ZakatCurrency('LYD', 'Libyan dinar'),
    ZakatCurrency('IDR', 'Indonesian rupiah'),
    ZakatCurrency('MYR', 'Malaysian ringgit'),
    ZakatCurrency('SGD', 'Singapore dollar'),
    ZakatCurrency('BND', 'Brunei dollar'),
    ZakatCurrency('THB', 'Thai baht'),
    ZakatCurrency('PHP', 'Philippine peso'),
    ZakatCurrency('NGN', 'Nigerian naira'),
    ZakatCurrency('ZAR', 'South African rand'),
    ZakatCurrency('KES', 'Kenyan shilling'),
    ZakatCurrency('GHS', 'Ghanaian cedi'),
    ZakatCurrency('ETB', 'Ethiopian birr'),
    ZakatCurrency('TZS', 'Tanzanian shilling'),
    ZakatCurrency('UGX', 'Ugandan shilling'),
    ZakatCurrency('XOF', 'West African CFA franc'),
    ZakatCurrency('XAF', 'Central African CFA franc'),
    ZakatCurrency('CHF', 'Swiss franc'),
    ZakatCurrency('SEK', 'Swedish krona'),
    ZakatCurrency('NOK', 'Norwegian krone'),
    ZakatCurrency('DKK', 'Danish krone'),
    ZakatCurrency('PLN', 'Polish zloty'),
    ZakatCurrency('RUB', 'Russian rouble'),
    ZakatCurrency('KZT', 'Kazakhstani tenge'),
    ZakatCurrency('UZS', 'Uzbekistani som'),
    ZakatCurrency('AZN', 'Azerbaijani manat'),
    ZakatCurrency('JPY', 'Japanese yen'),
    ZakatCurrency('CNY', 'Chinese yuan'),
    ZakatCurrency('HKD', 'Hong Kong dollar'),
    ZakatCurrency('MXN', 'Mexican peso'),
    ZakatCurrency('BRL', 'Brazilian real'),
    ZakatCurrency('MVR', 'Maldivian rufiyaa'),
  ];

  static final Map<String, ZakatCurrency> _byCode = <String, ZakatCurrency>{
    for (final ZakatCurrency c in all) c.code: c,
  };

  /// The listed currency whose code is [code] (any case), or null.
  static ZakatCurrency? byCode(String? code) =>
      code == null ? null : _byCode[code.trim().toUpperCase()];

  /// The listed currency code that the free text in the currency box means,
  /// or null when it is not one of the listed currencies (or is empty).
  /// Accepts the code ("cad"), the dollar sign forms people type for US
  /// dollars, and the English name ("Canadian dollar").
  static String? codeFromLabel(String? label) {
    if (label == null) return null;
    final String t = label.trim().toUpperCase().replaceAll('.', '');
    if (t.isEmpty) return null;
    if (_byCode.containsKey(t)) return t;
    if (t == r'$' ||
        t == r'US$' ||
        t == 'US DOLLAR' ||
        t == 'US DOLLARS' ||
        t == 'DOLLAR' ||
        t == 'DOLLARS') {
      return 'USD';
    }
    for (final ZakatCurrency c in all) {
      if (c.name.toUpperCase() == t) return c.code;
    }
    return null;
  }

  /// Currency of an ISO 3166-1 alpha-2 country code, or null when the
  /// country's currency is not in the list.
  static String? forCountryCode(String? countryCode) {
    if (countryCode == null) return null;
    return _countryToCurrency[countryCode.trim().toUpperCase()];
  }

  /// Currency of a country named the way the prayer-times city list names it
  /// ("Canada", "UAE", "Türkiye", "The Netherlands"), or null.
  static String? forCountryName(String? countryName) {
    if (countryName == null) return null;
    final String n = countryName.trim().toLowerCase();
    if (n.isEmpty) return null;
    final String? iso = _nameToIso[n];
    return iso == null ? null : _countryToCurrency[iso];
  }

  /// Best guess for the person's currency: the country of the saved
  /// prayer-times city first (a choice they made in the app), then the
  /// region of the device language. Null when neither tells us.
  static DetectedCurrency? detect({
    String? placeCountryName,
    String? deviceCountryCode,
  }) {
    final String? fromPlace = forCountryName(placeCountryName);
    if (fromPlace != null) {
      return DetectedCurrency(
        fromPlace,
        'your prayer-times location (${placeCountryName!.trim()})',
      );
    }
    final String? fromDevice = forCountryCode(deviceCountryCode);
    if (fromDevice != null) {
      return DetectedCurrency(
        fromDevice,
        'your device region (${deviceCountryCode!.trim().toUpperCase()})',
      );
    }
    return null;
  }

  static const Map<String, String> _countryToCurrency = <String, String>{
    'US': 'USD',
    'CA': 'CAD',
    'GB': 'GBP',
    'AU': 'AUD',
    'NZ': 'NZD',
    'PK': 'PKR',
    'IN': 'INR',
    'BD': 'BDT',
    'LK': 'LKR',
    'NP': 'NPR',
    'AF': 'AFN',
    'SA': 'SAR',
    'AE': 'AED',
    'QA': 'QAR',
    'KW': 'KWD',
    'OM': 'OMR',
    'BH': 'BHD',
    'JO': 'JOD',
    'IQ': 'IQD',
    'EG': 'EGP',
    'TR': 'TRY',
    'MA': 'MAD',
    'DZ': 'DZD',
    'TN': 'TND',
    'LY': 'LYD',
    'ID': 'IDR',
    'MY': 'MYR',
    'SG': 'SGD',
    'BN': 'BND',
    'TH': 'THB',
    'PH': 'PHP',
    'NG': 'NGN',
    'ZA': 'ZAR',
    'KE': 'KES',
    'GH': 'GHS',
    'ET': 'ETB',
    'TZ': 'TZS',
    'UG': 'UGX',
    'SN': 'XOF',
    'ML': 'XOF',
    'NE': 'XOF',
    'CI': 'XOF',
    'BF': 'XOF',
    'BJ': 'XOF',
    'TG': 'XOF',
    'GW': 'XOF',
    'CM': 'XAF',
    'TD': 'XAF',
    'GA': 'XAF',
    'CG': 'XAF',
    'CF': 'XAF',
    'GQ': 'XAF',
    'CH': 'CHF',
    'SE': 'SEK',
    'NO': 'NOK',
    'DK': 'DKK',
    'PL': 'PLN',
    'RU': 'RUB',
    'KZ': 'KZT',
    'UZ': 'UZS',
    'AZ': 'AZN',
    'JP': 'JPY',
    'CN': 'CNY',
    'HK': 'HKD',
    'MX': 'MXN',
    'BR': 'BRL',
    'MV': 'MVR',
    // Euro area (Bulgaria joined on 1 January 2026), plus the countries that
    // use the euro without being members.
    'AT': 'EUR',
    'BE': 'EUR',
    'BG': 'EUR',
    'HR': 'EUR',
    'CY': 'EUR',
    'EE': 'EUR',
    'FI': 'EUR',
    'FR': 'EUR',
    'DE': 'EUR',
    'GR': 'EUR',
    'IE': 'EUR',
    'IT': 'EUR',
    'LV': 'EUR',
    'LT': 'EUR',
    'LU': 'EUR',
    'MT': 'EUR',
    'NL': 'EUR',
    'PT': 'EUR',
    'SK': 'EUR',
    'SI': 'EUR',
    'ES': 'EUR',
    'AD': 'EUR',
    'MC': 'EUR',
    'SM': 'EUR',
    'VA': 'EUR',
    'ME': 'EUR',
    'XK': 'EUR',
  };

  /// Lower-case country names as the prayer-times city list and common
  /// alternatives write them, to ISO 3166-1 alpha-2. A name that is not here
  /// (or whose currency is not listed) gives no guess: never a wrong one.
  static const Map<String, String> _nameToIso = <String, String>{
    'united states': 'US',
    'united states of america': 'US',
    'usa': 'US',
    'canada': 'CA',
    'united kingdom': 'GB',
    'uk': 'GB',
    'australia': 'AU',
    'new zealand': 'NZ',
    'pakistan': 'PK',
    'india': 'IN',
    'bangladesh': 'BD',
    'sri lanka': 'LK',
    'nepal': 'NP',
    'afghanistan': 'AF',
    'saudi arabia': 'SA',
    'uae': 'AE',
    'united arab emirates': 'AE',
    'qatar': 'QA',
    'kuwait': 'KW',
    'oman': 'OM',
    'bahrain': 'BH',
    'jordan': 'JO',
    'iraq': 'IQ',
    'egypt': 'EG',
    'türkiye': 'TR',
    'turkiye': 'TR',
    'turkey': 'TR',
    'morocco': 'MA',
    'algeria': 'DZ',
    'tunisia': 'TN',
    'libya': 'LY',
    'indonesia': 'ID',
    'malaysia': 'MY',
    'singapore': 'SG',
    'brunei': 'BN',
    'thailand': 'TH',
    'philippines': 'PH',
    'nigeria': 'NG',
    'south africa': 'ZA',
    'kenya': 'KE',
    'ghana': 'GH',
    'ethiopia': 'ET',
    'tanzania': 'TZ',
    'uganda': 'UG',
    'senegal': 'SN',
    'côte d\'ivoire': 'CI',
    'ivory coast': 'CI',
    'mali': 'ML',
    'niger': 'NE',
    'burkina faso': 'BF',
    'benin': 'BJ',
    'togo': 'TG',
    'guinea-bissau': 'GW',
    'cameroon': 'CM',
    'chad': 'TD',
    'gabon': 'GA',
    'switzerland': 'CH',
    'sweden': 'SE',
    'norway': 'NO',
    'denmark': 'DK',
    'poland': 'PL',
    'russia': 'RU',
    'kazakhstan': 'KZ',
    'uzbekistan': 'UZ',
    'azerbaijan': 'AZ',
    'japan': 'JP',
    'china': 'CN',
    'hong kong': 'HK',
    'mexico': 'MX',
    'brazil': 'BR',
    'maldives': 'MV',
    'austria': 'AT',
    'belgium': 'BE',
    'bulgaria': 'BG',
    'croatia': 'HR',
    'cyprus': 'CY',
    'estonia': 'EE',
    'finland': 'FI',
    'france': 'FR',
    'germany': 'DE',
    'greece': 'GR',
    'ireland': 'IE',
    'italy': 'IT',
    'latvia': 'LV',
    'lithuania': 'LT',
    'luxembourg': 'LU',
    'malta': 'MT',
    'the netherlands': 'NL',
    'netherlands': 'NL',
    'portugal': 'PT',
    'slovakia': 'SK',
    'slovenia': 'SI',
    'spain': 'ES',
    'kosovo': 'XK',
    'montenegro': 'ME',
  };
}
