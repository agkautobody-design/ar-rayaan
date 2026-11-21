import '../../share/application/share_text.dart' show kInviteUrl;

/// A game a person can invite a friend to play online.
enum InviteGame {
  shatranj('shatranj', 'Chess (Shatranj)'),
  ludo('ludo', 'Ludo');

  const InviteGame(this.id, this.label);
  final String id;
  final String label;
}

/// The invite to a game table: a plain, friendly message with a link that
/// opens the free web app straight into the table, and the six-letter code as
/// a fallback. It is only an invitation to play; it asks for no account and
/// says nothing about the sender. The table is deleted when someone leaves
/// and after six hours.
abstract final class GameInvite {
  static final RegExp _codeRe = RegExp(r'^[A-Z0-9]{4,8}$');

  /// [code] upper-cased and trimmed, or null when it is not a table code.
  static String? cleanCode(String? code) {
    final String c = (code ?? '').trim().toUpperCase();
    return _codeRe.hasMatch(c) ? c : null;
  }

  /// The game for [id], or null.
  static InviteGame? gameFor(String id) {
    for (final InviteGame g in InviteGame.values) {
      if (g.id == id) return g;
    }
    return null;
  }

  /// The link that opens the table for a guest.
  static String link(InviteGame game, String code) =>
      '$kInviteUrl/#/games/${game.id}?room=$code&side=guest';

  static String message(InviteGame game, String code) =>
      'Come and play ${game.label} with me on Ar-Rayaan. It is a free game '
      'and needs no account.\n\n'
      'Tap to join my table: ${link(game, code)}\n\n'
      'Or open the app, choose Play online, and enter the code $code.';
}
