import 'package:ar_rayaan/app/core/child_mode.dart';
import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/elder/application/elder_mode.dart';
import 'package:ar_rayaan/features/habits/presentation/quiet_done.dart';
import 'package:ar_rayaan/features/quran/domain/quran_models.dart';
import 'package:ar_rayaan/features/quran/presentation/ayah_actions_sheet.dart';
import 'package:ar_rayaan/features/share/application/share_service.dart';
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

  Widget openButton(ShareDoc doc) => Scaffold(
        body: Builder(
          builder: (BuildContext c) => TextButton(
            onPressed: () => showSharePreview(c, doc: doc),
            child: const Text('open'),
          ),
        ),
      );

  group('share texts', () {
    test('invite: fixed link, no personal data, credit and download line', () {
      final String t = ShareService.inviteText();
      expect(kInviteUrl, 'https://ar-rayaan.onrender.com');
      expect(t, contains(kInviteUrl));
      expect(t, contains('Free to use, no account needed'));
      expect(t.trimRight(), endsWith(kInviteUrl));
    });

    test('an ayah shares its Arabic and reference, never the translation', () {
      final ShareDoc d = ShareDoc.ayah(
        surahName: 'Al-Fatihah',
        surah: 1,
        from: 1,
        arabic: 'ٱلْحَمْدُ',
      );
      final String t = ShareService.build(d);
      expect(t, contains('ٱلْحَمْدُ'));
      expect(t, contains('— Al-Fatihah 1:1'));
      expect(t, contains('Tanzil'));
      expect(t, isNot(contains('Saheeh')));
      expect(t, contains('Shared from Ar-Rayaan'));
    });
  });

  group('preview before share', () {
    testWidgets('shows exactly the text and sends nothing until asked', (
      tester,
    ) async {
      _clipboard(tester);
      final ShareDoc doc = ShareDoc.invite();
      await pump(tester, openButton(doc));
      await tester.tap(find.text('open'));
      await settle(tester);
      expect(
        tester
            .widget<SelectableText>(find.byKey(const Key('share-preview-text')))
            .data,
        ShareService.build(doc),
      );
      expect(find.text(kSharePreviewNote), findsOneWidget);
      expect(_copied, isNull);
      await tester.tap(find.byKey(const Key('share-preview-cancel')));
      await settle(tester);
      expect(find.byKey(const Key('share-preview-text')), findsNothing);
      expect(_copied, isNull);
    });

    testWidgets('Copy in the preview copies the exact text and says so', (
      tester,
    ) async {
      _clipboard(tester);
      final ShareDoc doc = ShareDoc.invite();
      await pump(tester, openButton(doc));
      await tester.tap(find.text('open'));
      await settle(tester);
      await tester.tap(find.byKey(const Key('share-preview-copy')));
      await settle(tester);
      expect(_copied, ShareService.build(doc));
      expect(find.textContaining('Copied'), findsOneWidget);
    });

    testWidgets('Share falls back to copying when the system sheet fails', (
      tester,
    ) async {
      _clipboard(tester);
      final Future<bool> Function(String, String?) saved =
          ShareService.nativeShare;
      ShareService.nativeShare = (String text, String? subject) async => false;
      addTearDown(() => ShareService.nativeShare = saved);
      final ShareDoc doc = ShareDoc.invite();
      await pump(tester, openButton(doc));
      await tester.tap(find.text('open'));
      await settle(tester);
      await tester.tap(find.byKey(const Key('share-preview-share')));
      await settle(tester);
      expect(_copied, ShareService.build(doc));
      expect(find.textContaining('Copied'), findsOneWidget);
    });

    testWidgets('Share hands the exact text to the system sheet', (
      tester,
    ) async {
      _clipboard(tester);
      String? sent;
      final Future<bool> Function(String, String?) saved =
          ShareService.nativeShare;
      ShareService.nativeShare = (String text, String? subject) async {
        sent = text;
        return true;
      };
      addTearDown(() => ShareService.nativeShare = saved);
      final ShareDoc doc = ShareDoc.invite();
      await pump(tester, openButton(doc));
      await tester.tap(find.text('open'));
      await settle(tester);
      await tester.tap(find.byKey(const Key('share-preview-share')));
      await settle(tester);
      expect(sent, ShareService.build(doc));
      expect(_copied, isNull);
    });

    testWidgets('the share button has a tooltip and opens the preview', (
      tester,
    ) async {
      await pump(
        tester,
        Scaffold(
          body: Center(
            child: ShareButton(doc: ShareDoc.invite(), subject: 'this dhikr'),
          ),
        ),
      );
      expect(find.byTooltip('Share this dhikr'), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const Key('share-card'))).shortestSide,
        greaterThanOrEqualTo(48),
      );
      await tester.tap(find.byKey(const Key('share-card')));
      await settle(tester);
      expect(find.byKey(const Key('share-preview-card')), findsOneWidget);
    });

    testWidgets('Elder Mode makes the button 64dp', (tester) async {
      await pump(
        tester,
        Scaffold(
          body: Center(child: ShareButton(doc: ShareDoc.invite())),
        ),
        prefs: <String, Object>{ElderMode.pref: true},
      );
      expect(
        tester.getSize(find.byKey(const Key('share-card'))).shortestSide,
        greaterThanOrEqualTo(64),
      );
    });

    testWidgets('child mode hides the share button', (tester) async {
      kChildMode.value = true;
      addTearDown(() => kChildMode.value = false);
      await pump(
        tester,
        Scaffold(
          body: Center(child: ShareButton(doc: ShareDoc.invite())),
        ),
      );
      expect(find.byKey(const Key('share-card')), findsNothing);
    });

    testWidgets('Elder Mode and 2.5x text keep buttons large, no overflow', (
      tester,
    ) async {
      await pump(
        tester,
        openButton(
          ShareDoc.story(
            title: 'T',
            body: 'a ' * 80,
            reviewKey: 'story.prophets.prophet-nuh',
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
      expect(shown, contains('ٱلرَّحْمَٰنِ'));
      expect(shown, contains('— Al-Fatihah 1:2'));
      expect(shown, isNot(contains('Mercy.')));
      expect(shown, isNot(contains('Saheeh')));
    });

    testWidgets('a completion card has no share button, only Close', (
      tester,
    ) async {
      await pump(tester, const Scaffold(body: QuietDoneCard()));
      expect(find.byKey(const Key('quiet-done-share')), findsNothing);
      expect(find.byKey(const Key('quiet-done-close')), findsOneWidget);
      expect(find.textContaining('Share'), findsNothing);
    });
  });
}
