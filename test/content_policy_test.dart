import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/sources/presentation/content_policy_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('policy text never claims scholar review', () {
    final String all = ContentPolicyScreen.sections
        .expand(((String, List<String>) s) => <String>[s.$1, ...s.$2])
        .join('\n');
    expect(ContentPolicyScreen.reviewStatus, 'Scholar review needed');
    final RegExp bare = RegExp(r'(?<!not yet )(?<!not )scholar-reviewed',
        caseSensitive: false);
    expect(bare.hasMatch(all), isFalse);
    expect(all, contains('Sahih al-Bukhari 4485'));
    expect(all, contains('Sahih al-Bukhari 3461'));
    expect(all, contains(ContentPolicyScreen.earlierBadge));
  });

  testWidgets('policy page renders its sections', (tester) async {
    tester.view.physicalSize = const Size(430, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      home: const ContentPolicyScreen(),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Scholar review needed'), findsWidgets);
  });
}
