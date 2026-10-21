#!/usr/bin/env python3
"""Hadith citation extractor and verdict checker (Kutub al-Sittah only).

Finds every `<book> <number>` reference in assets/**/*.json and in the string
literals of lib/**/*.dart, normalises it to "<book>:<number>" and checks it
against the verdict files in tool/hadith_verdicts/*.json.

Verdict file schema (one JSON object per file, merged across files):
  {"<book>:<number>": {"verdict": "ok|wrong|unverifiable",
                       "correct": "<book>:<n>",   # when verdict is wrong
                       "grade": "", "grader": "", "checked": "YYYY-MM-DD",
                       "note": ""}}
Verdicts are verdicts ONLY. Never paste hadith text from sunnah.com here.

books: bukhari muslim abudawud tirmidhi nasai ibnmajah (the Kutub al-Sittah)
 plus `ahmad` (Musnad Ahmad numbers: tracked only so they cannot be shipped
 unverified; there is no free numbered source to check them against)

Commands:
  list                         print every citation with file:line
  check [--all] [--no-strict]  fail if an enforced citation has no `ok` verdict
                               (or is recorded `wrong`), or if a citation from
                               Abu Dawud/Tirmidhi/Nasa'i/Ibn Majah does not name
                               who graded it, unless allowlisted in
                               tool/hadith_verdicts/allowlist.json
                               ("<book:n>@<file>": reason). Enforced paths come
                               from tool/hadith_verdicts/scope.json; --all
                               enforces every path.
  verifier-url <book:n>        the sunnah.com page to check by hand

The `Verifier` class is the seam for a future sunnah.com API-backed verifier.
Run from the repo root. Exit 1 on failure.
"""
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VERDICT_DIR = os.path.join(ROOT, 'tool', 'hadith_verdicts')
ALLOWLIST = 'allowlist.json'
SCOPE = 'scope.json'
GRADED = ('abudawud', 'tirmidhi', 'nasai', 'ibnmajah')
# A citation outside the two Sahihs must name who graded it within this many
# characters after the citation (or the line must say it is ungraded).
GRADER_RE = re.compile(r"al-?albani|darussalam|zubair|al-?tirmidhi|tirmidhi himself|ungraded|not graded", re.I)
GRADER_WINDOW = 140

BOOKS = [
    ('bukhari', r'bukhari'),
    ('muslim', r'(?<!new\s)muslim(?![a-z])'),
    ('abudawud', r'(?:abu|abi)\s+dawu?o?d'),
    ('tirmidhi', r'tirmidhi'),
    ('nasai', r"nasa['’ʿʼ]?i"),
    ('ibnmajah', r'ibn\s+maja?h?'),
    ('ahmad', r'(?:musnad\s+)?ahmad'),
]
BOOK_RE = '|'.join('(?P<%s>%s)' % (k, v) for k, v in BOOKS)
# optional "Sahih"/"Sunan"/"al-"/"an-"/"Jami'" prefixes are not needed in the
# pattern: the book token itself is what we anchor on.
CITE = re.compile(
    r'(?:' + BOOK_RE + r')(?:\s*\)?\s*[:#]?\s*(?:no\.?\s*|hadith\s+)?)(?P<nums>\d{1,5}(?:\s*(?:,|&|/|and|;)\s*\d{1,5}(?![\d:]))*)(?![\d:]|\s*(?:days?|times|years|minutes|rak))',
    re.I)
NUM = re.compile(r'\d+')
# Strings that look like ids (muslim-12) are not citations: handled by the
# regex because '-' is not allowed between the book and the number.


def asset_files():
    out = sorted(glob.glob(os.path.join(ROOT, 'assets', '**', '*.json'), recursive=True))
    out = [f for f in out if os.path.basename(f) not in ('content_manifest.json',)]
    out += sorted(glob.glob(os.path.join(ROOT, 'lib', '**', '*.dart'), recursive=True))
    return out


def extract(files=None):
    """Return list of (key, relpath, line_no, snippet, tail)."""
    res = []
    for f in files or asset_files():
        rel = os.path.relpath(f, ROOT).replace(os.sep, '/')
        dart = f.endswith('.dart')
        with open(f, encoding='utf8') as fh:
            for i, line in enumerate(fh, 1):
                if dart and line.lstrip().startswith('//'):
                    continue
                for m in CITE.finditer(line):
                    book = next(k for k, _ in BOOKS if m.group(k))
                    for n in NUM.findall(m.group('nums')):
                        s = max(0, m.start() - 30)
                        res.append(('%s:%d' % (book, int(n)), rel, i,
                                    line[s:m.end() + 10].strip(),
                                    line[m.end():m.end() + GRADER_WINDOW]))
    return res


RANK = {'ok': 3, 'wrong': 2, 'unverifiable': 1}


def load_verdicts():
    v = {}
    for p in sorted(glob.glob(os.path.join(VERDICT_DIR, '*.json'))):
        if os.path.basename(p) in (ALLOWLIST, SCOPE):
            continue
        d = json.load(open(p, encoding='utf8'))
        for k, val in d.items():
            if k in v and v[k]['verdict'] != val['verdict']:
                # A verdict describes the NUMBER (what hadith it resolves to) or
                # records that an OLD claim did not match it. Different files
                # check different claims, so merge by rank: ok > wrong >
                # unverifiable. An `ok` therefore never hides a surviving wrong
                # claim without a note: conflicts are printed for human review.
                print('conflicting verdicts for %s (%s)' % (k, p), file=sys.stderr)
                if RANK[val['verdict']] > RANK[v[k]['verdict']]:
                    v[k] = val
            else:
                v[k] = val
    return v


def load_scope():
    """Path prefixes (relative to the repo root) whose citations are enforced.

    Everything else is counted and reported but does not fail the check until
    its owner adds the prefix to tool/hadith_verdicts/scope.json. `--all`
    enforces every path."""
    p = os.path.join(VERDICT_DIR, SCOPE)
    if not os.path.exists(p):
        return None
    return json.load(open(p, encoding='utf8')).get('enforced')


def in_scope(rel, scope):
    return scope is None or any(rel.startswith(x) for x in scope)


def load_allowlist():
    p = os.path.join(VERDICT_DIR, ALLOWLIST)
    if not os.path.exists(p):
        return {}
    return json.load(open(p, encoding='utf8'))


def schema_errors(v):
    errs = []
    names = {k for k, _ in BOOKS}
    for k, val in v.items():
        if not re.fullmatch(r'(%s):\d+' % '|'.join(names), k):
            errs.append('%s: bad key' % k)
            continue
        if val.get('verdict') not in ('ok', 'wrong', 'unverifiable'):
            errs.append('%s: bad verdict' % k)
        if not re.fullmatch(r'\d{4}-\d{2}-\d{2}', val.get('checked', '')):
            errs.append('%s: missing checked date' % k)
        if val.get('verdict') == 'wrong' and not re.fullmatch(
                r'(%s):\d+|none' % '|'.join(names), val.get('correct', '')):
            errs.append('%s: wrong verdict needs correct (book:n or none)' % k)
        if val.get('verdict') == 'ok' and not val.get('note'):
            errs.append('%s: ok verdict needs a note (what it was checked as)' % k)
        if k.split(':')[0] in ('abudawud', 'tirmidhi', 'nasai', 'ibnmajah') \
                and val.get('verdict') == 'ok' and not (val.get('grade') and val.get('grader')):
            errs.append('%s: non-Bukhari/Muslim ok verdict needs grade and grader' % k)
    return errs


class Verifier:
    """Seam for an API-backed verifier (sunnah.com API needs a key)."""

    def url(self, key):
        book, n = key.split(':')
        return 'https://sunnah.com/%s:%s' % (
            {'abudawud': 'abudawud', 'nasai': 'nasai', 'ibnmajah': 'ibnmajah'}.get(book, book), n)

    def verify(self, key):  # pragma: no cover - needs network + API key
        raise NotImplementedError('manual verdicts only until an API key exists')


def check(strict=True, everything=False):
    v = load_verdicts()
    allow = load_allowlist()
    scope = None if everything else load_scope()
    cites = extract()
    errs = schema_errors(v)
    seen = {}
    outside = 0
    for key, f, ln, snip, tail in cites:
        if not in_scope(f, scope):
            outside += 1
            continue
        seen.setdefault(key, []).append((f, ln, tail))
    for key, locs in sorted(seen.items()):
        val = v.get(key)
        for f, ln, tail in locs:
            where = '%s:%d' % (f, ln)
            allowed = '%s@%s' % (key, f) in allow
            if val and val['verdict'] == 'ok':
                if key.split(':')[0] in GRADED and not GRADER_RE.search(tail) \
                        and not allowed:
                    errs.append('%s at %s: names no grader (al-Albani/Darussalam) after the citation' % (key, where))
                continue
            if allowed:
                continue
            if val and val['verdict'] == 'wrong':
                errs.append('%s is WRONG (correct: %s) at %s' % (key, val.get('correct'), where))
            else:
                errs.append('%s has no ok verdict (%s) at %s' % (
                    key, val['verdict'] if val else 'missing', where))
    n = sum(len(x) for x in seen.values())
    print('citations enforced: %d occurrences, %d distinct; not yet enforced (other owners): %d; verdicts on file: %d'
          % (n, len(seen), outside, len(v)))
    for e in errs:
        print('FAIL', e)
    return 0 if not errs or not strict else 1


def main(argv):
    cmd = argv[1] if len(argv) > 1 else 'check'
    if cmd == 'list':
        for key, f, ln, snip, tail in extract():
            print('%s\t%s:%d\t%s' % (key, f, ln, snip))
        return 0
    if cmd == 'check':
        return check('--no-strict' not in argv, '--all' in argv)
    if cmd == 'verifier-url':
        print(Verifier().url(argv[2]))
        return 0
    print(__doc__)
    return 2


if __name__ == '__main__':
    sys.exit(main(sys.argv))
