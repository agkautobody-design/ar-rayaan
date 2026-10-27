#!/usr/bin/env python3
"""Self-test for validate_packs.py: a good pack passes, and each rule has a
bad example that must fail. Run: python3 tool/support/validate_packs.py --self-test"""
import copy
import json
import os
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import validate_packs as vp  # noqa: E402

V = vp.hc.load_verdicts()


def pick(book, graded=False):
    for k, v in sorted(V.items()):
        if k.startswith(book + ':') and v.get('verdict') == 'ok' and not vp.WEAK_GRADE.search(v.get('grade') or ''):
            if graded and 'albani' not in (v.get('grader') or '').lower():
                continue
            return k, v
    raise SystemExit('no verdict for ' + book)


BK, BV = pick('bukhari')
TK, TV = pick('tirmidhi', graded=True)


def snip(**kw):
    s = {
        'id': 'alcohol.orient.001', 'kind': 'orient', 'stage': ['open'],
        'text': {'en': 'Thank you for telling me. I am glad you are here. What would help most right now?'},
        'ageBand': ['adult'], 'tags': ['opening'], 'triggers': ['drink'], 'doNotSay': [],
        'sources': [], 'evidenceLevel': 'N', 'risk': 'low',
        'needsScholarReview': False, 'needsClinicianReview': False, 'needsNativeClinicianReview': False,
        'reviewedBy': None, 'reviewedOn': None, 'status': 'draft',
    }
    s.update(kw)
    return s


def pack(snippets, **kw):
    p = {'schema': 1, 'pack': 'alcohol', 'packKind': 'knowledge', 'topic': 'alcohol', 'audience': 'hadi', 'version': '0.1.0',
         'createdOn': '2026-10-27', 'reviewBy': '2099-01-01', 'languages': ['en'], 'snippets': snippets}
    p.update(kw)
    return p


def run(p, name='alcohol'):
    d = tempfile.mkdtemp()
    path = os.path.join(d, name + '.json')
    json.dump(p, open(path, 'w'))
    rep, _ = vp.check_pack(path, V)
    return rep.errors


def good_pack():
    # knowledge pack so the 25-snippet floor does not apply; kind fact.
    return pack([snip(kind='fact')])


CASES = []


def bad(label, p, needle, name='alcohol'):
    CASES.append((label, p, needle, name))


def with_text(t, **kw):
    return pack([snip(kind='fact', text={'en': t}, **kw)])


def main():
    fails = 0
    errs = run(good_pack())
    if errs:
        print('FAIL good pack rejected:', errs)
        fails += 1
    # forbidden phrases
    for label, t in [
        ('dose', 'Take 10 mg each night.'), ('taper', 'Here is a taper schedule for you.'), ('just stop', 'You can just stop today.'),
        ('cold turkey', 'Going cold turkey is fine.'), ('shaming', 'You are an addict.'), ('obey', 'You should obey your husband.'),
        ('4:34', 'See 4:34 for what a husband may do.'), ('must tell family', 'You must tell your family tonight.'),
        ('secrecy', 'I promise I will keep this secret.'), ('feel', 'I know how you feel.'), ('diagnosis', 'You have depression.'),
        ('stat', 'Studies show most people relapse.'), ('url', 'See https://example.com now.'),
        ('hook', 'Does that help? Let me know if you need more.'), ('emoji', 'Well done \U0001F600 friend.'),
        ('pray more', 'Just pray more and it will pass.'), ('safe amount', 'A safe amount is two drinks.'),
        ('hadith in text', 'As in Bukhari 7507 it is forgiven.'), ('quran in text', 'Read (Qur\'an 39:53) tonight.'),
        ('arabic', 'Say بسم الله now.'),
        
        ('forty days', 'Your prayer is not accepted for forty days after that.'),
        ('marriage', 'You should get married soon.'),
    ]:
        bad('text: ' + label, with_text(t), '')
    bad('number in support text', pack([snip(text={'en': 'Call 0800123456 now.'})], packKind='support'), 'number or percentage')
    bad('percent in support text', pack([snip(text={'en': 'About half, 50%, slip.'})], packKind='support'), 'number or percentage')
    bad('two questions', pack([snip(text={'en': 'How are you? What happened today?'})], packKind='support'), 'question mark')
    bad('moralising first reply', pack([snip(text={'en': 'That is a sin and you know it.'})]), 'moralising')
    bad('missing field', pack([{k: v for k, v in snip(kind='fact').items() if k != 'tags'}]), "missing required field 'tags'")
    bad('unknown field', pack([snip(kind='fact', extra=1)]), 'unknown field')
    bad('kind not allowed in pack kind', pack([snip(kind='safety')]), 'not allowed in a knowledge pack')
    bad('bad id', pack([snip(kind='fact', id='Alcohol-1')]), 'bad id')
    bad('id wrong pack', pack([snip(kind='fact', id='gambling.fact.001')]), 'must start with the pack')
    bad('duplicate id', pack([snip(kind='fact'), snip(kind='fact', text={'en': 'A different line here for sure.'})]), 'duplicate id')
    bad('duplicate text', pack([snip(kind='fact'), snip(kind='fact', id='alcohol.fact.002')]), 'duplicates')
    bad('expired', pack([snip(kind='fact')], reviewBy='2020-01-01'), 'expired')
    bad('file name mismatch', good_pack(), 'does not match file name', name='gambling')
    bad('no sources but evidence C', pack([snip(kind='fact', evidenceLevel='C')]), 'no sources')
    bad('weak hadith', pack([snip(kind='islamic', sources=[{'type': 'hadith', 'ref': 'tirmidhi:1862', 'grade': 'Sahih', 'grader': 'al-Albani'}],
                                  evidenceLevel='D', needsScholarReview=True)]), 'must not be used')
    bad('hadith without verdict', pack([snip(kind='fact', sources=[{'type': 'hadith', 'ref': 'bukhari:99999', 'grade': 'Sahih', 'grader': 'two Sahihs'}],
                                            evidenceLevel='D', needsScholarReview=True)]), 'no verdict')
    bad('hadith without scholar flag', pack([snip(kind='fact', sources=[{'type': 'hadith', 'ref': BK, 'grade': 'Sahih', 'grader': 'two Sahihs'}], evidenceLevel='D')]),
        'needsScholarReview must be true')
    bad('graded hadith without grader', pack([snip(kind='fact', sources=[{'type': 'hadith', 'ref': TK}], evidenceLevel='D', needsScholarReview=True)]), 'needs grade and grader')
    bad('bad quran ref', pack([snip(kind='fact', sources=[{'type': 'quran', 'ref': '2:999'}], evidenceLevel='D', needsScholarReview=True)]), 'does not exist')
    bad('quran 4:34', pack([snip(kind='fact', sources=[{'type': 'quran', 'ref': '4:34'}], evidenceLevel='D', needsScholarReview=True)]), 'not allowed in packs')
    bad('clinical without url', pack([snip(kind='fact', sources=[{'type': 'clinical', 'section': 'RES_H1 2.1'}], evidenceLevel='A', needsClinicianReview=True)]), 'needs the RES_H1 url')
    bad('clinical without flag', pack([snip(kind='fact', sources=[{'type': 'clinical', 'section': 'RES_H1 2.1', 'url': 'https://www.nice.org.uk/guidance/cg100'}], evidenceLevel='A')]),
        'needsClinicianReview must be true')
    bad('non-English outside allowed kinds', pack([snip(kind='fact', text={'en': 'Hello there friend.', 'ar': 'مرحبا بك'}, needsNativeClinicianReview=True)],
                                                  languages=['en', 'ar']), 'only allowed for safety')
    bad('shippable without reviewer', pack([snip(kind='fact', status='shippable')]), 'requires reviewedBy')
    bad('half reviewed', pack([snip(kind='fact', reviewedOn='2026-10-27')]), 'both be null or both set')
    bad('disputed without wording', pack([snip(kind='fact', disputed=True, schoolsNamed=['hanafi'], needsScholarReview=True)]), 'scholars differ')
    bad('child needs flags', pack([snip(kind='fact', ageBand=['5-8'], text={'en': 'You did well today.'})]), 'child age band')
    bad('child long sentence', pack([snip(kind='fact', ageBand=['5-8'], needsClinicianReview=True, needsSafeguardingReview=True,
                                          text={'en': 'This is one very long sentence that goes on and on and on and on for far too many words to read.'})]), 'too long')
    bad('child tell parents', pack([snip(kind='fact', ageBand=['9-12'], needsClinicianReview=True, needsSafeguardingReview=True, text={'en': 'Please tell your parents today.'})]), 'parent-only')
    bad('undeclared slot', pack([snip(kind='fact', text={'en': 'Hello {name}, welcome.'})]), 'not declared')
    bad('conversation without rotation', pack([snip(kind='converse', move='greet_morning', tone='warm', variantGroup='g')], packKind='conversation'), 'rotation')
    bad('conversation too few variants', pack([snip(kind='converse', move='greet_morning', tone='warm', variantGroup='g')], packKind='conversation',
                                              rotation={'strategy': 'seeded-no-repeat', 'defaultMinGapTurns': 6}), 'need >= 6')
    # conversation pack that passes
    openers = ['Good morning to you.', 'Morning. Hope the day starts gently.', 'A fresh morning, welcome in.', 'Peace and good morning.',
               'Hello, it is a new day.', 'Early start today, welcome.']
    tones = ['warm', 'brief', 'formal', 'warm', 'brief', 'formal']
    conv = pack([snip(id='alcohol.greet.%03d' % (i + 1), kind='converse', move='greet_morning', tone=tones[i], variantGroup='greet_morning',
                      text={'en': openers[i]}) for i in range(6)], packKind='conversation',
                rotation={'strategy': 'seeded-no-repeat', 'defaultMinGapTurns': 6})
    errs = run(conv)
    if errs:
        print('FAIL good conversation pack rejected:', errs)
        fails += 1
    dup = copy.deepcopy(conv)
    dup['snippets'][1]['text']['en'] = 'Good morning to everyone.'
    bad('same opening words', dup, 'open with the same words')
    for label, p, needle, name in CASES:
        errs = run(p, name)
        if not errs:
            print('FAIL expected a failure but passed:', label)
            fails += 1
        elif needle and not any(needle in e for e in errs):
            print('FAIL %s: wanted %r, got %s' % (label, needle, errs[:3]))
            fails += 1
    print('self-test: %d cases, %d problems' % (len(CASES) + 2, fails))
    return 1 if fails else 0


if __name__ == '__main__':
    sys.exit(main())
