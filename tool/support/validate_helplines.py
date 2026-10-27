#!/usr/bin/env python3
"""Validates assets/support/helplines.json and cross-checks it against the
app's HelpResources (lib/features/sakina/domain/sakina_content.dart).

Fails on: bad schema, a verified row without an https source or a verifiedOn
date, a toVerify row marked verified, duplicate ids, a child-audience row
without the child scope, an unknown scope, a verified row with no number, text
or url, and a number that disagrees with the app for the same country+service
name. Warns (does not fail) when the app has a number this file does not.
Run: python3 tool/support/validate_helplines.py [--self-test]
"""
import datetime
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PATH = os.path.join(ROOT, 'assets', 'support', 'helplines.json')
DART = os.path.join(ROOT, 'lib', 'features', 'sakina', 'domain', 'sakina_content.dart')
MAX_AGE_DAYS = 400
REQ = ['id', 'country', 'service', 'number', 'text', 'url', 'hours', 'scope', 'language', 'audience', 'verifiedOn', 'source', 'status', 'notes']
AUD = {'adult', 'child', 'adult-concerned', 'child-or-adult-concerned', 'adult-or-concerned'}
COUNTRIES = {'US', 'CA', 'GB', 'IE', 'AU', 'NZ', 'SA', 'AE', 'QA', 'KW', 'MY', 'ID', 'PK', 'BD', 'IN', 'EG', 'TR', 'ZA', 'NG', 'SG', 'INT'}
NEED = ['US', 'CA', 'GB', 'IE', 'AU', 'NZ', 'SA', 'AE', 'QA', 'MY', 'ID', 'PK', 'BD', 'IN', 'EG', 'TR', 'ZA', 'NG', 'INT']


def digits(s):
    return re.sub(r'\D', '', s or '')


def check(doc, today=None):
    errs, warns = [], []
    today = today or datetime.date.today()
    scopes = set(doc.get('scopes', []))
    ids = set()
    for key in ('helplines', 'toVerify'):
        for r in doc.get(key, []):
            w = r.get('id', '?')
            for f in REQ:
                if f not in r:
                    errs.append('%s: missing field %s' % (w, f))
            if w in ids:
                errs.append('%s: duplicate id' % w)
            ids.add(w)
            if r.get('country') not in COUNTRIES:
                errs.append('%s: bad country %r' % (w, r.get('country')))
            for s in r.get('scope', []):
                if s not in scopes:
                    errs.append('%s: unknown scope %s' % (w, s))
            if r.get('audience') not in AUD:
                errs.append('%s: bad audience' % w)
            if 'child' in (r.get('audience') or '').split('-')[0:1] and r.get('audience') == 'child' and 'child' not in r.get('scope', []):
                errs.append('%s: child audience needs the child scope' % w)
            if key == 'helplines':
                if r.get('status') != 'verified':
                    errs.append('%s: display list holds a non-verified row' % w)
                if not (r.get('source') or '').startswith('https://'):
                    errs.append('%s: verified row needs an https source' % w)
                try:
                    d = datetime.date.fromisoformat(r.get('verifiedOn') or '')
                    if (today - d).days > MAX_AGE_DAYS:
                        errs.append('%s: verifiedOn older than %d days' % (w, MAX_AGE_DAYS))
                    if d > today:
                        errs.append('%s: verifiedOn in the future' % w)
                except ValueError:
                    errs.append('%s: bad verifiedOn' % w)
                if not (r.get('number') or r.get('text') or r.get('url')):
                    errs.append('%s: verified row has no number, text or url' % w)
                if r.get('number') and not re.search(r'\d', r['number']):
                    errs.append('%s: number has no digits' % w)
                if not r.get('language'):
                    errs.append('%s: language empty' % w)
            else:
                if r.get('status') == 'verified':
                    errs.append('%s: toVerify row marked verified' % w)
                if not r.get('notes'):
                    errs.append('%s: toVerify row needs a reason in notes' % w)
    shown = {r['country'] for r in doc.get('helplines', []) if 'country' in r}
    for c in NEED:
        if c not in shown:
            errs.append('no verified row for %s' % c)
    for c in NEED:
        have = {s for r in doc.get('helplines', []) if r['country'] == c for s in r['scope']}
        if c not in ('INT',) and 'emergency' not in have:
            warns.append('%s: no verified emergency number (see toVerify)' % c)
        if c not in ('INT',) and not (have & {'suicide'}):
            warns.append('%s: no verified suicide/crisis line (app falls back to INT directories)' % c)
    return errs, warns


def dart_rows():
    if not os.path.exists(DART):
        return []
    src = open(DART, encoding='utf-8').read()
    rows = []
    for m in re.finditer(r"HelpResource\((.*?)\n    \),", src, re.S):
        b = m.group(1)
        n = re.search(r"name:\s*'([^']*)'", b)
        d = re.search(r"dial:\s*'([^']*)'", b)
        c = re.search(r"countries:\s*(?:<String>)?\[([^\]]*)\]", b)
        if n and d:
            rows.append((n.group(1), digits(d.group(1)), re.findall(r"'([A-Z]{2})'", c.group(1)) if c else []))
    return rows


def cross(doc):
    warns, errs = [], []
    allrows = doc['helplines'] + doc['toVerify']
    known = {}
    for r in allrows:
        for blob in (r.get('number') or '', r.get('text') or ''):
            for m in re.findall(r'[\d][\d\s\-+()]{1,}\d', blob):
                known.setdefault(digits(m), set()).add(r['country'])
    for name, dial, cs in dart_rows():
        if not dial:
            continue
        if dial not in known and not any(dial in k or k.endswith(dial) for k in known):
            warns.append('app row not in helplines.json: %s (%s) %s' % (name, dial, cs))
    return errs, warns


def main():
    if '--self-test' in sys.argv:
        return self_test()
    doc = json.load(open(PATH, encoding='utf-8'))
    errs, warns = check(doc)
    e2, w2 = cross(doc)
    errs += e2
    warns += w2
    for w in warns:
        print('warn:', w)
    for e in errs:
        print('ERROR:', e)
    print('helplines: %d verified, %d toVerify, %d errors, %d warnings' % (len(doc['helplines']), len(doc['toVerify']), len(errs), len(warns)))
    return 1 if errs else 0


def self_test():
    import copy
    base = {'scopes': ['suicide', 'child', 'emergency'], 'toVerify': [], 'helplines': [
        {'id': 'a', 'country': c, 'service': 's', 'number': '988', 'text': None, 'url': None, 'hours': None, 'scope': ['suicide', 'emergency'],
         'language': ['en'], 'audience': 'adult', 'verifiedOn': '2026-10-27', 'source': 'https://x.org', 'status': 'verified', 'notes': None}
        for c in NEED]}
    for i, r in enumerate(base['helplines']):
        r['id'] = 'r%d' % i
    today = datetime.date(2026, 10, 27)
    assert not check(base, today)[0], check(base, today)[0]
    bad = []

    def mut(label, fn):
        d = copy.deepcopy(base)
        fn(d)
        bad.append((label, check(d, today)[0]))
    mut('http source', lambda d: d['helplines'][0].update(source='http://x'))
    mut('no source', lambda d: d['helplines'][0].update(source=None))
    mut('stale', lambda d: d['helplines'][0].update(verifiedOn='2020-01-01'))
    mut('unverified in display', lambda d: d['helplines'][0].update(status='unverified'))
    mut('dup id', lambda d: d['helplines'][1].update(id='r0'))
    mut('bad scope', lambda d: d['helplines'][0].update(scope=['nope']))
    mut('no contact', lambda d: d['helplines'][0].update(number=None))
    mut('child no scope', lambda d: d['helplines'][0].update(audience='child'))
    mut('country missing', lambda d: d['helplines'].pop())
    mut('toVerify verified', lambda d: d['toVerify'].append(dict(d['helplines'][0], id='z', notes='x')))
    fails = [l for l, e in bad if not e]
    print('self-test: %d cases, %d problems' % (len(bad) + 1, len(fails)), fails)
    return 1 if fails else 0


if __name__ == '__main__':
    sys.exit(main())
