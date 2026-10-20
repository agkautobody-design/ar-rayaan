#!/usr/bin/env python3
"""Regenerates assets/content_manifest.json from assets/content_version.json.

ContentSync only accepts a remotely served content pack when its SHA-256
matches this manifest, so run this after any change to a versioned pack and
commit both files together:

    python3 tool/gen_content_manifest.py
"""
import hashlib, json, os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets')
versions = json.load(open(os.path.join(ROOT, 'content_version.json'), encoding='utf-8'))
files = {}
for path, ver in sorted(versions.items()):
    if not isinstance(ver, int):
        continue
    p = os.path.join(ROOT, path)
    if not os.path.isfile(p):
        continue
    data = open(p, 'rb').read()
    files[path] = {'version': ver, 'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data)}
out = {'schema': 1, 'files': files}
with open(os.path.join(ROOT, 'content_manifest.json'), 'w', encoding='utf-8') as f:
    json.dump(out, f, indent=1, sort_keys=True)
    f.write('\n')
print(len(files), 'files in manifest')
