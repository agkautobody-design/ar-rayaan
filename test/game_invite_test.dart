import 'package:flutter_test/flutter_test.dart';

import 'package:ar_rayaan/features/games/data/game_invite.dart';

void main() {
  group('GameInvite', () {
    test('link opens the table for a guest', () {
      expect(
        GameInvite.link(InviteGame.ludo, 'ABC234'),
        'https://ar-rayaan.onrender.com/#/games/ludo?room=ABC234&side=guest',
      );
      expect(
        GameInvite.link(InviteGame.shatranj, 'XYZ789'),
        contains('/#/games/shatranj?room=XYZ789&side=guest'),
      );
    });

    test('message is only an invitation to play', () {
      final String m = GameInvite.message(InviteGame.ludo, 'ABC234');
      expect(m, contains('Ludo'));
      expect(m, contains('ABC234'));
      expect(m, contains('free'));
      expect(m, contains('no account'));
      for (final String bad in <String>[
        'Islam', 'Muslim', 'Quran', "Qur'an", 'pray', 'Allah', 'convert',
      ]) {
        expect(m.toLowerCase(), isNot(contains(bad.toLowerCase())));
      }
    });

    test('cleanCode accepts table codes only', () {
      expect(GameInvite.cleanCode(' abc234 '), 'ABC234');
      expect(GameInvite.cleanCode(null), isNull);
      expect(GameInvite.cleanCode(''), isNull);
      expect(GameInvite.cleanCode('ab'), isNull);
      expect(GameInvite.cleanCode('ABC 234'), isNull);
      expect(GameInvite.cleanCode('<script>'), isNull);
    });

    test('gameFor maps ids', () {
      expect(GameInvite.gameFor('ludo'), InviteGame.ludo);
      expect(GameInvite.gameFor('shatranj'), InviteGame.shatranj);
      expect(GameInvite.gameFor('tetris'), isNull);
    });
  });
}
