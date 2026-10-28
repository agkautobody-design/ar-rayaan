import 'dart:async' show unawaited;

import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/speak_button.dart';
import '../../hadi/application/hadi_controller.dart';
import '../data/game_settings.dart';
import 'games_art.dart';
import 'games_theme.dart';

/// The colours of the cards and boards in the learning games, for one of the
/// three themes a person can choose in Game Settings. Every text colour has
/// at least 4.5:1 contrast on its fill (checked in the tests).
class GamePalette {
  const GamePalette({
    required this.fill,
    required this.border,
    required this.text,
    required this.accent,
    required this.good,
  });

  final Color fill;
  final Color border;
  final Color text;
  final Color accent;
  final Color good;

  static const GamePalette night = GamePalette(
    fill: Color(0xFF101C2E),
    border: Color(0xFFD4AF37),
    text: Color(0xFFEAD6B4),
    accent: Color(0xFFE8C96A),
    good: Color(0xFF7FD1A8),
  );

  static const GamePalette parchment = GamePalette(
    fill: Color(0xFFEAD6B4),
    border: Color(0xFF7A5C10),
    text: Color(0xFF0B1B2A),
    accent: Color(0xFF5C430A),
    good: Color(0xFF1B5E3B),
  );

  static const GamePalette contrast = GamePalette(
    fill: Color(0xFF000000),
    border: Color(0xFFFFFFFF),
    text: Color(0xFFFFFFFF),
    accent: Color(0xFFFFD54F),
    good: Color(0xFF7FD1A8),
  );

  static GamePalette of(GameCardTheme t) => switch (t) {
        GameCardTheme.night => night,
        GameCardTheme.parchment => parchment,
        GameCardTheme.contrast => contrast,
      };
}

/// A board background: the art file of [slot] when it is bundled, otherwise a
/// plain panel in the chosen palette. [child] is drawn over it.
class GameBoardBackdrop extends StatelessWidget {
  const GameBoardBackdrop({
    required this.slot,
    required this.palette,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    super.key,
  });

  final ArtSlot slot;
  final GamePalette palette;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ArtBuilder(
      slot: slot,
      builder: (BuildContext context, bool hasArt) {
        return Container(
          decoration: BoxDecoration(
            color: palette.fill,
            borderRadius: BorderRadius.circular(GamesTheme.radius),
            border: Border.all(color: palette.border, width: 1.2),
            image: hasArt
                ? DecorationImage(
                    image: AssetImage(slot.path),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      palette.fill.withValues(alpha: 0.7),
                      BlendMode.srcOver,
                    ),
                  )
                : null,
          ),
          padding: padding,
          child: child,
        );
      },
    );
  }
}

/// "Ask Hadi about this": Hadi explains the question, in a sheet over the
/// game. The game stays underneath, so closing the sheet returns to exactly
/// where the person was (opening Hadi's own tab would have replaced the
/// screens behind it, so Back landed on Home), and the question, the answer
/// and the explanation never travel in an address. It makes no network call
/// of its own: Hadi answers from the game's text and his checked answers.
class AskHadiAboutButton extends ConsumerWidget {
  const AskHadiAboutButton({required this.question, super.key});

  final String question;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlineAction(
      label: 'Ask Hadi about this',
      icon: Icons.chat_bubble_outline,
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: AppColors.night,
        builder: (BuildContext c) => _AskHadiSheet(question: question),
      ),
    );
  }
}

class _AskHadiSheet extends ConsumerStatefulWidget {
  const _AskHadiSheet({required this.question});
  final String question;

  @override
  ConsumerState<_AskHadiSheet> createState() => _AskHadiSheetState();
}

class _AskHadiSheetState extends ConsumerState<_AskHadiSheet> {
  String? _reply;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_ask());
  }

  Future<void> _ask() async {
    try {
      final String a = await ref
          .read(hadiControllerProvider.notifier)
          .ask(widget.question);
      if (!mounted) return;
      setState(() {
        _reply = a.trim().isEmpty ? null : a;
        _failed = a.trim().isEmpty;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? reply = _reply;
    final List<String> routes =
        reply == null ? const <String>[] : HadiTokens.routesOf(reply);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text('HADI EXPLAINS', style: AppText.eyebrow),
                ),
                if (reply != null) SpeakButton(text: HadiTokens.strip(reply)),
                IconButton(
                  key: const Key('ask-hadi-sheet-close'),
                  tooltip: 'Close and return to the game',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.gold),
                ),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                child: reply == null && !_failed
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.gold),
                        ),
                      )
                    : Text(
                        _failed
                            ? 'Hadi could not answer just now. Your game is '
                                'where you left it; try again in a moment.'
                            : HadiTokens.strip(reply!),
                        style: AppText.body.copyWith(height: 1.6),
                      ),
              ),
            ),
            if (routes.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  for (final String r in routes)
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.open(r);
                      },
                      child: Text(HadiTokens.labelFor(r),
                          style: AppText.bodyMuted
                              .copyWith(color: AppColors.gold)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A short buzz when the person has vibration on in Game Settings.
void gameHaptic(WidgetRef ref) {
  if (!ref.read(gameSettingsProvider).vibration) return;
  try {
    unawaited(HapticFeedback.selectionClick().catchError((Object _) {}));
  } catch (_) {}
}

/// [s] cut to at most [max] characters, at a word.
String clip(String s, int max) {
  final String t = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (t.length <= max) return t;
  final int cut = t.lastIndexOf(' ', max);
  return '${t.substring(0, cut > max ~/ 2 ? cut : max)} …';
}
