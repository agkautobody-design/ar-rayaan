import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
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

/// "Ask Hadi about this": opens Hadi with [question] already asked. It uses
/// the existing Hadi route and makes no network call of its own.
class AskHadiAboutButton extends StatelessWidget {
  const AskHadiAboutButton({required this.question, super.key});

  final String question;

  @override
  Widget build(BuildContext context) {
    return OutlineAction(
      label: 'Ask Hadi about this',
      icon: Icons.chat_bubble_outline,
      onPressed: () => context.open(AppRoutes.hadiAsk(question)),
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
