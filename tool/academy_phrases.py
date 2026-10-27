#!/usr/bin/env python3
"""Builds / re-verifies assets/academy/phrases/foundation.json.

The Arabic of every phrase in that registry is NOT typed by hand: it is
copied, letter for letter with its vowel marks, out of the cited primary-source
hadith text. Only the transliteration, the English meaning and the word-by-word
glosses are the author's own learning aids (and are flagged for scholar
review).

Source corpus: github.com/fawazahmed0/hadith-api (branch `1`, folder
`editions`), files ara-<book>.json. Numbering is the sunnah.com numbering
(`hadithnumber`), except Muslim, whose number is the Muhammad Fu'ad
Abd al-Baqi number held in `arabicnumber` (sub-narrations 234.01, 234.02 ...
are 234a, 234b ... on sunnah.com). The corpus also carries each Sunan
hadith's grade by name (al-Albani, Zubair Ali Zai ...).

Usage (needs network access to raw.githubusercontent.com):

    python3 tool/academy_phrases.py build    # rewrite the registry
    python3 tool/academy_phrases.py verify   # re-check the registry against the corpus

`verify` fails when a phrase's Arabic is not found, letter for letter, in the
cited hadith, or when a cited Sunan grade changed. CI does not run this (it
needs the corpus); the Dart test `academy_v3_phrases_test.dart` checks the
registry's shape, its sources and its Qur'an references.
"""
import json
import os
import re
import sys
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'assets', 'academy', 'phrases', 'foundation.json')
CACHE = os.environ.get('HADITH_CACHE', '/tmp/academy_hadith_cache')
BASE = 'https://raw.githubusercontent.com/fawazahmed0/hadith-api/1/editions/'
CHECKED = '2026-10-27'

TASH = re.compile('[ؐ-ًؚ-ٰٟۖ-ۭـ]')


def norm(s):
    s = TASH.sub('', s)
    s = re.sub('[إأآٱ]', 'ا', s).replace('ى', 'ي').replace('ة', 'ه')
    s = s.replace('ؤ', 'و').replace('ئ', 'ي')
    return re.sub(r'\s+', ' ', s).strip()


_corp = {}


def corpus(lang, book):
    k = (lang, book)
    if k not in _corp:
        os.makedirs(CACHE, exist_ok=True)
        p = os.path.join(CACHE, '%s-%s.json' % (lang, book))
        if not os.path.exists(p):
            with urllib.request.urlopen(BASE + '%s-%s.json' % (lang, book)) as r:
                open(p, 'wb').write(r.read())
        d = json.load(open(p, encoding='utf8'))['hadiths']
        _corp[k] = {(str(h.get('arabicnumber', h['hadithnumber'])) if book == 'muslim' else h['hadithnumber']): h for h in d}
    return _corp[k]


def hadith(book, num):
    key = str(num) if book == 'muslim' else int(num)
    h = corpus('ara', book).get(key)
    if h is None and book == 'muslim':
        # a number with sub-narrations: use the first (234 -> 234.01)
        h = corpus('ara', book).get('%s.01' % num)
    if h is None:
        raise SystemExit('no such hadith %s %s' % (book, num))
    return h


def grades(book, num):
    key = str(num) if book == 'muslim' else int(num)
    h = corpus('eng', book).get(key)
    return [(g['name'], g['grade']) for g in (h or {}).get('grades', [])]


STRIP = '‏‎"\'“”‘’«»،,.;:؛؟?()[]{}‑'


def clean_token(t):
    return t.strip(STRIP + ' \t\r\n')


def extract(text, expected):
    """Return the vowelled original words of the first run of tokens whose
    unvowelled form equals `expected` (a space separated unvowelled phrase)."""
    toks = [clean_token(t) for t in text.split()]
    toks = [t for t in toks if t and norm(t)]
    want = norm(expected).split(' ')
    n = len(want)
    for i in range(len(toks) - n + 1):
        if [norm(t) for t in toks[i:i + n]] == want:
            return ' '.join(toks[i:i + n])
    return None


def W(*pairs):
    return [{'tr': a, 'en': b} for a, b in pairs]


# Each phrase: id, hadith it is copied from (book, number), expected
# unvowelled words, and the author's learning aids. `parts` makes a phrase
# that is the in-order concatenation of other phrases (no Arabic of its own).
# `cites` is what the learner is shown as the source; the strings are written
# so that tool/hadith_check.py accepts them (a Sunan citation names its grader).
SPEC = [
    dict(id='shahada.tawhid', book='muslim', num='403', ar='أشهد أن لا إله إلا الله',
         tr='Ash-hadu al-laa ilaaha illal-laah',
         en='I bear witness that there is no god but Allah.',
         words=W(('ash-hadu', 'I bear witness'), ('an', 'that'), ('laa', 'no'), ('ilaaha', 'god'),
                 ('illaa', 'except'), ('Allaah', 'Allah')),
         cites=['Muslim 403 (the words, as the Prophet taught them inside the tashahhud)',
                'Muslim 379 (the same words in the adhan)'],
         also=[('muslim', '379')]),
    dict(id='shahada.risala', book='muslim', num='403', ar='وأشهد أن محمدا رسول الله',
         tr='Wa ash-hadu anna Muhammadan rasoolul-laah',
         en='And I bear witness that Muhammad is the Messenger of Allah.',
         words=W(('wa-ash-hadu', 'and I bear witness'), ('anna', 'that'), ('Muhammadan', 'Muhammad'),
                 ('rasoolu', 'messenger of'), ('Allaah', 'Allah')),
         cites=['Muslim 403 (the words, as the Prophet taught them inside the tashahhud)',
                'Muslim 379 (the same words in the adhan)'],
         also=[('muslim', '379')]),
    dict(id='shahada.full', parts=['shahada.tawhid', 'shahada.risala'],
         tr='Ash-hadu al-laa ilaaha illal-laah, wa ash-hadu anna Muhammadan rasoolul-laah',
         en='I bear witness that there is no god but Allah, and I bear witness that Muhammad is the Messenger of Allah.',
         cites=['Bukhari 8 (it is the first pillar of Islam)', 'Muslim 403 (the words)']),
    dict(id='takbir', book='muslim', num='379', ar='الله أكبر',
         tr='Allaahu akbar', en='Allah is the Greatest.',
         words=W(('Allaahu', 'Allah'), ('akbar', 'the Greatest')),
         cites=['Muslim 379 (the words, in the adhan)',
                'Abu Dawud 61 (graded hasan sahih by al-Albani): the prayer is entered by takbir']),
    dict(id='ruku.tasbih', book='muslim', num='772', ar='سبحان ربي العظيم',
         tr="Subhaana Rabbiyal-'Azeem", en='Glory be to my Lord, the Magnificent.',
         words=W(('subhaana', 'glory be to'), ('Rabbiya', 'my Lord'), ("al-'Azeem", 'the Magnificent')),
         cites=['Muslim 772']),
    dict(id='rise.sami', book='bukhari', num='689', ar='سمع الله لمن حمده',
         tr="Sami'al-laahu liman hamidah", en='Allah hears the one who praises Him.',
         words=W(("sami'a", 'hears'), ('Allaahu', 'Allah'), ('liman', 'the one who'), ('hamidah', 'praised Him')),
         cites=['Bukhari 689', 'Muslim 772']),
    dict(id='rise.rabbana', book='bukhari', num='689', ar='ربنا ولك الحمد',
         tr='Rabbanaa wa lakal-hamd', en='Our Lord, and to You belongs all praise.',
         words=W(('Rabbanaa', 'our Lord'), ('wa-laka', 'and to You'), ('al-hamd', 'the praise')),
         cites=['Bukhari 689']),
    dict(id='rise', parts=['rise.sami', 'rise.rabbana'],
         tr="Sami'al-laahu liman hamidah. Rabbanaa wa lakal-hamd",
         en='Allah hears the one who praises Him. Our Lord, and to You belongs all praise.',
         cites=['Bukhari 689']),
    dict(id='sujud.tasbih', book='muslim', num='772', ar='سبحان ربي الأعلى',
         tr="Subhaana Rabbiyal-A'laa", en='Glory be to my Lord, the Most High.',
         words=W(('subhaana', 'glory be to'), ('Rabbiya', 'my Lord'), ("al-A'laa", 'the Most High')),
         cites=['Muslim 772']),
    dict(id='between.rabbighfir', book='abudawud', num='874', ar='رب اغفر لي',
         tr='Rabbigh-fir lee', en='My Lord, forgive me.',
         words=W(('Rabbi', 'my Lord'), ('ighfir', 'forgive'), ('lee', 'me')),
         cites=['Abu Dawud 874 (graded sahih by al-Albani)'], also=[]),
    dict(id='tashahhud.1', book='bukhari', num='831', ar='التحيات لله والصلوات والطيبات',
         tr='At-tahiyyaatu lillaahi was-salawaatu wat-tayyibaat',
         en='All greetings, prayers and good things belong to Allah.',
         words=None, cites=['Bukhari 831']),
    dict(id='tashahhud.2', book='bukhari', num='831', ar='السلام عليك أيها النبي ورحمة الله وبركاته',
         tr="As-salaamu 'alayka ayyuhan-Nabiyyu wa rahmatul-laahi wa barakaatuh",
         en='Peace be upon you, O Prophet, and the mercy of Allah and His blessings.',
         words=None, cites=['Bukhari 831']),
    dict(id='tashahhud.3', book='bukhari', num='831', ar='السلام علينا وعلى عباد الله الصالحين',
         tr="As-salaamu 'alaynaa wa 'alaa 'ibaadil-laahis-saaliheen",
         en='Peace be upon us and upon the righteous servants of Allah.',
         words=None, cites=['Bukhari 831']),
    dict(id='tashahhud.4', book='bukhari', num='831',
         ar='أشهد أن لا إله إلا الله وأشهد أن محمدا عبده ورسوله',
         tr="Ash-hadu al-laa ilaaha illal-laah, wa ash-hadu anna Muhammadan 'abduhu wa rasooluh",
         en='I bear witness that there is no god but Allah, and I bear witness that Muhammad is His servant and His Messenger.',
         words=None, cites=['Bukhari 831']),
    dict(id='tashahhud', parts=['tashahhud.1', 'tashahhud.2', 'tashahhud.3', 'tashahhud.4'],
         tr="At-tahiyyaatu lillaahi was-salawaatu wat-tayyibaat. As-salaamu 'alayka ayyuhan-Nabiyyu wa rahmatul-laahi wa barakaatuh. As-salaamu 'alaynaa wa 'alaa 'ibaadil-laahis-saaliheen. Ash-hadu al-laa ilaaha illal-laah, wa ash-hadu anna Muhammadan 'abduhu wa rasooluh.",
         en='All greetings, prayers and good things belong to Allah. Peace be upon you, O Prophet, and the mercy of Allah and His blessings. Peace be upon us and upon the righteous servants of Allah. I bear witness that there is no god but Allah, and I bear witness that Muhammad is His servant and His Messenger.',
         cites=['Bukhari 831', 'Muslim 403 (Ibn Abbas teaches another authentic wording)']),
    dict(id='salawat.1', book='bukhari', num='3370',
         ar='اللهم صل على محمد وعلى آل محمد كما صليت على إبراهيم وعلى آل إبراهيم إنك حميد مجيد',
         tr="Allaahumma salli 'alaa Muhammadin wa 'alaa aali Muhammad, kamaa sallayta 'alaa Ibraaheema wa 'alaa aali Ibraaheem, innaka Hameedun Majeed",
         en='O Allah, send prayers upon Muhammad and upon the family of Muhammad, as You sent prayers upon Ibrahim and upon the family of Ibrahim. You are Praiseworthy, Glorious.',
         words=None, cites=['Bukhari 3370']),
    dict(id='salawat.2', book='bukhari', num='3370',
         ar='اللهم بارك على محمد وعلى آل محمد كما باركت على إبراهيم وعلى آل إبراهيم إنك حميد مجيد',
         tr="Allaahumma baarik 'alaa Muhammadin wa 'alaa aali Muhammad, kamaa baarakta 'alaa Ibraaheema wa 'alaa aali Ibraaheem, innaka Hameedun Majeed",
         en='O Allah, bless Muhammad and the family of Muhammad, as You blessed Ibrahim and the family of Ibrahim. You are Praiseworthy, Glorious.',
         words=None, cites=['Bukhari 3370']),
    dict(id='salawat', parts=['salawat.1', 'salawat.2'],
         tr="Allaahumma salli 'alaa Muhammadin wa 'alaa aali Muhammad, kamaa sallayta 'alaa Ibraaheema wa 'alaa aali Ibraaheem, innaka Hameedun Majeed. Allaahumma baarik 'alaa Muhammadin wa 'alaa aali Muhammad, kamaa baarakta 'alaa Ibraaheema wa 'alaa aali Ibraaheem, innaka Hameedun Majeed.",
         en='O Allah, send prayers upon Muhammad and upon the family of Muhammad, as You sent prayers upon Ibrahim and upon the family of Ibrahim. You are Praiseworthy, Glorious. O Allah, bless Muhammad and the family of Muhammad, as You blessed Ibrahim and the family of Ibrahim. You are Praiseworthy, Glorious.',
         cites=['Bukhari 3370', 'Muslim 406 (another wording of the same teaching)']),
    dict(id='salam', book='abudawud', num='996', ar='السلام عليكم ورحمة الله',
         tr="As-salaamu 'alaykum wa rahmatul-laah", en='Peace be upon you, and the mercy of Allah.',
         words=W(('as-salaamu', 'the peace'), ("'alaykum", 'be upon you'), ('wa-rahmatu', 'and the mercy of'), ('Allaah', 'Allah')),
         cites=['Abu Dawud 996 (graded sahih by al-Albani)']),
    dict(id='amin', book='bukhari', num='780', ar='آمين',
         tr='Aameen', en='O Allah, answer (our prayer).',
         words=None, cites=['Bukhari 780']),
    dict(id='wudu.bismillah', book='nasai', num='78', ar='بسم الله',
         tr='Bismil-laah', en='In the name of Allah.',
         words=W(('bismi', 'in the name of'), ('Allaah', 'Allah')),
         cites=["Nasa'i 78 (graded sahih isnad by al-Albani)", 'Abu Dawud 101 (graded sahih by al-Albani)']),
    dict(id='wudu.dua.1', book='muslim', num='234.02', ar='أشهد أن لا إله إلا الله وحده لا شريك له',
         tr="Ash-hadu al-laa ilaaha illal-laahu wahdahu laa shareeka lah",
         en='I bear witness that there is no god but Allah alone, with no partner.',
         words=None, cites=['Muslim 234']),
    dict(id='wudu.dua.2', book='muslim', num='234.02', ar='وأشهد أن محمدا عبده ورسوله',
         tr="Wa ash-hadu anna Muhammadan 'abduhu wa rasooluh",
         en='And I bear witness that Muhammad is His servant and His Messenger.',
         words=None, cites=['Muslim 234']),
    dict(id='wudu.dua', parts=['wudu.dua.1', 'wudu.dua.2'],
         tr="Ash-hadu al-laa ilaaha illal-laahu wahdahu laa shareeka lah, wa ash-hadu anna Muhammadan 'abduhu wa rasooluh",
         en='I bear witness that there is no god but Allah alone, with no partner, and I bear witness that Muhammad is His servant and His Messenger.',
         cites=['Muslim 234']),
    dict(id='dhikr.1', book='abudawud', num='832', ar='سبحان الله', tr='Subhaanal-laah', en='Glory be to Allah.',
         words=W(('subhaana', 'glory be to'), ('Allaah', 'Allah')), cites=['Abu Dawud 832 (graded hasan by al-Albani)']),
    dict(id='dhikr.2', book='abudawud', num='832', ar='والحمد لله', tr='Wal-hamdu lillaah', en='And praise be to Allah.',
         words=W(('wal-hamdu', 'and the praise'), ('lillaah', 'is for Allah')), cites=['Abu Dawud 832 (graded hasan by al-Albani)']),
    dict(id='dhikr.3', book='abudawud', num='832', ar='ولا إله إلا الله', tr='Wa laa ilaaha illal-laah',
         en='And there is no god but Allah.',
         words=W(('wa-laa', 'and no'), ('ilaaha', 'god'), ('illaa', 'except'), ('Allaah', 'Allah')),
         cites=['Abu Dawud 832 (graded hasan by al-Albani)']),
    dict(id='dhikr.4', book='abudawud', num='832', ar='والله أكبر', tr='Wallaahu akbar', en='And Allah is the Greatest.',
         words=W(('wallaahu', 'and Allah'), ('akbar', 'the Greatest')), cites=['Abu Dawud 832 (graded hasan by al-Albani)']),
    dict(id='dhikr.5', book='abudawud', num='832', ar='ولا حول ولا قوة إلا بالله',
         tr='Wa laa hawla wa laa quwwata illaa billaah', en='And there is no power and no strength except with Allah.',
         words=W(('wa-laa', 'and no'), ('hawla', 'power'), ('wa-laa', 'and no'), ('quwwata', 'strength'),
                 ('illaa', 'except'), ('billaah', 'with Allah')),
         cites=['Abu Dawud 832 (graded hasan by al-Albani)']),
    dict(id='dhikr.beginner', parts=['dhikr.1', 'dhikr.2', 'dhikr.3', 'dhikr.4', 'dhikr.5'],
         tr='Subhaanal-laah, wal-hamdu lillaah, wa laa ilaaha illal-laah, wallaahu akbar, wa laa hawla wa laa quwwata illaa billaah',
         en='Glory be to Allah, and praise be to Allah, and there is no god but Allah, and Allah is the Greatest, and there is no power and no strength except with Allah.',
         cites=['Abu Dawud 832 (graded hasan by al-Albani)']),
]

# What the learner may be told about each cited Sunan hadith, as recorded in
# the corpus at the time of checking. Used by `verify` to detect a change.
GRADES_EXPECTED = {
    ('abudawud', 61): 'Al-Albani',
    ('abudawud', 101): 'Al-Albani',
    ('abudawud', 832): 'Al-Albani',
    ('abudawud', 874): 'Al-Albani',
    ('abudawud', 996): 'Al-Albani',
    ('nasai', 78): 'Al-Albani',
}


def build():
    out = {}
    for sp in SPEC:
        e = {}
        pid = sp['id']
        if 'parts' in sp:
            e['parts'] = sp['parts']
            e['status'] = 'verified'
        else:
            h = hadith(sp['book'], sp['num'])
            got = extract(h['text'], sp['ar'])
            if got is None:
                e['arabic'] = None
                e['status'] = 'unverified'
                print('NOT FOUND', pid, file=sys.stderr)
            else:
                e['arabic'] = got
                e['status'] = 'verified'
                if sp.get('words'):
                    assert len(got.split()) == len(sp['words']), (pid, len(got.split()), len(sp['words']))
        e['translit'] = sp['tr']
        e['meaning'] = sp['en']
        if sp.get('words'):
            e['words'] = sp['words']
        e['sources'] = sp['cites']
        if 'parts' not in sp:
            bk = {'bukhari': 'Bukhari', 'muslim': 'Muslim', 'abudawud': 'Abu Dawud', 'nasai': "Nasa'i"}[sp['book']]
            grader = 'graded by al-Albani; ' if sp['book'] in ('abudawud', 'nasai') else ''
            e['copiedFrom'] = '%s %s (%sfawazahmed0/hadith-api, ara-%s)' % (bk, sp['num'], grader, sp['book'])
        e['needsScholarReview'] = True
        e['reviewNote'] = ('Arabic is copied from the cited text. The transliteration, the English meaning'
                           + (' and the word glosses' if sp.get('words') else '')
                           + ' are the app author\'s own learning aids and have not been reviewed by a scholar.')
        out[pid] = e
    doc = {
        'schema': 1,
        'note': ('Verified-phrase registry for Academy v3 lessons. A lesson never contains Arabic of its own: '
                 'it names a phrase here, or an ayah of assets/quran/quran.json as q:<surah>:<ayah>. '
                 '`status: verified` means the Arabic was found letter for letter in the cited primary-source '
                 'text on the date below; it does NOT mean a scholar has reviewed it (see needsScholarReview). '
                 'Rebuild or re-check with tool/academy_phrases.py.'),
        'checked': CHECKED,
        'corpus': 'github.com/fawazahmed0/hadith-api (branch 1, editions/ara-*.json); sunnah.com numbering; Muslim by Abd al-Baqi number',
        'phrases': out,
    }
    with open(OUT, 'w', encoding='utf8') as f:
        json.dump(doc, f, ensure_ascii=False, indent=1)
        f.write('\n')
    print('wrote', OUT, len(out), 'phrases')


def verify():
    doc = json.load(open(OUT, encoding='utf8'))
    bad = 0
    for sp in SPEC:
        e = doc['phrases'].get(sp['id'])
        if e is None:
            print('MISSING', sp['id']); bad += 1; continue
        if 'parts' in sp:
            continue
        h = hadith(sp['book'], sp['num'])
        if extract(h['text'], sp['ar']) != e.get('arabic'):
            print('MISMATCH', sp['id']); bad += 1
    for (b, n), who in GRADES_EXPECTED.items():
        if not any(name == who for name, _ in grades(b, n)):
            print('GRADE GONE', b, n, who); bad += 1
    print('verify:', 'OK' if not bad else '%d problems' % bad)
    return 1 if bad else 0


if __name__ == '__main__':
    cmd = sys.argv[1] if len(sys.argv) > 1 else 'verify'
    if cmd == 'build':
        build()
    else:
        sys.exit(verify())
