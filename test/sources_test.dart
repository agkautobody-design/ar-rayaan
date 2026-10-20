import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/sources/presentation/sources_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Our Sources is honest about the Qur’an, hadith and guidance',
      (tester) async {
    tester.view.physicalSize = const Size(430, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const SourcesScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final Object? error = tester.takeException();
    expect(error, isNull, reason: '$error');
    // Qur'an layer: text, translation, recitation, with real attributions.
    expect(find.textContaining('Tanzil Uthmani'), findsWidgets);
    expect(find.textContaining('Saheeh International'), findsWidgets);
    expect(find.textContaining('Mahmoud Khalil Al-Husary'), findsWidgets);
    expect(find.textContaining('everyayah.com'), findsWidgets);

    // The six canonical collections (Founder-approved descriptions).
    expect(find.text('Sahih al-Bukhari'), findsOneWidget);
    expect(find.text('Sahih Muslim'), findsOneWidget);
    expect(find.text('Sunan Abu Dawood'), findsOneWidget);
    expect(find.text('Jami’ al-Tirmidhi'), findsOneWidget);
    expect(find.text('Sunan an-Nasa’i'), findsOneWidget);
    expect(find.text('Sunan Ibn Majah'), findsOneWidget);
    expect(find.textContaining('al-Bukhari (d. 870 CE)'), findsOneWidget);

    // Four of the six are Sunan, not all-sahih: the screen must not call
    // the whole set "authentic", and must say how grades are handled.
    expect(find.text('HADITH · THE SIX COLLECTIONS'), findsOneWidget);
    expect(find.textContaining('Authentic Six'), findsNothing);
    expect(find.textContaining('Only Bukhari and Muslim'), findsOneWidget);
    expect(find.textContaining('fawazahmed0'), findsOneWidget);

    // Knowledge & guidance (lazy list: scroll into view).
    await tester.scrollUntilVisible(
      find.text('Shaykh Muhammad Saqib Iqbal'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Shaykh Muhammad Saqib Iqbal'), findsOneWidget);

    // Adhkar credit.
    await tester.scrollUntilVisible(
      find.text('Adhkar · Hisn al-Muslim'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Adhkar · Hisn al-Muslim'), findsOneWidget);

    // Honest review status in the footer, never a bare claim.
    await tester.scrollUntilVisible(
      find.textContaining('NOT YET SCHOLAR-REVIEWED'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('NOT YET SCHOLAR-REVIEWED'), findsOneWidget);
  });
}
