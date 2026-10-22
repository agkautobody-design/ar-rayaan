import 'dart:io';

import 'package:ar_rayaan/features/games/data/game_rooms_service.dart';
import 'package:ar_rayaan/features/majlis/data/majlis_service.dart';
import 'package:ar_rayaan/features/majlis/domain/majlis_policy.dart';
import 'package:flutter_test/flutter_test.dart';

/// There is no Firestore emulator in CI, so the rules file cannot be
/// executed here. These tests pin what the rules are meant to guarantee
/// (P1-7, P1-8) by reading `firestore.rules`, and check the app side of
/// each contract. The owner publishes the file (docs/OWNER_ACTIONS.md).
void main() {
  final String rules = File('firestore.rules').readAsStringSync();

  String block(String start) {
    final int at = rules.indexOf(start);
    expect(at, greaterThan(0), reason: start);
    var depth = 0;
    var i = rules.indexOf('{', at + start.length);
    final int begin = i;
    for (; i < rules.length; i++) {
      if (rules[i] == '{') depth++;
      if (rules[i] == '}') {
        depth--;
        if (depth == 0) break;
      }
    }
    return rules.substring(begin, i + 1);
  }

  test('the rules file is balanced', () {
    for (final List<String> p in <List<String>>[
      <String>['{', '}'],
      <String>['(', ')'],
      <String>['[', ']'],
    ]) {
      expect(p[0].allMatches(rules).length, p[1].allMatches(rules).length,
          reason: p.join());
    }
  });

  group('game_rooms', () {
    late String rooms;
    setUpAll(() => rooms = block('match /game_rooms/{code}'));

    test('rooms can be fetched by code but never listed or deleted', () {
      expect(rooms, contains('allow get: if signedIn()'));
      expect(rooms, contains('allow list: if false'));
      expect(rooms, contains('allow delete: if false'));
      expect(rooms.contains('allow read:'), isFalse);
    });

    test('create is an exact field allow-list with server time and a TTL', () {
      expect(rooms, contains("code.matches('[A-HJ-NP-Z2-9]{6}')"));
      expect(rooms, contains('keys().hasOnly('));
      expect(rooms, contains('keys().hasAll('));
      expect(rooms, contains("game in ['ludo', 'shatranj']"));
      expect(rooms, contains('createdAt == request.time'));
      expect(rooms, contains('expireAt'));
      expect(rooms, contains('request.resource.data.guest == null'));
      expect(rooms, contains('moves.size() == 0'));
    });

    test('a joiner may change only guest, status and lastTs', () {
      expect(rooms, contains("hasOnly(['guest', 'status', 'lastTs'])"));
      expect(rooms, contains('resource.data.guest == null'));
      expect(rooms, contains('request.auth.uid != roomHostUid()'));
    });

    test('players write a short list of fields and one new move at a time',
        () {
      expect(rooms,
          contains("hasOnly(['moves', 'turn', 'status', 'result', 'lastTs'])"));
      // roomMovesOk() lives beside the match block, which calls it.
      expect(rooms, contains('roomMovesOk()'));
      expect(rules, contains('addedKeys().size() == 1'));
      expect(rules, contains('changedKeys().size() == 0'));
      expect(rules, contains('removedKeys().size() == 0'));
      expect(rooms, contains("resource.data.status in ['waiting', 'playing']"));
    });

    test('the game codes the app creates satisfy the create rule', () {
      final RegExp rx = RegExp(r'^[A-HJ-NP-Z2-9]{6}$');
      for (var i = 0; i < 500; i++) {
        expect(rx.hasMatch(GameRoomsService.newCode()), isTrue);
      }
    });

    test('the app writes numbered moves, not an arrayUnion list', () {
      final String svc = File('lib/features/games/data/game_rooms_service.dart')
          .readAsStringSync();
      expect(svc.contains('arrayUnion'), isFalse);
      expect(svc, contains("'moves.\${RoomMoves.keyOf(seq)}'"));
      expect(svc, contains('FieldValue.serverTimestamp()'));
    });
  });

  group('Majlis rules', () {
    test('threads and posts exist only in the Courtyard', () {
      expect(rules, contains("room == 'courtyard'"));
      expect(RegExp(r'knownRoom\(room\)').allMatches(rules).length,
          greaterThanOrEqualTo(4));
    });

    test('reads are bounded', () {
      expect(rules, contains('allow list: if request.query.limit <= 100'));
      expect(rules, contains('allow list: if request.query.limit <= 300'));
    });

    test('the app asks for no more than the rules allow', () {
      expect(MajlisService.threadLimit, lessThanOrEqualTo(100));
      expect(MajlisService.postLimit, lessThanOrEqualTo(300));
    });

    test('names are folded for digits and limited to safe characters', () {
      expect(rules, contains('function foldedName'));
      expect(rules, contains('function authorCharsOk'));
      expect(rules, contains('administrator'));
    });
  });

  group('display name characters (mirrors authorCharsOk)', () {
    test('plain, Arabic and Urdu names pass', () {
      for (final String n in <String>[
        'Umm Yusuf',
        "O'Brien",
        'Abd-Allah',
        'Ahmed_2',
        'عبد الله',
        'احمد خان',
      ]) {
        expect(MajlisPolicy.validateName(n), isNull, reason: n);
      }
    });

    test('look-alikes, accents and emoji are refused', () {
      for (final String n in <String>[
        'Hаdi', // Cyrillic a
        'Hādi',
        'Zoë',
        'Amina \u{1F600}',
        'Bil​al', // zero-width space
      ]) {
        expect(MajlisPolicy.validateName(n), isNotNull, reason: n);
      }
    });
  });
}
