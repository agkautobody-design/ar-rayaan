#!/usr/bin/env python3
"""Validator for the Hadi / Wasia support, conversation and knowledge packs.

    python3 tool/support/validate_packs.py            # check assets/support/packs/*.json
    python3 tool/support/validate_packs.py FILE...    # check given files
    python3 tool/support/validate_packs.py --self-test

Rules live in docs/support/pack_format.md. Enums come from
tool/support/pack_schema.json (single source of truth). Python 3 standard
library only, so it runs in CI without installs. If `jsonschema` happens to be
installed the schema is also applied as a second opinion.

What it enforces (exit 1 on any failure):
  * required fields, enums, id shape, unique ids, no duplicate texts;
  * packKind -> allowed snippet kinds; conversation packs: >= 6 variants per
    move and age band, >= 2 tones, distinct openings, rotation block;
  * forbidden phrases (no dosing, no taper schedules, no 'just stop', no
    shaming labels, no 'you must tell your family', no 'obey', no 4:34 as a
    right, no weak/forbidden hadith, no secrecy promises, no 'I know how you
    feel', no diagnosis labels, no numbers/URLs/statistics in text);
  * every hadith source has an `ok` verdict in tool/hadith_verdicts with a
    usable (non-weak) grade; every Qur'an ref exists in assets/quran/quran.json;
  * non-English text only for safety / referral / checkin snippets (and the
    medical_emergency pack), always flagged needsNativeClinicianReview, and
    never with Qur'an/hadith marks;
  * review flags are consistent with the sources and kind, and a snippet is
    never `shippable` without a reviewer and date;
  * length: <= 90 words (<= 60 for child bands, <= 180 for knowledge), <= 1
    question mark, simple sentences for the 5-8 and 9-12 bands.
"""
import datetime
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, 'tool'))
import hadith_check as hc  # noqa: E402
import quran_ref_check as qrc  # noqa: E402

SCHEMA_PATH = os.path.join(ROOT, 'tool', 'support', 'pack_schema.json')
PACK_DIR = os.path.join(ROOT, 'assets', 'support', 'packs')
SCHEMA = json.load(open(SCHEMA_PATH, encoding='utf8'))
D = SCHEMA['$defs']
KINDS = set(D['kind']['enum'])
MOVES = set(D['move']['enum'])
TONES = set(D['tone']['enum'])
SLOTS = set(D['slot']['enum'])
AGE = set(D['ageBand']['enum'])
SRC_TYPES = set(D['sourceType']['enum'])
SNIP_REQUIRED = D['snippet']['required']
SNIP_PROPS = set(D['snippet']['properties'])
TOP_REQUIRED = SCHEMA['required']
TOP_PROPS = set(SCHEMA['properties'])
SRC_PROPS = set(D['source']['properties'])

PACK_KIND_KINDS = {
    'support': {'orient', 'reflect', 'ask', 'explain', 'plan-step', 'safety', 'islamic', 'family', 'referral',
                'checkin', 'affirm', 'summary'},
    'conversation': {'converse'},
    'knowledge': {'fact', 'howto', 'misconception', 'etiquette', 'app-help', 'lesson-fact', 'faq'},
}
CHILD_BANDS = {'5-8', '9-12', '13-17'}
# Kinds whose first-person wording may be a person's very first reply: no moralising.
FIRST_REPLY_KINDS = {'orient', 'reflect', 'ask', 'affirm', 'checkin', 'summary', 'safety', 'referral', 'plan-step'}
NON_EN_KINDS = {'safety', 'referral', 'checkin'}
NON_EN_PACKS = {'medical_emergency'}
CLINICAL_SRC = {'clinical', 'guideline', 'study', 'background'}
RELIGIOUS_SRC = {'quran', 'hadith', 'fiqh'}
MIN_VARIANTS = 6
TODAY = datetime.date.today().isoformat()

# Hadith that must never reach a user (RES_H2 section 8 'Do not use', and the
# 40-day / fourth-repentance narrations). Keys as in tool/hadith_verdicts.
FORBIDDEN_HADITH = {
    'tirmidhi:1862': '40 days / repentance not accepted after the fourth time (RES_H2 3.8, 8)',
    'nasai:5664': '40 days (RES_H2 3.8, 8)',
    'nasai:5670': '40 days (RES_H2 3.8, 8)',
    'bukhari:5578': 'not a believer while drinking (RES_H2 8)',
    'bukhari:5778': 'suicide and the Fire wording (RES_H2 4.7, 8)',
    'muslim:109': 'suicide and the Fire wording (RES_H2 4.7, 8)',
    'abudawud:495': 'beat them at ten (RES_H2 5.5, 8)',
    'muslim:2664': 'misusable "if only" clause (RES_H2 8)',
    'bukhari:5645': 'affliction as love, misusable with abuse (RES_H2 5.6, 8)',
    'tirmidhi:2505': 'fabricated shaming narration (RES_H2 4.6, 8)',
    'abudawud:3874': 'weak (RES_H2 8)',
    'abudawud:4377': 'weak (RES_H2 8)',
    'ibnmajah:4250': 'disputed grade (RES_H2 8, 9)',
    'muslim:2749': 'sounds like licence to sin (RES_H2 8)',
    'abudawud:4870': 'weak parallel of Muslim 1437 (RES_H2 2.4)',
    'tirmidhi:3049': 'disputed grade (RES_H2 9)',
    'nasai:5540': 'disputed grade (RES_H2 9)',
    'abudawud:3670': 'disputed grade (RES_H2 9)',
    'tirmidhi:2499': 'disputed grade (RES_H2 9)',
}
FORBIDDEN_QURAN_REFS = {
    '4:34': 'never as a right; not for the user-facing module (RES_H2 5.3, 1.6)',
}
WEAK_GRADE = re.compile(r"da.?[iy]f|weak|mawd|munkar|fabricat|batil|disputed", re.I)

# ---------------------------------------------------------------- patterns
def rx(*alts):
    return re.compile('|'.join(alts), re.I)

FORBIDDEN_TEXT = [
    ('dose or unit of medicine', rx(r"\b\d+(?:\.\d+)?\s?(?:mg|mcg|µg|ug|ml|milligrams?|micrograms?|grams?|tablets?|pills?|capsules?|drops?|units?|iu)\b",
                                   r"\b(?:take|swallow|inject|snort|smoke)\s+(?:\d+|one|two|three|half|a)\s+(?:more\s+)?(?:tablets?|pills?|capsules?|doses?|shots?|drinks?)\b",
                                   r"\bdosage\b", r"\bdose of\b", r"\bhow much to take\b")),
    ('taper schedule or reduction plan', rx(r"\btaper", r"\breduce (?:it |your (?:dose|drinking|intake) )?by\b", r"\bcut (?:back|down) by\b",
                                           r"\bsafe (?:amount|number|level|limit|dose)s?\b", r"\bdrinks? (?:a|per) (?:day|week)\b.*\breduce")),
    ('"just stop" / abrupt stopping advice', rx(r"\bjust (?:stop|quit|say no|pray|trust allah|be patient|leave|get over)\b", r"\bcold turkey\b",
                                               r"\bstop (?:right )?now\b", r"\bquit (?:right )?now\b", r"\bdetox(?:ing)? at home\b",
                                               r"\bstop (?:drinking|using|taking)(?: it| them)? (?:today|tonight|immediately|completely|suddenly)\b",
                                               r"\byou (?:can|could) (?:quit|stop) on your own\b", r"\bdon'?t need a doctor\b")),
    ('shaming label or word', rx(r"\baddicts?\b", r"\balcoholics?\b", r"\bjunkies?\b", r"\bdruggies?\b", r"\bpervert(?:s|ed)?\b", r"\bdegenerates?\b",
                                r"\bsinners?\b", r"\bfilth(?:y)?\b", r"\bdisgusting\b", r"\bpathetic\b", r"\bweak (?:iman|faith)\b", r"\bweakness of (?:iman|faith)\b",
                                r"\bhopeless case\b", r"\bbeyond (?:help|saving)\b", r"\bcursed\b", r"\bmust not love allah\b", r"\bback to zero\b",
                                r"\byou(?:'re| are) a failure\b", r"\byou failed\b", r"\bshame on you\b", r"\bunclean person\b", r"\bgutter\b",
                                r"\bloser\b", r"\bstupid\b", r"\blazy\b", r"\bnaughty\b", r"\bbad (?:boy|girl|child|kid)\b", r"\bdumb\b")),
    ('forced disclosure to family', rx(r"\byou (?:must|have to|need to|should) (?:tell|inform|confess to|come clean to) (?:your|the) (?:family|parents?|spouse|wife|husband|community|imam|mosque)\b",
                                       r"\bconfess to (?:your|the) (?:family|community|mosque)\b")),
    ('obedience to an abuser / keeping the family together', rx(r"\bobey\b", r"\bobedien(?:ce|t)\b", r"\bbe patient with (?:him|her|them)\b", r"\bkeep the family together\b",
                                                            r"\bmaybe (?:he|she|they) didn'?t mean\b", r"\bwhy don'?t you (?:just )?leave\b", r"\btry being a better (?:wife|husband)\b",
                                                            r"\byou should forgive (?:him|her|them)\b", r"\bgo back to (?:him|her|them)\b",
                                                            r"\btalk to (?:him|her) about it\b", r"\bconfront (?:him|her|them|your abuser)\b", r"\bthis is (?:just )?a test from allah\b",
                                                            r"\bthink of (?:your )?(?:family'?s? )?honou?r\b", r"\bdon'?t shame the (?:family|community)\b")),
    ('4:34 or striking as a right', rx(r"\b4\s*:\s*34\b", r"\bhusband(?:s)? (?:has|have) (?:a |the )?right to (?:hit|strike|beat|discipline)\b", r"\b(?:hit|strike|beat) (?:your|his|her) wife\b",
                                      r"\bnisa\b.*\bstrike\b")),
    ('Tirmidhi 1862 / forbidden narration wording', rx(r"\bforty days\b", r"\b40 days\b",
                                                        r"\bfourth time\b.*\brepent", r"\bnot (?:accept|accepted)(?:ed)? (?:his|your|their) (?:repentance|tawbah|prayer)\b")),
    ('secrecy or confidentiality promise', rx(r"\bi promise\b", r"\bour secret\b", r"\bkeep (?:it|this|that|your secret) (?:a )?secret\b", r"\bbetween (?:you and me|us)\b",
                                              r"\bi (?:will|won'?t|will not) (?:ever )?tell (?:anyone|anybody|no one|a soul)\b", r"\bi'?ll keep (?:it|this|that|your secret)\b",
                                              r"\b(?:completely|totally|fully|100) ?(?:confidential|anonymous|private|secret)\b", r"\bno one (?:will|can) (?:ever )?(?:see|know|find out)\b",
                                              r"\bpromise (?:me )?you won'?t tell\b")),
    ('claims to feel, be human or be a clinician/scholar', rx(r"\bi (?:know|understand|can imagine) (?:exactly )?how you feel\b", r"\bi feel your pain\b", r"\bi feel for you\b",
                                                               r"\bas (?:a|your) (?:therapist|counsell?or|doctor|psychologist|imam|scholar|mufti|human)\b", r"\bi(?:'m| am) (?:a )?human\b",
                                                               r"\bi(?:'ve| have) been (?:through|there) (?:this|it)\b", r"\bin my (?:own )?experience\b", r"\bmy (?:own )?(?:wife|husband|mum|mom|dad|children|kids|family)\b")),
    ('diagnosis of the person', rx(r"\byou(?:'re| are| have)\s+(?:an? )?(?:alcohol(?:ic|ism)|addict(?:ed)?|dependent|depress\w*|dyslexi\w*|adhd|autis\w*|bipolar|anorexi\w*|bulimi\w*|ocd|ptsd|psychotic|mentally ill|sick in the head)\b",
                                  r"\b(?:your child|he|she|they|your son|your daughter|the child|your student|you)\s+(?:has|have|is|are)\s+(?:an? )?(?:dyslexi\w*|adhd|autis\w*|dyscalcul\w*)\b",
                                  r"\byou (?:might|may|probably|likely) (?:have|be) (?:an? )?(?:addict|depress|alcohol|dyslexi|adhd)\w*")),
    ('closing hook', rx(r"\bdoes that help\?", r"\bhope that helps\b", r"\bis there anything else\b", r"\blet me know if you (?:need|want|have)\b", r"\bcome back (?:soon|tomorrow|tonight)\b",
                        r"\bi(?:'ll| will) be here (?:waiting|any ?time|always|24/7)\b", r"\bi(?:'m| am) always here for you\b", r"\bi(?:'ll| will) never leave\b", r"\bdon'?t go\b")),
    ('marriage as a cure', rx(r"\bget married\b", r"\bmarriage (?:will|would|can) (?:cure|fix|solve|heal)\b", r"\bfind (?:yourself )?a (?:wife|husband|spouse)\b")),
    ('guaranteed outcome or cure claim', rx(r"\bguarantee[sd]?\b", r"\b(?:will|can) (?:definitely|certainly|always) (?:cure|fix|heal|work)\b", r"\b(?:cure|cures|cured) (?:your|the) (?:addiction|craving)\b",
                                            r"\bprayer (?:will|can) cure\b", r"\bjust pray(?:ing)? (?:more|harder)\b", r"\bpray more\b(?! if)")),
    ('suicide/self-harm method or solution framing', rx(r"\bways? to (?:die|kill)\b", r"\bpainless(?:ly)?\b", r"\bsuicide is (?:the |an )?(?:answer|solution|way out|option)\b", r"\bcommitted suicide\b",
                                                        r"\bhow to (?:overdose|hang|cut)\b")),
    ('statistic or link in text (use helplines.json / sources)', rx(r"\b(?:one|1|two|2|three|3|four|4|five|5|six|6|seven|7|eight|8|nine|9) in (?:\d+|ten|three|four|five|six|seven|eight|nine|two)\b",
                                                                      r"\btimes (?:more|as) likely\b", r"\bstudies (?:show|prove|found)\b", r"\bresearch (?:shows|proves|found)\b", r"\bhttps?://", r"\bwww\.",
                                                                      r"\b[\w.+-]+@[\w-]+\.\w+\b", r"\b\d{2,}[- ]\d{2,}[- ]?\d*\b")),
    ('number or percentage in text (allowed only in non-clinical knowledge facts)', rx(r"\d\s?%", r"\bper ?cent\b", r"\b\d{3,}\b")),
    ('emoji', re.compile('[\U0001F300-\U0001FAFF☀-➿️]')),
    ('Qur\'an/hadith marks or honorific ligatures in text', re.compile('[﴾﴿۝ﷺﷲﷻۖ-ۜ۞-ۨ]')),
]
MORALISING = rx(r"\bharam\b", r"\bsins?\b", r"\bsinful\b", r"\bsinned\b", r"\bforbidden\b", r"\bprohibited\b", r"\bharaam\b", r"\bhellfire\b", r"\bpunish(?:ed|ment)?\b")
CHILD_PARENT_ONLY = rx(r"\btell (?:your )?(?:mum|mom|dad|parents?|mother|father)\b", r"\bask your (?:mum|mom|dad|parents?|mother|father) (?:for|to keep)\b", r"\bkeep (?:it|this|that) (?:a )?secret\b",
                       r"\bdon'?t tell\b")
CHILD_FORBIDDEN = rx(r"\bharam\b", r"\bhell\b", r"\bpunish(?:ed|ment)?\b", r"\bsin(?:s|ful|ned)?\b", r"\bgo to hell\b", r"\bgrave sin\b")
AR_SCRIPT = re.compile('[؀-ۿݐ-ݿࢠ-ࣿﭐ-﷿ﹰ-﻿]')
BN_SCRIPT = re.compile('[ঀ-৿]')
LATIN = re.compile('[A-Za-z]')
SLOT_RX = re.compile(r"\{([a-z_]+)\}")
WORD = re.compile(r"[A-Za-z0-9][A-Za-z0-9'’-]*")
SENT_SPLIT = re.compile(r"(?<=[.!?])\s+")
HADITH_KEY = re.compile(r"^(bukhari|muslim|abudawud|tirmidhi|nasai|ibnmajah):\d+$")
QURAN_REF = re.compile(r"^(\d{1,3}):(\d{1,3})(?:-(\d{1,3}))?$")
DATE = re.compile(r"^\d{4}-\d{2}-\d{2}$")


class Report:
    def __init__(self):
        self.errors = []

    def err(self, where, msg):
        self.errors.append('%s: %s' % (where, msg))


def words(s):
    return WORD.findall(s)


def norm(s):
    return re.sub(r'[^a-z0-9]+', ' ', s.lower()).strip()


def first_words(s, n=3):
    return ' '.join(norm(s).split()[:n])


def text_fields(snip):
    return snip.get('text', {}) if isinstance(snip.get('text'), dict) else {}


def check_source(rep, where, src, verdicts, snip):
    t = src.get('type')
    if t not in SRC_TYPES:
        rep.err(where, 'source type %r not allowed' % t)
        return
    for k in src:
        if k not in SRC_PROPS:
            rep.err(where, 'source has unknown field %r' % k)
    if 'url' in src and not str(src['url']).startswith('https://'):
        rep.err(where, 'source url must be https')
    if 'retrievedOn' in src and not DATE.match(src['retrievedOn']):
        rep.err(where, 'source retrievedOn must be YYYY-MM-DD')
    ref = src.get('ref', '')
    if t == 'quran':
        m = QURAN_REF.match(ref)
        if not m:
            rep.err(where, 'quran ref %r is not "s:a" or "s:a-b"' % ref)
            return
        s, a = int(m.group(1)), int(m.group(2))
        b = int(m.group(3)) if m.group(3) else a
        if not qrc.ref_valid(s, a, b):
            rep.err(where, "Qur'an ref %s does not exist in assets/quran/quran.json" % ref)
        for r in FORBIDDEN_QURAN_REFS:
            rs, ra = (int(x) for x in r.split(':'))
            if s == rs and a <= ra <= b:
                rep.err(where, "Qur'an %s is not allowed in packs: %s" % (r, FORBIDDEN_QURAN_REFS[r]))
    elif t == 'hadith':
        if not HADITH_KEY.match(ref):
            rep.err(where, 'hadith ref %r must look like bukhari:7507 (book in bukhari muslim abudawud tirmidhi nasai ibnmajah)' % ref)
            return
        if ref in FORBIDDEN_HADITH:
            rep.err(where, 'hadith %s must not be used: %s' % (ref, FORBIDDEN_HADITH[ref]))
        v = verdicts.get(ref)
        if not v:
            rep.err(where, 'hadith %s has no verdict in tool/hadith_verdicts' % ref)
        else:
            if v.get('verdict') != 'ok':
                rep.err(where, 'hadith %s verdict is %r, not ok' % (ref, v.get('verdict')))
            g = v.get('grade') or ''
            if ref.split(':')[0] in hc.GRADED and not g:
                rep.err(where, 'hadith %s has no usable grade on file' % ref)
            if WEAK_GRADE.search(g):
                rep.err(where, 'hadith %s has a weak/disputed grade on file (%s); do not use' % (ref, g))
        if not src.get('grade') or not src.get('grader'):
            rep.err(where, 'hadith source %s needs grade and grader (Sahihayn: grader "two Sahihs")' % ref)
        elif v and v.get('grade') and ref.split(':')[0] in hc.GRADED:
            # The grader named must appear in the verdict record.
            gr = (v.get('grader') or '').lower()
            if src['grader'].lower().split()[0].strip('()') not in gr and src['grader'].lower() not in gr:
                rep.err(where, 'hadith %s: grader %r is not the one on file (%r)' % (ref, src['grader'], v.get('grader')))
        if src.get('grade') and WEAK_GRADE.search(src['grade']):
            rep.err(where, 'hadith %s grade %r is weak/disputed' % (ref, src['grade']))
    elif t in ('clinical', 'guideline', 'study'):
        if not src.get('url'):
            rep.err(where, '%s source needs the RES_H1 url' % t)
        if not src.get('section'):
            rep.err(where, '%s source needs "section" (e.g. RES_H1 2.1)' % t)
    elif t == 'fiqh':
        if not (src.get('url') or src.get('title')):
            rep.err(where, 'fiqh source needs url or title')
        if not src.get('section'):
            rep.err(where, 'fiqh source needs "section" (e.g. RES_H2 3.4)')
        if not src.get('level'):
            rep.err(where, 'fiqh source needs "level" (institution/scholar/academic/...)')
    elif t == 'background':
        if not src.get('section'):
            rep.err(where, 'background source needs "section"')
        if snip.get('evidenceLevel') not in ('C', 'X'):
            rep.err(where, 'a snippet resting on a background source must have evidenceLevel C or X')
    elif t in ('app', 'asset'):
        if not ref and not src.get('title'):
            rep.err(where, '%s source needs ref or title' % t)


def _src_types(snip):
    return {x.get('type') for x in snip.get('sources', []) if isinstance(x, dict)}


def check_text(rep, where, snip, pack):
    kind = snip.get('kind')
    bands = set(snip.get('ageBand') or [])
    child = bool(bands & CHILD_BANDS)
    text = text_fields(snip)
    en = text.get('en', '')
    pk = pack.get('packKind')
    if not isinstance(en, str):
        return
    # language policy
    for lang, val in text.items():
        if lang not in ('en', 'ar', 'ur', 'bn'):
            rep.err(where, 'unknown language %r' % lang)
            continue
        if lang != 'en':
            if kind not in NON_EN_KINDS and pack.get('pack') not in NON_EN_PACKS:
                rep.err(where, 'text.%s only allowed for safety, referral, checkin snippets or the medical_emergency pack' % lang)
            if not snip.get('needsNativeClinicianReview'):
                rep.err(where, 'text.%s requires needsNativeClinicianReview true' % lang)
            if lang in ('ar', 'ur') and not AR_SCRIPT.search(val):
                rep.err(where, 'text.%s has no Arabic-script letters' % lang)
            if lang == 'bn' and not BN_SCRIPT.search(val):
                rep.err(where, 'text.bn has no Bengali letters')
            if lang in ('ar', 'ur') and LATIN.search(re.sub(r"\{[a-z_]+\}", '', val)):
                rep.err(where, 'text.%s mixes Latin letters (numbers belong in helplines.json)' % lang)
            if lang == 'bn' and LATIN.search(re.sub(r"\{[a-z_]+\}", '', val)):
                rep.err(where, 'text.bn mixes Latin letters')
        else:
            if AR_SCRIPT.search(val) or BN_SCRIPT.search(val):
                rep.err(where, 'text.en contains non-English script (nothing hand-typed in Arabic)')
    # forbidden phrases: scan every language for numbers/links/marks/emoji, English for the rest
    for lang, val in text.items():
        relaxed = pk == 'knowledge' and not (_src_types(snip) & CLINICAL_SRC)
        for label, pat in FORBIDDEN_TEXT:
            if label.startswith('number or percentage') and relaxed and lang == 'en':
                continue
            if lang != 'en' and not (label.startswith('statistic') or label.startswith('number') or label.startswith('emoji') or label.startswith("Qur'an")):
                continue
            m = pat.search(val)
            if m:
                rep.err(where, 'text.%s forbidden (%s): %r' % (lang, label, m.group(0)))
    if kind in FIRST_REPLY_KINDS:
        m = MORALISING.search(en)
        if m:
            rep.err(where, 'moralising word %r in a %s snippet (first replies must not moralise)' % (m.group(0), kind))
    if child:
        for pat, label in ((CHILD_FORBIDDEN, 'frightening/moral word for a child'), (CHILD_PARENT_ONLY, 'parent-only routing or secrecy to a child')):
            m = pat.search(en)
            if m:
                rep.err(where, '%s: %r' % (label, m.group(0)))
    # length / questions
    wc = len(words(en))
    if pk == 'knowledge':
        limit = 180
    elif child:
        limit = 60
    else:
        limit = 90
    if wc > limit:
        rep.err(where, 'text.en is %d words (limit %d)' % (wc, limit))
    if wc < 2:
        rep.err(where, 'text.en is too short')
    if pk != 'knowledge' and en.count('?') > 1:
        rep.err(where, 'more than one question mark (one question at a time)')
    if bands & {'5-8', '9-12'}:
        cap = 16 if '5-8' in bands else 24
        for s in SENT_SPLIT.split(en.strip()):
            n = len(words(s))
            if n > cap:
                rep.err(where, 'a sentence of %d words is too long for band %s (max %d): %r' % (n, '5-8' if '5-8' in bands else '9-12', cap, s[:50]))
    # slots
    used = set(SLOT_RX.findall(en))
    for lang, val in text.items():
        used |= set(SLOT_RX.findall(val))
    declared = set(snip.get('slots') or [])
    for s in used:
        if s not in SLOTS:
            rep.err(where, 'unknown slot {%s}' % s)
        elif s not in declared:
            rep.err(where, 'slot {%s} used but not declared in "slots"' % s)
    for s in declared - used:
        rep.err(where, 'slot %s declared but not used' % s)
    if re.search(r"[{}]", SLOT_RX.sub('', en)):
        rep.err(where, 'stray brace in text.en')
    # diagnosis and quotes near refs are caught by the global gates; run the Qur'an/hadith
    # citation finders on the text too so a pasted "Bukhari 123" or "(2:255)" is caught here.
    for lang, val in text.items():
        for m in hc.CITE.finditer(val):
            book = next(k for k, _ in hc.BOOKS if m.group(k))
            for n in hc.NUM.findall(m.group('nums')):
                rep.err(where, 'hadith citation "%s %s" written in text; use a structured source (text carries no citations)' % (book, n))
        for r in qrc.find_refs(val):
            rep.err(where, 'Qur\'an reference "%s" written in text; use a structured source' % r[5])


def check_snippet(rep, where, snip, pack, verdicts):
    for k in snip:
        if k not in SNIP_PROPS:
            rep.err(where, 'unknown field %r' % k)
    for k in SNIP_REQUIRED:
        if k not in snip:
            rep.err(where, 'missing required field %r' % k)
    if any(k not in snip for k in SNIP_REQUIRED):
        return
    sid = snip['id']
    if not re.match(r"^[a-z][a-z0-9_]*\.[a-z0-9-]+\.[0-9]{3}$", sid):
        rep.err(where, 'bad id shape (want <pack>.<code>.<nnn>)')
    elif not sid.startswith(pack.get('pack', '?') + '.'):
        rep.err(where, 'id must start with the pack name %r' % pack.get('pack'))
    kind = snip['kind']
    if kind not in KINDS:
        rep.err(where, 'kind %r not allowed' % kind)
        return
    pk = pack.get('packKind')
    if kind not in PACK_KIND_KINDS.get(pk, set()):
        rep.err(where, 'kind %r is not allowed in a %s pack' % (kind, pk))
    for b in snip['ageBand']:
        if b not in AGE:
            rep.err(where, 'ageBand %r not allowed' % b)
    for s in snip['stage']:
        if s not in D['stage']['enum']:
            rep.err(where, 'stage %r not allowed' % s)
    if snip.get('tone') is not None and snip['tone'] not in TONES:
        rep.err(where, 'tone %r not allowed' % snip['tone'])
    if snip['evidenceLevel'] not in D['snippet']['properties']['evidenceLevel']['enum']:
        rep.err(where, 'evidenceLevel %r not allowed' % snip['evidenceLevel'])
    if snip['risk'] not in ('low', 'medium', 'high'):
        rep.err(where, 'risk %r not allowed' % snip['risk'])
    if snip['status'] not in ('draft', 'clinician_approved', 'scholar_approved', 'shippable'):
        rep.err(where, 'status %r not allowed' % snip['status'])
    if snip['evidenceLevel'] == 'X' and snip['status'] == 'shippable':
        rep.err(where, 'evidenceLevel X cannot be shippable')
    for fld in ('tags', 'triggers', 'doNotSay'):
        if not isinstance(snip[fld], list) or not all(isinstance(x, str) for x in snip[fld]):
            rep.err(where, '%s must be a list of strings' % fld)
    for t in snip['tags']:
        if not re.match(r"^[a-z0-9][a-z0-9_-]*$", t):
            rep.err(where, 'bad tag %r' % t)
    for t in snip['triggers']:
        if t != t.lower():
            rep.err(where, 'trigger %r must be lower case' % t)
    # sources
    srcs = snip['sources']
    if not isinstance(srcs, list):
        rep.err(where, 'sources must be a list')
        srcs = []
    for i, s in enumerate(srcs):
        check_source(rep, '%s source[%d]' % (where, i), s, verdicts, snip)
    types = {s.get('type') for s in srcs}
    if not srcs and snip['evidenceLevel'] not in ('N', 'X'):
        rep.err(where, 'no sources: evidenceLevel must be N (pure wording) or X (unreviewed)')
    if snip['evidenceLevel'] == 'N' and (types & (RELIGIOUS_SRC | CLINICAL_SRC)):
        rep.err(where, 'evidenceLevel N but has clinical or religious sources')
    # Review flags consistency
    sch, cli = snip['needsScholarReview'], snip['needsClinicianReview']
    if (types & RELIGIOUS_SRC or kind == 'islamic') and not sch:
        rep.err(where, 'religious source or islamic kind: needsScholarReview must be true')
    if (types & CLINICAL_SRC or kind in ('safety', 'plan-step', 'referral')) and not cli:
        rep.err(where, 'clinical source or kind %s: needsClinicianReview must be true' % kind)
    if (set(snip['ageBand']) & CHILD_BANDS) and not (cli and snip.get('needsSafeguardingReview')):
        rep.err(where, 'child age band: needsClinicianReview and needsSafeguardingReview must be true')
    if snip['risk'] == 'high' and not cli:
        rep.err(where, 'risk high: needsClinicianReview must be true')
    if pack.get('topic') in ('domestic_abuse', 'child_abuse', 'elder_abuse', 'sexual_violence') and not snip.get('needsSafeguardingReview'):
        rep.err(where, 'abuse topics need needsSafeguardingReview true')
    if len(snip['text']) > 1 and not snip['needsNativeClinicianReview']:
        rep.err(where, 'translations need needsNativeClinicianReview true')
    if snip['needsNativeClinicianReview'] and len(snip['text']) == 1:
        rep.err(where, 'needsNativeClinicianReview true but only English text')
    if snip.get('disputed'):
        if 'scholars differ' not in snip['text'].get('en', '').lower():
            rep.err(where, 'disputed snippet text must say "scholars differ"')
        if not snip.get('schoolsNamed'):
            rep.err(where, 'disputed snippet must name schools in schoolsNamed')
        if not sch:
            rep.err(where, 'disputed snippet needs needsScholarReview true')
    # reviewer
    rb, ro, st = snip['reviewedBy'], snip['reviewedOn'], snip['status']
    if (rb is None) != (ro is None):
        rep.err(where, 'reviewedBy and reviewedOn must both be null or both set')
    if rb is not None:
        if not isinstance(rb, dict) or not rb.get('name') or not rb.get('role'):
            rep.err(where, 'reviewedBy needs name and role')
        if ro and not DATE.match(ro):
            rep.err(where, 'reviewedOn must be YYYY-MM-DD')
    if st != 'draft' and rb is None:
        rep.err(where, 'status %s requires reviewedBy/reviewedOn' % st)
    # conversation
    if pk == 'conversation':
        if snip.get('move') not in MOVES:
            rep.err(where, 'conversation snippet needs a valid "move"')
        if not snip.get('tone'):
            rep.err(where, 'conversation snippet needs "tone"')
        if not snip.get('variantGroup'):
            rep.err(where, 'conversation snippet needs "variantGroup"')
    else:
        for f in ('move', 'variantGroup', 'minGapTurns'):
            if f in snip:
                rep.err(where, '%r only belongs in conversation packs' % f)
    # text
    check_text(rep, where, snip, pack)
    # crossRef
    for cr in snip.get('crossRef', []):
        p = os.path.join(ROOT, cr.get('asset', ''))
        if not os.path.isfile(p):
            rep.err(where, 'crossRef asset %s does not exist' % cr.get('asset'))


def check_pack(path, verdicts):
    rep = Report()
    rel = os.path.relpath(path, ROOT).replace(os.sep, '/')
    try:
        pack = json.load(open(path, encoding='utf8'))
    except ValueError as e:
        rep.err(rel, 'not valid JSON: %s' % e)
        return rep, None
    if not isinstance(pack, dict):
        rep.err(rel, 'top level must be an object')
        return rep, None
    for k in TOP_REQUIRED:
        if k not in pack:
            rep.err(rel, 'missing top-level field %r' % k)
    for k in pack:
        if k not in TOP_PROPS:
            rep.err(rel, 'unknown top-level field %r' % k)
    if rep.errors:
        return rep, pack
    name = os.path.basename(path)[:-5]
    if pack['pack'] != name:
        rep.err(rel, 'pack %r does not match file name %r' % (pack['pack'], name))
    pk = pack['packKind']
    if pk not in PACK_KIND_KINDS:
        rep.err(rel, 'packKind %r not allowed' % pk)
        return rep, pack
    if pack['audience'] not in ('hadi', 'wasia', 'both'):
        rep.err(rel, 'audience not allowed')
    if not re.match(r"^\d+\.\d+\.\d+$", pack['version']):
        rep.err(rel, 'version must be semver')
    for f in ('createdOn', 'reviewBy'):
        if not DATE.match(pack[f]):
            rep.err(rel, '%s must be YYYY-MM-DD' % f)
    if DATE.match(pack['reviewBy']) and pack['reviewBy'] < TODAY:
        rep.err(rel, 'reviewBy %s has passed: the pack is expired' % pack['reviewBy'])
    if pk == 'conversation':
        r = pack.get('rotation')
        if not isinstance(r, dict) or r.get('strategy') != 'seeded-no-repeat' or not isinstance(r.get('defaultMinGapTurns'), int):
            rep.err(rel, 'conversation packs need rotation {strategy: seeded-no-repeat, defaultMinGapTurns: int}')
    elif 'rotation' in pack:
        rep.err(rel, 'rotation only belongs in conversation packs')
    ids = set()
    texts = {}
    for i, sn in enumerate(pack['snippets']):
        where = '%s #%d (%s)' % (rel, i, sn.get('id', '?') if isinstance(sn, dict) else '?')
        if not isinstance(sn, dict):
            rep.err(where, 'snippet must be an object')
            continue
        if sn.get('id') in ids:
            rep.err(where, 'duplicate id')
        ids.add(sn.get('id'))
        check_snippet(rep, where, sn, pack, verdicts)
        en = text_fields(sn).get('en')
        if isinstance(en, str):
            k = norm(en)
            if k in texts:
                rep.err(where, 'text duplicates %s' % texts[k])
            texts[k] = sn.get('id')
        for lang in languages_used(sn):
            if lang not in pack['languages']:
                rep.err(where, 'text.%s used but "languages" does not list it' % lang)
    # pack-level rules
    n = len(pack['snippets'])
    if pk == 'support' and not (25 <= n <= 60) and pack['pack'] not in ('crisis_basics',):
        rep.err(rel, 'support packs hold 25-60 snippets (has %d)' % n)
    if pk == 'conversation':
        groups = {}
        for sn in pack['snippets']:
            if not isinstance(sn, dict):
                continue
            for band in (sn.get('ageBand') or []):
                groups.setdefault((sn.get('move'), band), []).append(sn)
        for (mv, band), g in sorted(groups.items(), key=lambda x: str(x)):
            if len(g) < MIN_VARIANTS:
                rep.err(rel, 'move %s / band %s has %d variants (need >= %d)' % (mv, band, len(g), MIN_VARIANTS))
            if len({s.get('tone') for s in g}) < 2:
                rep.err(rel, 'move %s / band %s needs at least two tones' % (mv, band))
            seen = {}
            for s in g:
                fw = first_words(text_fields(s).get('en', ''))
                if fw in seen and fw:
                    rep.err(rel, 'move %s / band %s: %s and %s open with the same words (%r)' % (mv, band, seen[fw], s.get('id'), fw))
                seen[fw] = s.get('id')
    return rep, pack


def languages_used(sn):
    t = sn.get('text')
    return list(t.keys()) if isinstance(t, dict) else []


def run(paths):
    verdicts = hc.load_verdicts()
    total = 0
    errors = []
    counts = {}
    for p in paths:
        rep, pack = check_pack(p, verdicts)
        errors.extend(rep.errors)
        if pack and isinstance(pack, dict) and isinstance(pack.get('snippets'), list):
            counts[os.path.basename(p)] = len(pack['snippets'])
            total += len(pack['snippets'])
    try:
        import jsonschema  # optional second opinion
        validator = jsonschema.Draft202012Validator(SCHEMA)
        for p in paths:
            try:
                doc = json.load(open(p, encoding='utf8'))
            except ValueError:
                continue
            for e in sorted(validator.iter_errors(doc), key=lambda e: list(e.path))[:20]:
                errors.append('%s: schema: %s at /%s' % (os.path.basename(p), e.message[:160], '/'.join(str(x) for x in e.path)))
    except ImportError:
        pass
    for p, n in sorted(counts.items()):
        print('  %-34s %4d snippets' % (p, n))
    print('packs checked: %d; snippets: %d; failures: %d' % (len(paths), total, len(errors)))
    for e in errors:
        print('FAIL', e)
    return 1 if errors else 0


def main(argv):
    if '--self-test' in argv:
        sys.path.insert(0, os.path.join(ROOT, 'tool', 'support'))
        import test_validate_packs
        return test_validate_packs.main()
    files = [a for a in argv[1:] if not a.startswith('--')]
    if not files:
        files = sorted(f for f in glob.glob(os.path.join(PACK_DIR, '*.json')) if not os.path.basename(f).startswith('_'))
    if not files:
        print('no packs under assets/support/packs yet; schema and validator load fine')
        return 0
    return run(files)


if __name__ == '__main__':
    sys.exit(main(sys.argv))
