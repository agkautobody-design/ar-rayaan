import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/gold_button.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../data/game_invite.dart';
import '../data/game_rooms_service.dart';
import '../data/race_link.dart';
import '../data/race_protocol.dart';
import '../engine/game_registry.dart';
import 'game_invite_screen.dart' show sendGameInvite;
import 'online_lobby.dart';

/// The table before a race: the host gets a link to send and waits, the guest
/// joins and waits for the host's settings. When both are seated, both go
/// straight to the same game.
class RaceTableScreen extends StatefulWidget {
  /// Host: [gameId] and its settings [query].
  const RaceTableScreen.host({
    required String this.gameId,
    required Map<String, String> this.query,
    super.key,
    this.service,
  }) : joinCode = null;

  /// Guest: joins the table [joinCode].
  const RaceTableScreen.guest({
    required String this.joinCode,
    super.key,
    this.service,
  })  : gameId = null,
        query = null;

  final String? gameId;
  final Map<String, String>? query;
  final String? joinCode;
  final GameRoomsService? service;

  @override
  State<RaceTableScreen> createState() => _RaceTableState();
}

class _RaceTableState extends State<RaceTableScreen> {
  late final GameRoomsService _rooms = widget.service ?? GameRoomsService();
  RaceLink? _link;
  String? _code;
  String? _error;
  String _busy = 'Setting up the table…';
  bool _going = false;
  int _seed = 0;

  bool get _host => widget.joinCode == null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_start()));
  }

  @override
  void dispose() {
    final RaceLink? l = _link;
    if (l != null) {
      // Leaving before the game starts closes the table.
      if (!_going) unawaited(l.leave());
      l.state.removeListener(_onState);
      l.dispose();
    }
    super.dispose();
  }

  Future<void> _start() async {
    if (!await OnlineLobby.gate(context) || !mounted) {
      if (mounted) context.go('/games');
      return;
    }
    try {
      final Map<String, dynamic>? r = _host
          ? await _rooms.createRoom(RaceProtocol.tableGame)
          : await _rooms.joinRoom(widget.joinCode!);
      if (!mounted) return;
      if (r == null) {
        setState(() {
          _busy = '';
          _error = 'Online play is not available in this build, or you are '
              'offline.';
        });
        return;
      }
      final Object? err = r['error'];
      final Object? code = r['code'];
      if (err is String || code is! String) {
        setState(() {
          _busy = '';
          _error = err is String ? err : 'Could not open the table.';
        });
        return;
      }
      final RaceLink link = RaceLink(
        code: code,
        side: _host ? 'host' : 'guest',
        rooms: _rooms,
      );
      link.state.addListener(_onState);
      link.listen();
      if (_host) {
        _seed = RaceProtocol.newSeed();
        unawaited(link.sendConfig(widget.gameId!, widget.query!, _seed));
      }
      setState(() {
        _link = link;
        _code = code;
        _busy = _host ? '' : 'Waiting for the game to start…';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = '';
        _error = OnlineLobby.describe(e);
      });
    }
  }

  void _onState() {
    final RaceLink? l = _link;
    if (l == null || _going || !mounted) return;
    final RaceState s = l.state.value;
    if (s.left) {
      setState(() => _error = 'The table was closed.');
      return;
    }
    if (!s.joined) return;
    if (_host) {
      _go(widget.gameId!, widget.query!, _seed);
    } else {
      final RaceConfig? c = s.config;
      if (c != null && gameById(c.gameId) != null) {
        _go(c.gameId, c.query, c.seed);
      }
    }
  }

  void _go(String gameId, Map<String, String> query, int seed) {
    _going = true;
    final Map<String, String> race = <String, String>{
      'race': _code!,
      'side': _host ? 'host' : 'guest',
      'seed': '$seed',
    };
    final Uri u = gameId == 'lineage'
        ? Uri(path: '/games/lineage', queryParameters: race)
        : gameId == 'memory'
        ? Uri(
            path: '/games/memory',
            queryParameters: <String, String>{
              'pairs': query['pairs'] ?? '8',
              'players': '1',
              ...race,
            },
          )
        : Uri(
            path: '/games/g/$gameId/play',
            queryParameters: <String, String>{
              ...query,
              'hints': '0',
              'players': '1',
              ...race,
            },
          );
    context.pushReplacement(u.toString());
  }

  String get _title {
    final String? id = widget.gameId;
    return (id == null ? null : gameById(id)?.title) ?? 'a game';
  }

  Future<void> _send() async {
    final String? code = _code;
    if (code == null) return;
    final String text = GameInvite.raceMessage(_title, code);
    await sendGameInvite(context, text);
  }

  @override
  Widget build(BuildContext context) {
    final String? code = _code;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: <Widget>[
              ScreenHeader(
                title: _host ? 'Play with a friend' : 'Joining a friend',
                close: true,
                showSettings: false,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!,
                      key: const Key('race-error'),
                      style: AppText.bodyMuted
                          .copyWith(color: Colors.orangeAccent)),
                )
              else if (_busy.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(children: <Widget>[
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.gold),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_busy, style: AppText.bodyMuted)),
                  ]),
                ),
              if (_host && code != null && _error == null) ...<Widget>[
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text('YOUR TABLE: ${_title.toUpperCase()}',
                          style: AppText.eyebrow),
                      const SizedBox(height: 8),
                      SelectableText(
                        code,
                        key: const Key('race-code'),
                        textAlign: TextAlign.center,
                        style: AppText.titleMedium
                            .copyWith(fontSize: 32, letterSpacing: 6),
                      ),
                      const SizedBox(height: 10),
                      SelectableText(
                        GameInvite.raceMessage(_title, code),
                        key: const Key('race-preview'),
                        style:
                            AppText.body.copyWith(fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GoldButton(label: 'Send the invite', onPressed: _send),
                const SizedBox(height: 10),
                Text(
                  'The game starts for both of you as soon as your friend '
                  'opens the link. You answer the same questions and see '
                  'each other’s score as you go. No name is shared.',
                  style: AppText.bodyMuted.copyWith(fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
