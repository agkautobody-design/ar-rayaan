#!/usr/bin/env python3
"""Build assets/academy/player_catalog_verified.json from
tool/nasheed_verified/verified.tsv and print its SHA-256.

Paste the printed digest into kVerifiedCatalogSha256 in
lib/features/academy/data/player_verified_pack.dart. This is the documented
regeneration path for the verified pack; the main player_catalog.json and
kCatalogSha256 are untouched.

Every row of verified.tsv was confirmed through YouTube's public oEmbed
response (title and channel) before it was added; see
docs/content_needed/NASHEED_VERIFICATION_LOG.md.
Columns: videoId, channel, artist, title, language, theme, occasion,
familyFriendly(0/1), audioStyle(vocals|duff|music|unknown).
"""
import hashlib
import json
import re

SRC = "tool/nasheed_verified/verified.tsv"
OUT = "assets/academy/player_catalog_verified.json"
LICENSE = "Official upload; streams from the official channel; not downloadable."


def main():
    seen, tracks = set(), []
    for line in open(SRC, encoding="utf-8"):
        line = line.rstrip("\n")
        if not line.strip():
            continue
        vid, chan, artist, title, lang, theme, occ, fam, style = line.split("\t")
        assert re.fullmatch(r"[A-Za-z0-9_-]{11}", vid), vid
        if vid in seen:
            continue
        seen.add(vid)
        tracks.append({
            "id": "v-" + vid,
            "title": title,
            "artist": artist,
            "language": lang,
            "theme": theme,
            "mood": "devotion",
            "audioUrl": "",
            "officialUrl": "https://www.youtube.com/watch?v=" + vid,
            "licenseLine": LICENSE,
            "occasion": occ,
            "familyFriendly": fam == "1",
            "audioStyle": style,
            "youtube": vid,
            "channel": chan,
        })
    raw = json.dumps({"version": 1, "tracks": tracks}, ensure_ascii=False,
                     indent=1) + "\n"
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write(raw)
    print(len(tracks), "tracks")
    print(hashlib.sha256(raw.encode("utf-8")).hexdigest())


if __name__ == "__main__":
    main()
