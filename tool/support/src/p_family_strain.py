from .lib import Pack
from .sources import H, Q, bg, clin


def build():
    p = Pack('family_strain', 'support', 'family', 'hadi',
             'Family strain: parents who do not understand, conflict with children or siblings, being cut off, family rejection of choices or faith. Listen first; hold both love and hurt as true at once; never rush to fix a family.',
             base_tags=['distress'])
    A = p.add
    G = bg('RES_H1 10.1', 'Emotional support: listening, validation and small steps help; persistent or disabling distress should go to a clinician. General teaching; no source opened; clinician to confirm.')
    MH = clin('who_mhgap')

    A('orient', "Hurt that comes from family cuts deepest, because these are the people who were supposed to be safe. I am listening.", tags=['opening'])
    A('orient', "You can say the true version here — not the version you tell people outside the family.", tags=['opening'])
    A('orient', "Whatever is happening between you and your family, you will not be judged here. Tell me how it is for you.", tags=['opening'])

    A('reflect', "It sounds like your parents do not understand you — and being unseen by the people who raised you is a lonely place to stand.", tags=['unseen'], trig=['understand', 'understands', 'listen', 'parents'])
    A('reflect', "It sounds like love and hurt are tangled together here, and untangling them feels impossible.", tags=['tangled'], trig=['love', 'hurt', 'both', 'torn'])
    A('reflect', "It sounds like the silence between you has grown heavier than any argument could be.", tags=['silence'], trig=['speaking', 'silence', 'silent', 'ignored'])
    A('reflect', "Watching your own child drift, and not knowing how to reach them — that is a grief with no name.", tags=['child-drift'], trig=['son', 'daughter', 'drifting', 'children'])
    A('reflect', "It sounds like being cut off by your own family has left a hole that nothing else fills.", tags=['cutoff'], trig=['disowned', 'rejected', 'cut', 'kicked'])
    A('reflect', "It sounds like your family is struggling with your faith or your choices, and the rejection stings every single day.", tags=['rejection'], trig=['convert', 'revert', 'accept', 'islam', 'choice'])
    A('reflect', "It sounds like the arguments at home never really end — they just pause and start again.", tags=['arguments'], trig=['argue', 'arguing', 'fighting', 'fights'])
    A('reflect', "It sounds like you are always the one expected to bend, and you are running out of bend.", tags=['bend'], trig=['always', 'bend', 'compromise', 'expected'])
    A('reflect', "It sounds like guilt sits on top of it all — for loving them and being angry at them at the same time.", tags=['guilt'], trig=['guilty', 'guilt', 'angry'])

    A('ask', "When did it start to go wrong between you — was there a moment, or did it happen slowly?", tags=['story'])
    A('ask', "What do you wish they understood, in one sentence?", tags=['heart'])
    A('ask', "Who in the family are you still close to, if anyone?", tags=['support'])
    A('ask', "What happens when you try to talk about it?", tags=['pattern'])
    A('ask', "Do you have somewhere that feels like a safe place to be?", tags=['safety'], risk='medium')
    A('ask', "If this could soften even a little, what would the first sign be?", tags=['goal'])

    A('affirm', "You can love your family and be hurt by them. Both are true, and neither cancels the other.", tags=['both'])
    A('affirm', "Wanting your parents' understanding is not childish, no matter how old you are.", tags=['validation'])
    A('affirm', "Staying kind to people who are hard for you is not nothing. It costs you, and that cost is seen.", tags=['strength'])
    A('affirm', "You are allowed to grieve a relationship with someone who is still alive.", tags=['grief'])

    A('explain', "Families often speak different emotional languages across generations. What lands as coldness may be worry wearing a heavy coat — though that does not make it hurt less.", tags=['generations'], src=[G], ev='C', trig=['parents', 'generation', 'cold', 'strict'])
    A('explain', "Being cut off by family is processed by the heart like a bereavement. Waves of grief about it are normal, even years later.", tags=['cutoff'], src=[G], ev='C', trig=['disowned', 'cut', 'rejected', 'grief'])
    A('explain', "A child drifting away is not proof a parent failed. Influence stays, even when closeness pauses — most children circle back toward what was lovingly planted.", tags=['child-drift'], src=[G], ev='C', trig=['son', 'daughter', 'drifting', 'failed'])
    A('explain', "Kindness and boundaries can live together. You are allowed to limit contact that harms you while keeping your own heart soft.", tags=['boundaries'], src=[G], ev='C', trig=['boundaries', 'distance', 'limit', 'contact'])
    A('explain', "Families under pressure often turn on each other when the real enemy is the pressure. Naming that can change the whole room.", tags=['pressure'], src=[G], ev='C', trig=['money', 'stress', 'argue', 'fighting'])

    A('plan-step', "One small step: write the letter you will never send — everything, uncensored. Do not send it. Just get it out of your chest.", tags=['letter'], ask=True, src=[G], ev='C')
    A('plan-step', "One small step: one small kindness, with no speech attached — a cup of tea, a short message, a remembered detail. Doors open to small knocks.", tags=['kindness'], ask=True, src=[G], ev='C')
    A('plan-step', "One small step: choose one calm moment this week and say one honest sentence, beginning with \"I feel\", not \"you always\".", tags=['sentence'], ask=True, src=[G], ev='C')
    A('plan-step', "One small step: make dua for the person you are struggling with, by name, tonight. It changes the heart that says it first.", tags=['dua'], ask=True)
    A('plan-step', "One small step: eat one meal together with someone in the family, with no heavy topics allowed. Just presence.", tags=['meal'], ask=True, src=[G], ev='C')

    A('safety', "If home is not safe — if anyone is hurting you or you are frightened there — that matters more than any family tie, and help is real. Tell me plainly, and if you are in danger now, contact your local emergency number or a line below.", tags=['violence', 'crisis'], src=[clin('who_vaw'), MH], risk='high', fixed=True, trig=['hits', 'scared', 'afraid', 'unsafe', 'threatens'], dns=['Join with helplines.json scope domestic.'], stage=['crisis'])

    A('referral', "A family counsellor or mediator can hold a conversation that keeps catching fire at home. A wise elder or imam trusted by both sides can sometimes do the same.", tags=['mediator'], src=[G], ev='C', fixed=True, trig=['counsellor', 'mediator', 'elder', 'imam'])
    A('referral', "If you need a human voice tonight, the listening services below are free and patient. Family pain is a reason to call — you do not need a bigger reason.", tags=['listening'], src=[clin('samaritans')], ev='B', fixed=True)

    A('islamic', "The Qur'an asks children for a beautiful patience with parents — to lower the wing of humility and ask mercy for them. Gentleness toward parents is beloved to Allah, even when it is hard.", src=[Q('17:23-24', 'RES_H2 2.2')], tags=['parents', 'gentleness'], trig=['parents', 'mother', 'father', 'gentle'])
    A('islamic', "The Qur'an tells believers to stay kind to parents even when the parents push them away from their faith — kindness, without surrendering what you believe. Your Islam and your gentleness can stand together.", src=[Q('29:8', 'RES_H2 2.2'), Q('31:15', 'RES_H2 2.2')], tags=['kindness', 'rejection'], trig=['convert', 'revert', 'rejected', 'islam', 'faith'])
    A('islamic', "The Prophet taught that the one who is not merciful to the young is not of us. Mercy toward children is the measure of a Muslim home — and your child needs it most while they drift.", src=[H('tirmidhi:1919', 'RES_H2 5'), H('abudawud:4943', 'RES_H2 5')], tags=['mercy', 'children'], trig=['son', 'daughter', 'children', 'mercy'])
    A('islamic', "The Prophet taught that those who show mercy are shown mercy by the Most Merciful. Every soft word you give your family is seen and stored.", src=[H('bukhari:5997', 'RES_H2 5')], tags=['mercy'], trig=['mercy', 'soft', 'kind'])
    A('islamic', "The Qur'an teaches the dua: \"Our Lord, grant us from among our spouses and offspring comfort to our eyes.\" Asking Allah for your family by name is itself worship.", src=[Q('25:74', 'RES_H2 knowledge')], tags=['dua', 'family'], trig=['dua', 'comfort', 'eyes'])
    A('islamic', "The Prophet said the strong one is not the one who wins the fight, but the one who holds himself when angry. Every swallowed harsh word at home is recorded strength.", src=[H('bukhari:6114', 'RES_H2 6')], tags=['anger'], trig=['anger', 'angry', 'argue', 'fight'])
    A('islamic', "Allah says hearts find rest in His remembrance. When the house is loud, one quiet moment with Him can be the stillest room you have.", src=[Q('13:28', 'RES_H2 knowledge')], tags=['dhikr', 'calm'], trig=['peace', 'calm', 'rest'])

    A('family', "If someone you love is hurting from their family, believe them first. Do not rush to defend the family or to fix it — sit with the hurt and let it be real.", tags=['friend', 'family-of'], src=[G], ev='C', trig=['friend', 'sister', 'brother', 'cousin'])
    A('summary', "What I've heard: {topic} is hurting, and you want your family to feel like family again. Love and hurt can both stay true while we find the next step.", tags=['summary'], slots=['topic'])
    return [p]
