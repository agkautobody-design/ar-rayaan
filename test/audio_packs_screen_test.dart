import 'package:ar_rayaan/features/academy/presentation/audio_packs_screen.dart';
import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('AudioPacksScreen lists surahs and shows downloaded state',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: <Override>[
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const AudioPacksScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Audio Packs'), findsOneWidget);
    expect(find.text('Surah 1'), findsOneWidget);
    final ListView list = tester.widget<ListView>(find.byType(ListView).first);
    final delegate = list.childrenDelegate as SliverChildBuilderDelegate;
    expect(delegate.childCount, 114);
    expect(find.byIcon(Icons.download_for_offline_outlined), findsWidgets);
    expect(find.textContaining('Wi-Fi recommended'), findsOneWidget);
    container.dispose();
  });
}
