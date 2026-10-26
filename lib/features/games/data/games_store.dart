import 'dart:async' show unawaited;
import 'dart:convert';

import 'package:flutter/widgets.dart' show BuildContext;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
import '../engine/game_registry.dart';
import '../engine/quiz_engine.dart';
import 'game_history.dart';

/// Where games keep what they remember. Device only: no account, no cloud,
/// no analytics. The history is capped at [kHistoryLimit] entries and each
/// quiz keeps at most one unfinished game.
abstract final class GamesKeys {
  static const String history = 'ar.games.history';
  static const String savedPrefix = 'ar.games.saved.';
  static String saved(String gameId) => '$savedPrefix$gameId';
}

/// Everything the Games screens read from the device.
class GamesState {
  const GamesState({
    this.results = const <GameResult>[],
    this.saved = const <SavedGame>[],
  });

  /// Finished games, newest first.
  final List<GameResult> results;

  /// Unfinished quizzes, newest first.
  final List<SavedGame> saved;
}

/// Loads and changes the history and the saved games. Every call is safe
/// without storage (a bare test, a browser with site data blocked): it
/// simply remembers nothing.
class GamesStoreController extends Notifier<GamesState> {
  SharedPreferences? _prefs() {
    try {
      return ref.read(sharedPreferencesProvider);
    } catch (_) {
      return null;
    }
  }

  @override
  GamesState build() {
    final SharedPreferences? p = _prefs();
    if (p == null) return const GamesState();
    return _read(p);
  }

  static GamesState _read(SharedPreferences p) {
    List<GameResult> results = <GameResult>[];
    final List<SavedGame> saved = <SavedGame>[];
    try {
      results = decodeResults(p.getString(GamesKeys.history));
      for (final GameDef g in kGames) {
        final String? raw = p.getString(GamesKeys.saved(g.id));
        if (raw == null) continue;
        try {
          final Map<String, dynamic> w = json.decode(raw) as Map<String, dynamic>;
          final Map<String, dynamic> s = w['s'] as Map<String, dynamic>;
          final List<dynamic> picks = s['picks'] as List<dynamic>;
          saved.add(SavedGame(
            gameId: g.id,
            answered: picks.where((dynamic e) => e != null).length,
            total: picks.length,
            savedMs: w['ts'] as int,
            sessionJson: json.encode(s),
          ));
        } catch (_) {
          // An unreadable save is ignored; the next save replaces it.
        }
      }
      saved.sort((SavedGame a, SavedGame b) => b.savedMs.compareTo(a.savedMs));
    } catch (_) {
      // No readable storage: nothing is remembered.
    }
    return GamesState(results: results, saved: saved);
  }

  /// Puts a finished game at the top of the history.
  Future<void> record(GameResult r) async {
    final SharedPreferences? p = _prefs();
    final List<GameResult> next = addResult(state.results, r);
    if (p != null) {
      try {
        await p.setString(GamesKeys.history, encodeResults(next));
      } catch (_) {}
    }
    state = GamesState(results: next, saved: state.saved);
  }

  /// Keeps an unfinished quiz so Continue can reopen it.
  Future<void> saveSession(QuizSession s) async {
    final SharedPreferences? p = _prefs();
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (p != null) {
      try {
        await p.setString(
          GamesKeys.saved(s.config.gameId),
          json.encode(<String, dynamic>{'ts': now, 's': s.toJson()}),
        );
      } catch (_) {}
    }
    state = p == null ? state : _read(p);
  }

  /// Drops the unfinished quiz of [gameId] (it was finished or abandoned).
  Future<void> clearSaved(String gameId) async {
    final SharedPreferences? p = _prefs();
    if (p != null) {
      try {
        await p.remove(GamesKeys.saved(gameId));
      } catch (_) {}
    }
    state = GamesState(
      results: state.results,
      saved: <SavedGame>[
        for (final SavedGame s in state.saved)
          if (s.gameId != gameId) s,
      ],
    );
  }

  /// Deletes the whole history and every unfinished game.
  Future<void> clearAll() async {
    final SharedPreferences? p = _prefs();
    if (p != null) {
      try {
        await p.remove(GamesKeys.history);
        for (final GameDef g in kGames) {
          await p.remove(GamesKeys.saved(g.id));
        }
      } catch (_) {}
    }
    state = const GamesState();
  }

  /// The unfinished quiz of [gameId], or null.
  QuizSession? savedSession(String gameId) {
    for (final SavedGame s in state.saved) {
      if (s.gameId != gameId) continue;
      try {
        return QuizSession.fromJson(
          json.decode(s.sessionJson) as Map<String, dynamic>,
        );
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

final NotifierProvider<GamesStoreController, GamesState> gamesStoreProvider =
    NotifierProvider<GamesStoreController, GamesState>(
  GamesStoreController.new,
);

/// Records a finished board game from a screen that is not a Riverpod
/// widget (Ludo, Shatranj). Never throws; remembers nothing without storage.
void recordBoardResult(
  BuildContext context, {
  required String gameId,
  required String title,
  required String outcome,
  int players = 2,
}) {
  try {
    final ProviderContainer c = ProviderScope.containerOf(context, listen: false);
    final int now = DateTime.now().millisecondsSinceEpoch;
    unawaited(
      c.read(gamesStoreProvider.notifier).record(
            GameResult(
              id: '$gameId-$now',
              gameId: gameId,
              title: title,
              finishedMs: now,
              players: players,
              outcome: outcome,
            ),
          ),
    );
  } catch (_) {}
}
