import 'dart:io';

import 'package:ar_rayaan/features/majlis/domain/majlis_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('display names', () {
    test('ordinary names pass', () {
      for (final n in <String>[
        'Umm Yusuf',
        'Bilal K',
        'Guest of the Courtyard',
        'Hadiya',
        'Shadi',
        'Rayaan',
        'Amina',
      ]) {
        expect(MajlisPolicy.validateName(n), isNull, reason: n);
      }
    });

    test('reserved and look-alike names are refused', () {
      for (final n in <String>[
        'Ar-Rayaan',
        'ar rayaan',
        'AR_RAYAAN official',
        'ArRayaan',
        'Ar.Rayaan Team',
        'Hadi',
        'Hādi',
        'Sakina',
        'Admin',
        'adm1n',
        'Moderator',
        'Shaykh Ahmad',
        'Sheikh_Omar',
        'Imam Yusuf',
        'Mufti Sahib',
        'Dr Scholar',
        'Official Support',
      ]) {
        expect(MajlisPolicy.validateName(n), isNotNull, reason: n);
      }
    });

    test('length limits', () {
      expect(MajlisPolicy.validateName('A'), isNotNull);
      expect(MajlisPolicy.validateName('   '), isNotNull);
      expect(MajlisPolicy.validateName('x' * 31), isNotNull);
      expect(MajlisPolicy.validateName('x' * 30), isNull);
    });
  });

  group('content limits', () {
    test('title and body', () {
      expect(MajlisPolicy.validateTitle('abc'), isNotNull);
      expect(MajlisPolicy.validateTitle('A dua for my mother'), isNull);
      expect(MajlisPolicy.validateTitle('t' * 141), isNotNull);
      expect(MajlisPolicy.validateBody('  '), isNotNull);
      expect(MajlisPolicy.validateBody('Salaam'), isNull);
      expect(MajlisPolicy.validateBody('b' * 2001), isNotNull);
    });
  });

  group('rate limit', () {
    final now = DateTime(2026, 10, 20, 12);
    test('first post is allowed', () {
      expect(MajlisPolicy.waitBeforeNextPost(<DateTime>[], now), isNull);
    });
    test('too soon after the last post', () {
      final w = MajlisPolicy.waitBeforeNextPost(
          <DateTime>[now.subtract(const Duration(seconds: 5))], now);
      expect(w, isNotNull);
      expect(w!.inSeconds, greaterThan(15));
    });
    test('after the gap it is fine', () {
      expect(
        MajlisPolicy.waitBeforeNextPost(
            <DateTime>[now.subtract(const Duration(seconds: 60))], now),
        isNull,
      );
    });
    test('hourly cap', () {
      final many = <DateTime>[
        for (var i = 0; i < MajlisPolicy.maxPerHour; i++)
          now.subtract(Duration(minutes: 50 - i)),
      ];
      expect(MajlisPolicy.waitBeforeNextPost(many, now), isNotNull);
    });
  });

  group('report reasons', () {
    test('every reason has a label', () {
      for (final r in MajlisPolicy.reportReasons) {
        expect(MajlisPolicy.reportLabels[r], isNotNull);
      }
    });
  });

  group('firestore.rules', () {
    final rules = File('firestore.rules').readAsStringSync();
    test('Majlis writes use server time, not client time', () {
      expect(rules.contains('createdAt == request.time'), isTrue);
      expect(rules.contains('lastActivity == request.time'), isTrue);
      expect(rules.contains('createdAt is timestamp'), isFalse);
      expect(rules.contains('lastActivity is timestamp'), isFalse);
    });
    test('reports collection exists and cannot be read by clients', () {
      final i = rules.indexOf('match /majlis_reports/');
      expect(i, greaterThan(0));
      expect(rules.substring(i).contains('allow read: if false'), isTrue);
    });
    test('rate limiting and reserved names are enforced', () {
      expect(rules.contains('majlis_rate'), isTrue);
      expect(rules.contains('reservedName'), isTrue);
    });
    test('the app UI no longer claims an Adab Engine', () {
      final ui =
          File('lib/features/majlis/presentation/majlis_screens.dart')
              .readAsStringSync();
      expect(ui.contains('Adab Engine'), isFalse);
      expect(ui.contains('seedIfEmpty'), isFalse);
    });
  });
}
