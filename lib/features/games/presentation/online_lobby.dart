import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../data/game_rooms_service.dart';

/// The Online Hall lobby — create a room and share the code, or join one.
/// Pops {'code','side'} on success; null on cancel.
class OnlineLobby extends StatefulWidget {
  final String game;
  final GameRoomsService service;
  const OnlineLobby({super.key, required this.game, required this.service});

  static Future<Map<String, String>?> show(
      BuildContext context, String game, GameRoomsService service) {
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

  @override
  State<OnlineLobby> createState() => _OnlineLobbyState();
}

class _OnlineLobbyState extends State<OnlineLobby> {
  String? _busy;
  String? _error;
  String _name = '';
  final _joinCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final prefs = await SharedPreferences.getInstance();
      final n = prefs.getString('ar.majlis.name') ?? 'Guest of the Courtyard';
      if (mounted) setState(() => _name = n);
    });
  }

  Future<void> _create() async {
    setState(() { _busy = 'Creating your table\u2026'; _error = null; });
    final r = await widget.service.createRoom(widget.game, _name);
    if (!mounted) return;
    if (r == null) {
      setState(() {
        _busy = null;
        _error = 'The online hall is not awake yet \u2014 flip the three '
            'Firebase switches (Firestore, Anonymous sign-in, rules) and it breathes.';
      });
      return;
    }
    Navigator.of(context).pop({'code': r['code'] as String, 'side': 'host'});
  }

  Future<void> _join() async {
    setState(() { _busy = 'Joining\u2026'; _error = null; });
    final r = await widget.service.joinRoom(_joinCtrl.text, _name);
    if (!mounted) return;
    if (r == null) {
      setState(() {
        _busy = null;
        _error = 'The online hall is not awake yet \u2014 flip the three '
            'Firebase switches and it breathes.';
      });
      return;
    }
    if (r.containsKey('error')) {
      setState(() { _busy = null; _error = r['error'] as String; });
      return;
    }
    Navigator.of(context).pop({'code': r['code'] as String, 'side': 'guest'});
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
              child: Text(_error!,
                  style: AppText.bodyMuted.copyWith(color: Colors.orangeAccent)),
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
              child: TextField(
                controller: _joinCtrl,
                textCapitalization: TextCapitalization.characters,
                style: AppText.body,
                decoration: const InputDecoration(hintText: 'Enter a code (e.g. K7Q2MX)'),
              ),
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
          Text('Playing as your Majlis name.', style: AppText.bodyMuted.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}
