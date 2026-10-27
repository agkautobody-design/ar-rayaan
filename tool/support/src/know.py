"""Helper for knowledge packs: short retrievable facts, how-tos, FAQs, etiquette and
misconceptions. Every snippet points at the app's own guide, Q&A or lesson through
`crossRef` and `sources` rather than duplicating its text, and where schools differ
the text says 'scholars differ' and names them."""
from .lib import Pack


def kpack(name, topic, desc, tags, audience='both'):
    return Pack(name, 'knowledge', topic, audience, desc, ages=('all',), base_tags=list(tags))


def K(p, kind, text, src, *, cross=(), tags=(), trig=(), dns=(), schools=None, age=('all',), sub=None, scholar=True,
      code=None, clinician=None, risk='low', ask=None):
    kw = dict(src=src, cross=list(cross), tags=list(tags), trig=list(trig), dns=list(dns), age=list(age), sub=sub,
              scholar=scholar, code=code, risk=risk)
    if clinician is not None:
        kw['clinician'] = clinician
    if ask is not None:
        kw['ask'] = ask
    if schools:
        kw['disputed'] = True
        kw['schools'] = list(schools)
    return p.add(kind, text, **kw)
