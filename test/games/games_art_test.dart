import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/games/engine/game_registry.dart';
import 'package:ar_rayaan/features/games/engine/learning_games.dart';
import 'package:ar_rayaan/features/games/presentation/game_details_screen.dart';
import 'package:ar_rayaan/features/games/presentation/game_history_screen.dart';
import 'package:ar_rayaan/features/games/presentation/games_screens.dart';
import 'package:ar_rayaan/features/games/ui/games_art.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Games art slots: the files, the manifest, the registry mapping, and
/// that every screen draws the art when it is there and its code-drawn
/// fallback when it is not.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Map<String, dynamic> manifest = jsonDecode(
    File('assets/games/art/manifest.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final Map<String, dynamic> slots =
      manifest['slots'] as Map<String, dynamic>;
  final Map<String, dynamic> fallback =
      manifest['fallback'] as Map<String, dynamic>;

  tearDown(() => GamesArt.debugSetKnown(null));

  group('the slots', () {
    test('every slot is in the manifest as art or as a fallback', () {
      for (final ArtSlot s in ArtSlot.values) {
        final bool art = slots.containsKey(s.name);
        final bool plain = fallback.containsKey(s.name);
        expect(art || plain, isTrue, reason: s.name);
        expect(art && plain, isFalse, reason: '${s.name} is in both lists');
      }
      for (final String name in slots.keys) {
        expect(
          ArtSlot.values.any((ArtSlot s) => s.name == name),
          isTrue,
          reason: 'manifest slot $name has no ArtSlot',
        );
      }
    });

    test('a slot path is the manifest file, and the file exists', () {
      for (final ArtSlot s in ArtSlot.values) {
        final Object? entry = slots[s.name];
        if (entry == null) continue;
        expect((entry as Map<String, dynamic>)['file'], s.path);
        expect(File(s.path).existsSync(), isTrue, reason: s.path);
      }
    });

    test('every registry game and every hub section has a slot with art', () {
      for (final GameDef g in kGames) {
        final ArtSlot? s = GamesArt.slotForGame(g.id);
        // The learning games without their own picture (timeline, prophets,
        // steps, word games, hidden games) draw the icon badge instead.
        if (s == null) {
          expect(
            g.hidden || kLearningGames.any((GameDef l) => l.id == g.id),
            isTrue,
            reason: g.id,
          );
          continue;
        }
        expect(slots.containsKey(s.name), isTrue, reason: g.id);
      }
      for (final GameCategory c in GameCategory.values) {
        expect(
          slots.containsKey(GamesArt.slotForCategory(c).name),
          isTrue,
          reason: c.name,
        );
      }
    });

    test('the manifest is honest about its kinds and stays small', () {
      const Set<String> kinds = <String>{'exact', 'patched'};
      for (final MapEntry<String, dynamic> e in slots.entries) {
        final Map<String, dynamic> v = e.value as Map<String, dynamic>;
        expect(kinds.contains(v['kind']), isTrue, reason: e.key);
        expect((v['box'] as List<dynamic>).length, 4, reason: e.key);
        expect(v['source'], isA<String>(), reason: e.key);
      }
      expect(manifest['totalBytes'] as int, lessThan(4 * 1024 * 1024));
    });
  });

  group('on screen', () {
    Set<String> allArt() => <String>{
          for (final ArtSlot s in ArtSlot.values)
            if (slots.containsKey(s.name)) s.path,
        };

    Finder artImages() => find.byWidgetPredicate(
          (Widget w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName.startsWith(GamesArt.folder),
        );

    Future<void> pump(WidgetTester tester, Widget screen) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(430, 8000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(theme: AppTheme.dark(), home: screen),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('the hub draws the arch and one picture per game', (
      tester,
    ) async {
      GamesArt.debugSetKnown(allArt());
      await pump(tester, const GamesScreen());
      expect(tester.takeException(), isNull);
      // Header arch + a section picture per category + a picture per game.
      expect(artImages(), findsAtLeastNWidgets(
        1 + visibleGames(showAcademy: true).where((GameDef g) => GamesArt.slotForGame(g.id) != null).length,
      ));
    });

    testWidgets('the hub falls back to the drawn look with no art', (
      tester,
    ) async {
      GamesArt.debugSetKnown(<String>{});
      await pump(tester, const GamesScreen());
      expect(tester.takeException(), isNull);
      expect(artImages(), findsNothing);
      for (final GameDef g in visibleGames(showAcademy: true)) {
        expect(find.text(g.title), findsOneWidget, reason: g.id);
      }
    });

    testWidgets('only some files present: the rest fall back, no error', (
      tester,
    ) async {
      GamesArt.debugSetKnown(<String>{ArtSlot.gameChess.path});
      await pump(tester, const GamesScreen());
      expect(tester.takeException(), isNull);
    });

    testWidgets('details, history and a missing slot all lay out', (
      tester,
    ) async {
      for (final Set<String> known in <Set<String>>[allArt(), <String>{}]) {
        GamesArt.debugSetKnown(known);
        await pump(tester, const GameDetailsScreen(gameId: 'qk'));
        expect(tester.takeException(), isNull);
        expect(find.text('How to play'), findsOneWidget);
        expect(
          find.text('Complete the ayah, and learn the surahs by name and '
              'number'),
          findsOneWidget,
        );
        await pump(tester, const GameHistoryScreen());
        expect(tester.takeException(), isNull);
      }
    });
  });
}
