#!/usr/bin/env python3
"""Validate and import Qur'an TranslationPack files.

Commands
  validate FILE
      Check a pack file (schema, 114 surahs, 6236 ayahs, ordering, no empty
      or padded verses, checksum, licence id). Exit 0 only if it is clean.

  import FILE --license-id ID --attribution TEXT [options]
      One step: FILE is either a finished pack (.json with "schema") or a
      plain-text file with one verse per line as   surah|ayah|text   or
      surah:ayah|text   in order 1|1 .. 114|6. The pack is built, validated
      and written to assets/quran/translations/<id>.json and the manifest is
      updated. Nothing is written if any check fails.

      Preset for the owner's default English translation:
        python3 tool/translation_pack.py import clear_quran.txt \
            --preset clear-quran --license-id "<publisher permission ref>" \
            --attribution "<credit line the publisher requires>"

The licence id and the attribution line come from the publisher's written
authorisation. A placeholder licence id ("pending", "tbd", ...) is refused:
nothing may be bundled without a licence. The text is never read from
anywhere but the file you pass in.

The checksum is SHA-256 over, for every ayah in order,
"<surah>:<ayah>\\t<text>\\n" (UTF-8); the app computes the same value.
"""
import argparse
import hashlib
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
QURAN = os.path.join(ROOT, "assets", "quran", "quran.json")
OUT_DIR = os.path.join(ROOT, "assets", "quran", "translations")
MANIFEST = os.path.join(OUT_DIR, "manifest.json")
TOTAL = 6236
PLACEHOLDERS = {"", "pending", "unknown", "none", "tbd", "todo", "n/a", "na",
                "unlicensed", "placeholder"}
PRESETS = {
    "clear-quran": {
        "id": "en.clear-quran", "language": "en", "rtl": False,
        "title": "The Clear Quran (Dr. Mustafa Khattab)",
        "translator": "Dr. Mustafa Khattab",
        "publisher": "Al-Furqaan Foundation",
        "url": "https://theclearquran.org",
    },
}


class PackError(Exception):
    pass


def ayah_counts():
    with open(QURAN, encoding="utf-8") as f:
        data = json.load(f)
    counts = [s["c"] for s in data]
    if len(counts) != 114 or sum(counts) != TOTAL:
        raise PackError("assets/quran/quran.json is not the full Qur'an")
    return counts


def texts_sha256(surahs):
    h = hashlib.sha256()
    for s, row in enumerate(surahs, 1):
        for a, t in enumerate(row, 1):
            h.update(f"{s}:{a}\t{t}\n".encode("utf-8"))
    return h.hexdigest()


def check_surahs(surahs):
    counts = ayah_counts()
    if not isinstance(surahs, list) or len(surahs) != 114:
        raise PackError('"surahs" must list 114 surahs')
    total = 0
    for s, row in enumerate(surahs):
        if not isinstance(row, list):
            raise PackError(f"surah {s + 1} must be a list")
        if len(row) != counts[s]:
            raise PackError(
                f"surah {s + 1} has {len(row)} ayahs, expected {counts[s]}")
        for a, t in enumerate(row):
            ref = f"{s + 1}:{a + 1}"
            if not isinstance(t, str) or not t.strip():
                raise PackError(f"{ref} is empty")
            if t != t.strip():
                raise PackError(f"{ref} has leading or trailing spaces")
            if any(c in t for c in "\n\r\t"):
                raise PackError(f"{ref} contains a line break or tab")
        total += len(row)
    if total != TOTAL:
        raise PackError(f"{total} ayahs, expected {TOTAL}")


def check_pack(p):
    if p.get("schema") != 1:
        raise PackError(f"unsupported schema {p.get('schema')!r}")
    for k in ("id", "language", "version", "title", "translator", "publisher",
              "licenseId", "attribution", "url", "sha256"):
        if not isinstance(p.get(k), str) or not p[k].strip():
            raise PackError(f'"{k}" must be a non-empty string')
    if not re.fullmatch(r"[a-z]{2,3}\.[a-z0-9][a-z0-9\-]*", p["id"]):
        raise PackError("id must look like <language>.<slug>")
    if not p["id"].startswith(p["language"] + "."):
        raise PackError('id must start with "<language>."')
    if not re.fullmatch(r"\d+(\.\d+)*", p["version"]):
        raise PackError("version must be 1.2.3 style")
    if not isinstance(p.get("rtl", False), bool):
        raise PackError('"rtl" must be true or false')
    if p["licenseId"].strip().lower() in PLACEHOLDERS:
        raise PackError("licenseId is a placeholder; name the permission")
    if not p["url"].startswith("https://"):
        raise PackError('"url" must start with https://')
    check_surahs(p.get("surahs"))
    if p["sha256"].lower() != texts_sha256(p["surahs"]):
        raise PackError("checksum mismatch: text does not match sha256")


def parse_lines(path):
    counts = ayah_counts()
    surahs = [[] for _ in range(114)]
    expect = [(s, a) for s in range(1, 115) for a in range(1, counts[s - 1] + 1)]
    got = []
    with open(path, encoding="utf-8") as f:
        for n, line in enumerate(f, 1):
            line = line.rstrip("\n").rstrip("\r")
            if not line.strip() or line.startswith("#"):
                continue
            m = re.match(r"^(\d+)[|:](\d+)\|(.*)$", line)
            if not m:
                raise PackError(f"line {n}: expected surah|ayah|text")
            s, a, t = int(m.group(1)), int(m.group(2)), m.group(3).strip()
            got.append((s, a))
            if len(got) > len(expect) or got[-1] != expect[len(got) - 1]:
                raise PackError(
                    f"line {n}: found {s}:{a}, expected "
                    f"{'%d:%d' % expect[len(got) - 1] if len(got) <= len(expect) else 'end'}"
                    " (verses must be complete and in order)")
            surahs[s - 1].append(t)
    if len(got) != TOTAL:
        raise PackError(f"{len(got)} verses found, expected {TOTAL}")
    return surahs


def load_manifest():
    if os.path.exists(MANIFEST):
        with open(MANIFEST, encoding="utf-8") as f:
            return json.load(f)
    return {"schema": 1, "packs": []}


def cmd_validate(args):
    with open(args.file, encoding="utf-8") as f:
        check_pack(json.load(f))
    print("OK: pack is valid")


def cmd_import(args):
    meta = dict(PRESETS.get(args.preset, {})) if args.preset else {}
    for k in ("id", "language", "title", "translator", "publisher", "url"):
        v = getattr(args, k)
        if v is not None:
            meta[k] = v
    if args.rtl is not None:
        meta["rtl"] = args.rtl
    meta.setdefault("rtl", False)
    with open(args.file, encoding="utf-8") as f:
        head = f.read(2000).lstrip()
    if head.startswith("{"):
        with open(args.file, encoding="utf-8") as f:
            pack = json.load(f)
        pack.setdefault("rtl", False)
        pack["licenseId"] = args.license_id
        pack["attribution"] = args.attribution
        pack["version"] = args.version or pack.get("version", "1.0.0")
        for k, v in meta.items():
            pack.setdefault(k, v)
        pack["sha256"] = texts_sha256(pack["surahs"])
    else:
        missing = [k for k in ("id", "language", "title", "translator",
                               "publisher", "url") if k not in meta]
        if missing:
            raise PackError("missing: " + ", ".join(
                "--" + m for m in missing) + " (or use --preset)")
        surahs = parse_lines(args.file)
        pack = {"schema": 1, **meta, "version": args.version or "1.0.0",
                "licenseId": args.license_id,
                "attribution": args.attribution,
                "sha256": texts_sha256(surahs), "surahs": surahs}
    pack["schema"] = 1
    if args.status != "granted":
        raise PackError("only a pack with granted permission may be bundled; "
                        "use --status granted once the publisher has agreed")
    check_pack(pack)
    ordered = {k: pack[k] for k in (
        "schema", "id", "language", "rtl", "version", "title", "translator",
        "publisher", "licenseId", "attribution", "url", "sha256", "surahs")}
    os.makedirs(OUT_DIR, exist_ok=True)
    fname = pack["id"] + ".json"
    with open(os.path.join(OUT_DIR, fname), "w", encoding="utf-8") as f:
        json.dump(ordered, f, ensure_ascii=False, separators=(",", ":"))
    man = load_manifest()
    man["packs"] = [e for e in man["packs"] if e["id"] != pack["id"]]
    man["packs"].append({
        "id": pack["id"], "language": pack["language"], "title": pack["title"],
        "file": fname, "version": pack["version"], "sha256": pack["sha256"],
        "licenseId": pack["licenseId"], "licenceStatus": "granted"})
    man["packs"].sort(key=lambda e: e["id"])
    with open(MANIFEST, "w", encoding="utf-8") as f:
        json.dump(man, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(f"OK: wrote assets/quran/translations/{fname} and updated manifest")
    print("Next: commit both files, open a PR, let CI pass, merge.")


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    v = sub.add_parser("validate")
    v.add_argument("file")
    v.set_defaults(fn=cmd_validate)
    i = sub.add_parser("import")
    i.add_argument("file")
    i.add_argument("--preset", choices=sorted(PRESETS))
    i.add_argument("--id")
    i.add_argument("--language")
    i.add_argument("--title")
    i.add_argument("--translator")
    i.add_argument("--publisher")
    i.add_argument("--url")
    i.add_argument("--rtl", action="store_true", default=None)
    i.add_argument("--version")
    i.add_argument("--license-id", required=True)
    i.add_argument("--attribution", required=True)
    i.add_argument("--status", default="granted")
    i.set_defaults(fn=cmd_import)
    args = ap.parse_args()
    try:
        args.fn(args)
    except (PackError, OSError, ValueError, KeyError) as e:
        print("REFUSED: %s" % e, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
