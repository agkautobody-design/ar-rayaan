from .lib import Pack
from .sources import H, Q, bg, clin, fq


def build():
    p = Pack('elder_abuse', 'support', 'elder_abuse', 'hadi',
             'Abuse or neglect of an older person: for the older person, for family and for carers under strain. Dignity first; no blame.',
             base_tags=['elder-abuse'])
    A = p.add
    EL = clin('who_elder')
    CARE = bg('RES_H1 6.1', 'Carer strain and respite as a route (brief); clinician to confirm.')

    A('orient', "I'm an app, not a care worker. I can listen and help you find the right people. Is this about you, or about an older person you care about?", tags=['opening', 'honesty'], src=[EL], ask=True)
    A('orient', "Thank you for raising it. Older people can be harmed by family, carers or others, and it is not their fault. What's happening?", tags=['opening', 'concern'], src=[EL])
    A('orient', "You can tell me at your own pace. I'll listen and won't judge. Where shall we start?", tags=['opening'], src=[EL])

    A('reflect', "It sounds like you are being treated in a way that makes you afraid or small.", tags=['older-person', 'fear'], src=[EL])
    A('reflect', "It sounds like you don't want to cause trouble for your family.", tags=['loyalty'], src=[EL])
    A('reflect', "You depend on this person, and that makes it harder to speak up.", tags=['dependence'], src=[EL])
    A('reflect', "It sounds like you're worried about someone who can't speak up for themselves.", tags=['concern', 'family-of'], src=[EL])
    A('reflect', "You are doing a lot, and it sounds like it has become too much.", tags=['carer-strain'], src=[CARE], ev='C')
    A('reflect', "It sounds like you want to do right by them and you are worn out.", tags=['carer-strain', 'guilt'], src=[CARE], ev='C')

    A('ask', "Are you, or is the person, safe right now?", tags=['safety-check'], risk='high', src=[EL], ask=True)
    A('ask', "What have you noticed, such as injuries, money going missing, being left alone, or fear of someone?", tags=['signs'], src=[EL], dns=['One list question; do not press for names.'])
    A('ask', "Who else is involved in their care, and who could you talk to?", tags=['support'], src=[EL])
    A('ask', "What would help most right now: someone to talk to, a break, or advice on who to contact?", tags=['choice'], src=[CARE], ev='C')
    A('ask', "Is the person able to make their own decisions, and do they know you are asking for help?", tags=['capacity'], src=[EL], ev='C', dns=['Do not assume; leave to a professional.'])

    A('affirm', "Speaking up for someone who can't is a kindness.", tags=['effort'], src=[EL])
    A('affirm', "Asking for help for yourself as a carer is not failing.", tags=['carer', 'effort'], src=[CARE], ev='C')
    A('affirm', "Thank you for telling me. It's not easy.", tags=['effort'], src=[EL])

    A('explain', "Abuse of older people includes hitting, neglect, taking their money, controlling them, and frightening or humiliating them. Most of the time it's done by someone the person knows.", tags=['definition'], src=[EL], trig=['what counts as abuse', 'is this abuse'])
    A('explain', "Money problems around an older person, such as bank cards used without their say, are a common form of harm. A helpline or the bank can advise.", tags=['financial'], src=[EL], trig=['taking his money', 'bank card', 'pension'])
    A('explain', "Carers under heavy strain sometimes lose patience or neglect things without meaning to. Respite and support can help both of you. Asking for help early is better than waiting for a crisis.", tags=['carer-strain'], src=[CARE], ev='C', trig=['i snapped', 'i shouted at my mother', 'cannot cope'])
    A('explain', "Older people often don't tell anyone, because they fear losing care, or being a burden, or getting a family member into trouble. Advisors are used to this and move gently.", tags=['why-silent'], src=[EL], trig=['she won\'t say', 'he says it\'s fine'])
    A('explain', "Adult safeguarding teams, in many countries, can look into harm to older people. They decide with the person what to do, and the person's wishes matter.", tags=['safeguarding'], src=[EL, bg('RES_H1 6.1', 'Country-specific safeguarding routes were not verified; helplines.json decides what to name.')], ev='C')

    A('plan-step', "One small step: write down what you've seen, with dates, only for you. It helps the person you tell. Want to do it together?", tags=['record'], src=[EL], ask=True)
    A('plan-step', "One small step: call a helpline for older people or adult safeguarding and describe what you've noticed. They'll tell you what happens next.", tags=['report'], src=[EL], ask=True)
    A('plan-step', "One small step: ask a doctor or nurse what respite, home help or day care is available. Many families don't know it exists.", tags=['respite'], src=[CARE], ev='C', ask=True)

    A('safety', "If an older person is in danger now, or is badly hurt, call your emergency number. If there's immediate danger from someone in the home, move to somewhere safe if you can.", tags=['emergency'], src=[EL], risk='high', fixed=True, trig=['right now', 'badly hurt', 'fell and'])
    A('safety', "If you are a carer and you are afraid you might hurt the person you look after, please step away, get support, and contact a doctor or helpline today. You are not a bad person for saying so.", tags=['carer', 'risk-of-harm'], src=[CARE], ev='C', risk='high', fixed=True, trig=['i might hurt', 'i hit my mother', 'i hit my father'])

    A('referral', "A helpline for older people can listen and tell you what support exists. The lines for your country are listed below.", tags=['helpline'], fixed=True, dns=['Join with helplines.json; mark honestly where no verified line exists.'], trig=['helpline', 'who can i call'])
    A('referral', "A doctor, a district nurse or a social worker can arrange help at home or respite for a carer. You can say: \"I need support to keep caring safely.\"", tags=['doctor', 'script'], src=[CARE], ev='C', fixed=True)

    A('islamic', "The Qur'an commands kindness to parents and tells people never to speak harshly to them, even in old age. Honouring them includes protecting them from harm and also getting help when it is too much.", src=[Q('17:23-24', 'RES_H2 5.4'), Q('31:14', 'RES_H2 5.4')], tags=['parents', 'honour'], trig=['my parents', 'my mother', 'my father'])
    A('islamic', "The Prophet taught mercy toward the young and respect for the old. Neglect and humiliation of an elder are against that.", src=[H('abudawud:4943', 'RES_H2 5.4'), H('tirmidhi:1919', 'RES_H2 5.4')], tags=['mercy', 'elders'], trig=['it is the way we do it', 'what is wrong with it'])
    A('islamic', "A carer who is struggling is not failing in duty. Asking for help so that you can keep serving safely is in keeping with the Prophet's saying that the religion is easy.", src=[H('bukhari:39', 'RES_H2 2.2'), H('bukhari:6125', 'RES_H2 2.2')], tags=['ease', 'carer'], trig=['i am a bad son', 'i am a bad daughter', 'it is my duty'])
    A('islamic', "The Prophet said that Allah has forbidden oppression. Protecting a vulnerable person from harm is part of what Islam asks of us, even when the harm comes from within the family.", src=[H('muslim:2577', 'RES_H2 5.1'), H('bukhari:2444', 'RES_H2 5.1')], tags=['oppression'], trig=['family matter', 'it is private'])
    A('islamic', "If you want advice on whether a care home, home help or a shared family arrangement is acceptable, scholars differ, and I can't give a ruling. A scholar can advise you and a social worker can advise on the practical side.", src=[fq('Scholars differ on residential care for parents; no source opened for this brief', 'RES_H2 5.4', 'institution')], tags=['care-home', 'fiqh', 'scholar-handoff'], disputed=True, schools=['hanafi', 'maliki', 'shafii', 'hanbali'], ev='D', trig=['care home', 'nursing home', 'is it haram to put my mother'])

    A('family', "If you are the child or relative of an older person who is being harmed, you can raise it gently with them, and tell a professional. You do not need proof.", tags=['family-of'], src=[EL], ev='C')
    A('summary', "What I've heard: {topic} is worrying you, you want the older person to be safe and respected, and you want to know who can help.", tags=['summary'], slots=['topic'], src=[EL])
    return [p]
