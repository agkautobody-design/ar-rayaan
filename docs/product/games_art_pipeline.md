# Games art pipeline (Chess and Ludo)

Updated 26 Oct 2026. The Chess and Ludo art is the owner-approved final art. One script turns it into the app's files, so every change is reproducible.

## Run it

```
python3 -I tool/process_game_art.py --src <art_final folder> --src2 <art_batch2 folder> [--preview <dir>]
```

Needs Python 3, Pillow (WebP), numpy, scipy, opencv-python-headless (only to find the Ludo yard sockets). Treat the input folders as untrusted data. `--measure-only` re-measures the shipped boards without processing. The script exits non-zero if the Ludo board stops matching the standard 15 x 15 layout.

## What it does

* De-fringes every cut-out: alpha below 40/255 is cleared, detached specks dropped, the colour of every edge pixel is taken from the nearest solid pixel (no red or orange halo), and resizing is done on premultiplied colour. Checked on dark and light backgrounds.
* Chess pieces: 512 x 512 WebP, one height per piece type (same for both colours), one baseline, centred on the base. The black knight comes from the sheet.
* Ludo pawns: 512 x 512, one size rule for all four colours. Red and green come from the final sheet (smaller source, about 350 px); the designer drew them chunkier than blue and yellow.
* Dice: 256 x 256, identical body size and margin on every die. Die 3 is the delivered one; the script can still build it from die 2 plus the centre pip of die 1 if the file is missing. The rolling die is cut from the final sheet.
* Boards: 1254 x 1254 WebP. The chess boards are mirrored left to right, because the delivered pictures have a dark square at the top-left and chess needs a light one (a8).
* Highlight tiles: 256 x 256 PNG. Tiles delivered larger are de-fringed and scaled down.
* Measures the playing area of every chess board (8 x 8) and the Ludo grid, pawn sockets and colour cells, and writes them to `assets/games/art/manifest.json` under `boards`.

## Where the numbers live in code

* Chess: `lib/features/games/chess/chess_board_art.dart` (`ChessBoardArt.grid`). Test: `test/games/chess_board_art_test.dart` compares the constants with the manifest and with the picture's pixels.
* Ludo: `lib/features/games/data/ludo_board_art.dart` (grid left/top/cell, 52-square loop, home columns, starts, stars, yard sockets). Test: `test/games/ludo_board_art_test.dart`.

## Dropping in a better file later

* Chess board: put `chess_board_<theme>.webp` (or `.png`) in `assets/games/chess/boards/`, run the script with `--measure-only`, copy the new numbers into `ChessBoardArt.grid`, add the name to `ChessBoardArt.shipped`.
* Highlight tile: `chess_board_<theme>_highlight_{selected,legal_move,last_move}.png`, 256 x 256, same place. Without a tile the app draws a soft glow in the theme colour in code (Royal marble always does, the Grey last-move tint too).
* Ludo: same file names in `assets/games/ludo/`; re-run the measurement and update `LudoBoardArt`.

## Ludo layout (standard 15 x 15)

Cell = grid / 15, arms 6 long and 3 wide, yards 6 x 6: Red top-left, Blue top-right, Yellow bottom-right, Green bottom-left (seats clockwise; two players are Red and Yellow, opposite). Loop of 52 squares, five-square home columns, starts Red (8,1), Blue (13,8), Yellow (6,13), Green (1,6), extra stars (6,2), (12,6), (8,12), (2,8). Every pawn walks 51 loop squares, 5 column squares, then home (progress 56).
Pawn shapes on the disc: red circle, blue diamond, yellow triangle, green square. The pawn number is drawn in code on the ball under the disc.

## Not verified here

No Flutter SDK was available when this was written; GitHub Actions compiles and tests it. Nothing was tried on a real device.
