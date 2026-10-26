import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/elder/application/elder_mode.dart';
import 'package:ar_rayaan/features/habits/presentation/quiet_done.dart';
import 'package:ar_rayaan/features/quran/domain/quran_models.dart';
import 'package:ar_rayaan/features/quran/presentation/ayah_actions_sheet.dart';
import 'package:ar_rayaan/features/share/application/share_text.dart';
import 'package:ar_rayaan/features/share/presentation/share_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

String? _copied;

void _clipboard(WidgetTester tester) {
  final TestDefaultBinaryMessenger messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') {
      _copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
    }
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );
  _copied = null;
}

Future<void> pump(
  WidgetTester tester,
  Widget home, {
  Map<String, Object> prefs = const <String, Object>{},
  double scale = 1,
  Size size = const Size(390, 900),
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final SharedPreferences p = await SharedPreferences.getInstance();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[sharedPreferencesProvider.overrideWithValue(p)],
      child: MaterialApp(
        theme: AppTheme.dark(),
        builder: (BuildContext context, Widget? child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: home,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('share texts', () {
    test('invite: fixed link, no personal data, credit line', () {
      final String t = inviteShareText();
      expect(kInviteUrl, 'https://ar-rayaan.onrender.com');
      expect(t, contains(kInviteUrl));
      expect(t.trimRight(), endsWith(kSharedFromLine));
    });

    test('milestone: "I completed ..." with the link and credit', () {
      final String t = milestoneShareText('reading Surah Al-Fatihah');
      expect(t, contains('I completed reading Surah Al-Fatihah on Ar-Rayaan.'));
      expect(t, contains(kInviteUrl));
      expect(t.trimRight(), endsWith(kSharedFromLine));
    });

    test('come-back line carries a count and nothing else personal', () {
      final String t = comeBackShareText('the Qur’an', 7);
      expect(t, contains('I came back to the Qur’an for 7 days on Ar-Rayaan.'));
      expect(t, isNot(contains('prayer')));
    });

    test('an ayah names its reference, Arabic source and translation', () {
      const Ayah a = Ayah(number: 1, arabic: 'ٱلْحَمْدُ', english: 'Praise.');
      final String t = ayahShareText('Al-Fatihah', 1, a);
      expect(t, contains('— Al-Fatihah 1:1'));
      expect(t, contains('Tanzil'));
      expect(t, contains('Saheeh International'));
      expect(t, contains('Shared from Ar-Rayaan'));
    });
  });

  group('preview before share', () {
    testWidgets('shows exactly the text and sends nothing until asked', (
      tester,
    ) async {
      _clipboard(tester);
      await pump(
        tester,
        Scaffold(
          body: Builder(
            builder: (BuildContext c) => TextButton(
              onPressed: () => showSharePreview(c, text: 'hello world'),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await settle(tester);
      expect(
        tester
            .widget<SelectableText>(find.byKey(const Key('share-preview-text')))
            .data,
        'hello world',
      );
      expect(find.text(kSharePreviewNote), findsOneWidget);
      expect(_copied, isNull);
      await tester.tap(find.byKey(const Key('share-preview-cancel')));
      await settle(tester);
      expect(find.byKey(const Key('share-preview-text')), findsNothing);
      expect(_copied, isNull);
    });

    testWidgets('without a share sheet the button copies and says so', (
      tester,
    ) async {
      _clipboard(tester);
      await pump(
        tester,
        Scaffold(
          body: Builder(
            builder: (BuildContext c) => TextButton(
              onPressed: () => showSharePreview(c, text: 'hello world'),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await settle(tester);
      expect(find.text('Copy to share'), findsOneWidget);
      await tester.tap(find.byKey(const Key('share-preview-share')));
      await settle(tester);
      expect(_copied, 'hello world');
      expect(find.textContaining('Copied'), findsOneWidget);
    });

    testWidgets('the card button has a tooltip and opens the preview', (
      tester,
    ) async {
      await pump(
        tester,
        const Scaffold(
          body: Center(
            child: ShareCardButton(text: 'x', subject: 'this dhikr'),
          ),
        ),
      );
      expect(find.byTooltip('Preview and share this dhikr'), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const Key('share-card'))).shortestSide,
        greaterThanOrEqualTo(48),
      );
      await tester.tap(find.byKey(const Key('share-card')));
      await settle(tester);
      expect(find.byKey(const Key('share-preview-card')), findsOneWidget);
    });

    testWidgets('Elder Mode and 2.5x text keep buttons large, no overflow', (
      tester,
    ) async {
      await pump(
        tester,
        Scaffold(
          body: Builder(
            builder: (BuildContext c) => TextButton(
              onPressed: () => showSharePreview(c, text: 'a ' * 80),
              child: const Text('open'),
            ),
          ),
        ),
        prefs: <String, Object>{ElderMode.pref: true},
        scale: 2.5,
        size: const Size(320, 560),
      );
      await tester.tap(find.text('open'));
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byKey(const Key('share-preview-share'))).height,
        greaterThanOrEqualTo(64),
      );
    });
  });

  group('entry points', () {
    testWidgets('an ayah can be previewed and shared from its actions', (
      tester,
    ) async {
      const Ayah a = Ayah(number: 2, arabic: 'ٱلرَّحْمَٰنِ', english: 'Mercy.');
      await pump(
        tester,
        const Scaffold(
          body: AyahActionsSheet(surahName: 'Al-Fatihah', surah: 1, ayah: a),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Preview and share this ayah'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Preview and share this ayah'));
      await settle(tester);
      final String shown = tester
          .widget<SelectableText>(find.byKey(const Key('share-preview-text')))
          .data!;
      expect(shown, contains('— Al-Fatihah 1:2'));
      expect(shown, contains('Saheeh International'));
    });

    testWidgets('a completion card offers Share only when given a line', (
      tester,
    ) async {
      await pump(tester, const Scaffold(body: QuietDoneCard()));
      expect(find.byKey(const Key('quiet-done-share')), findsNothing);
      await pump(
        tester,
        Scaffold(
          body: QuietDoneCard(shareText: milestoneShareText('an adhkar set')),
        ),
      );
      await tester.tap(find.byKey(const Key('quiet-done-share')));
      await settle(tester);
      expect(
        tester
            .widget<SelectableText>(find.byKey(const Key('share-preview-text')))
            .data,
        contains('I completed an adhkar set on Ar-Rayaan.'),
      );
    });
  });
}
