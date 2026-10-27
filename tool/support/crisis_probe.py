#!/usr/bin/env python3
"""Pre-flight for test/crisis_robustness_test.dart ("on the app's own text the
later passes add no new detections"): that Dart test fails when an asset string
is caught by CrisisDetector only after folding or a typo allowance. Flutter is
not available everywhere, so this is a conservative Python approximation of the
plain and typo passes (guards such as notAfter/notFollowedBy are ignored, which
can only make this probe flag MORE than the real detector, never less).

    python3 tool/support/crisis_probe.py [FILE...]     # default: assets/support/**/*.json
    python3 tool/support/crisis_probe.py --baseline    # run over every assets/**/*.json (should be clean)

Exit 1 when a string would be flagged. `exact` hits are fine (the real test only
rejects strings that fire in the later passes but not the first)."""
import glob
import json
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
DART = os.path.join(ROOT, 'lib', 'features', 'sakina', 'domain', 'crisis_detector.dart')
NEAR = os.path.join(ROOT, 'lib', 'features', 'sakina', 'domain', 'crisis_near_words.dart')


def norm(s):
    out = []
    last_space = True
    for ch in s.lower():
        if ch in "'‘’`´­":
            continue
        if ch.isalnum():
            out.append(ch)
            last_space = False
        else:
            if not last_space:
                out.append(' ')
                last_space = True
    t = ''.join(out).strip()
    return re.sub(r'(.)\1{2,}', r'\1', t)


def one_slip(a, b):
    la, lb = len(a), len(b)
    if a == b or abs(la - lb) > 1:
        return False
    if la == lb:
        d = [i for i in range(la) if a[i] != b[i]]
        if len(d) == 1:
            return True
        return len(d) == 2 and d[1] == d[0] + 1 and a[d[0]] == b[d[1]] and a[d[1]] == b[d[0]]
    s, l = (a, b) if la < lb else (b, a)
    i = 0
    while i < len(s) and s[i] == l[i]:
        i += 1
    return s[i:] == l[i + 1:]


def load():
    src = open(DART, encoding='utf8').read()
    phrases = {norm(m.group(1)) for m in re.finditer(r"_Pat\(\s*'((?:[^'\\]|\\.)*)'", src)}
    phrases.discard('')
    near_src = open(NEAR, encoding='utf8').read()
    near = set(re.findall(r"'([a-z]+)'", near_src))
    words = {w for p in phrases for w in p.split()}
    by_first = {}
    for w in words:
        by_first.setdefault(w[0], []).append(w)
    return phrases, near, words, by_first


def strings(node):
    if isinstance(node, str):
        yield node
    elif isinstance(node, list):
        for x in node:
            yield from strings(x)
    elif isinstance(node, dict):
        for v in node.values():
            yield from strings(v)


def probe(text, phrases, near, words, by_first):
    toks = norm(text).split()
    if not toks:
        return None
    nm = {}
    for t in set(toks):
        if len(t) < 3 or not re.fullmatch(r'[a-z]+', t) or t in words or t in near:
            continue
        for w in by_first.get(t[0], []):
            if abs(len(w) - len(t)) <= 1 and one_slip(t, w):
                nm.setdefault(t, set()).add(w)
    exact = near_hit = False
    for p in phrases:
        pt = p.split()
        slips_ok = len(pt) > 1 or len(p) >= 7
        for i in range(len(toks) - len(pt) + 1):
            same, slips = True, 0
            for j, w in enumerate(pt):
                t = toks[i + j]
                if t == w:
                    continue
                if slips_ok and slips == 0 and w in nm.get(t, ()):
                    slips += 1
                    continue
                same = False
                break
            if same:
                if slips == 0:
                    exact = True
                else:
                    near_hit = True
    if exact:
        return 'exact'
    return 'FUZZY-ONLY' if near_hit else None


def main(argv):
    phrases, near, words, by_first = load()
    if '--baseline' in argv:
        files = sorted(glob.glob(os.path.join(ROOT, 'assets', '**', '*.json'), recursive=True))
    else:
        files = [a for a in argv[1:] if not a.startswith('--')] or sorted(glob.glob(os.path.join(ROOT, 'assets', 'support', '**', '*.json'), recursive=True))
    bad = 0
    n = exact = 0
    for f in files:
        try:
            doc = json.load(open(f, encoding='utf8'))
        except ValueError:
            continue
        for s in strings(doc):
            n += 1
            r = probe(s, phrases, near, words, by_first)
            if r == 'exact':
                exact += 1
            elif r:
                bad += 1
                print('%s: %s: %s' % (os.path.relpath(f, ROOT), r, s[:100]))
    print('crisis probe: %d strings, %d exact crisis phrases (fine), %d would be fuzzy-only (fail)' % (n, exact, bad))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
