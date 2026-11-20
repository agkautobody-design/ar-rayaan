#!/usr/bin/env python3
"""Place the owner's delivered game art (20 Nov 2026) into assets/games/art.

    python3 tool/place_games_art.py --src <folder with the delivered images>

The delivered files are named by upload id; MAP says which id is which slot.
Every output is a WebP (PNG for cornerOrnament, as the app expects) and the
manifest entry is rewritten. Re-running gives the same files.
"""
import argparse, json, os
from PIL import Image

ART = "assets/games/art"
# slot -> (uploaded file, output size or None to keep, kind, note)
MAP = {
    "bottomNavFrame": ("d53d25bf-image.png", None, "Empty gold nav frame with the raised centre tab; transparent."),
    "scrambleTile": ("a4e16fdb-image.png", None, "Rounded star-border panel for Word Scramble tiles; transparent corners."),
    "wordSearchGrid": ("01cec129-image.png", (1080, 1080), "12 x 12 grid with a star border, no letters."),
    "hajjMap": ("dd4ff163-image.png", (1080, 1399), "Schematic mountain map with ornament frame, no labels, no text."),
    "prophetsOrderBoard": ("cdcbe6f4-image.png", (1030, 1527), "Floral prayer-rug arch frame, text-free."),
    "wuduStepsBoard": ("51c62566-image.png", (1030, 1527), "Arch frame with water ripples at the foot, text-free."),
    "salahStepsBoard": ("b8faba35-image.png", (1003, 1568), "Blue and gold geometric mihrab frame, text-free."),
    "seerahTimelineBoard": ("db933de8-image.png", (1003, 1568), "Dark board with corner stars and desert dunes, text-free."),
    "historyEmpty": ("41263e4b-image.png", (600, 400), "Lantern and closed book, no text."),
    "backdropFull": ("393c5818-image.png", None, "Mosque-at-sunset arch with lanterns, dark navy below for panels."),
}


# slot, file, output size, crop (size -> box) or None, ext, note
SECOND = [
    ("hubHeader", "6a5168be-image.png", (1200, 550), None, "webp",
     "Clean arch with lanterns, flowers and skyline; empty dark sky, no text or buttons."),
    ("goldDivider", "9258bd75-image.png", None, None, "png",
     "Thin gold rule with centre diamond on transparent."),
    ("resultBanner", "da4dee82-image.png", (1080, 420), None, "webp",
     "Gold star-and-arch ornament with rays on dark navy; no text."),
    ("titlePlaque", "064478e8-image.png", (1100, 198),
     lambda sz: (30, 150, 2142, 530), "webp",
     "Gold rounded plaque with a raised centre and two corner ornaments, empty inside; the app writes the label."),
    ("settingsHeader", "adfb1ec1-image.png", (941, 222),
     lambda sz: (0, sz[1] - round(sz[0] * 222 / 941), sz[0], sz[1]), "webp",
     "Skyline strip, bottom of the delivered 2172 x 724 image; empty dark sky."),
]


def save(im, slot, size, ext="webp"):
    if size and im.size != size:
        im = im.resize(size, Image.LANCZOS)
    path = f"{ART}/{slot}.{ext}"
    if ext == "png":
        im.save(path, optimize=True)
    else:
        im.save(path, "WEBP", quality=82, method=6)
    return path, im.size


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", required=True)
    a = ap.parse_args()
    man = json.load(open(f"{ART}/manifest.json"))
    for slot, (fn, size, note) in MAP.items():
        im = Image.open(os.path.join(a.src, fn))
        im = im.convert("RGBA") if im.mode == "RGBA" else im.convert("RGB")
        path, sz = save(im, slot, size)
        man["slots"][slot] = {"file": path, "kind": "exact", "source": fn,
                              "sourceScreen": "Owner delivery 20 Nov 2026",
                              "box": [0, 0, im.size[0], im.size[1]], "size": list(sz),
                              "transparent": im.mode == "RGBA", "note": note}
    # Corner ornament: the delivered top-left corner is already transparent.
    im = Image.open(os.path.join(a.src, "7dad9f46-image.png")).convert("RGBA")
    path, sz = save(im, "cornerOrnament", (256, 256), "png")
    man["slots"]["cornerOrnament"] = {"file": path, "kind": "exact", "source": "7dad9f46-image.png",
                                      "sourceScreen": "Owner delivery 20 Nov 2026", "box": [0, 0, 1254, 1254],
                                      "size": list(sz), "transparent": True,
                                      "note": "Gold floral top-left corner on transparent; the app mirrors it."}
    # Second delivery (20 Nov 2026): clean headers and divider.
    for slot, fn, size, crop, ext, note in SECOND:
        im = Image.open(os.path.join(a.src, fn))
        im = im.convert("RGBA") if ext == "png" else im.convert("RGB")
        if crop:
            im = im.crop(crop(im.size))
        path, sz = save(im, slot, size, ext)
        man["slots"][slot] = {"file": path, "kind": "exact", "source": fn,
                              "sourceScreen": "Owner delivery 20 Nov 2026 (2)",
                              "box": [0, 0, im.size[0], im.size[1]], "size": list(sz),
                              "transparent": ext == "png", "note": note}
        man["fallback"].pop(slot, None)
    man["totalBytes"] = sum(os.path.getsize(v["file"]) for v in man["slots"].values())
    json.dump(man, open(f"{ART}/manifest.json", "w"), indent=2, ensure_ascii=False)
    open(f"{ART}/manifest.json", "a").write("\n")


if __name__ == "__main__":
    main()
