import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/switch_row.dart';
import '../data/game_settings.dart';
import '../ui/games_theme.dart';
import '../ui/learning_widgets.dart';

/// /games/settings - sound, vibration, the look of boards and cards, and the
/// free hints. Kept on this device only. Text follows the phone's text size
/// and Elder Mode; nothing here shrinks it.
class GameSettingsScreen extends ConsumerWidget {
  const GameSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GameSettings s = ref.watch(gameSettingsProvider);
    final GameSettingsController c = ref.read(gameSettingsProvider.notifier);
    final GamePalette pal = GamePalette.of(s.theme);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: <Widget>[
          const ArchHeader(
            title: 'Game settings',
            tagline: 'Quiet by default, and free to change',
          ),
          _Group(
            title: 'Sound',
            child: SwitchRow(
              icon: Icons.volume_up_outlined,
              title: 'Game sounds',
              subtitle: 'Off unless you turn it on. No game sounds are '
                  'included in this version yet; your choice is saved for '
                  'when they are.',
              value: s.sound,
              onChanged: c.setSound,
            ),
          ),
          _Group(
            title: 'Vibration',
            child: SwitchRow(
              icon: Icons.vibration,
              title: 'Vibrate on a move',
              subtitle: 'A short buzz when you move a card, check an answer '
                  'or find a word. It works on phones, not in a browser.',
              value: s.vibration,
              onChanged: c.setVibration,
            ),
          ),
          _Group(
            title: 'Board and card theme',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final GameCardTheme t in GameCardTheme.values)
                      GameChip(
                        label: t.label,
                        selected: s.theme == t,
                        onTap: () => c.setTheme(t),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: pal.fill,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: pal.border),
                  ),
                  child: Text(
                    'This is how cards and boards look in the learning games.',
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 15,
                      height: 1.4,
                      color: pal.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _Group(
            title: 'Hints',
            child: SwitchRow(
              icon: Icons.lightbulb_outline,
              title: 'Show free hints',
              subtitle: 'Hints are free and never bought or earned. Off hides '
                  'every hint button and starts new quizzes without hints.',
              value: s.showHints,
              onChanged: c.setShowHints,
            ),
          ),
          _Group(
            title: 'Large text',
            child: Text(
              'Games follow your phone’s text size and Elder Mode. Letters '
              'in the word grid keep a size that is easy to tap; at large '
              'text the grid gets fewer, bigger squares.',
              style: AppText.body.copyWith(height: 1.5),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: OutlineAction(
              label: 'Reset to default',
              icon: Icons.restart_alt,
              onPressed: c.reset,
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GamePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                title,
                style: AppText.titleMedium.copyWith(
                  color: GamesTheme.champagne,
                ),
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
