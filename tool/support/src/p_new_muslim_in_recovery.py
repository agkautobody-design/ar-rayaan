from .lib import Pack
from .sources import H, Q, bg, clin, fq


def build():
    p = Pack('new_muslim_in_recovery', 'support', 'new_muslim', 'hadi',
             'A person new to Islam who is also in or near recovery: old habits, old friends, family reactions, fear of getting it wrong, gentle stages.',
             base_tags=['new-muslim'])
    A = p.add
    CORE = clin('niaaa_core')
    NM = bg('RES_H1 4.1', 'New-Muslim experience of old habits and old social circles: brief background; no source opened; clinician to confirm.')

    A('orient', "Welcome. I'm an app, not a scholar or a counsellor. I can listen, and I can help you find people who know both Islam and recovery. What's on your mind?", tags=['opening', 'honesty'])
    A('orient', "Being new to Islam and trying to change habits at the same time is a lot. You can go at your own pace. Where would you like to start?", tags=['opening', 'pace'])
    A('orient', "There is no test here. You can ask anything, big or small. What would help most?", tags=['opening'])

    A('reflect', "It sounds like you're afraid of getting it wrong.", tags=['fear'])
    A('reflect', "You're proud of the step you've taken, and also scared you'll slip.", tags=['ambivalence'])
    A('reflect', "It sounds like your old friends and your new faith pull in different directions.", tags=['social'])
    A('reflect', "You feel you have to be perfect straight away.", tags=['perfectionism'])
    A('reflect', "It sounds like your family isn't sure about the change.", tags=['family'])
    A('reflect', "You miss the old life in some ways, and you want the new one.", tags=['ambivalence'])
    A('reflect', "It sounds like you feel you don't fit in at the mosque yet.", tags=['belonging'])

    A('ask', "What brought you to Islam, if you'd like to share?", tags=['story'])
    A('ask', "What's the hardest part of the change right now?", tags=['explore'])
    A('ask', "Who has welcomed you so far, a person, a group or a mosque?", tags=['support'])
    A('ask', "Which old habit worries you most?", tags=['habit'])
    A('ask', "What would make this week a little easier?", tags=['goal'])

    A('affirm', "Coming to a new faith takes courage.", tags=['effort'])
    A('affirm', "You don't have to know everything. Asking is a good sign.", tags=['effort'])
    A('affirm', "You are exactly where you need to start.", tags=['validation'])

    A('explain', "Islam asks for steps you can manage, not perfection overnight. Many new Muslims start small, with the basics, and learn the rest with time.", tags=['stages'], src=[NM], ev='C', trig=['do i have to do everything', 'too much to learn'])
    A('explain', "Old friends and places can be strong triggers for old habits. It can help to spend time with people who support your recovery, and to find a welcoming community at your own pace.", tags=['social', 'trigger'], src=[CORE, NM], ev='C', trig=['my old friends', 'old crowd'])
    A('explain', "If you used to drink or use drugs, ask a doctor before changing anything about your use, even for religious reasons, because stopping suddenly can be dangerous.", tags=['safety', 'withdrawal'], src=[clin('niaaa_cut'), clin('benzo')], risk='high', trig=['i have to stop now', 'cold turkey for allah'])
    A('explain', "Many mosques have a welcoming person for new Muslims, and some towns have new-Muslim support groups. You can ask for someone to sit with you and explain.", tags=['community', 'welcome'], src=[NM], ev='C', trig=['no one to talk to', 'mosque'])
    A('explain', "Families sometimes react with worry or anger to a conversion. Giving them time, staying kind and keeping some calm space often helps.", tags=['family'], src=[NM], ev='C', trig=['my family doesn\'t accept', 'parents angry'])

    A('plan-step', "One small step: choose one new thing to learn this week, like one short surah or one way to make wudu. Shall we pick it together?", tags=['learning'], ask=True)
    A('plan-step', "One small step: find one person, online or in person, who is also new to Islam, and say hello. I can help you find ideas.", tags=['community'], ask=True)
    A('plan-step', "One small step: tell your doctor or counsellor about your change if it feels safe. They can fit support around it.", tags=['doctor'], ask=True, src=[CORE], ev='C')

    A('safety', "If you drink or use drugs most days, please don't stop suddenly because of a new religious commitment, because that can be dangerous. See a doctor first so stopping can be made safer.", tags=['withdrawal', 'alcohol', 'safety'], src=[clin('niaaa_cut'), clin('nice_cg100'), clin('benzo')], risk='high', fixed=True, trig=['quit alcohol today', 'stop everything now'])
    A('safety', "If you feel you've lost everything, such as family, friends and old life, and you feel you can't go on, please contact a crisis line or your emergency number now.", tags=['suicide', 'crisis'], src=[clin('who_suicide'), clin('who_mhgap')], risk='high', fixed=True, trig=['lost my family', 'disowned', 'kill myself'], stage=['crisis'], dns=['Join with helplines.json scope suicide.'])

    A('referral', "A new-Muslim support group, or a convert-friendly mosque or organisation, can give practical help. The list below shows what exists in your country.", tags=['new-muslim-support'], dns=['Only verified services.'], fixed=True)
    A('referral', "A Muslim counsellor can understand both recovery and your new faith. The list below shows what exists in your country.", tags=['muslim-counsellor'], dns=['Only verified services.'], fixed=True)

    A('islamic', "The Prophet told of a man who had done terrible things, asked if he could repent, and was told to go to a land of righteous people. A new beginning, in a new place and among new people, is something Islam welcomes.", src=[H('bukhari:3470', 'RES_H2 1.1'), H('muslim:2766', 'RES_H2 1.1')], tags=['fresh-start', 'environment'], trig=['my past', 'what i did before', 'is my past forgiven'])
    A('islamic', "The Prophet taught that the religion is easy, and that no one makes it harder for themselves without it overpowering them. Take it step by step.", src=[H('bukhari:39', 'RES_H2 2.2')], tags=['ease', 'stages'], trig=['i can\'t keep up', 'i\'m behind'])
    A('islamic', "The Prophet said, make things easy and do not make them hard. This applies to how you treat yourself as a new Muslim, too.", src=[H('bukhari:6125', 'RES_H2 2.2')], tags=['ease'], trig=['too strict with myself'])
    A('islamic', "The Qur'an says that Allah does not burden a soul beyond what it can bear. Your pace is part of His mercy, not a failure.", src=[Q('2:286', 'RES_H2 2.2')], tags=['ease', 'mercy'], trig=['not good enough'])
    A('islamic', "Scholars differ on a few practical questions for new Muslims, such as old financial arrangements and family ties across faiths, and I can't give a ruling. A scholar who works with new Muslims can advise you.", src=[fq('Scholars differ on practical questions for new Muslims; no source opened for this brief', 'RES_H2 1.3', 'institution')], tags=['fiqh', 'scholar-handoff'], disputed=True, schools=['hanafi', 'maliki', 'shafii', 'hanbali'], ev='D', trig=['my mortgage', 'my non-muslim family', 'ruling'])

    A('family', "If someone close to you has come to Islam, listen to why, stay kind, and let them tell you at their pace. If they are struggling with old habits, support them without shaming.", tags=['family-of'], src=[NM], ev='C')
    A('summary', "What I've heard: you're new to Islam, {topic} is hard right now, and you want to do this well without rushing. Small steps are enough.", tags=['summary'], slots=['topic'])
    return [p]
