#!/usr/bin/env python3
"""Fills transliteration gaps through a rule-based pipeline, never by hand.

Writes assets/translit/generated.json: for every fully vowelled Arabic text the
app shows that has no transliteration of its own, a transliteration made by the
quran-json romaniser (renderer en-simple, CC BY-SA 4.0 project), keyed by the
exact Arabic text. The app looks a text up here only when its own registry has
no transliteration, and always labels the result "Scholar review needed".

What it will NOT do (so it never invents):
  * a text that is not fully vowelled (a word of 3+ letters with no vowel mark,
    which includes the blessing formula after a name) is skipped;
  * a text with Allah written without its shadda (the program would misread it)
    is skipped;
  * hadith texts are skipped: the romaniser is built for Qur'anic script and
    gets hadith prose wrong (checked on Nawawi 1 to 3);
  * a text longer than 60 words is skipped.
Texts that are found inside the Qur'an text are left out: they get the Qur'an
transliteration (or none), never a rule-made line cut from its ayah.

Usage: python3 tool/translit/build_generated_translit.py PATH_TO_QURAN_JSON_CHECKOUT
       python3 tool/translit/build_generated_translit.py --check
"""
import glob
import json
import os
import re
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
OUT = os.path.join(ROOT, 'assets', 'translit', 'generated.json')

AR = re.compile(r'[؀-ۿ]')
HARAKAT = re.compile('[ً-ْٰ]')
LETTER = re.compile('[ء-يٱ]')
MARKS = re.compile('[ً-ٰٟۖ-ۭـ]')
ALLAH_NO_SHADDA = re.compile('الل[ًٌٍَُِْ]*ه')
SKIP_DIRS = ('i18n', 'l10n', 'hadi', 'search', 'sakina', 'support', 'majlis')
SKIP_FILES = ('quran_index.dart', 'hijri_date.dart', 'ui_labels.dart')
SKIP_ASSETS = ('hadith/', 'noor/', 'qa/', 'support/', 'quran/', 'academy/phrases/', 'academy/word_', 'games/names99')
WORDS_MAX = 60


def norm(s):
    return ' '.join(s.split())


def plain(s):
    return MARKS.sub('', s).replace('ٱ', 'ا')


def fully_vowelled(s):
    t = re.sub(r'[\(\)\[\]«»:،؛.,!؟"“”×٠-٩\d]', ' ', s)
    for w in t.split():
        letters = LETTER.findall(w)
        if len(letters) >= 3 and not HARAKAT.search(w):
            return False
    return True


def usable(s):
    if len(AR.findall(s)) < 6:
        return False
    if ALLAH_NO_SHADDA.search(s):
        return False
    if len(s.split()) > WORDS_MAX:
        return False
    return fully_vowelled(s)


def arabic_runs(text):
    """Arabic phrases in a string: a run of Arabic words, spaces and the usual marks."""
    for m in re.finditer(r'[؀-ۿ][؀-ۿ ‌‍ً-ْ،؛:؟.\-]*[؀-ۿ]', text):
        yield m.group(0)


def decode_dart(s):
    return re.sub(r'\\u([0-9a-fA-F]{4})', lambda m: chr(int(m.group(1), 16)), s)


def candidates():
    found = set()
    for f in glob.glob(os.path.join(ROOT, 'assets', '**', '*.json'), recursive=True):
        rel = os.path.relpath(f, os.path.join(ROOT, 'assets')).replace(os.sep, '/')
        if any(rel.startswith(x) for x in SKIP_ASSETS):
            continue
        try:
            d = json.load(open(f, encoding='utf-8'))
        except Exception:
            continue
        stack = [d]
        while stack:
            o = stack.pop()
            if isinstance(o, dict):
                for k, v in o.items():
                    if isinstance(v, str) and k in ('arabic', 'ar', 'dua') and AR.search(v):
                        found.add(norm(v))
                    else:
                        stack.append(v)
            elif isinstance(o, list):
                stack.extend(o)
    for f in glob.glob(os.path.join(ROOT, 'lib', '**', '*.dart'), recursive=True):
        rel = os.path.relpath(f, os.path.join(ROOT, 'lib')).replace(os.sep, '/')
        if any('/%s/' % d in '/' + rel for d in SKIP_DIRS) or os.path.basename(f) in SKIP_FILES:
            continue
        src = decode_dart(open(f, encoding='utf-8').read())
        for line in src.splitlines():
            if line.strip().startswith('//'):
                continue
            for run in arabic_runs(line):
                found.add(norm(run))
    return sorted(found)


def build(engine_src):
    sys.path.insert(0, os.path.join(engine_src, 'src'))
    from quranjson import romanize
    q = json.load(open(os.path.join(ROOT, 'assets', 'quran', 'quran.json'), encoding='utf-8'))
    qtext = ' '.join(plain(v[1]) for s in q for v in s['v'])
    out = {}
    for a in candidates():
        if not usable(a):
            continue
        if plain(a) in qtext:
            continue  # Qur'an text: shown with the Qur'an transliteration or none
        # Allah / Allahumma written with a plain alif: read it as the joining alif
        # (a spelling aid for the program only; the Arabic shown is not changed).
        src = re.sub('\u0627(?=\u0644\u0644)', '\u0671', a)
        tl = romanize.romanize_verse(src, 'en-simple', chapter=1, verse=1).replace('`', "'").strip()
        if not tl or re.search(r"[^A-Za-z\s',.\-]", tl):
            continue
        # Sparse vowelling means the program is guessing: need marks on half the letters.
        def _sparse(a):
            for w in a.split():
                n = len(re.findall(r'[\u0621-\u064a]', w))
                m = len(re.findall(r'[\u064b-\u0652\u0670]', w))
                if n >= 4 and m < n / 2:
                    return True
            return False
        if _sparse(a) or re.search(r'llh|lhu', tl):
            continue
        # A word with no vowel in it means the program could not read the Arabic.
        if any(len(w) >= 2 and not re.search('[aeiouAEIOU]', w) for w in re.split(r"[\s,.\-']+", tl) if w):
            continue
        out[a] = {'tl': tl}
    doc = {
        'schema': 1,
        'source': 'quran-json romaniser (https://github.com/risan/quran-json), renderer en-simple, applied to the Arabic shown; ayn written as an apostrophe',
        'license': 'CC BY-SA 4.0 project; machine-generated',
        'review': 'Machine-generated; not reviewed by a qualified reader. Scholar review needed.',
        'map': out,
    }
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, 'w', encoding='utf-8') as f:
        json.dump(doc, f, ensure_ascii=False, indent=0, sort_keys=True)
        f.write('\n')
    print('generated', len(out), 'of', len(candidates()), 'candidates')


def check():
    d = json.load(open(OUT, encoding='utf-8'))
    assert d.get('review') and d.get('source')
    for a, e in d['map'].items():
        assert a == norm(a), 'key not normalised'
        assert usable(a), 'unusable key kept: ' + a[:30]
        assert re.fullmatch(r"[A-Za-z\s',.\-]+", e['tl']), e['tl']
    print('ok', len(d['map']))


if __name__ == '__main__':
    if sys.argv[1:] == ['--check']:
        check()
    else:
        build(sys.argv[1])
        check()
