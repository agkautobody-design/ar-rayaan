from .lib import Pack
from .sources import H, Q, bg, clin, fq


def build():
    p = Pack('sexual_violence', 'support', 'sexual_violence', 'hadi',
             'Sexual violence, assault, coercion and rape, within or outside marriage: believe, not your fault, medical care and choice. No questions that blame, no demands to report or disclose.',
             base_tags=['sexual-violence'])
    A = p.add
    VAW = clin('who_vaw')
    MED = bg('RES_H1 6', 'Time-sensitive medical care after sexual assault (emergency contraception, infection prevention, injury) is standard practice; brief gave no single source; clinician and safeguarding to confirm.')
    PF = clin('peaceful')

    A('orient', "I'm an app, not a counsellor or a doctor. I believe you, and I'm here to listen. You can tell me as much or as little as you want, and you can stop any time.", tags=['opening', 'believe', 'honesty'], src=[VAW])
    A('orient', "Whatever happened, it was not your fault. I can listen, and I can show you people who help in confidence. What would you like?", tags=['opening', 'not-your-fault'], src=[VAW])
    A('orient', "First, are you safe right now? You do not need to say anything else yet.", tags=['opening', 'safety-first'], src=[VAW], risk='high', ask=True)

    A('reflect', "That sounds frightening and painful. I'm sorry it happened.", tags=['validation'], src=[VAW])
    A('reflect', "It took courage to say that.", tags=['validation'], src=[VAW])
    A('reflect', "It sounds like you're not sure what to call it, and it still hurt.", tags=['unsure'], src=[VAW])
    A('reflect', "It sounds like your body and your mind are still reacting to it.", tags=['trauma-response'], src=[VAW])
    A('reflect', "You feel unsafe in your own home.", tags=['fear', 'home'], src=[VAW])
    A('reflect', "It sounds like you're afraid people won't believe you.", tags=['fear', 'disbelief'], src=[VAW])
    A('reflect', "It sounds like you are carrying shame that doesn't belong to you.", tags=['shame'], src=[VAW])

    A('ask', "Are you safe right now?", tags=['safety-check'], risk='high', src=[VAW], ask=True)
    A('ask', "Would you like to talk about what you're feeling, or about what you could do next?", tags=['choice'], src=[VAW])
    A('ask', "Do you need medical care today, for an injury or for protection?", tags=['medical'], src=[MED], ev='C', risk='high', ask=True)
    A('ask', "Is there someone you trust who could be with you?", tags=['support'], src=[VAW], dns=['Never push disclosure to family or community.'])
    A('ask', "What would help you feel safer tonight?", tags=['safety-plan'], src=[VAW])

    A('affirm', "You did nothing to deserve this.", tags=['not-your-fault'], src=[VAW])
    A('affirm', "Whatever you did to survive was the right thing to do.", tags=['survival'], src=[VAW], ev='C', clinician=True)
    A('affirm', "It is okay to not be okay.", tags=['validation'], src=[VAW])

    A('explain', "Sex without your clear agreement is assault, including in marriage, and including when you froze or didn't fight back. Freezing is a common response.", tags=['definition', 'consent', 'marital'], src=[VAW, bg('RES_H1 6', 'Freeze response and marital rape as violence: standard clinical teaching; clinician to confirm.')], ev='C', trig=['my husband forced', 'in marriage', 'i froze', 'i did not say no'])
    A('explain', "Some medical care works best soon after an assault, such as treatment to protect against infection and pregnancy. A doctor or sexual assault service can explain, and you can go without reporting to the police.", tags=['medical', 'time-sensitive'], src=[MED], ev='C', risk='high', trig=['pregnant', 'morning after', 'hiv', 'std'])
    A('explain', "You do not have to report it to anyone to be given care. Whether to report is your choice, and a specialist service can talk it through with you without pressure.", tags=['reporting', 'choice'], src=[VAW], ev='C', trig=['should i tell the police', 'should i report'])
    A('explain', "It's common to feel numb, afraid, angry, ashamed, or to have trouble sleeping after sexual violence. These are normal responses to something terrible. They can ease with support.", tags=['trauma-response'], src=[VAW, bg('RES_H1 6', 'Common reactions after sexual violence: clinician to confirm.')], ev='C', trig=['cannot sleep', 'flashbacks', 'numb'])
    A('explain', "Many survivors find it helps to talk to someone trained in this, at their own pace. It isn't about reliving every detail.", tags=['counselling'], src=[VAW], trig=['therapy', 'counselling'])

    A('plan-step', "One small step: if it feels right, think of one safe person or place for tonight. You do not have to decide anything else.", tags=['safety-plan'], src=[VAW], ask=True)
    A('plan-step', "One small step: call a sexual assault helpline when you're ready, just to ask questions. You don't have to give your name.", tags=['helpline'], src=[VAW], ask=True)
    A('plan-step', "One small step: if you can, avoid washing or changing clothes until you decide about medical care. If you've already washed, it is still fine to get care.", tags=['evidence', 'medical'], src=[MED], ev='C', ask=True,
      dns=['Never insist; this is optional and the person may have already washed; clinician to confirm.'])

    A('safety', "If you are in danger now, call your emergency number or go somewhere safe. If you are hurt, please get medical care, even if you are not sure you want to report it.", tags=['emergency'], src=[VAW, MED], risk='high', fixed=True, ev='C', trig=['right now', 'he is outside', 'bleeding'])
    A('safety', "If you feel you can't go on after what has happened, please contact your emergency number or a crisis line now. You deserve care and support.", tags=['suicide', 'crisis'], src=[clin('who_suicide'), clin('who_mhgap')], risk='high', fixed=True, trig=['kill myself', 'end it', 'no point'], dns=['Join with helplines.json scope suicide.'])

    A('referral', "A sexual assault helpline or centre can talk to you in confidence, any time you're ready. The lines for your country are listed below.", tags=['helpline'], fixed=True, dns=['Join with helplines.json scope sexual violence; never type a number.'], trig=['helpline', 'who can i call'])
    A('referral', "Some services are run by and for Muslim women, and understand faith, family and community pressures. The list below shows what exists in your country.", tags=['muslim-services'], src=[clin('mwn'), PF], fixed=True, dns=['Only verified services.'], trig=['muslim women'])
    A('referral', "A doctor, a sexual assault referral centre or an emergency department can give medical care and can arrange support. You can say: \"I need care after an assault.\"", tags=['medical', 'script'], src=[MED], ev='C', fixed=True)

    A('islamic', "What was done to you against your will is not your sin. The Qur'an says Allah does not burden a soul beyond what it can bear, and tells those who feel weighed down not to despair of His mercy.", src=[Q('2:286', 'RES_H2 5.5'), Q('39:53')], tags=['not-your-fault', 'mercy'], trig=['am i sinful', 'did i commit zina', 'i feel dirty'], dns=['Never discuss zina rulings in the app.'])
    A('islamic', "The Prophet said that Allah has forbidden oppression. The shame belongs to the one who did wrong, not to the one it was done to.", src=[H('muslim:2577', 'RES_H2 5.1')], tags=['oppression', 'shame'], trig=['my family will blame me', 'they will say it is my fault'])
    A('islamic', "Protecting yourself, getting medical care and seeking justice are all permitted. Staying quiet to protect a family's name is not required of you.", src=[bg('RES_H2 5.5', 'Authored framing that medical care, protection and seeking justice are permitted; scholar to confirm.'), H('ibnmajah:3436', 'RES_H2 2.5')], tags=['help-seeking'], ev='C', scholar=True, trig=['should i stay quiet', 'family honour'], dns=['Never "keep it within the family".'])
    A('islamic', "Scholars differ on some questions people ask afterwards, such as marriage, divorce and what a family should do. I can't give a ruling, and a scholar who understands sexual violence can advise you.", src=[fq('Scholars differ on consequences and procedure; no source opened for this brief', 'RES_H2 5.5', 'institution')], tags=['fiqh', 'scholar-handoff'], disputed=True, schools=['hanafi', 'maliki', 'shafii', 'hanbali'], ev='D', trig=['is my marriage valid', 'can i get divorced', 'ruling'])
    A('islamic', "You do not have to tell anyone what happened. Scholars say that a private matter may be kept private and that you only need to tell someone who can help, to the extent needed.", src=[H('bukhari:6069', 'RES_H2 2.4'), fq('Islamweb fatwa 393796 and Darul Ifta Birmingham fatwa 08109', 'RES_H2 2.4', 'institution')], tags=['sitr', 'privacy'], trig=['should i tell my imam', 'who should i tell'])

    A('family', "If someone you love tells you they've been assaulted, believe them, tell them it isn't their fault, and let them choose what to do next. Offer to go with them to get help.", tags=['friend', 'family-of'], src=[VAW], trig=['my friend told me', 'my daughter told me', 'my wife told me'])
    A('summary', "What I've heard: something terrible happened, it was not your fault, and you want to know what comes next. You can choose the pace, and help is there.", tags=['summary'], src=[VAW])
    return [p]
