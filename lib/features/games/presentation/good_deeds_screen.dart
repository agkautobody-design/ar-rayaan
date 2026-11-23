import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../ui/game_stats.dart';
import '../ui/games_theme.dart';
import 'puzzle_games.dart';

typedef _Deed = ({String id, IconData icon, String title, String detail});

const List<_Deed> _deeds = <_Deed>[
  (
    id: 'quran',
    icon: Icons.menu_book_outlined,
    title: 'Read the Qur’an',
    detail: 'Read a little today, even one page.',
  ),
  (
    id: 'dua',
    icon: Icons.back_hand_outlined,
    title: 'Make extra du’a',
    detail: 'Ask Allah for yourself, your family and the ummah.',
  ),
  (
    id: 'charity',
    icon: Icons.volunteer_activism_outlined,
    title: 'Give charity',
    detail: 'Any amount, however small.',
  ),
  (
    id: 'family',
    icon: Icons.family_restroom,
    title: 'Help your family',
    detail: 'Do a kind act for a family member today.',
  ),
  (
    id: 'smile',
    icon: Icons.sentiment_satisfied_alt_outlined,
    title: 'Smile and greet',
    detail: 'Say salaam and smile at someone you meet.',
  ),
  (
    id: 'dhikr',
    icon: Icons.self_improvement,
    title: 'Remember Allah',
    detail: 'Say SubhanAllah, Alhamdulillah and Allahu Akbar.',
  ),
];

/// Good Deeds: a short checklist for today. Ticks are kept on this device
/// for the day they were made and start fresh the next day. There is no
/// score and nothing is counted across days.
class GoodDeedsScreen extends ConsumerStatefulWidget {
  const GoodDeedsScreen({super.key});

  @override
  ConsumerState<GoodDeedsScreen> createState() => _GoodDeedsState();
}

class _GoodDeedsState extends ConsumerState<GoodDeedsScreen> {
  late final String _key = 'good_deeds_${_today()}';
  Set<String> _done = <String>{};

  static String _today() {
    final DateTime n = DateTime.now();
    return '${n.year}${n.month.toString().padLeft(2, '0')}'
        '${n.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _done = (ref.read(sharedPreferencesProvider).getStringList(_key) ??
            <String>[])
        .toSet();
  }

  void _toggle(String id) {
    setState(() => _done.contains(id) ? _done.remove(id) : _done.add(id));
    ref.read(sharedPreferencesProvider).setStringList(_key, _done.toList());
  }

  @override
  Widget build(BuildContext context) {
    return PuzzleFrame(
      title: 'Good Deeds',
      tagline: 'Small steps, one day at a time.',
      children: <Widget>[
        const SizedBox(height: 8),
        GameStatBar(
          stats: <GameStat>[
            GameStat(Icons.checklist, 'Done today',
                '${_done.length} of ${_deeds.length}'),
          ],
        ),
        const SizedBox(height: 12),
        for (final _Deed d in _deeds)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GamePanel(
              selected: _done.contains(d.id),
              semanticsLabel:
                  '${d.title}${_done.contains(d.id) ? ', done' : ''}',
              onTap: () => _toggle(d.id),
              child: Row(
                children: <Widget>[
                  Icon(d.icon, color: AppColors.gold, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          d.title,
                          style: AppText.titleMedium.copyWith(
                            color: GamesTheme.champagne,
                          ),
                        ),
                        Text(d.detail, style: AppText.bodyMuted),
                      ],
                    ),
                  ),
                  Icon(
                    _done.contains(d.id)
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: _done.contains(d.id)
                        ? GamesTheme.good
                        : AppColors.goldLight,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
