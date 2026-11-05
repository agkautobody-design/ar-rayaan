import 'package:ar_rayaan/app/core/route_titles.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/feedback/application/feedback_providers.dart';
import 'package:ar_rayaan/features/feedback/data/feedback_service.dart';
import 'package:ar_rayaan/features/feedback/presentation/feedback_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the feedback route has a document title', () {
    expect(RouteTitles.forPath('/feedback'), 'Send feedback · Ar-Rayaan');
  });

  group('FeedbackService.validate', () {
    test('a clear message with no email is enough', () {
      expect(
        FeedbackService.validate('The prayer times page did not load.', null),
        isNull,
      );
    });

    test('too short, too long and a bad email are refused', () {
      expect(FeedbackService.validate('broken', null), isNotNull);
      expect(FeedbackService.validate('x' * 2001, null), isNotNull);
      expect(
        FeedbackService.validate('The map screen froze.', 'not-an-email'),
        isNotNull,
      );
      expect(
        FeedbackService.validate('The map screen froze.', 'a@b.co'),
        isNull,
      );
    });
  });

  group('FeedbackScreen', () {
    Future<void> pump(WidgetTester tester, {required bool enabled}) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            feedbackEnabledProvider.overrideWithValue(enabled),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const FeedbackScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
    }

    testWidgets('without the cloud, says so instead of a form', (tester) async {
      await pump(tester, enabled: false);
      expect(tester.takeException(), isNull);
      expect(find.textContaining('cloud'), findsOneWidget);
      expect(find.byKey(const Key('feedback-send')), findsNothing);
    });

    testWidgets('with the cloud, shows the form and the error-notes toggle',
        (tester) async {
      await pump(tester, enabled: true);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('feedback-message')), findsOneWidget);
      expect(find.byKey(const Key('feedback-email')), findsOneWidget);
      expect(find.byKey(const Key('feedback-attach-errors')), findsOneWidget);
      expect(find.byKey(const Key('feedback-send')), findsOneWidget);
    });
  });
}
