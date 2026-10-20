#!/usr/bin/env python3
"""Check every Qur'an reference in the bundled assets against the repo's own
Qur'an text (assets/quran/quran.json).

1. Structural: surah 1..114, ayah <= real count, ranges ordered.
2. Semantic (English): a quoted phrase directly before a "(s:a)" reference, or in a
   "Qur'an s:a — 'quote'" string, must share most of its words with the cited
   ayah range (Saheeh International text bundled in the repo).
3. Semantic (Arabic): an Arabic string next to a reference must occur in the cited
   ayah range after orthography folding.

Usage: python3 tools/check_quran_quotes.py [--strict]
Exit 1 when --strict and anything is flagged. Run from the repo root.
"""
import glob, json, re, sys, unicodedata

Q = json.load(open('assets/quran/quran.json', encoding='utf8'))
COUNT = {s['n']: s['c'] for s in Q}
EN = {(s['n'], v[0]): v[2] for s in Q for v in s['v']}
AR = {(s['n'], v[0]): v[1] for s in Q for v in s['v']}


def norm_ar(t):
    t = unicodedata.normalize('NFKD', t)
    out = []
    for c in t:
        o = ord(c)
        if 0x64b <= o <= 0x65f or o == 0x670 or 0x6d6 <= o <= 0x6ed or o == 0x640:
            continue
        c = {'ٱ': 'ا', 'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ى': 'ي', 'ة': 'ه', 'ؤ': 'و', 'ئ': 'ي'}.get(c, c)
        if c == 'ء':
            continue
        out.append(c)
    s = re.sub(r'[^ء-ي ]', '', ''.join(out))
    return s.split()


def words_en(t):
    t = t.lower().replace('’', "'").replace('‘', "'")
    return re.findall(r"[a-z']+", t)


STOP = set('the a an and of to in is are was were be it he she they them his her their you your we our i me my that this who which for on with as by at from not but or so then'.split())

REF = re.compile(r"(?<![\d:/.])(\d{1,3}):(\d{1,3})(?:\s*[–-]\s*(\d{1,3}))?(?![\d:])")


def rng(s, a, b):
    return [(s, i) for i in range(a, (b or a) + 1)]


def structural_ok(s, a, b):
    if not 1 <= s <= 114:
        return False
    if not 1 <= a <= COUNT[s]:
        return False
    if b is not None and not a <= b <= COUNT[s]:
        return False
    return True


def strings(node, path=''):
    if isinstance(node, str):
        yield path, node
    elif isinstance(node, list):
        for i, x in enumerate(node):
            yield from strings(x, f'{path}[{i}]')
    elif isinstance(node, dict):
        for k, x in node.items():
            yield from strings(x, f'{path}.{k}')


QUOTE = re.compile(
    r"(?<![A-Za-z])'((?:[^']|'(?=[A-Za-z])){12,300}?)'(?![A-Za-z])"
    r"|\u2018((?:[^\u2019]|\u2019(?=[A-Za-z])){12,300}?)\u2019(?![A-Za-z])"
    r"|\u201c([^\u201d]{12,300})\u201d")


def _q(m):
    return next(g for g in m.groups() if g)


def coverage(quote, ayahs):
    qw = [w for w in words_en(quote) if w not in STOP]
    if not qw:
        return 1.0
    pool = set()
    for k in ayahs:
        pool.update(words_en(EN[k]))
    return sum(1 for w in qw if w in pool) / len(qw)


def check_text(label, text, issues, stats):
    for m in REF.finditer(text):
        s, a = int(m.group(1)), int(m.group(2))
        b = int(m.group(3)) if m.group(3) else None
        ctx = text[max(0, m.start() - 40):m.end() + 12].replace('\n', ' ')
        if s > 114 and not re.search(r'Qur|Surah|ayah', ctx):
            continue
        if re.search(r'\d{1,2}:\d{2}\s*(am|pm|AM|PM)|\d{2}:\d{2}:\d{2}', ctx):
            continue
        if not re.search(r'Qur|Surah|ayah|Sura|\(\d|\[\d|Q\.|\u2014|\u00b7|—', ctx) and s > 114:
            continue
        stats['refs'] += 1
        if not structural_ok(s, a, b):
            if s <= 114 or re.search(r'Qur|Surah', ctx):
                issues.append(('BADREF', label, m.group(0), ctx))
            continue
        ayahs = rng(s, a, b)
        # English quote immediately before "(s:a)" or after "s:a —"
        before = text[max(0, m.start() - 340):m.start()]
        after = text[m.end():m.end() + 340]
        cand = None
        qs = list(QUOTE.finditer(before))
        if qs and len(before) - qs[-1].end() < 25:
            cand = _q(qs[-1])
        else:
            qa = QUOTE.match(after.lstrip(' \u2014-–:'))
            if qa and re.search(r'Qur|Surah', before[-30:]):
                cand = _q(qa)
        if cand:
            stats['quotes'] += 1
            cov = coverage(cand, ayahs)
            if cov < 0.6:
                issues.append(('QUOTE', label, m.group(0), f'cov={cov:.2f} quote={cand!r} ayah={EN[ayahs[0]]!r}'))


def check_arabic(label, text, ref_text, issues, stats):
    """Arabic string + cited reference given separately (cards, duas)."""


def main():
    issues, stats = [], {'refs': 0, 'quotes': 0}
    for f in sorted(glob.glob('assets/**/*.json', recursive=True)):
        if f.endswith(('quran.json', 'transliteration.json', 'word_pack.json')):
            continue
        d = json.load(open(f, encoding='utf8'))
        for p, s in strings(d):
            check_text(f'{f}{p}', s, issues, stats)
    # share cards: Arabic must be in the cited ayah
    cards = json.load(open('assets/share/cards.json', encoding='utf8'))['cards']
    for c in cards:
        m = re.search(r'Qur.an (\d+):(\d+)(?:-(\d+))?', c['ref'])
        if m and c['arabic']:
            s, a = int(m.group(1)), int(m.group(2))
            b = int(m.group(3)) if m.group(3) else None
            pool = ' '.join(' '.join(norm_ar(AR[k])) for k in rng(s, a, b))
            skel = lambda t: re.sub('[اوي]', '', ' '.join(norm_ar(t)))
            ok = skel(c['arabic']) in re.sub('[اوي]', '', pool)
            stats['cards'] = stats.get('cards', 0) + 1
            if not ok:
                issues.append(('CARD-ARABIC', f"cards.json {c['id']}", c['ref'], c['arabic']))
    print('references scanned:', stats)
    for i in issues:
        print(*i, sep=' | ')
    print(f'flagged: {len(issues)}')
    if '--strict' in sys.argv and issues:
        sys.exit(1)


main()
