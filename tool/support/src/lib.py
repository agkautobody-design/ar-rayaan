"""Authoring helpers for the support packs. The packs under assets/support/packs
are GENERATED from tool/support/src/p_*.py by tool/support/build_packs.py; edit
the sources, then rebuild. Every flag that can be derived is derived here so
that the validator and the review register stay consistent."""
import json
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
TODAY = '2026-10-27'
REVIEW_BY = '2027-04-27'
CHILD = ('5-8', '9-12', '13-17')
RELIGIOUS = {'quran', 'hadith', 'fiqh'}
CLINICAL = {'clinical', 'guideline', 'study', 'background'}
ABUSE_TOPICS = {'domestic_abuse', 'child_abuse', 'elder_abuse', 'sexual_violence'}

DEFAULT_STAGE = {
    'orient': ['open'], 'reflect': ['reflect'], 'ask': ['explore'], 'affirm': ['reflect', 'close'], 'summary': ['close'],
    'explain': ['explore'], 'plan-step': ['plan'], 'safety': ['crisis', 'handoff'], 'referral': ['handoff', 'plan'],
    'family': ['explore'], 'islamic': ['explore'], 'checkin': ['checkin'], 'converse': ['any'],
    'fact': ['question'], 'howto': ['question'], 'misconception': ['question'], 'etiquette': ['question'],
    'app-help': ['question'], 'lesson-fact': ['question'], 'faq': ['question'],
}


def evidence_for(srcs):
    types = {s['type'] for s in srcs}
    if not srcs:
        return 'N'
    if types <= {'app', 'asset', 'authored'}:
        return 'N'
    if 'background' in types:
        return 'C'
    clin = types & {'clinical', 'guideline', 'study'}
    rel = types & RELIGIOUS
    if clin and rel:
        return 'C'
    if clin:
        return 'B' if types == {'study'} else 'A'
    if rel:
        return 'D'
    return 'N'


class Pack:
    def __init__(self, name, kind, topic, audience, description, ages=('adult',), langs=('en',), rotation=None, version='0.1.0', base_tags=()):
        self.name, self.kind, self.topic, self.audience = name, kind, topic, audience
        self.description, self.ages, self.langs, self.rotation, self.version = description, list(ages), list(langs), rotation, version
        self.base_tags = list(base_tags)
        self.snips = []
        self.counts = {}

    def add(self, kind, en, *, code=None, stage=None, tags=(), trig=(), dns=(), src=(), ev=None, risk='low', age=None,
            ask=None, fixed=None, tone=None, move=None, vgroup=None, gap=None, slots=(), sub=None, disputed=False,
            schools=(), tr=None, cross=(), scholar=None, clinician=None, safeguard=None, audience=None):
        code = code or kind
        n = self.counts.get(code, 0) + 1
        self.counts[code] = n
        age = list(age or ['adult'])
        srcs = [dict(s) for s in src]
        types = {s['type'] for s in srcs}
        text = {'en': en}
        if tr:
            text.update(tr)
        sch = bool(scholar) if scholar is not None else bool(types & RELIGIOUS or kind == 'islamic')
        if scholar is None and (types & RELIGIOUS or kind == 'islamic'):
            sch = True
        cli = bool(types & CLINICAL) or kind in ('safety', 'plan-step', 'referral') or risk == 'high' or bool(set(age) & set(CHILD))
        if clinician is not None:
            cli = cli or clinician
        sg = bool(set(age) & set(CHILD)) or self.topic in ABUSE_TOPICS or bool(safeguard)
        if kind in ('safety', 'referral') or self.name == 'medical_emergency':
            fixed = True if fixed is None else fixed
        s = {
            'id': '%s.%s.%03d' % (self.name, code, n),
            'kind': kind,
        }
        if sub:
            s['subtopic'] = sub
        if audience:
            s['audience'] = audience
        s['stage'] = list(stage or DEFAULT_STAGE[kind])
        s['text'] = text
        s['ageBand'] = age
        if tone:
            s['tone'] = tone
        if move:
            s['move'] = move
        if vgroup:
            s['variantGroup'] = vgroup
        if gap:
            s['minGapTurns'] = gap
        if slots:
            s['slots'] = list(slots)
        s['tags'] = list(dict.fromkeys(self.base_tags + list(tags)))
        s['triggers'] = [t.lower() for t in dict.fromkeys(trig)]
        s['doNotSay'] = list(dns)
        s['sources'] = srcs
        if cross:
            s['crossRef'] = [dict(c) for c in cross]
        s['evidenceLevel'] = ev or evidence_for(srcs)
        s['risk'] = risk
        if ask is not None:
            s['askPermission'] = ask
        elif kind in ('explain', 'islamic', 'family'):
            s['askPermission'] = True
        if fixed:
            s['neverParaphrase'] = True
        if disputed:
            s['disputed'] = True
            s['schoolsNamed'] = list(schools)
        s['needsScholarReview'] = sch
        s['needsClinicianReview'] = cli
        if sg:
            s['needsSafeguardingReview'] = True
        s['needsNativeClinicianReview'] = bool(tr)
        s['reviewedBy'] = None
        s['reviewedOn'] = None
        s['status'] = 'draft'
        self.snips.append(s)
        return s

    def doc(self):
        langs = set()
        for s in self.snips:
            langs |= set(s['text'])
        d = {'schema': 1, 'pack': self.name, 'packKind': self.kind, 'topic': self.topic, 'description': self.description,
             'audience': self.audience, 'ageBands': self.ages, 'version': self.version, 'createdOn': TODAY, 'reviewBy': REVIEW_BY,
             'languages': [l for l in ('en', 'ar', 'ur', 'bn') if l in langs]}
        if self.rotation:
            d['rotation'] = self.rotation
        d['snippets'] = self.snips
        return d


def dumps_pack(doc):
    """Readable JSON: one key per line, each source object on a single line (the
    repo-wide hadith gate needs the grader on the same line as the reference)."""
    out = ['{']
    keys = [k for k in doc if k != 'snippets']
    for k in keys:
        out.append(' %s: %s,' % (json.dumps(k), json.dumps(doc[k], ensure_ascii=False)))
    out.append(' "snippets": [')
    parts = []
    for s in doc['snippets']:
        lines = ['  {']
        ks = list(s)
        for i, k in enumerate(ks):
            v = s[k]
            comma = ',' if i < len(ks) - 1 else ''
            if k == 'sources' and v:
                lines.append('   "sources": [')
                for j, src in enumerate(v):
                    lines.append('    %s%s' % (json.dumps(src, ensure_ascii=False), ',' if j < len(v) - 1 else ''))
                lines.append('   ]%s' % comma)
            elif k == 'text':
                lines.append('   "text": {')
                tk = list(v)
                for j, l in enumerate(tk):
                    lines.append('    %s: %s%s' % (json.dumps(l), json.dumps(v[l], ensure_ascii=False), ',' if j < len(tk) - 1 else ''))
                lines.append('   }%s' % comma)
            else:
                lines.append('   %s: %s%s' % (json.dumps(k), json.dumps(v, ensure_ascii=False), comma))
        lines.append('  }')
        parts.append('\n'.join(lines))
    out.append(',\n'.join(parts))
    out.append(' ]')
    out.append('}')
    return '\n'.join(out) + '\n'
