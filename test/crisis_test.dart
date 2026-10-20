import 'package:ar_rayaan/features/sakina/domain/crisis_detector.dart';
import 'package:ar_rayaan/features/sakina/domain/sakina_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CrisisDetector: must catch', () {
    const List<String> selfHarm = <String>[
      'I want to kill myself',
      'i want to commit suicide',
      'I want to end my life',
      "I don't want to live anymore",
      'I dont want to live',
      'I wanna die',
      'I WANT TO DIEEEE',
      "life isn't worth living",
      'I am thinking about suicide',
      'I am going to hurt myself',
      'I cut myself last night',
      'there is no reason to live',
      'everyone would be better off without me',
      "I can't go on like this",
      'my life has no point, i want to die',
    ];
    for (final String t in selfHarm) {
      test('self-harm: "$t"', () {
        expect(CrisisDetector.detect(t), CrisisKind.selfHarm);
      });
    }

    const List<String> abuse = <String>[
      'my husband beats me',
      'my father hits me',
      'I am being beaten by my father',
      'my husband abuses me',
      'he hits me every night',
      'I am afraid of my husband',
    ];
    for (final String t in abuse) {
      test('abuse: "$t"', () {
        expect(CrisisDetector.detect(t), CrisisKind.abuse);
      });
    }

    test('a question about the ruling on suicide is handled gently', () {
      expect(
        CrisisDetector.detect(
          'can I pray janazah for someone who committed suicide',
        ),
        CrisisKind.suicideQuestion,
      );
      expect(
        CrisisDetector.detect('what does Islam say about suicide'),
        CrisisKind.suicideQuestion,
      );
    });

    test('shouting, spacing and punctuation do not hide it', () {
      expect(CrisisDetector.detect('I   WANT   TO   KILL   MYSELF!!!'),
          CrisisKind.selfHarm);
    });
  });

  group('CrisisDetector: must NOT fire', () {
    const List<String> fine = <String>[
      'I want to learn about the day of judgement',
      'How do I pray janazah?',
      'what is the ruling on a funeral prayer',
      'I am dying to see Makkah',
      'this homework is killing me',
      'I could die of embarrassment',
      "I can't go on Friday",
      'Tell me about death in Islam',
      'breakfast',
      'business',
      'what is the dua when someone dies',
      'I killed it at the exam',
      'how to pray',
      'I am tired of living in a flat',
      'my husband is very kind',
      'What is the virtue of Surah Al-Kahf?',
      'A du\'a for anxiety',
      '',
    ];
    for (final String t in fine) {
      test('"$t"', () {
        expect(CrisisDetector.detect(t), isNull);
      });
    }
  });

  group('CrisisDetector: the newer kinds', () {
    test('child safety', () {
      for (final String t in <String>[
        'a man online asked me to send nudes',
        'my uncle touches me and told me not to tell',
      ]) {
        expect(CrisisDetector.detect(t), CrisisKind.childSafety, reason: t);
      }
    });

    test('eating disorder', () {
      expect(CrisisDetector.detect('I have been starving myself for a week'),
          CrisisKind.eatingDisorder);
    });

    test('extremism', () {
      expect(CrisisDetector.detect('I want to join a terrorist group'),
          CrisisKind.extremism);
    });

    test('everyday sentences with the same words stay quiet', () {
      for (final String t in <String>[
        'my dad hits the gym every morning',
        'my dad beats me at chess',
        'I stopped eating sweets for Ramadan',
      ]) {
        expect(CrisisDetector.detect(t), isNull, reason: t);
      }
    });

    test('every kind has a follow-up that keeps help in view', () {
      for (final CrisisKind k in CrisisKind.values) {
        expect(CrisisResponses.followUpFor(k), isNotEmpty);
        expect(CrisisResponses.reminderFor(k), isNotEmpty);
      }
    });
  });

  group('CrisisResponses', () {
    test('every kind gives a reply with real help in it', () {
      for (final CrisisKind k in CrisisKind.values) {
        for (final String? cc in <String?>['US', 'GB', 'PK', null]) {
          final String text = CrisisResponses.textFor(k, countryCode: cc);
          expect(text, isNotEmpty);
          expect(RegExp(r'\d{3}').hasMatch(text) || text.contains('findahelpline'),
              isTrue,
              reason: '$k/$cc has no number or directory');
        }
      }
    });

    test('never points at a feature that does not exist', () {
      for (final CrisisKind k in CrisisKind.values) {
        final String t = CrisisResponses.textFor(k, countryCode: 'US');
        expect(t.contains('Prayer Times'), isFalse);
        expect(t.toLowerCase().contains('prayer times screen'), isFalse);
      }
    });

    test('US readers see 988; abuse readers see a domestic-violence line', () {
      expect(
        CrisisResponses.textFor(CrisisKind.selfHarm, countryCode: 'US'),
        contains('988'),
      );
      final List<HelpResource> abuse =
          CrisisResponses.resourcesFor(CrisisKind.abuse, 'US');
      expect(abuse.any((r) => r.kinds.contains(HelpKind.abuse)), isTrue);
    });

    test('self-harm replies are compassionate, not a lecture', () {
      final String t = CrisisResponses.textFor(CrisisKind.selfHarm);
      final String lower = t.toLowerCase();
      for (final String banned in <String>[
        'haram',
        'sinful',
        'you will be punished',
        'hellfire',
      ]) {
        expect(lower.contains(banned), isFalse, reason: banned);
      }
      expect(t, contains('39:53'));
    });
  });

  group('HelpResources', () {
    test('every row can be acted on and dials digits only', () {
      for (final HelpResource r in HelpResources.all) {
        expect(r.dial != null || r.url != null, isTrue, reason: r.name);
        if (r.dial != null) {
          expect(RegExp(r'^\d{2,11}$').hasMatch(r.dial!), isTrue,
              reason: '${r.name}: ${r.dial}');
        }
      }
    });

    test('a worldwide row never dials a single country\'s number', () {
      for (final HelpResource r in HelpResources.all) {
        if (r.countries.isNotEmpty || r.dial == null) continue;
        expect(<String>['911', '988', '999', '000'].contains(r.dial), isFalse,
            reason: '${r.name} is worldwide but dials ${r.dial}');
      }
    });

    test('local rows come before worldwide ones', () {
      final List<HelpResource> rows = HelpResources.forCountry('US');
      expect(rows.first.countries, contains('US'));
    });

    test('unknown country still returns help', () {
      expect(HelpResources.forCountry(null), isNotEmpty);
      expect(HelpResources.forCountry('ZZ'), isNotEmpty);
    });

    test('coverage includes the countries Muslims most often write from', () {
      expect(
        HelpResources.coveredCountries,
        containsAll(<String>['US', 'CA', 'GB', 'AU', 'PK', 'IN', 'BD']),
      );
    });
  });
}
