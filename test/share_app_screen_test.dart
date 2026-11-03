import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/core/route_titles.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/share/application/share_service.dart';
import 'package:ar_rayaan/features/share/application/share_text.dart';
import 'package:ar_rayaan/features/share/presentation/share_app_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
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

Future<void> pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues(const <String, Object>{});
  final SharedPreferences p = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[sharedPreferencesProvider.overrideWithValue(p)],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const ShareAppScreen(),
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

  test('the route has a document title', () {
    expect(RouteTitles.forPath('/share-app'), 'Share Ar-Rayaan · Ar-Rayaan');
  });

  testWidgets('shows the QR code, the link and both actions', (tester) async {
    await pump(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.byKey(const Key('share-app-url')), findsOneWidget);
    expect(find.text(kInviteUrl), findsOneWidget);
    expect(find.byKey(const Key('share-app-send')), findsOneWidget);
    expect(find.byKey(const Key('share-app-copy')), findsOneWidget);
  });

  testWidgets('Copy the link copies exactly the app address', (tester) async {
    _clipboard(tester);
    await pump(tester);
    await tester.tap(find.byKey(const Key('share-app-copy')));
    await settle(tester);
    expect(_copied, kInviteUrl);
    expect(find.textContaining('Copied'), findsOneWidget);
  });

  testWidgets('Send the link opens the preview with the invitation', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('share-app-send')));
    await settle(tester);
    final String shown = tester
        .widget<SelectableText>(find.byKey(const Key('share-preview-text')))
        .data!;
    expect(shown, ShareService.build(ShareDoc.invite()));
    expect(shown, contains(kInviteUrl));
    expect(shown, contains('Free to use, no account needed'));
  });
}
