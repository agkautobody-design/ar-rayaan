import 'package:ar_rayaan/app/core/modules/module_status.dart';
import 'package:ar_rayaan/features/majlis/presentation/majlis_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Courtyard is an open forum with no moderation yet. While the module
/// registry says anything other than 'live', no Majlis screen may offer posting.
void main() {
  Widget host(Widget child, String status) => ProviderScope(
        overrides: [
          moduleRegistryProvider.overrideWith(
            (Ref ref) async => ModuleStatusService(<String, dynamic>{
              'modules': <dynamic>[
                <String, dynamic>{'id': 'majlis', 'status': status},
              ],
            }),
          ),
        ],
        child: MaterialApp(home: child),
      );

  testWidgets('gated: forum, thread and new-thread screens show the closed notice',
      (WidgetTester tester) async {
    for (final Widget screen in <Widget>[
      const MajlisScreen(),
      const NewThreadScreen(),
    ]) {
      await tester.pumpWidget(host(screen, 'gated'));
      await tester.pumpAndSettle();
      expect(find.textContaining('not open yet'), findsOneWidget);
      expect(find.text('New thread'), findsNothing);
      expect(find.byType(TextField), findsNothing);
    }
  });
}
