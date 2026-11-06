import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/calendar/application/hijri_settings.dart';
import 'package:ar_rayaan/features/calendar/application/moon_sighting_settings.dart';
import 'package:ar_rayaan/features/calendar/domain/hijri_date.dart';
import 'package:ar_rayaan/features/calendar/domain/moon_sighting.dart';
import 'package:ar_rayaan/features/calendar/presentation/calendar_screen.dart';
import 'package:ar_rayaan/features/majlis/domain/countries.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('moon sighting choice', () {
    test('labels and hints exist for every convention', () {
      for (final SightingConvention c in SightingConvention.values) {
        expect(sightingConventionLabel(c), isNotEmpty);
        expect(sightingConventionHint(c), isNotEmpty);
      }
      expect(sightingConventionLabel(SightingConvention.localSighting),
          'Local moon sighting');
      expect(sightingConventionLabel(SightingConvention.saudi),
          'Saudi announcement');
      expect(sightingConventionLabel(SightingConvention.calculated),
          'Astronomical criteria');
    });

    test('the calendar effect matches the convention', () {
      expect(
        const MoonSightingChoice(
                countryCode: 'MA',
                convention: SightingConvention.localSighting)
            .hijriEffect
            .adjustDays,
        1,
      );
      expect(
        const MoonSightingChoice(
                countryCode: 'SA', convention: SightingConvention.saudi)
            .hijriEffect
            .adjustDays,
        0,
      );
      expect(
        const MoonSightingChoice(
                countryCode: 'US',
                convention: SightingConvention.calculated)
            .hijriEffect
            .adjustDays,
        0,
      );
      // Every effect uses the Umm al-Qura table as its base.
      for (final SightingConvention c in SightingConvention.values) {
        expect(
          MoonSightingChoice(countryCode: 'SA', convention: c)
              .hijriEffect
              .basis,
          HijriBasis.ummAlQura,
        );
      }
    });

    test('national pre-fills are real countries, split ones absent', () {
      for (final String cc in kNationalConvention.keys) {
        expect(kCountries.containsKey(cc), isTrue, reason: cc);
      }
      // Communities in these countries are split between conventions, so
      // the app must not pre-decide for them.
      for (final String cc in <String>['GB', 'DE', 'FR', 'NL', 'AU']) {
        expect(kNationalConvention.containsKey(cc), isFalse, reason: cc);
      }
    });

    test('save and load round-trips through device storage', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const MoonSightingChoice choice = MoonSightingChoice(
        countryCode: 'PK',
        convention: SightingConvention.localSighting,
      );
      await choice.save();
      final MoonSightingChoice? loaded = await MoonSightingChoice.load();
      expect(loaded, isNotNull);
      expect(loaded!.countryCode, 'PK');
      expect(loaded.convention, SightingConvention.localSighting);
      expect(loaded.label, 'Pakistan · Local moon sighting');
    });

    test('load refuses a country that is not on the list', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'ar.moon.country': 'XX',
        'ar.moon.convention': 'saudi',
      });
      expect(await MoonSightingChoice.load(), isNull);
    });

    test('load refuses an unknown convention word', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'ar.moon.country': 'MA',
        'ar.moon.convention': 'whatever',
      });
      expect(await MoonSightingChoice.load(), isNull);
    });

    test('clearing removes the saved choice', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const MoonSightingChoice choice = MoonSightingChoice(
        countryCode: 'TR',
        convention: SightingConvention.calculated,
      );
      await choice.save();
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      await container
          .read(moonSightingProvider.notifier)
          .setChoice(choice);
      expect(container.read(moonSightingProvider), isNotNull);
      await container.read(moonSightingProvider.notifier).clear();
      expect(container.read(moonSightingProvider), isNull);
      expect(await MoonSightingChoice.load(), isNull);
    });
  });

  group('calendar moon sighting sheet', () {
    Future<void> openCalendar(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(430, 3600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(home: CalendarScreen()),
        ),
      );
      await tester.pump();
    }

    testWidgets('unset state offers to set a country', (tester) async {
      await openCalendar(tester);
      await tester.pumpAndSettle();
      expect(
        find.text('Moon sighting: set your country'),
        findsOneWidget,
      );
    });

    testWidgets('choosing Morocco pre-fills local sighting and applies it',
        (tester) async {
      await openCalendar(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('moon-sighting-change')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('moon-country')), findsOneWidget);
      await tester.tap(find.byKey(const Key('moon-country')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Morocco').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('moon-sighting-save')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Morocco · Local moon sighting'),
        findsOneWidget,
      );
      // The +1 day shift of local sighting reaches the Hijri settings.
      final ProviderContainer container =
          ProviderScope.containerOf(tester.element(find.byType(CalendarScreen)));
      expect(container.read(hijriSettingsProvider).adjustDays, 1);
    });
  });
}
