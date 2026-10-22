#!/usr/bin/env python3
"""Keeps assets/share/app_toc.json (Hadi's table of contents) in step with the
story and guide packs.

    python3 tool/sync_app_toc.py          # rewrite the file
    python3 tool/sync_app_toc.py --check  # exit 1 if it is out of date (CI/tests)

Existing entries and their order are kept; ids found in a pack but missing
from the matching room are appended in pack order, with the pack's title.
The `games` room is hand-written and left alone. The file is not a versioned
pack (it is not in assets/content_version.json), so no manifest change is
needed.
"""
import json, os, sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets')
TOC = os.path.join(ROOT, 'share', 'app_toc.json')
SKIP_ROOMS = {'games'}


def pack_path(room):
    if room == 'huda':
        return os.path.join(ROOT, 'guides', 'guides.json')
    return os.path.join(ROOT, 'stories', room + '.json')


def synced(toc):
    out = json.loads(json.dumps(toc))
    for room, entries in out['rooms'].items():
        if room in SKIP_ROOMS:
            continue
        path = pack_path(room)
        if not os.path.isfile(path):
            continue
        items = json.load(open(path, encoding='utf-8'))
        have = {e['id'] for e in entries}
        for it in items:
            if it['id'] not in have:
                entries.append({'id': it['id'], 'title': it['title']})
                have.add(it['id'])
    return out


def main():
    raw = open(TOC, encoding='utf-8').read()
    toc = json.loads(raw)
    new = synced(toc)
    text = json.dumps(new, ensure_ascii=False)
    if '--check' in sys.argv:
        if text != raw:
            print('app_toc.json is out of date: run python3 tool/sync_app_toc.py')
            sys.exit(1)
        print('app_toc.json is up to date')
        return
    added = sum(len(new['rooms'][r]) - len(toc['rooms'][r]) for r in toc['rooms'])
    with open(TOC, 'w', encoding='utf-8') as f:
        f.write(text)
    print('added', added, 'entries')


if __name__ == '__main__':
    main()
