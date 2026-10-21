import 'package:ar_rayaan/app/router.dart';
import 'package:ar_rayaan/app/theme/widgets/screen_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// The shared header: the gear opens Settings, Back pops (or goes Home when
/// there is nothing to pop), and both buttons are named, tappable semantics.
Widget _app(GoRouter router) => MaterialApp.router(routerConfig: router);

GoRouter _router({String initial = '/start', bool settingsGear = true}) =>
    GoRouter(
      initialLocation: initial,
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.home,
          builder: (BuildContext c, GoRouterState s) =>
              const Scaffold(body: Text('HOME PAGE')),
        ),
        GoRoute(
          path: '/start',
          builder: (BuildContext c, GoRouterState s) => Scaffold(
            body: SafeArea(
              child: ScreenHeader(title: 'Start', showSettings: settingsGear),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (BuildContext c, GoRouterState s) => const Scaffold(
            body: SafeArea(
              child: Column(
                children: <Widget>[
                  ScreenHeader(title: 'Settings', showSettings: false),
                  Text('SETTINGS PAGE'),
                ],
              ),
            ),
          ),
        ),
      ],
    );

void main() {
  testWidgets('gear opens Settings and Back returns', (WidgetTester tester) async {
    await tester.pumpWidget(_app(_router()));
    await tester.pumpAndSettle();
    expect(find.text('Start'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('SETTINGS PAGE'), findsOneWidget);
    // The settings screen itself shows no gear (showSettings: false).
    expect(find.byTooltip('Settings'), findsNothing);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('SETTINGS PAGE'), findsNothing);
  });

  testWidgets('Back with nothing to pop goes Home', (WidgetTester tester) async {
    await tester.pumpWidget(_app(_router()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('HOME PAGE'), findsOneWidget);
  });

  testWidgets('showSettings: false has no gear', (WidgetTester tester) async {
    await tester.pumpWidget(_app(_router(settingsGear: false)));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Settings'), findsNothing);
    expect(find.byTooltip('Back'), findsOneWidget);
  });

  testWidgets('buttons expose named button semantics and a 44 px target',
      (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(_app(_router()));
    await tester.pumpAndSettle();

    for (final String label in <String>['Back', 'Settings']) {
      final Finder f = find.bySemanticsLabel(label);
      expect(f, findsWidgets, reason: label);
      expect(
        tester.getSemantics(f.first),
        isSemantics(isButton: true, label: label, hasTapAction: true),
        reason: label,
      );
      final Size hit = tester.getSize(find.byTooltip(label));
      expect(hit.width, greaterThanOrEqualTo(44), reason: label);
      expect(hit.height, greaterThanOrEqualTo(44), reason: label);
    }
    handle.dispose();
  });
}
