import 'dart:io';

import 'package:ar_rayaan/app/core/modules/module_status.dart';
import 'package:ar_rayaan/features/majlis/domain/countries.dart';
import 'package:ar_rayaan/features/majlis/domain/region.dart';
import 'package:ar_rayaan/features/majlis/presentation/majlis_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The regional-room contract: the slug the app builds, the pattern the
/// Firestore rules accept, and the picker's behaviour. The rules pattern is
/// mirrored here on purpose — drift between them fails loudly.
void main() {
  const String rulesPattern =
      r'^region-[a-z]{2}-[a-z0-9][a-z0-9-]{0,38}[a-z0-9]$';

  group('slugify', () {
    test('plain, spaced and accented areas become slugs', () {
      expect(slugify('Birmingham'), 'birmingham');
      expect(slugify('New York'), 'new-york');
      expect(slugify('São Paulo'), 'sao-paulo');
      expect(slugify('Straßburg'), 'strassburg');
      expect(slugify('  Dubai  '), 'dubai');
      expect(slugify('Köln'), 'koln');
      expect(slugify("Dar es Salaam"), 'dar-es-salaam');
    });

    test('junk becomes null, never a broken room', () {
      expect(slugify(''), isNull);
      expect(slugify('a'), isNull);
      expect(slugify('!!@@##'), isNull);
      expect(slugify('--'), isNull);
    });

    test('very long areas are capped at 40 characters', () {
      final String? s = slugify('a' * 60);
      expect(s, isNotNull);
      expect(s!.length, 40);
    });
  });

  group('room keys and the rules pattern', () {
    test('the rules file carries the mirrored pattern', () {
      final String rules = File('firestore.rules').readAsStringSync();
      expect(rules, contains("room.matches('$rulesPattern')"));
      expect(rules, contains("room == 'courtyard'"));
      expect(rules,
          contains("room in ['ask-a-scholar', 'ask-a-professional']"));
    });

    test('rules gate ask-room replies and hold helper roles', () {
      final String rules = File('firestore.rules').readAsStringSync();
      expect(rules, contains('function helperCanAnswer(room)'));
      expect(rules, contains('helperCanAnswer(room)'));
      expect(rules, contains('match /helper_roles/{uid}'));
      expect(rules, contains("get(r).data.role == 'scholar'"));
      expect(rules,
          contains("in ['doctor', 'counsellor', 'professional']"));
      // The reply gate names both ask rooms in the posts create rule.
      final int gate = rules.indexOf('helperCanAnswer(room))');
      final int postCreate = rules.lastIndexOf('allow create: if signedIn()', gate);
      expect(postCreate, greaterThan(-1));
      expect(postCreate, greaterThan(gate - 1200));
    });

    test('the Dart pattern is the same pattern', () {
      expect(roomKeyPattern.pattern, rulesPattern);
    });

    test('built room keys always satisfy the pattern', () {
      final RegExp rx = RegExp(rulesPattern);
      for (final (String cc, String area) in <(String, String)>[
        ('GB', 'Birmingham'),
        ('US', 'New York'),
        ('AE', 'Dubai'),
        ('PK', 'Lahore'),
        ('CA', 'Ontario'),
        ('BR', 'São Paulo'),
        ('ID', 'West Java'),
      ]) {
        final RegionSetting r = RegionSetting(countryCode: cc, area: area);
        expect(r.isValid, isTrue, reason: '$cc/$area');
        expect(rx.hasMatch(r.roomKey), isTrue, reason: r.roomKey);
        expect(roomKeyPattern.hasMatch(r.roomKey), isTrue, reason: r.roomKey);
      }
      expect(RegionSetting(countryCode: 'GB', area: 'Birmingham').roomKey,
          'region-gb-birmingham');
    });

    test('roomKeyOrNull accepts only real rooms', () {
      expect(roomKeyOrNull('courtyard'), 'courtyard');
      expect(roomKeyOrNull('ask-a-scholar'), 'ask-a-scholar');
      expect(roomKeyOrNull('ask-a-professional'), 'ask-a-professional');
      expect(roomKeyOrNull('region-gb-birmingham'), 'region-gb-birmingham');
      expect(roomKeyOrNull(null), isNull);
      expect(roomKeyOrNull(''), isNull);
      expect(roomKeyOrNull('region-GB-birmingham'), isNull); // case
      expect(roomKeyOrNull('region-gb-'), isNull);
      expect(roomKeyOrNull('region-gb-x'), isNull); // slug too short
      expect(roomKeyOrNull('evil'), isNull);
      expect(roomKeyOrNull('courtyard2'), isNull);
      expect(roomKeyOrNull('region-gb-b' * 30), isNull); // too long
    });
  });

  group('countries', () {
    test('codes are ISO alpha-2 and the big communities are present', () {
      for (final MapEntry<String, String> e in kCountries.entries) {
        expect(e.key, matches(RegExp(r'^[A-Z]{2}$')));
        expect(e.value.isNotEmpty, isTrue);
      }
      for (final String cc in <String>[
        'GB', 'US', 'CA', 'PK', 'IN', 'BD', 'SA', 'AE', 'ID', 'MY', 'TR',
        'EG', 'NG', 'FR', 'DE', 'AU',
      ]) {
        expect(kCountries.containsKey(cc), isTrue, reason: cc);
      }
    });

    test('names and aliases resolve to codes', () {
      expect(countryCodeForName('United Kingdom'), 'GB');
      expect(countryCodeForName('uk'), 'GB');
      expect(countryCodeForName('USA'), 'US');
      expect(countryCodeForName('UAE'), 'AE');
      expect(countryCodeForName('Turkey'), 'TR');
      expect(countryCodeForName('canada'), 'CA');
      expect(countryCodeForName('Atlantis'), isNull);
      expect(countryCodeForName(''), isNull);
    });
  });

  group('RegionSetting on the device', () {
    test('save and load round-trip', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const RegionSetting r =
          RegionSetting(countryCode: 'GB', area: 'Birmingham');
      await r.save();
      final RegionSetting? back = await RegionSetting.load();
      expect(back, isNotNull);
      expect(back!.roomKey, 'region-gb-birmingham');
      expect(back.label, 'Birmingham, United Kingdom');
    });

    test('nothing stored or junk stored loads as null', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      expect(await RegionSetting.load(), isNull);
      SharedPreferences.setMockInitialValues(<String, Object>{
        RegionSetting.countryKey: 'GB',
        RegionSetting.areaKey: '!!',
      });
      expect(await RegionSetting.load(), isNull);
    });
  });

  group('screens without a community server', () {
    Widget host(Widget child, String status) => ProviderScope(
          overrides: [
            moduleRegistryProvider.overrideWith(
              (Ref ref) async => ModuleStatusService(<String, dynamic>{
                'modules': <dynamic>[
                  <String, dynamic>{'id': 'majlis', 'status': status},
                ],
              }),
            ),
          ],
          child: MaterialApp(home: child),
        );

    testWidgets('live module but no Firebase: an honest card, no form fields',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.pumpWidget(host(const MajlisScreen(), 'live'));
      await tester.pumpAndSettle();
      expect(find.textContaining('not connected'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('New thread'), findsNothing);
    });

    testWidgets('thread and new-thread screens also stay safe', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.pumpWidget(
          host(const ThreadScreen(threadId: 'x', title: 'T'), 'live'));
      await tester.pumpAndSettle();
      expect(find.textContaining('not connected'), findsOneWidget);
      await tester.pumpWidget(host(const NewThreadScreen(), 'live'));
      await tester.pumpAndSettle();
      expect(find.textContaining('not connected'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });
  });

  group('RegionSheet', () {
    Future<void> openSheet(
      WidgetTester tester,
      void Function(RegionSetting?) onDone,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (BuildContext ctx) => ElevatedButton(
              onPressed: () async => onDone(await showRegionSheet(ctx)),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('refuses to save without a country', (WidgetTester tester) async {
      await openSheet(tester, (_) {});
      await tester.enterText(find.byKey(const Key('region-area')), 'Toronto');
      await tester.tap(find.byKey(const Key('region-save')));
      await tester.pumpAndSettle();
      expect(find.textContaining('choose your country'), findsOneWidget);
    });

    testWidgets('country + area pop a valid RegionSetting',
        (WidgetTester tester) async {
      RegionSetting? got;
      await openSheet(tester, (RegionSetting? r) => got = r);
      await tester.tap(find.byKey(const Key('region-country')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Albania').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('region-area')), 'Toronto');
      await tester.tap(find.byKey(const Key('region-save')));
      await tester.pumpAndSettle();
      expect(got, isNotNull);
      expect(got!.countryCode, 'AL');
      expect(got!.roomKey, 'region-al-toronto');
    });
  });
}
