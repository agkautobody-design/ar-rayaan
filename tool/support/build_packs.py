#!/usr/bin/env python3
"""Builds assets/support/packs/*.json from tool/support/src/p_*.py.

    python3 tool/support/build_packs.py            # write all packs
    python3 tool/support/build_packs.py --check    # exit 1 if a file differs from the sources

The sources are the place to edit; the JSON is generated (do not hand-edit it).
Translations (ar, ur, bn) live in src/tr_*.py keyed by snippet id and are merged
here."""
import glob
import importlib
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, ROOT)
sys.dont_write_bytecode = True
from tool.support.src import lib  # noqa: E402

OUT = os.path.join(ROOT, 'assets', 'support', 'packs')


def all_packs():
    packs = []
    for f in sorted(glob.glob(os.path.join(HERE, 'src', 'p_*.py'))):
        m = importlib.import_module('tool.support.src.' + os.path.basename(f)[:-3])
        packs.extend(m.build())
    tr = {}
    for f in sorted(glob.glob(os.path.join(HERE, 'src', 'tr_*.py'))):
        m = importlib.import_module('tool.support.src.' + os.path.basename(f)[:-3])
        for k, v in m.TR.items():
            assert k not in tr, 'duplicate translation for ' + k
            tr[k] = v
    ids = {}
    for p in packs:
        for s in p.snips:
            assert s['id'] not in ids, 'duplicate id ' + s['id']
            ids[s['id']] = s
    for k, v in tr.items():
        assert k in ids, 'translation for unknown snippet ' + k
        s = ids[k]
        for lang, text in v.items():
            assert lang in ('ar', 'ur', 'bn'), lang
            s['text'][lang] = text
        s['needsNativeClinicianReview'] = True
    return packs


def main(argv):
    packs = all_packs()
    os.makedirs(OUT, exist_ok=True)
    bad = 0
    for p in packs:
        path = os.path.join(OUT, p.name + '.json')
        text = lib.dumps_pack(p.doc())
        if '--check' in argv:
            cur = open(path, encoding='utf8').read() if os.path.exists(path) else ''
            if cur != text:
                print('stale: ' + path)
                bad += 1
        else:
            open(path, 'w', encoding='utf8').write(text)
    print('%d packs, %d snippets' % (len(packs), sum(len(p.snips) for p in packs)))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
