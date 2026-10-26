import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../engine/game_registry.dart';
import 'games_theme.dart';

/// The named art slots of the Games section.
///
/// Each slot is one file in `assets/games/art/`, named after the slot. The
/// owner's exact art lives there (cropped from his design screenshots by
/// `tool/crop_game_art.py`; see `assets/games/art/manifest.json` and
/// `docs/content_needed/GAMES_ART_NEEDED.md`). To replace a slot, drop a
/// better file with the same name and extension into that folder. To fill a
/// slot that has no file yet, do the same: the app finds whatever is bundled.
///
/// A slot with no file is never an error: every use of a slot has a
/// code-drawn fallback, so a missing file only means the plain look.
enum ArtSlot {
  // Headers and backdrops.
  hubHeader,
  skylineBand,
  backdropFull,
  // Hub categories.
  categoryIslamic,
  categoryBoard,
  categoryWords,
  categoryPuzzles,
  categoryFamily,
  categoryMore,
  // One picture per game.
  gameQuranKnowledge,
  heroQuranKnowledge,
  gameStories,
  gameNames99,
  gameLineage,
  gameHijrah,
  gameHadith,
  gameHifz,
  gameChess,
  gameLudo,
  gameMemory,
  gameArabicWords,
  gameSeerahChallenge,
  gamePuzzlePath,
  gameLogicTiles,
  // Results and decoration.
  resultTrophy,
  cornerOrnament,
  goldDivider,
  // Slots the designs give no clean art for (fallback only until exported).
  bottomNavFrame,
  historyEmpty,
  settingsHeader,
  // Boards of the learning games (fallback only until exported).
  seerahTimelineBoard,
  prophetsOrderBoard,
  wuduStepsBoard,
  salahStepsBoard,
  wordSearchGrid,
  scrambleTile,
  hajjMap;

  /// Ornaments are cut-outs with transparency (PNG); everything else WebP.
  String get ext => switch (this) {
        ArtSlot.cornerOrnament || ArtSlot.goldDivider => 'png',
        _ => 'webp',
      };

  /// The asset path of the slot's file, named after the slot.
  String get path => '${GamesArt.folder}$name.$ext';
}

/// Finds out which slots have a file and gives the picture for a game or a
/// hub category.
abstract final class GamesArt {
  static const String folder = 'assets/games/art/';

  static Future<void>? _loading;
  static Set<String>? _known;

  /// Reads the list of bundled assets once. Never throws: when the list
  /// cannot be read every slot simply counts as missing.
  static Future<void> warmUp() => _loading ??= _load();

  static Future<void> _load() async {
    try {
      final AssetManifest manifest =
          await AssetManifest.loadFromAssetBundle(rootBundle);
      _known = manifest
          .listAssets()
          .where((String p) => p.startsWith(folder))
          .toSet();
    } on Object {
      _known = <String>{};
    }
  }

  /// True or false once the asset list is known, null before that.
  static bool? has(ArtSlot slot) => _known?.contains(slot.path);

  /// Tests only: pretend exactly these asset paths are bundled.
  @visibleForTesting
  static void debugSetKnown(Set<String>? paths) {
    _known = paths;
    _loading = paths == null ? null : Future<void>.value();
  }

  /// The slot that holds the picture of a registry game, if it has one.
  static ArtSlot? slotForGame(String gameId) => switch (gameId) {
        'qk' => ArtSlot.gameQuranKnowledge,
        'stories' => ArtSlot.gameStories,
        'names99' => ArtSlot.gameNames99,
        'lineage' => ArtSlot.gameLineage,
        'hijrah' => ArtSlot.gameHijrah,
        'hifz' => ArtSlot.gameHifz,
        'chess' => ArtSlot.gameChess,
        'ludo' => ArtSlot.gameLudo,
        'memory' => ArtSlot.gameMemory,
        'seerah' => ArtSlot.gameSeerahChallenge,
        'hadith' => ArtSlot.gameHadith,
        'arabic-words' => ArtSlot.gameArabicWords,
        _ => null,
      };

  /// The slot that holds the picture of a hub section.
  static ArtSlot slotForCategory(GameCategory c) => switch (c) {
        GameCategory.islamic => ArtSlot.categoryIslamic,
        GameCategory.strategy => ArtSlot.categoryBoard,
        GameCategory.family => ArtSlot.categoryFamily,
        GameCategory.words => ArtSlot.categoryWords,
      };

  /// The picture itself, decorative (no semantics). If the file turns out to
  /// be unreadable it draws nothing.
  static Widget asset(
    ArtSlot slot, {
    BoxFit fit = BoxFit.cover,
    AlignmentGeometry alignment = Alignment.center,
    double? width,
    double? height,
  }) {
    return Image.asset(
      slot.path,
      fit: fit,
      alignment: alignment,
      width: width,
      height: height,
      gaplessPlayback: true,
      excludeFromSemantics: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (BuildContext context, Object error, StackTrace? trace) =>
          const SizedBox.shrink(),
    );
  }
}

/// Builds with `present` true when the slot's file is bundled. Until the list
/// of bundled files is known, and whenever it is not there, `present` is
/// false, so the caller draws its fallback.
class ArtBuilder extends StatefulWidget {
  const ArtBuilder({required this.slot, required this.builder, super.key});

  final ArtSlot slot;
  final Widget Function(BuildContext context, bool present) builder;

  @override
  State<ArtBuilder> createState() => _ArtBuilderState();
}

class _ArtBuilderState extends State<ArtBuilder> {
  @override
  void initState() {
    super.initState();
    if (GamesArt.has(widget.slot) == null) {
      unawaited(
        GamesArt.warmUp().then((_) {
          if (mounted) setState(() {});
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, GamesArt.has(widget.slot) ?? false);
  }
}

/// A game's picture in a rounded, gold-edged frame, or the round icon badge
/// when the game has no picture or its file is missing.
class ArtThumb extends StatelessWidget {
  const ArtThumb({
    required this.gameId,
    required this.iconKey,
    this.size = 52,
    super.key,
  });

  final String gameId;
  final String iconKey;

  /// Height of the frame; the picture is half as wide again.
  final double size;

  @override
  Widget build(BuildContext context) {
    final ArtSlot? slot = GamesArt.slotForGame(gameId);
    final Widget badge = GameBadge(iconKey: iconKey, size: size);
    if (slot == null) return badge;
    return ArtBuilder(
      slot: slot,
      builder: (BuildContext context, bool present) {
        if (!present) return badge;
        return ExcludeSemantics(
          child: Container(
            width: size * 1.5,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: GamesTheme.border, width: 1.2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: GamesArt.asset(slot),
            ),
          ),
        );
      },
    );
  }
}

/// The thin gold rule with a diamond, or nothing when the file is missing.
class GoldDivider extends StatelessWidget {
  const GoldDivider({this.maxWidth = 260, super.key});

  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ArtBuilder(
      slot: ArtSlot.goldDivider,
      builder: (BuildContext context, bool present) {
        if (!present) return const SizedBox.shrink();
        return ExcludeSemantics(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: GamesArt.asset(
                  ArtSlot.goldDivider,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The Islamic pattern corners laid over the four corners of a panel (put it
/// in a `Positioned.fill` inside a `Stack`). Draws nothing when the file is
/// missing.
class PanelCorners extends StatelessWidget {
  const PanelCorners({super.key});

  static const double size = 30;

  @override
  Widget build(BuildContext context) {
    return ArtBuilder(
      slot: ArtSlot.cornerOrnament,
      builder: (BuildContext context, bool present) {
        if (!present) return const SizedBox.shrink();
        Widget corner({required bool flipX, required bool flipY}) {
          return Opacity(
            opacity: 0.85,
            child: Transform.flip(
              flipX: flipX,
              flipY: flipY,
              child: SizedBox(
                width: size,
                height: size,
                child: GamesArt.asset(
                  ArtSlot.cornerOrnament,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        }

        return IgnorePointer(
          child: ExcludeSemantics(
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: 6,
                  top: 6,
                  child: corner(flipX: false, flipY: false),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: corner(flipX: true, flipY: false),
                ),
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: corner(flipX: false, flipY: true),
                ),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: corner(flipX: true, flipY: true),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The trophy picture at the top of a result: a rounded, gold-edged banner.
/// Draws nothing when the file is missing.
class ResultTrophyArt extends StatelessWidget {
  const ResultTrophyArt({super.key});

  @override
  Widget build(BuildContext context) {
    return ArtBuilder(
      slot: ArtSlot.resultTrophy,
      builder: (BuildContext context, bool present) {
        if (!present) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 10),
          child: ExcludeSemantics(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(GamesTheme.radius),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.6),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(GamesTheme.radius - 1),
                    child: AspectRatio(
                      aspectRatio: 783 / 355,
                      child: GamesArt.asset(ArtSlot.resultTrophy),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The wide picture at the top of a game's page: the hero for Qur’an
/// Knowledge, otherwise the game's own picture at a modest size. Draws
/// nothing when there is no file.
class GameBanner extends StatelessWidget {
  const GameBanner({required this.gameId, super.key});

  final String gameId;

  @override
  Widget build(BuildContext context) {
    final ArtSlot? hero =
        gameId == 'qk' ? ArtSlot.heroQuranKnowledge : GamesArt.slotForGame(gameId);
    if (hero == null) return const SizedBox.shrink();
    final bool wide = hero == ArtSlot.heroQuranKnowledge;
    return ArtBuilder(
      slot: hero,
      builder: (BuildContext context, bool present) {
        if (!present) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ExcludeSemantics(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 520 : 300),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(GamesTheme.radius),
                    border: Border.all(color: GamesTheme.border, width: 1.2),
                  ),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(GamesTheme.radius - 1),
                    child: AspectRatio(
                      aspectRatio: wide ? 798 / 347 : 230 / 144,
                      child: GamesArt.asset(hero),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
