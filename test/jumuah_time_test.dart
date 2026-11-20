import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ar_rayaan/features/places/application/places_providers.dart';
import 'package:ar_rayaan/features/places/domain/jumuah_time.dart';
import 'package:ar_rayaan/features/places/presentation/jumuah_line.dart';

void main() {
  group('JumuahPolicy.validate', () {
    test('accepts real times', () {
      for (final String t in <String>[
        '1:30 PM',
        '13:30',
        '1pm',
        '1:00 PM and 2:00 PM',
        '12:45 PM, 1:45 PM',
      ]) {
        expect(JumuahPolicy.validate(t), isNull, reason: t);
      }
    });
    test('refuses empty, no clock time, too long and odd characters', () {
      expect(JumuahPolicy.validate('  '), isNotNull);
      expect(JumuahPolicy.validate('after zuhr'), isNotNull);
      expect(JumuahPolicy.validate('${'1:30 PM ' * 10}'), isNotNull);
      expect(JumuahPolicy.validate('1:30 PM <b>'), isNotNull);
      expect(JumuahPolicy.validate('25:99'), isNotNull);
    });
  });

  group('JumuahPolicy.fromServiceTimes', () {
    test('keeps only the Friday rules, as written', () {
      expect(JumuahPolicy.fromServiceTimes('Fr 13:15; Su 10:00'), 'Fr 13:15');
      expect(JumuahPolicy.fromServiceTimes('Fr 12:30; Fr 13:30'),
          'Fr 12:30; Fr 13:30');
    });
    test('null when there is no Friday time', () {
      expect(JumuahPolicy.fromServiceTimes(null), isNull);
      expect(JumuahPolicy.fromServiceTimes('Su 10:00'), isNull);
      expect(JumuahPolicy.fromServiceTimes('Fr'), isNull);
    });
  });

  test('newestByKey keeps the newest entry per masjid', () {
    final Map<String, JumuahEntry> m = JumuahPolicy.newestByKey(<JumuahEntry>[
      JumuahEntry(
          key: 'a', text: '1:00 PM', uid: 'u1', createdAt: DateTime(2026, 11, 1)),
      JumuahEntry(
          key: 'a', text: '1:30 PM', uid: 'u2', createdAt: DateTime(2026, 11, 8)),
      JumuahEntry(
          key: 'b', text: '2:00 PM', uid: 'u1', createdAt: DateTime(2026, 11, 2)),
    ]);
    expect(m['a']!.text, '1:30 PM');
    expect(m['b']!.text, '2:00 PM');
  });

  Future<void> pump(
    WidgetTester tester, {
    String? mapTime,
    Map<String, JumuahEntry> community = const <String, JumuahEntry>{},
    bool enabled = true,
  }) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        communityPlacesEnabledProvider.overrideWithValue(enabled),
        jumuahTimesProvider.overrideWith((ref) => Stream.value(community)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: JumuahLine(masjidKey: 'k', name: 'Test Masjid', mapTime: mapTime),
        ),
      ),
    ));
    await tester.pump();
  }

  testWidgets('no time: says not listed and offers Add time', (tester) async {
    await pump(tester);
    expect(find.byKey(const Key('jumuah-not-listed')), findsOneWidget);
    expect(find.byKey(const Key('jumuah-add')), findsOneWidget);
    expect(find.text('Add time'), findsOneWidget);
  });

  testWidgets('open-map time is shown with its source', (tester) async {
    await pump(tester, mapTime: 'Fr 13:15');
    expect(find.textContaining('Fr 13:15'), findsOneWidget);
    expect(find.textContaining('open map data'), findsOneWidget);
    expect(find.text('Update'), findsOneWidget);
  });

  testWidgets('a community time wins over the map time', (tester) async {
    await pump(tester, mapTime: 'Fr 13:15', community: <String, JumuahEntry>{
      'k': const JumuahEntry(key: 'k', text: '1:45 PM', uid: 'u'),
    });
    expect(find.textContaining('1:45 PM'), findsOneWidget);
    expect(find.textContaining('Fr 13:15'), findsNothing);
    expect(find.textContaining('community member'), findsOneWidget);
  });

  testWidgets('no add button when community features are off', (tester) async {
    await pump(tester, enabled: false);
    expect(find.byKey(const Key('jumuah-not-listed')), findsOneWidget);
    expect(find.byKey(const Key('jumuah-add')), findsNothing);
  });
}
