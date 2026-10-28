import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../academy/presentation/widgets/parent_gate.dart';
import '../data/game_rooms_service.dart';
import '../data/online_access.dart';

/// The Online Hall lobby — create a room and share the code, or join one.
/// Pops {'code','side'} on success; null on cancel.
class OnlineLobby extends StatefulWidget {
  final String game;
  final GameRoomsService service;
  const OnlineLobby({super.key, required this.game, required this.service});

  /// Opens the lobby, after the family check: a child profile reaches it
  /// only when a guardian has switched online tables on for that child, and
  /// an adult on a device that has child profiles answers the parent check
  /// first. [access] is for tests.
  static Future<Map<String, String>?> show(
    BuildContext context,
    String game,
    GameRoomsService service, {
    OnlineAccess? access,
  }) async {
    final OnlineAccess gate = access ?? OnlineAccess();
    final OnlineVerdict verdict = await gate.check();
    if (!context.mounted) return null;
    if (verdict.blocked) {
      await showDialog<void>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          semanticLabel: 'Online tables are off',
          backgroundColor: const Color(0xFF0A0F18),
          title: Text('Online tables are off', style: AppText.titleMedium),
          content: Text(verdict.message, style: AppText.bodyMuted),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return null;
    }
    if (verdict.needsParent) {
      final bool ok = await showParentGate(context);
      if (!ok || !context.mounted) return null;
    }
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A0F18),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: OnlineLobby(game: game, service: service),
      ),
    );
  }

  /// What to tell the person when a call failed, in plain words.
  static String describe(Object e) {
    final String t = e.toString().toLowerCase();
    if (e is TimeoutException || t.contains('timeout')) {
      return 'The table did not answer in time. Check your connection and '
          'try again.';
    }
    if (t.contains('permission-denied') || t.contains('permission_denied')) {
      return 'The table could not be opened just now. Please try again in a '
          'moment.';
    }
    if (t.contains('unavailable') || t.contains('network')) {
      return 'You seem to be offline. Check your connection and try again.';
    }
    return 'Something went wrong opening the table. Please try again.';
  }

  @override
  State<OnlineLobby> createState() => _OnlineLobbyState();
}

class _OnlineLobbyState extends State<OnlineLobby> {
  String? _busy;
  String? _error;
  bool _canRetry = false;
  Future<void> Function()? _retry;
  final _joinCtrl = TextEditingController();

  @override
  void dispose() {
    _joinCtrl.dispose();
    super.dispose();
  }

  static const String _unavailable = 'Online play is not available in this '
      'build, or you are offline. You can still play on this device.';

  Future<void> _create() async {
    _retry = _create;
    setState(() { _busy = 'Creating your table\u2026'; _error = null; });
    try {
      final r = await widget.service.createRoom(widget.game);
      if (!mounted) return;
      if (r == null) {
        setState(() { _busy = null; _error = _unavailable; _canRetry = false; });
        return;
      }
      Navigator.of(context).pop({'code': r['code'] as String, 'side': 'host'});
    } catch (e) {
      if (!mounted) return;
      setState(() { _busy = null; _error = OnlineLobby.describe(e); _canRetry = true; });
    }
  }

  Future<void> _join() async {
    _retry = _join;
    final String typed = _joinCtrl.text.trim();
    if (typed.isEmpty) {
      setState(() { _error = 'Enter the six-letter code your friend shared.'; _canRetry = false; });
      return;
    }
    setState(() { _busy = 'Joining\u2026'; _error = null; });
    try {
      final r = await widget.service.joinRoom(typed);
      if (!mounted) return;
      if (r == null) {
        setState(() { _busy = null; _error = _unavailable; _canRetry = false; });
        return;
      }
      final Object? err = r['error'];
      if (err is String) {
        setState(() { _busy = null; _error = err; _canRetry = false; });
        return;
      }
      Navigator.of(context).pop({'code': r['code'] as String, 'side': 'guest'});
    } catch (e) {
      if (!mounted) return;
      setState(() { _busy = null; _error = OnlineLobby.describe(e); _canRetry = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('PLAY A FRIEND ONLINE', style: AppText.eyebrow),
          const SizedBox(height: 10),
          if (_busy != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                const SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)),
                const SizedBox(width: 10),
                Expanded(child: Text(_busy!, style: AppText.bodyMuted)),
              ]),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Expanded(
                  child: Text(_error!,
                      style: AppText.bodyMuted.copyWith(color: Colors.orangeAccent)),
                ),
                if (_canRetry && _retry != null)
                  TextButton(
                    onPressed: _busy == null ? _retry : null,
                    child: const Text('Try again'),
                  ),
              ]),
            ),
          ElevatedButton.icon(
            onPressed: _busy == null ? _create : null,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create a table \u2014 get a code'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: const Color(0xFF0A0F18)),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: Semantics(label: 'Enter a code (e.g. K7Q2MX)', child: TextField(
                controller: _joinCtrl,
                textCapitalization: TextCapitalization.characters,
                style: AppText.body,
                decoration: const InputDecoration(hintText: 'Enter a code (e.g. K7Q2MX)'),
              )),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _busy == null ? _join : null,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: const Color(0xFF0A0F18)),
              child: const Text('Join'),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            'No name is shared. You appear as Player 1 or Player 2, and the '
            'table is deleted when someone leaves.',
            style: AppText.bodyMuted.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
