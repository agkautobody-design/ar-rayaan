#!/usr/bin/env python3
"""Reads the fawazahmed0/hadith-api corpus (cached under $HADITH_CACHE) and
answers: what does <book>:<n> say, and how do the graders grade it.

Used by make_verdicts.py to record `ok` verdicts for the hadith the support
packs cite. Muslim numbers are the Abd al-Baqi numbers, mapped through the
Arabic edition's `arabicnumber` field (sub-narrations 2758.01 -> 2758)."""
import json
import os
import re
import urllib.request

CACHE = os.environ.get('HADITH_CACHE', '/tmp/hadith_api_cache')
BASE = 'https://raw.githubusercontent.com/fawazahmed0/hadith-api/1/editions/'
ED = {'bukhari': 'eng-bukhari', 'muslim': 'eng-muslim', 'abudawud': 'eng-abudawud',
      'tirmidhi': 'eng-tirmidhi', 'nasai': 'eng-nasai', 'ibnmajah': 'eng-ibnmajah'}
_cache = {}


def fetch(edition):
    os.makedirs(CACHE, exist_ok=True)
    p = os.path.join(CACHE, edition + '.json')
    if not os.path.exists(p) or os.path.getsize(p) < 1000:
        with urllib.request.urlopen(BASE + edition + '.json', timeout=180) as r:
            open(p, 'wb').write(r.read())
    return json.load(open(p, encoding='utf8'))['hadiths']


def table(book):
    if book in _cache:
        return _cache[book]
    eng = fetch(ED[book])
    m = {}
    if book == 'muslim':
        ara = fetch('ara-muslim')
        amap = {}
        for h in ara:
            an = h.get('arabicnumber')
            if an is not None and an != '':
                amap[h['hadithnumber']] = int(str(an).split('.')[0])
        for h in eng:
            n = amap.get(h['hadithnumber'])
            if n is not None:
                m.setdefault(n, []).append(h)
    else:
        for h in eng:
            m[h['hadithnumber']] = [h]
    _cache[book] = m
    return m


def get(ref):
    book, n = ref.split(':')
    return table(book).get(int(n))


def text(ref):
    hs = get(ref)
    return ' '.join(h['text'] for h in hs) if hs else None


def grades(ref):
    hs = get(ref) or []
    out = {}
    for h in hs:
        for g in h.get('grades') or []:
            out.setdefault(g['name'], g['grade'])
    return out


if __name__ == '__main__':
    import sys
    for ref in sys.argv[1:]:
        t = text(ref)
        print('==', ref, grades(ref))
        print((t or 'NOT FOUND')[:900])
