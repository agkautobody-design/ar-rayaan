import 'dart:async' show unawaited;
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../presentation/chess_pieces.dart';
import '../ui/games_art.dart';
import 'chess_board_art.dart';
import 'chess_engine.dart';
import 'chess_settings.dart';

/// Where the chess art lives. `tool/process_game_art.py` makes the pieces and
/// the marble boards from the owner's approved art (see
/// `docs/product/games_art_pipeline.md`); the owner can drop exact exports
/// over any of these files (same names) with no code change. Board pictures
/// and highlight tiles are in `chess_board_art.dart`.
abstract final class ChessAssets {
  static const String root = 'assets/games/chess';

  /// 'assets/games/chess/pieces/wn.webp' for a white knight.
  static String piece(int piece) =>
      '$root/pieces/${pieceIsWhite(piece) ? 'w' : 'b'}'
      '${'pnbrqk'[pieceType(piece) - 1]}.webp';

  /// One of three grain variants of a light or dark square. Only the themes
  /// in [squareThemes] have them: they are drawn when a theme has no board
  /// picture (yet).
  static String square(ChessBoardTheme t, {required bool light, int v = 0}) =>
      '$root/squares/${t.name}_${light ? 'light' : 'dark'}_$v.jpg';

  static const int squareVariants = 3;

  /// Themes that still have textured squares on disk.
  static const List<ChessBoardTheme> squareThemes = <ChessBoardTheme>[
    ChessBoardTheme.blue,
    ChessBoardTheme.grey,
    ChessBoardTheme.classic,
  ];

  /// Every file the board can ask for (the asset test checks them all).
  static List<String> all() => <String>[
        for (final bool white in <bool>[true, false])
          for (int t = kPawn; t <= kKing; t++)
            piece(t | (white ? 0 : kBlackBit)),
        for (final ChessBoardTheme t in squareThemes)
          for (final bool light in <bool>[true, false])
            for (int v = 0; v < squareVariants; v++)
              square(t, light: light, v: v),
        ...ChessBoardArt.allShipped,
      ];
}

/// Plain colours behind the textures: shown if an image is ever missing, and
/// used for the little theme swatches.
(Color light, Color dark) chessThemeColors(ChessBoardTheme t) => switch (t) {
      ChessBoardTheme.royal => (
          const Color(0xFFE9C58C),
          const Color(0xFF15120E),
        ),
      ChessBoardTheme.classic => (
          const Color(0xFFDFAF73),
          const Color(0xFF774419),
        ),
      ChessBoardTheme.green => (
          const Color(0xFFF7CD82),
          const Color(0xFF136728),
        ),
      ChessBoardTheme.blue => (
          const Color(0xFFD3B59A),
          const Color(0xFF084E7E),
        ),
      ChessBoardTheme.grey => (
          const Color(0xFFBEA58E),
          const Color(0xFF302D2B),
        ),
    };

/// The blue of the selected square, as in the design.
const Color kChessSelected = Color(0xFF2A9BD6);

/// The dark fill of the frame and the coordinate gutter.
const Color kChessGutter = Color(0xFF1B150D);

/// 'PNBRQK' letter of a piece, upper case for White.
String chessPieceLetter(int piece) {
  final String l = 'PNBRQK'[pieceType(piece) - 1];
  return pieceIsWhite(piece) ? l : l.toLowerCase();
}

/// One piece: the owner's sprite (Classic) or a code-drawn silhouette
/// (Modern, and the fallback if a sprite file is missing).
class ChessPieceView extends StatelessWidget {
  const ChessPieceView({
    required this.piece,
    required this.style,
    this.size,
    super.key,
  });

  final int piece;
  final ChessPieceStyle style;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final Widget vector = CustomPaint(
      painter: ChessPiecePainter(chessPieceLetter(piece)),
      size: Size.square(size ?? 40),
    );
    final Widget child = style == ChessPieceStyle.modern
        ? vector
        : Image.asset(
            ChessAssets.piece(piece),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            excludeFromSemantics: true,
            errorBuilder: (BuildContext c, Object e, StackTrace? s) => vector,
          );
    if (size == null) return child;
    return SizedBox.square(dimension: size, child: child);
  }
}

String _squareLabel(List<int> board, int sq) {
  final int p = board[sq];
  if (p == 0) return '${squareName(sq)}, empty';
  return '${squareName(sq)}, ${pieceIsWhite(p) ? 'white' : 'black'} '
      '${pieceName(pieceType(p))}';
}

/// Builds again once the list of bundled files is known, so board pictures
/// and tiles that were dropped in later are found.
class _AssetsKnown extends StatefulWidget {
  const _AssetsKnown({required this.builder});

  final WidgetBuilder builder;

  @override
  State<_AssetsKnown> createState() => _AssetsKnownState();
}

class _AssetsKnownState extends State<_AssetsKnown> {
  @override
  void initState() {
    super.initState();
    if (GamesArt.hasAsset('') == null) {
      unawaited(
        GamesArt.warmUp().then((_) {
          if (mounted) setState(() {});
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

/// The board: the theme's picture (frame included) with the 8 x 8 playing area
/// laid on it at its measured place, an A-H / 1-8 gutter, pieces and the
/// highlights. A theme with no picture draws textured squares in a code-drawn
/// frame instead. Pure display; taps go to [onTap] with the square index.
class ChessBoardView extends StatelessWidget {
  const ChessBoardView({
    required this.board,
    required this.theme,
    required this.pieceStyle,
    required this.onTap,
    this.flipped = false,
    this.selected,
    this.targets = const <int>{},
    this.lastFrom,
    this.lastTo,
    this.checkSquare,
    this.hintFrom,
    this.hintTo,
    super.key,
  });

  final List<int> board;
  final ChessBoardTheme theme;
  final ChessPieceStyle pieceStyle;
  final ValueChanged<int> onTap;
  final bool flipped;
  final int? selected;

  /// Squares the selected piece may move to (empty when hints are off).
  final Set<int> targets;
  final int? lastFrom;
  final int? lastTo;
  final int? checkSquare;
  final int? hintFrom;
  final int? hintTo;

  @override
  Widget build(BuildContext context) {
    return _AssetsKnown(builder: _build);
  }

  Widget _build(BuildContext context) {
    final TextScaler scaler = MediaQuery.textScalerOf(context)
        .clamp(maxScaleFactor: 1.2);
    final TextStyle coord = AppText.bodyMuted.copyWith(
      fontSize: 12,
      color: AppColors.goldLight,
      fontWeight: FontWeight.w600,
    );
    final String? picture = ChessBoardArt.board(theme);
    final Rect play =
        picture == null ? const Rect.fromLTWH(0, 0, 1, 1) : ChessBoardArt.grid(theme).fractions;
    return Container(
      key: const ValueKey<String>('chess-board'),
      decoration: BoxDecoration(
        color: kChessGutter,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.75)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.10),
            blurRadius: 36,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(4, 6, 6, 4),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints box) {
          const double gutter = 18;
          final double side = box.maxWidth - gutter;
          final double pl = play.left * side;
          final double pt = play.top * side;
          final double pw = play.width * side;
          final double ph = play.height * side;
          final Widget grid = SizedBox(
            width: pw,
            height: ph,
            child: _grid(pw / 8, ph / 8, picture != null),
          );
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                height: side,
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: gutter,
                      child: ExcludeSemantics(
                        child: Stack(
                          children: <Widget>[
                            for (int r = 0; r < 8; r++)
                              Positioned(
                                left: 0,
                                right: 0,
                                top: pt + r * ph / 8,
                                height: ph / 8,
                                child: Center(
                                  child: Text(
                                    '${flipped ? r + 1 : 8 - r}',
                                    textScaler: scaler,
                                    style: coord,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: side,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          if (picture != null)
                            Positioned.fill(
                              child: Image.asset(
                                picture,
                                key: const ValueKey<String>('chess-board-art'),
                                fit: BoxFit.fill,
                                gaplessPlayback: true,
                                excludeFromSemantics: true,
                                filterQuality: FilterQuality.medium,
                                errorBuilder: (BuildContext x, Object e,
                                        StackTrace? t) =>
                                    const ColoredBox(color: kChessGutter),
                              ),
                            ),
                          Positioned(
                            left: pl,
                            top: pt,
                            width: pw,
                            height: ph,
                            child: grid,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              ExcludeSemantics(
                child: SizedBox(
                  height: 20,
                  child: Stack(
                    children: <Widget>[
                      for (int i = 0; i < 8; i++)
                        Positioned(
                          left: gutter + pl + i * pw / 8,
                          width: pw / 8,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Text(
                              'ABCDEFGH'[flipped ? 7 - i : i],
                              textScaler: scaler,
                              style: coord,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _grid(double cw, double ch, bool picture) {
    final Widget rows = Column(
      children: <Widget>[
        for (int r = 0; r < 8; r++)
          Expanded(
            child: Row(
              children: <Widget>[
                for (int c = 0; c < 8; c++)
                  Expanded(child: _square(r, c, cw, ch, picture)),
              ],
            ),
          ),
      ],
    );
    return picture
        ? rows
        : ClipRRect(borderRadius: BorderRadius.circular(4), child: rows);
  }

  Widget _tile(ChessHighlight h) => Positioned.fill(
        child: IgnorePointer(
          child: Image.asset(
            ChessBoardArt.highlight(theme, h)!,
            fit: BoxFit.fill,
            gaplessPlayback: true,
            excludeFromSemantics: true,
            errorBuilder: (BuildContext x, Object e, StackTrace? t) =>
                const SizedBox.shrink(),
          ),
        ),
      );

  Widget _square(int r, int c, double cw, double ch, bool picture) {
    final double s = math.min(cw, ch);
    final int row = flipped ? 7 - r : r;
    final int col = flipped ? 7 - c : c;
    final int sq = row * 8 + col;
    final bool light = (row + col) % 2 == 0;
    final int piece = board[sq];
    final bool isSel = selected == sq;
    final bool isTarget = targets.contains(sq);
    final bool isLast = sq == lastFrom || sq == lastTo;
    final bool isCheck = checkSquare == sq;
    final bool isHint = sq == hintFrom || sq == hintTo;
    final (Color lightColor, Color darkColor) = chessThemeColors(theme);
    final Color accent = Color(ChessBoardArt.accent(theme));
    final int variant = (row * 3 + col * 5) % ChessAssets.squareVariants;
    final bool selTile =
        picture && ChessBoardArt.highlight(theme, ChessHighlight.selected) != null;
    final bool legalTile = picture &&
        ChessBoardArt.highlight(theme, ChessHighlight.legalMove) != null;
    final bool lastTile = picture &&
        ChessBoardArt.highlight(theme, ChessHighlight.lastMove) != null;
    final String hint = isSel
        ? 'selected'
        : isTarget
            ? (piece == 0 ? 'legal move' : 'legal capture')
            : '';
    return Semantics(
      key: ValueKey<String>('sq-${squareName(sq)}'),
      button: true,
      selected: isSel,
      label: _squareLabel(board, sq),
      hint: hint.isEmpty ? null : hint,
      excludeSemantics: true,
      onTap: () => onTap(sq),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(sq),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (!picture)
              if (isSel)
                const ColoredBox(color: kChessSelected)
              else
                Image.asset(
                  ChessAssets.square(theme, light: light, v: variant),
                  fit: BoxFit.fill,
                  gaplessPlayback: true,
                  excludeFromSemantics: true,
                  errorBuilder: (BuildContext x, Object e, StackTrace? t) =>
                      ColoredBox(color: light ? lightColor : darkColor),
                ),
            if (isLast && !isSel)
              if (lastTile)
                _tile(ChessHighlight.lastMove)
              else
                ColoredBox(
                  color: (picture
                          ? Color(ChessBoardArt.lastMoveTint(theme))
                          : AppColors.gold)
                      .withValues(alpha: picture ? 0.34 : 0.28),
                ),
            if (isSel && picture)
              if (selTile)
                _tile(ChessHighlight.selected)
              else
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.30),
                    border: Border.all(color: accent, width: 2.5),
                    borderRadius: BorderRadius.circular(s * 0.08),
                  ),
                ),
            if (isCheck)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: <Color>[
                      const Color(0xCCFF3B30),
                      const Color(0x00FF3B30),
                    ],
                  ),
                ),
              ),
            if (isHint)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.goldLight, width: 3),
                  color: AppColors.goldLight.withValues(alpha: 0.18),
                ),
              ),
            if (piece != 0)
              Padding(
                padding: EdgeInsets.all(s * (picture ? 0.02 : 0.04)),
                child: ChessPieceView(piece: piece, style: pieceStyle),
              ),
            if (isTarget)
              if (picture && piece == 0 && legalTile)
                _tile(ChessHighlight.legalMove)
              else
                Center(
                  child: piece == 0
                      ? Container(
                          width: s * 0.30,
                          height: s * 0.30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (picture ? accent : kChessSelected)
                                .withValues(alpha: 0.85),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.85),
                              width: 1.2,
                            ),
                          ),
                        )
                      : Container(
                          width: s * 0.92,
                          height: s * 0.92,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: picture ? accent : kChessSelected,
                              width: 3.2,
                            ),
                          ),
                        ),
                ),
          ],
        ),
      ),
    );
  }
}
