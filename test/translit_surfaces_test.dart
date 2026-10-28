// Reading support on the content surfaces: the Dua school card, the hadith
// card, the Academy phrase step, and the guard that new screens do not print
// Arabic outside the shared block. No golden files.
import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/academy/domain/v3/phrase_resolver.dart';
import 'package:ar_rayaan/features/academy/presentation/dua_school_screen.dart';
import 'package:ar_rayaan/features/academy/presentation/v3/v3_widgets.dart';
import 'package:ar_rayaan/features/hadith/application/hadith_providers.dart';
import 'package:ar_rayaan/features/hadith/domain/hadith_models.dart';
import 'package:ar_rayaan/features/hadith/presentation/hadith_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  List<Override> overrides = const <Override>[],
  Map<String, Object> prefs = const <String, Object>{},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final SharedPreferences sp = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(430, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(sp),
        ...overrides,
      ],
      child: MaterialApp(theme: AppTheme.dark(), home: home),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('Dua school card', () {
    const DuaLesson withTl = DuaLesson(
      title: 'Before sleeping',
      arabic: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
      meaning: 'In Your name, O Allah, I die and I live.',
      when: 'At bedtime.',
      source: 'Bukhari 6314',
      translit: 'Bismika Allahumma amootu wa ahyaa',
      translitSource: 'Hisn 79 (sunnah.com/hisn:79)',
    );
    const DuaLesson noTl = DuaLesson(
      title: 'Before eating',
      arabic: 'بِسْمِ اللَّهِ',
      meaning: 'In the name of Allah.',
      when: 'Before a meal.',
      source: 'Muslim 2022',
    );

    testWidgets('shows Arabic, transliteration, then the labelled meaning',
        (WidgetTester tester) async {
      await _pump(
        tester,
        const DuaSchoolScreen(),
        overrides: <Override>[
          duaLessonsProvider.overrideWith(
            (Ref ref) async => <DuaLesson>[withTl, noTl],
          ),
        ],
      );
      expect(find.text(withTl.arabic), findsOneWidget);
      expect(find.text(withTl.translit!), findsOneWidget);
      expect(find.text('Meaning'), findsWidgets);
      expect(find.text(withTl.meaning), findsOneWidget);
      // The one with no transliteration of its own says so (never invents one).
      expect(find.byKey(const Key('arabic-block-missing')), findsWidgets);
    });

    testWidgets('Show transliteration and Show meaning switch them off',
        (WidgetTester tester) async {
      await _pump(
        tester,
        const DuaSchoolScreen(),
        prefs: <String, Object>{
          'ar.read.translit': false,
          'ar.read.meaning': false,
        },
        overrides: <Override>[
          duaLessonsProvider.overrideWith(
            (Ref ref) async => <DuaLesson>[withTl],
          ),
        ],
      );
      expect(find.text(withTl.arabic), findsOneWidget);
      expect(find.text(withTl.translit!), findsNothing);
      expect(find.text(withTl.meaning), findsNothing);
    });
  });

  group('Hadith card', () {
    const Hadith h = Hadith(
      number: 1,
      arabic: 'إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ',
      english: 'Deeds are only by intentions.',
      source: 'Bukhari & Muslim',
    );

    testWidgets('Arabic, an honest note for the missing transliteration, meaning',
        (WidgetTester tester) async {
      await _pump(
        tester,
        const HadithScreen(),
        overrides: <Override>[
          hadithCollectionProvider.overrideWith(
            (Ref ref) async => <Hadith>[h],
          ),
        ],
      );
      expect(find.byKey(const ValueKey<String>('hadith-block-1')), findsOneWidget);
      expect(find.text(h.arabic), findsOneWidget);
      expect(find.text('Transliteration not available yet'), findsOneWidget);
      expect(find.text(h.english), findsOneWidget);
    });
  });

  group('Academy phrase step', () {
    ResolvedPhrase phrase({bool review = true}) => ResolvedPhrase(
          ref: 'x',
          lines: <ResolvedLine>[
            ResolvedLine(
              arabic: 'سُبْحَانَ اللَّهِ',
              translit: 'Subhaanallah',
              translitReview: review,
              meaning: 'Glory be to Allah.',
            ),
            const ResolvedLine(
              arabic: 'الْحَمْدُ لِلَّهِ',
              meaning: 'All praise is for Allah.',
            ),
          ],
          verified: true,
          needsScholarReview: review,
          sources: const <String>[],
        );

    testWidgets('each line shows the three layers, with the review note',
        (WidgetTester tester) async {
      await _pump(tester, Scaffold(body: SingleChildScrollView(child: PhraseBlock(phrase: phrase()))));
      expect(find.text('سُبْحَانَ اللَّهِ'), findsOneWidget);
      expect(find.text('Subhaanallah'), findsOneWidget);
      expect(find.text('Glory be to Allah.'), findsOneWidget);
      expect(find.text('Scholar review needed'), findsWidgets);
      // The second line has no transliteration: the note, not an invented one.
      expect(find.byKey(const Key('arabic-block-missing')), findsOneWidget);
    });

    testWidgets('the settings apply to the step too', (WidgetTester tester) async {
      await _pump(
        tester,
        Scaffold(body: SingleChildScrollView(child: PhraseBlock(phrase: phrase()))),
        prefs: <String, Object>{'ar.read.translit': false, 'ar.read.meaning': false},
      );
      expect(find.text('سُبْحَانَ اللَّهِ'), findsOneWidget);
      expect(find.text('Subhaanallah'), findsNothing);
      expect(find.text('Glory be to Allah.'), findsNothing);
    });
  });

  group('guard', () {
    // Files that may draw Arabic in their own style, each for a stated reason.
    // A new file in lib that does this fails the test: use ArabicBlock.
    const Set<String> allowed = <String>{
      // Decorative school and tile names; the English title sits beside them.
      'academy_home_screen', 'aqeedah_school_screen', 'arabic_language_school_screen',
      'character_school_screen', 'dawah_school_screen', 'end_of_life_school_screen',
      'family_school_screen', 'hadith_school_screen', 'hajj_umrah_pack_screen',
      'health_school_screen', 'hisn_al_muslim_screen', 'history_school_screen',
      'qa_bank_screen', 'ramadan_mode_screen', 'seerah_school_screen',
      'stories_school_screen', 'transactions_school_screen',
      'understanding_school_screen', 'womens_school_screen', 'youth_school_screen',
      'calendar_screen', 'zakat_screen', 'hifz_surah_picker', 'quran_screen',
      'theme_demo_screen', 'hadith_screen',
      // Test faces: the Arabic is what is being tested (answers show the layers).
      'review_session_screen', 'wasia_lessons', 'games_extra', 'games_screens',
      'quiz_play_screen', 'v3_widgets', 'letters_school_screen', 'word_deck_screen',
      // Screens that lay the three layers out themselves.
      'adhkar_screen', 'story_reader_screen', 'huda_screens', 'surah_reader_screen',
      'mushaf_page_view', 'handout_screen',
      // The shared block.
      'arabic_block',
    };

    test('Arabic content goes through the shared block', () {
      final RegExp raw = RegExp(r"AppText\.arabic|fontFamily: *'Amiri'|AppFonts\.arabic");
      final List<String> bad = <String>[];
      for (final FileSystemEntity f
          in Directory('lib/features').listSync(recursive: true)) {
        if (f is! File || !f.path.endsWith('.dart')) continue;
        final String name = f.uri.pathSegments.last.replaceAll('.dart', '');
        if (allowed.contains(name)) continue;
        if (raw.hasMatch(f.readAsStringSync())) bad.add(f.path);
      }
      expect(bad, isEmpty,
          reason: 'These files draw Arabic in their own style. Use ArabicBlock '
              '(Arabic, transliteration, labelled meaning) or add them to the '
              'allowed list with a reason: $bad');
    });

    test('program-made transliteration is labelled and Latin only', () {
      final Map<String, dynamic> d = jsonDecode(
        File('assets/translit/generated.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(d['review'] as String, contains('Scholar review needed'));
      final Map<String, dynamic> m = d['map'] as Map<String, dynamic>;
      expect(m, isNotEmpty);
      m.forEach((String ar, dynamic e) {
        final String tl = (e as Map<String, dynamic>)['tl'] as String;
        expect(RegExp(r"^[A-Za-z\s',.\-]+$").hasMatch(tl), isTrue, reason: tl);
      });
    });

    test('the Dua school registry has Arabic and meaning for every lesson', () {
      final List<DuaLesson> ls = DuaLesson.parse(
        File('assets/academy/dua_lessons.json').readAsStringSync(),
      );
      expect(ls.length, 13);
      for (final DuaLesson l in ls) {
        expect(l.arabic.trim(), isNotEmpty);
        expect(l.meaning.trim(), isNotEmpty);
        if (l.translit != null) expect(l.translitSource, isNotNull, reason: l.title);
      }
    });
  });
}
