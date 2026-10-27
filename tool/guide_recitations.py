#!/usr/bin/env python3
"""Builds / re-verifies the `recitations` of assets/guides/guides.json.

Nothing Arabic in a guide is typed by hand. For each recitation the Arabic is
copied, letter for letter with its vowel marks, from either

  * assets/quran/quran.json (a Qur'an reference such as 2:255), or
  * the text of the cited hadith in the hadith-api corpus
    (github.com/fawazahmed0/hadith-api, branch 1, editions/ara-*.json).

For a hadith, the SPEC below only holds the *unvowelled words to look for* (a
search key). The tool finds that run of words in the cited hadith and copies
the vowelled original; if the words are not found the recitation is written
as `status: unverified` with no Arabic at all.

The transliteration and the English meaning are the app author's own learning
aids (Qur'an meanings are the bundled Saheeh International text); every
recitation is therefore flagged `needsScholarReview`.

Usage (the corpus is read from $HADITH_CACHE, or downloaded from
raw.githubusercontent.com):

    python3 tool/guide_recitations.py build    # write the recitations into guides.json
    python3 tool/guide_recitations.py verify   # re-check guides.json against the sources
"""
import json
import os
import re
import sys
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GUIDES = os.path.join(ROOT, 'assets', 'guides', 'guides.json')
QURAN = os.path.join(ROOT, 'assets', 'quran', 'quran.json')
TRANSLIT = os.path.join(ROOT, 'assets', 'quran', 'transliteration.json')
PHRASES = os.path.join(ROOT, 'assets', 'academy', 'phrases', 'foundation.json')
CACHE = os.environ.get('HADITH_CACHE', '/tmp/academy_hadith_cache')
BASE = 'https://raw.githubusercontent.com/fawazahmed0/hadith-api/1/editions/'
CHECKED = '2026-10-27'

TASH = re.compile('[ؐ-ًؚ-ٰٟۖ-ۭـ]')
STRIP = '‏‎"\'“”‘’«»،,.;:؛؟?()[]{}‑–—-ـ'


def norm(s):
    s = TASH.sub('', s)
    s = re.sub('[إأآٱ]', 'ا', s).replace('ى', 'ي').replace('ة', 'ه')
    s = s.replace('ؤ', 'و').replace('ئ', 'ي')
    return re.sub(r'\s+', ' ', s).strip()


_c = {}


def corpus(lang, book):
    k = (lang, book)
    if k not in _c:
        os.makedirs(CACHE, exist_ok=True)
        p = os.path.join(CACHE, '%s-%s.json' % (lang, book))
        if not os.path.exists(p):
            with urllib.request.urlopen(BASE + '%s-%s.json' % (lang, book)) as r:
                open(p, 'wb').write(r.read())
        _c[k] = json.load(open(p, encoding='utf8'))['hadiths']
    return _c[k]


def hadith_arabic(book, num):
    """Arabic text of sunnah.com hadith `num`. Muslim numbers are Abd al-Baqi
    numbers: the English edition carries them, the Arabic edition shares its
    running index (`hadithnumber`)."""
    if book == 'muslim':
        want = str(num)
        idx = None
        for h in corpus('eng', 'muslim'):
            an = str(h.get('arabicnumber'))
            if an == want or an.startswith(want + '.'):
                idx = h['hadithnumber']
                break
        if idx is None:
            return None
        for h in corpus('ara', 'muslim'):
            if h['hadithnumber'] == idx:
                return h['text']
        return None
    for h in corpus('ara', book):
        if h['hadithnumber'] == int(num):
            return h['text']
    return None


def grades(book, num):
    for h in corpus('eng', book):
        if book == 'muslim':
            an = str(h.get('arabicnumber'))
            if an == str(num) or an.startswith(str(num) + '.'):
                return [(g['name'], g['grade']) for g in h.get('grades', [])]
        elif h['hadithnumber'] == int(num):
            return [(g['name'], g['grade']) for g in h.get('grades', [])]
    return []


def extract(text, expected):
    toks = [t.strip(STRIP + ' \t\r\n') for t in text.split()]
    toks = [t for t in toks if t and norm(t)]
    want = norm(expected).split(' ')
    n = len(want)
    for i in range(len(toks) - n + 1):
        if [norm(t) for t in toks[i:i + n]] == want:
            return ' '.join(toks[i:i + n])
    return None


def quran_ayat(ref):
    """'2:255' or '112:1-4' -> list of (ref, arabic, english)."""
    s, rest = ref.split(':')
    a, _, b = rest.partition('-')
    a = int(a)
    b = int(b) if b else a
    for sur in json.load(open(QURAN, encoding='utf8')):
        if sur['n'] == int(s):
            return [('%s:%d' % (s, v[0]), v[1], v[2]) for v in sur['v'] if a <= v[0] <= b]
    raise SystemExit('no such surah ' + s)


_tl = None


def quran_translit(ref):
    global _tl
    if _tl is None:
        _tl = json.load(open(TRANSLIT, encoding='utf8'))['map']
    return [_tl.get(r) for r, _, _ in quran_ayat(ref)]


BOOKS = {'bukhari': 'Bukhari', 'muslim': 'Muslim', 'abudawud': 'Abu Dawud', 'tirmidhi': 'Tirmidhi', 'nasai': "Nasa'i", 'ibnmajah': 'Ibn Majah'}


class H:
    """A recitation copied from a hadith."""

    def __init__(self, when, book, num, segs, tr, en, cites, note=None):
        self.when, self.book, self.num, self.segs = when, book, num, segs
        self.tr, self.en, self.cites, self.note = tr, en, cites, note


class Q:
    """A recitation that is one or more ayat of quran.json."""

    def __init__(self, when, ref, tr=None, en=None, cites=None):
        self.when, self.ref, self.tr, self.en, self.cites = when, ref, tr, en, cites


class P:
    """A phrase of the Academy foundation registry, reused as is."""

    def __init__(self, when, pid):
        self.when, self.pid = when, pid


class U:
    """A recitation whose wording could not be verified: no Arabic is shown."""

    def __init__(self, when, en, note):
        self.when, self.en, self.note = when, en, note


TALBIYAH = H('The talbiyah', 'bukhari', 1549, ['لبيك اللهم لبيك لبيك لا شريك لك لبيك إن الحمد والنعمة لك والملك لا شريك لك'],
    "Labbayka Allaahumma labbayk, labbayka laa shareeka laka labbayk, innal-hamda wan-ni'mata laka wal-mulk, laa shareeka lak.",
    'Here I am, O Allah, here I am. Here I am, You have no partner, here I am. Indeed all praise and blessing are Yours, and all sovereignty. You have no partner.', ['Bukhari 1549'])

TAWAF_DUA = Q('Between the Yemeni corner and the Black Stone', '2:201', tr="Rabbanaa aatinaa fid-dunyaa hasanatan wa fil-aakhirati hasanatan wa qinaa 'adhaaban-naar.", cites=["Qur\u2019an 2:201 (the Prophet said it between the two corners: Abu Dawud 1892, hasan per al-Albani)"])

SPEC = {
 'huda-ihram': [TALBIYAH],
 'huda-ihram-rites': [TALBIYAH],
 'huda-umrah': [TALBIYAH, TAWAF_DUA],
 'huda-hajj-overview': [TALBIYAH, TAWAF_DUA],
 'huda-prayer': [
  P('To begin the prayer', 'takbir'),
  Q('In every rak’ah, standing', '1:1-7', cites=["Qur'an 1:1-7 (Al-Fatihah); the Prophet said there is no prayer for the one who does not recite it (Bukhari 756)"]),
  P('After the Fatihah, said by the imam and the one praying behind', 'amin'),
  P('In ruku’ (bowing)', 'ruku.tasbih'),
  P('Rising from ruku’', 'rise'),
  P('In sujud (prostration)', 'sujud.tasbih'),
  P('Sitting between the two prostrations', 'between.rabbighfir'),
  P('In the sitting, the tashahhud', 'tashahhud'),
  P('After the tashahhud in the last sitting', 'salawat'),
  P('To end the prayer, turning right then left', 'salam'),
 ],
 'huda-wudu': [
  P('At the start of wudu', 'wudu.bismillah'),
  P('After finishing wudu', 'wudu.dua'),
 ],
 'huda-adhan': [
  H('The adhan, as taught to Abdullah ibn Zayd', 'abudawud', 499,
    ['الله أكبر الله أكبر الله أكبر الله أكبر أشهد أن لا إله إلا الله أشهد أن لا إله إلا الله أشهد أن محمدا رسول الله أشهد أن محمدا رسول الله حي على الصلاة حي على الصلاة حي على الفلاح حي على الفلاح الله أكبر الله أكبر لا إله إلا الله'],
    "Allaahu akbar, Allaahu akbar, Allaahu akbar, Allaahu akbar. Ash-hadu al-laa ilaaha illal-laah, ash-hadu al-laa ilaaha illal-laah. Ash-hadu anna Muhammadar-rasoolul-laah, ash-hadu anna Muhammadar-rasoolul-laah. Hayya 'alas-salaah, hayya 'alas-salaah. Hayya 'alal-falaah, hayya 'alal-falaah. Allaahu akbar, Allaahu akbar. Laa ilaaha illal-laah.",
    'Allah is the Greatest (four times). I bear witness that there is no god but Allah (twice). I bear witness that Muhammad is the Messenger of Allah (twice). Come to the prayer (twice). Come to success (twice). Allah is the Greatest (twice). There is no god but Allah.',
    ['Abu Dawud 499 (hasan sahih per al-Albani); the Prophet said of it: it is a true vision, if Allah wills']),
  H('The iqamah, called when the prayer is about to begin', 'abudawud', 499,
    ['الله أكبر الله أكبر أشهد أن لا إله إلا الله أشهد أن محمدا رسول الله حي على الصلاة حي على الفلاح قد قامت الصلاة قد قامت الصلاة الله أكبر الله أكبر لا إله إلا الله'],
    "Allaahu akbar, Allaahu akbar. Ash-hadu al-laa ilaaha illal-laah. Ash-hadu anna Muhammadar-rasoolul-laah. Hayya 'alas-salaah. Hayya 'alal-falaah. Qad qaamatis-salaah, qad qaamatis-salaah. Allaahu akbar, Allaahu akbar. Laa ilaaha illal-laah.",
    'Allah is the Greatest (twice). I bear witness that there is no god but Allah. I bear witness that Muhammad is the Messenger of Allah. Come to the prayer. Come to success. The prayer has been established (twice). Allah is the Greatest (twice). There is no god but Allah.',
    ['Abu Dawud 499 (hasan sahih per al-Albani)']),
  H('After hearing the adhan, send blessings and say', 'bukhari', 614,
    ['اللهم رب هذه الدعوة التامة والصلاة القائمة آت محمدا الوسيلة والفضيلة وابعثه مقاما محمودا الذي وعدته'],
    "Allaahumma Rabba haadhihid-da'watit-taammah, was-salaatil-qaa'imah, aati Muhammadanil-waseelata wal-fadeelah, wab'athhu maqaamam-mahmoodanil-ladhee wa'adtah.",
    'O Allah, Lord of this perfect call and of the prayer that is about to be established, give Muhammad the means of approach and the excellence, and raise him to the praised station that You have promised him.',
    ['Bukhari 614']),
 ],
 'huda-mosque': [
  H('Entering the mosque', 'muslim', 713, ['اللهم افتح لي أبواب رحمتك'],
    "Allaahum-maftah lee abwaaba rahmatik.", 'O Allah, open for me the doors of Your mercy.', ['Muslim 713']),
  H('Leaving the mosque', 'muslim', 713, ['اللهم إني أسألك من فضلك'],
    "Allaahumma innee as'aluka min fadlik.", 'O Allah, I ask You of Your bounty.', ['Muslim 713']),
 ],
 'huda-witr': [
  H('The qunut of witr, taught to al-Hasan ibn Ali', 'abudawud', 1425,
    ['اللهم اهدني فيمن هديت وعافني فيمن عافيت وتولني فيمن توليت وبارك لي فيما أعطيت وقني شر ما قضيت إنك تقضي ولا يقضى عليك وإنه لا يذل من واليت ولا يعز من عاديت تباركت ربنا وتعاليت'],
    "Allaahumma-hdinee feeman hadayt, wa 'aafinee feeman 'aafayt, wa tawallanee feeman tawallayt, wa baarik lee feemaa a'tayt, wa qinee sharra maa qadayt. Innaka taqdee wa laa yuqdaa 'alayk, wa innahu laa yadhillu man waalayt, wa laa ya'izzu man 'aadayt. Tabaarakta Rabbanaa wa ta'aalayt.",
    'O Allah, guide me among those You have guided; grant me well-being among those You have granted well-being; take me into Your charge among those You have taken into Your charge; bless me in what You have given; guard me from the evil of what You have decreed. You decree and none decrees over You. He whom You take as an ally is not humbled, and he whom You take as an enemy is not honored. Blessed are You, our Lord, and exalted.',
    ['Abu Dawud 1425 (sahih per al-Albani)']),
 ],
 'huda-janazah-prayer': [
  H('The dua for the deceased, after the third takbir', 'muslim', 963,
    ['اللهم اغفر له وارحمه وعافه واعف عنه وأكرم نزله ووسع مدخله واغسله بالماء والثلج والبرد ونقه من الخطايا كما نقيت الثوب الأبيض من الدنس وأبدله دارا خيرا من داره وأهلا خيرا من أهله وزوجا خيرا من زوجه وأدخله الجنة وأعذه من عذاب القبر أو من عذاب النار'],
    "Allaahum-maghfir lahu warhamhu wa 'aafihi wa'fu 'anhu, wa akrim nuzulahu wa wassi' mudkhalahu, waghsilhu bil-maa'i wath-thalji wal-barad, wa naqqihi minal-khataayaa kamaa naqqaytath-thawbal-abyada minad-danas, wa abdilhu daaran khayran min daarih, wa ahlan khayran min ahlih, wa zawjan khayran min zawjih, wa adkhilhul-jannah, wa a'idhhu min 'adhaabil-qabri aw min 'adhaabin-naar.",
    'O Allah, forgive him and have mercy on him, give him well-being and pardon him; honor his place of rest and make his entrance wide; wash him with water, snow and hail; cleanse him of sins as a white garment is cleansed of dirt; give him a home better than his home, a family better than his family and a spouse better than his spouse; admit him to Paradise and protect him from the punishment of the grave, or of the Fire.',
    ['Muslim 963 (Awf ibn Malik)'],
    note='For a woman or a group, the pronouns change (for example "laha", "lahum"); ask your imam.'),
 ],
 'huda-food': [
  H('If you forgot Bismillah at the start of the meal', 'abudawud', 3767, ['بسم الله أوله وآخره'],
    "Bismillaahi awwalahu wa aakhirah.", 'In the name of Allah at its beginning and at its end.', ['Abu Dawud 3767 (sahih per al-Albani)']),
  H('When the meal is finished', 'bukhari', 5458,
    ['الحمد لله كثيرا طيبا مباركا فيه غير مكفي ولا مودع ولا مستغنى عنه ربنا'],
    "Al-hamdu lillaahi katheeran tayyiban mubaarakan feeh, ghayra makfiyyin wa laa muwadda'in wa laa mustaghnan 'anhu, Rabbanaa.",
    'Praise be to Allah, abundant, good and blessed praise; not a farewell to it nor in disregard of it, nor can we do without it, our Lord.',
    ['Bukhari 5458']),
 ],
 'huda-sleep': [
  H('When lying down to sleep', 'bukhari', 6324, ['باسمك اللهم أموت وأحيا'],
    "Bismika Allaahumma amootu wa ahyaa.", 'With Your name, O Allah, I die and I live.', ['Bukhari 6324']),
  H('On waking', 'bukhari', 6324, ['الحمد لله الذي أحيانا بعد ما أماتنا وإليه النشور'],
    "Al-hamdu lillaahil-ladhee ahyaanaa ba'da maa amaatanaa wa ilayhin-nushoor.",
    'All praise is for Allah who gave us life after He made us die, and to Him is the resurrection.', ['Bukhari 6324']),
  Q('Ayat al-Kursi, before sleeping', '2:255', cites=['Qur’an 2:255; Bukhari 2311']),
  Q('Al-Ikhlas, blown into the hands and wiped over the body', '112:1-4', cites=['Qur’an 112; Bukhari 5017']),
  Q('Al-Falaq, in the same way', '113:1-5', cites=['Qur’an 113; Bukhari 5017']),
  Q('An-Nas, in the same way', '114:1-6', cites=['Qur’an 114; Bukhari 5017']),
 ],
 'huda-adhkar': [
  H('The evening dua (in the morning say “we have entered the morning”)', 'muslim', 2723,
    ['أمسينا وأمسى الملك لله والحمد لله لا إله إلا الله وحده لا شريك له'],
    "Amsaynaa wa amsal-mulku lillaah, wal-hamdu lillaah, laa ilaaha illal-laahu wahdahu laa shareeka lah.",
    'We have entered the evening and the whole kingdom of Allah has entered the evening; praise is for Allah. There is no god but Allah alone, with no partner.',
    ['Muslim 2723']),
  H('Sayyid al-istighfar', 'bukhari', 6306,
    ['اللهم أنت ربي لا إله إلا أنت خلقتني وأنا عبدك وأنا على عهدك ووعدك ما استطعت أعوذ بك من شر ما صنعت أبوء لك بنعمتك علي وأبوء لك بذنبي فاغفر لي فإنه لا يغفر الذنوب إلا أنت'],
    "Allaahumma anta Rabbee, laa ilaaha illaa anta, khalaqtanee wa anaa 'abduka, wa anaa 'alaa 'ahdika wa wa'dika mastata'tu, a'oodhu bika min sharri maa sana'tu, aboo'u laka bini'matika 'alayya, wa aboo'u laka bidhanbee faghfir lee, fa-innahu laa yaghfirudh-dhunooba illaa anta.",
    'O Allah, You are my Lord; there is no god but You. You created me and I am Your servant, and I keep Your covenant and promise as far as I am able. I seek refuge in You from the evil of what I have done. I acknowledge Your favor upon me and I acknowledge my sin, so forgive me, for none forgives sins except You.',
    ['Bukhari 6306']),
  H('Tasbih', 'bukhari', 6405, ['سبحان الله وبحمده'],
    "Subhaanal-laahi wa bihamdih.", 'Glory be to Allah and praise be to Him.', ['Bukhari 6405']),
 ],
 'huda-travel': [
  H('On setting out', 'muslim', 1342,
    ['سبحان الذي سخر لنا هذا وما كنا له مقرنين وإنا إلى ربنا لمنقلبون اللهم إنا نسألك في سفرنا هذا البر والتقوى ومن العمل ما ترضى اللهم هون علينا سفرنا هذا واطو عنا بعده اللهم أنت الصاحب في السفر والخليفة في الأهل اللهم إني أعوذ بك من وعثاء السفر وكآبة المنظر وسوء المنقلب في المال والأهل'],
    "Subhaanal-ladhee sakh-khara lanaa haadhaa wa maa kunnaa lahu muqrineen, wa innaa ilaa Rabbinaa lamunqaliboon. Allaahumma innaa nas'aluka fee safarinaa haadhal-birra wat-taqwaa, wa minal-'amali maa tardaa. Allaahumma hawwin 'alaynaa safaranaa haadhaa, watwi 'annaa bu'dah. Allaahumma antas-saahibu fis-safar, wal-khaleefatu fil-ahl. Allaahumma innee a'oodhu bika min wa'thaa'is-safar, wa ka'aabatil-manzar, wa soo'il-munqalabi fil-maali wal-ahl.",
    'Glory to Him who has subjected this to us, and we could not have subdued it, and to our Lord we shall return. O Allah, we ask You on this journey of ours for righteousness and piety, and for deeds that please You. O Allah, make this journey easy for us and fold up its distance for us. O Allah, You are the Companion on the journey and the Guardian of the family. O Allah, I seek refuge in You from the hardship of travel, from a gloomy sight, and from an evil return in property and family.',
    ['Muslim 1342']),
  H('On returning, say the same and add', 'muslim', 1342, ['آيبون تائبون عابدون لربنا حامدون'],
    "Aa'iboona taa'iboona 'aabidoona li-Rabbinaa haamidoon.", 'We return, repentant, worshipping, and praising our Lord.', ['Muslim 1342']),
 ],
 'huda-istikhara': [
  H('The istikhara dua, after the two rak’ahs; at the words “this matter”, name your need', 'bukhari', 6382,
    ['اللهم إني أستخيرك بعلمك وأستقدرك بقدرتك وأسألك من فضلك العظيم فإنك تقدر ولا أقدر وتعلم ولا أعلم وأنت علام الغيوب',
     'اللهم إن كنت تعلم أن هذا الأمر خير لي في ديني ومعاشي وعاقبة أمري',
     'فاقدره لي',
     'وإن كنت تعلم أن هذا الأمر شر لي في ديني ومعاشي وعاقبة أمري',
     'فاصرفه عني واصرفني عنه واقدر لي الخير حيث كان ثم رضني به'],
    "Allaahumma innee astakheeruka bi'ilmika, wa astaqdiruka biqudratika, wa as'aluka min fadlikal-'azeem, fa-innaka taqdiru wa laa aqdir, wa ta'lamu wa laa a'lam, wa anta 'allaamul-ghuyoob.\nAllaahumma in kunta ta'lamu anna haadhal-amra khayrun lee fee deenee wa ma'aashee wa 'aaqibati amree,\nfaqdurhu lee,\nwa in kunta ta'lamu anna haadhal-amra sharrun lee fee deenee wa ma'aashee wa 'aaqibati amree,\nfasrifhu 'annee wasrifnee 'anhu, waqdur liyal-khayra haythu kaana thumma raddinee bih.",
    'O Allah, I ask You to choose for me by Your knowledge, and I ask You for ability by Your power, and I ask You of Your great bounty; for You are able and I am not able, You know and I do not know, and You are the Knower of the unseen.\nO Allah, if You know that this matter is good for me in my religion, my livelihood and the end of my affair,\nthen decree it for me;\nand if You know that this matter is bad for me in my religion, my livelihood and the end of my affair,\nthen turn it away from me and turn me away from it, and decree for me the good wherever it may be, then make me content with it.',
    ['Bukhari 6382']),
 ],
 'huda-hardship': [
  H('The dua of distress', 'bukhari', 6346,
    ['لا إله إلا الله العظيم الحليم لا إله إلا الله رب العرش العظيم لا إله إلا الله رب السموات ورب الأرض ورب العرش الكريم'],
    "Laa ilaaha illal-laahul-'Azeemul-Haleem. Laa ilaaha illal-laahu Rabbul-'arshil-'azeem. Laa ilaaha illal-laahu Rabbus-samaawaati wa Rabbul-ardi wa Rabbul-'arshil-kareem.",
    'There is no god but Allah, the Mighty, the Forbearing. There is no god but Allah, Lord of the Mighty Throne. There is no god but Allah, Lord of the heavens, Lord of the earth and Lord of the Noble Throne.',
    ['Bukhari 6346']),
  H('The dua of Yunus', 'tirmidhi', 3505, ['لا إله إلا أنت سبحانك إني كنت من الظالمين'],
    "Laa ilaaha illaa anta, subhaanaka innee kuntu minaz-zaalimeen.",
    'There is no god but You; glory be to You. Indeed, I have been of the wrongdoers.', ['Tirmidhi 3505 (sahih per al-Albani)', "Qur’an 21:87"]),
  H('Seeking refuge from worry and debt', 'bukhari', 6369,
    ['اللهم إني أعوذ بك من الهم والحزن والعجز والكسل والجبن والبخل وضلع الدين وغلبة الرجال'],
    "Allaahumma innee a'oodhu bika minal-hammi wal-hazan, wal-'ajzi wal-kasal, wal-jubni wal-bukhl, wa dala'id-dayni wa ghalabatir-rijaal.",
    'O Allah, I seek refuge in You from worry and grief, from incapacity and laziness, from cowardice and miserliness, from being heavily in debt and from being overpowered by men.',
    ['Bukhari 6369']),
  H('For a debt', 'tirmidhi', 3563, ['اللهم اكفني بحلالك عن حرامك وأغنني بفضلك عمن سواك'],
    "Allaahum-makfinee bihalaalika 'an haraamik, wa aghninee bifadlika 'amman siwaak.",
    'O Allah, suffice me with what You have made lawful against what You have forbidden, and make me independent by Your favor of all others.', ['Tirmidhi 3563 (hasan per al-Albani)']),
 ],
 'huda-taraweeh': [
  H('The dua for Laylat al-Qadr', 'tirmidhi', 3513, ['اللهم إنك عفو كريم تحب العفو فاعف عني'],
    "Allaahumma innaka 'afuwwun kareemun tuhibbul-'afwa fa'fu 'annee.", 'O Allah, You are Pardoning and Generous, You love to pardon, so pardon me.',
    ["Tirmidhi 3513 (sahih per al-Albani; da'if per Zubair Ali Zai)"]),
 ],
 'huda-fasting': [
  H('When breaking the fast', 'abudawud', 2357, ['ذهب الظمأ وابتلت العروق وثبت الأجر إن شاء الله'],
    "Dhahaba az-zama'u wabtallatil-'urooqu wa thabatal-ajru in shaa'allaah.", 'The thirst has gone, the veins are moistened, and the reward is confirmed, if Allah wills.', ['Abu Dawud 2357 (hasan per al-Albani)']),
 ],
 'huda-greeting': [
  H('When you sneeze', 'bukhari', 6224, ['الحمد لله'], "Al-hamdu lillaah.", 'Praise be to Allah.', ['Bukhari 6224']),
  H('To the one who sneezed and praised Allah', 'bukhari', 6224, ['يرحمك الله'], "Yarhamukal-laah.", 'May Allah have mercy on you.', ['Bukhari 6224']),
  H('The sneezer replies', 'bukhari', 6224, ['يهديكم الله ويصلح بالكم'], "Yahdeekumul-laahu wa yuslihu baalakum.", 'May Allah guide you and set right your condition.', ['Bukhari 6224']),
  P('The greeting', 'salam'),
 ],
 'huda-illness': [
  H('Over a sick person', 'bukhari', 5675, ['أذهب البأس رب الناس اشف وأنت الشافي لا شفاء إلا شفاؤك شفاء لا يغادر سقما'],
    "Adh-hibil-ba'sa Rabban-naas, ishfi wa antash-shaafee, laa shifaa'a illaa shifaa'uk, shifaa'an laa yughaadiru saqamaa.",
    'Take away the harm, O Lord of the people. Heal, for You are the Healer. There is no healing except Your healing, a healing that leaves no illness.', ['Bukhari 5675']),
 ],
 'huda-parents': [
  Q('A dua for your parents', '17:24', tr="Wakhfid lahumaa janaahadh-dhulli minar-rahmati waqur-rabbir-hamhumaa kamaa rabbayaanee sagheeraa."
    ),
 ],
 'huda-condolence': [
  H('The dua taught by Umm Salamah\u2019s hadith, after a calamity', 'muslim', 918,
    ['\u0625\u0646\u0627 \u0644\u0644\u0647 \u0648\u0625\u0646\u0627 \u0625\u0644\u064a\u0647 \u0631\u0627\u062c\u0639\u0648\u0646 \u0627\u0644\u0644\u0647\u0645 \u0623\u062c\u0631\u0646\u064a \u0641\u064a \u0645\u0635\u064a\u0628\u062a\u064a \u0648\u0623\u062e\u0644\u0641 \u0644\u064a \u062e\u064a\u0631\u0627 \u0645\u0646\u0647\u0627'],
    "Innaa lillaahi wa innaa ilayhi raaji'oon. Allaahumma-jurnee fee museebatee wa akhlif lee khayran minhaa.",
    'We belong to Allah and to Him we return. O Allah, reward me in my calamity and replace it for me with something better.', ['Muslim 918']),
  Q('When a calamity strikes, or to a bereaved person', '2:156', tr="Innaa lillaahi wa innaa ilayhi raaji'oon.", cites=["Qur’an 2:156; Muslim 918 (the Prophet taught saying it with a dua)"]),
 ],
 'huda-tawaf': [TAWAF_DUA],
 'huda-janazah-burial': [
  H('When placing the deceased in the grave', 'abudawud', 3213, ['\u0628\u0633\u0645 \u0627\u0644\u0644\u0647 \u0648\u0639\u0644\u0649 \u0633\u0646\u0629 \u0631\u0633\u0648\u0644 \u0627\u0644\u0644\u0647'],
    "Bismillaahi wa 'alaa sunnati rasoolil-laah.", 'In the name of Allah and upon the way of the Messenger of Allah.', ['Abu Dawud 3213 (sahih per al-Albani)']),
 ],
 'huda-arafat': [
  H('The best dua of the day of Arafah', 'tirmidhi', 3585, ['\u0644\u0627 \u0625\u0644\u0647 \u0625\u0644\u0627 \u0627\u0644\u0644\u0647 \u0648\u062d\u062f\u0647 \u0644\u0627 \u0634\u0631\u064a\u0643 \u0644\u0647 \u0644\u0647 \u0627\u0644\u0645\u0644\u0643 \u0648\u0644\u0647 \u0627\u0644\u062d\u0645\u062f \u0648\u0647\u0648 \u0639\u0644\u0649 \u0643\u0644 \u0634\u064a\u0621 \u0642\u062f\u064a\u0631'],
    "Laa ilaaha illal-laahu wahdahu laa shareeka lah, lahul-mulku wa lahul-hamdu wa huwa 'alaa kulli shay'in qadeer.",
    'There is no god but Allah alone, with no partner. His is the dominion and His is the praise, and He has power over all things.',
    ["Tirmidhi 3585 (da'if per Zubair Ali Zai; hasan per al-Albani)"]),
 ],
 'huda-udhiyah': [
  H('At the sacrifice, as the Prophet said when he sacrificed', 'muslim', 1967,
    ['\u0628\u0627\u0633\u0645 \u0627\u0644\u0644\u0647 \u0627\u0644\u0644\u0647\u0645 \u062a\u0642\u0628\u0644 \u0645\u0646 \u0645\u062d\u0645\u062f \u0648\u0622\u0644 \u0645\u062d\u0645\u062f \u0648\u0645\u0646 \u0623\u0645\u0629 \u0645\u062d\u0645\u062f'],
    "Bismillaah, Allaahumma taqabbal min Muhammadin wa aali Muhammadin wa min ummati Muhammad.",
    'In the name of Allah. O Allah, accept this from Muhammad, the family of Muhammad and the community of Muhammad.', ['Muslim 1967'],
    note='This is what the Prophet said over his own sacrifice. He is also reported to have said Bismillah and Allahu akbar as he slaughtered (Bukhari 5558). Ask your imam how you should say it over your own animal.'),
 ],
 'huda-eid': [
  U('The takbir of Eid', 'The takbir is said in the days of Eid; the Prophet’s own words for it are not given here.',
    'The exact wording and its chain were not verified against a primary text in this audit, so no Arabic is shown. Ask your imam for the wording of your school.'),
  U('The Eid greeting (for example “Taqabbal Allahu minna wa minkum”)', 'A wish that Allah accept our worship and yours.',
    'No hadith number for this greeting was verified, so it is not presented as a text of the Sunnah and no Arabic is shown.'),
 ],
}


def phrase_registry():
    return json.load(open(PHRASES, encoding='utf8'))['phrases']


def arabic_of_phrase(reg, pid):
    e = reg[pid]
    if 'parts' in e:
        return ' '.join(arabic_of_phrase(reg, p) for p in e['parts'])
    return e['arabic']


def build_one(item, reg):
    r = {'when': item.when}
    if isinstance(item, P):
        e = reg[item.pid]
        r.update(kind='hadith', arabic=arabic_of_phrase(reg, item.pid), translit=e['translit'],
                 meaning=e['meaning'], sources=e['sources'], status='verified', phraseId=item.pid)
    elif isinstance(item, Q):
        ay = quran_ayat(item.ref)
        tl = item.tr
        if tl is None:
            parts = quran_translit(item.ref)
            tl = ' '.join(parts) if all(parts) else None
        if tl is None:
            raise SystemExit('no transliteration for ' + item.ref)
        r.update(kind='quran', arabic='\n'.join(a for _, a, _ in ay), translit=tl,
                 meaning=' '.join(e for _, _, e in ay), sources=item.cites or ["Qur’an " + item.ref],
                 status='verified', ref=item.ref)
    elif isinstance(item, H):
        text = hadith_arabic(item.book, item.num)
        outs = []
        for seg in item.segs:
            got = extract(text, seg) if text else None
            if got is None:
                outs = None
                break
            outs.append(got)
        if outs is None:
            r.update(kind='hadith', status='unverified', meaning=item.en, sources=item.cites,
                     note='The Arabic could not be matched in the cited text, so none is shown.')
            print('NOT FOUND', item.book, item.num, item.when, file=sys.stderr)
        else:
            r.update(kind='hadith', arabic='\n'.join(outs), translit=item.tr, meaning=item.en,
                     sources=item.cites, status='verified')
            if item.note:
                r['note'] = item.note
    elif isinstance(item, U):
        r.update(kind='hadith', status='unverified', meaning=item.en, note=item.note, sources=[])
    if r['status'] == 'verified':
        r['needsScholarReview'] = True
    return r


def build():
    reg = phrase_registry()
    guides = json.load(open(GUIDES, encoding='utf8'))
    byid = {g['id']: g for g in guides}
    for gid, items in SPEC.items():
        if gid not in byid:
            raise SystemExit('unknown guide ' + gid)
        byid[gid]['recitations'] = [build_one(i, reg) for i in items]
    for g in guides:
        if g['id'] not in SPEC:
            g.pop('recitations', None)
    with open(GUIDES, 'w', encoding='utf8') as f:
        json.dump(guides, f, ensure_ascii=False, indent=1)
        f.write('\n')
    n = sum(len(v) for v in SPEC.values())
    print('wrote', n, 'recitations into', len(SPEC), 'guides')


def verify():
    reg = phrase_registry()
    guides = json.load(open(GUIDES, encoding='utf8'))
    bad = 0
    for g in guides:
        items = SPEC.get(g['id'])
        have = g.get('recitations')
        if items is None:
            if have:
                print('UNEXPECTED recitations in', g['id']); bad += 1
            continue
        want = [build_one(i, reg) for i in items]
        if want != have:
            print('MISMATCH', g['id']); bad += 1
    print('verify:', 'OK' if not bad else '%d problems' % bad)
    return 1 if bad else 0


if __name__ == '__main__':
    cmd = sys.argv[1] if len(sys.argv) > 1 else 'verify'
    if cmd == 'build':
        build()
    else:
        sys.exit(verify())
