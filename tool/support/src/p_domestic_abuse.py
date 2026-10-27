from .lib import Pack
from .sources import H, Q, bg, clin, fq


def build():
    p = Pack('domestic_abuse', 'support', 'domestic_abuse', 'hadi',
             'Abuse by a partner or family member at home: safety first, privacy, options without pressure, faith used for care and never as pressure to stay or to endure.',
             base_tags=['domestic-abuse'])
    A = p.add
    VAW, MWN, PF = clin('who_vaw'), clin('mwn'), clin('peaceful')
    SP = bg('RES_H1 6', 'Safety planning content (a bag, documents, a trusted person, phone safety) is standard domestic-abuse practice; the brief gave no single source; safeguarding and clinician to confirm.')
    STR = bg('RES_H1 6', 'Strangulation, threats to kill and escalation are standard high-risk markers in domestic-abuse practice (no source opened); safeguarding to confirm.')

    A('orient', "First, is it safe to talk right now? If someone could see this screen, you can close it any time, and nothing here is shown to anyone. I'm an app, not a counsellor.", tags=['opening', 'privacy', 'safety-first'], risk='high', src=[VAW], ask=True)
    A('orient', "You don't have to explain everything. I can listen, and I can show you people who help in confidence. What would you like to share?", tags=['opening', 'honesty'], src=[VAW])
    A('orient', "Whatever is happening, it isn't your fault. I'm here to listen without judging. Where would you like to begin?", tags=['opening', 'not-your-fault'], src=[VAW])

    A('reflect', "It sounds like you are frightened in your own home.", tags=['fear'], src=[VAW])
    A('reflect', "You've been trying to keep the peace for a long time.", tags=['coping'], src=[VAW])
    A('reflect', "It sounds like you're doubting yourself because of how you are spoken to.", tags=['emotional-abuse'], src=[VAW])
    A('reflect', "You love this person, and you are also afraid of them. Both can be true.", tags=['ambivalence'], src=[VAW])
    A('reflect', "It sounds like you feel alone and watched.", tags=['isolation', 'control'], src=[VAW])
    A('reflect', "You are worried about the children seeing this.", tags=['children'], src=[VAW])
    A('reflect', "You are tired of making excuses for what happens.", tags=['normalising'], src=[VAW])

    A('ask', "Are you safe right now?", tags=['safety-check'], risk='high', src=[VAW], ask=True, dns=['One question only; if no, go to the safety card; do not ask for details.'])
    A('ask', "Would it help to talk about what has been happening, or about what you could do next?", tags=['choice'], src=[VAW], dns=['Two options only; person chooses.'])
    A('ask', "Is there someone you trust who could be with you, or whom you could go to if you needed to?", tags=['support', 'safety-plan'], src=[SP], ev='C', dns=['Never push disclosure to family or community leaders; some may side with the person causing harm.'])
    A('ask', "Does the person ever try to control where you go, who you see, your phone or your money?", tags=['coercive-control'], src=[VAW], ask=True)
    A('ask', "Have there been times when you were afraid for your life, such as being choked or threatened with a weapon?", tags=['high-risk'], risk='high', src=[STR], ev='C', ask=True, dns=['If yes, go to the safety card at once.'])
    A('ask', "What matters most to you right now?", tags=['values', 'choice'], src=[VAW])

    A('affirm', "Telling someone takes enormous courage.", tags=['effort'], src=[VAW])
    A('affirm', "You are not overreacting.", tags=['validation'], src=[VAW])
    A('affirm', "What you are feeling makes sense.", tags=['validation'], src=[VAW])

    A('explain', "Abuse is not only hitting. Insults, threats, controlling money and phone, and forcing sex are abuse too. None of it is deserved.", tags=['definition'], src=[VAW], trig=['he doesn\'t hit me', 'only shouts', 'is this abuse'])
    A('explain', "Abuse often gets worse over time, and leaving can be the most dangerous time. That's why planning with a trained advisor matters. You decide what's right for you.", tags=['risk', 'planning'], src=[VAW, SP], ev='C', risk='medium', trig=['should i leave', 'if i leave'],
      dns=['Never tell someone to leave or to stay.'])
    A('explain', "Many people who are abused stay for reasons that make sense: love, fear, children, money, family, faith. Staying isn't a failure and neither is leaving.", tags=['staying'], src=[VAW], trig=['why do i stay', 'why don\'t i leave'])
    A('explain', "Advisors at specialist services can help with safety planning, housing, legal protection and your children. They keep what you say confidential, within the limits they will tell you.", tags=['services'], src=[VAW, MWN], trig=['what can they do', 'who can help'])
    A('explain', "Abuse harms children even when they are not hit, and they often see and hear more than adults think. Their wellbeing is something advisors can help you plan around.", tags=['children'], src=[clin('who_cm')], trig=['children saw', 'the kids'])

    A('plan-step', "One small step: think of one safe person and one safe place you could go to quickly, if you needed to. You don't have to use them. Shall we think it through?", tags=['safety-plan'], src=[SP], ev='C', ask=True)
    A('plan-step', "One small step: if it's safe, keep ID, money and a spare phone charger somewhere you can reach fast, like with a trusted person. A specialist advisor can help you plan the rest.", tags=['safety-plan', 'documents'], src=[SP], ev='C', ask=True)
    A('plan-step', "One small step: call a helpline when you are alone and it's safe, just to ask questions. You don't have to decide anything.", tags=['helpline'], src=[VAW], ask=True)
    A('plan-step', "One small step: if your phone could be checked, think about whether you can delete this chat or use a friend's phone to call. I can't see your phone, so you know best.", tags=['phone-safety'], src=[SP], ev='C', ask=True)

    A('safety', "If you are in danger now, call your emergency number. If it isn't safe to speak, many places let you press a key or stay on the line. Get to a room with a door that locks, or leave if you can do so safely.", tags=['emergency'], src=[VAW], risk='high', fixed=True,
      trig=['he is going to kill me', 'right now', 'locked me in', 'in danger now'], dns=['Never tell the person to stay and talk it through.'])
    A('safety', "If someone has choked you, threatened to kill you, or the attacks are getting worse, please get urgent help from a specialist service or the police. These are signs of serious danger.", tags=['high-risk', 'strangulation'], src=[STR], ev='C', risk='high', fixed=True, trig=['choked me', 'strangled', 'threatened to kill'])
    A('safety', "If you are hurt, please get medical care. You can say what happened, or you can say less. A doctor or nurse can help, and many places have staff trained in this.", tags=['injury', 'medical'], src=[VAW], ev='C', risk='high', fixed=True)

    A('referral', "A domestic abuse helpline can talk through your options in confidence, any time you are ready. The lines for your country are listed below, and I can show them again.", tags=['helpline'], dns=['Join with helplines.json scope domestic abuse; never type a number; flag lines not verified.'], fixed=True, trig=['helpline', 'who can i call'])
    A('referral', "Some services are run by and for Muslim women, and understand faith, family and community pressures. The list below shows what exists in your country.", tags=['muslim-services'], src=[MWN, PF], dns=['Only verified services; some Muslim organisations may be affected by community pressure, so offer alongside non-faith services.'], trig=['muslim women', 'islamic'])
    A('referral', "If you want to speak to a scholar about your situation, it is better to choose one who understands abuse and will put your safety first. A specialist service can often suggest one.", tags=['scholar-handoff'], src=[PF], ev='C', trig=['imam', 'scholar', 'is it haram to leave'])

    A('islamic', "Islam does not allow anyone to harm another. The Prophet said that Allah has forbidden oppression, and that the best of people are those who are best to their families.", src=[H('muslim:2577', 'RES_H2 5.1'), H('tirmidhi:3895', 'RES_H2 5.1')], tags=['oppression', 'family'], trig=['islam allows', 'is it my fault'])
    A('islamic', "The Prophet's wife Aisha said he never struck anyone with his hand, neither a servant nor a woman. Violence is not the example he gave.", src=[H('muslim:2328', 'RES_H2 5.1')], tags=['example'], trig=['he says islam lets him', 'a husband can hit'], dns=['Never discuss Qur\'an 4:34 in the app; scholars differ and the app does not issue a fiqh ruling. Refer to a scholar who understands abuse.'])
    A('islamic', "The Qur'an commands living with your spouse in kindness, and forbids holding someone back in order to harm them. Marriage in Islam is meant to be a place of mercy.", src=[Q('4:19', 'RES_H2 5.1'), Q('2:231', 'RES_H2 5.1'), Q('30:21', 'RES_H2 5.1')], tags=['marriage', 'mercy'], trig=['marriage', 'my husband says'])
    A('islamic', "When women came to complain about their husbands, the Prophet said such men are not the best of people. Reaching out for help is not disloyal.", src=[H('abudawud:2146', 'RES_H2 5.1'), H('ibnmajah:1985', 'RES_H2 5.1')], tags=['complaint', 'help-seeking'], trig=['complain', 'shame on the family'])
    A('islamic', "Patience in Islam never means accepting harm. You can ask for help and protect yourself and your children, and still trust Allah. The Prophet said to tie your camel and trust.", src=[H('tirmidhi:2517', 'RES_H2 2.5')], tags=['sabr', 'action'], trig=['be patient', 'sabr', 'just pray'])
    A('islamic', "Scholars differ on questions such as when a wife can seek separation or end the marriage, and the schools give different details. I can't give a ruling, and a scholar who understands abuse can advise you on your situation.", src=[fq('Scholars differ on grounds and procedure for khul\' and faskh; no source opened for this brief', 'RES_H2 5.2', 'institution')], tags=['divorce', 'fiqh', 'scholar-handoff'], disputed=True, schools=['hanafi', 'maliki', 'shafii', 'hanbali'], ev='D',
      trig=['is divorce haram', 'can i leave my husband', 'khula'], dns=['Never say "you must stay" or "you must leave".'])

    A('family', "If you are worried about someone you love, listen without blaming, and tell them you believe them. Let them choose the pace. If they are in danger, a specialist service can advise you on how to help safely.", tags=['friend', 'family-of'], src=[VAW], trig=['my sister', 'my friend', 'my daughter'])
    A('summary', "What I've heard: you are afraid, {topic} is part of it, and you want to know what you can do. The next step is yours, and help is there when you want it.", tags=['summary'], slots=['topic'], src=[VAW])
    return [p]
