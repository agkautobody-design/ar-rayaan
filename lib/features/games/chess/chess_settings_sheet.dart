import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/switch_row.dart';
import '../ui/games_theme.dart';
import 'chess_board_art.dart';
import 'chess_board_view.dart';
import 'chess_settings.dart';
import '../../../app/theme/widgets/focus_ring.dart';
import '../../../app/theme/widgets/focus_safe_semantics.dart';
import '../../../app/theme/widgets/named_sheet.dart';

/// Chess Settings, opened from the board or the table menu: board theme,
/// piece style and the switches. Saved on this device the moment they change.
Future<void> showChessSettings(BuildContext context) {
  return showNamedSheet<void>(
    label: 'Chess settings',
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.night,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext c) => const ChessSettingsSheet(),
  );
}

class ChessSettingsSheet extends ConsumerWidget {
  const ChessSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ChessSettings s = ref.watch(chessSettingsProvider);
    final ChessSettingsController c =
        ref.read(chessSettingsProvider.notifier);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text('Chess Settings', style: AppText.titleMedium),
              ),
              const SizedBox(height: 4),
              Text(
                'Customize your experience. Kept on this device only.',
                style: AppText.bodyMuted,
              ),
              const SizedBox(height: 16),
              Text('Board Theme', style: AppText.label),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  for (final ChessBoardTheme t in ChessBoardTheme.values)
                    _ThemeSwatch(
                      theme: t,
                      selected: s.theme == t,
                      onTap: () => c.update(s.copyWith(theme: t)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Pieces Style', style: AppText.label),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final ChessPieceStyle p in ChessPieceStyle.values)
                    GameChip(
                      label: p.label,
                      selected: s.pieces == p,
                      onTap: () => c.update(s.copyWith(pieces: p)),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Classic: glossy gold and black. Modern: flat shapes drawn in '
                'code.',
                style: AppText.bodyMuted,
              ),
              const SizedBox(height: 12),
              SwitchRow(
                icon: Icons.volume_up_outlined,
                title: 'Sound Effects',
                subtitle: 'A soft click on each move, on phones. Off until '
                    'you turn it on.',
                value: s.sound,
                onChanged: (bool v) => c.update(s.copyWith(sound: v)),
              ),
              SwitchRow(
                icon: Icons.lightbulb_outline,
                title: 'Show Move Hints',
                subtitle: 'Show where the selected piece can go.',
                value: s.showLegalMoves,
                onChanged: (bool v) => c.update(s.copyWith(showLegalMoves: v)),
              ),
              SwitchRow(
                icon: Icons.stars_outlined,
                title: 'Auto-queen promotion',
                subtitle: 'A pawn that reaches the end becomes a queen '
                    'without asking.',
                value: s.autoQueen,
                onChanged: (bool v) => c.update(s.copyWith(autoQueen: v)),
              ),
              SwitchRow(
                icon: Icons.flag_outlined,
                title: 'Confirm resign',
                subtitle: 'Ask once more before a game is given up.',
                value: s.confirmResign,
                onChanged: (bool v) => c.update(s.copyWith(confirmResign: v)),
              ),
              SwitchRow(
                icon: Icons.save_outlined,
                title: 'Auto Save Games',
                subtitle: 'Keep an unfinished game on this device so you can '
                    'resume it.',
                value: s.autoSave,
                onChanged: (bool v) {
                  c.update(s.copyWith(autoSave: v));
                  if (!v) c.clearSaved();
                },
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final ChessBoardTheme theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (Color light, Color dark) = chessThemeColors(theme);
    final String? picture = ChessBoardArt.board(theme);
    Widget tile(bool isLight) => Expanded(
          child: Image.asset(
            ChessAssets.square(theme, light: isLight),
            fit: BoxFit.fill,
            excludeFromSemantics: true,
            errorBuilder: (BuildContext c, Object e, StackTrace? s) =>
                ColoredBox(color: isLight ? light : dark),
          ),
        );
    return FocusSafeSemantics(
      button: true,
      selected: selected,
      label: '${theme.label} board',
      excludeSemantics: true,
      onTap: onTap,
      child: FocusRing(borderRadius: 12, child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 76,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? GamesTheme.borderBright
                  : AppColors.gold.withValues(alpha: 0.35),
              width: selected ? 2.4 : 1,
            ),
          ),
          child: Column(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox.square(
                  dimension: 64,
                  child: picture != null
                      // The middle 2 x 2 squares of the board picture.
                      ? FittedBox(
                          fit: BoxFit.cover,
                          clipBehavior: Clip.hardEdge,
                          child: ClipRect(
                            child: Align(
                              widthFactor: 0.25,
                              heightFactor: 0.25,
                              child: Image.asset(
                                picture,
                                width: 256,
                                height: 256,
                                excludeFromSemantics: true,
                                filterQuality: FilterQuality.medium,
                                errorBuilder: (BuildContext c, Object e,
                                        StackTrace? st) =>
                                    ColoredBox(color: dark),
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: <Widget>[
                            Expanded(
                              child: Row(
                                children: <Widget>[tile(true), tile(false)],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: <Widget>[tile(false), tile(true)],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                theme.label,
                textAlign: TextAlign.center,
                style: AppText.bodyMuted.copyWith(
                  color: selected ? AppColors.goldLight : null,
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }
}
