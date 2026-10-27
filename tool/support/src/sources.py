"""Source objects for the packs. Clinical and fiqh entries come from RES_H1 and
RES_H2 (the research briefs of 27 Oct 2026); every URL is one the research
fetched. Hadith and Qur'an sources are built from the verdict files and the
bundled Qur'an so a wrong ref fails at build time."""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
sys.path.insert(0, os.path.join(ROOT, 'tool'))
import hadith_check as hc  # noqa: E402
from .hadith_registry import REGISTRY  # noqa: E402

_V = None
_QC = None
RET = '2026-10-27'


def _verdicts():
    global _V
    if _V is None:
        import io, contextlib
        with contextlib.redirect_stderr(io.StringIO()):
            _V = hc.load_verdicts()
    return _V


def _quran():
    global _QC
    if _QC is None:
        q = json.load(open(os.path.join(ROOT, 'assets', 'quran', 'quran.json'), encoding='utf8'))
        _QC = {s['n']: s['c'] for s in q}
    return _QC


def Q(ref, section='RES_H2 2.1'):
    s, rest = ref.split(':')
    a, _, b = rest.partition('-')
    a, b = int(a), int(b or a)
    assert int(s) in _quran() and 1 <= a <= b <= _quran()[int(s)], 'bad Qur\'an ref ' + ref
    assert ref != '4:34'
    return {'type': 'quran', 'ref': ref, 'section': section}


def H(ref, section):
    assert ref in REGISTRY, 'hadith %s is not in src/hadith_registry.py' % ref
    v = _verdicts().get(ref)
    assert v and v['verdict'] == 'ok', 'no ok verdict for ' + ref
    book = ref.split(':')[0]
    grader = v.get('grader') or 'two Sahihs'
    if book in ('bukhari', 'muslim'):
        return {'type': 'hadith', 'ref': ref, 'grade': 'Sahih', 'grader': 'two Sahihs', 'section': section}
    return {'type': 'hadith', 'ref': ref, 'grade': v['grade'], 'grader': grader, 'section': section}


def clin(key, section=None):
    s = dict(CLIN[key])
    if section:
        s['section'] = section
    s.setdefault('retrievedOn', RET)
    return s


def bg(section, note):
    return {'type': 'background', 'section': section, 'note': note}


def fq(title, section, level, schools=(), url=None, note=None):
    d = {'type': 'fiqh', 'title': title, 'level': level, 'section': section}
    if schools:
        d['schools'] = list(schools)
    if url:
        d['url'] = url
    if note:
        d['note'] = note
    d['retrievedOn'] = RET
    return d


def asset(path, ident=None, note=None):
    d = {'type': 'asset', 'ref': path + ('#' + ident if ident else '')}
    if note:
        d['note'] = note
    return d


def HV(ref, section='RES_H2 knowledge'):
    """A hadith that already has an ok verdict in tool/hadith_verdicts (other gates
    wrote it), for knowledge packs. Same output shape as H()."""
    v = _verdicts().get(ref)
    assert v and v['verdict'] == 'ok', 'no ok verdict for ' + ref
    book = ref.split(':')[0]
    if book in ('bukhari', 'muslim'):
        return {'type': 'hadith', 'ref': ref, 'grade': 'Sahih', 'grader': 'two Sahihs', 'section': section}
    return {'type': 'hadith', 'ref': ref, 'grade': v['grade'], 'grader': v.get('grader') or 'al-Albani', 'section': section}


def guide(gid, note=None):
    d = {'type': 'asset', 'ref': 'assets/guides/guides.json#' + gid}
    if note:
        d['note'] = note
    return d


def lesson(course_file, lid, note=None):
    d = {'type': 'asset', 'ref': 'assets/academy/lessons_v3/%s.json#%s' % (course_file, lid)}
    if note:
        d['note'] = note
    return d


def qa(i, note=None):
    d = {'type': 'asset', 'ref': 'assets/qa/qa_bank.json#questions[%d]' % i}
    if note:
        d['note'] = note
    return d


def xg(gid):
    return {'asset': 'assets/guides/guides.json', 'id': gid}


def xl(course_file, lid):
    return {'asset': 'assets/academy/lessons_v3/%s.json' % course_file, 'id': lid}


def xq(i):
    return {'asset': 'assets/qa/qa_bank.json', 'id': 'questions[%d]' % i}


def auth(title='Wording written for this app; no external claim'):
    return {'type': 'authored', 'title': title}


def app(title):
    return {'type': 'app', 'title': title}


CLIN = {
    'niaaa_cut': {'type': 'guideline', 'title': 'NIAAA Rethinking Drinking: cutting down or quitting',
                  'url': 'https://rethinkingdrinking.niaaa.nih.gov/thinking-about-change/cut-down-or-quit', 'section': 'RES_H1 2.1'},
    'niaaa_core': {'type': 'guideline', 'title': 'NIAAA Core Resource on Alcohol: alcohol use disorder, risk, diagnosis and recovery',
                   'url': 'https://www.niaaa.nih.gov/health-professionals-communities/core-resource-on-alcohol/alcohol-use-disorder-risk-diagnosis-recovery', 'section': 'RES_H1 2.1'},
    'niaaa_treat': {'type': 'guideline', 'title': 'NIAAA: Treatment for alcohol problems, finding and getting help',
                    'url': 'https://www.niaaa.nih.gov/publications/brochures-and-fact-sheets/treatment-alcohol-problems-finding-and-getting-help', 'section': 'RES_H1 3.3'},
    'nice_cg100': {'type': 'guideline', 'title': 'NICE CG100: Alcohol-use disorders, diagnosis and management of physical complications',
                   'url': 'https://www.nice.org.uk/guidance/cg100/chapter/1-Guidance', 'section': 'RES_H1 2.1'},
    'benzo': {'type': 'study', 'title': 'Horowitz et al. 2026, benzodiazepine dependence and withdrawal, Psychological Medicine',
              'url': 'https://www.cambridge.org/core/product/C172F9ABC3E2E32D7FB133132A4F8012/core-reader', 'section': 'RES_H1 2.2'},
    'ghb_austin': {'type': 'guideline', 'title': 'Austin Health toxicology guideline: GHB withdrawal (July 2023)',
                   'url': 'https://austin.org.au/Assets/Files/GHB%20Withdrawal.July%202023[1].pdf', 'section': 'RES_H1 2.3'},
    'ghb_neu': {'type': 'study', 'title': 'Neu et al. 2023, GHB/GBL withdrawal inpatient series',
                'url': 'https://ascpjournal.BioMedCentral.com/counter/pdf/10.1186/s13722-023-00414-w.pdf', 'section': 'RES_H1 2.3'},
    'who_opioid': {'type': 'guideline', 'title': 'WHO fact sheet: opioid overdose', 'url': 'https://www.who.int/news-room/fact-sheets/detail/opioid-overdose', 'section': 'RES_H1 2.4'},
    'who_opioid_2026': {'type': 'guideline', 'title': 'WHO update on opioid dependence treatment and overdose prevention, 2 April 2026',
                        'url': 'https://www.who.int/news/item/02-04-2026-who-updates-guidelines-on-opioid-dependence-treatment-and-overdose-prevention', 'section': 'RES_H1 3.3'},
    'who_suicide': {'type': 'guideline', 'title': 'WHO fact sheet: suicide', 'url': 'https://www.who.int/news-room/fact-sheets/detail/suicide', 'section': 'RES_H1 2.5'},
    'who_mhgap': {'type': 'guideline', 'title': 'WHO mhGAP: assessment for self-harm and suicide in persons with priority mental, neurological and substance use disorders',
                  'url': 'https://cdn.who.int/media/docs/default-source/mental-health/mhgap/self-harm-and-suicide/assessment-for-self-harm-suicide-in-persons-with-priority-mental-neurological-and-substance-use-disorders.pdf?sfvrsn=616d6857_0', 'section': 'RES_H1 2.5'},
    'afsp': {'type': 'guideline', 'title': 'AFSP: how to talk safely about suicide', 'url': 'https://afsp.org/how-to-talk-safely-about-suicide/', 'section': 'RES_H1 2.5'},
    'who_vaw': {'type': 'guideline', 'title': 'WHO fact sheet: violence against women', 'url': 'https://www.who.int/news-room/fact-sheets/detail/violence-against-women', 'section': 'RES_H1 6.1'},
    'who_cm': {'type': 'guideline', 'title': 'WHO fact sheet: child maltreatment', 'url': 'https://www.who.int/news-room/fact-sheets/detail/child-maltreatment', 'section': 'RES_H1 10.1'},
    'who_elder': {'type': 'guideline', 'title': 'WHO fact sheet: abuse of older people', 'url': 'https://www.who.int/news-room/fact-sheets/detail/abuse-of-older-people', 'section': 'RES_H1 6.1'},
    'who_adol': {'type': 'guideline', 'title': 'WHO fact sheet: adolescent mental health', 'url': 'https://www.who.int/news-room/fact-sheets/detail/adolescent-mental-health', 'section': 'RES_H1 10.1'},
    'csbd': {'type': 'study', 'title': 'Frontiers in Psychiatry 2025 review: compulsive sexual behaviour disorder',
             'url': 'https://www.frontiersin.org/articles/10.3389/fpsyt.2025.1621136/full', 'section': 'RES_H1 3.10'},
    'ispu': {'type': 'study', 'title': 'ISPU / Stanford 2026: Substance use, addiction and recovery among American Muslims',
             'url': 'https://ispu.org/research-areas/addiction-recovery/', 'section': 'RES_H1 4.1'},
    'northumbria': {'type': 'study', 'title': 'British South Asian and Muslim communities\' perceptions of addiction and treatment services (2024)',
                    'url': 'https://researchportal.northumbria.ac.uk/en/publications/british-south-asian-and-muslim-communitys-perceptions-and-experie/', 'section': 'RES_H1 4.1'},
    'childhelp': {'type': 'institution', 'title': 'Childhelp National Child Abuse Hotline (operator page)', 'url': 'https://childhelphotline.org/', 'section': 'RES_H1 10.8'},
    'mwn': {'type': 'institution', 'title': 'Muslim Women\'s Network UK helpline', 'url': 'https://mwnuk.co.uk/mwn-helpline', 'section': 'RES_H1 4.4'},
    'peaceful': {'type': 'institution', 'title': 'Peaceful Families Project services directory', 'url': 'https://peacefulfamilies.org/services-directory-search.html', 'section': 'RES_H1 4.4'},
    'samaritans': {'type': 'institution', 'title': 'Samaritans UK: talk to us by phone', 'url': 'https://www.samaritans.org/how-we-can-help/contact-samaritan/talk-us-phone/', 'section': 'RES_H1 6.4'},
    'drinkaware': {'type': 'clinical', 'title': 'Drinkaware: alcohol withdrawal symptoms',
                   'url': 'https://www.drinkaware.co.uk/facts/health-effects-of-alcohol/general-health-effects/alcohol-withdrawal-symptoms', 'section': 'RES_H2 13'},
}
