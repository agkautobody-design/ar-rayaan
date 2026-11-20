import 'package:ar_rayaan/features/academy/domain/free_downloads.dart';
import 'package:ar_rayaan/features/academy/presentation/free_downloads_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every download points at an allowed https host and has terms', () {
    final Set<String> ids = <String>{};
    for (final FreeDownload d in kFreeDownloads) {
      final Uri u = Uri.parse(d.pageUrl);
      expect(u.scheme, 'https', reason: d.id);
      expect(kFreeDownloadHosts, contains(u.host), reason: d.id);
      expect(d.terms.trim(), isNotEmpty, reason: d.id);
      expect(ids.add(d.id), isTrue, reason: 'duplicate ${d.id}');
      if (d.terms.contains('Attribution')) {
        expect(d.credit.trim(), isNotEmpty, reason: '${d.id} needs a credit');
      }
    }
  });

  testWidgets('screen lists every recording with a button to its source',
      (WidgetTester t) async {
    await t.pumpWidget(const ProviderScope(
        child: MaterialApp(home: FreeDownloadsScreen())));
    await t.pumpAndSettle();
    for (final FreeDownload d in kFreeDownloads) {
      await t.scrollUntilVisible(find.byKey(Key('dl-open-${d.id}')), 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.byKey(Key('dl-open-${d.id}')), findsOneWidget);
    }
  });
}
