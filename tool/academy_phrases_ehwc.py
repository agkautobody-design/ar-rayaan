#!/usr/bin/env python3
"""Builds / re-verifies assets/academy/phrases/eol_hlth_wmns_char.json, the
verified phrases of the End of Life, Health & Ruqyah, Women in the Deen and
Character courses.

Same rules as tool/academy_phrases.py: the Arabic of a phrase is NOT typed by
hand. Each phrase names a hadith (book, number) and a range of its Arabic
words (token indices, as printed by `python3 tool/academy_phrases_ehwc.py show
<book> <number>`); the words, with their vowel marks, are copied out of the
primary-source text. Only the transliteration, the English meaning and the
word glosses are the author's own learning aids, flagged for scholar review.

The cited grade of a Sunan hadith is read from the corpus, never typed.

Source corpus: github.com/fawazahmed0/hadith-api (branch `1`, folder
`editions`), files ara-<book>.json / eng-<book>.json. Numbering is the
sunnah.com numbering, except Muslim, whose number is the Abd al-Baqi number
(`arabicnumber`; sub-narrations 963.02 ...).

    python3 tool/academy_phrases_ehwc.py build    # rewrite the registry
    python3 tool/academy_phrases_ehwc.py verify   # re-check against the corpus
    python3 tool/academy_phrases_ehwc.py show muslim 963.02   # indexed Arabic words
"""
import json
import os
import re
import sys
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'assets', 'academy', 'phrases', 'eol_hlth_wmns_char.json')
CACHE = os.environ.get('HADITH_CACHE', '/tmp/academy_hadith_cache')
BASE = 'https://raw.githubusercontent.com/fawazahmed0/hadith-api/1/editions/'
CHECKED = '2026-10-27'
STRIP = '‏‎"\'“”‘’«»،,.;:؛؟?()[]{}‑'

BOOKNAME = {'bukhari': 'Bukhari', 'muslim': 'Muslim', 'abudawud': 'Abu Dawud', 'tirmidhi': 'Tirmidhi',
            'nasai': "Nasa'i", 'ibnmajah': 'Ibn Majah'}
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
        _corp[k] = {(str(h.get('arabicnumber', h['hadithnumber'])) if book == 'muslim' else str(h['hadithnumber'])): h
                    for h in d}
    return _corp[k]


def hadith(lang, book, num):
    h = corpus(lang, book).get(str(num))
    if h is None and book == 'muslim':
        h = corpus(lang, book).get('%s.01' % num)
    if h is None:
        raise SystemExit('no such hadith %s %s' % (book, num))
    return h


def tokens(text):
    out = []
    for t in text.split():
        t = t.strip(STRIP + ' \t\r\n')
        if t:
            out.append(t)
    return out


def albani(book, num):
    for g in hadith('eng', book, num).get('grades', []):
        if g['name'] == 'Al-Albani':
            return g['grade']
    return None


def cite(book, num):
    """The citation text a learner sees; a Sunan hadith names its grader."""
    n = str(num).split('.')[0]
    if book in ('bukhari', 'muslim'):
        return '%s %s' % (BOOKNAME[book], n)
    g = albani(book, num)
    if g is None:
        raise SystemExit('no Al-Albani grade for %s %s' % (book, num))
    return '%s %s (%s per al-Albani)' % (BOOKNAME[book], n, g.lower().replace("daif", "da'if"))


def W(*pairs):
    return [{'tr': a, 'en': b} for a, b in pairs]


# id, hadith, token range (inclusive), the author's aids. `parts` makes a phrase
# that is the in-order concatenation of other phrases.
SPEC = []


def P(id, book, num, a, b, tr, en, words=None, also=()):
    SPEC.append(dict(id=id, book=book, num=num, tok=(a, b), tr=tr, en=en, words=words, also=list(also)))


def COMP(id, parts, tr, en, cites):
    SPEC.append(dict(id=id, parts=parts, tr=tr, en=en, cites=cites))


# ---- End of Life ----------------------------------------------------------
P('eol.kalima', 'muslim', '916.01', 46, 49, 'Laa ilaaha illal-laah', 'There is no god but Allah.',
  W(('laa', 'no'), ('ilaaha', 'god'), ('illaa', 'except'), ('Allaah', 'Allah')), also=[('abudawud', '3116')])
P('eol.rafiq', 'bukhari', '4437', 57, 60, "Allaahumma fir-rafeeqil-a'laa",
  'O Allah, let me be with the highest companions.',
  W(('Allaahumma', 'O Allah'), ('fee', 'in'), ('ar-rafeeqi', 'the company'), ("al-a'laa", 'the highest')), also=[('bukhari', '4463')])
P('eol.janazah.1', 'muslim', '963.02', 41, 47, "Allaahummagh-fir lahu warhamhu wa 'aafihi wa'-fu 'anhu",
  'O Allah, forgive him, have mercy on him, grant him safety and pardon him.',
  W(('Allaahumma', 'O Allah'), ('ighfir', 'forgive'), ('lahu', 'him'), ('wa-irhamhu', 'and have mercy on him'),
    ("wa-'aafihi", 'and grant him safety'), ("wa-'fu", 'and pardon'), ("'anhu", 'him')))
P('eol.janazah.2', 'muslim', '963.02', 48, 51, "Wa akrim nuzulahu wa wassi' mudkhalahu",
  'Honour his arrival and make his entrance wide.',
  W(('wa-akrim', 'and honour'), ('nuzulahu', 'his place of welcome'), ("wa-wassi'", 'and widen'), ('mudkhalahu', 'his entrance')))
P('eol.janazah.3', 'muslim', '963.02', 52, 55, "Waghsilhu bil-maa'i wath-thalji wal-barad",
  'Wash him with water, snow and hail.',
  W(('wa-ighsilhu', 'and wash him'), ("bil-maa'i", 'with water'), ('wath-thalji', 'and snow'), ('wal-barad', 'and hail')))
P('eol.janazah.4', 'muslim', '963.02', 56, 64, 'Wa naqqihi minal-khataayaa kamaa naqqaytath-thawbal-abyada minad-danas',
  'Cleanse him of his wrongs as a white garment is cleansed of dirt.',
  W(('wa-naqqihi', 'and cleanse him'), ('minal', 'of'), ('khataayaa', 'the wrongs'), ('kamaa', 'as'),
    ('naqqayta', 'You cleanse'), ('ath-thawba', 'the garment'), ('al-abyada', 'the white'), ('minad', 'of'), ('danas', 'dirt')))
P('eol.janazah.5', 'muslim', '963.02', 65, 77, 'Wa abdilhu daaran khayran min daarihi wa ahlan khayran min ahlihi wa zawjan khayran min zawjihi',
  'Give him in exchange a home better than his home, a family better than his family, and a spouse better than his spouse.')
P('eol.janazah.6', 'muslim', '963.02', 78, 87, "Wa adkhilhul-jannah wa a'idh-hu min 'adhaabil-qabri aw min 'adhaabin-naar",
  'Admit him to Paradise, and protect him from the punishment of the grave or of the Fire.')
COMP('eol.janazah.dua', ['eol.janazah.%d' % i for i in range(1, 7)],
     "Allaahummagh-fir lahu warhamhu wa 'aafihi wa'-fu 'anhu. Wa akrim nuzulahu wa wassi' mudkhalahu. Waghsilhu bil-maa'i wath-thalji wal-barad. Wa naqqihi minal-khataayaa kamaa naqqaytath-thawbal-abyada minad-danas. Wa abdilhu daaran khayran min daarihi wa ahlan khayran min ahlihi wa zawjan khayran min zawjihi. Wa adkhilhul-jannah wa a'idh-hu min 'adhaabil-qabri aw min 'adhaabin-naar.",
     'O Allah, forgive him, have mercy on him, grant him safety and pardon him. Honour his arrival and make his entrance wide. Wash him with water, snow and hail. Cleanse him of his wrongs as a white garment is cleansed of dirt. Give him in exchange a home better than his home, a family better than his family, and a spouse better than his spouse. Admit him to Paradise, and protect him from the punishment of the grave or of the Fire.',
     [('muslim', '963')])
P('eol.general.1', 'abudawud', '3201', 36, 45,
  "Allaahummagh-fir li-hayyinaa wa mayyitinaa wa saghirinaa wa kabirinaa wa dhakarinaa wa unthaanaa wa shaahidinaa wa ghaa'ibinaa",
  'O Allah, forgive our living and our dead, our young and our old, our men and our women, those present and those absent.',
  also=[('tirmidhi', '1024')])
P('eol.general.2', 'abudawud', '3201', 46, 58,
  "Allaahumma man ahyaytahu minnaa fa-ahyihi 'alal-eemaan wa man tawaffaytahu minnaa fa-tawaffahu 'alal-islaam",
  'O Allah, whoever of us You keep alive, keep him alive in faith; and whoever of us You take, take him in Islam.')
P('eol.general.3', 'abudawud', '3201', 59, 65, "Allaahumma laa tahrimnaa ajrahu wa laa tudillanaa ba'dah",
  'O Allah, do not deprive us of his reward, and do not let us go astray after him.')
COMP('eol.general', ['eol.general.1', 'eol.general.2', 'eol.general.3'],
     "Allaahummagh-fir li-hayyinaa wa mayyitinaa wa saghirinaa wa kabirinaa wa dhakarinaa wa unthaanaa wa shaahidinaa wa ghaa'ibinaa. Allaahumma man ahyaytahu minnaa fa-ahyihi 'alal-eemaan wa man tawaffaytahu minnaa fa-tawaffahu 'alal-islaam. Allaahumma laa tahrimnaa ajrahu wa laa tudillanaa ba'dah.",
     'O Allah, forgive our living and our dead, our young and our old, our men and our women, those present and those absent. O Allah, whoever of us You keep alive, keep him alive in faith; and whoever of us You take, take him in Islam. O Allah, do not deprive us of his reward, and do not let us go astray after him.',
     [('abudawud', '3201')])
P('eol.burial', 'abudawud', '3213', 32, 37, 'Bismil-laahi wa ala sunnati rasoolil-laah',
  'In the name of Allah, and on the way of the Messenger of Allah.',
  W(('bismi', 'in the name of'), ('Allaah', 'Allah'), ("wa-'alaa", 'and on'), ('sunnati', 'the way of'),
    ('rasooli', 'the messenger of'), ('Allaah', 'Allah')))
P('eol.grave.greeting', 'muslim', '975', 59, 75,
  "As-salaamu 'alaykum ahlad-diyaari minal-mu'mineena wal-muslimeen wa innaa in shaa'al-laahu lalaahiqoon as'alul-laaha lanaa wa lakumul-'aafiyah",
  'Peace be upon you, people of this place, among the believers and the Muslims. If Allah wills, we will join you. I ask Allah for well-being for us and for you.')
P('eol.grave.refuge', 'muslim', '588.01', 63, 81,
  "Allaahumma innee a'oodhu bika min 'adhaabi jahannam wa min 'adhaabil-qabr wa min fitnatil-mahyaa wal-mamaat wa min sharri fitnatil-maseehid-dajjaal",
  'O Allah, I seek refuge with You from the punishment of Hell, from the punishment of the grave, from the trial of life and death, and from the evil of the trial of the False Messiah (the Dajjal).',
  W(('Allaahumma', 'O Allah'), ('innee', 'indeed I'), ("a'oodhu", 'seek refuge'), ('bika', 'with You'), ('min', 'from'),
    ("'adhaabi", 'the punishment of'), ('jahannam', 'Hell'), ('wa-min', 'and from'), ("'adhaabi", 'the punishment of'),
    ('al-qabri', 'the grave'), ('wa-min', 'and from'), ('fitnati', 'the trial of'), ('al-mahyaa', 'life'),
    ('wal-mamaat', 'and death'), ('wa-min', 'and from'), ('sharri', 'the evil of'), ('fitnati', 'the trial of'),
    ('al-maseehi', 'the Messiah'), ('ad-dajjaal', 'the Impostor')), also=[('bukhari', '832')])
P('eol.grave.thabit', 'abudawud', '3221', 35, 42,
  "Istaghfiroo li-akheekum wa salu lahut-tathbeeta fa-innahu al-aana yus'al",
  'Ask forgiveness for your brother, and ask steadfastness for him, for he is being questioned now.',
  W(('istaghfiroo', 'ask forgiveness'), ('li-akheekum', 'for your brother'), ('wa-salu', 'and ask'), ('lahu', 'for him'),
    ('at-tathbeeta', 'steadfastness'), ('fa-innahu', 'for indeed he'), ('al-aana', 'now'), ("yus'al", 'is being questioned')))
P('eol.calamity.1', 'muslim', '918.02', 50, 54, "Innaa lillaahi wa innaa ilayhi raaji'oon",
  'We belong to Allah, and to Him we return.',
  W(('innaa', 'indeed we'), ('lillaahi', 'belong to Allah'), ('wa-innaa', 'and indeed we'), ('ilayhi', 'to Him'), ("raaji'oon", 'will return')))
P('eol.calamity.2', 'muslim', '918.02', 55, 62, "Allaahumma-jurnee fee museebatee wa akhlif lee khayran minhaa",
  'O Allah, reward me in my affliction and replace it for me with something better.')
COMP('eol.calamity', ['eol.calamity.1', 'eol.calamity.2'],
     "Innaa lillaahi wa innaa ilayhi raaji'oon. Allaahumma-jurnee fee museebatee wa akhlif lee khayran minhaa",
     'We belong to Allah, and to Him we return. O Allah, reward me in my affliction and replace it for me with something better.',
     [('muslim', '918')])
P('eol.condolence', 'bukhari', '1284', 42, 52, "Inna lillaahi maa akhadha wa lahu maa a'taa wa kullun 'indahu bi-ajalin musammaa",
  'What Allah took belongs to Him, and what He gave belongs to Him, and everything with Him has an appointed term.',
  W(('inna', 'indeed'), ('lillaahi', 'to Allah belongs'), ('maa', 'what'), ('akhadha', 'He took'), ('wa-lahu', 'and to Him'),
    ('maa', 'what'), ("a'taa", 'He gave'), ('wa-kullun', 'and everything'), ("'indahu", 'with Him'), ('bi-ajalin', 'has a term'),
    ('musammaa', 'appointed')))
P('eol.eyes.1', 'muslim', '920.01', 67, 79,
  "Allaahummagh-fir li-Abee Salamah warfa' darajatahu fil-mahdiyyeen wakhlufhu fee 'aqibihi fil-ghaabireen",
  'O Allah, forgive Abu Salama, raise his rank among the guided, and take care of those he left behind.')
P('eol.eyes.2', 'muslim', '920.01', 80, 92,
  "Waghfir lanaa wa lahu yaa Rabbal-'aalameen wafsah lahu fee qabrihi wa nawwir lahu feeh",
  'And forgive us and him, O Lord of the worlds; make his grave wide and give him light in it.')
COMP('eol.eyes', ['eol.eyes.1', 'eol.eyes.2'],
     "Allaahummagh-fir li-Abee Salamah warfa' darajatahu fil-mahdiyyeen wakhlufhu fee 'aqibihi fil-ghaabireen. Waghfir lanaa wa lahu yaa Rabbal-'aalameen wafsah lahu fee qabrihi wa nawwir lahu feeh",
     'O Allah, forgive Abu Salama, raise his rank among the guided, and take care of those he left behind. And forgive us and him, O Lord of the worlds; make his grave wide and give him light in it.',
     [('muslim', '920')])
# sleep (used in End of Life and in Health)
P('hlth.sleep.1', 'bukhari', '6320', 46, 51, "Bismika Rabbee wada'tu janbee wa bika arfa'uhu",
  'In Your name, my Lord, I lay down my side, and by You I raise it.',
  W(('bismika', 'in Your name'), ('Rabbee', 'my Lord'), ("wada'tu", 'I have laid down'), ('janbee', 'my side'),
    ('wa-bika', 'and by You'), ("arfa'uhu", 'I raise it')))
P('hlth.sleep.2', 'bukhari', '6320', 52, 63,
  "In amsakta nafsee farhamhaa wa in arsaltahaa fahfazhaa bimaa tahfazu bihi 'ibaadakas-saaliheen",
  'If You keep my soul, have mercy on it; and if You send it back, protect it as You protect Your righteous servants.')
COMP('hlth.sleep', ['hlth.sleep.1', 'hlth.sleep.2'],
     "Bismika Rabbee wada'tu janbee wa bika arfa'uhu. In amsakta nafsee farhamhaa wa in arsaltahaa fahfazhaa bimaa tahfazu bihi 'ibaadakas-saaliheen",
     'In Your name, my Lord, I lay down my side, and by You I raise it. If You keep my soul, have mercy on it; and if You send it back, protect it as You protect Your righteous servants.',
     [('bukhari', '6320')])
P('hlth.sleep.bismika', 'bukhari', '6312', 25, 27, 'Bismika amootu wa ahyaa', 'In Your name I die and I live.',
  W(('bismika', 'in Your name'), ('amootu', 'I die'), ('wa-ahyaa', 'and I live')))
P('hlth.sleep.wake', 'bukhari', '6312', 31, 39, "Alhamdu lillaahil-ladhee ahyaanaa ba'da maa amaatanaa wa ilayhin-nushoor",
  'Praise be to Allah who gave us life after He made us die, and to Him is the rising.',
  W(('al-hamdu', 'the praise'), ('lillaahi', 'is for Allah'), ('alladhee', 'who'), ('ahyaanaa', 'gave us life'),
    ("ba'da", 'after'), ('maa', 'that'), ('amaatanaa', 'He made us die'), ('wa-ilayhi', 'and to Him'), ('an-nushoor', 'is the rising')))

P('hlth.sleep.aslamtu', 'bukhari', '6311', 41, 67,
  "Allaahumma aslamtu wajhee ilayk wa fawwadtu amree ilayk wa alja'tu zahree ilayk raghbatan wa rahbatan ilayk laa malja'a wa laa manjaa minka illaa ilayk aamantu bikitaabikal-ladhee anzalt wa binabiyyikal-ladhee arsalt",
  'O Allah, I submit my face to You, I entrust my affair to You, and I rest my back on You, in hope and in fear of You. There is no refuge and no escape from You except to You. I believe in Your Book that You sent down and in Your Prophet whom You sent.')
P('hlth.eat.begin', 'abudawud', '3767', 62, 65, "Bismil-laahi awwalahu wa aakhirahu",
  'In the name of Allah at its beginning and at its end.',
  W(('bismi', 'in the name of'), ('Allaahi', 'Allah'), ('awwalahu', 'its beginning'), ('wa-aakhirahu', 'and its end')))
P('hlth.eat.end', 'bukhari', '5458', 25, 38,
  "Alhamdu lillaahi katheeran tayyiban mubaarakan feehi ghayra makfiyyin wa laa muwadda'in wa laa mustaghnan 'anhu Rabbanaa",
  'Praise be to Allah, much praise, good and blessed, which we can never repay enough, nor leave, nor do without, O our Lord.',
  W(('al-hamdu', 'the praise'), ('lillaahi', 'is for Allah'), ('katheeran', 'much'), ('tayyiban', 'good'),
    ('mubaarakan', 'blessed'), ('feehi', 'in it'), ('ghayra', 'not'), ('makfiyyin', 'sufficient'),
    ('wa-laa', 'and not'), ("muwadda'in", 'farewelled'), ('wa-laa', 'and not'), ('mustaghnan', 'done without'),
    ("'anhu", 'from it'), ('Rabbanaa', 'our Lord')))
P('hlth.ruqyah.pain', 'muslim', '2202', 64, 71, "A'oodhu billaahi wa qudratihi min sharri maa ajidu wa uhaadhir",
  'I seek refuge with Allah and with His power from the evil of what I feel and fear.',
  W(("a'oodhu", 'I seek refuge'), ('billaahi', 'with Allah'), ('wa-qudratihi', 'and with His power'), ('min', 'from'),
    ('sharri', 'the evil of'), ('maa', 'what'), ('ajidu', 'I find'), ('wa-uhaadhir', 'and I fear')))
P('hlth.shifa', 'bukhari', '5675', 36, 50, "Adh-hibil-ba's Rabban-naas ishfi wa antash-Shaafee laa shifaa'a illaa shifaa'uka shifaa'an laa yughaadiru saqamaa",
  'Take away the harm, Lord of the people. Heal, for You are the Healer. There is no cure but Your cure, a cure that leaves no illness behind.',
  W(('adh-hibi', 'take away'), ("al-ba's", 'the harm'), ('Rabba', 'Lord of'), ('an-naas', 'the people'), ('ishfi', 'heal'),
    ('wa-anta', 'and You are'), ('ash-Shaafee', 'the Healer'), ('laa', 'no'), ("shifaa'a", 'cure'), ('illaa', 'except'),
    ("shifaa'uka", 'Your cure'), ("shifaa'an", 'a cure'), ('laa', 'not'), ('yughaadiru', 'it leaves'), ('saqaman', 'illness')))
P('hlth.baas', 'bukhari', '3616', 46, 51, "Laa ba'sa tahoorun in shaa'al-laah",
  'No harm: it is a cleansing, if Allah wills.',
  W(('laa', 'no'), ("ba'sa", 'harm'), ('tahoorun', 'a cleansing'), ('in', 'if'), ('shaa\'a', 'wills'), ('Allaah', 'Allah')))
P('hlth.eye.refuge', 'bukhari', '3371', 41, 52, "A'oodhu bi-kalimaatil-laahit-taammati min kulli shaytaanin wa haammatin wa min kulli 'aynin laammah",
  'I seek refuge in the perfect words of Allah from every devil and every harmful creature, and from every evil eye.',
  W(("a'oodhu", 'I seek refuge'), ('bi-kalimaati', 'in the words of'), ('Allaahi', 'Allah'), ('at-taammati', 'the perfect'),
    ('min', 'from'), ('kulli', 'every'), ('shaytaanin', 'devil'), ('wa-haammatin', 'and harmful creature'),
    ('wa-min', 'and from'), ('kulli', 'every'), ("'aynin", 'eye'), ('laammah', 'evil')))
P('hlth.heart.dua', 'muslim', '2655', 70, 76, "Allaahumma musarrifal-quloobi sarrif quloobanaa 'alaa taa'atik",
  'O Allah, Turner of the hearts, turn our hearts to obey You.',
  W(('Allaahumma', 'O Allah'), ('musarrifa', 'Turner of'), ('al-quloobi', 'the hearts'), ('sarrif', 'turn'),
    ('quloobanaa', 'our hearts'), ("'alaa", 'to'), ("taa'atika", 'Your obedience')))
P('hlth.dhikr', 'bukhari', '6406', 32, 37, "Subhaanal-laahil-'azeem. Subhaanal-laahi wa bihamdih",
  'Glory be to Allah the Magnificent. Glory be to Allah and praise be to Him.',
  W(('subhaana', 'glory be to'), ('Allaahi', 'Allah'), ("al-'azeem", 'the Magnificent'), ('subhaana', 'glory be to'),
    ('Allaahi', 'Allah'), ('wa-bihamdihi', 'and with His praise')))


def spec_by_id():
    return {s['id']: s for s in SPEC}


def sources_for(sp):
    if 'parts' in sp:
        return [cite(b, n) for b, n in sp['cites']]
    out = [cite(sp['book'], sp['num'])]
    for b, n in sp['also']:
        out.append(cite(b, n))
    return out


def extract(sp):
    h = hadith('ara', sp['book'], sp['num'])
    t = tokens(h['text'])
    a, b = sp['tok']
    if b >= len(t):
        raise SystemExit('%s: token range outside the hadith' % sp['id'])
    return ' '.join(t[a:b + 1])


def build():
    out = {}
    for sp in SPEC:
        pid = sp['id']
        e = {}
        if 'parts' in sp:
            e['parts'] = sp['parts']
            e['status'] = 'verified'
        else:
            e['arabic'] = extract(sp)
            e['status'] = 'verified'
            if sp.get('words'):
                assert len(e['arabic'].split()) == len(sp['words']), (pid, len(e['arabic'].split()), len(sp['words']))
        e['translit'] = sp['tr']
        e['meaning'] = sp['en']
        if sp.get('words'):
            e['words'] = sp['words']
        e['sources'] = sources_for(sp)
        if 'parts' not in sp:
            grader = 'graded by al-Albani; ' if sp['book'] in ('abudawud', 'tirmidhi', 'nasai', 'ibnmajah') else ''
            e['copiedFrom'] = '%s %s (%sfawazahmed0/hadith-api, ara-%s)' % (
                BOOKNAME[sp['book']], sp['num'].split('.')[0] if sp['book'] != 'muslim' else sp['num'], grader, sp['book'])
        e['needsScholarReview'] = True
        e['reviewNote'] = ('Arabic is copied from the cited text. The transliteration, the English meaning'
                           + (' and the word glosses' if sp.get('words') else '')
                           + " are the app author's own learning aids and have not been reviewed by a scholar.")
        out[pid] = e
    doc = {
        'schema': 1,
        'note': ('Verified-phrase registry (End of Life, Health & Ruqyah, Women in the Deen, Character). A lesson '
                 'never contains Arabic of its own: it names a phrase here, or an ayah of assets/quran/quran.json '
                 'as q:<surah>:<ayah>. `status: verified` means the Arabic was copied, word for word with its vowel '
                 'marks, out of the cited primary-source text on the date below; it does NOT mean a scholar has '
                 'reviewed it (see needsScholarReview). Rebuild or re-check with tool/academy_phrases_ehwc.py.'),
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
            print('MISSING', sp['id'])
            bad += 1
            continue
        if 'parts' in sp:
            continue
        if extract(sp) != e.get('arabic'):
            print('MISMATCH', sp['id'])
            bad += 1
        if e.get('sources') != sources_for(sp):
            print('SOURCES CHANGED (grade?)', sp['id'])
            bad += 1
    print('verify:', 'OK' if not bad else '%d problems' % bad)
    return 1 if bad else 0


if __name__ == '__main__':
    cmd = sys.argv[1] if len(sys.argv) > 1 else 'verify'
    if cmd == 'build':
        build()
    elif cmd == 'show':
        t = tokens(hadith('ara', sys.argv[2], sys.argv[3])['text'])
        print(' '.join('%d:%s' % (i, w) for i, w in enumerate(t)))
    else:
        sys.exit(verify())
