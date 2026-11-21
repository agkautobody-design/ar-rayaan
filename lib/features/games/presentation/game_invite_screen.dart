import 'dart:async' show unawaited;

import 'package:flutter/material.dart' hide Text;
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/gold_button.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../../share/application/share_service.dart';
import '../../share/presentation/share_actions.dart' show copyWithFeedback;
import '../data/game_invite.dart';
import '../data/game_rooms_service.dart';
import 'online_lobby.dart';

/// Invite a friend to play. Pick a game, get a table and a link, send it by
/// any app. The friend opens the link, the free web app opens at the table
/// and they play, with no account. It is only an invitation to play: the
/// message says nothing about the sender and asks for nothing.
/// Sends an invitation [text]: the share sheet when there is one, else it is
/// copied. The one place a game invitation leaves the app (the screens that
/// make an invitation call this).
Future<void> sendGameInvite(BuildContext context, String text) async {
  final bool shared =
      await ShareService.shareText(text, subject: 'Come and play with me');
  if (!shared && context.mounted) await copyWithFeedback(context, text);
}

class GameInviteScreen extends StatefulWidget {
  const GameInviteScreen({super.key, this.service, this.initialGame});

  /// Skips the choice when the person came from a game's own page.
  final InviteGame? initialGame;

  /// For tests.
  final GameRoomsService? service;

  @override
  State<GameInviteScreen> createState() => _GameInviteScreenState();
}

class _GameInviteScreenState extends State<GameInviteScreen> {
  late final GameRoomsService _rooms = widget.service ?? GameRoomsService();
  InviteGame? _game;
  String? _code;
  String? _busy;
  String? _error;
  bool _entered = false;

  @override
  void initState() {
    super.initState();
    final InviteGame? g = widget.initialGame;
    if (g != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_pick(g)));
    }
  }

  @override
  void dispose() {
    // An invitation that was never taken to the table leaves nothing behind.
    final String? code = _code;
    if (code != null && !_entered) unawaited(_rooms.leave(code));
    super.dispose();
  }

  Future<void> _pick(InviteGame g) async {
    if (!await OnlineLobby.gate(context) || !mounted) return;
    setState(() {
      _busy = 'Setting up your table…';
      _error = null;
    });
    try {
      final Map<String, dynamic>? r = await _rooms.createRoom(g.id);
      if (!mounted) return;
      final Object? code = r?['code'];
      if (r == null || code is! String) {
        setState(() {
          _busy = null;
          _error = 'Online play is not available in this build, or you are '
              'offline. You can still play on this device.';
        });
        return;
      }
      setState(() {
        _busy = null;
        _game = g;
        _code = code;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = null;
        _error = OnlineLobby.describe(e);
      });
    }
  }

  Future<void> _send() async {
    final InviteGame? g = _game;
    final String? code = _code;
    if (g == null || code == null) return;
    final String text = GameInvite.message(g, code);
    final bool shared =
        await ShareService.shareText(text, subject: 'Come and play with me');
    if (!shared && mounted) {
      await copyWithFeedback(context, text);
    }
  }

  void _enter() {
    final InviteGame? g = _game;
    final String? code = _code;
    if (g == null || code == null) return;
    _entered = true;
    context.pushReplacement('/games/${g.id}?room=$code&side=host');
  }

  @override
  Widget build(BuildContext context) {
    final InviteGame? g = _game;
    final String? code = _code;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: <Widget>[
              const ScreenHeader(title: 'Invite a friend to play'),
              if (g == null || code == null) ...<Widget>[
                Text(
                  'Pick a game and send your friend a link. They open it, the '
                  'game starts in their browser, and you play together. Free, '
                  'no account.',
                  style: AppText.bodyMuted.copyWith(height: 1.5),
                ),
                const SizedBox(height: 14),
                if (_busy != null)
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
                      Expanded(child: Text(_busy!, style: AppText.bodyMuted)),
                    ]),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!,
                        key: const Key('invite-error'),
                        style: AppText.bodyMuted
                            .copyWith(color: Colors.orangeAccent)),
                  ),
                for (final InviteGame game in InviteGame.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      child: ListTile(
                        key: Key('invite-pick-${game.id}'),
                        contentPadding: EdgeInsets.zero,
                        minVerticalPadding: 12,
                        title: Text(game.label, style: AppText.titleMedium),
                        subtitle: Text('Two players, one table',
                            style: AppText.bodyMuted),
                        trailing: const Icon(Icons.chevron_right,
                            color: AppColors.gold),
                        enabled: _busy == null,
                        onTap: () => _pick(game),
                      ),
                    ),
                  ),
              ] else ...<Widget>[
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text('YOUR TABLE: ${g.label.toUpperCase()}',
                          style: AppText.eyebrow),
                      const SizedBox(height: 8),
                      SelectableText(
                        code,
                        key: const Key('invite-code'),
                        textAlign: TextAlign.center,
                        style: AppText.titleMedium
                            .copyWith(fontSize: 32, letterSpacing: 6),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'This is exactly what your friend gets:',
                        style: AppText.bodyMuted.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        GameInvite.message(g, code),
                        key: const Key('invite-preview'),
                        style: AppText.body.copyWith(fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GoldButton(label: 'Send the invite', onPressed: _send),
                const SizedBox(height: 8),
                OutlinedButton(
                  key: const Key('invite-copy'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: () =>
                      copyWithFeedback(context, GameInvite.message(g, code)),
                  child: const Text('Copy the invite'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  key: const Key('invite-enter'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: _enter,
                  child: const Text('Go to my table and wait'),
                ),
                const SizedBox(height: 10),
                Text(
                  'No name is shared. The table closes when someone leaves, '
                  'and after six hours.',
                  style: AppText.bodyMuted.copyWith(fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
