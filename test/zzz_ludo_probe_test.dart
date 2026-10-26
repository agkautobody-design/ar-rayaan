import 'package:ar_rayaan/features/games/presentation/ludo_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';

void main() {
  testWidgets('PROBE ludo game view', (WidgetTester tester) async {
    AppHarness.useSurface(tester);
    final List<String> seen = <String>[];
    final FlutterExceptionHandler? old = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails d) {
      final String st = d.stack
          .toString()
          .split('\n')
          .where((String l) => l.contains('package:'))
          .take(9)
          .join(' | ');
      seen.add('${d.exceptionAsString().split('\n').take(3).join(' ')} @@ $st');
    };
    await tester.pumpWidget(const MaterialApp(home: LudoScreen()));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Play Hadi'));
    await tester.pump(const Duration(milliseconds: 300));
    FlutterError.onError = old;
    if (seen.isNotEmpty) {
      fail('PROBE_BEGIN ${seen.length} ${seen.first} PROBE_END');
    }
  });
}
