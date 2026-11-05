import 'package:ar_rayaan/app/core/route_titles.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/auth/application/auth_providers.dart';
import 'package:ar_rayaan/features/auth/application/auth_repository.dart';
import 'package:ar_rayaan/features/places/application/places_providers.dart';
import 'package:ar_rayaan/features/places/domain/community_place.dart';
import 'package:ar_rayaan/features/places/presentation/add_place_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('route titles', () {
    test('the new routes have document titles', () {
      expect(RouteTitles.forPath('/places/add'), 'Add to the map · Ar-Rayaan');
      expect(RouteTitles.forPath('/places-admin'),
          'Community map moderation · Ar-Rayaan');
    });
  });

  group('PlacesPolicy.place validation', () {
    test('a name, a pin and nothing else is enough', () {
      expect(
        PlacesPolicy.validatePlace(name: 'Small Heath Masjid', lat: 52.4, lon: -1.8),
        isNull,
      );
    });

    test('name limits', () {
      expect(
        PlacesPolicy.validatePlace(name: ' ', lat: 52.4, lon: -1.8),
        isNotNull,
      );
      expect(
        PlacesPolicy.validatePlace(
            name: 'x' * 81, lat: 52.4, lon: -1.8),
        isNotNull,
      );
    });

    test('a pin is required and must be on the map', () {
      expect(PlacesPolicy.validatePlace(name: 'Masjid', lat: null, lon: null),
          isNotNull);
      expect(PlacesPolicy.validatePlace(name: 'Masjid', lat: 91, lon: 0),
          isNotNull);
      expect(PlacesPolicy.validatePlace(name: 'Masjid', lat: 0, lon: -181),
          isNotNull);
    });

    test('phone allows digits and punctuation only', () {
      expect(
        PlacesPolicy.validatePlace(
            name: 'Masjid', lat: 1, lon: 1, phone: '+44 121 555 0100'),
        isNull,
      );
      expect(
        PlacesPolicy.validatePlace(
            name: 'Masjid', lat: 1, lon: 1, phone: 'call me maybe'),
        isNotNull,
      );
    });

    test('websites must be http(s) links', () {
      expect(
        PlacesPolicy.validatePlace(
            name: 'Masjid', lat: 1, lon: 1, website: 'https://example.org'),
        isNull,
      );
      expect(
        PlacesPolicy.validatePlace(
            name: 'Masjid', lat: 1, lon: 1, website: 'example.org'),
        isNotNull,
      );
      expect(
        PlacesPolicy.validatePlace(
            name: 'Masjid', lat: 1, lon: 1, website: 'javascript:alert(1)'),
        isNotNull,
      );
    });
  });

  group('PlacesPolicy.event validation', () {
    final DateTime now = DateTime(2026, 11, 6, 12);
    test('a valid event passes', () {
      expect(
        PlacesPolicy.validateEvent(
          title: 'Community iftar',
          where: 'Small Heath Masjid',
          lat: 52.4,
          lon: -1.8,
          startsAt: now.add(const Duration(days: 3)),
          now: now,
        ),
        isNull,
      );
    });

    test('title and where are required', () {
      expect(
        PlacesPolicy.validateEvent(
            title: 'iftar', where: ' ', lat: 1, lon: 1,
            startsAt: now.add(const Duration(days: 1)), now: now),
        isNotNull,
      );
    });

    test('the start may not be long past nor over a year ahead', () {
      expect(
        PlacesPolicy.validateEvent(
            title: 'Community iftar', where: 'Masjid', lat: 1, lon: 1,
            startsAt: now.subtract(const Duration(days: 2)), now: now),
        isNotNull,
      );
      expect(
        PlacesPolicy.validateEvent(
            title: 'Community iftar', where: 'Masjid', lat: 1, lon: 1,
            startsAt: now.add(const Duration(days: 400)), now: now),
        isNotNull,
      );
      // Started an hour ago: still fine (people join late).
      expect(
        PlacesPolicy.validateEvent(
            title: 'Community iftar', where: 'Masjid', lat: 1, lon: 1,
            startsAt: now.subtract(const Duration(hours: 1)), now: now),
        isNull,
      );
    });
  });

  group('PlacesPolicy visibility', () {
    CommunityPlace place({
      bool hidden = false,
      int confirms = 0,
      int flags = 0,
    }) =>
        CommunityPlace(
          id: 'p',
          type: CommunityPlaceType.mosque,
          name: 'Masjid',
          lat: 52.4,
          lon: -1.8,
          uid: 'u',
          hidden: hidden,
          confirms: confirms,
          flags: flags,
        );

    test('hidden places never show', () {
      expect(PlacesPolicy.visible(place(hidden: true)), isFalse);
    });

    test('three more flags than confirms drops a place on its own', () {
      expect(PlacesPolicy.visible(place(flags: 3)), isFalse);
      expect(PlacesPolicy.visible(place(flags: 2)), isTrue);
      expect(PlacesPolicy.visible(place(flags: 5, confirms: 3)), isFalse);
      expect(PlacesPolicy.visible(place(flags: 5, confirms: 5)), isTrue);
      expect(PlacesPolicy.visible(place(flags: 6, confirms: 3)), isFalse);
    });

    test('events show until a day after they start', () {
      final DateTime now = DateTime(2026, 11, 6, 12);
      CommunityEvent ev(DateTime start, {bool hidden = false}) =>
          CommunityEvent(
            id: 'e',
            title: 'Iftar',
            where: 'Masjid',
            lat: 1,
            lon: 1,
            startsAt: start,
            uid: 'u',
            hidden: hidden,
          );
      expect(
          PlacesPolicy.eventVisible(
              ev(now.subtract(const Duration(hours: 23))),
              now: now),
          isTrue);
      expect(
          PlacesPolicy.eventVisible(
              ev(now.subtract(const Duration(days: 2))),
              now: now),
          isFalse);
      expect(
          PlacesPolicy.eventVisible(ev(now.add(const Duration(days: 1)),
              hidden: true), now: now),
          isFalse);
    });
  });

  group('PlacesPolicy nearby and upcoming', () {
    final List<CommunityPlace> places = <CommunityPlace>[
      const CommunityPlace(
          id: 'near',
          type: CommunityPlaceType.mosque,
          name: 'Near',
          lat: 52.41,
          lon: -1.81,
          uid: 'u'),
      const CommunityPlace(
          id: 'far',
          type: CommunityPlaceType.mosque,
          name: 'Far',
          lat: 53.4,
          lon: -1.8,
          uid: 'u'),
      const CommunityPlace(
          id: 'food',
          type: CommunityPlaceType.halalFood,
          name: 'Food',
          lat: 52.41,
          lon: -1.81,
          uid: 'u'),
    ];

    test('nearby filters by type and radius and sorts nearest first', () {
      final List<CommunityPlace> out = PlacesPolicy.nearby(
        places,
        type: CommunityPlaceType.mosque,
        lat: 52.4,
        lon: -1.8,
      );
      expect(out.map((p) => p.id), <String>['near']);
    });

    test('upcoming filters by radius only when a place is set', () {
      final DateTime now = DateTime(2026, 11, 6, 12);
      final List<CommunityEvent> events = <CommunityEvent>[
        CommunityEvent(
            id: 'later',
            title: 'Later',
            where: 'Here',
            lat: 52.41,
            lon: -1.81,
            startsAt: now.add(const Duration(days: 5)),
            uid: 'u'),
        CommunityEvent(
            id: 'sooner',
            title: 'Sooner',
            where: 'Here',
            lat: 52.41,
            lon: -1.81,
            startsAt: now.add(const Duration(days: 1)),
            uid: 'u'),
        CommunityEvent(
            id: 'far',
            title: 'Far away',
            where: 'There',
            lat: 40.0,
            lon: -3.0,
            startsAt: now.add(const Duration(days: 1)),
            uid: 'u'),
      ];
      expect(
        PlacesPolicy.upcoming(events, now: now).map((e) => e.id),
        <String>['sooner', 'far', 'later'],
      );
      expect(
        PlacesPolicy.upcoming(events, lat: 52.4, lon: -1.8, now: now)
            .map((e) => e.id),
        <String>['sooner', 'later'],
      );
    });
  });

  group('PlacesPolicy write pacing', () {
    final DateTime now = DateTime(2026, 11, 6, 12);
    test('a write right after another must wait', () {
      final Duration? wait = PlacesPolicy.waitBeforeNextWrite(
          <DateTime>[now.subtract(const Duration(seconds: 10))], now);
      expect(wait, isNotNull);
    });
    test('after the gap, writing is allowed', () {
      expect(
        PlacesPolicy.waitBeforeNextWrite(
            <DateTime>[now.subtract(const Duration(minutes: 5))], now),
        isNull,
      );
    });
    test('the hourly cap holds', () {
      final List<DateTime> recent = List<DateTime>.generate(
        PlacesPolicy.maxPerHour,
        (i) => now.subtract(Duration(minutes: 10 + i)),
      );
      expect(PlacesPolicy.waitBeforeNextWrite(recent, now), isNotNull);
    });
  });

  group('PlacesPolicy.osmTargetId', () {
    test('is doc-id safe, stable and bounded', () {
      final String id = PlacesPolicy.osmTargetId(
          'Masjid Al-Rahman & Community Centre (Birmingham!)', 52.4862, -1.8567);
      expect(id, PlacesPolicy.osmTargetId(
          'Masjid Al-Rahman & Community Centre (Birmingham!)', 52.4862, -1.8567));
      expect(id.contains('/'), isFalse);
      expect(id.length, lessThanOrEqualTo(120));
      expect(id.startsWith('osm-'), isTrue);
    });
  });

  group('AddPlaceScreen', () {
    Future<void> pump(
      WidgetTester tester, {
      required bool enabled,
      AuthUser? user,
    }) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            communityPlacesEnabledProvider.overrideWithValue(enabled),
            authStateProvider.overrideWith(
                (ref) => Stream<AuthUser?>.value(user)),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const AddPlaceScreen(lat: 52.4, lon: -1.8),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
    }

    testWidgets('without the cloud, says so instead of a form', (tester) async {
      await pump(tester, enabled: false);
      expect(tester.takeException(), isNull);
      expect(find.textContaining('cloud'), findsOneWidget);
      expect(find.byKey(const Key('add-place-submit')), findsNothing);
    });

    testWidgets('signed-out people are asked to sign in', (tester) async {
      await pump(tester, enabled: true);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('add-place-signin')), findsOneWidget);
      expect(find.byKey(const Key('add-place-submit')), findsNothing);
    });

    testWidgets('signed-in people get the form with the pin from the map',
        (tester) async {
      await pump(
        tester,
        enabled: true,
        user: const AuthUser(uid: 'u1', email: 'a@b.c'),
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('add-place-name')), findsOneWidget);
      expect(find.byKey(const Key('add-place-submit')), findsOneWidget);
      expect(find.textContaining('52.4000'), findsOneWidget);
    });
  });
}
