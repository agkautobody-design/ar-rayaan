#!/usr/bin/env python3
"""Qur'an reference checker for the bundled content.

Mirrors test/hadith/quran_refs_test.dart (the CI test is the gate; this script
is the same logic for running by hand: `python3 tool/quran_ref_check.py`).

1. Every explicit Qur'an reference in assets/**/*.json and lib/**/*.dart must
   resolve in the bundled text (assets/quran/quran.json): "Qur'an 2:255",
   "Quran 94:5-6", "(2:255)", and named ones such as "(Al-Baqarah 255)".
2. In the Hadi offline knowledge base (lib/features/hadi/**, assets/noor/**)
   every quotation placed next to a reference must be inside the cited ayah(s),
   word for word (case, punctuation and the translator's [brackets] ignored),
   never quoted from memory. assets/noor/noor.json entries of kind "quran"
   must match the bundled Arabic and English of their ref.

Run from the repo root. Exit 1 on failure. `--report` also lists quotations
outside the Hadi scope that are not word for word in the cited ayah (paraphrases
or wrong ayah: for human review, never a failure).
"""
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tool'))
import hadith_check as hc  # noqa: E402

STRICT_PREFIXES = ('lib/features/hadi/', 'assets/noor/')

QURAN = json.load(open(os.path.join(ROOT, 'assets', 'quran', 'quran.json'), encoding='utf8'))
COUNT = {s['n']: s['c'] for s in QURAN}
AYAH = {(s['n'], v[0]): (v[1], v[2]) for s in QURAN for v in s['v']}


def _key(name):
    return re.sub(r'[^a-z]', '', name.lower())


NAMES = {_key(s['tl']): s['n'] for s in QURAN}
for alias in ('alimran', 'aalimran', 'imran', 'aliimran'):
    NAMES[alias] = 3

# "Qur'an 2:255", "Quran 94:5-6", "Surah 2:255", or "(2:255)".
NUM_REF = re.compile(
    r"(?:(?:Qur['’]?an|Quran|Surah|Sura)\s*\(?\s*|\()"
    r"(?P<s>\d{1,3}):(?P<a>\d{1,3})(?:\s*[-–]\s*(?P<b>\d{1,3}))?(?![\d:])")
# "(Al-Baqarah 255)", "Al-Imran 35-37", "An-Nisa 11-12".
NAMED_REF = re.compile(
    r"(?<![A-Za-z'’\-])(?P<n>(?:Al|An|Ar|As|Ash|At|Az|Ad|Adh|Ath)[- ][A-Za-z'’]+|[A-Z][a-z'’]+)"
    r"\s+(?P<a>\d{1,3})(?:\s*[-–]\s*(?P<b>\d{1,3}))?(?![\d:])")
# JSON strings may quote with any mark; Dart source uses ' for the literal
# itself, so only double and curly double quotes delimit a quotation there.
QUOTE_ANY = re.compile(
    r"(?<![A-Za-z0-9])[‘'“\"]([^‘“\"”]{10,}?)['’”\"](?![A-Za-z0-9])")
QUOTE_DART = re.compile(
    r"(?<![A-Za-z0-9])[“\"]([^“\"”]{10,}?)[”\"](?![A-Za-z0-9])")
HADITH = re.compile(r"bukhari|muslim|tirmidhi|da[wu]*[ou]*d|nasa|majah|ahmad", re.I)
WORD3 = re.compile(r"[A-Za-z]{3}.*[A-Za-z]{3}")


def unescape(t):
    t = re.sub(r"\\u([0-9a-fA-F]{4})", lambda m: chr(int(m.group(1), 16)), t)
    return t.replace("\\'", "'").replace('\\"', '"').replace('\\n', '\n')


def norm_en(t, keep_brackets):
    t = t.lower().replace('’', "'")
    if keep_brackets:
        t = t.replace('[', '').replace(']', '')
    else:
        t = re.sub(r'\[[^\]]*\]', '', t)
    return re.sub(r'[^a-z0-9]+', ' ', t).strip()


def norm_ar(t):
    t = re.sub('[ؐ-ًؚ-ٰٟۖ-ۭ࣓-ࣿـ]', '', t)
    t = re.sub('[إأآٱ]', 'ا', t).replace('ى', 'ي')
    return re.sub('[^ء-ي]+', ' ', t).strip()


def units(path):
    raw = open(path, encoding='utf8').read()
    if path.endswith('.dart'):
        text, lines = hc.dart_logical(raw)
        yield unescape(text), lines
        return
    try:
        doc = json.loads(raw)
    except ValueError:
        return

    def walk(o):
        if isinstance(o, str):
            yield o
        elif isinstance(o, list):
            for x in o:
                yield from walk(x)
        elif isinstance(o, dict):
            for x in o.values():
                yield from walk(x)
    for s in walk(doc):
        yield s, None


def find_refs(text):
    """[(start, end, surah, from_ayah, to_ayah, valid, label)]"""
    out = []
    for m in NUM_REF.finditer(text):
        s, a = int(m.group('s')), int(m.group('a'))
        b = int(m.group('b')) if m.group('b') else a
        out.append((m.start(), m.end(), s, a, b, m.group(0).strip()))
    for m in NAMED_REF.finditer(text):
        n = NAMES.get(_key(m.group('n')))
        if n is None:
            continue
        a = int(m.group('a'))
        b = int(m.group('b')) if m.group('b') else a
        out.append((m.start(), m.end(), n, a, b, m.group(0).strip()))
    return out


def ref_valid(s, a, b):
    return s in COUNT and 1 <= a <= b <= COUNT[s]


def ayah_text(s, a, b):
    return [AYAH[(s, k)][1] for k in range(a, b + 1)]


def quote_ok(quote, s, a, b):
    pieces = [p for p in re.split(r"\.\.\.|…|\[\.\.\.\]", quote)
              if len(norm_en(p, False).split()) >= 2]
    if not pieces:
        return True
    ayat = ayah_text(s, a, b)
    for keep in (True, False):
        hay = ' '.join(norm_en(x, keep) for x in ayat)
        if all(norm_en(p, False) in hay or norm_en(p, True) in hay for p in pieces):
            return True
    return False


def pair_quotes(text, refs, dart):
    """Yield (quote, ref) for every quotation placed next to a valid ref."""
    for qm in (QUOTE_DART if dart else QUOTE_ANY).finditer(text):
        qt = qm.group(1)
        if not WORD3.search(qt):
            continue
        after = [r for r in refs if 0 <= r[0] - qm.end() <= 45]
        ref = None
        if after:
            ref = min(after, key=lambda r: r[0])
            if HADITH.search(text[qm.end():ref[0]]):
                continue
        else:
            before = [r for r in refs if 0 <= qm.start() - r[1] <= 8
                      and re.fullmatch(r"[\s:—–\-,]*", text[r[1]:qm.start()])]
            if not before:
                continue
            ref = max(before, key=lambda r: r[1])
        yield qt, ref, qm.start()


def check(report=False):
    errs, notes = [], []
    files = [f for f in hc.asset_files()
             if '/assets/quran/' not in f.replace(os.sep, '/')
             and not f.endswith('content_manifest.json')]
    n_refs = n_quotes = 0
    for f in files:
        rel = os.path.relpath(f, ROOT).replace(os.sep, '/')
        strict = rel.startswith(STRICT_PREFIXES)
        for text, lines in units(f):
            refs = find_refs(text)
            for r in refs:
                n_refs += 1
                if not ref_valid(r[2], r[3], r[4]):
                    errs.append('%s: reference "%s" does not exist in the bundled Qur\'an' % (rel, r[5]))
            valid = [r for r in refs if ref_valid(r[2], r[3], r[4])]
            for qt, ref, pos in pair_quotes(text, valid, f.endswith('.dart')):
                n_quotes += 1
                if not quote_ok(qt, ref[2], ref[3], ref[4]):
                    ln = (lines[pos] if lines else '?')
                    msg = '%s:%s: "%s" is not word for word in %s' % (rel, ln, qt[:90], ref[5])
                    (errs if strict else notes).append(msg)
    # noor.json and the Hadi corpus
    nj = json.load(open(os.path.join(ROOT, 'assets', 'noor', 'noor.json'), encoding='utf8'))
    for e in nj['entries']:
        if e.get('k') != 'quran':
            continue
        m = re.fullmatch(r"(\d+):(\d+)(?:-(\d+))?", e['ref'])
        s, a = int(m.group(1)), int(m.group(2))
        b = int(m.group(3)) if m.group(3) else a
        if not ref_valid(s, a, b):
            errs.append('assets/noor/noor.json: ref %s does not exist' % e['ref'])
            continue
        ar = ' '.join(norm_ar(AYAH[(s, k)][0]) for k in range(a, b + 1))
        if norm_ar(e['ar']) not in ar:
            errs.append('assets/noor/noor.json: Arabic of %s is not in the bundled ayah' % e['ref'])
        if not quote_ok(e['en'], s, a, b):
            errs.append('assets/noor/noor.json: English of %s is not in the bundled ayah' % e['ref'])
    hc_ = json.load(open(os.path.join(ROOT, 'assets', 'noor', 'hadi_corpus.json'), encoding='utf8'))
    for q in hc_['quran']:
        m = re.fullmatch(r"(\d+):(\d+)(?:-(\d+))?", q['ref'])
        s, a = int(m.group(1)), int(m.group(2))
        b = int(m.group(3)) if m.group(3) else a
        if not ref_valid(s, a, b):
            errs.append('assets/noor/hadi_corpus.json: ref %s does not exist' % q['ref'])
    print('references checked: %d; quotations next to a reference: %d; strict-scope failures: %d; review notes: %d'
          % (n_refs, n_quotes, len(errs), len(notes)))
    for e in errs:
        print('FAIL', e)
    if report:
        for n in notes:
            print('REVIEW', n)
    return 1 if errs else 0


if __name__ == '__main__':
    sys.exit(check('--report' in sys.argv))
