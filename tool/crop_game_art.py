#!/usr/bin/env python3
"""Crops the Games art out of the owner's final-theme design screenshots.

Reproducible: run it again and the same files and the same manifest come out.

    python3 tool/crop_game_art.py --src /path/to/design/screenshots

Needs Pillow, NumPy and OpenCV (opencv-python-headless). Nothing here is part
of the app build; the app only ships the files this writes to
`assets/games/art/` and the `manifest.json` next to them.

What it does, honestly:
  * "exact" slots are a plain rectangular crop of one screenshot, resized
    down at most (never up). No text, no buttons, no faces in the box.
  * "patched" slots are a crop where baked-in text, status bar, round
    buttons or a dark background had to be removed. Text and buttons are
    painted out with OpenCV (Telea) inpainting, which smears: the result is
    fine on smooth sky, soft on busy detail. Ornaments are cut out of a dark
    background by turning brightness/colour into transparency, so they only
    look right over a dark panel.
  * "fallback" slots have no clean source. The app draws them in code, and
    docs/content_needed/GAMES_ART_NEEDED.md says what to export.

Every slot is listed in SLOTS below with its source image, crop box (pixels
of the source) and kind. `docs/content_needed/GAMES_ART_NEEDED.md` is the
owner-facing version of the same table.

Never cropped: human photos or faces (avatars are drawn as initials in the
app), anything showing a prophet. The Family tile contains dark silhouettes
seen from behind, no faces.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

OUT_DIR = Path(__file__).resolve().parent.parent / 'assets' / 'games' / 'art'

# Short ids for the screenshots used (file name prefix in the design folder).
SOURCES = {
    'hub6': ('c7b6c535-image.png', 'Games landing, six category cards'),
    'collection': ('855838e9-image.png', 'All Games Collection'),
    'islamicList': ('fac12202-image.png', 'Islamic Games list'),
    'history': ('3da17b52-image.png', 'Game History'),
    'setup': ('c86399a6-image.png', 'Game Setup, Qur’an Knowledge'),
    'details': ('8197268e-image.png', 'Qur’an Knowledge details'),
    'waiting': ('985cb0f6-image.png', 'Qur’an Knowledge waiting room'),
    'complete': ('97b0ae78-image.png', 'Game Complete (trophy)'),
    'astronomy': ('d87e652c-image.png', 'Astronomy Explorer (ornate panel)'),
}


# Inpaint operations, in source pixels.
#   ('text', (x0, y0, x1, y1), threshold)  paint out bright pixels in a box
#   ('circle', (cx, cy), r)                paint out a disc
#   ('rect', (x0, y0, x1, y1))             paint out a rectangle
HUB_HEADER_FIX = [
    ('text', (335, 140, 610, 235), 110),  # "Ar-Rayaan / your gateway"
    ('text', (240, 255, 705, 320), 110),  # "All Games Collection"
    ('text', (290, 318, 650, 350), 110),  # "Play / Learn / Grow"
    ('circle', (114, 104), 40),  # back button
    ('circle', (825, 104), 40),  # search button
    ('rect', (150, 18, 235, 52)),  # clock
    ('rect', (675, 18, 810, 52)),  # signal, wifi, battery
]

# slot -> dict(kind, src, box, [fix], [alpha], [fmt], note)
SLOTS: dict[str, dict] = {
    # ---- headers and backdrops -------------------------------------------
    'hubHeader': dict(
        kind='patched', src='collection', box=(0, 50, 941, 480),
        fix=HUB_HEADER_FIX,
        note='Arch, lanterns, skyline. Title, tagline, status bar and the two '
             'round buttons painted out; the buttons leave a soft glow.'),
    'skylineBand': dict(
        kind='exact', src='waiting', box=(0, 262, 941, 484),
        note='Text-free skyline with lanterns and flowers. Used as the '
             'backdrop strip on setup, waiting, results, history.'),
    # ---- hub category cards (icon and scene, text-free top of each card) --
    'categoryIslamic': dict(
        kind='exact', src='hub6', box=(52, 644, 290, 770),
        note='Dome icon on the arcade scene.'),
    'categoryBoard': dict(
        kind='exact', src='hub6', box=(318, 644, 549, 770),
        note='Dice icon.'),
    'categoryWords': dict(
        kind='exact', src='hub6', box=(576, 644, 815, 770),
        note='A B tiles icon.'),
    'categoryPuzzles': dict(
        kind='exact', src='hub6', box=(52, 958, 290, 1080),
        note='Puzzle piece icon.'),
    'categoryFamily': dict(
        kind='exact', src='hub6', box=(318, 958, 549, 1082),
        note='Family icon over dark silhouettes seen from behind (no faces).'),
    'categoryMore': dict(
        kind='exact', src='hub6', box=(578, 958, 815, 1082),
        note='Controller icon.'),
    # ---- one picture per game ---------------------------------------------
    'gameQuranKnowledge': dict(
        kind='exact', src='setup', box=(94, 384, 400, 556),
        note='Open Qur’an on a rehal with a lantern.'),
    'heroQuranKnowledge': dict(
        kind='exact', src='details', box=(72, 168, 870, 515),
        note='Wide hero: Qur’an, mosque at sunset, lanterns.'),
    'gameStories': dict(
        kind='exact', src='islamicList', box=(60, 838, 300, 948),
        note='Mountains and river (Prophets and Messengers tile). No figures.'),
    'gameNames99': dict(
        kind='exact', src='islamicList', box=(60, 1238, 300, 1348),
        note='Gold calligraphy medallion on teal.'),
    'gameLineage': dict(
        kind='exact', src='islamicList', box=(60, 972, 300, 1082),
        note='Old city, domes and towers at sunset.'),
    'gameHijrah': dict(
        kind='exact', src='islamicList', box=(60, 572, 300, 682),
        note='Camels and a mosque in the desert at sunset.'),
    'gameHadith': dict(
        kind='exact', src='islamicList', box=(60, 706, 300, 816),
        note='Bound books and a lantern.'),
    'gameHifz': dict(
        kind='exact', src='history', box=(36, 470, 266, 614),
        note='Open Qur’an with mosque behind.'),
    'gameChess': dict(
        kind='exact', src='history', box=(36, 818, 266, 962),
        note='Gold and black chess pieces.'),
    'gameLudo': dict(
        kind='exact', src='history', box=(36, 644, 266, 788),
        note='Ludo board with pawns and dice.'),
    'gameMemory': dict(
        kind='exact', src='history', box=(36, 1168, 266, 1312),
        note='Star-pattern memory cards and a lantern card.'),
    'gameArabicWords': dict(
        kind='exact', src='history', box=(36, 992, 266, 1136),
        note='Arabic letter tiles on a card table.'),
    'gameSeerahChallenge': dict(
        kind='exact', src='history', box=(36, 1342, 266, 1486),
        note='Mosque and market at sunset.'),
    'gamePuzzlePath': dict(
        kind='exact', src='collection', box=(250, 1286, 460, 1410),
        note='Glowing puzzle path through an arch.'),
    'gameLogicTiles': dict(
        kind='exact', src='collection', box=(640, 1290, 905, 1405),
        note='Glowing geometric tiles.'),
    # ---- results ----------------------------------------------------------
    'resultTrophy': dict(
        kind='exact', src='complete', box=(40, 300, 823, 655),
        note='Gold trophy with crescent, Ludo pawns and dice, garden arch.'),
    # ---- ornaments: cut out of a dark background ----------------------------
    'cornerOrnament': dict(
        kind='patched', src='astronomy', box=(47, 710, 140, 800),
        alpha='colour', fmt='png',
        note='Islamic pattern panel corner (top-left). Cut out of a dark '
             'panel; mirror it for the other corners. Dark panels only.'),
    'goldDivider': dict(
        kind='patched', src='waiting', box=(205, 1237, 735, 1257),
        alpha='luma', fmt='png',
        note='Thin gold rule with a diamond in the middle. Dark panels only.'),
}

# Slots with no usable source: the app draws them in code.
FALLBACK_SLOTS = {
    'bottomNavFrame': 'The gold nav pill exists only with icons and labels '
                      'baked in. The app keeps its own shared bottom nav.',
    'backdropFull': 'No design crop is a clean full-screen background: every '
                    'screen has its title, cards or buttons baked in.',
    'historyEmpty': 'No design for an empty history list.',
    'settingsHeader': 'No Games settings screen exists on main yet, and no '
                      'design crop is text-free.',
}

MAX_W = {  # never wider than this (about 2x the biggest display size)
    'hubHeader': 941, 'skylineBand': 941, 'heroQuranKnowledge': 800,
    'resultTrophy': 783,
}


def build_mask(shape, ops, img):
    h, w = shape[:2]
    mask = np.zeros((h, w), np.uint8)
    for op in ops:
        if op[0] == 'text':
            x0, y0, x1, y1 = op[1]
            g = cv2.cvtColor(img[y0:y1, x0:x1], cv2.COLOR_BGR2GRAY)
            mask[y0:y1, x0:x1] = ((g > op[2]).astype(np.uint8)) * 255
        elif op[0] == 'circle':
            cv2.circle(mask, op[1], op[2], 255, -1)
        elif op[0] == 'rect':
            x0, y0, x1, y1 = op[1]
            mask[y0:y1, x0:x1] = 255
    text_part = cv2.dilate(mask, np.ones((7, 7), np.uint8), iterations=2)
    return text_part


def inpaint(path: Path, ops) -> Image.Image:
    img = cv2.imread(str(path))
    if img is None:
        raise SystemExit(f'cannot read {path}')
    # Text first (thin strokes), then discs and rectangles (solid areas).
    text_ops = [o for o in ops if o[0] == 'text']
    solid_ops = [o for o in ops if o[0] != 'text']
    out = cv2.inpaint(img, build_mask(img.shape, text_ops, img), 6,
                      cv2.INPAINT_TELEA)
    out = cv2.inpaint(out, build_mask(out.shape, solid_ops, out), 5,
                      cv2.INPAINT_TELEA)
    return Image.fromarray(cv2.cvtColor(out, cv2.COLOR_BGR2RGB))


def to_alpha(crop: Image.Image, how: str) -> Image.Image:
    rgb = np.asarray(crop.convert('RGB')).astype(np.float32)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    if how == 'luma':
        lum = 0.3 * r + 0.59 * g + 0.11 * b
        a = np.clip((lum - 40) / 110, 0, 1)
    else:  # 'colour': warm and bright (gold lines) but not white stars
        warm = np.clip((r - b - 30) / 60, 0, 1)
        bright = np.clip((np.maximum(r, g) - 60) / 120, 0, 1)
        a = warm * bright
        # Fade out towards the open corner so stray specks disappear.
        h, w = a.shape
        yy, xx = np.mgrid[0:h, 0:w]
        d = np.sqrt((xx / w) ** 2 + (yy / h) ** 2)
        a *= np.clip((1.25 - d) / 0.35, 0, 1)
    out = np.dstack([rgb, a * 255]).astype(np.uint8)
    out[..., :3] = np.where(a[..., None] > 0.02, out[..., :3], 0)
    return Image.fromarray(out, 'RGBA')


def build(src_dir: Path) -> dict:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for old in OUT_DIR.glob('*'):
        if old.suffix in ('.webp', '.png'):
            old.unlink()
    cache: dict[str, Image.Image] = {}
    manifest: dict = {'version': 1, 'slots': {}, 'fallback': {}}
    for slot, spec in SLOTS.items():
        fname, desc = SOURCES[spec['src']]
        path = src_dir / fname
        if not path.exists():
            raise SystemExit(f'missing source {path}')
        key = spec['src'] + str(bool(spec.get('fix')))
        if spec.get('fix'):
            if key not in cache:
                cache[key] = inpaint(path, spec['fix'])
            img = cache[key]
        else:
            if key not in cache:
                cache[key] = Image.open(path).convert('RGB')
            img = cache[key]
        crop = img.crop(spec['box'])
        mw = MAX_W.get(slot)
        if mw and crop.width > mw:
            crop = crop.resize(
                (mw, round(crop.height * mw / crop.width)), Image.LANCZOS)
        fmt = spec.get('fmt', 'webp')
        if spec.get('alpha'):
            crop = to_alpha(crop, spec['alpha'])
        out = OUT_DIR / f'{slot}.{fmt}'
        if fmt == 'webp':
            crop.convert('RGB').save(out, 'WEBP', quality=84, method=6)
        else:
            crop.save(out, 'PNG', optimize=True)
        manifest['slots'][slot] = {
            'file': f'assets/games/art/{out.name}',
            'kind': spec['kind'],
            'source': fname,
            'sourceScreen': desc,
            'box': list(spec['box']),
            'size': [crop.width, crop.height],
            'transparent': bool(spec.get('alpha')),
            'note': spec['note'],
        }
    for slot, note in FALLBACK_SLOTS.items():
        manifest['fallback'][slot] = {'kind': 'fallback', 'note': note}
    total = sum(p.stat().st_size for p in OUT_DIR.iterdir()
                if p.suffix in ('.webp', '.png'))
    manifest['totalBytes'] = total
    (OUT_DIR / 'manifest.json').write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + '\n',
        encoding='utf-8')
    return manifest


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--src', default=os.environ.get('GAMES_ART_SRC', ''),
                    help='folder with the design screenshots')
    args = ap.parse_args()
    if not args.src:
        ap.error('pass --src or set GAMES_ART_SRC')
    m = build(Path(args.src))
    kinds = [v['kind'] for v in m['slots'].values()]
    print(f"{kinds.count('exact')} exact, {kinds.count('patched')} patched, "
          f"{len(m['fallback'])} fallback; {m['totalBytes'] / 1024:.0f} KB")
    return 0


if __name__ == '__main__':
    sys.exit(main())
