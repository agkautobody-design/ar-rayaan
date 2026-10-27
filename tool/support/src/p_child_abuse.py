from .lib import Pack
from .sources import H, Q, bg, clin, fq


def build():
    p = Pack('child_abuse', 'support', 'child_abuse', 'both',
             'Child abuse and neglect: for adults worried about a child, and short, safe lines for children and teens. Report-first, never investigate, never promise secrecy.',
             ages=('adult', '9-12', '13-17'), base_tags=['child-abuse'])
    A = p.add
    CM, CH = clin('who_cm'), clin('childhelp')
    SG = bg('RES_H1 10.1', 'Do not interrogate a child, do not promise secrecy, write down what the child said and report to the child-protection service: standard safeguarding practice (brief); safeguarding review required.')

    # adults
    A('orient', "I'm an app, not a child-protection worker. I can listen, help you think, and show you who to contact. Is this about a child you are worried about, or about something that happened to you as a child?", tags=['opening', 'honesty'], src=[CM], ask=True)
    A('orient', "Thank you for caring enough to ask. You don't need proof to be worried. What have you noticed?", tags=['opening', 'concern'], src=[CM])
    A('orient', "Whichever it is, you can tell me as much or as little as you like. I'll listen first. Where shall we begin?", tags=['opening'], src=[CM])

    A('reflect', "It sounds like something has been worrying you about this child.", tags=['concern'], src=[CM])
    A('reflect', "You're afraid of getting it wrong, and afraid of doing nothing.", tags=['ambivalence'], src=[CM])
    A('reflect', "It sounds like a lot to carry.", tags=['burden'], src=[CM])
    A('reflect', "You noticed something, and you are taking it seriously.", tags=['validation'], src=[CM])
    A('reflect', "It sounds like what happened to you has stayed with you for a long time.", tags=['survivor'], src=[CM])
    A('reflect', "You may have wondered if it was your fault. It was not.", tags=['survivor', 'not-your-fault'], src=[CM])

    A('ask', "Is the child safe at this moment?", tags=['safety-check'], risk='high', src=[SG], ev='C', ask=True, dns=['If no, go to the safety card.'])
    A('ask', "What have you seen or heard that worries you?", tags=['listen'], src=[SG], ev='C', dns=['Do not push for details; do not ask for the child\'s name.'])
    A('ask', "Has the child said anything to you, or have you only noticed things?", tags=['disclosure'], src=[SG], ev='C')
    A('ask', "Who is the child with most of the time, and who else could you ask for help?", tags=['support'], src=[SG], ev='C')
    A('ask', "Is this about something that happened to you when you were younger, and would you like to talk about that?", tags=['survivor'], src=[CM], ask=True)

    A('affirm', "Being willing to act for a child is a good thing.", tags=['effort'], src=[CM])
    A('affirm', "You don't have to be sure. Raising a concern is enough.", tags=['effort', 'permission'], src=[SG], ev='C')

    A('explain', "You don't have to be certain to ask for advice. Child-protection services can listen to a worry and decide what to do next. That is their job, not yours.", tags=['reporting'], src=[CM, SG], ev='C', trig=['not sure', 'what if i am wrong'])
    A('explain', "If a child tells you something, stay calm, listen, tell them you believe them and that it isn't their fault, and don't promise that you will tell no one. Then pass it to the child-protection service.", tags=['disclosure', 'response'], src=[SG], ev='C', trig=['she told me', 'he told me', 'child told me'])
    A('explain', "Abuse and neglect can be physical, emotional, sexual, or not meeting a child's basic needs. Signs vary, and no single sign proves anything.", tags=['definition'], src=[CM], trig=['signs of abuse', 'what counts'])
    A('explain', "Children are more likely to be harmed by someone they know. That is one reason it can feel so hard to say something, and one reason it matters.", tags=['known-person'], src=[CM], trig=['family member', 'relative', 'teacher', 'imam'])
    A('explain', "What happened to you as a child was not your fault, whatever you did or didn't do. Many survivors find that talking to a trained counsellor helps, at their own pace.", tags=['survivor', 'treatment'], src=[CM, bg('RES_H1 6', 'Survivor support: counsellor at own pace (brief); clinician to confirm.')], ev='C', trig=['when i was a child', 'abused as a child'])

    A('plan-step', "One small step: write down, only for yourself, what you saw or heard, with dates if you can. Don't question the child. This helps the person you tell.", tags=['record'], src=[SG], ev='C', ask=True)
    A('plan-step', "One small step: contact the child-protection line for your country and describe your worry. They will tell you what happens next. I can show you the lines.", tags=['report'], src=[CM, CH], ask=True)

    A('safety', "If a child is in danger right now, call your emergency number. Don't confront the person who may be harming them, and keep the child out of harm's way if you can do so safely.", tags=['emergency'], src=[CM], risk='high', fixed=True, trig=['right now', 'he is hurting', 'she is being hurt'])
    A('safety', "If a child tells you about abuse, you can't promise to tell no one, because you need to get them help. You can say: \"I believe you, it's not your fault, and I'm going to get help for you.\"", tags=['disclosure', 'secrecy'], src=[SG], risk='high', ev='C', fixed=True)

    A('referral', "A child-protection or children's helpline can advise on a worry and take a report. The lines for your country are listed below.", tags=['helpline'], src=[CH], fixed=True, dns=['Join with helplines.json scope child; separate from adult lines.'], trig=['helpline', 'who do i call'])
    A('referral', "If it happened to you, a specialist counsellor can help in confidence. A helpline can also direct you.", tags=['survivor', 'counsellor'], src=[CM], fixed=True)

    # children (short, no parent-only routing)
    A('reflect', "That sounds really hard. I'm glad you told me.", tags=['child', 'validation'], age=['9-12'], src=[CM, SG], ev='C')
    A('reflect', "It sounds like something is making you feel scared or sad.", tags=['child'], age=['9-12'], src=[CM, SG], ev='C')
    A('safety', "It is not your fault. You are not in trouble. Please tell a grown-up you trust, like a teacher, a doctor or a relative. You can also call a children's helpline. It is free.", tags=['child', 'safety'], age=['9-12'], src=[CM, SG, CH], risk='high', ev='C', fixed=True, trig=['someone hurts me', 'it hurts', 'he touches me'])
    A('safety', "If you are in danger right now, call your emergency number. Go somewhere safe if you can. It is okay to ask for help.", tags=['child', 'emergency'], age=['9-12'], src=[CM, SG], risk='high', ev='C', fixed=True)
    A('safety', "It is not your fault, whatever has happened. You can talk to a teacher, school nurse, doctor or a trusted adult. A children's helpline is free and private. I can show you the number.", tags=['child', 'safety'], age=['13-17'], src=[CM, SG, CH], risk='high', ev='C', fixed=True, trig=['someone is hurting me', 'being abused'])
    A('referral', "A children's helpline is free and you do not have to give your name. They will listen and help you work out what to do.", tags=['child', 'helpline'], age=['9-12', '13-17'], src=[CH], risk='medium', ev='C', fixed=True, dns=['Join with helplines.json scope child.'])

    # faith
    A('islamic', "The Prophet taught that every one of you is a guardian and will be asked about those in your care. Protecting a child is a duty, not a betrayal.", src=[H('bukhari:893', 'RES_H2 5.3')], tags=['guardian', 'duty'], trig=['should i say something', 'it is a family matter'])
    A('islamic', "The Prophet said that whoever has no mercy for our young is not one of us. Gentleness with children is part of the faith.", src=[H('tirmidhi:1919', 'RES_H2 5.3'), H('abudawud:4943', 'RES_H2 5.3')], tags=['mercy', 'children'], trig=['discipline', 'i hit my child'])
    A('islamic', "Protecting a child from harm comes before protecting a name or a family's reputation. The Prophet taught that Allah has forbidden oppression.", src=[H('muslim:2577', 'RES_H2 5.1')], tags=['oppression', 'honour'], trig=['reputation', 'shame on the family', 'family honour'],
      dns=['Never "keep it within the family".'])
    A('islamic', "You do not have to carry guilt for what was done to you. The Qur'an tells those who feel burdened not to despair of Allah's mercy.", src=[Q('39:53'), Q('4:28')], tags=['survivor', 'mercy'], trig=['i feel dirty', 'i feel guilty about what happened'])
    A('islamic', "Scholars differ on discipline of children, and I can't give a ruling. Hitting a child is harmful, and a scholar who understands child protection can advise you.", src=[fq('Scholars differ on discipline; no source opened for this brief', 'RES_H2 5.3', 'institution'), CM], tags=['discipline', 'fiqh', 'scholar-handoff'], disputed=True, schools=['hanafi', 'maliki', 'shafii', 'hanbali'], ev='D', trig=['can i hit my child', 'is it allowed to smack'])

    A('family', "If a child in your family has been harmed, believe them, keep them safe, and get specialist advice. Looking after their healing comes first.", tags=['family-of'], src=[CM, SG], ev='C')
    A('summary', "What I've heard: you're worried about a child, {topic} is part of it, and you want to know who to call. The next step is to speak to a child-protection service.", tags=['summary'], slots=['topic'], src=[SG], ev='C')
    return [p]
