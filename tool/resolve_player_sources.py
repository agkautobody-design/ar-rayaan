#!/usr/bin/env python3
"""Propose YouTube video IDs for the Player catalogue, for a person to approve.

Nothing here edits assets/academy/player_sources.json. It writes
tool/player_source_candidates.json: for each catalogue track without an
approved source, the top embeddable search results with their channel names.
A person checks the channel is the artist's official one (or the label's) and
copies the chosen ID into player_sources.json.

Needs YOUTUBE_API_KEY (YouTube Data API v3). A search costs 100 quota units
and the default daily quota is 10,000, so each run handles --limit tracks
(default 80) and resumes where the last run stopped.
"""
import argparse
import json
import os
import sys
import urllib.parse
import urllib.request

CATALOG = "assets/academy/player_catalog.json"
SOURCES = "assets/academy/player_sources.json"
CANDIDATES = "tool/player_source_candidates.json"
API = "https://www.googleapis.com/youtube/v3"


def get(path, params, key):
    q = urllib.parse.urlencode({**params, "key": key})
    with urllib.request.urlopen(f"{API}/{path}?{q}", timeout=30) as r:
        return json.load(r)


def load(path, default):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        return default


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=80)
    args = ap.parse_args()
    key = os.environ.get("YOUTUBE_API_KEY", "")
    if not key:
        sys.exit("YOUTUBE_API_KEY is not set")

    tracks = load(CATALOG, {"tracks": []})["tracks"]
    approved = set(load(SOURCES, {"sources": {}}).get("sources", {}))
    cands = load(CANDIDATES, {"candidates": {}})
    done = cands.setdefault("candidates", {})

    todo = [t for t in tracks
            if not t.get("audioUrl") and t["id"] not in approved
            and t["id"] not in done]
    print(f"{len(todo)} tracks still need candidates; doing {min(len(todo), args.limit)}")

    for t in todo[: args.limit]:
        q = f'{t["artist"]} {t["title"]} official'
        try:
            res = get("search", {
                "part": "snippet", "q": q, "type": "video",
                "videoEmbeddable": "true", "safeSearch": "strict",
                "maxResults": 3,
            }, key)
        except Exception as e:  # quota or network: stop cleanly, keep progress
            print("stopping:", e)
            break
        ids = [i["id"]["videoId"] for i in res.get("items", [])]
        details = {}
        if ids:
            v = get("videos", {"part": "contentDetails,status,snippet",
                               "id": ",".join(ids)}, key)
            details = {i["id"]: i for i in v.get("items", [])}
        artist_words = [w.lower() for w in t["artist"].replace("-", " ").split()
                        if len(w) > 2]
        out = []
        for i in res.get("items", []):
            vid = i["id"]["videoId"]
            d = details.get(vid, {})
            ch = i["snippet"]["channelTitle"]
            out.append({
                "youtube": vid,
                "videoTitle": i["snippet"]["title"],
                "channel": ch,
                "duration": d.get("contentDetails", {}).get("duration", ""),
                "embeddable": d.get("status", {}).get("embeddable", False),
                "madeForKids": d.get("status", {}).get("madeForKids", False),
                "channelLooksOfficial": any(w in ch.lower() for w in artist_words)
                or "vevo" in ch.lower() or "official" in ch.lower(),
            })
        done[t["id"]] = {"artist": t["artist"], "title": t["title"], "options": out}

    cands["note"] = ("Proposals only. A person must check the channel is official "
                     "before an ID is copied into player_sources.json.")
    with open(CANDIDATES, "w", encoding="utf-8") as f:
        json.dump(cands, f, ensure_ascii=False, indent=1, sort_keys=True)
        f.write("\n")
    left = len([t for t in tracks if not t.get("audioUrl")
                and t["id"] not in approved and t["id"] not in done])
    print(f"done; {left} tracks still without candidates")


if __name__ == "__main__":
    main()
