import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../presentation/chess_pieces.dart';
import 'chess_engine.dart';
import 'chess_settings.dart';

/// Where the board art lives. `tool/crop_game_boards.py` cuts it from the
/// owner's design; the owner can drop exact exports over any of these files
/// (same names) with no code change.
abstract final class ChessAssets {
  static const String root = 'assets/games/chess';

  /// 'assets/games/chess/pieces/wn.png' for a white knight.
  static String piece(int piece) =>
      '$root/pieces/${pieceIsWhite(piece) ? 'w' : 'b'}'
      '${'pnbrqk'[pieceType(piece) - 1]}.png';

  /// One of three grain variants of a light or dark square.
  static String square(ChessBoardTheme t, {required bool light, int v = 0}) =>
      '$root/squares/${t.name}_${light ? 'light' : 'dark'}_$v.jpg';

  static const int squareVariants = 3;

  /// Every file the board can ask for (the asset test checks them all).
  static List<String> all() => <String>[
        for (final bool white in <bool>[true, false])
          for (int t = kPawn; t <= kKing; t++)
            piece(t | (white ? 0 : kBlackBit)),
        for (final ChessBoardTheme t in ChessBoardTheme.values)
          for (final bool light in <bool>[true, false])
            for (int v = 0; v < squareVariants; v++)
              square(t, light: light, v: v),
      ];
}

/// Plain colours behind the textures: shown if an image is ever missing, and
/// used for the little theme swatches.
(Color light, Color dark) chessThemeColors(ChessBoardTheme t) => switch (t) {
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

/// The board: gold frame, A-H / 1-8 gutter, textured squares, pieces and
/// the highlights. Pure display; taps go to [onTap] with the square index.
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
    final TextScaler scaler = MediaQuery.textScalerOf(context)
        .clamp(maxScaleFactor: 1.2);
    final TextStyle coord = AppText.bodyMuted.copyWith(
      fontSize: 12,
      color: AppColors.goldLight,
      fontWeight: FontWeight.w600,
    );
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
                        child: Column(
                          children: <Widget>[
                            for (int r = 0; r < 8; r++)
                              Expanded(
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
                    SizedBox(width: side, child: _grid(side / 8)),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              ExcludeSemantics(
                child: Row(
                  children: <Widget>[
                    const SizedBox(width: gutter),
                    for (int i = 0; i < 8; i++)
                      Expanded(
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
            ],
          );
        },
      ),
    );
  }

  Widget _grid(double s) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Column(
        children: <Widget>[
          for (int r = 0; r < 8; r++)
            Expanded(
              child: Row(
                children: <Widget>[
                  for (int c = 0; c < 8; c++)
                    Expanded(child: _square(r, c, s)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _square(int r, int c, double s) {
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
    final int variant = (row * 3 + col * 5) % ChessAssets.squareVariants;
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
              ColoredBox(color: AppColors.gold.withValues(alpha: 0.28)),
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
                padding: EdgeInsets.all(s * 0.04),
                child: ChessPieceView(piece: piece, style: pieceStyle),
              ),
            if (isTarget)
              Center(
                child: piece == 0
                    ? Container(
                        width: s * 0.30,
                        height: s * 0.30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kChessSelected.withValues(alpha: 0.85),
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
                            color: kChessSelected,
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
