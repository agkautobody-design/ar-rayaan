import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/academy/application/academy_providers.dart';
import 'package:ar_rayaan/features/academy/application/wasia_controller.dart';
import 'package:ar_rayaan/features/academy/domain/learner_path.dart';
import 'package:ar_rayaan/features/academy/presentation/widgets/start_here_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final ProviderContainer c = ProviderContainer(overrides: <Override>[
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('Wasia coaches from on-device state', () {
    test('"what should I do next" gives one step and a place to open',
        () async {
      final ProviderContainer c = await _container();
      final WasiaController w = c.read(wasiaControllerProvider.notifier);
      final String r = await w.ask('what should I do next?');
      expect(r, contains('Just this one'));
      final msg = c.read(wasiaControllerProvider).messages.last;
      expect(msg.routes.length == 1, isTrue);
      expect(msg.routes.first.startsWith('/academy/'), isTrue);
      expect(msg.notes.isNotEmpty, isTrue);
    });

    test('telling Wasia "I am brand new" saves the level on the device',
        () async {
      final ProviderContainer c = await _container();
      await c.read(wasiaControllerProvider.notifier).ask('I am brand new');
      expect(c.read(learnerLevelProvider) == LearnerLevel.fresh, isTrue);
      final SharedPreferences p = await SharedPreferences.getInstance();
      expect(p.getString(kLearnerLevelPref) == 'fresh', isTrue);
    });

    test('"this is too easy" moves the level up', () async {
      final ProviderContainer c = await _container();
      await c.read(learnerLevelProvider.notifier).set(LearnerLevel.basics);
      await c.read(wasiaControllerProvider.notifier).ask('this is too easy');
      expect(c.read(learnerLevelProvider) == LearnerLevel.deeper, isTrue);
    });

    test('a parent is pointed to the Family Wing and nothing is saved',
        () async {
      final ProviderContainer c = await _container();
      final WasiaController w = c.read(wasiaParentControllerProvider.notifier);
      final String r = await w.ask('what should we do next?',
          persona: WasiaPersona.parent);
      expect(r, contains('Family Wing'));
      expect(c.read(learnerLevelProvider) == null, isTrue);
    });

    test('"I dont understand" is left to the letter re-teach, not the coach',
        () async {
      final ProviderContainer c = await _container();
      final WasiaController w = c.read(wasiaControllerProvider.notifier);
      await w.ask('what is baa');
      final String r = await w.ask('I dont understand');
      expect(r, contains('That is okay'));
    });
  });

  testWidgets('Start here: pick a level, see three places, no test',
      (WidgetTester t) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await t.pumpWidget(ProviderScope(
      overrides: <Override>[sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(body: SingleChildScrollView(child: StartHereCard())),
      ),
    ));
    expect(find.text('WHERE ARE YOU?'), findsOneWidget);
    expect(find.byKey(const Key('level-fresh')), findsOneWidget);
    await t.tap(find.byKey(const Key('level-deeper')));
    await t.pump();
    expect(find.text('START HERE'), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(3));
    expect(find.byKey(const Key('start-letters-check')), findsOneWidget);
  });
}
