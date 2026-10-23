import 'package:ar_rayaan/features/quran/domain/quran_models.dart';
import 'package:ar_rayaan/features/quran/domain/surah_search.dart';
import 'package:flutter_test/flutter_test.dart';

SurahMeta _m(int n, String ar, String tl, String en, int c) => SurahMeta(
  number: n,
  arabicName: ar,
  transliteration: tl,
  englishMeaning: en,
  revelationType: 'meccan',
  ayahCount: c,
);

void main() {
  final List<SurahMeta> all = <SurahMeta>[
    _m(1, 'الفاتحة', 'Al-Fatihah', 'The Opener', 7),
    _m(2, 'البقرة', 'Al-Baqarah', 'The Cow', 286),
    _m(36, 'يس', 'Ya-Sin', 'Ya Sin', 83),
    _m(67, 'الملك', 'Al-Mulk', 'The Sovereignty', 30),
  ];

  List<int> nums(String q) =>
      filterSurahs(all, q).map((SurahMeta s) => s.number).toList();

  test('empty query returns everything', () {
    expect(nums(''), <int>[1, 2, 36, 67]);
    expect(nums('  '), <int>[1, 2, 36, 67]);
  });

  test('number matches that surah only', () {
    expect(nums('36'), <int>[36]);
    expect(nums('3'), isEmpty);
  });

  test('transliteration ignores case, hyphens and spaces', () {
    expect(nums('yasin'), <int>[36]);
    expect(nums('Ya-Sin'), <int>[36]);
    expect(nums('ya sin'), <int>[36]);
    expect(nums('mulk'), <int>[67]);
    expect(nums('baqarah'), <int>[2]);
  });

  test('English meaning and Arabic name match', () {
    expect(nums('cow'), <int>[2]);
    expect(nums('opener'), <int>[1]);
    expect(nums('الملك'), <int>[67]);
    expect(nums('يَس'), <int>[36]);
  });

  test('no match gives an empty list', () {
    expect(nums('zzz'), isEmpty);
  });

  test('parseAyahJump validates against the ayah count', () {
    expect(parseAyahJump('5', 7), 5);
    expect(parseAyahJump(' 7 ', 7), 7);
    expect(parseAyahJump('1', 7), 1);
    expect(parseAyahJump('0', 7), isNull);
    expect(parseAyahJump('8', 7), isNull);
    expect(parseAyahJump('-3', 7), isNull);
    expect(parseAyahJump('abc', 7), isNull);
    expect(parseAyahJump('', 7), isNull);
    expect(parseAyahJump('255', 286), 255);
  });
}
