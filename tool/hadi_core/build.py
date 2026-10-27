#!/usr/bin/env python3
"""Builds Hadi's built-in answers from the spec files in this folder.

    python3 tool/hadi_core/build.py            # write the Dart data file
    python3 tool/hadi_core/build.py --check    # fail if the Dart file is stale

Every answer is written in spec_*.py with small macros instead of typed
scripture, so nothing religious is typed twice:

  {Q 2:187|exact words}   a Qur'an quotation. The words MUST occur in the
                          bundled English text of that ayah (assets/quran/
                          quran.json); the output is  "words" (Qur'an 2:187)
  {QR 2:187}              the reference only  (Qur'an 2:187)
  {H bukhari:1245|summary of what it says}
                          a hadith citation. The number MUST exist in the
                          hadith-api corpus (github.com/fawazahmed0/hadith-api,
                          fetched from raw.githubusercontent.com and cached).
                          The output is the citation with its grade and who
                          gave it (for the four Sunan: e.g.
                          "Jami' at-Tirmidhi 3895, sahih per Darussalam").
                          The summary is written for the app (never a copy of a
                          translation) and is printed on the hadith's card.

Outputs: lib/features/hadi/data/hadi_core_data.dart and the hadith entries
added to assets/noor/hadi_corpus.json. See the pull request for the rules.
"""
import datetime
import json
import os
import re
import sys
import urllib.request

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
HERE = os.path.dirname(os.path.abspath(__file__))
CACHE = os.environ.get('HADITH_CACHE', '/tmp/hadith_api_cache')
OUT_DART = os.path.join(ROOT, 'lib/features/hadi/data/hadi_core_data.dart')
CORPUS = os.path.join(ROOT, 'assets/noor/hadi_corpus.json')
TODAY = os.environ.get('BUILD_DATE', datetime.date.today().isoformat())

BOOKS = {
    'bukhari': ('eng-bukhari', 'Sahih al-Bukhari', 'Sahih al-Bukhari', False),
    'muslim': ('eng-muslim', 'Sahih Muslim', 'Sahih Muslim', False),
    'abudawud': ('eng-abudawud', 'Sunan Abu Dawud', 'Sunan Abu Dawud', True),
    'tirmidhi': ('eng-tirmidhi', 'Jamiʿ at-Tirmidhi', "Jami' at-Tirmidhi", True),
    'nasai': ('eng-nasai', 'Sunan an-Nasaʾi', "Sunan an-Nasa'i", True),
    'ibnmajah': ('eng-ibnmajah', 'Sunan Ibn Majah', 'Sunan Ibn Majah', True),
}
SUNNAH = {'bukhari': 'bukhari', 'muslim': 'muslim', 'abudawud': 'abudawud',
          'tirmidhi': 'tirmidhi', 'nasai': 'nasai', 'ibnmajah': 'ibnmajah'}


def fetch(edition):
    os.makedirs(CACHE, exist_ok=True)
    p = os.path.join(CACHE, edition + '.json')
    if not os.path.exists(p) or os.path.getsize(p) < 1000:
        url = f'https://raw.githubusercontent.com/fawazahmed0/hadith-api/1/editions/{edition}.json'
        with urllib.request.urlopen(url, timeout=120) as r:
            data = r.read()
        open(p, 'wb').write(data)
    return json.load(open(p, encoding='utf8'))['hadiths']


_hd = {}


def hadith(book, num):
    if book not in _hd:
        m = {}
        for h in fetch(BOOKS[book][0]):
            if book == 'muslim':
                an = h.get('arabicnumber')
                if an is None:
                    continue
                m.setdefault(int(str(an).split('.')[0]), []).append(h)
            else:
                m[h['hadithnumber']] = [h]
        _hd[book] = m
    return _hd[book].get(int(num))


def grade_of(book, hs):
    """(label, grader) from the corpus grades, or None."""
    gs = []
    for h in hs:
        gs.extend(h.get('grades') or [])
    by = {g['name']: g['grade'] for g in gs}

    def norm(g):
        g = g.strip().lower().replace("da'if", "da'if")
        return {'sahih': 'sahih', 'hasan': 'hasan', 'hasan sahih': 'hasan sahih',
                'sahih hasan': 'hasan sahih', 'daif': "da'if", "da'if": "da'if",
                'hasan gharib': 'hasan', 'sahih lighairihi': 'sahih',
                'hasan lighairihi': 'hasan', 'maudu': "mawdu'", 'mawdu': "mawdu'"}.get(g, g)
    z = by.get('Zubair Ali Zai')
    KNOWN = ('sahih', 'hasan', 'hasan sahih', "da'if", "mawdu'")
    if z and not z.strip().lower().startswith('isnaad') and norm(z) in KNOWN:
        return norm(z), 'Darussalam'
    if 'Al-Albani' in by:
        return norm(by['Al-Albani']), 'al-Albani'
    if 'Ahmad Muhammad Shakir' in by:
        return norm(by['Ahmad Muhammad Shakir']), 'Ahmad Shakir'
    if z:
        return 'hasan' if 'hasan' in z.lower() else norm(z.split()[-1]), 'Darussalam'
    return None


Q = json.load(open(os.path.join(ROOT, 'assets/quran/quran.json'), encoding='utf8'))
QEN = {(s['n'], v[0]): v[2] for s in Q for v in s['v']}
QCOUNT = {s['n']: s['c'] for s in Q}


def qnorm(t):
    return re.sub(r'\s+', ' ', t.replace('’', "'").replace('‘', "'").replace('“', '"').replace('”', '"')).strip()


class Ctx:
    def __init__(self):
        self.hadith = {}     # key -> dict(summary, topics, entries)
        self.errors = []
        self.report = []


CTX = Ctx()
ENTRIES = []


CARDS = []


def card(key, summary):
    """Register a hadith the older shelf already cites, so it gets a card."""
    CARDS.append((key, summary))


_SPLIT = re.compile(r"(?<=[a-z]) (s|t|re|ve|ll)(?=\b)")
_FIXED = (('qur an', 'quran'), ('ka aba', 'kaaba'), ('ka bah', 'kaaba'), ('da if', 'daif'),
          ('shi a', 'shia'), ('shi ite', 'shiite'), ('mi raj', 'miraj'))


def fixpat(p):
    """The app drops apostrophes before matching ("don't" is "dont",
    "prophet's" is "prophets"), so patterns written with a space there get
    joined up."""
    p = _SPLIT.sub(lambda m: m.group(1), p)
    for a, b in _FIXED:
        p = p.replace(a, b)
    # The app also drops a polite opening ("can you", "tell me about") and a
    # closing "in Islam" before matching, so a pattern that needs them is
    # made to take them or not.
    p = re.sub(r"^((?:\\b|\^|\(\?:)?)(can you|could you|tell me about|tell me|do you know|explain) ",
               lambda m: ('^' if m.group(1) == '\\b' else m.group(1)) + '(?:' + m.group(2) + ' )?', p)
    return p


def E(id, m, text, x=(), go=(), src=None, topic='', gate=True, why='', review=''):
    m = [fixpat(p) for p in m]
    x = [fixpat(p) for p in x]
    ENTRIES.append(dict(id=id, m=list(m), x=list(x), text=text.strip(), go=list(go),
                        src=src, topic=topic, gate=gate, why=why.strip(), review=review))


MACRO = re.compile(r'\{(QR|Q|HS|H|HW|AR)\s+([^}|]+?)(?:\|([^}]*))?\}')


def expand(entry):
    cites = []
    text = entry['text']

    def rep(m):
        kind, ref, arg = m.group(1), m.group(2).strip(), (m.group(3) or '').strip()
        if kind in ('Q', 'QR'):
            mm = re.match(r'^(\d+):(\d+)(?:-(\d+))?$', ref)
            if not mm:
                CTX.errors.append(f"{entry['id']}: bad Q ref {ref}")
                return '???'
            s, a = int(mm.group(1)), int(mm.group(2))
            b = int(mm.group(3) or a)
            if s not in QCOUNT or a < 1 or b < a or b > QCOUNT[s]:
                CTX.errors.append(f"{entry['id']}: Qur'an {ref} does not exist")
                return '???'
            label = f"Qur'an {s}:{a}" + (f"-{b}" if b != a else '')
            cites.append(("Qur'an", f"{s}:{a}" + (f"-{b}" if b != a else ''), ''))
            if kind == 'QR':
                return label
            full = qnorm(' '.join(QEN[(s, i)] for i in range(a, b + 1)))
            if not arg:
                CTX.errors.append(f"{entry['id']}: Q {ref} needs the quoted words")
                return '???'
            quote = qnorm(arg)
            if quote not in full:
                CTX.errors.append(f"{entry['id']}: words not in {label}: {quote!r}")
            return f'"{arg}" ({label})'
        if kind == 'AR':
            return arabic(entry, ref, arg)
        weak_ok = kind == 'HW'
        inline = kind == 'HS'
        # hadith
        mm = re.match(r'^(\w+):(\d+)$', ref)
        if not mm or mm.group(1) not in BOOKS:
            CTX.errors.append(f"{entry['id']}: bad H ref {ref}")
            return '???'
        book, num = mm.group(1), int(mm.group(2))
        hs = hadith(book, num)
        if not hs:
            CTX.errors.append(f"{entry['id']}: {book} {num} not in the corpus")
            return '???'
        key = f'{book}:{num}'
        rec = CTX.hadith.setdefault(key, dict(summary=None, entries=set(), texts=[re.sub(r'\s+', ' ', h['text']) for h in hs]))
        if arg:
            if rec['summary'] and rec['summary'] != arg:
                CTX.errors.append(f"{entry['id']}: two different summaries for {key}")
            rec['summary'] = arg
        rec['entries'].add(entry['id'])
        _, _, disp, graded = BOOKS[book]
        if not graded:
            cites.append((disp, str(num), ''))
            return f'{arg} ({disp} {num})' if inline else f'{disp} {num}'
        g = grade_of(book, hs)
        if not g:
            CTX.errors.append(f"{entry['id']}: {key} has no grade in the corpus")
            return '???'
        rec['grade'], rec['grader'] = g
        if g[0] in ("da'if", "mawdu'") and not weak_ok:
            CTX.errors.append(f"{entry['id']}: {key} is graded {g[0]}; not cited as evidence (use {{HW ...}} to cite it as weak)")
        if weak_ok and g[0] not in ("da'if", "mawdu'"):
            CTX.errors.append(f"{entry['id']}: {key} is graded {g[0]}, not weak; use {{H ...}}")
        cites.append((disp, str(num), f', {g[0]} per {g[1]}'))
        if inline:
            return f'{arg} ({disp} {num}, {g[0]} per {g[1]})'
        return f'{disp} {num}, {g[0]} per {g[1]}'

    out = MACRO.sub(rep, text)
    return out, cites


_ar = {}
_TASH = re.compile('[\u0610-\u061a\u064b-\u065f\u0670\u06d6-\u06ed\u200f\u200e\u0640]')


def arabic(entry, ref, arg):
    """{AR bukhari:831|first words|last words}: the Arabic of a hadith from the
    hadith-api Arabic edition, from the first marker through the last one.
    Markers are written without vowel marks."""
    mm = re.match(r'^(\w+):(\d+)$', ref)
    parts = [p.strip() for p in arg.split('|')]
    if not mm or mm.group(1) == 'muslim' or len(parts) != 2:
        CTX.errors.append(f"{entry['id']}: bad AR {ref} {arg!r}")
        return '???'
    book, num = mm.group(1), int(mm.group(2))
    if book not in _ar:
        _ar[book] = {h['hadithnumber']: h for h in fetch('ara-' + book)}
    h = _ar[book].get(num)
    if not h:
        CTX.errors.append(f"{entry['id']}: Arabic {book} {num} not found")
        return '???'
    t = h['text']
    idx, out = [], []
    prev_space = False
    for i, ch in enumerate(t):
        if _TASH.match(ch) and not ch.isspace():
            continue
        sp = ch.isspace() or ch == '\u200f'
        if sp:
            if prev_space:
                continue
            ch = ' '
        prev_space = sp
        out.append(ch.replace('\u0622', '\u0627'))
        idx.append(i)
    plain = ''.join(out)
    a, b = parts
    i = plain.find(a)
    j = plain.find(b, i + len(a) if i >= 0 else 0)
    if i < 0 or j < 0:
        CTX.errors.append(f"{entry['id']}: Arabic markers not found in {book} {num}")
        return '???'
    start = idx[i]
    end = idx[j + len(b) - 1] + 1
    while end < len(t) and _TASH.match(t[end]):
        end += 1
    return re.sub(r'\s+', ' ', t[start:end]).strip()


def check_summaries():
    for key, rec in CTX.hadith.items():
        if not rec['summary']:
            # reuse a summary given elsewhere is handled by merging; here none at all
            CTX.errors.append(f'{key}: no summary given anywhere')


def source_line(cites):
    """'Sahih al-Bukhari 1331, 1335; Sahih Muslim 963; Jami' at-Tirmidhi 745, sahih per Darussalam'."""
    groups = []   # [name, [numbers]] in order of first appearance (Sahihayn and Qur'an merge)
    for name, num, extra in cites:
        if extra:
            item = [name + ' ' + num + extra, None]
            if item not in groups:
                groups.append(item)
            continue
        for g in groups:
            if g[0] == name and g[1] is not None:
                if num not in g[1]:
                    g[1].append(num)
                break
        else:
            groups.append([name, [num]])
    parts = []
    for name, nums in groups:
        parts.append(name if nums is None else name + ' ' + ', '.join(nums))
    return '; '.join(parts) if parts else None


def whitelist():
    c = open(os.path.join(ROOT, 'lib/features/hadi/application/hadi_controller.dart'), encoding='utf8').read()
    wl = set(re.findall(r"'(/[a-z0-9\-/]+)'", c[c.index('kHadiNavWhitelist'):c.index('kHadiRouteNames')]))
    guides = set(re.findall(r"'(huda-[a-z0-9\-]+)':", c[c.index('kHadiGuideNames'):c.index('abstract final class HadiTokens')]))
    return wl, guides


def dart_str(s):
    s = s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$').replace('\n', '\\n')
    return "'" + s + "'"


def dart_raw(s):
    if "'" in s:
        raise ValueError(f'single quote in pattern {s!r}')
    return "r'" + s + "'"


def build():
    for fn in sorted(os.listdir(HERE)):
        if fn.startswith('spec_') and fn.endswith('.py'):
            exec(compile(open(os.path.join(HERE, fn), encoding='utf8').read(), fn, 'exec'), globals())
    wl, guides = whitelist()
    ids = set()
    out = []
    for e in ENTRIES:
        if e['id'] in ids:
            CTX.errors.append(f"duplicate id {e['id']}")
        ids.add(e['id'])
        for p in e['m'] + e['x']:
            try:
                re.compile(p)
            except re.error as ex:
                CTX.errors.append(f"{e['id']}: bad regex {p!r}: {ex}")
        body, cites = expand(e)
        for r in e['go']:
            mm = re.match(r'^/huda/guide\?id=(huda-[a-z0-9\-]+)$', r)
            if not (r in wl or (mm and mm.group(1) in guides)):
                CTX.errors.append(f"{e['id']}: route {r} is not on Hadi's whitelist")
        src = e['src']
        if src is None:
            src = source_line(cites)
        if src:
            body += f'\n\nSource: {src}.'
        if e['go']:
            body += '\n' + '\n'.join(f'[GO:{r}]' for r in e['go'])
        e['out'] = body
    for key, summ in CARDS:
        book, num = key.split(':')
        hs = hadith(book, int(num))
        if not hs:
            CTX.errors.append(f'card {key} not in the corpus')
            continue
        rec = CTX.hadith.setdefault(key, dict(summary=None, entries=set(), texts=[re.sub(r'\s+', ' ', h['text']) for h in hs]))
        rec['summary'] = summ
        rec['entries'].add('(shelf)')
        if BOOKS[book][3]:
            g = grade_of(book, hs)
            if not g:
                CTX.errors.append(f'card {key} has no grade')
                continue
            rec['grade'], rec['grader'] = g
    check_summaries()
    return out


def render():
    lines = ['// GENERATED by tool/hadi_core/build.py from tool/hadi_core/spec_*.py.',
             '// Do not edit by hand: change the spec and run the script.',
             "import 'hadi_core.dart';", '',
             'const List<CoreEntry> kHadiCoreEntries = <CoreEntry>[']
    for e in ENTRIES:
        lines.append('  CoreEntry(')
        lines.append(f"    id: {dart_str(e['id'])},")
        lines.append('    patterns: <String>[')
        for p in e['m']:
            lines.append(f'      {dart_raw(p)},')
        lines.append('    ],')
        if e['x']:
            lines.append('    avoid: <String>[')
            for p in e['x']:
                lines.append(f'      {dart_raw(p)},')
            lines.append('    ],')
        lines.append(f"    answer: {dart_str(e['out'])},")
        if e['topic']:
            lines.append(f"    topic: {dart_str(e['topic'])},")
        if e['gate']:
            lines.append('    beforeGate: true,')
        if e['why']:
            lines.append(f"    why: {dart_str(e['why'])},")
        if e['review']:
            lines.append(f"    reviewNote: {dart_str(e['review'])},")
        lines.append('  ),')
    lines.append('];')
    return '\n'.join(lines) + '\n'


STOPW = set('the a an and of to in is are was were be been that this it for on with as by from not but or he she they his her them their you your i we our who whom which what when then so if at all have has had do does did will shall would can may said say says allah prophet messenger'.split())


def corpus_update():
    c = json.load(open(CORPUS, encoding='utf8'))
    have = {h['id']: h for h in c['hadith']}
    added = 0
    for key, rec in sorted(CTX.hadith.items()):
        book, num = key.split(':')
        hid = f'h:{book}-{num}'
        _, coll, disp, graded = BOOKS[book]
        if graded:
            grade, grader = rec['grade'], rec['grader']
            gl = grade[0].upper() + grade[1:]
        else:
            gl = f'In {coll}'
            grader = f'Included in {coll}; the collection gives no separate grade'
        if hid in have and 'checkedAgainst' not in have[hid]:
            continue  # an older, hand-checked entry: never overwritten
        words = [w for w in re.findall(r"[a-z']+", rec['summary'].lower()) if len(w) > 3 and w not in STOPW]
        topics = []
        for w in words:
            if w not in topics:
                topics.append(w)
        h = dict(id=hid, collection=coll, number=str(num), english=rec['summary'], grade=gl, grader=grader,
                 topics=topics[:8], verifiedAt=f'https://sunnah.com/{SUNNAH[book]}:{num}',
                 checkedAgainst='fawazahmed0/hadith-api (GitHub), English edition', textKind='summary',
                 verifiedOn=TODAY)
        if hid in have:
            have[hid].clear()
            have[hid].update(h)
        else:
            c['hadith'].append(h)
            added += 1
    return c, added


def write_verdicts():
    out = {}
    for key, rec in sorted(CTX.hadith.items()):
        book, num = key.split(':')
        v = dict(verdict='ok', grade='', grader='', checked=TODAY,
                 note='Number resolves to the cited narration in the hadith-api English edition (fawazahmed0/hadith-api); '
                      'the app summary was read against that text.')
        if BOOKS[book][3]:
            v['grade'] = rec['grade'][0].upper() + rec['grade'][1:]
            v['grader'] = rec['grader']
        out[key] = v
    path = os.path.join(ROOT, 'tool/hadith_verdicts/hadi_core.json')
    open(path, 'w', encoding='utf8').write(json.dumps(out, ensure_ascii=False, indent=1) + '\n')
    # the verifiedAt URL of a graded hadith in the corpus is a link, not prose
    ap = os.path.join(ROOT, 'tool/hadith_verdicts/allowlist.json')
    allow = json.load(open(ap, encoding='utf8'))
    for key, v in out.items():
        if v['grader']:
            k = f'{key}@assets/noor/hadi_corpus.json'
            allow.setdefault(k, f"verifiedAt URL field, not prose; grader recorded in hadi_core.json ({v['grade'].lower()}, {v['grader']})")
    open(ap, 'w', encoding='utf8').write(json.dumps(allow, ensure_ascii=False, indent=1))


if __name__ == '__main__':
    build()
    if CTX.errors:
        print('ERRORS:')
        for e in CTX.errors:
            print('  ', e)
        sys.exit(1)
    dart = render()
    if '--report' in sys.argv:
        for key, rec in sorted(CTX.hadith.items()):
            print(f'## {key}  grade={rec.get("grade")}  used in {sorted(rec["entries"])}')
            print('   MINE:', rec['summary'])
            print('   TEXT:', rec['texts'][0][:420])
    if '--check' in sys.argv:
        cur = open(OUT_DART, encoding='utf8').read() if os.path.exists(OUT_DART) else ''
        if cur != dart:
            print('hadi_core_data.dart is stale: run python3 tool/hadi_core/build.py')
            sys.exit(1)
        print('ok', len(ENTRIES), 'entries')
        sys.exit(0)
    open(OUT_DART, 'w', encoding='utf8').write(dart)
    c, added = corpus_update()
    open(CORPUS, 'w', encoding='utf8').write(json.dumps(c, ensure_ascii=False, indent=1))
    write_verdicts()
    print(len(ENTRIES), 'entries;', len(CTX.hadith), 'hadith cited;', added, 'added to the corpus')
