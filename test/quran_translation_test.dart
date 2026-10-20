import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/features/quran/domain/quran_texts.dart';
import 'package:flutter_test/flutter_test.dart';

/// The bundled English is Saheeh International exactly as the Tanzil Project
/// supplies it (punctuation, quotation marks and dashes included). An earlier
/// copy had the verse-final punctuation trimmed away (112:1 lost its closing
/// quotation mark, 55:13 lost its question mark), which turned questions into
/// statements. These tests pin the restored text.
void main() {
  late List<dynamic> quran;

  String english(int surah, int ayah) {
    final Map<String, dynamic> s = quran[surah - 1] as Map<String, dynamic>;
    final List<dynamic> v = s['v'] as List<dynamic>;
    return (v[ayah - 1] as List<dynamic>)[2] as String;
  }

  setUpAll(() {
    quran = jsonDecode(File('assets/quran/quran.json').readAsStringSync())
        as List<dynamic>;
  });

  test('opening verses are character-for-character the Tanzil lines', () {
    // Lines 1|1 .. 2|5 of tanzil.net/trans/en.sahih, read 20 Oct 2026.
    expect(
      english(1, 1),
      'In the name of Allah, the Entirely Merciful, the Especially Merciful.',
    );
    expect(english(1, 2), '[All] praise is [due] to Allah, Lord of the worlds -');
    expect(english(1, 3), 'The Entirely Merciful, the Especially Merciful,');
    expect(english(1, 4), 'Sovereign of the Day of Recompense.');
    expect(english(1, 5), 'It is You we worship and You we ask for help.');
    expect(english(1, 6), 'Guide us to the straight path -');
    expect(english(2, 1), 'Alif, Lam, Meem.');
    expect(
      english(2, 2),
      'This is the Book about which there is no doubt, a guidance for those '
      'conscious of Allah -',
    );
    expect(
      english(2, 5),
      'Those are upon [right] guidance from their Lord, and it is those who '
      'are the successful.',
    );
  });

  test('questions keep their question mark', () {
    expect(english(55, 13), endsWith('?'));
    expect(english(55, 13), contains('would you deny?'));
    expect(english(76, 1), endsWith('?'));
  });

  test('quotations keep their closing quotation marks', () {
    final String a = english(112, 1);
    expect(a, startsWith('Say, "He is Allah'));
    // The speech opened in 112:1 closes at the end of 112:4.
    expect(english(112, 4), endsWith('."'));
    // 6:130 opens its quotation in the verse itself.
    expect(english(6, 130), startsWith('"O company of jinn and mankind'));
  });

  test('almost every verse ends with punctuation, as the source does', () {
    int total = 0;
    int punctuated = 0;
    for (final dynamic s in quran) {
      for (final dynamic v in (s as Map<String, dynamic>)['v'] as List<dynamic>) {
        final String t = (v as List<dynamic>)[2] as String;
        total++;
        if (RegExp(r'[.?!,;:"\x27-]$').hasMatch(t) || t.endsWith('...')) {
          punctuated++;
        }
      }
    }
    expect(total, 6236);
    // 5,750 of 6,236 in the Tanzil file end in punctuation; the trimmed copy
    // had none. Anything below this means the trimming came back.
    expect(punctuated, greaterThan(5600));
  });

  test('no verse carries stray outer spaces or exotic whitespace', () {
    final RegExp odd = RegExp(r'[ -‏  ]');
    for (final dynamic s in quran) {
      final Map<String, dynamic> sm = s as Map<String, dynamic>;
      for (final dynamic v in sm['v'] as List<dynamic>) {
        final List<dynamic> row = v as List<dynamic>;
        final String t = row[2] as String;
        expect(t, t.trim(), reason: '${sm['n']}:${row[0]}');
        expect(odd.hasMatch(t), isFalse, reason: '${sm['n']}:${row[0]}');
      }
    }
  });

  test('texts.json (credit, link, status) matches the built-in fallback', () {
    final QuranTexts file = QuranTexts.fromJson(
      jsonDecode(File('assets/quran/texts.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    expect(file.arabic.title, QuranTexts.fallback.arabic.title);
    expect(file.arabic.url, QuranTexts.fallback.arabic.url);
    expect(file.arabic.note, QuranTexts.fallback.arabic.note);
    expect(file.translation.title, QuranTexts.fallback.translation.title);
    expect(file.translation.url, QuranTexts.fallback.translation.url);
    expect(file.translation.credit, QuranTexts.fallback.translation.credit);
    expect(file.translation.note, QuranTexts.fallback.translation.note);
    expect(file.arabic.url, startsWith('https://tanzil.net'));
    expect(file.translation.credit, contains('Saheeh International'));
    expect(file.translation.note.toLowerCase(), contains('licence'));
  });
}
