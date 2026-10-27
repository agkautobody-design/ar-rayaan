#!/usr/bin/env python3
"""Processes the owner's approved Chess and Ludo art into the app's assets.

Reproducible: same input folder, same output files.

    python3 tool/process_game_art.py --src /path/to/art_final \
        [--preview /tmp/preview]

Needs: Python 3, Pillow (with WebP), numpy, scipy and opencv-python-headless
(OpenCV only to find the four yard sockets of the Ludo board; never used at
app run time). Treat the --src folder as untrusted data: run this script with
`python3 -I` from a different directory.

INPUT (the owner-approved final art, 1254 x 1254 RGBA unless noted)
  chess_{w,b}_{king,queen,rook,bishop,knight,pawn}.png   (no black knight)
  _sheet_blackknight.png   2172 x 724; the black knight is the left third
  ludo_pawn_{blue,yellow}.png
  _sheet_final.png         1536 x 1024; final RED pawn (circle on the disc),
                           final GREEN pawn (square on the disc) and the
                           rolling die are cropped out of it
  ludo_die_{1,2,4,5,6}.png (die 3 was never delivered: it is BUILT here)
  chess_board_black_cream.png, chess_board_green.png, ludo_board_empty.png

SECOND BATCH (--src2, optional, same trust rules)
  ludo_die_3.png                        the REAL die 3 (256 x 256); used instead
                                        of the synthesised one when present
  chess_board_{blue,grey}.png, chess_board_classic_wood.png
                                        framed boards (2048 or 1254), scaled to
                                        1254; the wood one becomes theme "classic"
  chess_board_{green,blue,grey,classic_wood}_highlight_{selected,legal_move,
  last_move}.png                        tiles; those larger than 256 are
                                        de-fringed and scaled to 256, saved PNG

OUTPUT (WebP, lossy q88 with lossless alpha; the repo already ships WebP)
  assets/games/chess/pieces/{w,b}{p,n,b,r,q,k}.webp         512 x 512
  assets/games/chess/boards/chess_board_{royal,green,blue,grey,classic}.webp  1254 x 1254
  assets/games/chess/boards/chess_board_<theme>_highlight_*.png        256 x 256
  assets/games/ludo/pawn_{red,blue,yellow,green}.webp       512 x 512
  assets/games/ludo/die_{1..6}.webp, die_rolling.webp       256 x 256
  assets/games/ludo/board.webp                              1254 x 1254
  assets/games/art/manifest.json  -> "boards": measured geometry

WHAT IT DOES TO EVERY CUT-OUT (pieces, pawns, dice, rolling die, board edge)
  1. De-fringe. The designer's PNGs carry a red/orange glow in the faint,
     semi-transparent pixels at the edge. We (a) clip alpha below 40/255 to
     fully transparent and drop detached specks, (b) rescale the remaining
     alpha so the faintest kept pixel is faint rather than 40/255 strong, and
     (c) replace the COLOUR of every non-opaque pixel with the colour of the
     nearest fully opaque pixel (so a gold rim ends in gold, not in orange
     glow). Resampling is done on premultiplied colour, so no new halo is
     created by the downscale.
  2. Crop to the alpha bounding box and place on the square canvas with a
     shared baseline and centring:
       chess pieces  one height per piece TYPE (king tallest ... pawn
                     shortest, the same for both colours), bottom on one
                     baseline, centred on the middle of the base
       ludo pawns    one scale rule for all four colours (equal geometric
                     mean of width and height) because the designer drew the
                     red/green pawns chunkier than the blue/yellow ones;
                     same baseline, centred on the base
       dice          IDENTICAL body size and margin on every die (dice 4 and
                     5 were delivered larger than 1, 2 and 6)
     Chess boards are also mirrored left-right: the delivered pictures have a
     dark square top-left, chess needs a light one (a8), so the pieces would
     otherwise stand on the wrong colours.
  3. (Only without --src2) Die 3 = die 2 (pips top-left and bottom-right) + the centre pip cut from
     die 1 (same normalised size, so it lands exactly on the die centre),
     with a soft circular mask.
  4. Measures the boards: the 8x8 playing area inside the chess frames, and
     the 15x15 grid, the pawn sockets and the colour cells of the Ludo board.
     It checks the Ludo cells against the standard-board expectations and
     exits non-zero if the picture does not match. The numbers go to
     assets/games/art/manifest.json ("boards") and must equal the constants
     in lib/features/games/chess/chess_board_art.dart and
     lib/features/games/data/ludo_board_art.dart (a Dart test checks this).

The grey "last move" tile was delivered opaque and fringed, so it is skipped and
the app draws a soft silver-gold tint in code; see docs/product/games_art_pipeline.md.
"""
import argparse
import hashlib
import json
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
ALPHA_CUT = 40  # alpha below this (of 255) becomes fully transparent
WEBP_Q = 88

# Height of each chess piece type, as a fraction of the 512 canvas.
PIECE_HEIGHT = {'k': 0.93, 'q': 0.89, 'b': 0.82, 'n': 0.78, 'r': 0.70, 'p': 0.64}
PIECE_MAX_WIDTH = 0.86
PIECE_BASELINE = 0.97  # bottom of every piece, fraction of the canvas height
PIECE_PX = 512
PAWN_GEO_MEAN = 0.74  # sqrt(w*h) of every Ludo pawn, fraction of the canvas
PAWN_BASELINE = 0.96
DIE_PX = 256
DIE_BODY = 0.90  # body width of every die, fraction of the canvas


# ------------------------------------------------------------------ helpers
def load(path):
    return np.array(Image.open(path).convert('RGBA'))


def defringe(arr, cut=ALPHA_CUT, speck=0.02, reach=None):
    """See the module docstring, step 1. Returns a new RGBA uint8 array.

    [reach]: when set, only pixels within that many source pixels of the opaque
    core get the nearest-core colour (keeps the motion blur of the rolling die
    soft instead of striped).
    """
    a = arr[..., 3].astype(np.float32)
    a[a < cut] = 0
    lab, n = ndi.label(a > 0, structure=np.ones((3, 3)))
    if n > 1:
        sizes = ndi.sum(a > 0, lab, range(1, n + 1))
        keep = np.zeros(n + 1, bool)
        keep[1:] = sizes >= sizes.max() * speck
        a[~keep[lab]] = 0
    a = np.clip((a - cut) / (255.0 - cut), 0, 1) * 255.0
    core = a >= 250
    eroded = ndi.binary_erosion(core, iterations=1)  # keep colour from the inside
    if eroded.sum() > 0.5 * core.sum():
        core = eroded
    dist, (iy, ix) = ndi.distance_transform_edt(~core, return_indices=True)
    rgb = arr[..., :3][iy, ix]
    replace = (a < 250) | (~core)
    if reach is not None:
        replace &= dist <= reach
    out = arr[..., :3].copy()
    out[replace] = rgb[replace]
    out[a == 0] = rgb[a == 0]  # colour under transparent pixels: no red glow
    res = np.dstack([out, np.rint(a).astype(np.uint8)])
    return res


def bbox(arr, thr=1):
    ys, xs = np.where(arr[..., 3] >= thr)
    return xs.min(), ys.min(), xs.max() + 1, ys.max() + 1


def resize_premul(arr, size):
    im = Image.fromarray(arr, 'RGBA').convert('RGBa')
    im = im.resize(size, Image.LANCZOS)
    return im.convert('RGBA')


def place(arr, box, scale, canvas, anchor_x, baseline_y=None, centre_y=None):
    """Scales crop [box] of [arr] by [scale] and pastes it on a transparent
    square canvas: horizontally so that [anchor_x] (source x) is the middle;
    vertically with the crop bottom on [baseline_y] or its middle on
    [centre_y]."""
    x0, y0, x1, y1 = box
    crop = arr[y0:y1, x0:x1]
    w = max(1, int(round((x1 - x0) * scale)))
    h = max(1, int(round((y1 - y0) * scale)))
    im = resize_premul(crop, (w, h))
    out = Image.new('RGBA', (canvas, canvas), (0, 0, 0, 0))
    left = int(round(canvas / 2 - (anchor_x - x0) * scale))
    if baseline_y is not None:
        top = int(round(baseline_y - h))
    else:
        top = int(round(centre_y - h / 2))
    _paste_clipped(out, im, left, top)
    return out


def _paste_clipped(out, im, left, top):
    tmp = Image.new('RGBA', out.size, (0, 0, 0, 0))
    tmp.paste(im, (left, top))
    out.alpha_composite(tmp)


def base_centre(arr, box):
    """x middle of the lowest 8% of the piece: its base, not its head."""
    x0, y0, x1, y1 = box
    h = y1 - y0
    band = arr[max(y0, y1 - int(h * 0.08)):y1, x0:x1, 3] > 0
    xs = np.where(band.any(0))[0]
    return x0 + (xs.min() + xs.max() + 1) / 2.0


def save_webp(img, path, quality=WEBP_Q):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, 'WEBP', quality=quality, alpha_quality=100, method=6)


def alpha_free(img):
    a = np.array(img)[..., 3]
    return bool((a == 255).all())


# ------------------------------------------------------------------- chess
def chess_pieces(src, out_root, report):
    names = {'king': 'k', 'queen': 'q', 'rook': 'r', 'bishop': 'b', 'knight': 'n', 'pawn': 'p'}
    srcs = {}
    for colour, c in (('w', 'w'), ('b', 'b')):
        for long, short in names.items():
            if (c, long) == ('b', 'knight'):
                sheet = load(os.path.join(src, '_sheet_blackknight.png'))
                third = sheet[:, : sheet.shape[1] // 3]
                srcs[(c, short)] = third
            else:
                srcs[(c, short)] = load(os.path.join(src, 'chess_%s_%s.png' % (c, long)))
    for (c, t), arr in srcs.items():
        arr = defringe(arr)
        box = bbox(arr)
        w, h = box[2] - box[0], box[3] - box[1]
        s = PIECE_HEIGHT[t] * PIECE_PX / h
        s = min(s, PIECE_MAX_WIDTH * PIECE_PX / w)
        img = place(arr, box, s, PIECE_PX, base_centre(arr, box), baseline_y=PIECE_BASELINE * PIECE_PX)
        save_webp(img, os.path.join(out_root, 'assets/games/chess/pieces/%s%s.webp' % (c, t)))
        report['pieces'][c + t] = {'src_box': [int(v) for v in box], 'scale': round(float(s), 4)}


def clean_board(arr, cut=24):
    """De-fringes a framed board and snaps near-opaque alpha (the designer's
    files carry 250-254 everywhere) to fully opaque."""
    arr = arr.copy()
    arr[..., 3][arr[..., 3] >= 200] = 255  # the 250-254 haze must not count as edge
    if (arr[..., 3] < 255).any():
        arr = defringe(arr, cut=cut)
        arr[..., 3][arr[..., 3] >= 245] = 255
    return arr


def chess_boards(src, src2, out_root, report):
    jobs = [(src, 'chess_board_black_cream.png', 'royal'), (src, 'chess_board_green.png', 'green')]
    for fname, theme in (('chess_board_blue.png', 'blue'), ('chess_board_grey.png', 'grey'),
                         ('chess_board_classic_wood.png', 'classic')):
        if src2 and os.path.exists(os.path.join(src2, fname)):
            jobs.append((src2, fname, theme))
    for folder, srcname, theme in jobs:
        arr = clean_board(load(os.path.join(folder, srcname)))
        # The delivered boards have a DARK square at the top-left. In chess the
        # square at White's bottom-left (a1) is dark, so the top-left (a8) is
        # light. Mirror left-right so every square has its correct colour.
        arr = np.ascontiguousarray(arr[:, ::-1])
        img = Image.fromarray(arr, 'RGBA')
        if img.width != 1254:
            img = resize_premul(arr, (1254, 1254))
        if alpha_free(img):
            img = img.convert('RGB')
        save_webp(img, os.path.join(out_root, 'assets/games/chess/boards/chess_board_%s.webp' % theme), quality=84)
    if src2:
        for theme, prefix in (('green', 'green'), ('blue', 'blue'), ('grey', 'grey'), ('classic', 'classic_wood')):
            for kind in ('selected', 'legal_move', 'last_move'):
                if (theme, kind) == ('grey', 'last_move'):
                    continue  # delivered opaque and fringed: the app draws a soft tint in code
                p = os.path.join(src2, 'chess_board_%s_highlight_%s.png' % (prefix, kind))
                if not os.path.exists(p):
                    p = os.path.join(src2, 'chess_board_%s_highlight_%s.png' % (theme, kind))
                if not os.path.exists(p):
                    continue
                arr = load(p)
                if arr.shape[0] != 256:
                    # delivered larger: clean the red specks and glow fringe,
                    # then scale to 256 on premultiplied colour.
                    arr = defringe(arr, cut=16, reach=4)
                    im = resize_premul(arr, (256, 256))
                else:
                    im = Image.fromarray(arr, 'RGBA')
                dst = os.path.join(out_root, 'assets/games/chess/boards',
                                   'chess_board_%s_highlight_%s.png' % (theme, kind))
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                im.save(dst, 'PNG', optimize=True)


# -------------------------------------------------------------------- ludo
def ludo_pawns(src, out_root, report):
    sheet = load(os.path.join(src, '_sheet_final.png'))
    pawns = {
        'blue': load(os.path.join(src, 'ludo_pawn_blue.png')),
        'yellow': load(os.path.join(src, 'ludo_pawn_yellow.png')),
        # final red (circle on the disc) and green (square) from the sheet;
        # the boards start at y=420, the pawns end at about y=412.
        'red': sheet[0:416, 0:383],
        'green': sheet[0:416, 383:765],
    }
    for name, arr in pawns.items():
        arr = defringe(arr)
        box = bbox(arr)
        w, h = box[2] - box[0], box[3] - box[1]
        s = PAWN_GEO_MEAN * PIECE_PX / np.sqrt(w * h)
        img = place(arr, box, s, PIECE_PX, base_centre(arr, box), baseline_y=PAWN_BASELINE * PIECE_PX)
        save_webp(img, os.path.join(out_root, 'assets/games/ludo/pawn_%s.webp' % name))
        report['pawns'][name] = {'src_box': [int(v) for v in box], 'scale': round(float(s), 4)}


def _die_norm(arr):
    """Defringed die and its body box."""
    arr = defringe(arr)
    return arr, bbox(arr)


def ludo_dice(src, src2, out_root, report):
    dice = {}
    for n in (1, 2, 4, 5, 6):
        dice[n] = _die_norm(load(os.path.join(src, 'ludo_die_%d.png' % n)))
    real3 = os.path.join(src2, 'ludo_die_3.png') if src2 else None
    if real3 and os.path.exists(real3):
        dice[3] = _die_norm(load(real3))

    # Normalise every die to one 1254-style frame: body width 1000 px, centred.
    FR, BODY = 1254, 1000.0

    def to_frame(n):
        arr, (x0, y0, x1, y1) = dice[n]
        s = BODY / max(x1 - x0, y1 - y0)
        return place(arr, (x0, y0, x1, y1), s, FR, (x0 + x1) / 2.0, centre_y=FR / 2.0), s

    framed = {}
    for n in dice:
        im, s = to_frame(n)
        framed[n] = np.array(im)
        report['dice'][str(n)] = {'src_box': [int(v) for v in dice[n][1]], 'scale_to_frame': round(float(s), 4)}

    if 3 in dice:
        report['dice']['3'] = {'source': 'delivered die 3 (second batch)'}
    else:
        _build_die3(framed, report, FR)

    for n, arr in framed.items():
        # frame (1254) -> canvas: body DIE_BODY of the canvas.
        s = (DIE_BODY * DIE_PX) / BODY
        im = place(arr, (0, 0, FR, FR), s, DIE_PX, FR / 2.0, centre_y=DIE_PX / 2.0)
        save_webp(im, os.path.join(out_root, 'assets/games/ludo/die_%d.webp' % n), quality=90)

    _rolling_die(src, out_root, report)


def _build_die3(framed, report, FR):
    """Fallback when die 3 was not delivered: die 2 + centre pip of die 1."""
    d1, d2 = framed[1], framed[2]
    cy = cx = FR / 2.0
    lum = d1[..., :3].astype(float).max(2)
    yy, xx = np.mgrid[0:FR, 0:FR]
    near = (np.hypot(xx - cx, yy - cy) < 160) & (lum < 60) & (d1[..., 3] > 200)
    ys, xs = np.where(near)
    pcx, pcy = xs.mean(), ys.mean()
    r_dark = np.sqrt(near.sum() / np.pi)
    # Gold ring: walk outwards from the dark disc until the colour is marble
    # cream again (bright, low saturation) - that radius is the ring's outer edge.
    prof = []
    for r in range(int(r_dark), int(r_dark * 2.2)):
        th = np.linspace(0, 2 * np.pi, 90, endpoint=False)
        px = d1[(pcy + r * np.sin(th)).astype(int), (pcx + r * np.cos(th)).astype(int), :3].astype(float)
        sat = (px.max(1) - px.min(1)).mean()
        prof.append((r, sat))
    ring_out = max(prof, key=lambda t: t[1])[0]
    # first radius after the saturation peak where saturation falls to marble level
    peak_sat = max(p[1] for p in prof)
    ring_end = next((r for r, sat in prof if r > ring_out and sat < peak_sat * 0.45), ring_out + 8)
    R = ring_end + 4
    d = np.hypot(xx - pcx, yy - pcy)
    mask = np.clip((R + 6 - d) / 6.0, 0, 1)[..., None]  # 6 px feather at the rim
    # Place the pip at die 2's body centre (the frames are already centred).
    dx, dy = int(round(cx - pcx)), int(round(cy - pcy))
    shifted = np.roll(np.roll(d1, dy, axis=0), dx, axis=1)
    m_shift = np.roll(np.roll(mask, dy, axis=0), dx, axis=1)
    d3 = (d2.astype(float) * (1 - m_shift) + shifted.astype(float) * m_shift)
    d3[..., 3] = np.maximum(d2[..., 3], 0)
    framed[3] = np.clip(d3, 0, 255).astype(np.uint8)
    report['dice']['3'] = {'built_from': 'die 2 + centre pip of die 1', 'pip_radius_px': int(R), 'pip_centre_offset_px': [int(dx), int(dy)]}



def _rolling_die(src, out_root, report):
    # Rolling die: crop from the final sheet (tilted die, motion blur on the left).
    sheet = load(os.path.join(src, '_sheet_final.png'))
    roll = sheet[56:420, 1090:1536]
    roll = defringe(roll, reach=3)
    box = bbox(roll)
    w, h = box[2] - box[0], box[3] - box[1]
    s = min(DIE_PX * 0.96 / w, DIE_PX * 0.96 / h)
    im = place(roll, box, s, DIE_PX, (box[0] + box[2]) / 2.0, centre_y=DIE_PX / 2.0)
    save_webp(im, os.path.join(out_root, 'assets/games/ludo/die_rolling.webp'), quality=90)
    report['dice']['rolling'] = {'src_box': [int(v) for v in box], 'scale': round(float(s), 4)}


def ludo_board(src, out_root, report):
    arr = load(os.path.join(src, 'ludo_board_empty.png'))
    arr = clean_board(arr)
    img = Image.fromarray(arr, 'RGBA')
    save_webp(img, os.path.join(out_root, 'assets/games/ludo/board.webp'), quality=86)


# ------------------------------------------------------------ measurement
def _edge_profile(lum, axis, lo, hi):
    """|d lum| averaged over the band [lo, hi) of the other axis."""
    g = np.abs(np.diff(lum, axis=axis))
    return g[lo:hi, :].mean(0) if axis == 1 else g[:, lo:hi].mean(1)


def _peak(profile, centre, half=5):
    lo, hi = int(centre - half), int(centre + half + 1)
    seg = profile[lo:hi]
    i = int(np.argmax(seg))
    j = lo + i
    # centroid of the peak (3 samples) for a sub-pixel edge; diff index i is the
    # edge between pixel i and i+1, i.e. at coordinate i + 1.
    w = profile[max(j - 1, 0): j + 2]
    xs = np.arange(max(j - 1, 0), max(j - 1, 0) + len(w))
    return float((w * xs).sum() / w.sum()) + 1.0


def _fit(ks, es):
    k = np.array(ks, float)
    e = np.array(es, float)
    A = np.vstack([np.ones_like(k), k]).T
    (x0, s), *_ = np.linalg.lstsq(A, e, rcond=None)
    resid = float(np.abs(A @ np.array([x0, s]) - e).max())
    return float(x0), float(s), resid


def measure_chess(path):
    im = np.array(Image.open(path).convert('RGB')).astype(float)
    lum = im.mean(2)
    n = lum.shape[0]
    out = {}
    est = n * 0.0555  # first estimate of the grid origin (frame ~5.5% of the side)
    cell = (n - 2 * est) / 8.0
    px = _edge_profile(lum, 1, int(n * 0.16), int(n * 0.84))
    py = _edge_profile(lum, 0, int(n * 0.16), int(n * 0.84))
    for key, prof in (('x', px), ('y', py)):
        ks = list(range(1, 8))
        es = [_peak(prof, est + k * cell, half=8) for k in ks]
        o, s, resid = _fit(ks, es)
        out[key] = (o, s, resid)
    return {
        'image': [int(lum.shape[1]), int(lum.shape[0])],
        'left': round(out['x'][0], 1), 'top': round(out['y'][0], 1),
        'width': round(out['x'][1] * 8, 1), 'height': round(out['y'][1] * 8, 1),
        'fit_residual_px': round(max(out['x'][2], out['y'][2]), 2),
    }


# Standard 15x15 Ludo expectations (col, row) from the top-left of the grid.
LUDO_COLUMNS = {
    'red': [(7, r) for r in range(1, 6)],
    'blue': [(c, 7) for c in range(9, 14)],
    'yellow': [(7, r) for r in range(9, 14)],
    'green': [(c, 7) for c in range(1, 6)],
}
LUDO_START = {'red': (8, 1), 'blue': (13, 8), 'yellow': (6, 13), 'green': (1, 6)}
LUDO_STARS = [(6, 2), (12, 6), (8, 12), (2, 8)]
LUDO_YARDS = {'red': (0, 0), 'blue': (9, 0), 'yellow': (9, 9), 'green': (0, 9)}


def classify(rgb):
    r, g, b = [float(v) for v in rgb]
    if r > 195 and g > 175 and b > 130 and (max(r, g, b) - min(r, g, b)) < 90:
        return 'cream'
    if r > 160 and g < 90 and b < 90:
        return 'red'
    if b > 110 and r < 80 and g < 120:
        return 'blue'
    if r > 170 and g > 120 and b < 90:
        return 'yellow'
    if g > 80 and r < 90 and b < 90:
        return 'green'
    return 'other'


def sample(img, x, y, half=7):
    p = img[int(y - half): int(y + half), int(x - half): int(x + half), :3].reshape(-1, 3)
    return np.median(p, axis=0)


def measure_ludo(path):
    rgba = Image.open(path).convert('RGBA')
    bg = Image.new('RGBA', rgba.size, (0, 0, 0, 255))
    bg.alpha_composite(rgba)
    img = np.array(bg.convert('RGB'))
    lum = img.astype(float).mean(2)
    n = lum.shape[0]
    g0, cell = 77.0, 73.6  # first estimate; the fit below replaces it
    # x edges: left/right arms (rows 6-8 band) for k<=5 and k>=10, top/bottom
    # arms (rows 0-5 band) for 6<=k<=9; same for y.
    band_mid = (int(g0 + 6.15 * cell), int(g0 + 8.85 * cell))
    band_top = (int(g0 + 0.3 * cell), int(g0 + 5.7 * cell))
    band_bot = (int(g0 + 9.3 * cell), int(g0 + 14.7 * cell))
    pts = {}
    for key, axis in (('x', 1), ('y', 0)):
        ks, es = [], []
        for k in range(1, 15):
            lo, hi = band_mid if (k <= 5 or k >= 10) else band_top
            prof = _edge_profile(lum, axis, lo, hi)
            ks.append(k)
            es.append(_peak(prof, g0 + k * cell, half=4))
        pts[key] = (np.array(ks, float), np.array(es, float))
    # Square cells: one cell size from both axes, one origin per axis. The
    # bevels of the cells make single edges wander by up to ~3 px, which is
    # noise, so the fit is over all 14 inner edges per axis.
    sizes = [_fit(*pts[k])[1] for k in ('x', 'y')]
    cw = ch = float(np.mean(sizes))
    left = float(np.mean(pts['x'][1] - pts['x'][0] * cw))
    top = float(np.mean(pts['y'][1] - pts['y'][0] * ch))
    resid = max(float(np.abs(pts['x'][1] - (left + pts['x'][0] * cw)).max()),
                float(np.abs(pts['y'][1] - (top + pts['y'][0] * ch)).max()))
    res = {'x': (left, cw, resid), 'y': (top, ch, resid)}

    def centre(c, r):
        return left + (c + 0.5) * cw, top + (r + 0.5) * ch

    checks, bad = [], []
    for colour, cells in LUDO_COLUMNS.items():
        for (c, r) in cells:
            got = classify(sample(img, *centre(c, r)))
            checks.append((colour, c, r, got))
            if got != colour:
                bad.append('home column %s cell (%d,%d) is %s' % (colour, c, r, got))
    for colour, (c, r) in LUDO_START.items():
        x, y = centre(c, r)  # the star sits in the middle: sample the corner
        got = classify(sample(img, x - 0.3 * cw, y - 0.3 * ch, half=5))
        if got != colour:
            bad.append('start %s (%d,%d) is %s' % (colour, c, r, got))
    # Stars: cream cells carrying a gold star => darker/yellow mean than plain cream
    for (c, r) in LUDO_STARS:
        x, y = centre(c, r)
        p = img[int(y - 12): int(y + 12), int(x - 12): int(x + 12), :3].reshape(-1, 3).astype(float)
        gold = ((p[:, 0] > 150) & (p[:, 1] > 100) & (p[:, 2] < 100)).mean()
        if gold < 0.03:
            bad.append('no gold star at (%d,%d)' % (c, r))
    # Yard sockets via Hough circles (rim of each hole).
    import cv2
    gray = cv2.GaussianBlur(cv2.cvtColor(img, cv2.COLOR_RGB2GRAY), (0, 0), 2)
    yards = {}
    for colour, (c0, r0) in LUDO_YARDS.items():
        x0, y0 = int(left + c0 * cw), int(top + r0 * ch)
        s = int(6 * cw)
        sub = gray[y0:y0 + s, x0:x0 + s]
        found = cv2.HoughCircles(sub, cv2.HOUGH_GRADIENT, dp=1, minDist=100, param1=100,
                                 param2=25, minRadius=30, maxRadius=48)
        pts = []
        if found is not None:
            for x, y, rad in found[0]:
                u, v = (x + x0 - left) / cw, (y + y0 - top) / ch
                if 0.8 < u - c0 < 5.2 and 0.8 < v - r0 < 5.2:
                    pts.append((round(float(u), 2), round(float(v), 2)))
        pts.sort(key=lambda p: (round(p[1]), p[0]))  # top-left, top-right, bottom-left, bottom-right
        pts = sorted(pts, key=lambda p: p[1])
        top2 = sorted(pts[:2], key=lambda p: p[0])
        bot2 = sorted(pts[2:4], key=lambda p: p[0])
        yards[colour] = top2 + bot2
        if len(yards[colour]) != 4:
            bad.append('yard %s: found %d sockets' % (colour, len(yards[colour])))
    return {
        'image': [int(n), int(n)],
        'left': round(left, 2), 'top': round(top, 2),
        'cell': round(cw, 2),
        'fit_residual_px': round(max(res['x'][2], res['y'][2]), 2),
        'yard_sockets': yards,
    }, bad


def draw_overlay(path, geo, outpath):
    from PIL import ImageDraw
    rgba = Image.open(path).convert('RGBA')
    bg = Image.new('RGBA', rgba.size, (60, 0, 60, 255))
    bg.alpha_composite(rgba)
    d = ImageDraw.Draw(bg)
    l, t = geo['left'], geo['top']
    cw = ch = geo['cell']
    for k in range(16):
        d.line([(l + k * cw, t), (l + k * cw, t + 15 * ch)], fill=(255, 255, 255, 255), width=1)
        d.line([(l, t + k * ch), (l + 15 * cw, t + k * ch)], fill=(255, 255, 255, 255), width=1)
    def box(c, r, col):
        d.rectangle([l + c * cw + 3, t + r * ch + 3, l + (c + 1) * cw - 3, t + (r + 1) * ch - 3], outline=col, width=3)
    for cells in LUDO_COLUMNS.values():
        for c, r in cells:
            box(c, r, (255, 0, 255, 255))
    for c, r in LUDO_START.values():
        box(c, r, (0, 255, 255, 255))
    for c, r in LUDO_STARS:
        box(c, r, (255, 255, 0, 255))
    for pts in geo['yard_sockets'].values():
        for u, v in pts:
            x, y = l + u * cw, t + v * ch
            d.ellipse([x - 6, y - 6, x + 6, y + 6], fill=(0, 255, 0, 255))
    bg.convert('RGB').save(outpath)


def draw_chess_overlay(path, geo, outpath):
    from PIL import ImageDraw
    im = Image.open(path).convert('RGB')
    d = ImageDraw.Draw(im)
    l, t, w, h = geo['left'], geo['top'], geo['width'], geo['height']
    for k in range(9):
        d.line([(l + k * w / 8, t), (l + k * w / 8, t + h)], fill=(255, 0, 255), width=2)
        d.line([(l, t + k * h / 8), (l + w, t + k * h / 8)], fill=(255, 0, 255), width=2)
    im.save(outpath)


def contact_sheet(files, outpath, bg):
    tile = 256
    cols = 6
    rows = (len(files) + cols - 1) // cols
    sheet = Image.new('RGB', (tile * cols, tile * rows), bg)
    for i, f in enumerate(files):
        im = Image.open(f).convert('RGBA')
        im.thumbnail((tile, tile))
        sheet.paste(im, ((i % cols) * tile, (i // cols) * tile), im)
    sheet.save(outpath)


# ------------------------------------------------------------------- main
def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--src', required=True, help='folder with the owner-approved art')
    ap.add_argument('--src2', help='folder with the second batch (die 3, blue board, highlight tiles)')
    ap.add_argument('--out', default=ROOT, help='repo root (default: this repo)')
    ap.add_argument('--preview', help='folder for contact sheets and overlays (not committed)')
    ap.add_argument('--measure-only', action='store_true', help='skip processing, measure the shipped boards')
    args = ap.parse_args()
    out_root = os.path.abspath(args.out)
    report = {'pieces': {}, 'pawns': {}, 'dice': {}}

    if not args.measure_only:
        for n in ('chess_board_black_cream.png', 'ludo_board_empty.png', '_sheet_final.png'):
            p = os.path.join(args.src, n)
            print('source', n, hashlib.sha256(open(p, 'rb').read()).hexdigest()[:16])
        chess_pieces(args.src, out_root, report)
        chess_boards(args.src, args.src2, out_root, report)
        ludo_pawns(args.src, out_root, report)
        ludo_dice(args.src, args.src2, out_root, report)
        ludo_board(args.src, out_root, report)

    boards = {}
    themes = [t for t in ('royal', 'green', 'blue', 'grey', 'classic')
              if os.path.exists(os.path.join(out_root, 'assets/games/chess/boards/chess_board_%s.webp' % t))]
    for theme in themes:
        p = os.path.join(out_root, 'assets/games/chess/boards/chess_board_%s.webp' % theme)
        boards['chess_' + theme] = measure_chess(p)
    lp = os.path.join(out_root, 'assets/games/ludo/board.webp')
    ludo_geo, bad = measure_ludo(lp)
    boards['ludo'] = ludo_geo
    print(json.dumps(boards, indent=1))

    man_path = os.path.join(out_root, 'assets/games/art/manifest.json')
    man = json.load(open(man_path))
    man['boards'] = boards
    with open(man_path, 'w') as f:
        json.dump(man, f, indent=2)
        f.write('\n')

    if args.preview:
        os.makedirs(args.preview, exist_ok=True)
        pd = os.path.join(out_root, 'assets/games/chess/pieces')
        files = [os.path.join(pd, '%s%s.webp' % (c, t)) for c in 'wb' for t in 'kqrbnp']
        contact_sheet(files, os.path.join(args.preview, 'chess_pieces_dark.png'), (30, 30, 30))
        contact_sheet(files, os.path.join(args.preview, 'chess_pieces_light.png'), (240, 240, 240))
        ld = os.path.join(out_root, 'assets/games/ludo')
        lf = [os.path.join(ld, 'pawn_%s.webp' % c) for c in ('red', 'blue', 'yellow', 'green')]
        lf += [os.path.join(ld, 'die_%s.webp' % n) for n in ('1', '2', '3', '4', '5', '6', 'rolling')]
        contact_sheet(lf, os.path.join(args.preview, 'ludo_dark.png'), (30, 30, 30))
        contact_sheet(lf, os.path.join(args.preview, 'ludo_light.png'), (240, 240, 240))
        draw_overlay(lp, ludo_geo, os.path.join(args.preview, 'ludo_overlay.png'))
        for theme in themes:
            draw_chess_overlay(os.path.join(out_root, 'assets/games/chess/boards/chess_board_%s.webp' % theme),
                               boards['chess_' + theme], os.path.join(args.preview, 'chess_%s_overlay.png' % theme))

    if bad:
        print('LUDO BOARD DOES NOT MATCH THE STANDARD 15x15 EXPECTATIONS:', file=sys.stderr)
        for b in bad:
            print('  ' + b, file=sys.stderr)
        sys.exit(1)
    print('ok: Ludo board matches the standard 15x15 layout')


if __name__ == '__main__':
    main()
