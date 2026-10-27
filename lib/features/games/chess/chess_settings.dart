import 'dart:async' show unawaited;
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';

/// The board looks of the owner's design. Royal marble (black and cream) is
/// the default; green and blue are marble pictures too; classic wood and grey
/// still use the older textured squares until their pictures arrive.
enum ChessBoardTheme { royal, green, blue, grey, classic }

extension ChessBoardThemeInfo on ChessBoardTheme {
  String get label => switch (this) {
        ChessBoardTheme.royal => 'Royal marble',
        ChessBoardTheme.classic => 'Classic wood',
        ChessBoardTheme.green => 'Green marble',
        ChessBoardTheme.blue => 'Blue marble',
        ChessBoardTheme.grey => 'Grey and black',
      };
}

/// Classic: the owner's glossy gold and black pieces. Modern: flat vector
/// silhouettes drawn in code.
enum ChessPieceStyle { classic, modern }

extension ChessPieceStyleInfo on ChessPieceStyle {
  String get label => switch (this) {
        ChessPieceStyle.classic => 'Classic',
        ChessPieceStyle.modern => 'Modern',
      };
}

abstract final class ChessKeys {
  static const String theme = 'ar.chess.theme';
  static const String pieces = 'ar.chess.pieces';
  static const String sound = 'ar.chess.sound';
  static const String legal = 'ar.chess.legal';
  static const String autoQueen = 'ar.chess.autoqueen';
  static const String confirmResign = 'ar.chess.confirmresign';
  static const String autoSave = 'ar.chess.autosave';
  static const String saved = 'ar.chess.saved';
}

/// What the player chose in Chess Settings. Everything is kept on this
/// device only. Sound is off until the player turns it on.
class ChessSettings {
  const ChessSettings({
    this.theme = ChessBoardTheme.royal,
    this.pieces = ChessPieceStyle.classic,
    this.sound = false,
    this.showLegalMoves = true,
    this.autoQueen = false,
    this.confirmResign = true,
    this.autoSave = true,
  });

  final ChessBoardTheme theme;
  final ChessPieceStyle pieces;
  final bool sound;
  final bool showLegalMoves;
  final bool autoQueen;
  final bool confirmResign;
  final bool autoSave;

  ChessSettings copyWith({
    ChessBoardTheme? theme,
    ChessPieceStyle? pieces,
    bool? sound,
    bool? showLegalMoves,
    bool? autoQueen,
    bool? confirmResign,
    bool? autoSave,
  }) {
    return ChessSettings(
      theme: theme ?? this.theme,
      pieces: pieces ?? this.pieces,
      sound: sound ?? this.sound,
      showLegalMoves: showLegalMoves ?? this.showLegalMoves,
      autoQueen: autoQueen ?? this.autoQueen,
      confirmResign: confirmResign ?? this.confirmResign,
      autoSave: autoSave ?? this.autoSave,
    );
  }
}

/// An unfinished local game, kept so it can be resumed.
class SavedChess {
  const SavedChess({
    required this.mode,
    required this.level,
    required this.humanWhite,
    required this.uci,
    this.fen,
  });

  /// 1 = against Hadi, 2 = two players on this device.
  final int mode;

  /// ChessLevel name.
  final String level;
  final bool humanWhite;
  final List<String> uci;
  final String? fen;

  String encode() => json.encode(<String, Object?>{
        'v': 1,
        'mode': mode,
        'level': level,
        'white': humanWhite,
        'uci': uci,
        'fen': fen,
      });

  static SavedChess? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final Object? d = json.decode(raw);
      if (d is! Map<String, dynamic>) return null;
      final Object? mode = d['mode'];
      final Object? level = d['level'];
      final Object? white = d['white'];
      final Object? uci = d['uci'];
      if (mode is! int || (mode != 1 && mode != 2)) return null;
      if (level is! String || white is! bool || uci is! List<dynamic>) {
        return null;
      }
      final Object? fen = d['fen'];
      return SavedChess(
        mode: mode,
        level: level,
        humanWhite: white,
        uci: <String>[for (final Object? s in uci) if (s is String) s],
        fen: fen is String ? fen : null,
      );
    } catch (_) {
      return null;
    }
  }
}

class ChessSettingsController extends Notifier<ChessSettings> {
  SharedPreferences? _prefs() {
    try {
      return ref.read(sharedPreferencesProvider);
    } catch (_) {
      return null;
    }
  }

  @override
  ChessSettings build() {
    final SharedPreferences? p = _prefs();
    if (p == null) return const ChessSettings();
    try {
      ChessBoardTheme theme = ChessBoardTheme.royal;
      for (final ChessBoardTheme t in ChessBoardTheme.values) {
        if (t.name == p.getString(ChessKeys.theme)) theme = t;
      }
      ChessPieceStyle pieces = ChessPieceStyle.classic;
      for (final ChessPieceStyle s in ChessPieceStyle.values) {
        if (s.name == p.getString(ChessKeys.pieces)) pieces = s;
      }
      return ChessSettings(
        theme: theme,
        pieces: pieces,
        sound: p.getBool(ChessKeys.sound) ?? false,
        showLegalMoves: p.getBool(ChessKeys.legal) ?? true,
        autoQueen: p.getBool(ChessKeys.autoQueen) ?? false,
        confirmResign: p.getBool(ChessKeys.confirmResign) ?? true,
        autoSave: p.getBool(ChessKeys.autoSave) ?? true,
      );
    } catch (_) {
      return const ChessSettings();
    }
  }

  void update(ChessSettings next) {
    state = next;
    final SharedPreferences? p = _prefs();
    if (p == null) return;
    unawaited(_write(p, next));
  }

  Future<void> _write(SharedPreferences p, ChessSettings s) async {
    try {
      await p.setString(ChessKeys.theme, s.theme.name);
      await p.setString(ChessKeys.pieces, s.pieces.name);
      await p.setBool(ChessKeys.sound, s.sound);
      await p.setBool(ChessKeys.legal, s.showLegalMoves);
      await p.setBool(ChessKeys.autoQueen, s.autoQueen);
      await p.setBool(ChessKeys.confirmResign, s.confirmResign);
      await p.setBool(ChessKeys.autoSave, s.autoSave);
    } catch (_) {}
  }

  /// The unfinished game on this device, if any.
  SavedChess? loadSaved() {
    try {
      return SavedChess.decode(_prefs()?.getString(ChessKeys.saved));
    } catch (_) {
      return null;
    }
  }

  void saveGame(SavedChess game) {
    final SharedPreferences? p = _prefs();
    if (p == null) return;
    unawaited(_safe(() => p.setString(ChessKeys.saved, game.encode())));
  }

  void clearSaved() {
    final SharedPreferences? p = _prefs();
    if (p == null) return;
    unawaited(_safe(() => p.remove(ChessKeys.saved)));
  }

  Future<void> _safe(Future<bool> Function() f) async {
    try {
      await f();
    } catch (_) {}
  }
}

final NotifierProvider<ChessSettingsController, ChessSettings>
    chessSettingsProvider =
    NotifierProvider<ChessSettingsController, ChessSettings>(
  ChessSettingsController.new,
);
