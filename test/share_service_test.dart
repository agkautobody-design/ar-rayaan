import 'package:ar_rayaan/app/core/scholar_review.dart';
import 'package:ar_rayaan/features/quran/domain/quran_models.dart';
import 'package:ar_rayaan/features/share/application/share_service.dart';
import 'package:ar_rayaan/features/share/application/share_text.dart';
import 'package:flutter_test/flutter_test.dart';

/// One example of every allowed kind, built the way the screens build them.
Map<ShareKind, ShareDoc> _samples() => <ShareKind, ShareDoc>{
      ShareKind.ayah: ShareDoc.ayah(
        surahName: 'Al-Fatihah',
        surah: 1,
        from: 2,
        arabic: 'ARABIC-FROM-REGISTRY',
      ),
      ShareKind.hadith: ShareDoc.hadith(
        title: 'Hadith 1',
        arabic: 'HADITH-ARABIC',
        english: 'Actions are by intentions.',
        source: 'Bukhari & Muslim',
        reviewKey: 'hadith.nawawi.01',
      ),
      ShareKind.dua: ShareDoc.dua(
        title: 'Before sleeping',
        arabic: 'DUA-ARABIC',
        meaning: 'In Your name, O Allah, I die and I live.',
        when: 'On going to bed.',
        source: 'Sahih al-Bukhari 6324',
        reviewKey: 'school.dua',
      ),
      ShareKind.dhikr: ShareDoc.dhikr(
        title: 'After prayer',
        arabic: 'DHIKR-ARABIC',
        translation: 'Glory be to Allah.',
        source: 'Sahih Muslim 597',
        reviewKey: 'dua.adhkar',
      ),
      ShareKind.story: ShareDoc.story(
        title: 'The Cave: The road',
        body: 'They left at night.',
        source: "Qur'an 9:40",
        reviewKey: 'story.prophets.prophet-nuh',
      ),
      ShareKind.treePerson: ShareDoc.treePerson(
        name: 'Ibrahim',
        era: 'The Two Rivers',
        label: 'Established',
        description: 'The friend of Allah.',
        lineage: 'Child of Azar',
        lineageNote: 'Named in the Qur’an.',
        sources: <String>["Qur'an 6:74"],
      ),
      ShareKind.lesson: ShareDoc.lesson(
        title: 'Names of Allah',
        body: 'Allah has beautiful names.',
        source: "Qur'an 7:180",
        reviewKey: 'lesson.path.u0.l1',
      ),
      ShareKind.calendarOccasion: ShareDoc.calendarOccasion(
        name: 'Day of Ashura',
        dateLine: '10 Muharram 1448 AH · 25 Jun 2026',
        basis: 'Established in the Qur’an and sunnah',
        about: 'The Prophet fasted it.',
        source: 'Sahih al-Bukhari 2004',
        reviewKey: 'calendar.observance.1-10',
      ),
      ShareKind.mosque: ShareDoc.mosque(
        name: 'Masjid Example',
        address: '12 Main St, Springfield,',
        lat: 21.4225,
        lon: 39.8262,
      ),
      ShareKind.halalPlace: ShareDoc.halalPlace(
        name: 'Example Grill',
        cuisine: 'turkish',
        address: 'High Street',
        lat: 51.5,
        lon: -0.12,
      ),
      ShareKind.guide: ShareDoc.guide(
        title: 'How to make wudu',
        subtitle: 'Step by step',
        steps: <String>['Intend.', 'Wash the hands.'],
        sources: <String>['Sahih al-Bukhari 159'],
        reviewKey: 'huda.guide.huda-wudu',
      ),
      ShareKind.invite: ShareDoc.invite(),
    };

/// Kinds whose text is religious teaching and so carries the review label.
const Set<ShareKind> _carriesLabel = <ShareKind>{
  ShareKind.hadith,
  ShareKind.dua,
  ShareKind.dhikr,
  ShareKind.story,
  ShareKind.treePerson,
  ShareKind.lesson,
  ShareKind.calendarOccasion,
  ShareKind.guide,
};

void main() {
  final Map<ShareKind, ShareDoc> samples = _samples();

  test('there is a sample for every allowed kind', () {
    expect(samples.keys.toSet(), ShareKind.values.toSet());
  });

  group('per-kind templates', () {
    test('ayah: Arabic from the registry, reference, credit, no translation',
        () {
      final String t = ShareService.build(samples[ShareKind.ayah]!);
      expect(t, startsWith('ARABIC-FROM-REGISTRY\n\n'));
      expect(t, contains('— Al-Fatihah 1:2'));
      expect(t, contains(kAyahArabicCredit));
      expect(t, isNot(contains('Translation')));
      expect(t, isNot(contains('Saheeh')));
      expect(t, isNot(contains(kScholarReviewNeeded)));
    });

    test('ayah range names the whole range', () {
      final ShareDoc d = ShareDoc.ayah(
        surahName: 'Al-Baqarah',
        surah: 2,
        from: 255,
        to: 256,
        arabic: 'x',
      );
      expect(ShareService.build(d), contains('— Al-Baqarah 2:255-256'));
    });

    test('ayahFromRegistry joins the registry Arabic and refuses bad refs',
        () {
      final List<Surah> all = <Surah>[
        const Surah(
          meta: SurahMeta(
            number: 1,
            arabicName: 'a',
            transliteration: 'Al-Fatihah',
            englishMeaning: 'The Opening',
            revelationType: 'meccan',
            ayahCount: 3,
          ),
          ayahs: <Ayah>[
            Ayah(number: 1, arabic: 'one', english: 'EN-ONE'),
            Ayah(number: 2, arabic: 'two', english: 'EN-TWO'),
            Ayah(number: 3, arabic: 'three', english: 'EN-THREE'),
          ],
        ),
      ];
      final ShareDoc d = ShareService.ayahFromRegistry(all, 1, 2, 3)!;
      final String t = ShareService.build(d);
      expect(t, contains('two three'));
      expect(t, contains('Al-Fatihah 1:2-3'));
      expect(t, isNot(contains('EN-')));
      expect(ShareService.ayahFromRegistry(all, 1, 4), isNull);
      expect(ShareService.ayahFromRegistry(all, 2, 1), isNull);
      expect(ShareService.ayahFromRegistry(all, 1, 3, 2), isNull);
    });

    test('hadith: title, Arabic, English, source, label', () {
      final String t = ShareService.build(samples[ShareKind.hadith]!);
      expect(t, contains('Hadith 1'));
      expect(t, contains('HADITH-ARABIC'));
      expect(t, contains('Actions are by intentions.'));
      expect(t, contains('— Bukhari & Muslim'));
      expect(t.indexOf('HADITH-ARABIC'),
          lessThan(t.indexOf('Actions are by intentions.')));
      expect(t.indexOf('— Bukhari'),
          lessThan(t.indexOf(kScholarReviewNeeded)));
    });

    test('dua: meaning, when, source, label', () {
      final String t = ShareService.build(samples[ShareKind.dua]!);
      expect(t, contains('DUA-ARABIC'));
      expect(t, contains('When: On going to bed.'));
      expect(t, contains('— Sahih al-Bukhari 6324'));
      expect(t, isNot(contains('pending scholar')));
      expect(t, contains(kScholarReviewNeeded));
    });

    test('dhikr: translation, source, label', () {
      final String t = ShareService.build(samples[ShareKind.dhikr]!);
      expect(t, contains('Glory be to Allah.'));
      expect(t, contains('— Sahih Muslim 597'));
      expect(t, contains(kScholarReviewNeeded));
    });

    test('story: text and sources, no image reference', () {
      final String t = ShareService.build(samples[ShareKind.story]!);
      expect(t, contains('They left at night.'));
      expect(t, contains("— Qur'an 9:40"));
      expect(t, isNot(contains('assets/')));
      expect(t, contains(kScholarReviewNeeded));
    });

    test('tree person: words only, with the label and how we know the link',
        () {
      final String t = ShareService.build(samples[ShareKind.treePerson]!);
      expect(t, contains('Ibrahim'));
      expect(t, contains('The Two Rivers · Established'));
      expect(t, contains('Child of Azar'));
      expect(t, contains('How we know this link: Named in the Qur’an.'));
      expect(t, isNot(contains('assets/')));
      expect(t, isNot(contains('.png')));
      expect(t, contains(kScholarReviewNeeded));
    });

    test('lesson: what it teaches, never that anyone finished it', () {
      final String t = ShareService.build(samples[ShareKind.lesson]!);
      expect(t, contains('Names of Allah'));
      expect(t, contains('Allah has beautiful names.'));
      expect(t.toLowerCase(), isNot(contains('completed')));
      expect(t.toLowerCase(), isNot(contains('finished')));
      expect(t, contains(kScholarReviewNeeded));
    });

    test('calendar occasion: name, date, basis, caveat, source', () {
      final String t = ShareService.build(samples[ShareKind.calendarOccasion]!);
      expect(t, contains('Day of Ashura'));
      expect(t, contains('10 Muharram 1448 AH'));
      expect(t, contains('confirm by local moon sighting'));
      expect(t, contains('— Sahih al-Bukhari 2004'));
      expect(t, contains(kScholarReviewNeeded));
      expect(t.toLowerCase(), isNot(contains('reminder')));
    });

    test('guide: numbered steps and sources', () {
      final String t = ShareService.build(samples[ShareKind.guide]!);
      expect(t, contains('1. Intend.'));
      expect(t, contains('2. Wash the hands.'));
      expect(t, contains('— Sahih al-Bukhari 159'));
      expect(t, contains(kScholarReviewNeeded));
    });

    test('invite: neutral, nothing personal', () {
      final String t = ShareService.build(samples[ShareKind.invite]!);
      expect(t, contains('Ar-Rayaan'));
      expect(t, contains('welcome to try it'));
      expect(t, isNot(contains(kScholarReviewNeeded)));
    });

    test('mosque: name, cleaned address, OSM link, attribution; nothing else',
        () {
      final String t = ShareService.build(samples[ShareKind.mosque]!);
      expect(t, contains('Masjid Example'));
      expect(t, contains('12 Main St, Springfield\n'));
      expect(t, isNot(contains('Springfield,')));
      expect(
        t,
        contains(
          'https://www.openstreetmap.org/?mlat=21.42250&mlon=39.82620'
          '#map=18/21.42250/39.82620',
        ),
      );
      expect(t, contains(kOsmAttribution));
      expect(t, contains('openstreetmap.org/copyright'));
      expect(t.toLowerCase(), isNot(contains(' km')));
      expect(t.toLowerCase(), isNot(contains('phone')));
      expect(t.toLowerCase(), isNot(contains('tel:')));
      expect(t, isNot(contains(kScholarReviewNeeded)));
    });

    test('a mosque without an address still shares name and link', () {
      final String t = ShareService.build(
        ShareDoc.mosque(name: 'Masjid', address: '  ,  ', lat: 1, lon: 2),
      );
      expect(t, startsWith('Masjid\n\nhttps://www.openstreetmap.org/'));
    });
  });

  group('halal wording', () {
    test('says tagged in community map data and confirm before eating', () {
      final String t = ShareService.build(samples[ShareKind.halalPlace]!);
      expect(t, contains('Tagged halal in community map data'));
      expect(t, contains('confirm before eating'));
      expect(t, contains(kOsmAttribution));
      expect(t, contains('https://www.openstreetmap.org/?mlat=51.50000'));
    });

    test('fully halal is still only "tagged"', () {
      final String t = ShareService.build(
        ShareDoc.halalPlace(
          name: 'R',
          lat: 1,
          lon: 2,
          fullyHalal: true,
        ),
      );
      expect(t, contains('Tagged fully halal in community map data'));
      expect(t, contains('confirm before eating'));
    });

    test('never claims a certificate or a bare halal claim', () {
      for (final bool only in <bool>[false, true]) {
        final String t = ShareService.build(
          ShareDoc.halalPlace(
            name: 'Place',
            cuisine: 'indian',
            address: 'Road',
            lat: 3,
            lon: 4,
            fullyHalal: only,
          ),
        ).toLowerCase();
        expect(t, isNot(contains('certified')));
        expect(t, isNot(contains('approved')));
        expect(t, isNot(contains('verified halal')));
        // Every mention of "halal" sits inside the tagged / community line.
        for (final RegExpMatch m in RegExp('halal').allMatches(t)) {
          final String around =
              t.substring(m.start < 14 ? 0 : m.start - 14, m.end);
          expect(around, contains('tagged'));
        }
        expect(t, isNot(contains(' km')));
        expect(t, isNot(contains('phone')));
      }
    });
  });

  group('scholar review label', () {
    test('travels with every religious kind, exactly the fixed wording', () {
      expect(kScholarReviewNeeded, 'Scholar review needed');
      for (final ShareKind k in _carriesLabel) {
        expect(
          ShareService.build(samples[k]!),
          contains('\n\nScholar review needed\n\n'),
          reason: '$k',
        );
      }
    });

    test('is absent from kinds that carry none', () {
      for (final ShareKind k in ShareKind.values) {
        if (_carriesLabel.contains(k)) continue;
        expect(
          ShareService.build(samples[k]!),
          isNot(contains(kScholarReviewNeeded)),
          reason: '$k',
        );
      }
    });

    test('becomes the named sign-off when one is recorded, not before', () {
      final Map<String, ScholarSignoff> ledger = <String, ScholarSignoff>{
        'hadith.nawawi': const ScholarSignoff(
          reviewedBy: 'Test Scholar',
          reviewedOn: '2026-10-01',
        ),
      };
      final String signed =
          ShareService.build(samples[ShareKind.hadith]!, ledger: ledger);
      expect(signed, contains('Reviewed by Test Scholar on 2026-10-01'));
      expect(signed, isNot(contains(kScholarReviewNeeded)));
      // A different hadith key is not covered by that entry.
      final String other =
          ShareService.build(samples[ShareKind.dua]!, ledger: ledger);
      expect(other, contains(kScholarReviewNeeded));
    });

    test('the hand-typed dua wording is gone', () {
      for (final ShareDoc d in samples.values) {
        expect(ShareService.build(d), isNot(contains('pending scholar')));
      }
    });
  });

  group('download line and link', () {
    test('every share ends with the credit, the download line and the link',
        () {
      for (final MapEntry<ShareKind, ShareDoc> e in samples.entries) {
        final String t = ShareService.build(e.value);
        expect(
          t,
          endsWith(
            'Shared from Ar-Rayaan\n'
            'Free to use, no account needed\n'
            'https://ar-rayaan.onrender.com',
          ),
          reason: '${e.key}',
        );
        expect(t, endsWith(kInviteUrl));
      }
    });

    test('the link appears once and carries no query, fragment or code', () {
      for (final ShareDoc d in samples.values) {
        final String t = ShareService.build(d);
        expect('ar-rayaan.onrender.com'.allMatches(t).length, 1);
        expect(t.trimRight().split('\n').last, 'https://ar-rayaan.onrender.com');
        expect(t.contains('${kInviteUrl}?'), isFalse);
        expect(t.contains('$kInviteUrl#'), isFalse);
        expect(t.contains('$kInviteUrl/'), isFalse);
        expect(t.toLowerCase(), isNot(contains('utm_')));
        expect(t.toLowerCase(), isNot(contains('ref=')));
        expect(t.toLowerCase(), isNot(contains('invite=')));
      }
    });

    test('promises no account', () {
      expect(kShareDownloadLine, 'Free to use, no account needed');
      for (final ShareDoc d in samples.values) {
        final String t = ShareService.build(d).toLowerCase();
        expect(t, isNot(contains('create an account')));
        expect(t, isNot(contains('sign up')));
        expect(t, isNot(contains('log in')));
      }
    });
  });

  group('nothing about the sender', () {
    test('no template says anyone did, finished or counted anything', () {
      for (final MapEntry<ShareKind, ShareDoc> e in samples.entries) {
        final String t = ShareService.build(e.value).toLowerCase();
        for (final String banned in <String>[
          'i completed',
          'i finished',
          'i memorised',
          'i memorized',
          'streak',
          'days in a row',
          'points',
          'my progress',
          'my notes',
          'percent',
          'you missed',
        ]) {
          expect(t, isNot(contains(banned)), reason: '${e.key}: $banned');
        }
      }
    });
  });
}
