#!/usr/bin/env python3
"""Pre-commit gate for the daily content job (and anyone adding a story).

Runs the checks that broke main on 2026-10-23 without needing Flutter:
  1. every story in assets/stories/modernhadith.json has string `sources` entries,
  2. every story id has a row in docs/story_audit.md,
  3. ids are unique across packs,
  4. the Kutub al-Sittah citation gate (tool/hadith_check.py check) passes.
  5. the same checks cover khutbahs.json, ids are unique across ALL story packs,
  6. no two stories share the same source set and title-free body text
     (the bot re-published Bukhari 2072 several times),
  7. assets/share/app_toc.json is in step (tool/sync_app_toc.py --check).
  8. assets/content_manifest.json matches every versioned pack (ContentSync
     rejects a pack whose SHA-256 differs, so a stale manifest silently stops
     all remote content updates). Fix: python3 tool/gen_content_manifest.py
Exit code 1 on any problem. The daily job must run this BEFORE committing
and drop the entry (not the check) when it fails.
"""
import glob
import json
import subprocess
import sys

problems = []
audit = open('docs/story_audit.md', encoding='utf-8').read()
seen = {}
for path in sorted(glob.glob('assets/stories/*.json')):
    data = json.load(open(path, encoding='utf-8'))
    if not isinstance(data, list):
        continue
    for s in data:
        sid = s.get('id', '?')
        if sid in seen:
            problems.append(f'{sid}: duplicate id ({path}, {seen[sid]})')
        seen[sid] = path
        for src in s.get('sources', []):
            if not isinstance(src, str):
                problems.append(f'{sid}: sources must be strings, got {type(src).__name__}')
                break
        if path.endswith(('modernhadith.json', 'khutbahs.json')) and sid not in audit:
            problems.append(f'{sid}: no row in docs/story_audit.md')
# near-duplicates: same cited sources, or the same opening of the first chapter
bysrc = {}
bybody = {}
for path in sorted(glob.glob('assets/stories/modernhadith.json')) + ['assets/stories/khutbahs.json']:
    for s in json.load(open(path, encoding='utf-8')):
        sid = s.get('id', '?')
        key = tuple(sorted(x for x in s.get('sources', []) if isinstance(x, str)))
        if key and len(key) <= 2 and key in bysrc and bysrc[key] != sid:
            problems.append(f'{sid}: same sources as {bysrc[key]} (duplicate story?)')
        bysrc.setdefault(key, sid)
        chs = s.get('chapters') or []
        head = ' '.join((chs[0].get('body', '') if chs else '').lower().split()[:25])
        if head and head in bybody and bybody[head] != sid:
            problems.append(f'{sid}: opens like {bybody[head]} (duplicate story?)')
        bybody.setdefault(head, sid)
r = subprocess.run([sys.executable, 'tool/sync_app_toc.py', '--check'],
                   capture_output=True, text=True)
if r.returncode != 0:
    problems.append('app_toc.json out of step: run tool/sync_app_toc.py\n' + r.stdout[-500:])
import hashlib
_ver = json.load(open('assets/content_version.json', encoding='utf-8'))
_man = json.load(open('assets/content_manifest.json', encoding='utf-8')).get('files', {})
for _path, _v in sorted(_ver.items()):
    if not isinstance(_v, int):
        continue
    _data = open('assets/' + _path, 'rb').read()
    _m = _man.get(_path)
    if not _m or _m.get('version') != _v or _m.get('sha256') != hashlib.sha256(_data).hexdigest():
        problems.append(f'content_manifest.json stale for {_path}: run tool/gen_content_manifest.py')
r = subprocess.run([sys.executable, 'tool/hadith_check.py', 'check'],
                   capture_output=True, text=True)
if r.returncode != 0:
    problems.append('hadith_check.py failed:\n' + r.stdout[-1500:] + r.stderr[-500:])
if problems:
    print('\n'.join(problems))
    sys.exit(1)
print('daily content ok')
