import 'package:ar_rayaan/app/app.dart';
import 'package:ar_rayaan/app/core/env_config.dart';
import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/router.dart';
import 'package:ar_rayaan/features/academy/presentation/seerah_school_screen.dart';
import 'package:ar_rayaan/features/auth/application/auth_providers.dart';
import 'package:ar_rayaan/features/auth/data/fake_auth_repository.dart';
import 'package:ar_rayaan/features/games/presentation/games_screens.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_controller.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/grounding/corpus.dart';
import 'package:ar_rayaan/features/stories/data/stories_repository.dart';
import 'package:ar_rayaan/features/stories/domain/story.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_harness.dart';
import 'hadi_eval/corpus_fixture.dart';

class _SlowStub implements HadiProvider {
  int calls = 0;

  @override
  Future<String> ask(String q, List<HadiMessage> h) async {
    calls++;
    return 'Peace be with you.';
  }
}

/// Round 3 navigation and state: a tap that lands twice opens one screen, a
/// chip asks one question, Escape goes Back, Seerah chapters open, and the
/// 99 Names keep the place.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('open() twice in one frame stacks the screen once',
      (WidgetTester tester) async {
    await AppHarness.boot(tester);
    await AppHarness.go(tester, find.byType(Scaffold).first, '/academy/seerah');
    final BuildContext ctx = tester.element(find.byType(Scaffold).last);
    ctx.open('/settings');
    ctx.open('/settings');
    await AppHarness.settle(tester);
    expect(AppHarness.location(tester, find.byType(Scaffold).last),
        AppRoutes.settings);
    GoRouter.of(tester.element(find.byType(Scaffold).last)).pop();
    await AppHarness.settle(tester);
    expect(AppHarness.location(tester, find.byType(Scaffold).last),
        '/academy/seerah',
        reason: 'one Back must leave, not peel off a second copy');
  });

  testWidgets('Escape goes Back on a pushed screen and stays put on a tab',
      (WidgetTester tester) async {
    await AppHarness.boot(tester);
    await AppHarness.go(tester, find.byType(Scaffold).first, '/academy/seerah');
    tester.element(find.byType(Scaffold).last).open('/settings');
    await AppHarness.settle(tester);
    expect(AppHarness.location(tester, find.byType(Scaffold).last),
        AppRoutes.settings);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await AppHarness.settle(tester);
    expect(AppHarness.location(tester, find.byType(Scaffold).last),
        '/academy/seerah');

    await AppHarness.go(tester, find.byType(Scaffold).first, AppRoutes.home);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await AppHarness.settle(tester);
    expect(AppHarness.location(tester, find.byType(Scaffold).last),
        AppRoutes.home);
  });

  testWidgets('a Seerah chapter opens its story', (WidgetTester tester) async {
    await AppHarness.boot(
      tester,
      overrides: <Override>[
        storiesProvider.overrideWith((ref) async => <Story>[]),
      ],
    );
    await AppHarness.go(tester, find.byType(Scaffold).first, '/academy/seerah');
    await tester.tap(find.text('The Year of the Elephant'));
    await AppHarness.settle(tester);
    expect(AppHarness.location(tester, find.byType(Scaffold).last),
        AppRoutes.storyReader);
    // A chapter without its id would have been sent back to the library.
  });

  test('every Seerah chapter has an id the reader can open', () {
    for (final era in kSeerahEras) {
      for (final st in era.stories) {
        expect(RegExp(r'^seerah-\d\d$').hasMatch(st.id), isTrue, reason: st.id);
      }
    }
  });

  testWidgets('the 99 Names reopen where the person was',
      (WidgetTester tester) async {
    await AppHarness.boot(
      tester,
      prefsValues: <String, Object>{'ar.names99.index': 5},
      overrides: <Override>[
        namesProvider.overrideWith(
          (ref) async => <Name99>[
            for (int i = 1; i <= 99; i++)
              Name99(n: i, name: 'Name $i', meaning: 'Meaning $i', ref: '1:$i'),
          ],
        ),
      ],
    );
    await AppHarness.go(tester, find.byType(Scaffold).first, AppRoutes.names99);
    expect(find.text('6 OF 99'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await AppHarness.settle(tester);
    expect(find.text('7 OF 99'), findsOneWidget);
  });

  testWidgets('first run opens the introduction over Home, so Back stays in',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final FakeAuthRepository auth = FakeAuthRepository(prefs);
    await auth.init();
    AppHarness.useSurface(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(auth),
        ],
        child: ArRayaanApp(env: EnvConfig.fromDefines(), showOnboarding: true),
      ),
    );
    await AppHarness.settle(tester);
    final Finder anchor = find.byType(Scaffold).last;
    expect(AppHarness.location(tester, anchor), AppRoutes.onboarding);
    expect(find.text('Welcome to Ar-Rayaan'), findsOneWidget);

    GoRouter.of(tester.element(anchor)).pop();
    await AppHarness.settle(tester);
    expect(AppHarness.location(tester, find.byType(Scaffold).last),
        AppRoutes.home);
  });

  test('a chip tapped twice asks one question', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final HadiCorpus corpus = loadRealCorpus();
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
        hadiCorpusProvider.overrideWith((ref) => corpus),
      ],
    );
    addTearDown(c.dispose);
    final HadiController ctrl = c.read(hadiControllerProvider.notifier);
    final _SlowStub stub = _SlowStub();
    final Future<String> first =
        ctrl.ask('How do I make wudu?', provider: stub);
    final Future<String> second =
        ctrl.ask('How do I make wudu?', provider: stub);
    expect(await second, isEmpty);
    await first;
    final int asked = c
        .read(hadiControllerProvider)
        .messages
        .where((HadiMessage m) => !m.fromHadi)
        .length;
    expect(asked, 1);
    // And Hadi is free to answer again afterwards.
    await ctrl.ask('How do I make wudu?', provider: stub);
    expect(c.read(hadiControllerProvider).typing, isFalse);
  });
}
