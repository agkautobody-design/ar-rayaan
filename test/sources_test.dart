import 'package:ar_rayaan/app/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app() {
    return ProviderScope(
      child: MaterialApp.router(routerConfig: buildRouter()),
    );
  }

  testWidgets('Our Sources shows Qur’an, the Authentic Six, and guidance', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // Skip the splash (it auto-advances after 4s; tap to skip).
    await tester.tap(find.byType(GestureDetector).first);
    await tester.pumpAndSettle();

    // Navigate straight to /sources.
    final BuildContext ctx = tester.element(find.byType(Scaffold).first);
    GoRouter.of(ctx).go('/sources');
    await tester.pumpAndSettle();

    // Qur'an layer.
    expect(find.textContaining('Tanzil Uthmani'), findsOneWidget);
    expect(find.textContaining('Saheeh International'), findsOneWidget);
    expect(find.textContaining('Mishary Rashid Alafasy'), findsOneWidget);

    // The Authentic Six (Founder-approved).
    expect(find.text('Sahih al-Bukhari'), findsOneWidget);
    expect(find.text('Sahih Muslim'), findsOneWidget);
    expect(find.text('Sunan Abu Dawood'), findsOneWidget);
    expect(find.text('Jami’ al-Tirmidhi'), findsOneWidget);
    expect(find.text('Sunan an-Nasa’i'), findsOneWidget);
    expect(find.text('Sunan Ibn Majah'), findsOneWidget);
    expect(find.text('HADITH · THE AUTHENTIC SIX'), findsOneWidget);

    // Knowledge & guidance (scroll into view — the ListView builds lazily).
    await tester.scrollUntilVisible(
      find.text('Shaykh Muhammad Saqib Iqbal'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Shaykh Muhammad Saqib Iqbal'), findsOneWidget);

    // The Authentic Six appear nowhere with wrong attributions.
    expect(find.textContaining('al-Bukhari (d. 870 CE)'), findsOneWidget);
  });
}
