import 'dart:async';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/academy/application/naat_recital.dart';
import 'package:ar_rayaan/features/academy/application/user_poems_provider.dart';
import 'package:ar_rayaan/features/academy/domain/user_poem.dart';
import 'package:ar_rayaan/features/academy/presentation/add_poem_screen.dart';
import 'package:ar_rayaan/features/academy/presentation/naat_words_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Says each line instantly and remembers what it was asked to say.
class FakeVoice implements RecitalVoice {
  FakeVoice({this.available = true, this.hold});

  final bool available;

  /// When set, speak() waits for it (so a test can pause mid-poem).
  final Completer<void>? hold;
  final List<String> said = <String>[];
  final List<String> langs = <String>[];
  final List<double> rates = <double>[];
  int stops = 0;

  @override
  Future<bool> speak(
    String text, {
    required String lang,
    required double rate,
  }) async {
    if (!available) return false;
    said.add(text);
    langs.add(lang);
    rates.add(rate);
    if (hold != null && said.length == 1) await hold!.future;
    return true;
  }

  @override
  Future<void> stop() async => stops++;
}

Future<ProviderContainer> _container(FakeVoice v) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences sp = await SharedPreferences.getInstance();
  final ProviderContainer c = ProviderContainer(
    overrides: <Override>[
      recitalVoiceProvider.overrideWithValue(v),
      sharedPreferencesProvider.overrideWithValue(sp),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('the recital controller', () {
    test('says every line in order, in the poem language, then stops', () async {
      final FakeVoice v = FakeVoice();
      final ProviderContainer c = await _container(v);
      final ProviderSubscription<RecitalState> keep = c.listen(
        naatRecitalProvider,
        (_, _) {},
      );
      await c.read(naatRecitalProvider.notifier).play(<String>['a', 'b', 'c'], 'ur');
      expect(v.said, <String>['a', 'b', 'c']);
      expect(v.langs.toSet(), <String>{'ur'});
      expect(keep.read().playing, isFalse);
      expect(keep.read().index, -1);
    });

    test('slow uses the slower rate', () async {
      final FakeVoice v = FakeVoice();
      final ProviderContainer c = await _container(v);
      c.listen(naatRecitalProvider, (_, _) {});
      c.read(naatRecitalProvider.notifier).toggleSlow();
      await c.read(naatRecitalProvider.notifier).play(<String>['a'], 'ar');
      expect(v.rates.single, kRecitalSlowRate);
    });

    test('a phone with no voice says so and does not claim to play', () async {
      final FakeVoice v = FakeVoice(available: false);
      final ProviderContainer c = await _container(v);
      final ProviderSubscription<RecitalState> keep = c.listen(
        naatRecitalProvider,
        (_, _) {},
      );
      await c.read(naatRecitalProvider.notifier).play(<String>['a', 'b'], 'ur');
      expect(keep.read().unavailable, isTrue);
      expect(keep.read().playing, isFalse);
    });

    test('starting from a line skips the ones before it', () async {
      final FakeVoice v = FakeVoice();
      final ProviderContainer c = await _container(v);
      c.listen(naatRecitalProvider, (_, _) {});
      await c.read(naatRecitalProvider.notifier).play(<String>['a', 'b', 'c'], 'en', from: 1);
      expect(v.said, <String>['b', 'c']);
    });

    test('pause keeps the line it was on, resume carries on from it', () async {
      final Completer<void> hold = Completer<void>();
      final FakeVoice v = FakeVoice(hold: hold);
      final ProviderContainer c = await _container(v);
      final ProviderSubscription<RecitalState> keep = c.listen(
        naatRecitalProvider,
        (_, _) {},
      );
      final NaatRecital n = c.read(naatRecitalProvider.notifier);
      unawaited(n.play(<String>['a', 'b', 'c'], 'en'));
      await Future<void>.delayed(Duration.zero);
      expect(keep.read().index, 0);
      expect(keep.read().playing, isTrue);
      await n.pause();
      hold.complete();
      await Future<void>.delayed(Duration.zero);
      expect(keep.read().playing, isFalse);
      expect(keep.read().index, 0);
      expect(v.said, <String>['a']); // nothing after the pause
      await n.resume();
      expect(v.said, <String>['a', 'a', 'b', 'c']);
    });
  });

  group('your own poems', () {
    test('lines are trimmed and blank rows dropped', () {
      expect(parsePoemLines('  a \n\n b\r\n   \nc'), <String>['a', 'b', 'c']);
    });

    test('a poem survives saving and loading, damaged entries are skipped', () {
      const UserPoem p = UserPoem(
        id: 'mine-1',
        title: 'T',
        lang: 'ur',
        lines: <String>['x', 'y'],
        meaningLang: 'en',
        meanings: <String>['one'],
        audioUrl: 'https://example.com/a.mp3',
      );
      final List<UserPoem> back = decodeUserPoems(encodeUserPoems(<UserPoem>[p]));
      expect(back.single.title, 'T');
      expect(back.single.meanings, <String>['one']);
      expect(back.single.audioUrl, 'https://example.com/a.mp3');
      expect(decodeUserPoems('not json'), isEmpty);
      expect(decodeUserPoems('[{"id":"x"},5,null]'), isEmpty);
      expect(decodeUserPoems(null), isEmpty);
    });

    test('a link that is not http is not kept', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences sp = await SharedPreferences.getInstance();
      final UserPoemsNotifier n = UserPoemsNotifier(sp);
      await n.add(title: 'T', lang: 'en', lines: <String>['a'], audioUrl: 'file:///x');
      expect(n.state.single.audioUrl, isNull);
      expect(decodeUserPoems(sp.getString(kUserPoemsKey)).length, 1);
    });
  });

  group('the screens', () {
    Future<ProviderContainer> boot(
      WidgetTester tester,
      Widget home, {
      FakeVoice? voice,
      Map<String, Object> prefs = const <String, Object>{},
    }) async {
      SharedPreferences.setMockInitialValues(prefs);
      final SharedPreferences sp = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(430, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final GoRouter router = GoRouter(
        routes: <RouteBase>[
          GoRoute(path: '/', builder: (_, _) => home),
          GoRoute(
            path: '/player/words/:id',
            builder: (_, GoRouterState s) =>
                NaatReaderScreen(id: s.pathParameters['id']!),
          ),
        ],
      );
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(sp),
          recitalVoiceProvider.overrideWithValue(voice ?? FakeVoice()),
        ],
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      return c;
    }

    testWidgets('Read aloud lights the line being said and ends cleanly', (
      WidgetTester tester,
    ) async {
      final FakeVoice v = FakeVoice();
      await boot(tester, const NaatReaderScreen(id: 'lab-pe-aati-hai-dua'), voice: v);
      expect(find.byKey(const Key('naat-play')), findsOneWidget);
      await tester.tap(find.byKey(const Key('naat-play')));
      await tester.pumpAndSettle();
      expect(v.said.length, 6);
      expect(v.langs.toSet(), <String>{'ur'});
      expect(find.byKey(const Key('naat-no-voice')), findsNothing);
    });

    testWidgets('no voice on the phone: a plain message, the words still show', (
      WidgetTester tester,
    ) async {
      await boot(
        tester,
        const NaatReaderScreen(id: 'tala-al-badru'),
        voice: FakeVoice(available: false),
      );
      await tester.tap(find.byKey(const Key('naat-play')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('naat-no-voice')), findsOneWidget);
      expect(find.textContaining('ṭalaʿa l-badru'), findsOneWidget);
    });

    testWidgets('tapping a line starts reading from that line', (
      WidgetTester tester,
    ) async {
      final FakeVoice v = FakeVoice();
      await boot(tester, const NaatReaderScreen(id: 'lab-pe-aati-hai-dua'), voice: v);
      await tester.tap(find.byKey(const Key('naat-line-4')));
      await tester.pumpAndSettle();
      expect(v.said.length, 2);
    });

    testWidgets('the add form checks, saves, and opens the poem', (
      WidgetTester tester,
    ) async {
      final ProviderContainer c = await boot(tester, const AddPoemScreen());
      await tester.tap(find.byKey(const Key('poem-save')));
      await tester.pump();
      expect(find.byKey(const Key('poem-error')), findsOneWidget);
      expect(c.read(userPoemsProvider), isEmpty);

      await tester.enterText(find.byKey(const Key('poem-title')), 'My naat');
      await tester.enterText(find.byKey(const Key('poem-words')), 'line one\nline two');
      await tester.enterText(find.byKey(const Key('poem-meaning')), 'first\nsecond\nthird');
      await tester.tap(find.byKey(const Key('poem-save')));
      await tester.pump();
      expect(find.byKey(const Key('poem-error')), findsOneWidget); // too many
      await tester.enterText(find.byKey(const Key('poem-meaning')), 'first\nsecond');
      await tester.tap(find.byKey(const Key('poem-lang-en')));
      await tester.tap(find.byKey(const Key('poem-save')));
      await tester.pumpAndSettle();
      expect(c.read(userPoemsProvider).single.title, 'My naat');
      expect(find.text('first'), findsOneWidget); // the reader opened
      expect(find.text('line one'), findsOneWidget);
    });

    testWidgets('a poem in another language cannot be read aloud, and says so', (
      WidgetTester tester,
    ) async {
      const UserPoem p = UserPoem(
        id: 'mine-9',
        title: 'Autre',
        lang: 'xx',
        lines: <String>['bonjour'],
      );
      await boot(
        tester,
        const NaatReaderScreen(id: 'mine-9'),
        prefs: <String, Object>{kUserPoemsKey: encodeUserPoems(<UserPoem>[p])},
      );
      expect(find.byKey(const Key('naat-play')), findsNothing);
      expect(find.textContaining('Reading aloud is available'), findsOneWidget);
      expect(find.text('bonjour'), findsWidgets);
    });

    testWidgets('a poem can be removed after confirming', (
      WidgetTester tester,
    ) async {
      const UserPoem p = UserPoem(
        id: 'mine-2',
        title: 'Gone',
        lang: 'en',
        lines: <String>['hi'],
      );
      final ProviderContainer c = await boot(
        tester,
        const NaatReaderScreen(id: 'mine-2'),
        prefs: <String, Object>{kUserPoemsKey: encodeUserPoems(<UserPoem>[p])},
      );
      await tester.scrollUntilVisible(find.byKey(const Key('poem-remove')), 200);
      await tester.tap(find.byKey(const Key('poem-remove')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('poem-remove-yes')));
      await tester.pumpAndSettle();
      expect(c.read(userPoemsProvider), isEmpty);
    });
  });
}
