import 'package:ar_rayaan/features/academy/application/player_queue_provider.dart';
import 'package:ar_rayaan/features/academy/domain/player.dart';
import 'package:ar_rayaan/features/academy/presentation/player_screen.dart';
import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Player renders the shipped library',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(theme: AppTheme.dark(), home: const PlayerScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('The Ar-Rayaan Player'), findsOneWidget);
    expect(find.text('Nothing playing — choose a mix or a track.'),
        findsOneWidget);
    // The shipped library surfaces its language facets.
    expect(find.textContaining('Urdu'), findsWidgets);
  });
}
