#!/usr/bin/env python3
"""Builds / re-verifies assets/academy/phrases/aqid-und-daw.json.

The phrases used by the Aqeedah, Understanding the Qur'an and Dawah courses of
the Academy (v3 lessons). The Arabic of every phrase is NOT typed by hand: it is
cut, with its vowel marks, out of the cited hadith by word position (the words
numbered `start` up to but not including `end` of the narration `key`, counted
on spaces) in github.com/fawazahmed0/hadith-api (branch `1`, editions/ara-*.json).
Only the transliteration, the English meaning and the word glosses are the
author's own learning aids, and they are flagged for scholar review.

Numbering is the sunnah.com numbering (`hadithnumber`), except Muslim, which uses
the Muhammad Fu'ad Abd al-Baqi number held in `arabicnumber` (sub-narrations
2594.01 ... are 2594a ... on sunnah.com). `key` is the corpus key of the
narration the words are cut from.

Usage (needs network access to raw.githubusercontent.com):

    python3 tool/academy_phrases_aqid_und_daw.py build    # rewrite the registry
    python3 tool/academy_phrases_aqid_und_daw.py verify   # re-cut every phrase and compare

`verify` fails when a phrase's Arabic differs from the words cut from the
corpus, when the number of word glosses differs from the number of Arabic words,
or when a cited Sunan grade changed. CI does not run this (it needs the corpus);
the Dart tests check the registry's shape, its sources and its references.
"""
import json
import os
import sys
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'assets', 'academy', 'phrases', 'aqid-und-daw.json')
CACHE = os.environ.get('HADITH_CACHE', '/tmp/academy_hadith_cache')
BASE = 'https://raw.githubusercontent.com/fawazahmed0/hadith-api/1/editions/'
CHECKED = '2026-10-27'
STRIP = '‏‎"\'“”‘’«»،,.;:؛؟?()[]{}‑'
BOOK_NAME = {'bukhari': 'Bukhari', 'muslim': 'Muslim', 'abudawud': 'Abu Dawud'}

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
        _corp[k] = {(str(h.get('arabicnumber', h['hadithnumber'])) if book == 'muslim'
                     else str(h['hadithnumber'])): h for h in d}
    return _corp[k]


def clean(t):
    return t.strip(STRIP + ' \t\r\n')


def cut(book, key, start, end):
    h = corpus('ara', book).get(str(key))
    if h is None:
        raise SystemExit('no such narration %s %s' % (book, key))
    toks = [clean(t) for t in h['text'].split()]
    words = toks[start:end]
    if len(words) != end - start or any(not w for w in words):
        raise SystemExit('bad cut %s %s %s:%s' % (book, key, start, end))
    return ' '.join(words)


def grades(book, key):
    h = corpus('eng', book).get(str(key))
    return [(g['name'], g['grade']) for g in (h or {}).get('grades', [])]


def W(*pairs):
    return [{'tr': a, 'en': b} for a, b in pairs]


# Each leaf: id, book, key (narration), start, end (word positions), the author's
# learning aids, and the sources shown to the learner. `note` is for the reviewer.
LEAVES = [
    # ------------------------------------------------------------ Aqeedah
    dict(id='aqid.mercy', book='bukhari', key='7404', cut=(40, 44), num='7404',
         tr='Inna rahmatee taghlibu ghadabee', en='Truly, My mercy overcomes My anger.',
         words=W(('inna', 'truly'), ('rahmatee', 'My mercy'), ('taghlibu', 'overcomes'), ('ghadabee', 'My anger')),
         cites=['Bukhari 7404', 'Muslim 2751 (the same teaching in another wording)']),
    dict(id='aqid.names99.1', book='bukhari', key='2736', cut=(28, 36), num='2736',
         tr="Inna lillaahi tis'atan wa tis'eena ismaa, mi'atan illaa waahidan",
         en='Allah has ninety-nine names, one hundred less one.',
         words=W(('inna', 'truly'), ('lillaahi', 'Allah has'), ("tis'atan", 'nine'), ("wa-tis'eena", 'and ninety'),
                 ('ismaa', 'names'), ("mi'atan", 'a hundred'), ('illaa', 'except'), ('waahidan', 'one')),
         cites=['Bukhari 2736', 'Muslim 2677 (the same teaching in another wording)']),
    dict(id='aqid.names99.2', book='bukhari', key='2736', cut=(36, 40), num='2736',
         tr='Man ahsaahaa dakhalal-jannah', en='Whoever counts them [learns and keeps them] will enter Paradise.',
         words=W(('man', 'whoever'), ('ahsaahaa', 'counts them'), ('dakhala', 'enters'), ('al-jannah', 'Paradise')),
         cites=['Bukhari 2736'],
         note='The verb ahsaa has been explained as counting, memorising, understanding and acting on the names. '
              'The English gives the plain sense; the range of explanations is in the lesson text.'),
    dict(id='aqid.prophets.1', book='bukhari', key='3443', cut=(40, 45), num='3443',
         tr="Wal-anbiyaa'u ikhwatun li-'allaat, ummahaatuhum shattaa",
         en='The prophets are brothers from one father; their mothers are different.',
         words=W(("wal-anbiyaa'u", 'and the prophets'), ('ikhwatun', 'brothers'), ("li-'allaat", 'of one father'),
                 ('ummahaatuhum', 'their mothers'), ('shattaa', 'are different')),
         cites=['Bukhari 3443', 'Muslim 2365 (the same teaching in another wording)']),
    dict(id='aqid.prophets.2', book='bukhari', key='3443', cut=(45, 47), num='3443',
         tr='Wa deenuhum waahid', en='And their religion is one.',
         words=W(('wa-deenuhum', 'and their religion'), ('waahid', 'is one')),
         cites=['Bukhari 3443', 'Muslim 2365 (the same teaching in another wording)']),
    dict(id='aqid.iman.1', book='muslim', key='8.01', cut=(273, 281), num='8',
         tr="An tu'mina billaahi wa malaa'ikatihi wa kutubihi wa rusulihi wal-yawmil-aakhir",
         en='Faith is to believe in Allah, His angels, His books, His messengers and the Last Day,',
         words=W(('an', 'that'), ("tu'mina", 'you believe'), ('billaahi', 'in Allah'), ("wa-malaa'ikatihi", 'and His angels'),
                 ('wa-kutubihi', 'and His books'), ('wa-rusulihi', 'and His messengers'), ('wal-yawmi', 'and the Day'),
                 ('al-aakhir', 'the Last')),
         cites=['Muslim 8 (the hadith of Jibril)']),
    dict(id='aqid.iman.2', book='muslim', key='8.01', cut=(281, 285), num='8',
         tr="Wa tu'mina bil-qadari khayrihi wa sharrih", en='and to believe in the decree (qadar), its good and its bad.',
         words=W(("wa-tu'mina", 'and you believe'), ('bil-qadar', 'in the decree'), ('khayrihi', 'its good'),
                 ('wa-sharrihi', 'and its bad')),
         cites=['Muslim 8 (the hadith of Jibril)']),
    dict(id='aqid.ihsan.1', book='muslim', key='8.01', cut=(297, 302), num='8',
         tr="An ta'buda Allaaha ka-annaka taraahu", en='Ihsan is to worship Allah as if you see Him,',
         words=W(('an', 'that'), ("ta'buda", 'you worship'), ('Allaaha', 'Allah'), ('ka-annaka', 'as if you'),
                 ('taraahu', 'see Him')),
         cites=['Muslim 8 (the hadith of Jibril)', 'Bukhari 50 (the same teaching in another wording)']),
    dict(id='aqid.ihsan.2', book='muslim', key='8.01', cut=(302, 308), num='8',
         tr='Fa-in lam takun taraahu fa-innahu yaraak', en='and if you do not see Him, then He sees you.',
         words=W(('fa-in', 'and if'), ('lam', 'not'), ('takun', 'you are'), ('taraahu', 'seeing Him'),
                 ('fa-innahu', 'then indeed He'), ('yaraak', 'sees you')),
         cites=['Muslim 8 (the hadith of Jibril)', 'Bukhari 50 (the same teaching in another wording)']),
    dict(id='aqid.zulm.1', book='muslim', key='2577.01', cut=(49, 56), num='2577',
         tr="Yaa 'ibaadee innee harramtuz-zulma 'alaa nafsee",
         en='O My servants, I have forbidden injustice for Myself,',
         words=W(('yaa', 'O'), ("'ibaadee", 'My servants'), ('innee', 'indeed I'), ('harramtu', 'have forbidden'),
                 ('az-zulma', 'injustice'), ("'alaa", 'upon'), ('nafsee', 'Myself')),
         cites=['Muslim 2577']),
    dict(id='aqid.zulm.2', book='muslim', key='2577.01', cut=(56, 61), num='2577',
         tr='Wa ja\'altuhu baynakum muharraman fa-laa tazaalamoo', en='and I have made it forbidden between you, so do not wrong one another.',
         words=W(("wa-ja'altuhu", 'and I have made it'), ('baynakum', 'between you'), ('muharraman', 'forbidden'),
                 ('fa-laa', 'so do not'), ('tazaalamoo', 'wrong one another')),
         cites=['Muslim 2577']),
    # ------------------------------------------------------------ Dawah
    dict(id='daw.convey', book='bukhari', key='3461', cut=(29, 33), num='3461',
         tr="Ballighoo 'annee wa law aayah", en='Convey from me, even if it is one verse.',
         words=W(('ballighoo', 'convey'), ("'annee", 'from me'), ('wa-law', 'even if'), ('aayah', 'one verse')),
         cites=['Bukhari 3461']),
    dict(id='daw.ease.1', book='bukhari', key='69', cut=(27, 30), num='69',
         tr="Yassiroo wa laa tu'assiroo", en='Make things easy, and do not make them hard.',
         words=W(('yassiroo', 'make it easy'), ('wa-laa', 'and do not'), ("tu'assiroo", 'make it hard')),
         cites=['Bukhari 69']),
    dict(id='daw.ease.2', book='bukhari', key='69', cut=(30, 33), num='69',
         tr='Wa bashshiroo wa laa tunaffiroo', en='Give good news, and do not drive people away.',
         words=W(('wa-bashshiroo', 'and give good news'), ('wa-laa', 'and do not'), ('tunaffiroo', 'drive people away')),
         cites=['Bukhari 69']),
    dict(id='daw.gentle.1', book='muslim', key='2594.01', cut=(38, 46), num='2594',
         tr="Innar-rifqa laa yakoonu fee shay'in illaa zaanahu", en='Gentleness is not found in anything but it beautifies it,',
         words=W(('inna', 'indeed'), ('ar-rifqa', 'gentleness'), ('laa', 'not'), ('yakoonu', 'is'), ('fee', 'in'),
                 ("shay'in", 'anything'), ('illaa', 'except'), ('zaanahu', 'it beautified it')),
         cites=['Muslim 2594']),
    dict(id='daw.gentle.2', book='muslim', key='2594.01', cut=(46, 52), num='2594',
         tr="Wa laa yun-za'u min shay'in illaa shaanahu", en='and it is not taken away from anything but it spoils it.',
         words=W(('wa-laa', 'and not'), ("yunza'u", 'is taken away'), ('min', 'from'), ("shay'in", 'anything'),
                 ('illaa', 'except'), ('shaanahu', 'it spoiled it')),
         cites=['Muslim 2594']),
    dict(id='daw.nasiha', book='muslim', key='55.01', cut=(55, 57), num='55',
         tr='Ad-deenun-naseehah', en='The religion is sincere care (naseehah).',
         words=W(('ad-deenu', 'the religion'), ('an-naseehah', 'sincere care')),
         cites=['Muslim 55']),
    dict(id='daw.believer.1', book='muslim', key='2999', cut=(39, 46), num='2999',
         tr="'Ajaban li-amril-mu'mini inna amrahu kullahu khayr",
         en='How wonderful is the affair of the believer: all of his affair is good.',
         words=W(("'ajaban", 'how wonderful'), ('li-amri', 'is the affair of'), ("al-mu'mini", 'the believer'),
                 ('inna', 'indeed'), ('amrahu', 'his affair'), ('kullahu', 'all of it'), ('khayr', 'good')),
         cites=['Muslim 2999']),
    dict(id='daw.believer.2', book='muslim', key='2999', cut=(51, 58), num='2999',
         tr="In asaabat-hu sarraa'u shakara fa-kaana khayran lahu",
         en='If good times reach him he is thankful, and that is good for him.',
         words=W(('in', 'if'), ('asaabat-hu', 'reaches him'), ("sarraa'u", 'good times'), ('shakara', 'he is thankful'),
                 ('fa-kaana', 'and it is'), ('khayran', 'good'), ('lahu', 'for him')),
         cites=['Muslim 2999']),
    dict(id='daw.believer.3', book='muslim', key='2999', cut=(58, 65), num='2999',
         tr="Wa in asaabat-hu darraa'u sabara fa-kaana khayran lahu",
         en='And if hardship reaches him he is patient, and that is good for him.',
         words=W(('wa-in', 'and if'), ('asaabat-hu', 'reaches him'), ("darraa'u", 'hardship'), ('sabara', 'he is patient'),
                 ('fa-kaana', 'and it is'), ('khayran', 'good'), ('lahu', 'for him')),
         cites=['Muslim 2999']),
    dict(id='daw.dua.daws', book='bukhari', key='2937', cut=(48, 53), num='2937',
         tr="Allaahumma ihdi Dawsan wa'-ti bihim", en='O Allah, guide Daws and bring them.',
         words=W(('Allaahumma', 'O Allah'), ('ihdi', 'guide'), ('Dawsan', 'Daws (a tribe)'), ("wa'-ti", 'and bring'),
                 ('bihim', 'them')),
         cites=['Bukhari 2937', 'Muslim 2524 (the same prayer in another wording)']),
    # ------------------------------------------------------------ Understanding
    dict(id='und.best', book='bukhari', key='5027', cut=(36, 41), num='5027',
         tr="Khayrukum man ta'allamal-Qur'aana wa 'allamahu", en='The best of you is the one who learns the Qur\'an and teaches it.',
         words=W(('khayrukum', 'the best of you'), ('man', 'is the one who'), ("ta'allama", 'learns'),
                 ("al-Qur'aana", 'the Qur\'an'), ("wa-'allamahu", 'and teaches it')),
         cites=['Bukhari 5027']),
    dict(id='und.beautify', book='abudawud', key='1468', cut=(30, 33), num='1468',
         tr="Zayyinul-Qur'aana bi-aswaatikum", en='Beautify the Qur\'an with your voices.',
         words=W(('zayyinoo', 'beautify'), ("al-Qur'aana", 'the Qur\'an'), ('bi-aswaatikum', 'with your voices')),
         cites=['Abu Dawud 1468 (graded sahih by al-Albani)']),
    dict(id='und.consistent', book='bukhari', key='6464', cut=(40, 47), num='6464',
         tr="Ahabbal-a'maali adwamuhaa ilal-laahi wa in qall",
         en='The deeds most beloved to Allah are the most constant, even if small.',
         words=W(('ahabba', 'most beloved'), ("al-a'maali", 'of deeds'), ('adwamuhaa', 'the most constant of them'),
                 ('ilaa', 'to'), ('Allaahi', 'Allah'), ('wa-in', 'even if'), ('qalla', 'it is little')),
         cites=['Bukhari 6464']),
    dict(id='und.proof', book='muslim', key='223', cut=(60, 65), num='223',
         tr="Wal-Qur'aanu hujjatun laka aw 'alayk", en='And the Qur\'an is a proof for you or against you.',
         words=W(("wal-Qur'aanu", 'and the Qur\'an'), ('hujjatun', 'a proof'), ('laka', 'for you'), ('aw', 'or'),
                 ("'alayka", 'against you')),
         cites=['Muslim 223']),
    dict(id='und.taawwudh', book='bukhari', key='3282', cut=(49, 53), num='3282',
         tr="A'oodhu billaahi minash-shaytaan", en='I seek refuge with Allah from the devil.',
         words=W(("a'oodhu", 'I seek refuge'), ('billaahi', 'with Allah'), ('mina', 'from'), ('ash-shaytaan', 'the devil')),
         cites=['Bukhari 3282'],
         note='The wording in the cited narration is shorter than the form usually said (which adds ar-rajeem, '
              'from the Qur\'an, 16:98). The lesson shows both.'),
]

COMPOSITES = [
    dict(id='aqid.names99', parts=['aqid.names99.1', 'aqid.names99.2'],
         tr="Inna lillaahi tis'atan wa tis'eena ismaa, mi'atan illaa waahidan. Man ahsaahaa dakhalal-jannah",
         en='Allah has ninety-nine names, one hundred less one. Whoever counts them [learns and keeps them] will enter Paradise.',
         cites=['Bukhari 2736', 'Muslim 2677 (the same teaching in another wording)']),
    dict(id='aqid.prophets', parts=['aqid.prophets.1', 'aqid.prophets.2'],
         tr="Wal-anbiyaa'u ikhwatun li-'allaat, ummahaatuhum shattaa, wa deenuhum waahid",
         en='The prophets are brothers from one father; their mothers are different, and their religion is one.',
         cites=['Bukhari 3443', 'Muslim 2365 (the same teaching in another wording)']),
    dict(id='aqid.iman', parts=['aqid.iman.1', 'aqid.iman.2'],
         tr="An tu'mina billaahi wa malaa'ikatihi wa kutubihi wa rusulihi wal-yawmil-aakhir, wa tu'mina bil-qadari khayrihi wa sharrih",
         en='Faith is to believe in Allah, His angels, His books, His messengers and the Last Day, and to believe in the decree (qadar), its good and its bad.',
         cites=['Muslim 8 (the hadith of Jibril)']),
    dict(id='aqid.ihsan', parts=['aqid.ihsan.1', 'aqid.ihsan.2'],
         tr="An ta'buda Allaaha ka-annaka taraahu, fa-in lam takun taraahu fa-innahu yaraak",
         en='Ihsan is to worship Allah as if you see Him, and if you do not see Him, then He sees you.',
         cites=['Muslim 8 (the hadith of Jibril)', 'Bukhari 50 (the same teaching in another wording)']),
    dict(id='aqid.zulm', parts=['aqid.zulm.1', 'aqid.zulm.2'],
         tr="Yaa 'ibaadee innee harramtuz-zulma 'alaa nafsee, wa ja'altuhu baynakum muharraman fa-laa tazaalamoo",
         en='O My servants, I have forbidden injustice for Myself, and I have made it forbidden between you, so do not wrong one another.',
         cites=['Muslim 2577']),
    dict(id='daw.ease', parts=['daw.ease.1', 'daw.ease.2'],
         tr="Yassiroo wa laa tu'assiroo, wa bashshiroo wa laa tunaffiroo",
         en='Make things easy, and do not make them hard. Give good news, and do not drive people away.',
         cites=['Bukhari 69']),
    dict(id='daw.gentle', parts=['daw.gentle.1', 'daw.gentle.2'],
         tr="Innar-rifqa laa yakoonu fee shay'in illaa zaanahu, wa laa yun-za'u min shay'in illaa shaanahu",
         en='Gentleness is not found in anything but it beautifies it, and it is not taken away from anything but it spoils it.',
         cites=['Muslim 2594']),
    dict(id='daw.believer', parts=['daw.believer.1', 'daw.believer.2', 'daw.believer.3'],
         tr="'Ajaban li-amril-mu'mini inna amrahu kullahu khayr. In asaabat-hu sarraa'u shakara fa-kaana khayran lahu. Wa in asaabat-hu darraa'u sabara fa-kaana khayran lahu",
         en='How wonderful is the affair of the believer: all of his affair is good. If good times reach him he is thankful, and that is good for him. If hardship reaches him he is patient, and that is good for him.',
         cites=['Muslim 2999']),
]

# What the learner is told about each cited Sunan hadith, as recorded in the corpus.
GRADES_EXPECTED = {('abudawud', '1468'): 'Al-Albani'}


def build():
    out = {}
    for sp in LEAVES:
        book = sp['book']
        s, e = sp['cut']
        ar = cut(book, sp['key'], s, e)
        if len(ar.split()) != len(sp['words']):
            raise SystemExit('%s: %d Arabic words but %d glosses' % (sp['id'], len(ar.split()), len(sp['words'])))
        grader = 'graded by al-Albani; ' if book == 'abudawud' else ''
        e_ = {
            'arabic': ar,
            'status': 'verified',
            'translit': sp['tr'],
            'meaning': sp['en'],
            'words': sp['words'],
            'sources': sp['cites'],
            'copiedFrom': '%s %s (%swords %d to %d of narration %s, fawazahmed0/hadith-api, ara-%s)' % (
                BOOK_NAME[book], sp['num'], grader, s + 1, e, sp['key'], book),
            'needsScholarReview': True,
            'reviewNote': ("Arabic is cut from the cited text. The transliteration, the English meaning and the word "
                           "glosses are the app author's own learning aids and have not been reviewed by a scholar."
                           + ((' ' + sp['note']) if sp.get('note') else '')),
        }
        out[sp['id']] = e_
    for c in COMPOSITES:
        out[c['id']] = {
            'parts': c['parts'],
            'status': 'verified',
            'translit': c['tr'],
            'meaning': c['en'],
            'sources': c['cites'],
            'needsScholarReview': True,
            'reviewNote': ("Arabic is cut from the cited text. The transliteration and the English meaning are the "
                           "app author's own learning aids and have not been reviewed by a scholar."),
        }
    doc = {
        'schema': 1,
        'note': ('Verified-phrase registry for the Aqeedah, Understanding the Qur\'an and Dawah Academy lessons. '
                 'A lesson never contains Arabic of its own: it names a phrase here, or an ayah of '
                 'assets/quran/quran.json as q:<surah>:<ayah>. `status: verified` means the Arabic was cut, '
                 'with its vowel marks, from the cited primary-source text on the date below; it does NOT mean a '
                 'scholar has reviewed it (see needsScholarReview). Rebuild or re-check with '
                 'tool/academy_phrases_aqid_und_daw.py.'),
        'checked': CHECKED,
        'corpus': 'github.com/fawazahmed0/hadith-api (branch 1, editions/ara-*.json); sunnah.com numbering; Muslim by Abd al-Baqi number',
        'phrases': out,
    }
    with open(OUT, 'w', encoding='utf8') as f:
        json.dump(doc, f, ensure_ascii=False, indent=1)
        f.write('\n')
    print('wrote', OUT, len(out), 'phrases')


def verify():
    doc = json.load(open(OUT, encoding='utf8'))['phrases']
    bad = 0
    for sp in LEAVES:
        e = doc.get(sp['id'])
        if e is None:
            print('MISSING', sp['id'])
            bad += 1
            continue
        s, en = sp['cut']
        if cut(sp['book'], sp['key'], s, en) != e.get('arabic'):
            print('MISMATCH', sp['id'])
            bad += 1
        if len(e['arabic'].split()) != len(e.get('words', [])):
            print('GLOSS COUNT', sp['id'])
            bad += 1
    for c in COMPOSITES:
        if doc.get(c['id'], {}).get('parts') != c['parts']:
            print('COMPOSITE', c['id'])
            bad += 1
    for (b, n), who in GRADES_EXPECTED.items():
        if not any(name == who for name, _ in grades(b, n)):
            print('GRADE GONE', b, n, who)
            bad += 1
    print('verify:', 'OK' if not bad else '%d problems' % bad)
    return 1 if bad else 0


if __name__ == '__main__':
    cmd = sys.argv[1] if len(sys.argv) > 1 else 'verify'
    if cmd == 'build':
        build()
    else:
        sys.exit(verify())
