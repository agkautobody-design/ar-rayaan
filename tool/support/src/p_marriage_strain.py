from .lib import Pack
from .sources import H, Q, bg, clin


def build():
    p = Pack('marriage_strain', 'support', 'marriage', 'hadi',
             'Marriage strain: arguments that loop, coldness, feeling unloved, in-law pressure, thinking about divorce. Listen first; never take sides, never rule on divorce; help the person find one honest next step.',
             base_tags=['distress'])
    A = p.add
    G = bg('RES_H1 10.1', 'Emotional support: listening, validation and small steps help; persistent or disabling distress should go to a clinician. General teaching; no source opened; clinician to confirm.')
    MH = clin('who_mhgap')

    A('orient', "Marriage pain is its own kind of heavy, because it comes from the person who is meant to be the closest. I am listening.", tags=['opening'])
    A('orient', "Thank you for trusting this space with it. Whatever is happening between you two, you can say it plainly here.", tags=['opening'])
    A('orient', "You do not have to defend anyone here, not them and not yourself. Just tell me how it is for you.", tags=['opening'])

    A('reflect', "It sounds like the two of you keep having the same fight, and each round costs you more.", tags=['conflict'], trig=['argue', 'arguing', 'arguments', 'fight', 'fighting'])
    A('reflect', "It sounds like the warmth has gone quiet between you, and that silence hurts more than shouting would.", tags=['coldness'], trig=['cold', 'distant', 'distantly', 'quiet', 'silence'])
    A('reflect', "Feeling unloved by the person you built a life with is a deep ache, not a small complaint.", tags=['unloved'], trig=['unloved', 'affection', 'ignored', 'unseen'])
    A('reflect', "It sounds like people outside the marriage are pressing on it too, and you are carrying pressure from every side.", tags=['in-laws'], trig=['inlaws', 'pressure', 'interfering'])
    A('reflect', "Even thinking about divorce is exhausting — it sits in the background of everything else you do.", tags=['divorce'], trig=['divorce', 'talaq', 'khula', 'leaving', 'separate'])
    A('reflect', "It sounds like you are holding the home together mostly alone, and nobody sees the weight of that.", tags=['carrying'], trig=['alone', 'everything', 'carry', 'carrying'])
    A('reflect', "Being married and still feeling lonely is one of the loneliest places there is.", tags=['lonely'], trig=['lonely', 'empty', 'numb'])
    A('reflect', "It sounds like you are torn — part of you wants to fix this and part of you is so tired.", tags=['torn'], trig=['tired', 'confused', 'torn', 'unsure'])
    A('reflect', "It sounds like respect has been wearing thin, and that is painful to admit even to yourself.", tags=['respect'], trig=['respect', 'disrespect', 'belittled', 'criticism'])

    A('ask', "What does a good day between you two look like — the last one you can remember?", tags=['exceptions'])
    A('ask', "How long has it been like this?", tags=['duration'])
    A('ask', "After a fight, what happens — does anything get repaired, or does it just go quiet?", tags=['repair'])
    A('ask', "What first made you choose this person?", tags=['history'])
    A('ask', "Is there anyone safe in your life who knows how hard it has been?", tags=['support'])
    A('ask', "If your spouse could truly hear one sentence from you without defending themselves, what would it be?", tags=['heart'])
    A('ask', "Are you safe at home — physically safe?", tags=['safety-check'], risk='medium', ask=True, dns=['If no or unclear, move to the domestic abuse flow and the helplines.'])

    A('affirm', "Wanting peace in your home is not asking for too much. It is what a home is for.", tags=['validation'])
    A('affirm', "Talking about it honestly, even here, is not a betrayal of your marriage. It is care for it.", tags=['validation'])
    A('affirm', "Still being here, still hoping it can soften — that is not weakness.", tags=['strength'])
    A('affirm', "You are allowed to say this hurts without deciding anything today.", tags=['permission'])

    A('explain', "Most couples in trouble are not having many different fights; they are having one fight, on repeat, in different costumes. Naming the loop is the first step out of it.", tags=['cycle'], src=[G], ev='C', trig=['argue', 'arguing', 'fight', 'loop', 'same'])
    A('explain', "Repair matters more than never fighting. Couples who recover after conflict — a soft word, a cup of tea, a small joke — do better than couples who never disagree.", tags=['repair'], src=[G], ev='C', trig=['fight', 'argue', 'repair', 'after'])
    A('explain', "Feeling unloved often grows in silence, not in cruelty. The longer it goes unnamed, the louder it feels. Saying it, gently and specifically, is how it starts to shrink.", tags=['unloved'], src=[G], ev='C', trig=['unloved', 'cold', 'distant', 'affection'])
    A('explain', "A marriage carries two families, not two people. Pressure from relatives is real pressure, and it is fair to ask for a boundary kindly and clearly.", tags=['in-laws'], src=[G], ev='C', trig=['inlaws', 'family', 'pressure', 'interfering'])
    A('explain', "Whether a divorce counts, or how to seek one, is a question for a qualified scholar in person — and no one should rush you either way. What we can do here is carry the weight of the thinking.", tags=['ruling'], trig=['divorce', 'talaq', 'khula', 'valid', 'count'])

    A('plan-step', "One small step: write down the one thing you most need your spouse to understand, in one plain sentence. Just for yourself, for now.", tags=['clarity'], ask=True, src=[G], ev='C')
    A('plan-step', "One small step: pick a calm hour — not after a fight — and offer one soft sentence, like \"I miss us.\" Who you were at the start is still in there.", tags=['reconnect'], ask=True, src=[G], ev='C')
    A('plan-step', "One small step: notice one thing your spouse did today that was not nothing, and say it aloud. It feels small; it is not.", tags=['appreciation'], ask=True, src=[G], ev='C')
    A('plan-step', "One small step: agree together on a pause word — either of you can say it when a talk starts to burn, and you both stop for twenty minutes.", tags=['pause'], ask=True, src=[G], ev='C')
    A('plan-step', "One small step: pray two units slowly and ask, in your own words, for softness between you. Then tell me what that was like.", tags=['salah'], ask=True)

    A('safety', "If anyone in your home is hurting you, or you are frightened of them, that is different from arguments and it is never something to endure quietly. Tell me plainly, and if you are in danger now, contact your local emergency number or a crisis line below.", tags=['violence', 'crisis'], src=[clin('who_vaw'), MH], risk='high', fixed=True, trig=['hits', 'hit', 'scared', 'afraid', 'threatens', 'hurts'], dns=['Join with helplines.json scope domestic.'], stage=['crisis'])

    A('referral', "A couples counsellor, or a wise elder or imam both of you trust, can hold a conversation that is too hot to hold alone. Asking for that is a strength in a marriage, not an admission of failure.", tags=['counsellor'], src=[G], ev='C', fixed=True, trig=['counsellor', 'mediator', 'imam', 'elder'])
    A('referral', "If you need to talk to a person tonight, the listening services below are free and patient. You do not need to explain yourself first.", tags=['listening'], src=[clin('samaritans')], ev='B', fixed=True)

    A('islamic', "Allah says He placed between spouses affection and mercy, and made the home a place of stillness. That is His design for you — asking for it back is asking for something He loves.", src=[Q('30:21', 'RES_H2 2.2')], tags=['mercy', 'design'], trig=['love', 'mercy', 'affection', 'sakeena', 'tranquility'])
    A('islamic', "The Prophet taught that the most complete believers in faith are the best in character, and the best of them are the best to their wives. Gentleness at home is faith, not extra.", src=[H('tirmidhi:1162', 'RES_H2 6'), H('tirmidhi:3895', 'RES_H2 6')], tags=['character', 'kindness'], trig=['character', 'kind', 'gentle', 'best'])
    A('islamic', "The Prophet taught that Allah is kind and loves kindness in everything. A marriage can be re-softened; it starts with one person choosing gentleness first.", src=[H('muslim:2593', 'RES_H2 6')], tags=['kindness'], trig=['kindness', 'gentle', 'soft'])
    A('islamic', "The Prophet taught that those who are merciful are shown mercy by the Most Merciful. Mercy at home is never wasted, even when it is not returned yet.", src=[H('bukhari:5997', 'RES_H2 5')], tags=['mercy'], trig=['mercy', 'merciful'])
    A('islamic', "The Prophet praised the one who holds his anger when he could act on it. A swallowed harsh word in a marriage is recorded worship, not a lost argument.", src=[H('bukhari:6114', 'RES_H2 6')], tags=['anger'], trig=['anger', 'angry', 'rage', 'shouting'])
    A('islamic', "Allah tells believers to live with their spouses honourably, and reminds them He may place great good in something they dislike. Before any door closes, He asks for patience and fairness.", src=[Q('4:19', 'RES_H2 2.2')], tags=['honourable', 'patience'], trig=['patience', 'fair', 'honour'])
    A('islamic', "The Prophet taught that when a servant raises their hands in dua, Allah does not return them empty. Ask Him for your home by name, in your own language, tonight.", src=[H('tirmidhi:3556', 'RES_H2 2.5'), H('abudawud:1488', 'RES_H2 2.5')], tags=['dua', 'hope'], trig=['dua', 'ask', 'hope'])

    A('family', "If someone you love is struggling in their marriage, resist the urge to take a side. Listen, lower the temperature, and help them find calm counsel.", tags=['friend', 'family-of'], src=[G], ev='C', trig=['friend', 'son', 'daughter', 'sister', 'brother'])
    A('summary', "What I've heard: {topic} is weighing on you, and you want your home to feel like home again. That hope is worth carrying carefully.", tags=['summary'], slots=['topic'])
    return [p]
