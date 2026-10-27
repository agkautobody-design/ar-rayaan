"""Helper for conversation packs: every move gets >= 6 variants per age band,
tagged by tone, with a variantGroup and a minGapTurns rotation hint."""
from .lib import Pack
from .sources import auth

ROT = {'strategy': 'seeded-no-repeat', 'defaultMinGapTurns': 8}


def conv_pack(name, audience, desc, ages, base_tags, gap=8):
    return Pack(name, 'conversation', 'conversation', audience, desc, ages=ages, rotation={'strategy': 'seeded-no-repeat', 'defaultMinGapTurns': gap},
                base_tags=base_tags)


def move(p, mv, lines, *, ages=('adult',), gap=None, slots=(), tags=(), trig=(), dns=(), stage=('any',), src=None, cross=()):
    """lines: list of (tone, text). Code = the move name with '-' for '_'."""
    code = mv.replace('_', '-')
    for tone, text in lines:
        use = [s for s in slots if '{%s}' % s in text]
        p.add('converse', text, code=code, tone=tone, move=mv, vgroup='%s.%s' % (p.name, code), gap=gap, slots=use,
              tags=[mv.replace('_', '-')] + list(tags), trig=trig, dns=dns, stage=list(stage), age=list(ages),
              src=src if src is not None else [auth('Conversational wording written for this app; no factual claim')], cross=cross)
