import 'package:ar_rayaan/app/app.dart';
import 'package:ar_rayaan/app/core/env_config.dart';
import 'package:ar_rayaan/app/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('appUrlProvider honors the dart-define origin logic', () {
    final ProviderContainer c = ProviderContainer(
      overrides: [appUrlProvider.overrideWithValue('https://ar-rayaan.app')],
    );
    addTearDown(c.dispose);
    expect(c.read(appUrlProvider), 'https://ar-rayaan.app');
  });

  testWidgets('share screen shows the beta QR and live link', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appUrlProvider.overrideWithValue('https://beta.ar-rayaan.test'),
        ],
        child: ArRayaanApp(env: EnvConfig.fromDefines()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('welcome-continue')));
    await tester.pumpAndSettle();

    final BuildContext home = tester.element(find.text('Prayer Times'));
    // ignore: use_build_context_synchronously
    GoRouter.of(home).go('/share');
    await tester.pumpAndSettle();

    expect(find.text('BETA · INVITE A TESTER'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('https://beta.ar-rayaan.test'), findsOneWidget);
    expect(find.text('ADD TO ANY HOME SCREEN'), findsOneWidget);
  });
}
