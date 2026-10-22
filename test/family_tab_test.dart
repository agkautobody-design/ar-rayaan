import 'package:ar_rayaan/features/academy/presentation/academy_family.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';

/// P1-6: the Family tab used to open a "Coming soon" placeholder (four tiles
/// that only showed a snackbar). It now opens the real Family Wing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the Family tab opens the Family Wing, not a placeholder', (
    tester,
  ) async {
    await AppHarness.boot(tester);

    await tester.tap(find.text('Family'));
    await AppHarness.settle(tester);

    expect(AppHarness.location(tester, find.text('Faith')), '/family');
    expect(find.byType(FamilyScreen), findsOneWidget);
    expect(find.text('Coming soon'), findsNothing);
  });
}
