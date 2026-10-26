import 'dart:async';

import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/games/data/game_rooms_service.dart';
import 'package:ar_rayaan/features/games/presentation/online_lobby.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A hall whose network behaviour the test decides.
class _FakeRooms extends GameRoomsService {
  _FakeRooms({this.create, this.join});

  Future<Map<String, dynamic>?> Function()? create;
  Future<Map<String, dynamic>?> Function(String code)? join;
  int createCalls = 0;
  int joinCalls = 0;

  @override
  Future<Map<String, dynamic>?> createRoom(String game) {
    createCalls++;
    return create!();
  }

  @override
  Future<Map<String, dynamic>?> joinRoom(String code) {
    joinCalls++;
    return join!(code);
  }
}

/// P1-5: the lobby used to await the network with no try/catch, so an
/// offline or refused call left a spinner forever.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, String>? result;

  Future<void> open(WidgetTester tester, GameRoomsService service) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    result = null;
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () async {
              result = await OnlineLobby.show(context, 'ludo', service);
            },
            child: const Text('open lobby'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open lobby'));
    await tester.pumpAndSettle();
  }

  testWidgets('a timed-out create shows a plain message, stops the spinner '
      'and offers a retry that works', (tester) async {
    var fail = true;
    final _FakeRooms rooms = _FakeRooms(
      create: () async {
        if (fail) throw TimeoutException('no answer');
        return <String, dynamic>{'code': 'K7Q2MX', 'side': 'host'};
      },
    );
    await open(tester, rooms);

    await tester.tap(find.textContaining('Create a table'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('did not answer in time'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Try again'), findsOneWidget);
    // Both buttons are usable again.
    expect(rooms.createCalls, 1);

    fail = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(rooms.createCalls, 2);
    expect(result, <String, String>{'code': 'K7Q2MX', 'side': 'host'});
  });

  testWidgets('a refused join is explained, not a permanent spinner',
      (tester) async {
    final _FakeRooms rooms = _FakeRooms(
      join: (String code) async =>
          throw StateError('[cloud_firestore/permission-denied] denied'),
    );
    await open(tester, rooms);

    await tester.enterText(find.byType(TextField), 'K7Q2MX');
    await tester.tap(find.text('Join'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('could not be opened just now'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(rooms.joinCalls, 1);
  });

  testWidgets('an empty code asks for the code and makes no network call',
      (tester) async {
    final _FakeRooms rooms = _FakeRooms(join: (String code) async => null);
    await open(tester, rooms);

    await tester.tap(find.text('Join'));
    await tester.pump();

    expect(find.textContaining('six-letter code'), findsWidgets);
    expect(rooms.joinCalls, 0);
  });

  testWidgets('a table that is missing shows the reason from the server',
      (tester) async {
    final _FakeRooms rooms = _FakeRooms(
      join: (String code) async => <String, dynamic>{'error': 'Room not found'},
    );
    await open(tester, rooms);

    await tester.enterText(find.byType(TextField), 'ZZZZZZ');
    await tester.tap(find.text('Join'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Room not found'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('online play unavailable in this build says so', (tester) async {
    final _FakeRooms rooms = _FakeRooms(create: () async => null);
    await open(tester, rooms);

    await tester.tap(find.textContaining('Create a table'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('not available in this build'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  group('describe', () {
    test('plain words for each kind of failure', () {
      expect(OnlineLobby.describe(TimeoutException('x')),
          contains('did not answer'));
      expect(OnlineLobby.describe(StateError('permission-denied')),
          contains('could not be opened'));
      expect(OnlineLobby.describe(StateError('network error')),
          contains('offline'));
      expect(OnlineLobby.describe(StateError('???')),
          contains('Something went wrong'));
    });
  });
}
