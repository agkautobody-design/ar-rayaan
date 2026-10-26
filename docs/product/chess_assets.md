# Chess board art: how it was made and what to supply

Status: shipped with the complete chess engine (branch `feat/chess-complete`).

## What the board uses

The board in the app reproduces the owner's design (the in-game screen with the
`You 09:52 / Aisha 09:37` cards, the Chess setup screen with the four board
themes, and Chess Settings). Nothing from the mock-ups is bundled whole. The
art is cut out of the design screens by one reproducible script:

    python3 tool/crop_game_boards.py GAME_SCREEN.png SETUP_SCREEN.png

(needs Pillow, numpy and scipy at tool time only), and written to
`assets/games/chess/` (about 0.3 MB in total):

| Files | What they are | Fidelity |
| --- | --- | --- |
| `squares/classic_{light,dark}_{0,1,2}.jpg` | Exact crops of empty light-wood and dark-wood squares of the owner's board (three grain variants each, tiled per square). | Pixel-faithful to the design at its 941 px width. |
| `squares/{green,blue,grey}_*.jpg` | The classic wood grain recoloured to the light and dark colours measured on the empty centre squares of the owner's theme thumbnails. | Faithful in colour, not in texture: the thumbnails are about 150 px and have pieces baked in, so a pixel-exact crop is impossible. |
| `pieces/{w,b}{p,n,b,r,q,k}.png` | The owner's glossy gold and black pieces, cut from the starting position to transparent PNGs. Each is taken from the square where it contrasts best with the wood, silhouette-filled, largest blob only, one pixel eroded and feathered. | Close to the design. Small differences: 86 x 84 px sprites (soft when shown larger than about 45 px on a 3x screen), a faint warm edge on some gold pieces where the wood tone leaked into the matte, and no baked drop shadow. |

The gold frame and the A-H / 1-8 gutter are drawn in code, not cropped. The
design bakes the letters and numbers into the picture; the app needs them as
real text for screen readers and large text. The gutter colour (`27,21,13`),
the gold rim and the blue selected-square highlight (`42,155,214`) were sampled
from the design.

If a file is missing or fails to load, the board falls back to flat colours and
the code-drawn vector pieces (`chess_pieces.dart`, also the "Modern" style), so
the game always plays.

## Please supply for pixel-exact fidelity

Drop these over the files in `assets/games/chess/` with the same names (no code
change needed; keep the PNG/JPG types):

1. Twelve piece sprites as transparent PNG at 2x or more (at least 192 x 192 px,
   the piece centred, a little margin, no board behind): `wp wn wb wr wq wk` and
   `bp bn bb br bq bk`.
2. For each of the four themes (Classic wood, Green, Blue, Grey and black), one
   empty light square and one empty dark square, 192 x 192 px (three grain
   variants each if you have them): `<theme>_light_<0-2>.jpg` and
   `<theme>_dark_<0-2>.jpg`, or one empty 8 x 8 board PNG per theme at 2x and we
   will cut the squares with the same script.
3. Optional: an "Arabic" piece set (Shah, Firzan, Fil, Faras, Rukh, Baidaq) in
   the same twelve-file layout. The Pieces Style row shows Classic and Modern
   only until this exists.

## Left out of the design on purpose

- Human faces on the player cards: the app uses an icon and the colour instead.
- "Reset Statistics" and "About Chess" rows of Chess Settings: there are no chess
  statistics to reset yet (results go to the Games history, which has its own
  clear), and the rules text lives on the game's page.
- "Allow Hints" and "Game Type: Timed / Casual": hints are always on (the engine,
  not Hadi AI), and a clock is simply optional; it is off unless chosen so there
  is no pressure on children.
- Online tables keep to moves only: no undo, hint, draw, resign or clock yet,
  because the room rules cannot referee them (see `docs/product/games_plan.md`).
