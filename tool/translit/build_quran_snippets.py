#!/usr/bin/env python3
"""Builds assets/quran/snippets.json: short Qur'an texts the app shows outside
the reader (the Bismillah, and the part of 39:9 on the Academy gate and home
banner), each with its transliteration and meaning.

Nothing is typed here that is shown to a person:
  * Arabic: Tanzil Uthmani text from assets/quran/quran.json (the part of an
    ayah is cut at the stop marks the text itself carries);
  * transliteration: assets/quran/translit_en.json (the romaniser splits at the
    same marks, so clauses line up one to one);
  * meaning: the Saheeh International line in quran.json for a whole ayah; for
    the part of 39:9, the app's existing short wording (Saheeh exists only for
    the whole ayah).
A part is chosen by a plain-letter search key, which is never shown.
"""
import json
import os
import re

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
OUT = os.path.join(ROOT, 'assets', 'quran', 'snippets.json')
STOP = re.compile('[ۖ-ۜ]')
MARKS = re.compile('[ً-ٰٟۖ-ۭـ]')
KNOWLEDGE_KEY = 'هل يستوي'  # search key only (letters without marks)
KNOWLEDGE_EN = 'Are those who know equal to those who do not know?'
REVIEW = 'Machine-generated transliteration (quran-json, CC BY-SA 4.0); Scholar review needed.'


def plain(s):
    return MARKS.sub('', s).replace('ٱ', 'ا')


def load():
    q = json.load(open(os.path.join(ROOT, 'assets', 'quran', 'quran.json'), encoding='utf-8'))
    tl = json.load(open(os.path.join(ROOT, 'assets', 'quran', 'translit_en.json'), encoding='utf-8'))
    return q, tl['map']


def whole(q, tl, s, a):
    v = q[s - 1]['v'][a - 1]
    return {
        'ref': '%d:%d' % (s, a),
        'ar': v[1],
        'tl': tl['%d:%d' % (s, a)],
        'en': v[2],
        'enSource': 'Saheeh International via Tanzil (as in the reader)',
    }


def part(q, tl, s, a, key, en):
    v = q[s - 1]['v'][a - 1]
    ar_parts = [p.strip() for p in STOP.split(v[1])]
    tl_parts = [p.strip() for p in tl['%d:%d' % (s, a)].split(', ')]
    assert len(ar_parts) == len(tl_parts), (len(ar_parts), len(tl_parts))
    idx = [i for i, p in enumerate(ar_parts) if key in plain(p)]
    assert len(idx) == 1, idx
    return {
        'ref': '%d:%d' % (s, a),
        'ar': ar_parts[idx[0]],
        'tl': tl_parts[idx[0]],
        'en': en,
        'enSource': "The app's own short wording of this part of the verse (not the Saheeh text, which exists only for the whole ayah)",
    }


def main():
    q, tl = load()
    d = {
        'schema': 1,
        'arSource': 'Tanzil Uthmani text (tanzil.net)',
        'tlSource': 'quran-json romaniser, CC BY-SA 4.0 (assets/quran/translit_en.json)',
        'review': REVIEW,
        'bismillah': whole(q, tl, 1, 1),
        'knowledge': part(q, tl, 39, 9, KNOWLEDGE_KEY, KNOWLEDGE_EN),
    }
    with open(OUT, 'w', encoding='utf-8') as f:
        json.dump(d, f, ensure_ascii=False, indent=1)
        f.write('\n')
    for k in ('bismillah', 'knowledge'):
        print(k, d[k]['ar'], '|', d[k]['tl'])


if __name__ == '__main__':
    main()
