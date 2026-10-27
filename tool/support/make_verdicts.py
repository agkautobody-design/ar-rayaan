#!/usr/bin/env python3
"""Writes tool/hadith_verdicts/support.json: an `ok` verdict for every hadith in
src/hadith_registry.py that is not already ok in another verdict file, after
checking against the hadith-api corpus that the number resolves to a narration
whose English text matches the registry's pattern, and that the recorded grade
is not weak. Needs network once (HADITH_CACHE keeps the files).

    python3 tool/support/make_verdicts.py            # write
    python3 tool/support/make_verdicts.py --check    # exit 1 if the file is stale or a ref fails
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(ROOT, 'tool'))
import hadith_corpus as hcorp  # noqa: E402
from src.hadith_registry import REGISTRY  # noqa: E402

OUT = os.path.join(ROOT, 'tool', 'hadith_verdicts', 'support.json')
CHECKED = '2026-10-27'
WEAK = re.compile(r"da.?[iy]f|weak|mawd|munkar|fabricat", re.I)
GRADED = ('abudawud', 'tirmidhi', 'nasai', 'ibnmajah')


def norm(g):
    g = g.strip()
    low = g.lower().replace('isnaad', '').strip()
    if 'daif' in low or "da'if" in low or 'weak' in low:
        return "Da'if"
    if 'hasan' in low and 'sahih' in low:
        return 'Hasan Sahih'
    if 'hasan' in low:
        return 'Hasan'
    if 'sahih' in low:
        return 'Sahih'
    return g


def verdict_for(ref):
    book = ref.split(':')[0]
    t = hcorp.text(ref)
    if not t:
        raise SystemExit('%s: not found in the corpus' % ref)
    if not re.search(REGISTRY[ref], t, re.I):
        raise SystemExit('%s: corpus text does not match %r: %s' % (ref, REGISTRY[ref], t[:200]))
    note = ('Number resolves to the cited narration in the hadith-api English edition (fawazahmed0/hadith-api); '
            'text matched against /%s/ on %s.' % (REGISTRY[ref], CHECKED))
    if book in GRADED:
        gs = hcorp.grades(ref)
        alb = gs.get('Al-Albani')
        if not alb:
            raise SystemExit('%s: no al-Albani grade in the corpus (%s)' % (ref, gs))
        if WEAK.search(alb):
            raise SystemExit('%s: al-Albani grade is weak (%s); do not cite' % (ref, alb))
        others = '; '.join('%s: %s' % (k, v) for k, v in gs.items() if k != 'Al-Albani')
        return {'verdict': 'ok', 'grade': norm(alb), 'grader': 'al-Albani', 'checked': CHECKED,
                'note': note + (' Other graders in the corpus: %s.' % others if others else '')}
    return {'verdict': 'ok', 'grade': 'Sahih', 'grader': 'two Sahihs' if book in ('bukhari', 'muslim') else '', 'checked': CHECKED,
            'note': note + ' Sahih Bukhari / Sahih Muslim: the corpus carries no per-hadith grade; sahih by the consensus on the two books.'}


def main(argv):
    import hadith_check as hc
    existing = {}
    for p in sorted(os.listdir(os.path.join(ROOT, 'tool', 'hadith_verdicts'))):
        if p in ('allowlist.json', 'scope.json', 'support.json'):
            continue
        d = json.load(open(os.path.join(ROOT, 'tool', 'hadith_verdicts', p), encoding='utf8'))
        for k, v in d.items():
            if v.get('verdict') == 'ok':
                existing.setdefault(k, v)
    out = {}
    bad = []
    for ref in sorted(REGISTRY):
        # Even when another file has an ok verdict we check the text match, but do not duplicate it.
        try:
            v = verdict_for(ref)
        except SystemExit as e:
            bad.append(str(e))
            continue
        if ref in existing:
            continue
        out[ref] = v
    if bad:
        print('\n'.join(bad))
        return 1
    text = json.dumps(out, indent=1, ensure_ascii=False, sort_keys=True) + '\n'
    if '--check' in argv:
        cur = open(OUT, encoding='utf8').read() if os.path.exists(OUT) else ''
        if cur != text:
            print('support.json is stale; run tool/support/make_verdicts.py')
            return 1
        print('support.json up to date (%d verdicts)' % len(out))
        return 0
    open(OUT, 'w', encoding='utf8').write(text)
    print('%d registry refs checked; %d new verdicts written to %s' % (len(REGISTRY), len(out), os.path.relpath(OUT, ROOT)))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
