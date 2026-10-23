#!/usr/bin/env python3
"""Pre-commit gate for the daily content job (and anyone adding a story).

Runs the checks that broke main on 2026-10-23 without needing Flutter:
  1. every story in assets/stories/modernhadith.json has string `sources` entries,
  2. every story id has a row in docs/story_audit.md,
  3. ids are unique across packs,
  4. the Kutub al-Sittah citation gate (tool/hadith_check.py check) passes.
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
for path in sorted(glob.glob('assets/stories/modernhadith.json')):
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
        if sid not in audit:
            problems.append(f'{sid}: no row in docs/story_audit.md')
r = subprocess.run([sys.executable, 'tool/hadith_check.py', 'check'],
                   capture_output=True, text=True)
if r.returncode != 0:
    problems.append('hadith_check.py failed:\n' + r.stdout[-1500:] + r.stderr[-500:])
if problems:
    print('\n'.join(problems))
    sys.exit(1)
print('daily content ok')
