#!/usr/bin/env python3
"""Builds / re-verifies assets/academy/phrases/arabic_hfz.json (the Arabic and Hifz courses).

Same rules as tool/academy_phrases.py: no Arabic is typed by hand. Each phrase
below names a hadith (book, number) and the run of words in it (`tok`, counted
over the hadith's words after cleaning exactly as academy_phrases.extract does)
that is copied, letter for letter with its vowel marks, into the registry.
Only the transliteration, the English meaning and the word glosses are the
author's own learning aids and are flagged for scholar review.

Source corpus: github.com/fawazahmed0/hadith-api (branch `1`, editions/ara-*.json).

    python3 tool/academy_phrases_arabic_hfz.py build    # rewrite the registry
    python3 tool/academy_phrases_arabic_hfz.py verify   # re-check it against the corpus
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import academy_phrases as ap  # noqa: E402

OUT = os.path.join(ap.ROOT, 'assets', 'academy', 'phrases', 'arabic_hfz.json')
W = ap.W

SPEC = [
    dict(id='greet.1', book='tirmidhi', num=2689, tok=(40, 42),
         tr="As-salaamu ‘alaykum", en='Peace be upon you.',
         words=W(('as-salaamu', 'the peace'), ('‘alaykum', 'upon you')),
         cites=['Tirmidhi 2689 (graded sahih by al-Albani)',
                'Bukhari 6227 (the greeting Allah taught Adam to give the angels)']),
    dict(id='greet.2', book='tirmidhi', num=2689, tok=(54, 58),
         tr="As-salaamu ‘alaykum wa rahmatullaah", en='Peace be upon you, and the mercy of Allah.',
         words=W(('as-salaamu', 'the peace'), ('‘alaykum', 'upon you'), ('wa-rahmatu', 'and the mercy of'),
                 ('Allaah', 'Allah')),
         cites=['Tirmidhi 2689 (graded sahih by al-Albani)']),
    dict(id='greet.3', book='tirmidhi', num=2689, tok=(69, 74),
         tr="As-salaamu ‘alaykum wa rahmatullaahi wa barakaatuh",
         en='Peace be upon you, and the mercy of Allah, and His blessings.',
         words=W(('as-salaamu', 'the peace'), ('‘alaykum', 'upon you'), ('wa-rahmatu', 'and the mercy of'),
                 ('Allaahi', 'Allah'), ('wa-barakaatuhu', 'and His blessings')),
         cites=['Tirmidhi 2689 (graded sahih by al-Albani)']),
    dict(id='greet.reply', book='muslim', num='2380.03', tok=(187, 189),
         tr="Wa ‘alaykumus-salaam", en='And upon you be peace.',
         words=W(('wa-‘alaykum', 'and upon you'), ('as-salaamu', 'the peace')),
         cites=['Muslim 2380 (al-Khidr answers Musa, in the hadith of Musa and al-Khidr)']),
    dict(id='greet.reply.one', book='bukhari', num=6251, tok=(51, 53),
         tr="Wa ‘alaykas-salaam", en='And upon you (one person) be peace.',
         words=W(('wa-‘alayka', 'and upon you (to one person)'), ('as-salaamu', 'the peace')),
         cites=['Bukhari 6251 (the Prophet ﷺ answers the man who greeted him)']),
    dict(id='isti3adha', book='bukhari', num=6115, tok=(53, 58),
         tr="A‘oodhu billaahi minash-shaytaanir-rajeem", en='I seek refuge with Allah from Satan, the accursed.',
         words=W(('a‘oodhu', 'I seek refuge'), ('billaahi', 'with Allah'), ('mina', 'from'),
                 ('ash-shaytaani', 'Satan'), ('ar-rajeem', 'the accursed')),
         cites=['Bukhari 6115 (the Prophet ﷺ teaches the words to a man in anger)',
                "Qur’an 16:98 (the command to seek refuge before reciting)"]),
]

GRADES_EXPECTED = {('tirmidhi', 2689): 'Al-Albani'}


def toks(book, num):
    h = ap.hadith(book, num)
    t = [ap.clean_token(x) for x in h['text'].split()]
    return [x for x in t if x and ap.norm(x)]


def build():
    out = {}
    for sp in SPEC:
        a, b = sp['tok']
        got = ' '.join(toks(sp['book'], sp['num'])[a:b])
        assert len(got.split()) == len(sp['words']), (sp['id'], len(got.split()), len(sp['words']))
        bk = {'bukhari': 'Bukhari', 'muslim': 'Muslim', 'abudawud': 'Abu Dawud', 'tirmidhi': 'Tirmidhi',
              'nasai': "Nasa'i"}[sp['book']]
        grader = 'graded by al-Albani; ' if sp['book'] in ('abudawud', 'nasai', 'tirmidhi') else ''
        out[sp['id']] = {
            'arabic': got,
            'status': 'verified',
            'translit': sp['tr'],
            'meaning': sp['en'],
            'words': sp['words'],
            'sources': sp['cites'],
            'copiedFrom': '%s %s (%sfawazahmed0/hadith-api, ara-%s)' % (bk, sp['num'], grader, sp['book']),
            'needsScholarReview': True,
            'reviewNote': ("Arabic is copied from the cited text. The transliteration, the English meaning and "
                           "the word glosses are the app author's own learning aids and have not been reviewed "
                           "by a scholar."),
        }
    doc = {
        'schema': 1,
        'note': ('Verified-phrase registry for the Arabic and Hifz courses (Academy v3). A lesson never contains '
                 'Arabic of its own: it names a phrase here, or an ayah of assets/quran/quran.json as '
                 'q:<surah>:<ayah>. `status: verified` means the Arabic was copied letter for letter from the '
                 'cited primary-source text on the date below; it does NOT mean a scholar has reviewed it (see '
                 'needsScholarReview). Rebuild or re-check with tool/academy_phrases_arabic_hfz.py.'),
        'checked': ap.CHECKED,
        'corpus': ('github.com/fawazahmed0/hadith-api (branch 1, editions/ara-*.json); sunnah.com numbering; '
                   'Muslim by Abd al-Baqi number'),
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
        a, b = sp['tok']
        if ' '.join(toks(sp['book'], sp['num'])[a:b]) != e.get('arabic'):
            print('MISMATCH', sp['id']); bad += 1
    for (b, n), who in GRADES_EXPECTED.items():
        if not any(name == who for name, _ in ap.grades(b, n)):
            print('GRADE GONE', b, n, who); bad += 1
    print('verify:', 'OK' if not bad else '%d problems' % bad)
    return 1 if bad else 0


if __name__ == '__main__':
    cmd = sys.argv[1] if len(sys.argv) > 1 else 'verify'
    if cmd == 'build':
        build()
    else:
        sys.exit(verify())
