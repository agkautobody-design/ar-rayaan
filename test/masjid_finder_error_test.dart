import 'dart:async';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/masjid/presentation/masjid_finder_screen.dart';
import 'package:ar_rayaan/features/places/application/places_providers.dart';
import 'package:ar_rayaan/features/places/domain/community_place.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('the masjid finder still opens when the community streams fail',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          communityPlacesProvider.overrideWith(
            (ref) => Stream<List<CommunityPlace>>.error(
                StateError('permission-denied')),
          ),
          communityEventsProvider.overrideWith(
            (ref) => Stream<List<CommunityEvent>>.error(
                StateError('permission-denied')),
          ),
        ],
        child: const MaterialApp(home: MasjidFinderScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.text('Masajid'), findsWidgets);
  });
}
