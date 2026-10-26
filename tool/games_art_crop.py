#!/usr/bin/env python3
"""Crop one board or card from an exported design image into a game art slot.

The designs are not kept in the repo. Export the screen from the design tool
as PNG, then run, for example:

    python3 tool/games_art_crop.py design_wordsearch.png wordsearch_grid \
        --box 40 220 1040 1220

--box is left top right bottom in pixels of the exported image. The output is
assets/games/art/<slot>.webp, at most 1080 px wide, quality 80. Slot names are
the ones in kGameArtSlots (lib/features/games/ui/learning_widgets.dart). Crop
only the board or the tile art: no text, no buttons, no avatars, no faces.
The game draws the same theme in code when a slot has no file.
"""
import argparse
import os
import re
import sys

SLOTS = re.compile(r"'([a-z_]+)',")


def known_slots():
    src = open(
        os.path.join(os.path.dirname(__file__), "..", "lib", "features",
                     "games", "ui", "learning_widgets.dart"),
        encoding="utf-8").read()
    block = src.split("kGameArtSlots = <String>[", 1)[1].split("];", 1)[0]
    return SLOTS.findall(block)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawTextHelpFormatter)
    ap.add_argument("image")
    ap.add_argument("slot")
    ap.add_argument("--box", nargs=4, type=int, metavar=("L", "T", "R", "B"))
    a = ap.parse_args()
    if a.slot not in known_slots():
        sys.exit("unknown slot %r; use one of %s" % (a.slot, known_slots()))
    from PIL import Image  # Pillow

    im = Image.open(a.image).convert("RGB")
    if a.box:
        im = im.crop(tuple(a.box))
    if im.width > 1080:
        im = im.resize((1080, round(im.height * 1080 / im.width)))
    out = os.path.join(os.path.dirname(__file__), "..", "assets", "games",
                       "art", a.slot + ".webp")
    im.save(out, "WEBP", quality=80, method=6)
    print(out, os.path.getsize(out) // 1024, "KB")


if __name__ == "__main__":
    main()
