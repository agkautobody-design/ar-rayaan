#!/usr/bin/env python3
"""Cuts the Ludo board art out of the owner's in-game mockup.

Reproducible: same input file, same outputs.

    python3 tool/crop_ludo_board.py --src /path/to/ludo_in_game_mockup.png

Needs: Python 3, Pillow, numpy, opencv-python-headless (OpenCV is used only
for in-painting and GrabCut, never at app run time).

Input: the 863 x 1822 px "IT'S YOUR TURN / Roll the Dice" mockup of the Ludo
screen (sha256 is printed so a changed mockup is noticed).

Output, in assets/games/ludo/ (all WebP, lossy q90 with alpha, < 0.5 MB total):

  board.webp       the wooden, gold-framed board, 863 x 686 px, rounded frame
                   silhouette on a transparent background. The pawns that are
                   baked into the mockup are in-painted away, and the 16 pawn
                   sockets of the four yards are re-pasted from the three
                   empty sockets the mockup contains (see CLEAN-UP below).
  pawn_green.webp  glossy pawn with its gold-rimmed base, transparent; cut
                   from the mockup pixels (the one pawn that stands on a
                   contrasting tile, so it separates cleanly)
  pawn_red.webp    RECOLOURED copies of the green cut: in the mockup the
  pawn_blue.webp   other pawns stand on same-coloured tiles and cannot be cut
  pawn_yellow.webp cleanly
  dice_idle.webp   the golden-glow dice render, cut from the dark backdrop

The cell positions that the game uses to put pawns on this picture are NOT
produced here: they are data in lib/features/games/data/ludo_board_art.dart
(measured on board.webp, so they can be re-tuned by hand).

CLEAN-UP, honestly: the pawn silhouettes are in-painted (cv2.INPAINT_TELEA)
and film grain is added back. On the flat coloured home-column tiles the
result is clean. In the four yards the pattern under a removed pawn is a soft
fill rather than the original ornament; the game draws pawns over those spots
and the sockets themselves are real pixels. A zoomed look at an EMPTY yard
shows the soft fill above each socket.
"""
import argparse
import hashlib
import json
import os

import cv2
import numpy as np
from PIL import Image

OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'games', 'ludo')

# Board region of the mockup (source px). Rows below are in "b-space":
# source y minus B_Y0, so that numbers match what an image viewer shows when
# the board is cropped at the top of the frame.
B_Y0 = 640
CROP = (0, 20, 863, 706)  # x0, y0, x1, y1 in b-space -> board.webp

# Frame silhouette in b-space (rounded corners by supersampled polygon).
SILHOUETTE = [
    (101, 21), (84, 26), (72, 38), (67, 54),
    (8, 704), (856, 704),
    (793, 54), (788, 38), (776, 26), (759, 21),
]

# Pawn sockets in the four yards (b-space). Order = token 0..3: TL, TR, BL, BR.
YARD_SLOTS = {
    'red': [(189, 126), (269, 123), (184, 190), (265, 190)],
    'blue': [(599, 126), (676, 126), (602, 189), (682, 187)],
    'green': [(148, 493), (238, 494), (141, 570), (235, 565)],
    'yellow': [(627, 494), (715, 488), (630, 570), (721, 570)],
}
# Which slot of each yard is an EMPTY socket in the mockup (a clean source).
EMPTY_SLOT = {'blue': 3, 'green': 3, 'yellow': 1}

# Tiles that a track pawn (or its shadow) touches in the mockup. Each job
# repaints one tile with a clean tile of the same kind: (destination rect,
# source rect), both (x, y, w, h) in b-space. Tile edges and the dark gap
# lines come along with the copy, so the track stays crisp.
TILE_JOBS = [
    # red home column (pawn at 433,160); clean tile at y 229
    ((407, 112, 54, 38), (407, 227, 54, 38)),
    ((407, 148, 54, 40), (407, 227, 54, 38)),
    ((407, 186, 54, 39), (407, 227, 54, 38)),
    # green home column (pawn at 432,497); clean tiles at y 399 and y 538
    ((405, 441, 59, 45), (405, 397, 59, 45)),
    ((405, 486, 59, 49), (405, 536, 59, 51)),
    # blue home row (pawn at 161,322); clean tile at x 242
    ((133, 299, 56, 54), (241, 299, 56, 54)),
    ((188, 299, 55, 54), (241, 299, 56, 54)),
    ((138, 257, 55, 46), (190, 257, 55, 46)),     # cream tile above
    ((127, 351, 57, 47), (182, 351, 57, 47)),     # cream tile below
    # yellow home row (green pawn at 546,320 and yellow pawn at 653,320)
    ((520, 304, 54, 47), (573, 304, 54, 47)),
    ((626, 304, 54, 47), (679, 304, 54, 47)),
    ((519, 257, 55, 46), (570, 257, 55, 46)),     # cream tile above, left
    ((622, 257, 55, 46), (570, 257, 55, 46)),     # cream tile above, right
    ((519, 351, 57, 47), (574, 351, 57, 47)),     # cream tile below, left
    ((627, 351, 57, 47), (574, 351, 57, 47)),     # cream tile below, right
]
# Pawns cut as sprites: colour -> (cx, cy)
SPRITE_SRC = {'green': (432, 497)}


def load(src):
    im = cv2.imread(src)
    if im is None:
        raise SystemExit('cannot read ' + src)
    return im[B_Y0:B_Y0 + 780].copy()


def grabcut_pawn(im, cx, cy):
    x0, y0, x1, y1 = cx - 42, cy - 50, cx + 42, cy + 38
    crop = im[y0:y1, x0:x1].copy()
    mask = np.full(crop.shape[:2], cv2.GC_PR_BGD, np.uint8)
    mask[:6, :] = cv2.GC_BGD
    mask[:, :6] = cv2.GC_BGD
    mask[:, -6:] = cv2.GC_BGD
    mask[-4:, :] = cv2.GC_BGD
    h, w = mask.shape
    cv2.ellipse(mask, (w // 2, h // 2 + 6), (18, 34), 0, 0, 360,
                cv2.GC_PR_FGD, -1)
    cv2.ellipse(mask, (w // 2, h // 2 + 4), (10, 26), 0, 0, 360,
                cv2.GC_FGD, -1)
    bg = np.zeros((1, 65))
    fg = np.zeros((1, 65))
    cv2.grabCut(crop, mask, None, bg, fg, 6, cv2.GC_INIT_WITH_MASK)
    m = np.where((mask == 1) | (mask == 3), 255, 0).astype(np.uint8)
    n, lab, st, _ = cv2.connectedComponentsWithStats(m)
    k = 1 + int(np.argmax(st[1:, 4]))
    m = (lab == k).astype(np.uint8) * 255
    m = cv2.morphologyEx(m, cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))
    m = cv2.GaussianBlur(m, (3, 3), 0)
    return crop, m, (x0, y0)


def sprite_from(im, cx, cy):
    crop, m, _ = grabcut_pawn(im, cx, cy)
    ys, xs = np.nonzero(m > 40)
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    rgba = np.dstack([crop, m])[y0:y1, x0:x1]
    return rgba


def fit_canvas(rgba, w=72, h=88):
    """Scale to fit and bottom-centre on a w x h transparent canvas."""
    sh, sw = rgba.shape[:2]
    s = min((w - 4) / sw, (h - 4) / sh)
    nw, nh = max(1, round(sw * s)), max(1, round(sh * s))
    r = cv2.resize(rgba, (nw, nh), interpolation=cv2.INTER_AREA)
    out = np.zeros((h, w, 4), np.uint8)
    ox, oy = (w - nw) // 2, h - nh - 2
    out[oy:oy + nh, ox:ox + nw] = r
    return out


def recolor(rgba, src_hue_range, target_hue, sat_gain=1.0, val_gain=1.0):
    """Hue-shift only the body colour; the gold rim and white highlights stay."""
    bgr = rgba[:, :, :3]
    hsv = cv2.cvtColor(bgr, cv2.COLOR_BGR2HSV).astype(np.float32)
    h, s, v = hsv[:, :, 0], hsv[:, :, 1], hsv[:, :, 2]
    lo, hi = src_hue_range
    body = (s > 90) & (((h >= lo) & (h <= hi)) | ((lo > hi) & ((h >= lo) | (h <= hi))))
    mid = (lo + hi) / 2 if lo <= hi else 0
    # squeeze the source hue spread so shading does not drift into the
    # neighbouring colours
    h2 = np.where(body, (target_hue + (h - mid) * 0.3) % 180, h)
    s2 = np.where(body, np.clip(s * sat_gain, 0, 255), s)
    v2 = np.where(body, np.clip(v * val_gain, 0, 255), v)
    out = cv2.cvtColor(np.dstack([h2, s2, v2]).astype(np.uint8), cv2.COLOR_HSV2BGR)
    return np.dstack([out, rgba[:, :, 3]])


def silhouette_alpha(w, h, ox, oy):
    ss = 4
    big = np.zeros((h * ss, w * ss), np.uint8)
    pts = np.array([[(x - ox) * ss, (y - oy) * ss] for x, y in SILHOUETTE],
                   np.int32)
    cv2.fillPoly(big, [pts], 255)
    return cv2.resize(big, (w, h), interpolation=cv2.INTER_AREA)


def clean_board(im):
    out = im.copy()
    # 1. keep clean sockets from the three empty slots
    patches = {}
    rx, ry = 30, 26
    for yard, k in EMPTY_SLOT.items():
        cx, cy = YARD_SLOTS[yard][k]
        patches[yard] = im[cy - 34:cy + 34, cx - 36:cx + 36].copy()
    # a socket for the red yard: the blue one with every blue pixel turned
    # red (the gold rim keeps its hue)
    blue = patches['blue'].copy()
    hsv = cv2.cvtColor(blue, cv2.COLOR_BGR2HSV)
    hh = hsv[:, :, 0].astype(np.int32)
    isblue = (hh >= 95) & (hh <= 135) & (hsv[:, :, 1] > 60)
    hsv[:, :, 0] = np.where(isblue, (hh + 70) % 180, hh).astype(np.uint8)
    patches['red'] = cv2.cvtColor(hsv, cv2.COLOR_HSV2BGR)

    # 2. in-paint masks
    mask = np.zeros(im.shape[:2], np.uint8)
    for yard, slots in YARD_SLOTS.items():
        for cx, cy in slots:
            cv2.rectangle(mask, (cx - 34, cy - 48), (cx + 34, cy + 26), 255, -1)
    mask = cv2.dilate(mask, np.ones((5, 5), np.uint8))
    painted = cv2.inpaint(out, mask, 7, cv2.INPAINT_TELEA)
    for (dx, dy, dw, dh), (sx, sy, sw, sh) in TILE_JOBS:
        tile = im[sy:sy + sh, sx:sx + sw]
        painted[dy:dy + dh, dx:dx + dw] = cv2.resize(
            tile, (dw, dh), interpolation=cv2.INTER_AREA)
    # film grain, so the filled spots are not plastic-flat
    rng = np.random.default_rng(7)
    grain = rng.normal(0, 3.2, painted.shape[:2]).astype(np.float32)
    g3 = np.dstack([grain] * 3)
    soft = cv2.GaussianBlur(mask, (9, 9), 0).astype(np.float32)[:, :, None] / 255
    painted = np.clip(painted.astype(np.float32) + g3 * soft, 0, 255).astype(np.uint8)

    # 3. paste sockets into all 16 slots
    yy, xx = np.mgrid[-34:34, -36:36]
    ell = ((xx / rx) ** 2 + (yy / ry) ** 2)
    alpha = np.clip((1.12 - ell) / 0.22, 0, 1).astype(np.float32)[:, :, None]
    for yard, slots in YARD_SLOTS.items():
        p = patches[yard].astype(np.float32)
        for cx, cy in slots:
            reg = painted[cy - 34:cy + 34, cx - 36:cx + 36].astype(np.float32)
            painted[cy - 34:cy + 34, cx - 36:cx + 36] = (
                reg * (1 - alpha) + p * alpha).astype(np.uint8)
    return painted


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--src', required=True)
    a = ap.parse_args()
    with open(a.src, 'rb') as f:
        print('source sha256', hashlib.sha256(f.read()).hexdigest())
    im = load(a.src)
    os.makedirs(OUT, exist_ok=True)

    # sprites first (they need the original pixels)
    spr = {n: sprite_from(im, cx, cy) for n, (cx, cy) in SPRITE_SRC.items()}
    green = fit_canvas(spr['green'])
    # The mockup's red pawn comes with a smear of the tile above it, and the
    # blue and yellow ones stand on same-coloured tiles. All three are
    # therefore hue-shifted copies of the clean green cut.
    red = recolor(green, (40, 90), 3, 1.25, 1.15)
    blue = recolor(green, (40, 90), 108, 1.05, 1.0)
    yellow = recolor(green, (40, 90), 27, 0.8, 1.9)
    for name, arr in [('red', red), ('green', green), ('blue', blue),
                      ('yellow', yellow)]:
        rgba = cv2.cvtColor(arr, cv2.COLOR_BGRA2RGBA)
        Image.fromarray(rgba).save(os.path.join(OUT, f'pawn_{name}.webp'),
                                   quality=92, method=6)

    board = clean_board(im)
    x0, y0, x1, y1 = CROP
    alpha = silhouette_alpha(x1 - x0, y1 - y0, x0, y0)
    rgb = cv2.cvtColor(board[y0:y1, x0:x1], cv2.COLOR_BGR2RGB)
    Image.fromarray(np.dstack([rgb, alpha])).save(
        os.path.join(OUT, 'board.webp'), quality=90, method=6)

    # dice render: GrabCut from the glow behind it, interior holes filled
    # (the pips are dark and would otherwise be cut out).
    srcfull = cv2.imread(a.src)
    d = srcfull[1370:1545, 340:520].copy()
    mask = np.full(d.shape[:2], cv2.GC_PR_BGD, np.uint8)
    mask[:8, :] = cv2.GC_BGD
    mask[:, :15] = cv2.GC_BGD
    mask[:, -15:] = cv2.GC_BGD
    mask[-10:, :] = cv2.GC_BGD
    cv2.ellipse(mask, (90, 88), (62, 66), 0, 0, 360, cv2.GC_PR_FGD, -1)
    cv2.ellipse(mask, (90, 88), (45, 48), 0, 0, 360, cv2.GC_FGD, -1)
    cv2.grabCut(d, mask, None, np.zeros((1, 65)), np.zeros((1, 65)), 8,
                cv2.GC_INIT_WITH_MASK)
    m = np.where((mask == 1) | (mask == 3), 255, 0).astype(np.uint8)
    n, lab, st, _ = cv2.connectedComponentsWithStats(m)
    k = 1 + int(np.argmax(st[1:, 4]))
    m = (lab == k).astype(np.uint8) * 255
    m = cv2.morphologyEx(m, cv2.MORPH_OPEN, np.ones((5, 5), np.uint8))
    # fill holes: flood the outside, everything not reached is inside
    flood = m.copy()
    ff = np.zeros((m.shape[0] + 2, m.shape[1] + 2), np.uint8)
    cv2.floodFill(flood, ff, (0, 0), 255)
    m = m | cv2.bitwise_not(flood)
    m = cv2.GaussianBlur(m, (5, 5), 0)
    ys, xs = np.nonzero(m > 40)
    box = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
    rgba = np.dstack([cv2.cvtColor(d, cv2.COLOR_BGR2RGB), m])
    rgba = rgba[box[1]:box[3], box[0]:box[2]]
    Image.fromarray(rgba).save(os.path.join(OUT, 'dice_idle.webp'),
                               quality=92, method=6)
    print('done')


if __name__ == '__main__':
    main()
