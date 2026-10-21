#!/usr/bin/env python3
"""Qur'an reference checker for the bundled content.

Mirrors test/hadith/quran_refs_test.dart (the CI test is the gate; this script
is the same logic for running by hand: `python3 tool/quran_ref_check.py`).

1. Every explicit Qur'an reference in assets/**/*.json and lib/**/*.dart must
   resolve in the bundled text (assets/quran/quran.json): "Qur'an 2:255",
   "Quran 94:5-6", "(2:255)", and named ones such as "(Al-Baqarah 255)".
2. Everywhere in the repo (not only the Hadi knowledge base) every quotation
   placed next to a reference must be inside the cited ayah(s), word for word
   in the bundled Saheeh International text (case, punctuation and the
   translator's [brackets] ignored), never quoted from memory or paraphrased
   inside quotation marks. The only exceptions are listed, each with a reason,
   in tool/quran_quote_allowlist.json.
3. assets/noor/noor.json entries of kind "quran" must match the bundled Arabic
   and English of their ref.

Run from the repo root. Exit 1 on failure.
"""
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tool'))
import hadith_check as hc  # noqa: E402

# Justified exceptions: tool/quran_quote_allowlist.json, a list of
# {"file", "quote", "reason"} objects. A quote listed there is skipped; an entry
# that no longer matches anything, or has no reason, is itself a failure.
ALLOWLIST_PATH = os.path.join(ROOT, 'tool', 'quran_quote_allowlist.json')

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
QUOTE_DART = QUOTE_ANY  # Dart literals are decoded first (see dart_units)
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


ESCAPES = {'n': '\n', 't': '\t', 'r': '\r', 'b': '\b', 'f': '\f', 'v': '\v'}


def dart_units(raw):
    """Decoded Dart string literals as (text, line). Adjacent literals (only
    whitespace between them) are one unit, as at runtime. Comments are skipped;
    ${...} interpolations are dropped."""
    out, cur, cur_line, last_end = [], None, 0, -1
    i, n, line = 0, len(raw), 1
    while i < n:
        c = raw[i]
        if c == '\n':
            line += 1
            i += 1
        elif raw.startswith('//', i):
            while i < n and raw[i] != '\n':
                i += 1
        elif raw.startswith('/*', i):
            j = raw.find('*/', i + 2)
            j = n if j < 0 else j + 2
            line += raw.count('\n', i, j)
            i = j
        elif c in '\'"':
            is_raw = i > 0 and raw[i - 1] == 'r' and (i < 2 or not raw[i - 2].isalnum())
            triple = raw.startswith(c * 3, i)
            delim = c * 3 if triple else c
            j = i + len(delim)
            buf = []
            start_line = line
            while j < n and not raw.startswith(delim, j):
                ch = raw[j]
                if ch == '\n':
                    line += 1
                if ch == '\\' and not is_raw and j + 1 < n:
                    nx = raw[j + 1]
                    if nx == 'u':
                        m = re.match(r"u\{([0-9a-fA-F]+)\}|u([0-9a-fA-F]{4})", raw[j + 1:j + 12])
                        if m:
                            buf.append(chr(int(m.group(1) or m.group(2), 16)))
                            j += 1 + m.end()
                            continue
                    buf.append(ESCAPES.get(nx, nx))
                    if nx == '\n':
                        line += 1
                    j += 2
                    continue
                if ch == '$' and not is_raw and raw.startswith('${', j):
                    depth, j = 1, j + 2
                    while j < n and depth:
                        depth += {'{': 1, '}': -1}.get(raw[j], 0)
                        j += 1
                    continue
                buf.append(ch)
                j += 1
            j = min(n, j + len(delim))
            if cur is not None and not raw[last_end:i].strip():
                cur.append(''.join(buf))
            else:
                if cur is not None:
                    out.append((''.join(cur), cur_line))
                cur, cur_line = [''.join(buf)], start_line
            last_end = j
            i = j
        else:
            i += 1
    if cur is not None:
        out.append((''.join(cur), cur_line))
    return out


def units(path):
    raw = open(path, encoding='utf8').read()
    if path.endswith('.dart'):
        for text, line in dart_units(raw):
            yield text, line
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
    """Yield (quote, ref, position) for every quotation placed next to a valid ref."""
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


# Records that present a bundled-ayah as a card: {"arabic", "text"|"body",
# "source": "Qur'an 94:5-6"} in JSON and FeelingResponse(kind: 'Quran', text:,
# source: 'Quran 94:5–6') in Dart. The text (for "body": its first sentence)
# must be word for word in the cited ayah(s).
REC_SOURCE = re.compile(
    r"^\s*(?:Qur['’]?an|Quran)\s*(\d{1,3}):(\d{1,3})(?:\s*[-–]\s*(\d{1,3}))?(?:\s*[(—·].*)?$")
DART_REC = re.compile(
    r"kind:\s*'Quran',\s*text:\s*'((?:[^'\\]|\\.)*)',\s*source:\s*'((?:[^'\\]|\\.)*)'")
FIRST_SENTENCE = re.compile(r"^(.*?[.?!])(?:\s|$)", re.S)


def record_checks(path, doc, rel):
    """Yield (text, ref_tuple) for every Qur'an card record in a JSON doc."""
    def walk(o):
        if isinstance(o, dict):
            src = o.get('source')
            m = REC_SOURCE.match(src) if isinstance(src, str) else None
            if m and 'arabic' in o:
                s_, a_ = int(m.group(1)), int(m.group(2))
                b_ = int(m.group(3)) if m.group(3) else a_
                for key in ('text', 'body'):
                    t = o.get(key)
                    if isinstance(t, str):
                        if key == 'body':
                            fm = FIRST_SENTENCE.match(t)
                            t = fm.group(1) if fm else t
                        yield t, (s_, a_, b_, src)
            for v in o.values():
                yield from walk(v)
        elif isinstance(o, list):
            for v in o:
                yield from walk(v)
    yield from walk(doc)


def dart_record_checks(raw):
    for m in DART_REC.finditer(raw):
        sm = REC_SOURCE.match(unescape(m.group(2)))
        if sm:
            a_ = int(sm.group(2))
            yield unescape(m.group(1)), (int(sm.group(1)), a_, int(sm.group(3)) if sm.group(3) else a_, unescape(m.group(2)))


def load_allowlist(errs):
    allow = {}
    if os.path.exists(ALLOWLIST_PATH):
        for e in json.load(open(ALLOWLIST_PATH, encoding='utf8')):
            if not str(e.get('reason', '')).strip():
                errs.append('allowlist entry without a reason: %s' % e.get('quote', '')[:60])
            allow[(e['file'], norm_en(e['quote'], False))] = e
    return allow, set()


def check(report=False):
    errs = []
    files = [f for f in hc.asset_files()
             if '/assets/quran/' not in f.replace(os.sep, '/')
             and not f.endswith('content_manifest.json')]
    n_refs = n_quotes = 0
    allow, used = load_allowlist(errs)
    for f in files:
        rel = os.path.relpath(f, ROOT).replace(os.sep, '/')
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
                    key = (rel, norm_en(qt, False))
                    if key in allow:
                        used.add(key)
                        continue
                    ln = lines if lines else '?'
                    errs.append('%s:%s: "%s" is not word for word in %s' % (rel, ln, qt[:90], ref[5]))
    n_rec = 0
    for f in files:
        rel = os.path.relpath(f, ROOT).replace(os.sep, '/')
        if f.endswith('.json'):
            try:
                doc = json.load(open(f, encoding='utf8'))
            except ValueError:
                continue
            recs = list(record_checks(f, doc, rel))
        else:
            recs = list(dart_record_checks(open(f, encoding='utf8').read()))
        for text, (s_, a_, b_, label) in recs:
            if not ref_valid(s_, a_, b_):
                continue
            n_rec += 1
            if not quote_ok(text, s_, a_, b_):
                key = (rel, norm_en(text, False))
                if key in allow:
                    used.add(key)
                    continue
                errs.append('%s: card text "%s" is not word for word in %s' % (rel, text[:90], label))
    for key in sorted(set(allow) - used):
        errs.append('allowlist entry matches nothing (remove it): %s "%s"' % key)
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
    print('references checked: %d; quotations next to a reference: %d; Qur\'an cards: %d; allowlisted: %d; failures: %d'
          % (n_refs, n_quotes, n_rec, len(used), len(errs)))
    for e in errs:
        print('FAIL', e)
    return 1 if errs else 0


if __name__ == '__main__':
    sys.exit(check('--report' in sys.argv))
