#!/usr/bin/env python3
"""Builds assets/quran/translit_en.json, the app's Qur'an transliteration for
all 6,236 ayahs, from the output of the quran-json romaniser.

Nothing in the output is typed by hand. The text is produced by the rule-based
romaniser in https://github.com/risan/quran-json (src/quranjson/romanize.py,
renderer "en-simple"), which reads the Arabic and applies Hafs connected-reading
rules. That dataset is CC BY-SA 4.0 and says itself that it is machine-generated
and not yet reviewed by a qualified reader. Every line is therefore shown in the
app as "Scholar review needed".

One deterministic change is made so the whole app uses one scheme: the ayn,
which the source writes with a backtick, is written with an apostrophe, the way
the rest of the app already writes it (hamza and ayn both as '). No other change.

Usage (the engine output is a JSON file {renderer: [{id, verses:[{id,
transliteration}]}]} made by quranjson.romanize.build_editions()):

    python3 tool/translit/build_quran_translit.py ENGINE_OUTPUT.json
    python3 tool/translit/build_quran_translit.py --check        # verify the committed file
"""
import json
import os
import re
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
OUT = os.path.join(ROOT, 'assets', 'quran', 'translit_en.json')
QURAN = os.path.join(ROOT, 'assets', 'quran', 'quran.json')

META = {
    'schema': 1,
    'scheme': 'English, plain letters: long vowels doubled (aa ee oo), apostrophe for hamza and ayn, hyphen at the article',
    'source': 'quran-json romaniser, renderer en-simple (https://github.com/risan/quran-json), generated from the Kemenag Arabic text',
    'license': 'CC BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0/)',
    'review': 'Machine-generated; not yet reviewed by a qualified reader. Scholar review needed.',
    'change': 'Only change from the source: ayn written as an apostrophe instead of a backtick.',
}


def build(engine_path):
    ed = json.load(open(engine_path, encoding='utf-8'))['en-simple']
    q = json.load(open(QURAN, encoding='utf-8'))
    m = {}
    for c, s in zip(ed, q):
        assert c['id'] == s['n'] and len(c['verses']) == len(s['v']), c['id']
        for v, sv in zip(c['verses'], s['v']):
            assert v['id'] == sv[0]
            m['%d:%d' % (c['id'], v['id'])] = v['transliteration'].replace('`', "'")
    assert len(m) == 6236
    out = dict(META)
    out['map'] = m
    with open(OUT, 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False, separators=(',', ':'))
        f.write('\n')
    print('wrote', len(m), 'ayahs')


def check():
    d = json.load(open(OUT, encoding='utf-8'))
    q = json.load(open(QURAN, encoding='utf-8'))
    keys = {'%d:%d' % (s['n'], v[0]) for s in q for v in s['v']}
    assert set(d['map']) == keys, 'translit_en.json keys differ from quran.json'
    bad = [k for k, t in d['map'].items() if not t.strip() or re.search(r'[^A-Za-z\s\',.\-]', t)]
    assert not bad, 'unexpected characters in %s' % bad[:5]
    for k in ('source', 'license', 'review'):
        assert d.get(k), 'missing ' + k
    print('ok', len(d['map']))


if __name__ == '__main__':
    if sys.argv[1:] == ['--check']:
        check()
    else:
        build(sys.argv[1])
        check()
