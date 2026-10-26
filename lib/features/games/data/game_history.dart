/// What a finished game leaves behind, and how it is written to and read
/// from the device. Pure Dart. Nothing here leaves the device.
library;

import 'dart:convert';

import '../engine/game_registry.dart';

/// One finished (or abandoned) game, as the history shows it.
class GameResult {
  const GameResult({
    required this.id,
    required this.gameId,
    required this.title,
    required this.finishedMs,
    this.correct,
    this.total,
    this.players = 1,
    this.playerScores = const <int>[],
    this.difficulty,
    this.outcome,
    this.completed = true,
  });

  factory GameResult.fromJson(Map<String, dynamic> j) => GameResult(
        id: j['id'] as String,
        gameId: j['g'] as String,
        title: j['t'] as String,
        finishedMs: j['ts'] as int,
        correct: j['c'] as int?,
        total: j['n'] as int?,
        players: (j['p'] as int?) ?? 1,
        playerScores:
            ((j['ps'] as List<dynamic>?) ?? const <dynamic>[]).cast<int>(),
        difficulty: j['d'] as String?,
        outcome: j['o'] as String?,
        completed: (j['done'] as bool?) ?? true,
      );

  final String id;
  final String gameId;
  final String title;
  final int finishedMs;

  /// "8 of 10": right answers (or pairs found) and how many there were.
  final int? correct;
  final int? total;
  final int players;

  /// Right answers per player in a pass-and-play game.
  final List<int> playerScores;
  final String? difficulty;

  /// Board games: a neutral line such as "Checkmate: White won".
  final String? outcome;
  final bool completed;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'g': gameId,
        't': title,
        'ts': finishedMs,
        if (correct != null) 'c': correct,
        if (total != null) 'n': total,
        'p': players,
        if (playerScores.isNotEmpty) 'ps': playerScores,
        if (difficulty != null) 'd': difficulty,
        if (outcome != null) 'o': outcome,
        'done': completed,
      };

  /// The result line the history and results screens show.
  String get summary {
    if (outcome != null && correct == null) return outcome!;
    if (correct != null && total != null) return '$correct of $total';
    return outcome ?? '';
  }

  /// True for games in the Islamic section.
  bool get isIslamic => gameById(gameId)?.category == GameCategory.islamic;
}

/// Reads a saved history list. Anything unreadable is skipped, never thrown.
List<GameResult> decodeResults(String? raw) {
  if (raw == null || raw.isEmpty) return <GameResult>[];
  try {
    final dynamic d = json.decode(raw);
    if (d is! List<dynamic>) return <GameResult>[];
    final List<GameResult> out = <GameResult>[];
    for (final dynamic e in d) {
      try {
        out.add(GameResult.fromJson(e as Map<String, dynamic>));
      } catch (_) {
        // A bad row is dropped; the rest stay.
      }
    }
    return out;
  } catch (_) {
    return <GameResult>[];
  }
}

String encodeResults(List<GameResult> results) => json.encode(
      <dynamic>[for (final GameResult r in results) r.toJson()],
    );

/// [results] with [r] added at the front, newest first, capped at [limit].
List<GameResult> addResult(
  List<GameResult> results,
  GameResult r, {
  int limit = kHistoryLimit,
}) {
  final List<GameResult> out = <GameResult>[
    r,
    for (final GameResult e in results)
      if (e.id != r.id) e,
  ];
  return out.length > limit ? out.sublist(0, limit) : out;
}

/// A saved, unfinished quiz, as the hub's Continue row shows it.
class SavedGame {
  const SavedGame({
    required this.gameId,
    required this.answered,
    required this.total,
    required this.savedMs,
    required this.sessionJson,
  });

  final String gameId;
  final int answered;
  final int total;
  final int savedMs;

  /// The whole session, ready for `QuizSession.fromJson`.
  final String sessionJson;
}

/// The history filters.
enum HistoryFilter { all, islamic, completed, ongoing }

extension HistoryFilterLabel on HistoryFilter {
  String get label => switch (this) {
        HistoryFilter.all => 'All',
        HistoryFilter.islamic => 'Islamic',
        HistoryFilter.completed => 'Completed',
        HistoryFilter.ongoing => 'Ongoing',
      };
}

/// A plain date such as "26 Oct 2026".
String shortDate(int ms) {
  const List<String> m = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
  ];
  final DateTime d = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}
