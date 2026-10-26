#!/usr/bin/env python3
"""Cut the chess board art out of the owner's design screens.

Reproducible: run from the repo root with the two design screenshots

    python3 tool/crop_game_boards.py GAME_SCREEN.png SETUP_SCREEN.png

GAME_SCREEN  = the in-game chess screen (A-H / 1-8 coordinates, wooden board,
               "You 09:52 / Aisha 09:37" clocks), 941x1672 px.
SETUP_SCREEN = the Chess setup screen with the four board-theme thumbnails.

Needs Pillow, numpy and scipy (tool-time only, never shipped).

What it writes to assets/games/chess/ :
  squares/<theme>_light_<n>.jpg, <theme>_dark_<n>.jpg
        classic = exact empty-square crops from the game screen.
        green / blue / grey = the classic grain recoloured to the light and
        dark colours measured on the empty centre squares of the owner's
        theme thumbnails (the thumbnails are ~150 px with pieces baked in, so
        a pixel-exact crop is impossible; see docs/product/chess_assets.md).
  pieces/{w,b}{p,n,b,r,q,k}.png
        the owner's glossy gold / black pieces, matted to transparent from
        the starting position. Each is cut from the square where it contrasts
        best with the wood, silhouette-filled, largest blob only.
The gold frame and the A-H / 1-8 gutter are drawn in code (real text for
screen readers and large text), using the colours printed at the end.
"""
import json
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

OUT = 'assets/games/chess'
X0, Y0, CW, CH = 75, 439, 99.25, 96.0   # board grid in the game screen
INS = 4
SQ = 96                                  # output square size (px)

LIGHT = [(1, 3), (2, 0), (2, 2), (2, 4), (2, 6), (3, 1), (3, 5), (3, 7),
         (4, 0), (4, 6), (5, 1), (5, 5), (5, 7), (6, 4), (7, 3)]
DARK = [(2, 1), (2, 7), (3, 0), (3, 2), (3, 6), (4, 1), (4, 3), (4, 5),
        (4, 7), (5, 0), (5, 4), (5, 6), (6, 3)]
# best-contrast start square (row from rank 8, col from file a) per piece
PLACE = {'wp': (6, 1), 'wr': (7, 0), 'wn': (5, 2), 'wb': (7, 1),
         'wq': (7, 2), 'wk': (7, 4), 'bp': (1, 1), 'br': (0, 0),
         'bn': (0, 6), 'bb': (0, 2), 'bq': (0, 3), 'bk': (0, 4)}
# theme thumbnails in the setup screen: x0, x1, y0, y1
THUMBS = {'green': (305, 465), 'blue': (498, 655), 'grey': (688, 835)}
THUMB_Y = (795, 938)


def cell(img, r, c, w=86, h=84):
    x0 = round(X0 + c * CW)
    y0 = round(Y0 + r * CH)
    return np.array(img.crop((x0 + INS, y0 + INS, x0 + INS + w, y0 + INS + h))).astype(float)


def save_jpg(arr, path):
    im = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8)).resize((SQ, SQ), Image.LANCZOS)
    im.save(path, quality=84, optimize=True)


def thumb_colours(setup, x0, x1):
    y0, y1 = THUMB_Y
    w, h = x1 - x0, y1 - y0
    band = np.array(setup.crop((x0 + int(w * .2), y0 + int(h * .38),
                                x1 - int(w * .2), y0 + int(h * .62)))).reshape(-1, 3).astype(float)
    lum = band.mean(axis=1)
    cut = np.median(lum)
    return np.median(band[lum >= cut], axis=0), np.median(band[lum < cut], axis=0)


def main(game_path, setup_path):
    game = Image.open(game_path).convert('RGB')
    setup = Image.open(setup_path).convert('RGB')
    os.makedirs(f'{OUT}/squares', exist_ok=True)
    os.makedirs(f'{OUT}/pieces', exist_ok=True)

    light_tiles = [cell(game, *p) for p in LIGHT]
    dark_tiles = [cell(game, *p) for p in DARK]
    bg_l, bg_d = np.mean(light_tiles, axis=0), np.mean(dark_tiles, axis=0)
    mean_l, mean_d = bg_l.mean(axis=(0, 1)), bg_d.mean(axis=(0, 1))
    # three grain variants per colour: the tiles closest to the mean look
    pick = lambda tiles, m: sorted(range(len(tiles)), key=lambda i: np.abs(tiles[i].mean(axis=(0, 1)) - m).sum())[:3]
    pl, pd = pick(light_tiles, mean_l), pick(dark_tiles, mean_d)
    for n, i in enumerate(pl):
        save_jpg(light_tiles[i], f'{OUT}/squares/classic_light_{n}.jpg')
    for n, i in enumerate(pd):
        save_jpg(dark_tiles[i], f'{OUT}/squares/classic_dark_{n}.jpg')
    report = {'classic': [mean_l.round().tolist(), mean_d.round().tolist()]}
    for name, (x0, x1) in THUMBS.items():
        tl, td = thumb_colours(setup, x0, x1)
        report[name] = [tl.round().tolist(), td.round().tolist()]
        for n, i in enumerate(pl):
            save_jpg(light_tiles[i] * (tl / mean_l), f'{OUT}/squares/{name}_light_{n}.jpg')
        for n, i in enumerate(pd):
            save_jpg(dark_tiles[i] * (td / mean_d), f'{OUT}/squares/{name}_dark_{n}.jpg')

    for key, (r, c) in PLACE.items():
        bg = bg_l if (r + c) % 2 == 0 else bg_d
        c_arr = cell(game, r, c)
        d = np.sqrt(((c_arr - bg) ** 2).sum(axis=2))
        mask = d > (72 if key[0] == 'b' else 46)
        mask = ndi.binary_opening(mask, iterations=1)
        lab, n = ndi.label(mask)
        if n:
            sizes = ndi.sum(mask, lab, range(1, n + 1))
            mask = lab == (1 + int(np.argmax(sizes)))
        mask = ndi.binary_fill_holes(ndi.binary_closing(mask, iterations=2))
        mask = ndi.binary_erosion(mask, iterations=1)
        alpha = ndi.gaussian_filter(mask.astype(float), 0.7)
        rgba = np.dstack([c_arr, alpha * 255]).clip(0, 255).astype(np.uint8)
        Image.fromarray(rgba, 'RGBA').save(f'{OUT}/pieces/{key}.png', optimize=True)

    # colours for the code-drawn frame (printed, then copied into the app)
    gutter = np.array(game.crop((46, 460, 72, 1180))).reshape(-1, 3)
    report['gutter'] = np.median(gutter, axis=0).round().tolist()
    print(json.dumps(report))


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
