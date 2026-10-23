import 'package:ar_rayaan/app/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'app_harness.dart';

/// Round 5 navigation: the Settings gear in every screen header opens
/// Settings once per tap (a second tap that lands in the same frame must not
/// stack a second copy), and one Back returns to the screen the person left.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the header Settings gear stacks Settings once; Back leaves',
      (WidgetTester tester) async {
    await AppHarness.boot(tester);
    await AppHarness.go(tester, find.byType(Scaffold).first, '/menu');
    final Finder gear = find.byTooltip('Settings').first;
    await tester.tap(gear);
    await tester.tap(gear, warnIfMissed: false);
    await AppHarness.settle(tester);
    expect(AppHarness.location(tester, find.byType(Scaffold).last),
        AppRoutes.settings);
    GoRouter.of(tester.element(find.byType(Scaffold).last)).pop();
    await AppHarness.settle(tester);
    expect(AppHarness.location(tester, find.byType(Scaffold).last),
        '/menu',
        reason: 'one Back must leave Settings, not peel off a second copy');
  });
}
