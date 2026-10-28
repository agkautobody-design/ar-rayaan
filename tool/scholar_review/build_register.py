#!/usr/bin/env python3
"""Builds the scholar-review register from the repository.

Writes, from the repo root:
  tool/scholar_review/register.json           machine-readable register
  docs/SCHOLAR_REVIEW_REGISTER.md             human-readable register
  lib/features/sources/domain/scholar_review_summary.dart
                                              the area counts the app shows

  python3 tool/scholar_review/build_register.py          rebuild all three
  python3 tool/scholar_review/build_register.py --check  fail if any is stale

The register is MINED, not typed: every item that comes from a data file is
read from that file (a `needsScholarReview` flag, a `review` note on a lesson
step, a `madhhabNote`, a Hadi `reviewNote`, a layers `differences` question,
a row of docs/story_audit.md ...). Items that exist only in the audit and
fix reports are listed in manual_items.py with the report that raised them.

It never edits religious content. All items start with status "open"; a
status changes only when a named scholar signs off (see
lib/app/core/scholar_review.dart).
"""
from __future__ import annotations

import codecs
import glob
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)

from rg import (ARABIC, AREAS, AREA_TITLE, CLIN, FIQH, HADITH, LAWYER, MADHABS,  # noqa: E402
                NATIVE, OWNER, REVIEWER_TYPES, RIGHTS, WOMEN)

REGISTER_JSON = os.path.join(ROOT, 'tool', 'scholar_review', 'register.json')
REGISTER_MD = os.path.join(ROOT, 'docs', 'SCHOLAR_REVIEW_REGISTER.md')
SUMMARY_DART = os.path.join(ROOT, 'lib', 'features', 'sources', 'domain',
                            'scholar_review_summary.dart')


def rd(path):
    with open(os.path.join(ROOT, path), encoding='utf-8') as f:
        return f.read()


def rj(path):
    return json.loads(rd(path))


def clip(s, n=420):
    s = re.sub(r'\s+', ' ', str(s)).strip()
    return s if len(s) <= n else s[:n - 1].rstrip() + '\u2026'


def unesc(s):
    """Decode Dart string escapes (\\u2019, \\', \\n)."""
    s = re.sub(r'\\u\{([0-9a-fA-F]+)\}', lambda m: chr(int(m.group(1), 16)), s)
    s = re.sub(r'\\u([0-9a-fA-F]{4})', lambda m: chr(int(m.group(1), 16)), s)
    return s.replace("\\'", "'").replace('\\"', '"').replace('\\n', ' ').replace('\\\\', '\\')


class Register:
    def __init__(self):
        self.items = []
        self.by_id = {}

    def add(self, id, area, where_app, file, key, what, why, reviewer,
            source, priority='normal', also=(), subarea='', label_surface=''):
        assert area in AREA_TITLE, area
        assert reviewer in REVIEWER_TYPES, reviewer
        assert id not in self.by_id, 'duplicate id ' + id
        srcs = [source] if isinstance(source, str) else list(source)
        it = {
            'id': id,
            'area': area,
            'subarea': subarea,
            'where_in_app': where_app,
            'file': file,
            'key': key,
            'what_to_review': clip(what, 600),
            'why_flagged': clip(why, 900),
            'reviewer_type': reviewer,
            'also_reviewers': [r for r in also if r != reviewer],
            'madhabs': list(MADHABS) if (reviewer == FIQH or FIQH in also) else [],
            'priority': priority,
            'source_of_flag': srcs,
            'label_surface': label_surface,
            'status': 'open',
        }
        for r in it['also_reviewers']:
            assert r in REVIEWER_TYPES, r
        self.items.append(it)
        self.by_id[id] = it
        return it

    def enrich(self, id, why=None, source=None, priority=None, also=(), what=None):
        it = self.by_id[id]  # KeyError on a typo: that is the point
        if why:
            it['why_flagged'] = clip(it['why_flagged'] + ' | ' + why, 1100)
        if source:
            for s in ([source] if isinstance(source, str) else source):
                if s not in it['source_of_flag']:
                    it['source_of_flag'].append(s)
        if priority:
            it['priority'] = priority
        if what:
            it['what_to_review'] = clip(it['what_to_review'] + ' | ' + what, 800)
        for r in also:
            if r != it['reviewer_type'] and r not in it['also_reviewers']:
                it['also_reviewers'].append(r)
        if it['reviewer_type'] == FIQH or FIQH in it['also_reviewers']:
            it['madhabs'] = list(MADHABS)

    def find(self, pattern):
        rx = re.compile(pattern, re.I)
        return [i for i in self.items
                if rx.search(i['what_to_review'] + ' ' + i['why_flagged'] + ' ' + i['id'])]


R = Register()

# ---------------------------------------------------------------- helpers

COURSE_TITLE = {
    'the-path': 'The Path',
    'aqid': 'Aqeedah',
    'und': "Understanding the Qur'an",
    'daw': "Da'wah",
    'arabic-language': 'Arabic Language',
    'hifz': 'Hifz',
    'char': 'Character',
    'youth': 'Youth',
    'family': 'Family Life',
    'transactions': 'Halal Money (Transactions)',
    'eol': 'End of Life (will, estate, janazah)',
    'hlth': 'Health',
    'wmns': "Women's School",
}
COURSE_FILE = {
    'the-path': 'the-path.json', 'aqid': 'aqid.json', 'und': 'und.json',
    'daw': 'daw.json', 'arabic-language': 'arabic-language.json',
    'hifz': 'hifz.json', 'char': 'char.json', 'youth': 'youth.json',
    'family': 'family.json', 'transactions': 'transactions.json',
    'eol': 'eol.json', 'hlth': 'hlth.json', 'wmns': 'wmns.json',
}
COURSE_REVIEWERS = {
    'the-path': [HADITH, FIQH],
    'aqid': [HADITH],
    'und': [HADITH, ARABIC],
    'daw': [HADITH],
    'arabic-language': [ARABIC],
    'hifz': [ARABIC],
    'char': [HADITH],
    'youth': [HADITH],
    'family': [FIQH, WOMEN],
    'transactions': [FIQH],
    'eol': [FIQH],
    'hlth': [CLIN, HADITH],
    'wmns': [WOMEN, HADITH],
}

RX_FIQH = re.compile(r"madhab|madhhab|school|hanafi|maliki|shafi|hanbali|ruling|fiqh|wali\b|mahr|nisab|"
                     r"zakat|riba|kaffara|kaffarah|iddah|inherit|share|will\b|bequest|janazah|"
                     r"zihar|itikaf|i'tikaf|sa'i|qada|fidya|jumu|prayer in|mortgage|interest|"
                     r"hawl|gaze|divorce|nikah|guardian|witness", re.I)
RX_HADITH = re.compile(r"tafsir|ibn kathir|creed|ashari|maturidi|athari|attribute|istiwa|qadar|"
                       r"grade|graded|sahih|hasan|daif|weak|chain|isnad|seerah|ibn sa|ibn hisham|"
                       r"report|angel|jinn|unseen|prophet", re.I)
RX_ARABIC = re.compile(r"tajweed|arabic|root\b|letter|pronunc|transliterat|qira|harakat|noon|"
                       r"hafs|tarteel|rabb|prefix|grammar|verb|word order|vowel", re.I)
RX_CLIN = re.compile(r"doctor|clinician|medical|health|safety|crisis|counsel|anxiety|depress|"
                     r"ruqy|ruqya|therapy|diet|sleep|stress|mental|addiction|grief", re.I)
RX_WOMEN = re.compile(r"\bwomen\b|\bwoman\b|\bwife\b|\bmother\b|khadijah|sumayyah|nusaybah|"
                      r"umm |asma\b|safiyya|menstru|hijab|aisha|fatima|zaynab|maryam|asiya|"
                      r"bilqis|hagar|khawlah", re.I)


def reviewers_for(course, text, contrast=False):
    base = list(COURSE_REVIEWERS[course])
    found = []
    if contrast and FIQH not in found:
        found.append(FIQH)
    if RX_FIQH.search(text) and FIQH not in found:
        found.append(FIQH)
    if RX_ARABIC.search(text) and course in ('und', 'arabic-language', 'hifz') and ARABIC not in found:
        found.append(ARABIC)
    if RX_CLIN.search(text) and course in ('hlth', 'daw', 'aqid', 'und') and CLIN not in found:
        found.append(CLIN)
    if RX_WOMEN.search(text) and WOMEN not in found and course in ('wmns', 'family'):
        found.append(WOMEN)
    out = []
    # The course's own first reviewer leads unless this step is plainly a
    # madhab contrast.
    if contrast:
        out.append(FIQH)
    for r in base:
        if r not in out:
            out.append(r)
    for r in found:
        if r not in out:
            out.append(r)
    if course in ('aqid', 'daw', 'char', 'youth', 'und') and HADITH not in out:
        out.insert(0, HADITH)
    return out[0], out[1:]


# ============================================================ 1. LESSONS

def build_lessons():
    for course, fn in COURSE_FILE.items():
        data = rj('assets/academy/lessons_v3/' + fn)
        ctitle = COURSE_TITLE[course]
        larea = 'arabic-tajweed' if course in ('arabic-language', 'hifz') else 'academy-lessons'
        for L in data['lessons']:
            lid = L['id']
            steps = L['steps']
            nrev = sum(1 for s in steps if s.get('review'))
            ncon = sum(1 for s in steps if s['kind'] == 'contrast')
            nchk = sum(len(s.get('items', [])) for s in steps if s['kind'] == 'check')
            primary, also = reviewers_for(course, L['title'] + ' ' + L.get('intro', ''))
            R.add(
                id='lesson.%s' % lid, area=larea, subarea=course,
                where_app='Academy > %s > %s (lesson player)' % (ctitle, L['title']),
                file='assets/academy/lessons_v3/' + fn, key='lessons[id=%s]' % lid,
                what='The whole lesson "%s": %d steps (teaching text, say/howto, %d check items with explanations), '
                     '%d step(s) flagged by the author, %d madhab contrast step(s).' % (
                         L['title'], len(steps), nchk, nrev, ncon),
                why='Written for this app; no named scholar has reviewed it. Every lesson shows "Scholar review needed" '
                    'until a named reviewer and date are recorded.',
                reviewer=primary, also=also,
                source=['assets/academy/lessons_v3 (lesson text)', 'lesson_provenance.dart (no reviewer on record)'],
                priority='normal', label_surface='Lesson player header and Sources sheet')
            for s in steps:
                sid = s['id']
                review = s.get('review')
                contrast = s['kind'] == 'contrast'
                lab = s.get('label', '')
                interp = lab == '[Interpretive]'
                refl = lab == '[Reflection]'
                if not (review or contrast or interp or refl):
                    continue
                text = ' '.join([s.get('title', ''), review or '', s.get('note', '') or ''])
                primary, also = reviewers_for(course, text, contrast=contrast)
                if review:
                    why = review
                    pr = 'high'
                    srcs = ['assets/academy/lessons_v3 (step review flag)']
                elif contrast:
                    why = ('A madhab contrast step: each row states a school\'s position from the author\'s general '
                           'knowledge of the fiqh manuals, not from a quoted source.')
                    pr = 'high'
                    srcs = ['docs/academy/lesson_format_v3.md (every contrast step needs a scholar)']
                elif interp:
                    why = 'Labelled [Interpretive]: the app author\'s explanation of the sources, not a quoted text.'
                    pr = 'low'
                    srcs = ['assets/academy/lessons_v3 (step label [Interpretive])']
                else:
                    why = 'Labelled [Reflection]: the author\'s own reflection or application; confirm it does not overstate the teaching.'
                    pr = 'low'
                    srcs = ['assets/academy/lessons_v3 (step label [Reflection])']
                if review and contrast:
                    srcs.append('docs/academy/lesson_format_v3.md (every contrast step needs a scholar)')
                src = s.get('source')
                R.add(
                    id='lesson.%s.%s' % (lid, sid), area=larea, subarea=course,
                    where_app='Academy > %s > %s > step "%s" (%s)' % (ctitle, L['title'], s.get('title', sid), s['kind']),
                    file='assets/academy/lessons_v3/' + fn, key='lessons[%s].steps[%s]' % (lid, sid),
                    what='Step "%s" (%s%s)%s' % (s.get('title', sid), s['kind'], ', ' + lab if lab else '',
                                                 '; source line: ' + src if src else ''),
                    why=why, reviewer=primary, also=also, source=srcs, priority=pr,
                    label_surface='Lesson player step')


# ============================================================ 2. PHRASES

PHRASE_FILES = ['foundation', 'aqid-und-daw', 'arabic_hfz', 'eol_hlth_wmns_char', 'fam-yth-trx']


def build_phrases():
    for name in PHRASE_FILES:
        path = 'assets/academy/phrases/%s.json' % name
        d = rj(path)
        for pid, p in d['phrases'].items():
            if not p.get('needsScholarReview'):
                continue
            R.add(
                id='phrase.%s.%s' % (name, pid), area='academy-phrases', subarea=name,
                where_app='Academy lessons: Say / Listen steps that use phrase "%s"' % pid,
                file=path, key='phrases.%s' % pid,
                what='Transliteration "%s", meaning "%s", %d word glosses, and that the Arabic is exactly the cited '
                     'narration (sources: %s).' % (clip(p.get('translit', ''), 120), clip(p.get('meaning', ''), 160),
                                                    len(p.get('words', [])), clip('; '.join(p.get('sources', [])), 200)),
                why=p.get('reviewNote') or 'needsScholarReview=true: transliteration, meaning and glosses are the author\'s own.',
                reviewer=ARABIC, also=[HADITH],
                source=['phrases json: needsScholarReview=true', 'S2 / PHASE1 reports (all phrases need review)'],
                priority='high', label_surface='Lesson player (lesson-level label)')


# ============================================================ 3. GLOSSES

def build_glosses():
    d = rj('assets/academy/word_glosses.json')
    for i, g in enumerate(d['glosses']):
        ref = ':'.join(g['key'].split(':')[:2])
        R.add(
            id='gloss.%03d' % (i + 1), area='academy-glosses',
            where_app='Academy word pages and lesson word-by-word glosses',
            file='assets/academy/word_glosses.json', key='glosses[%d] %s' % (i, g['key']),
            what='English gloss "%s" for the word at Qur\'an %s' % (clip(g['gloss'], 120), ref),
            why='needsScholarReview=true: glosses are written for this app and checked only against the verse '
                'they first appear in; no root is given; no Arabic scholar has reviewed them.',
            reviewer=ARABIC, also=[HADITH],
            source=['word_glosses.json: needsScholarReview=true', 'S2_gaps report (300 glosses)'],
            priority='normal', label_surface='Word deck and lesson word glosses')


# ============================================================ 4. SCHOOLS (static screens + legacy lessons)

SCHOOL_SCREENS = [
    # (file, id, display name, reviewers)
    ('aqeedah_school_screen.dart', 'aqeedah', 'Aqeedah school', [HADITH]),
    ('arabic_language_school_screen.dart', 'arabic-language', 'Arabic Language school', [ARABIC]),
    ('character_school_screen.dart', 'character', 'Character school', [HADITH]),
    ('dawah_school_screen.dart', 'dawah', "Da'wah school", [HADITH]),
    ('dua_school_screen.dart', 'dua', 'Dua school', [HADITH, ARABIC]),
    ('end_of_life_school_screen.dart', 'end-of-life', 'End of Life school (will, estate, janazah)', [FIQH]),
    ('family_school_screen.dart', 'family-life', 'Family Life school', [FIQH, WOMEN]),
    ('hadith_school_screen.dart', 'hadith-school', 'Hadith school (40 lessons)', [HADITH]),
    ('health_school_screen.dart', 'health', 'Health school', [CLIN, HADITH]),
    ('history_school_screen.dart', 'history', 'History school', [HADITH]),
    ('seerah_school_screen.dart', 'seerah', 'Seerah school', [HADITH]),
    ('stories_school_screen.dart', 'stories-school', 'Stories school', [HADITH]),
    ('transactions_school_screen.dart', 'transactions', 'Halal Money school', [FIQH]),
    ('understanding_school_screen.dart', 'understanding', "Understanding the Qur'an school", [HADITH, ARABIC]),
    ('womens_school_screen.dart', 'womens', "Women's school", [WOMEN, HADITH]),
    ('youth_school_screen.dart', 'youth', 'Youth school', [HADITH]),
    ('tajweed_cards_screen.dart', 'tajweed-cards', 'Tajweed cards', [ARABIC]),
    ('hisn_al_muslim_screen.dart', 'hisn', 'Hisn al-Muslim (dua gates)', [HADITH]),
    ('hajj_umrah_pack_screen.dart', 'hajj-umrah', 'Hajj and Umrah pack', [FIQH]),
    ('ramadan_mode_screen.dart', 'ramadan-mode', 'Ramadan mode', [FIQH]),
]

TITLE_RX = re.compile(r"""title:\s*(?:'((?:[^'\\]|\\.)*)'|"((?:[^"\\]|\\.)*)")""")


def build_school_screens():
    for fn, sid, name, rts in SCHOOL_SCREENS:
        path = 'lib/features/academy/presentation/' + fn
        t = rd(path)
        cut = re.search(r'\nclass \w+Screen\b', t)
        head = t[:cut.start()] if cut else t
        titles = [unesc(a or b) for a, b in TITLE_RX.findall(head)]
        area = 'arabic-tajweed' if sid in ('tajweed-cards', 'arabic-language') else (
            'dua-dhikr' if sid in ('dua', 'hisn') else 'academy-schools')
        route = {'aqeedah': '/academy/aqeedah', 'arabic-language': '/academy/arabic-language',
                 'character': '/academy/character', 'dawah': '/academy/dawah', 'dua': '/academy/dua',
                 'end-of-life': '/academy/end-of-life', 'family-life': '/academy/family-life',
                 'hadith-school': '/academy/hadith', 'health': '/academy/health',
                 'history': '/academy/history', 'seerah': '/academy/seerah',
                 'stories-school': '/academy/stories', 'transactions': '/academy/transactions',
                 'understanding': '/academy/understanding', 'womens': '/academy/womens',
                 'youth': '/academy/youth', 'tajweed-cards': '/academy/recitation',
                 'hisn': '/academy/hisn', 'hajj-umrah': '/academy/hajj-umrah-pack',
                 'ramadan-mode': '/academy/ramadan-mode'}.get(sid, '')
        primary, also = rts[0], rts[1:]
        R.add(
            id='school.%s' % sid, area=area, subarea='static-screen',
            where_app='%s screen (%s)' % (name, route),
            file=path, key='screen',
            what='The whole %s screen: %d lesson/section cards of religious teaching written as in-app text.' % (name, len(titles)),
            why='Static in-app teaching text written for this app; no named scholar has reviewed it. Some of these '
                'screens predate the v3 courses and still carry older wording (see story_audit and S2 reports).',
            reviewer=primary, also=also,
            source=['Screen source (no review on record)', 'docs/OWNER_ACTIONS.md item 4'],
            priority='normal', label_surface='%s header' % name)
        for n, ti in enumerate(titles, 1):
            R.add(
                id='school.%s.%02d' % (sid, n), area=area, subarea='static-screen',
                where_app='%s > "%s"' % (name, clip(ti, 80)),
                file=path, key='title: %s' % clip(ti, 80),
                what='Card or section "%s" in the %s.' % (clip(ti, 100), name),
                why='Static teaching text in a school screen; not reviewed by a named scholar.',
                reviewer=primary, also=also, source='Screen source (no review on record)',
                priority='normal', label_surface='%s header' % name)


def build_legacy_lessons():
    manifest = rd('lib/features/academy/domain/course_manifest.dart')
    ids = re.findall(r"AcademyLesson\(\s*id: '([a-z]+\.u\d+\.l\d+)'", manifest)
    v3 = set()
    for fn in COURSE_FILE.values():
        for L in rj('assets/academy/lessons_v3/' + fn)['lessons']:
            v3.add(L['id'])
    strings = rd('lib/features/academy/application/academy_strings.dart')
    for lid in ids:
        if lid in v3:
            continue
        m = re.search(r"'%s\.title':\s*'((?:[^'\\]|\\.)*)'" % re.escape(lid), strings)
        title = unesc(m.group(1)) if m else lid
        course = lid.split('.')[0]
        rts = {'path': [HADITH, FIQH], 'arabic': [ARABIC]}.get(course, [HADITH])
        R.add(
            id='lesson-v1.%s' % lid, area='academy-schools', subarea='legacy-manifest-lesson',
            where_app='Academy > lesson "%s" (v1 lesson player)' % title,
            file='lib/features/academy/domain/course_manifest.dart', key=lid,
            what='Legacy manifest lesson "%s" (text in academy_strings.dart keys %s.*).' % (title, lid),
            why='A v1 lesson that has no v3 replacement yet; authored text with no named reviewer.',
            reviewer=rts[0], also=rts[1:], source='course_manifest.dart + lesson_provenance.dart',
            priority='normal', label_surface='Lesson player header and Sources sheet')


# ============================================================ 5. HUDA GUIDES

GUIDE_REVIEWERS = {
    'huda-menstruation': (FIQH, [WOMEN]),
    'huda-baby': (FIQH, [WOMEN]),
    'huda-nikah': (FIQH, [WOMEN]),
    'huda-illness': (HADITH, [CLIN]),
    'huda-hardship': (HADITH, [CLIN]),
    'huda-tawba': (HADITH, []),
    'huda-what-is-islam': (HADITH, []),
    'huda-madhhab-overview': (FIQH, []),
    'huda-gratitude': (HADITH, []),
    'huda-speech': (HADITH, []),
    'huda-neighbors': (HADITH, []),
    'huda-parents': (HADITH, []),
    'huda-knowledge': (HADITH, []),
    'huda-sleep': (HADITH, []),
    'huda-food': (HADITH, []),
    'huda-greeting': (HADITH, [FIQH]),
    'huda-home': (HADITH, []),
    'huda-condolence': (HADITH, [FIQH]),
    'huda-adhkar': (HADITH, []),
    'huda-earning': (FIQH, []),
    'huda-children-deen': (HADITH, [FIQH]),
    'huda-death-prep': (FIQH, []),
    'huda-tahajjud': (FIQH, [HADITH]),
}


def build_guides():
    data = rj('assets/guides/guides.json')
    for g in data:
        gid = g['id']
        rev, also = GUIDE_REVIEWERS.get(gid, (FIQH, [HADITH]))
        if g['category'] == 'Hajj & Umrah':
            rev, also = FIQH, [HADITH]
        note = g.get('madhhabNote', '')
        extra = ''
        if gid in ('huda-tahajjud', 'huda-what-is-islam', 'huda-madhhab-overview'):
            extra = (' Its Sources card says "not yet scholar-reviewed"; docs/content_needed/VERIFICATION_LOG.md '
                     'records what was dropped because no source was read.')
        R.add(
            id='huda.guide.%s' % gid, area='huda', subarea=g['category'],
            where_app='Huda > %s > %s' % (g['category'], g['title']),
            file='assets/guides/guides.json', key='[id=%s]' % gid,
            what='Guide "%s": %d steps, %d sources, %s.' % (
                g['title'], len(g.get('steps', [])), len(g.get('sources', [])),
                'with a madhhab note' if note else 'no madhhab note'),
            why=('Every guide was line-audited against the Qur\'an text and the hadith corpus, but no named scholar has '
                 'reviewed the wording, the steps, or the school positions.' + extra),
            reviewer=rev, also=also,
            source=['FIX_WORSHIP_REPORT (guides audit, no scholar reviewed)', 'guides.json Sources card status'],
            priority='high' if note else 'normal', label_surface='Guide screen (Sources card)')
        if note:
            R.add(
                id='huda.madhhab.%s' % gid, area='huda', subarea='madhhabNote',
                where_app='Huda > %s > "Madhhab note" card' % g['title'],
                file='assets/guides/guides.json', key='[id=%s].madhhabNote' % gid,
                what='Madhhab note: ' + clip(note, 360),
                why='FIX_WORSHIP_REPORT: all madhab notes need a scholar (no named scholar reviewed them); '
                    'school positions are from standard fiqh teaching, not text-checked against the manuals.',
                reviewer=FIQH, also=[],
                source=['FIX_WORSHIP_REPORT (all madhab notes)', 'guides.json madhhabNote'],
                priority='high', label_surface='Guide screen (Madhhab note card)')


# ============================================================ 6. Q&A

def build_qa():
    d = rj('assets/qa/qa_bank.json')
    for i, q in enumerate(d['questions'], 1):
        txt = q['q'].lower()
        rev, also = FIQH, [HADITH]
        if 'waswas' in txt or 'angry' in txt or 'cry' in txt:
            rev, also = HADITH, [CLIN]
        if 'menstruation' in txt:
            rev, also = FIQH, [WOMEN]
        pr = 'high' if any(k in txt for k in ('music', 'mortgage', 'make up', 'breaks the fast', 'menstruation', 'tawbah')) else 'normal'
        why = 'Ruling or school-dependent answer; no named scholar has reviewed it.'
        if 'music' in txt:
            why = 'Music: scholars differ; the answer states the views without settling it. FIX_HADI_REPORT and FACT_S4 item 1.'
        elif 'mortgage' in txt:
            why = 'Mortgage: differing views; FACT_S4 item 1 asks a scholar to confirm the wording; Muslim 1598 interest hadith.'
        elif 'make up' in txt:
            why = 'Make-up prayers: views of the schools stated; FACT_S4 item 1; audit C flagged "in order after the current prayer" as doubtful.'
        elif 'breaks the fast' in txt:
            why = ('Vomiting (Abu Dawud 2380: graders differ, Darussalam daif, al-Albani sahih); fidya for pregnant and nursing '
                   'women differs by school. FACT_S4 item 1.')
        elif 'tawbah' in txt:
            why = ('The four-conditions-of-tawbah list is labelled a scholars\' summary and was NOT checked against '
                   'Riyad as-Salihin (FACT_S4 item 5).')
        elif 'sunnah and nafl' in txt:
            why = 'Terminology differs by school; FACT_S4 item 1.'
        R.add(
            id='qa.%02d' % i, area='qa', subarea='ruling',
            where_app='Academy > Q&A bank > "%s" (also shown by Hadi)' % q['q'],
            file='assets/qa/qa_bank.json', key='questions[%d]' % (i - 1),
            what='Answer to "%s" (source line: %s)' % (q['q'], clip(q.get('s', ''), 160)),
            why=why, reviewer=rev, also=also,
            source=['FACT_S4_modern_qa_feelings (Q&A scholar-review item 1)', 'qa_bank.json note: not reviewed by a named scholar'],
            priority=pr, label_surface='Q&A bank card; Hadi answer that quotes it')


# ============================================================ 7. HADI

HADI_FIX_REPORT_TOPICS = {
    'games-ruling': 'games ruling (nardashir/chess), dice and video games',
    'other-religions': 'other religions',
    'music': 'music',
    'dating-relationships': 'dating',
    'spouse-rights': 'spouse rights',
    'sunni-shia': 'Sunni/Shia wording',
    'china-knowledge': '"seek knowledge in China" saying',
    'knowledge-importance': 'knowledge as fard',
    'fast-medicine': 'fasting and medicine',
    'laylat-qadr': "Laylat al-Qadr du'a (Tirmidhi 3513, graders disagree)",
    'credit-card': 'credit-card positions',
    'madhhab-which': 'madhhab neutral wording',
    'mahr': 'mahr minimum',
    'iddah': 'iddah widow conduct',
    'mahdi': 'the Mahdi reports',
    'janazah-prayer': 'janazah prayer details by school',
    'janazah-care': 'janazah care, washing and burial rules',
}


def hadi_reviewer(cid, note, answer):
    t = (cid + ' ' + note).lower()
    rev, also = FIQH, [HADITH]
    if any(k in t for k in ('menstru', 'iddah', 'hijab', 'spouse', 'wife', 'nikah', 'divorce', 'mahr', 'polygamy', 'abused', 'hitting')):
        also = [WOMEN, HADITH]
    if any(k in cid for k in ('karbala', 'sunni-shia', 'four-caliphs', 'companions', 'badr', 'isra', 'prophet', 'mahdi',
                              'allah', 'angels', 'afterlife', 'tawheed', 'quran-what', 'hadith-what', 'quran-vs',
                              'kaaba', 'jihad', 'other-religions', 'surah', 'ibrahim', 'pillars-iman', 'become-muslim',
                              'bismillah', 'salam', 'china', 'knowledge', 'allah-loves', 'superstition')):
        rev, also = HADITH, [FIQH] if 'jihad' in cid or 'other-religions' in cid else []
    if any(k in cid for k in ('hadi-about', 'streaks', 'language-help', 'downloads', 'kids-help', 'school-setting',
                              'privacy-free', 'wasia-who', 'academy-help', 'games-general')):
        rev, also = HADITH, []
    if 'abused' in cid or 'hitting' in cid:
        also = [WOMEN, CLIN, HADITH]
    return rev, also


def build_hadi():
    s = rd('lib/features/hadi/data/hadi_core_data.dart')
    # entries: id, answer (first line), reviewNote
    blocks = re.split(r"\n  CoreEntry\(\n", s)
    for b in blocks[1:]:
        mid = re.search(r"id: '([^']+)'", b)
        if not mid:
            continue
        cid = mid.group(1)
        mans = re.search(r"answer:\s*\n?\s*'((?:[^'\\]|\\.)*)'", b)
        mnote = re.search(r"reviewNote:\s*\n?\s*'((?:[^'\\]|\\.)*)'", b)
        ans = unesc(mans.group(1)) if mans else ''
        note = unesc(mnote.group(1)) if mnote else ''
        rev, also = hadi_reviewer(cid, note, ans)
        srcs = ['hadi_core_data.dart reviewNote (kept for the review list)']
        if cid in HADI_FIX_REPORT_TOPICS:
            srcs.append('FIX_HADI_REPORT (scholar review needed: %s)' % HADI_FIX_REPORT_TOPICS[cid])
        R.add(
            id='hadi.core.%s' % cid, area='hadi', subarea='core-answer',
            where_app='Hadi chat > built-in answer "%s"' % cid,
            file='lib/features/hadi/data/hadi_core_data.dart (generated from tool/hadi_core/)', key="CoreEntry id='%s'" % cid,
            what='Built-in answer "%s": %s' % (cid, clip(ans, 260)),
            why=note or 'Built-in answer; no named scholar has reviewed it.',
            reviewer=rev, also=also, source=srcs,
            priority='high' if cid in HADI_FIX_REPORT_TOPICS else 'normal',
            label_surface='Hadi answer bubble (built-in library)')
    # old keyword shelf
    o = rd('lib/features/hadi/data/offline_hadi_provider.dart')
    k = 0
    for m in re.finditer(r"\n  _Entry\(\n\s+<String>\[\s*'((?:[^'\\]|\\.)*)'((?:[^\]]*))\]", o):
        k += 1
        first = unesc(m.group(1))
        kws = [unesc(x) for x in re.findall(r"'((?:[^'\\]|\\.)*)'", "'" + m.group(1) + "'" + m.group(2))][:4]
        R.add(
            id='hadi.shelf.%03d' % k, area='hadi', subarea='keyword-shelf',
            where_app='Hadi chat > older keyword-shelf answer for "%s"' % clip(first, 60),
            file='lib/features/hadi/data/offline_hadi_provider.dart', key='_knowledge[%d] keywords: %s' % (k - 1, clip('; '.join(kws), 120)),
            what='Shelf answer matched by keywords: %s' % clip('; '.join(kws), 200),
            why='FIX_HADI_REPORT: the old ~330-answer shelf was only spot-audited and school-specific fiqh summaries '
                'were not text-checked; no named scholar has reviewed it.',
            reviewer=FIQH if re.search(r'ruling|halal|haram|permissib|prayer|fast|zakat|hajj|wudu|nikah|divorce|inherit|riba|interest', ' '.join(kws), re.I) else HADITH,
            also=[HADITH], source=['FIX_HADI_REPORT (shelf only spot-audited)'], priority='normal',
            label_surface='Hadi answer bubble (built-in library)')


# ============================================================ 8. HADITH

NAWAWI_EXTRA = {
    12: ('Tirmidhi 2317: al-Albani sahih, Darussalam da\'if, An-Nawawi hasan. The app shows the disagreement, not a ruling.',
         'FIX_QURAN_HADITH_REPORT (Nawawi #12)'),
    41: ('Some later scholars question the chain; shown as a note, not a ruling.', 'FIX_QURAN_HADITH_REPORT (Nawawi #41)'),
    42: ('Tirmidhi calls it gharib; al-Albani sahih; An-Nawawi quoted; shown as a caveat.', 'FIX_QURAN_HADITH_REPORT (Nawawi #42)'),
}


def build_hadith():
    d = rj('assets/hadith/nawawi40.json')
    for h in d:
        n = h['n']
        extra = NAWAWI_EXTRA.get(n)
        why = 'Grade "%s" by %s; no named scholar has reviewed the English wording or the grade display.' % (h.get('grade'), h.get('grader'))
        srcs = ['assets/hadith/nawawi40.json']
        pr = 'normal'
        if h.get('gradeNote'):
            why += ' Grade note in the data: ' + h['gradeNote']
        if extra:
            why += ' ' + extra[0]
            srcs.append(extra[1])
            pr = 'high'
        R.add(
            id='hadith.nawawi.%02d' % n, area='hadith', subarea='nawawi-40',
            where_app='Hadith > The Forty (An-Nawawi) > hadith %d' % n,
            file='assets/hadith/nawawi40.json', key='[n=%d]' % n,
            what='Hadith %d: English wording, source line "%s" and grade "%s" (%s).' % (n, clip(h.get('src', ''), 80), h.get('grade'), h.get('grader')),
            why=why, reviewer=HADITH, also=[], source=srcs, priority=pr, label_surface='Hadith card')
    # daily hadith
    dh = rd('lib/features/hadith/domain/daily_hadith.dart')
    entries = re.findall(r"DailyHadith\(text: '((?:[^'\\]|\\.)*)',\s*narrator: '((?:[^'\\]|\\.)*)',\s*source: '((?:[^'\\]|\\.)*)'(?:,\s*grade: '([^']*)',\s*grader: '((?:[^'\\]|\\.)*)')?", dh)
    for i, (text, narr, src, grade, grader) in enumerate(entries, 1):
        R.add(
            id='hadith.daily.%02d' % i, area='hadith', subarea='daily-hadith',
            where_app='Home > Daily Hadith (rotation entry %d)' % i,
            file='lib/features/hadith/domain/daily_hadith.dart', key='DailyHadith #%d (%s)' % (i, clip(unesc(src), 50)),
            what='One-sentence hadith "%s" (%s), source %s%s.' % (clip(unesc(text), 140), unesc(narr), unesc(src),
                                                              (', %s per %s' % (grade, unesc(grader))) if grade else ''),
            why='FIX_QURAN_HADITH_REPORT: the rotation was rebuilt so every entry is sahih/hasan with a named grader; '
                'no named scholar has confirmed the one-sentence wording or the grades.',
            reviewer=HADITH, also=[], source=['FIX_QURAN_HADITH_REPORT (Daily Hadith rebuild)'], priority='normal',
            label_surface='Daily hadith card')
    # hadi corpus
    c = rj('assets/noor/hadi_corpus.json')
    for h in c['hadith']:
        bm = h['collection'] in ('Sahih al-Bukhari', 'Sahih Muslim')
        why = ('Hadi grounding corpus: %s. Summary or short excerpt written for this app; not reviewed by a named scholar.'
               % ('grade: %s (%s)' % (h['grade'], h['grader'][:80])))
        if not bm:
            why += ' Graded outside the two Sahihs: graders can differ (checked against the fawazahmed0 corpus).'
        R.add(
            id='hadith.corpus.%s' % h['id'].replace('h:', ''), area='hadith', subarea='hadi-corpus',
            where_app='Hadi answers that cite %s %s' % (h['collection'], h['number']),
            file='assets/noor/hadi_corpus.json', key='hadith[id=%s]' % h['id'],
            what='%s %s: "%s" (grade %s, %s).' % (h['collection'], h['number'], clip(h['english'], 150), h['grade'], clip(h['grader'], 60)),
            why=why, reviewer=HADITH, also=[], source=['assets/noor/hadi_corpus.json note: not yet reviewed by a named scholar'],
            priority='normal' if bm else 'high', label_surface='Hadi answer source card')
    for q in c['quran']:
        R.add(
            id='hadith.corpus-quran.%s' % q['ref'].replace(':', '-'), area='hadith', subarea='hadi-corpus',
            where_app='Hadi answers that print Qur\'an %s' % q['ref'],
            file='assets/noor/hadi_corpus.json', key='quran[ref=%s]' % q['ref'],
            what='Qur\'an %s is offered by Hadi for topics: %s (text is read from the bundled Qur\'an).' % (q['ref'], ', '.join(q['topics'][:8])),
            why='Which topics a verse is offered for is an app decision; no named scholar has reviewed the topic mapping.',
            reviewer=HADITH, also=[], source=['assets/noor/hadi_corpus.json'], priority='low',
            label_surface='Hadi answer source card')


# ============================================================ 9. STORIES

PACK_AREA = {
    'prophets': 'stories-prophets', 'seerah': 'stories-seerah', 'companions': 'stories-seerah', 'women': 'stories-seerah',
    'ghayb': 'stories-unseen', 'signs': 'stories-unseen', 'tales': 'stories-unseen', 'khutbahs': 'stories-unseen',
    'modernhadith': 'stories-modern', 'newmuslim': 'new-muslim', 'dailyduas': 'dua-dhikr',
}
PACK_FILE = {k: 'assets/stories/%s.json' % k for k in PACK_AREA}
PACK_LABEL = {
    'prophets': 'Stories > Prophets', 'seerah': 'Stories > Seerah', 'companions': 'Stories > Companions',
    'women': 'Stories > Women', 'ghayb': 'Stories > The Unseen (Ghayb)', 'signs': 'Stories > Signs of the Hour',
    'tales': 'Stories > Tales', 'khutbahs': 'Stories > Khutbahs', 'modernhadith': 'Stories > Modern hadith',
    'newmuslim': 'Stories > New Muslim path (30 days)', 'dailyduas': 'Stories > Hisn al-Muslim / daily duas',
}
PACK_REVIEWERS = {
    'prophets': (HADITH, []), 'seerah': (HADITH, []), 'companions': (HADITH, []), 'women': (WOMEN, [HADITH]),
    'ghayb': (HADITH, [CLIN]), 'signs': (HADITH, []), 'tales': (HADITH, []), 'khutbahs': (HADITH, [FIQH]),
    'modernhadith': (HADITH, [FIQH]), 'newmuslim': (FIQH, [HADITH]), 'dailyduas': (HADITH, [ARABIC]),
}

AUDIT_ROW = re.compile(r'^\|\s*(\w+)\s*\|\s*([\w-]+)\s*\|\s*(\d+)\s*\|\s*(\w+)\s*\|\s*(.*?)\s*\|\s*$')
CLASS_MEANING = {
    'C': 'verified citation', 'Q': "Qur'an", 'CQ': "verified citation + Qur'an",
    'M': 'mixed: supported core, unsourced detail', 'U': 'unsourced colour', 'RF': 'unsourced colour (reflection only)',
}


def build_stories():
    audit_rows = {}
    for ln in rd('docs/story_audit.md').splitlines():
        m = AUDIT_ROW.match(ln)
        if m and m.group(1) in PACK_AREA:
            audit_rows.setdefault((m.group(1), m.group(2)), []).append((int(m.group(3)), m.group(4), m.group(5)))
    seen_story = set()
    for pack, area in PACK_AREA.items():
        stories = rj(PACK_FILE[pack])
        rev, also = PACK_REVIEWERS[pack]
        for st in stories:
            sid = st['id']
            seen_story.add((pack, sid))
            rows = audit_rows.get((pack, sid), [])
            cls = ', '.join('ch%d=%s' % (c, k) for c, k, _ in rows)
            chlabels = sorted({c.get('label') for c in st['chapters'] if c.get('label')})
            lab = st.get('sourceLabel', '')
            weak = (lab not in ('Established',)) or any(l in ('Seerah report', 'Seerah report (source not checked)',
                                                           'Hadith report (reference not checked)') for l in chlabels)
            why = 'Story text written for this app from the cited sources; no named scholar has reviewed it.'
            if lab and lab != 'Established':
                why += ' Story label: "%s".' % lab
            if chlabels:
                why += ' Chapter labels: %s.' % ', '.join(chlabels)
            if rows:
                why += ' Audit classes (docs/story_audit.md): %s.' % cls
            srcs = ['assets/stories/%s.json (no named reviewer)' % pack]
            if rows:
                srcs.append('docs/story_audit.md (%d chapter rows)' % len(rows))
            srcs.append('FACT reports (accuracy passes; nothing scholar-reviewed)')
            extra_who = []
            blob = json.dumps(st, ensure_ascii=False)
            if re.search(r"Ibn Sa.d|Ibn Hisham|Ibn Ishaq|al-Tabari|Ibn al-Athir", blob):
                extra_who.append('seerah-book reports (Ibn Sa\'d / Ibn Hisham / Ibn Ishaq / Tabari) rather than the six hadith books')
            if re.search(r"daif|da.if|weak", blob, re.I):
                extra_who.append('names a weak (daif) narration')
            if re.search(r"graders differ|differ", blob, re.I) and 'grader' in blob.lower():
                extra_who.append('grader disagreement stated')
            if extra_who:
                why += ' Also: ' + '; '.join(extra_who) + '.'
            pr = 'high' if (weak or extra_who) else 'normal'
            nm = {'newmuslim': 'new-muslim.', 'dailyduas': 'dua-dhikr.dailyduas.'}.get(pack)
            if pack == 'newmuslim':
                iid = 'new-muslim.%s' % sid
            elif pack == 'dailyduas':
                iid = 'dua.daily.%s' % sid
            else:
                iid = 'story.%s.%s' % (pack, sid)
            R.add(
                id=iid, area=area, subarea=pack,
                where_app='%s > "%s"' % (PACK_LABEL[pack], st['title']),
                file=PACK_FILE[pack], key='[id=%s]' % sid,
                what='%d chapter(s) of "%s" and its source lines (%d sources); label "%s".' % (len(st['chapters']), st['title'], len(st['sources']), lab),
                why=why, reviewer=rev, also=also, source=srcs, priority=pr,
                label_surface='Story reader (all packs)')
    # chapter-level rows from the audit that name a specific problem
    for (pack, sid), rows in audit_rows.items():
        rev, also = PACK_REVIEWERS[pack]
        for ch, cl, action in rows:
            if cl not in ('M', 'U', 'RF'):
                continue
            iid = 'story.%s.%s.ch%d' % (pack, sid, ch)
            if iid in R.by_id:
                continue
            if pack == 'newmuslim':
                continue
            R.add(
                id=iid, area=PACK_AREA[pack], subarea=pack + '-chapter',
                where_app='%s > %s > chapter %d' % (PACK_LABEL[pack], sid, ch),
                file=PACK_FILE[pack], key='[id=%s].chapters[%d]' % (sid, ch - 1),
                what='Chapter %d of %s, audit class %s (%s).' % (ch, sid, cl, CLASS_MEANING.get(cl, cl)),
                why='docs/story_audit.md: ' + clip(action, 700),
                reviewer=rev, also=also, source=['docs/story_audit.md (row %s ch%d)' % (sid, ch)],
                priority='high' if cl in ('U',) or re.search(r"not checked|not opened|unverified|number not|unchecked|invented|unsupported", action, re.I) else 'normal',
                label_surface='Story reader (all packs)')


# ---- story layers and earlier accounts

def build_layers():
    idx = rj('assets/stories/layers/index.json')
    for s in idx['subjects']:
        sid = s['id']
        path = 'assets/stories/layers/%s.json' % sid
        if not os.path.exists(os.path.join(ROOT, path)):
            continue
        d = rj(path)
        rev, also = HADITH, []
        R.add(
            id='layers.%s' % sid, area='stories-prophets', subarea='layers',
            where_app='Story reader > Go deeper > %s (Qur\'an, hadith, scholarly explanation, disputes)' % d.get('title', sid),
            file=path, key='reviewStatus',
            what='The whole "Go deeper" file for %s: %d Qur\'an refs, %d hadith cards, %d scholarly cards, %d disputed questions.' % (
                d.get('title', sid), len(d.get('quran', [])), len(d.get('hadith', [])), len(d.get('scholarly', [])), len(d.get('differences', []))),
            why='The file\'s own reviewStatus says it has not been reviewed by a scholar; hadith "verified" dates were not re-read on sunnah.com (FACT_S1).',
            reviewer=rev, also=also, source=['layers json reviewStatus', 'FACT_S1_prophets (verified dates not moved)'],
            priority='normal', label_surface='Story "Go deeper" banner')
        for i, h in enumerate(d.get('hadith', [])):
            gtxt = '%s per %s' % (h.get('grade'), h.get('grader'))
            differs = bool(re.search(r'differ', gtxt, re.I))
            R.add(
                id='layers.%s.hadith.%d' % (sid, i + 1), area='stories-prophets', subarea='layers-hadith',
                where_app='Go deeper > %s > Hadith card %s %s' % (d.get('title', sid), h.get('book'), h.get('number')),
                file=path, key='hadith[%d] %s:%s' % (i, h.get('book'), h.get('number')),
                what='Hadith card %s %s: summary "%s", grade "%s" by %s.' % (h.get('book'), h.get('number'), clip(h.get('summary', ''), 160), h.get('grade'), clip(h.get('grader', ''), 60)),
                why='Hadith card inside an unreviewed layers file.' + (' Graders differ on this report.' if differs else ''),
                reviewer=HADITH, also=[], source=['layers json (no named reviewer)'] + (['FACT_S1_prophets (graders differ)'] if differs else []),
                priority='high' if differs else 'low', label_surface='Story "Go deeper" banner')
        for i, df in enumerate(d.get('differences', [])):
            R.add(
                id='layers.%s.differ.%d' % (sid, i + 1), area='stories-prophets', subarea='layers-disputed',
                where_app='Go deeper > %s > Disputed in the sources' % d.get('title', sid),
                file=path, key='differences[%d]' % i,
                what='Disputed question: %s (%d views are set out).' % (clip(df.get('question', ''), 220), len(df.get('views', []))),
                why='"Disputed in the sources": the views are stated from named works, not weighed by a scholar. R9_T4 noted one-sided '
                    'views in at least one case; OWNER_ACTIONS item 4 lists open questions waiting for a scholar.',
                reviewer=HADITH, also=[], source=['layers json differences', 'docs/OWNER_ACTIONS.md item 4 (open questions)'],
                priority='high', label_surface='Story "Go deeper" banner')
        for i, sc in enumerate(d.get('scholarly', [])):
            R.add(
                id='layers.%s.scholarly.%d' % (sid, i + 1), area='stories-prophets', subarea='layers-scholarly',
                where_app='Go deeper > %s > What scholars wrote (%s)' % (d.get('title', sid), clip(sc.get('work', ''), 40)),
                file=path, key='scholarly[%d] %s' % (i, clip(sc.get('work', ''), 40)),
                what='One-line summary of %s (%s, %s): %s' % (sc.get('work'), sc.get('author'), sc.get('locator'), clip(sc.get('summary', ''), 200)),
                why='A summary of a classical work written for this app; FACT_S1 checked the quote against the tafsir text, '
                    'but page numbers were not available and no scholar confirmed the summary.',
                reviewer=HADITH, also=[], source=['layers json scholarly', 'FACT_S1_prophets (tafsir page numbers not available)'],
                priority='normal', label_surface='Story "Go deeper" banner')
    for fp in sorted(glob.glob(os.path.join(ROOT, 'assets/stories/earlier/*.json'))):
        name = os.path.basename(fp)[:-5]
        path = 'assets/stories/earlier/%s.json' % name
        d = rj(path)
        items = d if isinstance(d, list) else d.get('items', d.get('accounts', [d]))
        R.add(
            id='earlier.%s' % name, area='stories-prophets', subarea='earlier-accounts',
            where_app='Story reader > Go deeper > Earlier accounts (%s), badge "Not from the Qur\'an"' % name,
            file=path, key='file',
            what='Earlier accounts for %s (Bible, Jewish and Christian tradition) and the class given to each (confirmed, silent, contradicted).' % name,
            why='The three-class rule (confirmed / silent / contradicted) is applied by the app author; a scholar should confirm each class. '
                'FACT_S1 corrected one item (crucifixion: "two bandits").',
            reviewer=HADITH, also=[], source=['assets/stories/earlier', 'FACT_S1_prophets (earlier accounts)'], priority='high',
            label_surface='Story "Go deeper" banner (Earlier accounts block)')


# ============================================================ 10. DUA / DHIKR

def build_dua():
    a = rj('assets/adhkar/adhkar.json')
    for s in a['sets']:
        for it in s['items']:
            n = it['n']
            weak = bool(re.search(r'weak|daif|da.if|graded', it.get('source', ''), re.I))
            R.add(
                id='dua.adhkar.%s.%02d' % (s['id'], n), area='dua-dhikr', subarea='adhkar-' + s['id'],
                where_app='Dhikr > %s adhkar > item %d' % (s['titleEn'], n),
                file='assets/adhkar/adhkar.json', key='sets[%s].items[n=%d]' % (s['id'], n),
                what='Dua %d of the %s set: meaning "%s", count %s, source "%s", transliteration (learning aid).' % (
                    n, s['titleEn'], clip(it.get('en', ''), 140), it.get('count'), clip(it.get('source', ''), 100)),
                why='Transliteration is the author\'s own learning aid (tlSource says "flagged for scholar review" where applicable); '
                    'the meaning and count are not scholar-reviewed.' + (' The source line names a graded or weak chain.' if weak else ''),
                reviewer=HADITH, also=[ARABIC],
                source=['adhkar.json (tlSource: flagged for scholar review)', 'FIX_WORSHIP_REPORT (adhkar transliteration 50/52; all translit are learning aids)'],
                priority='high' if weak else 'normal', label_surface='Adhkar screen')
    r = rj('assets/finance/ramadan.json')
    for day in r['days']:
        R.add(
            id='dua.ramadan.%02d' % day['day'], area='dua-dhikr', subarea='ramadan-days',
            where_app='Ramadan > day %d companion (theme: %s)' % (day['day'], day['theme']),
            file='assets/finance/ramadan.json', key='days[day=%d]' % day['day'],
            what='Day %d: theme "%s", dua with source "%s", meaning and transliteration.' % (day['day'], day['theme'], clip(day.get('source', ''), 100)),
            why='Ramadan data: every transliteration is "a learning aid flagged for scholar review" (ramadan.json note); '
                'the theme per day is an app decision; FIX_WORSHIP_REPORT: Ramadan 30 days (translit, dedupe, fixes).',
            reviewer=HADITH, also=[ARABIC, FIQH], source=['ramadan.json note + translitSource', 'FIX_WORSHIP_REPORT'], priority='normal',
            label_surface='Ramadan companion card')


# ============================================================ 11. NEW MUSLIM  (items made in build_stories as new-muslim.<id>)

# ============================================================ 12. SAKINA

def build_sakina():
    s = rd('lib/features/sakina/domain/sakina_content.dart')
    rooms = re.findall(r"SakinaRoom\(\s*id: '([^']+)',\s*name: '((?:[^'\\]|\\.)*)',\s*subtitle: '((?:[^'\\]|\\.)*)'", s)
    for rid, name, sub in rooms:
        R.add(
            id='sakina.room.%s' % rid, area='sakina', subarea='room',
            where_app='Sakina > room "%s" (%s)' % (unesc(name), unesc(sub)),
            file='lib/features/sakina/domain/sakina_content.dart', key="SakinaRoom id='%s'" % rid,
            what='Door line, quoted verses/hadith, safety line and help kinds for the "%s" room.' % unesc(name),
            why='Sakina law: pathways ship only after clinician and scholar review; the door lines and safety lines are '
                'written for this app and the screen already says "in clinician + scholar review". Marriage room grade wording was '
                'changed in FACT_S4 (hasan per Darussalam, sahih per al-Albani).',
            reviewer=CLIN, also=[HADITH], source=['sakina_content.dart header', 'module_registry: clinician+scholar review law', 'FACT_S4'],
            priority='high', label_surface='Sakina room screen')
    R.add(
        id='sakina.comfort-deck', area='sakina', subarea='comfort-cards',
        where_app='Sakina > Comfort cards and word of the day',
        file='lib/features/sakina/domain/sakina_content.dart', key='ComfortCards.deck (20 cards) and withheld',
        what='The 20 comfort cards (Qur\'an excerpts and hadith summaries), the "meaning of hardship" flag that keeps some cards out of the word of the day, and the withheld cards.',
        why='"The first 20 of 40; the rest ship with the pathways after clinician + scholar review." Wording of summaries is the app\'s.',
        reviewer=CLIN, also=[HADITH], source=['sakina_content.dart comfort deck comment'], priority='high',
        label_surface='Sakina comfort card')
    helps = re.findall(r"HelpResource\(\s*(?:[^()]*?)region: '((?:[^'\\]|\\.)*)'(?:[^()]*?)name: '((?:[^'\\]|\\.)*)'", s, re.S)
    R.add(
        id='sakina.help-lines', area='sakina', subarea='help-lines',
        where_app='Need help now dialog; Sakina help tiles; Hadi crisis reply',
        file='lib/features/sakina/domain/sakina_content.dart', key='HelpResources.all (+ unverified)',
        what='%d help-line records (country, service name, number or link, languages) and the "unverified" list.' % len(re.findall(r'HelpResource\(', s)),
        why='Re-verified against operator pages on 2026-10-20 (FACT_S4); help lines are US-centric with a findahelpline fallback; some marked '
            '"Not re-checked recently" (audit B). Needs a clinician and native speakers to confirm service names and phrasing per country.',
        reviewer=CLIN, also=[NATIVE], source=['B_worship audit (help lines US-centric)', 'FACT_S4 (HelpResources re-verified 2026-10-20)'],
        priority='high', label_surface='Need help now dialog')
    # feelings
    f = rj('assets/feelings/feelings.json')
    for e in f:
        R.add(
            id='sakina.feeling.%s' % e['id'].replace('feel-', ''), area='sakina', subarea='feelings',
            where_app='Feelings > %s (dua, story links, support card)' % e['feeling'],
            file='assets/feelings/feelings.json', key='[id=%s]' % e['id'],
            what='Feeling "%s": line, dua (%s), %d linked items and why-lines.' % (e['feeling'], clip(e['dua'].get('source', ''), 60), len(e.get('items', []))),
            why='FACT_S4 re-sourced all 24 duas; the "why" lines are app wording; support-card wording on 15 feelings is not clinician-reviewed.',
            reviewer=CLIN, also=[HADITH], source=['FACT_S4_modern_qa_feelings (feelings)', 'Sakina law: clinician + scholar review'],
            priority='normal', label_surface='Feeling screen')
    # Hadi grief / distress replies
    R.add(
        id='sakina.hadi-distress', area='sakina', subarea='hadi-safety',
        where_app='Hadi chat > replies to distress, grief, heartbreak, crisis',
        file='lib/features/hadi/data/offline_hadi_provider.dart; lib/features/sakina/domain/crisis_detector.dart', key='distressReplies, _griefReplies, _heartbreakReplies, crisis cards',
        what='Fixed compassionate replies for distress, grief (including child loss), heartbreak and the crisis cards that name real help lines.',
        why='E_games_hadi audit: earlier "Depression is not a lack of faith; it is a test" named a diagnosis; replies were rewritten but no clinician or scholar has reviewed them.',
        reviewer=CLIN, also=[HADITH], source=['E_games_hadi audit #16/#76', 'Sakina law'], priority='high', label_surface='Hadi answer bubble')
    R.add(
        id='sakina.wellbeing-tools', area='sakina', subarea='tools',
        where_app='Sakina > Steady (breathing, grounding), Mood check-in, Safety plan',
        file='lib/features/sakina/presentation/wellbeing_tools.dart; lib/features/sakina/application/wellbeing_store.dart', key='SteadyScreen, MoodCheckInScreen, SafetyPlanScreen',
        what='4-in/6-out breathing, 5-4-3-2-1 grounding, the five-mood check-in ("not a score and not a streak") and the seven-step safety plan.',
        why='Disclosed on screen as "not yet reviewed by a clinician" (wellbeing_tools.dart, wellbeing_store.dart); audit B.',
        reviewer=CLIN, also=[], source=['B_worship audit (safety plan not clinician-reviewed)', 'wellbeing_store.dart'], priority='high',
        label_surface='Sakina tools screens')


# ============================================================ 13. MONEY

def build_money():
    z = [
        ('nisab', 'Nisab 85 g gold / 595 g silver, silver default, tola switch (87.48 g / 612.36 g)',
         'Nisab gram values are scholarly conventions (S2_family_youth_transactions); silver-as-default is an app decision shown with both.'),
        ('rate-hawl', 'Rate 2.5% (1/40) and the one-lunar-year (hawl) condition',
         'The hawl condition is stated on the schools\' authority; individual reports not checked (S2 FYT).'),
        ('jewelry', 'Worn jewelry: Hanafi zakatable, Maliki/Shafi\'i/Hanbali exempt if genuinely worn; stored jewelry zakatable in all',
         'The madhab split drives the calculator (zakat_engine.dart); Abu Dawud 1563 hasan per al-Albani.'),
        ('debts', 'Debts by school: Hanafi and Hanbali deduct due debts; Maliki from cash/gold/silver only; Shafi\'i do not deduct; long-term debt as this year\'s instalments',
         'Audit B flagged that Shafi\'i selected still deducted debts (fixed); the instalment rule is "a contemporary position" needing a scholar.'),
        ('stocks', 'Stocks held long-term: proportional share or 25% (IFG) / 30% (NZF) proxies; trader at market value',
         'Practical proxies from named bodies; not scholar-reviewed.'),
        ('retirement', 'Retirement funds: two positions (annual on net accessible value, FCNA; or on access); 30% default penalty/tax proxy',
         'Two positions presented; the 30% proxy is the app\'s default (zakat_engine.dart).'),
        ('business-crypto', 'Business cash, inventory, receivables, expected receivables and crypto as zakatable assets',
         'Contemporary asset classes; no named scholar has confirmed the treatment.'),
        ('purity-live', 'Gold purity (karats) and live metal prices as the basis of nisab',
         'Maths verified on 16 inputs (audit B); the use of live market prices is a convenience, not a ruling.'),
        ('fitr', 'Zakat al-Fitr: one sa\' measure of food, the app multiplies a figure the user brings; Bukhari 1503',
         'The schools differ on the weight of a sa\' and on paying cash value; the app supplies no figure by design.'),
        ('recipients', 'Zakat recipients (8 categories, 9:60) in the Huda zakat guide and the Tayyib finance copy',
         'Contemporary application of the categories is a fiqh question.'),
        ('reminders-hawl', 'Zakat anniversary/hawl reminders and zakat history record',
         'Reminder logic assumes a lunar-year hawl start the user sets.'),
    ]
    for k, what, why in z:
        R.add(
            id='money.zakat.%s' % k, area='money', subarea='zakat',
            where_app='Zakat calculator (/zakat) and Huda zakat guides',
            file='lib/features/zakat/domain/zakat_engine.dart; nisab.dart; zakat_al_fitr.dart', key=k,
            what=what, why=why + ' Calculator output is shown "with madhab awareness and positions labelled, never ruled on".',
            reviewer=FIQH, also=[], source=['zakat_engine.dart header', 'B_worship audit (zakat)', 'S2_family_youth_transactions (not verified: hawl, nisab)'],
            priority='high', label_surface='Zakat screen')
    for k, what, why, files in [
        ('will-lessons', 'Will and estate: the one-third limit, no bequest to an heir without the other heirs\' consent, debts before shares, heirs\' fixed shares (4:11-12), guardianship',
         'S2_gaps: End-of-Life will and estate lessons need a scholar; R9_T2 found the earlier text thin and over-absolute (no 1/3 cap, no no-bequest-to-heir, no debts-first); working out a real estate is a scholar\'s task.',
         'assets/academy/lessons_v3/eol.json; lib/features/academy/presentation/end_of_life_school_screen.dart'),
        ('practical-will-guide', 'Huda "Preparing - the practical will" (huda-death-prep): six duties, sources list, bequest rules',
         'R9_T2: subtitle "Five duties" but six listed; sources line omitted inline-cited hadith; no scholar/lawyer caveat. A lawyer for the legal side of a will.',
         'assets/guides/guides.json'),
        ('inheritance-answers', 'Hadi answers on inheritance, shares and wills',
         'Rulings summarised in general terms; Hadi sends case-specific questions to a scholar.',
         'lib/features/hadi/data/hadi_core_data.dart'),
    ]:
        R.add(
            id='money.will.%s' % k, area='money', subarea='will-estate',
            where_app='End of Life school; Huda guides; Hadi', file=files, key=k, what=what, why=why,
            reviewer=FIQH, also=[LAWYER], source=['S2_gaps report', 'R9_T2_parent_wasia', 'OWNER_ACTIONS item 4'], priority='high',
            label_surface='End of Life school header; guide Sources card')
    fin = [
        ('halal-screen', 'The halal screen rules in Rayaan stocks: 5% revenue tolerance with purification, debt under ~30%, AAOIFI-style screens',
         'The text says "the screens scholars use (AAOIFI-style)" and "scholars tolerate the share with purification"; thresholds are stated as common screens, not by a named scholar.'),
        ('stocks-analysis', 'Company analysis and the paper trading floor in the Rayaan finance module',
         'Ordinary company analysis "not attributed to any one scholar"; paper market only.'),
        ('tayyib-finance', 'Tayyib finance lessons and the halal screen screen (lib/features/finance)',
         'Contemporary Islamic-finance content; Hadi answers on mortgage, crypto, insurance, credit cards say scholars differ (FIX_HADI_REPORT).'),
    ]
    for k, what, why in fin:
        R.add(
            id='money.finance.%s' % k, area='money', subarea='finance',
            where_app='Finance > Rayaan stocks / Tayyib finance / halal screen',
            file='assets/finance/rayaan_stocks.json; lib/features/finance', key=k, what=what, why=why,
            reviewer=FIQH, also=[], source=['assets/finance/rayaan_stocks.json (scholars-tolerate wording)', 'FIX_HADI_REPORT (mortgage, crypto, insurance)'],
            priority='high', label_surface='Finance screens')


# ============================================================ 14. PRAYER / CALENDAR

def build_prayer():
    s = rd('lib/features/prayer/application/prayer_settings.dart')
    methods = re.findall(r"PrayerMethodOption\('([^']+)',\s*'((?:[^'\\]|\\.)*)',\s*'((?:[^'\\]|\\.)*)'\)", s)
    for key, label, detail in methods:
        note = ''
        if key == 'moon_sighting_committee':
            note = ' FIX_WORSHIP_REPORT: the Moonsighting Committee method could not be re-derived independently.'
        if key in ('jafari', 'morocco', 'algeria', 'tunisia', 'france_uoif', 'russia', 'jakim', 'kemenag'):
            note = ' Angles for the regional presets follow the AlAdhan list (read 20 Oct 2026), not the authorities\' own publications.'
        R.add(
            id='prayer.method.%s' % key, area='prayer-calendar', subarea='method',
            where_app='Prayer Times > Calculation method > %s' % unesc(label),
            file='lib/features/prayer/application/prayer_settings.dart', key="PrayerMethodOption('%s')" % key,
            what='Method "%s": %s.' % (unesc(label), unesc(detail)),
            why='Choice of Fajr/Isha convention offered and used as the regional default; FIX_WORSHIP_REPORT verified the maths against PyEphem '
                '(within 0.5 min, Asr up to 1.7 min at 43-60N) but a scholar of fiqh/astronomy has not confirmed which conventions to offer or default.' + note,
            reviewer=FIQH, also=[], source=['FIX_WORSHIP_REPORT (prayer verification)', 'prayer_settings.dart'],
            priority='high', label_surface='Prayer Times method card')
    for key, what, why in [
        ('asr-school', 'Asr shadow rule: standard (shadow = object) or Hanafi (twice)', 'A school-dependent choice offered in settings.'),
        ('high-latitude', 'High-latitude rules (middle of the night, seventh of the night, angle-based) and the automatic choice',
         'FIX_WORSHIP_REPORT: method, angles and high-latitude label are shown; scholars differ on which rule applies where; verified for Oslo only against ephemeris.'),
        ('auto-region', 'Automatic regional default: which method most mosques use by coordinates (autoMethodFor) and the 195-city directory',
         'PR #131 expanded 24 to 195 cities with regional method fixes; excluded cities Casablanca, Beirut, Jerusalem, Gaza, Auckland, Vancouver/Calgary/Edmonton/Winnipeg (GPS covers). The mapping is an app decision.'),
        ('adhan-alerts', 'Adhan reminder wording, Tahajjud card and the Jumu\'ah countdown copy', 'Short religious copy around the times; not scholar-reviewed.'),
        ('ramadan-times', 'Imsak/suhoor/iftar wording and the Ramadan screen\'s dates (Umm al-Qura calendar)', 'Ramadan dates come from a calculated calendar; sighting can differ by a day or two (stated on screen).'),
    ]:
        R.add(
            id='prayer.%s' % key, area='prayer-calendar', subarea='method',
            where_app='Prayer Times screen', file='lib/features/prayer', key=key, what=what, why=why,
            reviewer=FIQH, also=[], source=['FIX_WORSHIP_REPORT', 'prayer_settings.dart'], priority='high', label_surface='Prayer Times screen')
    R.add(
        id='prayer.qibla', area='prayer-calendar', subarea='qibla',
        where_app='Qibla screen (/qibla)', file='lib/features/qibla/presentation/qibla_screen.dart', key='qibla copy and calibration guidance',
        what='Qibla direction copy, compass calibration and declination guidance, and the near-Kaaba / ship / plane wording.',
        why='FIX_WORSHIP_REPORT: qibla copy fixed; no scholar has confirmed the guidance for cases where direction is uncertain.',
        reviewer=FIQH, also=[], source=['FIX_WORSHIP_REPORT (qibla copy)'], priority='normal', label_surface='Qibla screen')
    obs = rd('lib/features/calendar/domain/hijri_date.dart')
    for m in re.finditer(r"Observance\(\s*(\d+),\s*(\d+),\s*'((?:[^'\\]|\\.)*)'", obs):
        mo, dy, nm = m.group(1), m.group(2), unesc(m.group(3))
        R.add(
            id='calendar.observance.%s-%s' % (mo, dy), area='prayer-calendar', subarea='observance',
            where_app='Calendar > observance "%s" (%s/%s)' % (nm, dy, mo),
            file='lib/features/calendar/domain/hijri_date.dart', key="Observance %s/%s %s" % (mo, dy, nm),
            what='"%s": the basis label (established / date uncertain / scholars differ / calendar marker), the about text and its source line.' % nm,
            why='The basis classification is the app\'s; Isra\' & Mi\'raj date disputed (FIX_HADI_REPORT), Mawlid and Laylat al-Bara\'ah marked contested; no scholar confirmed the classes.',
            reviewer=HADITH, also=[FIQH], source=['hijri_date.dart ObservanceBasis', 'FIX_HADI_REPORT (Isra and Mi\'raj date)'],
            priority='high', label_surface='Calendar observance card')
    R.add(
        id='calendar.sunnah-fasting', area='prayer-calendar', subarea='fasting',
        where_app='Calendar > sunnah fasting days (Mon/Thu, white days, Arafah, Ashura)', file='lib/features/calendar/domain/sunnah_fasting.dart', key='sunnah fasting list',
        what='The sunnah fasting list, the 9th-and-10th Ashura wording and Arafah for non-pilgrims.',
        why='Short sourced entries (Muslim 1162, 1134, Bukhari 2004); R9_T4 checked weekdays only; no scholar confirmed the wording or the pilgrim exception.',
        reviewer=FIQH, also=[HADITH], source=['sunnah_fasting.dart', 'R9_T4_everyday_skeptic'], priority='normal', label_surface='Calendar fasting card')
    R.add(
        id='calendar.hijri-method', area='prayer-calendar', subarea='hijri',
        where_app='Calendar > Hijri date and converter (Umm al-Qura, adjustable)', file='lib/features/calendar/domain/hijri_date.dart', key='Umm al-Qura calculation and adjustment',
        what='Using Umm al-Qura as the default Hijri calendar and the +/- day adjustment.',
        why='Stated on screen: can differ from sighting by a day or two. Whether to default to calculation is a fiqh/community question.',
        reviewer=FIQH, also=[], source=['hijri_date.dart honesty note', 'R9_T4_everyday_skeptic'], priority='normal', label_surface='Calendar screen')


# ============================================================ 15. LANGUAGES

def build_languages():
    s = rd('lib/app/core/i18n/ui_labels.dart')
    keys = re.findall(r"\n  '([\w.]+)':\s*\{", s)
    for k in keys:
        R.add(
            id='lang.label.%s' % k, area='languages', subarea='ui-label',
            where_app='UI label "%s" (navigation, Home, onboarding, Menu)' % k,
            file='lib/app/core/i18n/ui_labels.dart', key=k,
            what='Arabic, Bangla and Urdu wording of UI label "%s" against the English; direction (RTL for ar/ur).' % k,
            why='docs/content_needed/translation_review.md: "MACHINE-STYLE, NOT YET CHECKED BY A NATIVE SPEAKER"; the Language screen says these are first drafts (OWNER_ACTIONS item 15).',
            reviewer=NATIVE, also=[], source=['docs/content_needed/translation_review.md', 'FIX_FLOWS_REPORT (owner action 2)'],
            priority='normal', label_surface='Language settings note')
    R.add(
        id='lang.app-locale', area='languages', subarea='ui-label',
        where_app='Language & Voice screen; prayer-name words for eight languages', file='lib/app/core/i18n/app_locale.dart', key='supported locales, prayer-name words',
        what='Language & Voice labels for Urdu, Arabic and Indonesian and the prayer-name words in eight languages.',
        why='translation_review.md: "predate this review and need the same check".', reviewer=NATIVE, also=[], source=['docs/content_needed/translation_review.md'],
        priority='normal', label_surface='Language settings note')
    R.add(
        id='lang.arb', area='languages', subarea='ui-label', where_app='App title, taglines and Next/Continue buttons',
        file='lib/app/l10n/app_ar.arb', key='appTitle, taglineGateway, journeyToParadise, continueLabel, nextLabel',
        what='Arabic app title and tagline ("your gateway to Allah", "a journey to Paradise") and button words.',
        why='Short religious-flavoured taglines in Arabic; no native or scholarly check on record.', reviewer=NATIVE, also=[HADITH],
        source=['app_ar.arb'], priority='normal', label_surface='Language settings note')
    d = rd('lib/features/sakina/domain/crisis_detector.dart')
    pats = re.findall(r"const _Pat\('((?:[^'\\]|\\.)*)'", d)
    n = 0
    for p in pats:
        if re.search(r'[\u0600-\u06FF]', p):
            lang = 'Arabic/Urdu script'
        elif re.search(r'[\u0980-\u09FF]', p):
            lang = 'Bengali script'
        else:
            continue
        n += 1
        R.add(
            id='lang.crisis.%03d' % n, area='languages', subarea='crisis-phrase',
            where_app='Hadi / Sakina crisis detector (fires the help-line card)',
            file='lib/features/sakina/domain/crisis_detector.dart', key="_Pat('%s')" % p,
            what='Crisis phrase in %s: "%s" (normalised form, no vowel marks): is it natural, does it catch what a speaker would write, and does it avoid common idioms?' % (lang, p),
            why='Crisis phrases in ar/ur/bn were written without a native speaker; a missed crisis costs far more than a needless card (crisis_detector.dart design rules). OWNER_ACTIONS item 4: native speakers for non-English crisis phrases.',
            reviewer=NATIVE, also=[CLIN], source=['docs/OWNER_ACTIONS.md item 4', 'crisis_detector.dart'], priority='high',
            label_surface='Not user-visible; behaviour of the crisis card')
    # Phrase tables (lib/app/core/i18n/ui_phrases_data.dart), one item per group.
    pd = rd('lib/app/core/i18n/ui_phrases_data.dart')
    groups = dict(re.findall(r"\n  '(\w+)': '((?:[^'\\]|\\.)*)',", pd.split('kUiPhraseGroups')[1].split('};')[0]))
    for gid, title in sorted(groups.items()):
        R.add(
            id='lang.phrases.%s' % gid, area='languages', subarea='ui-phrases',
            where_app='Arabic, Urdu and Bangla wording of: %s' % title,
            file='lib/app/core/i18n/ui_phrases_data.dart', key='group "%s"' % gid,
            what='Every English / Arabic / Urdu / Bangla row of group "%s" (generated table; each row is shown through the Text wrapper). Check meaning, register and direction; the screens that carry support, safety or religious content show a visible "Native-speaker review needed" note.' % gid,
            why='Pass D (languages): machine drafts, no native speaker has read them. OWNER_ACTIONS item 22. Qur\u2019an, hadith and du\u2019a text is never in these tables.',
            reviewer=NATIVE, also=[], source=['docs/OWNER_ACTIONS.md item 22', 'docs/content_needed/translation_review.md'],
            priority='high' if gid in ('support', 'hadi', 'sources') else 'normal',
            label_surface='NativeReviewNote on the screen' if gid in ('support', 'hadi', 'sources', 'prayer', 'qibla', 'quran', 'faith', 'you', 'settings', 'more') else 'Language settings note')
    R.add(
        id='lang.crisis.cards-l10n', area='languages', subarea='crisis-phrase',
        where_app='Crisis cards, follow-ups and the "which country" note in Arabic, Urdu and Bangla',
        file='lib/features/sakina/domain/crisis_l10n.dart', key='seven crisis cards, five follow-ups, four country notes',
        what='Arabic, Urdu and Bangla wording of the fixed crisis cards (self-harm, suicide question, abuse, child safety, eating disorder, substance emergency, extremism). The verse is not translated: the card gives a reference only. Help-line names and numbers come from HelpResources, never from this file.',
        why='Machine draft of safety text; a native-speaking clinician must read it before it can lose its on-screen "Native-speaker review needed" line. Until then a reply without checked wording is shown in English with a note in the language.',
        reviewer=NATIVE, also=[CLIN, HADITH], source=['docs/OWNER_ACTIONS.md item 22', 'OWNER_ACTIONS item 4'], priority='high',
        label_surface='Review line at the end of each card')
    rr = [
        ('lang.crisis.roman-urdu', 'Roman-Urdu and Roman-Bangla crisis phrases (for example "marna chahta hoon", "jaan de dunga")'),
        ('lang.crisis.abuse-child-ed-extremism', 'Non-English phrases for abuse, child safety, eating disorders and extremism in the detector, and the fixed replies'),
        ('lang.crisis.replies', 'English fixed replies shown after a crisis match and the country help-line chooser (the Arabic, Urdu and Bangla versions are the separate item lang.crisis.cards-l10n)'),
    ]
    for k, w in rr:
        R.add(
            id=k, area='languages', subarea='crisis-phrase', where_app='Crisis detector and reply cards',
            file='lib/features/sakina/domain/crisis_detector.dart; lib/features/sakina/presentation/widgets/', key=k, what=w,
            why='OWNER_ACTIONS item 4: native speakers for non-English crisis phrases; replies are English-only.',
            reviewer=NATIVE, also=[CLIN], source=['docs/OWNER_ACTIONS.md item 4'], priority='high', label_surface='Crisis reply card')


# ============================================================ 16. GAMES / NOOR / CARDS

def build_games_noor():
    for pack, what, why in [
        ('trivia', 'Stories trivia (310 questions, each with source and quoted claims)', 'FIX_GAMES_REPORT: all sourced and tested for quote; the questions are app wording; nothing scholar-reviewed.'),
        ('hadith_quiz', 'Hadith Knowledge quiz (36 items, the Prophet\'s own words)', 'FIX_GAMES_REPORT: new bank; Companion questions removed; wording and grades not scholar-reviewed.'),
        ('seerah_quiz', 'Seerah Challenge (72 questions with evidence in their stories)', 'FACT_S2: evidence strings sq-26, 32, 40, 47, 48 were re-matched to the corrected stories; seerah reports are not scholar-reviewed.'),
        ('order_rounds', 'Seerah Timeline and Prophets in Order (12 events)', 'Orders follow the Seerah School and the family tree; no dates asserted; not scholar-reviewed.'),
        ('names99', '99 Names of Allah deck: the list, the classification (name / related / list) and the meaning shown after each answer', 'FIX_GAMES_REPORT: scholar review needed for the 99 meanings and the Name classification; ~33 were re-marked related/list.'),
    ]:
        R.add(
            id='games.%s' % pack, area='games', subarea='pack',
            where_app='Games > %s' % pack, file='assets/games/%s.json' % pack, key='file', what=what, why=why,
            reviewer=HADITH, also=[ARABIC] if pack == 'names99' else [], source=['FIX_GAMES_REPORT', 'GAMES_CONTENT_NEEDED.md'], priority='high' if pack == 'names99' else 'normal',
            label_surface='Games hub / game details')
    for k, w, why in [
        ('zayd-33-37', 'Naming Zayd as the Companion in Qur\'an 33:37', 'FIX_GAMES_REPORT scholar review: the Qur\'an does not name him in the verse.'),
        ('spirit-97-4', 'Reading "the Spirit" in 97:4 as Jibril', 'FIX_GAMES_REPORT scholar review: a tafsir reading.'),
        ('quba-9-108', 'Identifying the mosque of 9:108 as Quba', 'FIX_GAMES_REPORT scholar review: a tafsir identification.'),
        ('wives-named', 'Naming Khadijah / Sarah / Asiya where the Qur\'an says only "the wife of"', 'FIX_GAMES_REPORT scholar review.'),
        ('dropped-claims', 'Claims dropped as unverified: Sumayyah as first martyr, Juwayriyya, Abu Ubaidah\'s teeth, Umm Ayman, Munkar/Nakir wording (Tirmidhi 1071), Bilal\'s adhan on the Kaaba', 'FIX_GAMES_REPORT "Unverified/dropped": a scholar should confirm they stay out or can return.'),
        ('hadi-taif-armour', 'Ta\'if "stoned" wording and the armour-for-wheat/barley point (in Hadi)', 'FIX_GAMES_REPORT "Not mine (in Hadi)".'),
        ('hidden-games', 'Hidden games awaiting scholar-approved content: Islamic History, Seerah scenarios (How Would You Respond?), Arabic Spelling, Hajj Map', 'GAMES_CONTENT_NEEDED.md: each needs a named scholar\'s sign-off before it may show.'),
        ('wudu-salah-steps', 'Wudu and Salah Steps game: the guide\'s step order and the guide\'s madhhab note shown in the round', 'GAMES_CONTENT_NEEDED.md: the round follows the huda guides which follow no single school.'),
    ]:
        R.add(
            id='games.claim.%s' % k, area='games', subarea='claim', where_app='Games / Hadi',
            file='assets/games; lib/features/games/engine/learning_games.dart', key=k, what=w, why=why,
            reviewer=HADITH, also=[], source=['FIX_GAMES_REPORT'], priority='high', label_surface='Games hub / game details')
    n = rj('assets/noor/noor.json')['entries']
    for i, e in enumerate(n):
        R.add(
            id='noor.entry.%02d' % (i + 1), area='noor-cards', subarea='noor',
            where_app="Today's NOOR (entry %d: %s %s)" % (i + 1, e['k'], e['ref']),
            file='assets/noor/noor.json', key='entries[%d] %s' % (i, e['ref']),
            what="Entry %d (%s %s): English wording, source line and reflection prompt." % (i + 1, e['k'], e['ref']),
            why='FACT_S4: 24 Qur\'an entries identical to the bundled text; 6 Forty-Hadith entries fixed; the prompts are app wording; none scholar-reviewed.',
            reviewer=HADITH, also=[], source=['FACT_S4_modern_qa_feelings (Noor)'], priority='normal', label_surface="Today's NOOR card")
    for c in rj('assets/share/cards.json')['cards']:
        R.add(
            id='noor.card.%s' % c['id'], area='noor-cards', subarea='share-card',
            where_app='Share cards (%s)' % c['id'], file='assets/share/cards.json', key='[id=%s]' % c['id'],
            what='%s card "%s": text and reference %s.' % (c['kind'], c['id'], c.get('ref')),
            why='FACT_S4 fixed 7 of 12 cards (wording and grades); a share card carries a single line out of the app, without its context; no scholar reviewed.',
            reviewer=HADITH, also=[], source=['FACT_S4_modern_qa_feelings (cards)'], priority='normal', label_surface='Share card preview')
    R.add(
        id='noor.app-toc', area='noor-cards', subarea='app-toc',
        where_app='Home / search / Hadi: the app table of contents (13 rooms)', file='assets/share/app_toc.json', key='rooms',
        what='One-line descriptions of the app\'s rooms and titles (games, stories, duas).',
        why='FACT_S4 refreshed titles; wording that describes religious content (for example "Established") is the app\'s.',
        reviewer=HADITH, also=[], source=['FACT_S4_modern_qa_feelings (app_toc)'], priority='low', label_surface='Home')


# ============================================================ run

# ============================================================ support packs

CHILD_BANDS = ('5-8', '9-12', '13-17')
RX_WOMEN_SP = re.compile(r"marriage|marry|wife|husband|spouse|divorce|talaq|mahr|nikah|menstru|pregnan|women|woman|mother", re.I)


def build_support_packs():
    """One register item per snippet in assets/support/packs/*.json."""
    for path in sorted(glob.glob(os.path.join(ROOT, 'assets', 'support', 'packs', '*.json'))):
        d = rj(path)
        pack = d['pack']
        rel = 'assets/support/packs/%s' % os.path.basename(path)
        for sn in d['snippets']:
            text = sn['text'].get('en', '')
            srcs = sn.get('sources', [])
            has_rel = any(x.get('type') in ('hadith', 'quran') or 'hadith' in x.get('type', '') for x in srcs)
            bands = sn.get('ageBand', [])
            child = any(b in CHILD_BANDS for b in bands)
            disputed = bool(re.search(r'scholars differ', text, re.I))
            native = sn.get('needsNativeClinicianReview')
            clin = sn.get('needsClinicianReview')
            schol = sn.get('needsScholarReview')
            also = []
            if native:
                lead = NATIVE
                also = [CLIN]
            elif clin:
                lead = CLIN
                if schol or has_rel:
                    also.append(HADITH)
            elif disputed:
                lead = FIQH
                also = [HADITH]
            elif schol or has_rel:
                lead = HADITH
            else:
                lead = OWNER
            if disputed and lead != FIQH:
                also.append(FIQH)
            if RX_WOMEN_SP.search(text) and d.get('topic') in ('family_parenting', 'domestic_abuse', 'sexual_violence', 'new_muslim', 'etiquette'):
                also.append(WOMEN)
            flags = []
            if native:
                flags.append('needsNativeClinicianReview')
            if clin:
                flags.append('needsClinicianReview')
            if schol:
                flags.append('needsScholarReview')
            if child:
                flags.append('child age band %s: clinician and safeguarding review' % '/'.join(b for b in bands if b in CHILD_BANDS))
            if disputed:
                flags.append('states that scholars differ: each named school to be checked')
            why = 'Support-module snippet (kind %s, pack kind %s, risk %s, evidence %s, status %s). Flags: %s. No named reviewer has signed off.' % (
                sn.get('kind'), d.get('packKind'), sn.get('risk'), sn.get('evidenceLevel'), sn.get('status'),
                '; '.join(flags) if flags else 'none (product wording)')
            pri = 'high' if (sn.get('risk') == 'high' or native) else ('low' if lead == OWNER and sn.get('risk') == 'low' else 'normal')
            R.add(
                id='support.' + sn['id'], area='support-packs', subarea=pack,
                where_app='Hadi / Wasia support module > pack "%s" (%s)' % (pack, d.get('packKind')),
                file=rel, key=sn['id'],
                what=text, why=why, reviewer=lead, also=also,
                source=['Support packs build (tool/support/build_packs.py)'] + ['%s %s' % (x.get('type'), x.get('ref', x.get('title', ''))) for x in srcs[:3]],
                priority=pri, label_surface='Hadi / Wasia reply (support, conversation or knowledge pack)')


def build_all():
    build_lessons()
    build_phrases()
    build_glosses()
    build_school_screens()
    build_legacy_lessons()
    build_guides()
    build_qa()
    build_hadi()
    build_hadith()
    build_stories()
    build_layers()
    build_dua()
    build_sakina()
    build_money()
    build_prayer()
    build_languages()
    build_games_noor()
    import manual_items
    manual_items.add_all(R)
    import enrich
    enrich.apply(R)
    build_support_packs()



# ============================================================ render

COVERAGE = [
    # (label, regex over id + what + why + sources)
    ('Nawawi #12', r'hadith\.nawawi\.12$'), ('Nawawi #41', r'hadith\.nawawi\.41$'), ('Nawawi #42', r'hadith\.nawawi\.42$'),
    ('Tirmidhi 3153', r'3153'), ('Ibn Majah 4080', r'4080'), ('Tirmidhi 3513', r'3513'),
    ('7:143 report', r'7:143'), ("Ibn Sa'd-only details", r"Ibn Sa.d"), ('Ibn Hisham-only details', r'Ibn Hisham'),
    ('Juwayriyya', r'Juwayriyya'), ('Mahdi', r'Mahdi'), ('Iblis jinn or angel', r'Iblis'),
    ('Hell duration', r'how long the Fire|Fire lasts'), ('Istiwa', r'[Ii]stiwa'),
    ('Hadi: music', r'hadi\.core\.music$'), ('Hadi: games', r'hadi\.core\.games-ruling$'), ('Hadi: dating', r'hadi\.core\.dating-relationships$'),
    ('Hadi: credit cards', r'hadi\.core\.credit-card$'), ('Hadi: mahr', r'hadi\.core\.mahr$'), ('Hadi: iddah', r'hadi\.core\.iddah$'),
    ('Madhab contrast rows', r'madhab contrast step'), ('300 word glosses', r'gloss\.300$'), ('New Muslim days', r'new-muslim\.newmuslim-30$'),
    ('Will / estate lessons', r'money\.will\.will-lessons'), ('Janazah', r'eol\.janazah'), ('Hifz method', r'arabic\.hifz-method'),
    ('Sun and moon letters', r'arabic\.sun-moon-letters'), ('Saheeh licence', r'quran\.saheeh-licence'),
    ('Transliteration 59 of 6,236', r'quran\.translit-59'), ('Crisis phrases (native)', r'lang\.crisis\.001'),
    ('UI labels ar/bn/ur', r'lang\.label\.'), ('Zakat', r'money\.zakat\.nisab'), ('Prayer-time methods', r'prayer\.method\.'),
    ('Sakina rooms', r'sakina\.room\.'), ('Privacy lawyer: Terms', r'legal\.terms'), ('Privacy lawyer: children', r'legal\.children-privacy'),
    ('Nasheeds', r'nasheed\.catalogue'), ('Which son was sacrificed', r'sacrificed'), ('Khidr identity', r'Khidr|prophet-musa'),
    ('Zihar', r'zihar'), ('Neglecting prayer', r'neglect|abandon'),
    ('Support packs: all packs', r'support\.[a-z_0-9]+\.[a-z-]+\.001$'), ('Support packs: Hadi conversation', r'support\.hadi_chat_core\.'),
    ('Support packs: Wasia conversation', r'support\.wasia_chat_5_8\.'), ('Support packs: knowledge', r'support\.family_parenting\.'),
]


def coverage_check():
    bad = []
    for label, rx in COVERAGE:
        r = re.compile(rx)
        ok = any(r.search(i['id']) or r.search(i['what_to_review'] + ' ' + i['why_flagged'] + ' ' + ' '.join(i['source_of_flag'])) for i in R.items)
        if not ok:
            bad.append(label)
    return bad


def counts():
    by_area = {a: [0, 0] for a, _ in AREAS}
    by_rev = {r: 0 for r in REVIEWER_TYPES}
    by_pri = {'high': 0, 'normal': 0, 'low': 0}
    for i in R.items:
        by_area[i['area']][0] += 1
        if i['priority'] == 'high':
            by_area[i['area']][1] += 1
        by_rev[i['reviewer_type']] += 1
        by_pri[i['priority']] += 1
    return by_area, by_rev, by_pri


def render_json():
    by_area, by_rev, by_pri = counts()
    out = {
        'generated_by': 'tool/scholar_review/build_register.py',
        'note': 'Every item has status "open". A status changes only when a named scholar signs off (lib/app/core/scholar_review.dart). '
                'No reviewer has been named yet.',
        'total': len(R.items),
        'totals_by_area': {a: {'title': AREA_TITLE[a], 'items': by_area[a][0], 'high_priority': by_area[a][1]} for a, _ in AREAS},
        'totals_by_reviewer_type': by_rev,
        'totals_by_priority': by_pri,
        'items': R.items,
    }
    return json.dumps(out, ensure_ascii=False, indent=1) + '\n'


def esc(s):
    return str(s).replace('|', '/').replace('\n', ' ')


def render_md():
    by_area, by_rev, by_pri = counts()
    L = []
    L.append('# Scholar review register\n')
    L.append('Everything in Ar-Rayaan that needs a named scholar, clinician, native speaker, lawyer or rights holder before it can be called reviewed. '
             'Abdul\'s instruction (27 Oct 2026): do not exclude anything. Nothing has been reviewed by a named person yet, so every item below is **open** '
             'and every matching screen in the app says **Scholar review needed**.\n')
    L.append('Generated by `python3 tool/scholar_review/build_register.py` from the data files, the lesson and phrase flags, the audit and fix reports and '
             '`docs/OWNER_ACTIONS.md`. Do not edit by hand. The machine-readable copy is `tool/scholar_review/register.json` (fields: id, area, subarea, '
             'where_in_app, file, key, what_to_review, why_flagged, reviewer_type, also_reviewers, madhabs, priority, source_of_flag, label_surface, status).\n')
    L.append('## How a label goes away\n')
    L.append('When a named scholar agrees to be named, add one entry to `kScholarSignoffs` in `lib/app/core/scholar_review.dart` using the item id (or a parent '
             'id such as `huda.guide` for all guides) with the scholar\'s name and the date. The label for that item then reads "Reviewed by NAME on DATE". '
             'No name is invented. Nothing else changes.\n')
    L.append('Priority: **high** = a ruling, grade, school position, safety or rights question, or a point a report called out by name; **normal** = ordinary '
             'teaching text; **low** = a step the author labelled Interpretive or Reflection, or a mapping choice.\n')
    L.append('## Totals\n')
    L.append('**%d items.** High priority: %d. Normal: %d. Low: %d.\n' % (len(R.items), by_pri['high'], by_pri['normal'], by_pri['low']))
    L.append('### By area\n')
    L.append('| Area | Items | High priority |\n|---|---:|---:|')
    for a, t in AREAS:
        L.append('| %s | %d | %d |' % (t, by_area[a][0], by_area[a][1]))
    L.append('| **Total** | **%d** | **%d** |\n' % (len(R.items), by_pri['high']))
    L.append('### By reviewer type\n')
    L.append('| Reviewer | Items as lead reviewer | Items where also needed |\n|---|---:|---:|')
    for r in REVIEWER_TYPES:
        also = sum(1 for i in R.items if r in i['also_reviewers'])
        L.append('| %s | %d | %d |' % (r, by_rev[r], also))
    L.append('')
    L.append('Madhab scope: items whose reviewer is a fiqh scholar need a reviewer for each school (%s) wherever the item states a school position.\n' % ', '.join(MADHABS))
    L.append('### Reviewer type by area (lead reviewer)\n')
    head = '| Area | ' + ' | '.join(r.split(' (')[0] for r in REVIEWER_TYPES) + ' |'
    L.append(head)
    L.append('|---|' + '---:|' * len(REVIEWER_TYPES))
    for a, t in AREAS:
        row = []
        for r in REVIEWER_TYPES:
            n = sum(1 for i in R.items if i['area'] == a and i['reviewer_type'] == r)
            row.append(str(n) if n else '')
        L.append('| %s | %s |' % (t, ' | '.join(row)))
    L.append('')
    L.append('## By reviewer type: what each one is asked to look at\n')
    for r in REVIEWER_TYPES:
        items = [i for i in R.items if i['reviewer_type'] == r]
        L.append('### %s (%d lead, %d also)\n' % (r, len(items), sum(1 for i in R.items if r in i['also_reviewers'])))
        areas = {}
        for i in items:
            areas.setdefault(i['area'], []).append(i)
        for a, t in AREAS:
            if a in areas:
                hi = sum(1 for i in areas[a] if i['priority'] == 'high')
                L.append('- %s: %d items (%d high). Ids start with %s.' % (t, len(areas[a]),
                         hi, ', '.join(sorted({'`' + '.'.join(i['id'].split('.')[:2]) + '`' for i in areas[a]})[:6])))
        L.append('')
    L.append('## Register by area\n')
    compact_prefix = ('gloss.', 'hadi.shelf.', 'phrase.')
    for a, t in AREAS:
        items = [i for i in R.items if i['area'] == a]
        if not items:
            continue
        L.append('### %s\n' % t)
        L.append('%d items, %d high priority. Area key `%s`.\n' % (len(items), by_area[a][1], a))
        table = [i for i in items if not (i['priority'] == 'low' or i['id'].startswith(compact_prefix))]
        compact = [i for i in items if i not in table]
        if table:
            L.append('| Id | Where in the app | What to review | Why flagged | Reviewer | Pri | Source |\n|---|---|---|---|---|---|---|')
            for i in table:
                rv = i['reviewer_type'].split(' (')[0] + (' + ' + ', '.join(x.split(' (')[0] for x in i['also_reviewers']) if i['also_reviewers'] else '')
                L.append('| `%s` | %s | %s | %s | %s | %s | %s |' % (
                    i['id'], esc(clip(i['where_in_app'], 110)), esc(clip(i['what_to_review'], 200)), esc(clip(i['why_flagged'], 260)),
                    esc(rv), i['priority'], esc(clip('; '.join(i['source_of_flag']), 140))))
            L.append('')
        if compact:
            L.append('Listed in short form (same reason and sources for the whole family; full text in the JSON):\n')
            for i in compact:
                L.append('- `%s` (%s): %s' % (i['id'], i['reviewer_type'].split(' (')[0], esc(clip(i['what_to_review'], 130))))
            L.append('')
    L.append('## Not covered by this register\n')
    L.append('- Anything added to the app after this register was generated: re-run the builder; a test fails if the Sources screen counts no longer match.\n'
             '- Behaviour that is not content (device audio, notifications on a real phone): see `docs/OWNER_ACTIONS.md` item 8. Nothing in this task was tested on a device.\n'
             '- Qur\'an Arabic text is not "reviewed" here beyond the diacritics and edition items above; it is read from the bundled text, never typed.\n')
    return '\n'.join(L) + '\n'


def render_dart():
    by_area, by_rev, by_pri = counts()
    rows = ['    ScholarReviewArea(\'%s\', \'%s\', %d, %d),' % (a, t.replace("'", "\\'"), by_area[a][0], by_area[a][1]) for a, t in AREAS]
    revs = ['    ScholarReviewerCount(\'%s\', %d),' % (r.replace("'", "\\'"), by_rev[r]) for r in REVIEWER_TYPES]
    return """// GENERATED by tool/scholar_review/build_register.py. Do not edit by hand.
// Source: tool/scholar_review/register.json (docs/SCHOLAR_REVIEW_REGISTER.md).
// test/scholar_review_test.dart fails if these counts and the register differ.
library;

/// One area of the scholar-review register.
class ScholarReviewArea {
  const ScholarReviewArea(this.key, this.title, this.items, this.highPriority);

  final String key;
  final String title;
  final int items;
  final int highPriority;
}

/// How many register items lead with one reviewer type.
class ScholarReviewerCount {
  const ScholarReviewerCount(this.reviewer, this.items);

  final String reviewer;
  final int items;
}

/// Total items in the register. All are open until a named reviewer signs off.
const int kScholarReviewTotal = %d;

/// Items marked high priority.
const int kScholarReviewHighPriority = %d;

const List<ScholarReviewArea> kScholarReviewAreas = <ScholarReviewArea>[
%s
];

const List<ScholarReviewerCount> kScholarReviewers = <ScholarReviewerCount>[
%s
];
""" % (len(R.items), by_pri['high'], '\n'.join(rows), '\n'.join(revs))


def main():
    build_all()
    bad = coverage_check()
    if bad:
        print('COVERAGE GAPS: ' + ', '.join(bad))
        return 1
    outs = [(REGISTER_JSON, render_json()), (REGISTER_MD, render_md()), (SUMMARY_DART, render_dart())]
    if '--check' in sys.argv:
        stale = []
        for path, text in outs:
            try:
                cur = open(path, encoding='utf-8').read()
            except OSError:
                cur = None
            if cur != text:
                stale.append(os.path.relpath(path, ROOT))
        if stale:
            print('STALE (re-run tool/scholar_review/build_register.py): ' + ', '.join(stale))
            return 1
        print('register up to date: %d items' % len(R.items))
        return 0
    for path, text in outs:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(text)
    print('wrote %d items' % len(R.items))
    return 0


if __name__ == '__main__':
    sys.exit(main())
