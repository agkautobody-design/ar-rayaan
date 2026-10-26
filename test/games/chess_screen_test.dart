import 'dart:io';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/elder/application/elder_mode.dart';
import 'package:ar_rayaan/features/games/chess/chess_ai.dart';
import 'package:ar_rayaan/features/games/chess/chess_board_view.dart';
import 'package:ar_rayaan/features/games/chess/chess_engine.dart';
import 'package:ar_rayaan/features/games/chess/chess_settings.dart';
import 'package:ar_rayaan/features/games/data/games_store.dart';
import 'package:ar_rayaan/features/games/presentation/shatranj_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Shatranj screen end to end: the owner's board art, every control under
/// the board, settings that stick, and the game rules reached by tapping.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> pumpChess(
    WidgetTester tester, {
    int mode = 2,
    ChessLevel level = ChessLevel.beginner,
    String playAs = 'white',
    int minutes = 0,
    Map<String, Object> prefsValues = const <String, Object>{},
    double width = 430,
    double height = 3000,
    double scale = 1,
  }) async {
    SharedPreferences.setMockInitialValues(prefsValues);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: ShatranjScreen(
            initialMode: mode,
            level: level,
            playAs: playAs,
            minutes: minutes,
            seed: 7,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    return ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
  }

  Future<void> tapSq(WidgetTester tester, String sq) async {
    await tester.tap(find.byKey(ValueKey<String>('sq-$sq')));
    await tester.pump();
  }

  Future<void> move(WidgetTester tester, String from, String to) async {
    await tapSq(tester, from);
    await tapSq(tester, to);
  }

  Future<void> letHadiThink(WidgetTester tester) async {
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> leave(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  group('board art', () {
    test('every sprite and square the board can ask for is shipped, small', () {
      int bytes = 0;
      for (final String path in ChessAssets.all()) {
        final File f = File(path);
        expect(f.existsSync(), isTrue, reason: path);
        bytes += f.lengthSync();
      }
      expect(ChessAssets.all().length, 12 + 4 * 2 * 3);
      expect(bytes, lessThan(1500 * 1024), reason: 'assets stay under 1.5 MB');
    });

    test('the asset folders are declared in pubspec.yaml', () {
      final String yaml = File('pubspec.yaml').readAsStringSync();
      expect(yaml.contains('assets/games/chess/pieces/'), isTrue);
      expect(yaml.contains('assets/games/chess/squares/'), isTrue);
    });

    test('the pieces are real transparent sprites', () {
      for (final String path in ChessAssets.all().where(
        (String p) => p.contains('/pieces/'),
      )) {
        final List<int> b = File(path).readAsBytesSync();
        // PNG signature, then colour type 6 (RGBA) at byte 25.
        expect(b.sublist(1, 4), <int>[0x50, 0x4E, 0x47], reason: path);
        expect(b[25], 6, reason: '$path must have an alpha channel');
      }
    });

    test('asset names follow the piece and the theme', () {
      expect(ChessAssets.piece(kKnight), 'assets/games/chess/pieces/wn.png');
      expect(
        ChessAssets.piece(kQueen | kBlackBit),
        'assets/games/chess/pieces/bq.png',
      );
      expect(
        ChessAssets.square(ChessBoardTheme.blue, light: false, v: 2),
        'assets/games/chess/squares/blue_dark_2.jpg',
      );
    });
  });

  group('settings', () {
    test('defaults: sound off, move hints on, confirm resign on', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(c.dispose);
      final ChessSettings s = c.read(chessSettingsProvider);
      expect(s.sound, isFalse);
      expect(s.showLegalMoves, isTrue);
      expect(s.autoQueen, isFalse);
      expect(s.confirmResign, isTrue);
      expect(s.autoSave, isTrue);
      expect(s.theme, ChessBoardTheme.classic);
      expect(s.pieces, ChessPieceStyle.classic);
    });

    test('choices are kept on the device and read back', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      ProviderContainer make() => ProviderContainer(
            overrides: <Override>[
              sharedPreferencesProvider.overrideWithValue(prefs),
            ],
          );
      final ProviderContainer a = make();
      a.read(chessSettingsProvider.notifier).update(
            const ChessSettings(
              theme: ChessBoardTheme.green,
              pieces: ChessPieceStyle.modern,
              sound: true,
              showLegalMoves: false,
              autoQueen: true,
              confirmResign: false,
              autoSave: false,
            ),
          );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      a.dispose();
      final ProviderContainer b = make();
      addTearDown(b.dispose);
      final ChessSettings s = b.read(chessSettingsProvider);
      expect(s.theme, ChessBoardTheme.green);
      expect(s.pieces, ChessPieceStyle.modern);
      expect(s.sound, isTrue);
      expect(s.showLegalMoves, isFalse);
      expect(s.autoQueen, isTrue);
      expect(s.confirmResign, isFalse);
      expect(s.autoSave, isFalse);
    });

    test('a damaged saved game is ignored', () {
      expect(SavedChess.decode('not json'), isNull);
      expect(SavedChess.decode('{"mode":9}'), isNull);
      expect(SavedChess.decode(null), isNull);
      final SavedChess ok = SavedChess(
        mode: 2,
        level: 'beginner',
        humanWhite: true,
        uci: <String>['e2e4'],
      );
      expect(SavedChess.decode(ok.encode())!.uci, <String>['e2e4']);
    });

    Future<ProviderContainer> openSheet(WidgetTester tester) async {
      final ProviderContainer c = await pumpChess(tester);
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      return c;
    }

    testWidgets('the settings sheet opens with its title', (tester) async {
      await openSheet(tester);
      expect(find.text('Chess Settings'), findsOneWidget);
      await leave(tester);
    });

    for (final String t in <String>[
      'Board Theme',
      'Pieces Style',
      'Sound Effects',
      'Show Move Hints',
      'Auto-queen promotion',
      'Confirm resign',
      'Auto Save Games',
      'Classic wood',
      'Green',
      'Blue',
      'Grey and black',
    ]) {
      testWidgets('the settings sheet shows the row "$t"', (tester) async {
        await openSheet(tester);
        expect(find.text(t), findsWidgets);
        await leave(tester);
      });
    }

    testWidgets('the sound switch turns sound on and is saved', (tester) async {
      final ProviderContainer c = await openSheet(tester);
      expect(c.read(chessSettingsProvider).sound, isFalse);
      await tester.ensureVisible(find.byType(Switch).first);
      await tester.pump();
      await tester.tap(find.byType(Switch).first);
      await tester.pump();
      expect(c.read(chessSettingsProvider).sound, isTrue);
      await leave(tester);
    });

    testWidgets('choosing the Green board saves the theme', (tester) async {
      final ProviderContainer c = await openSheet(tester);
      await tester.ensureVisible(find.text('Green'));
      await tester.pump();
      await tester.tap(find.text('Green'));
      await tester.pump();
      expect(c.read(chessSettingsProvider).theme, ChessBoardTheme.green);
      await leave(tester);
    });
  });

  group('pass and play', () {
    testWidgets('the board has a gold frame, A-H and 1-8, and 64 squares', (
      tester,
    ) async {
      await pumpChess(tester);
      expect(find.byKey(const ValueKey<String>('chess-board')), findsOneWidget);
      for (final String l in <String>['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H']) {
        expect(find.text(l), findsOneWidget);
      }
      for (int r = 1; r <= 8; r++) {
        expect(find.text('$r'), findsOneWidget);
      }
      expect(find.byType(ChessBoardView), findsOneWidget);
      expect(find.textContaining('Two players, one board'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await leave(tester);
    });

    testWidgets('squares have screen-reader labels', (tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await pumpChess(tester);
      expect(find.bySemanticsLabel('e2, white pawn'), findsOneWidget);
      expect(find.bySemanticsLabel('e1, white king'), findsOneWidget);
      expect(find.bySemanticsLabel('d8, black queen'), findsOneWidget);
      expect(find.bySemanticsLabel('e4, empty'), findsOneWidget);
      h.dispose();
      await leave(tester);
    });

    testWidgets('a move updates the move list, status and undo / redo', (
      tester,
    ) async {
      await pumpChess(tester);
      await move(tester, 'e2', 'e4');
      expect(find.text('1. e4'), findsOneWidget);
      expect(find.textContaining('Black to move'), findsOneWidget);
      await move(tester, 'e7', 'e5');
      expect(find.text('1. e4 e5'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.undo));
      await tester.pump();
      expect(find.text('1. e4'), findsOneWidget);
      expect(find.textContaining('Move taken back'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.redo));
      await tester.pump();
      expect(find.text('1. e4 e5'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.undo));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.undo));
      await tester.pump();
      expect(find.text('Moves'), findsNothing);
      expect(tester.takeException(), isNull);
      await leave(tester);
    });

    testWidgets('an illegal move is refused with a message', (tester) async {
      await pumpChess(tester);
      await move(tester, 'e2', 'e5');
      expect(find.text('1. e4'), findsNothing);
      expect(find.textContaining('not allowed'), findsOneWidget);
      await leave(tester);
    });

    testWidgets('castling by tapping the king, then the g-file square', (
      tester,
    ) async {
      await pumpChess(tester);
      for (final List<String> m in <List<String>>[
        <String>['e2', 'e4'],
        <String>['e7', 'e5'],
        <String>['g1', 'f3'],
        <String>['b8', 'c6'],
        <String>['f1', 'c4'],
        <String>['f8', 'c5'],
      ]) {
        await move(tester, m[0], m[1]);
      }
      await move(tester, 'e1', 'g1');
      expect(find.textContaining('O-O'), findsOneWidget);
      expect(find.textContaining('Black to move'), findsOneWidget);
      await leave(tester);
    });

    testWidgets("fool's mate ends the game and is recorded", (tester) async {
      final ProviderContainer c = await pumpChess(tester);
      for (final List<String> m in <List<String>>[
        <String>['f2', 'f3'],
        <String>['e7', 'e5'],
        <String>['g2', 'g4'],
        <String>['d8', 'h4'],
      ]) {
        await move(tester, m[0], m[1]);
      }
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('Checkmate. Black wins.'), findsWidgets);
      expect(find.text('Game over'), findsOneWidget);
      final GamesState s = c.read(gamesStoreProvider);
      expect(s.results.first.outcome, 'Checkmate: Black wins');
      expect(c.read(chessSettingsProvider.notifier).loadSaved(), isNull);
      await leave(tester);
    });

    testWidgets('a pawn reaching the end asks which piece to become', (
      tester,
    ) async {
      final SavedChess saved = SavedChess(
        mode: 2,
        level: 'beginner',
        humanWhite: true,
        uci: <String>[
          'h2h4', 'g7g5', 'h4g5', 'h7h6', 'g5h6', 'b8c6', 'h6h7', 'a7a6',
        ],
      );
      await pumpChess(
        tester,
        mode: 0,
        prefsValues: <String, Object>{ChessKeys.saved: saved.encode()},
      );
      await tester.tap(find.text('Resume your game'));
      await tester.pump();
      expect(find.textContaining('Game resumed'), findsOneWidget);
      await move(tester, 'h7', 'g8');
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Promote your pawn'), findsOneWidget);
      for (final String t in <String>['Queen', 'Rook', 'Bishop', 'Knight']) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      await tester.tap(find.text('Knight'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('hxg8=N'), findsOneWidget);
      await leave(tester);
    });

    testWidgets('auto-queen promotes without asking', (tester) async {
      final SavedChess saved = SavedChess(
        mode: 2,
        level: 'beginner',
        humanWhite: true,
        uci: <String>[
          'h2h4', 'g7g5', 'h4g5', 'h7h6', 'g5h6', 'b8c6', 'h6h7', 'a7a6',
        ],
      );
      await pumpChess(
        tester,
        mode: 0,
        prefsValues: <String, Object>{
          ChessKeys.saved: saved.encode(),
          ChessKeys.autoQueen: true,
        },
      );
      await tester.tap(find.text('Resume your game'));
      await tester.pump();
      await move(tester, 'h7', 'g8');
      expect(find.text('Promote your pawn'), findsNothing);
      expect(find.textContaining('hxg8=Q'), findsOneWidget);
      await leave(tester);
    });

    testWidgets('resign asks first, then ends the game', (tester) async {
      await pumpChess(tester);
      await move(tester, 'e2', 'e4');
      await tester.tap(find.byIcon(Icons.flag_outlined));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Black resigns?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Keep playing'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Game over'), findsNothing);
      await tester.tap(find.byIcon(Icons.flag_outlined));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.widgetWithText(TextButton, 'Resign'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Black resigned. White wins.'), findsWidgets);
      expect(find.text('Game over'), findsOneWidget);
      await leave(tester);
    });

    testWidgets('with Confirm resign off, resign is immediate', (tester) async {
      await pumpChess(
        tester,
        prefsValues: <String, Object>{ChessKeys.confirmResign: false},
      );
      await tester.tap(find.byIcon(Icons.flag_outlined));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Game over'), findsOneWidget);
      await leave(tester);
    });

    testWidgets('a draw offer can be accepted or declined', (tester) async {
      await pumpChess(tester);
      await tester.tap(find.byIcon(Icons.handshake_outlined));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('White offers a draw'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Decline'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('declined the draw'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.handshake_outlined));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.widgetWithText(TextButton, 'Accept draw'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Draw agreed.'), findsWidgets);
      await leave(tester);
    });

    testWidgets('a hint points at a legal move', (tester) async {
      await pumpChess(tester);
      await tester.tap(find.byIcon(Icons.lightbulb_outline));
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.textContaining('Hint: '), findsOneWidget);
      await leave(tester);
    });

    testWidgets('legal moves show when a piece is picked, unless turned off', (
      tester,
    ) async {
      await pumpChess(tester);
      await tapSq(tester, 'g1');
      expect(find.textContaining('no legal move'), findsNothing);
      await leave(tester);
      await pumpChess(
        tester,
        prefsValues: <String, Object>{ChessKeys.legal: false},
      );
      await tapSq(tester, 'g1');
      expect(tester.takeException(), isNull);
      await leave(tester);
    });
  });

  group('against Hadi', () {
    testWidgets('Hadi answers, the board never locks up, and undo takes back both', (
      tester,
    ) async {
      await pumpChess(tester, mode: 1);
      expect(find.textContaining('You are White'), findsOneWidget);
      await move(tester, 'e2', 'e4');
      await letHadiThink(tester);
      expect(find.textContaining('Your move'), findsOneWidget);
      expect(find.textContaining('1. e4 '), findsOneWidget);
      await tester.tap(find.byIcon(Icons.undo));
      await tester.pump();
      expect(find.text('Moves'), findsNothing);
      expect(tester.takeException(), isNull);
      await leave(tester);
    });

    testWidgets('playing Black: Hadi opens and the board is turned', (
      tester,
    ) async {
      await pumpChess(tester, mode: 1, playAs: 'black');
      expect(find.textContaining('You are Black'), findsOneWidget);
      await letHadiThink(tester);
      expect(find.textContaining('Your move'), findsOneWidget);
      expect(find.text('Moves'), findsOneWidget);
      // Turned board: the first rank number on the left is 1, the first
      // file letter under the board is H. Undo is off until the player has
      // moved (it would hand Hadi the opening again).
      expect(find.byType(ChessBoardView), findsOneWidget);
      expect(tester.takeException(), isNull);
      await leave(tester);
    });

    testWidgets('Hadi accepts or declines a draw by the game, not by luck', (
      tester,
    ) async {
      await pumpChess(tester, mode: 1);
      await tester.tap(find.byIcon(Icons.handshake_outlined));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Offer Hadi a draw?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Offer draw'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Hadi declines the draw'), findsOneWidget);
      await leave(tester);
    });
  });

  group('the clock', () {
    testWidgets('there is no clock unless one is chosen', (tester) async {
      await pumpChess(tester);
      expect(find.text('05:00'), findsNothing);
      await leave(tester);
    });

    testWidgets('a timed game counts down for the side to move', (
      tester,
    ) async {
      await pumpChess(tester, minutes: 5);
      expect(find.text('05:00'), findsNWidgets(2));
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('04:57'), findsOneWidget);
      expect(find.text('05:00'), findsOneWidget);
      await move(tester, 'e2', 'e4');
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('04:57'), findsOneWidget, reason: 'White stopped');
      expect(find.text('04:58'), findsOneWidget, reason: 'Black is running');
      await leave(tester);
    });

    testWidgets('undo is off in a timed game', (tester) async {
      await pumpChess(tester, minutes: 5);
      await move(tester, 'e2', 'e4');
      await tester.tap(find.byIcon(Icons.undo));
      await tester.pump();
      expect(find.text('1. e4'), findsOneWidget);
      await leave(tester);
    });
  });

  group('table menu', () {
    testWidgets('offers the three ways to play, the options and settings', (
      tester,
    ) async {
      await pumpChess(tester, mode: 0);
      for (final String t in <String>[
        'Play Hadi',
        'Two players',
        'Play a friend online',
        'Beginner',
        'Intermediate',
        'Advanced',
        'White',
        'Black',
        'Random',
        'No clock',
        'Chess settings',
      ]) {
        expect(find.text(t), findsWidgets, reason: t);
      }
      expect(find.textContaining('Castling and en passant are not'), findsNothing);
      await leave(tester);
    });
  });

  group('large text and Elder Mode', () {
    testWidgets('the table lays out on 360 px at 2x text', (tester) async {
      await pumpChess(tester, width: 360, scale: 2, minutes: 10);
      await move(tester, 'e2', 'e4');
      await move(tester, 'e7', 'e5');
      expect(tester.takeException(), isNull);
      await leave(tester);
    });

    testWidgets('the menu lays out on 360 px at 2x text', (tester) async {
      await pumpChess(tester, mode: 0, width: 360, scale: 2);
      expect(tester.takeException(), isNull);
      await leave(tester);
    });

    testWidgets('Elder Mode gets bigger round buttons and still works', (
      tester,
    ) async {
      await pumpChess(
        tester,
        width: 360,
        prefsValues: <String, Object>{ElderMode.pref: true},
      );
      await move(tester, 'd2', 'd4');
      expect(find.text('1. d4'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await leave(tester);
    });

    testWidgets('the modern piece style draws without any image', (tester) async {
      await pumpChess(
        tester,
        prefsValues: <String, Object>{ChessKeys.pieces: 'modern'},
      );
      await move(tester, 'e2', 'e4');
      expect(find.text('1. e4'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await leave(tester);
    });
  });
}
