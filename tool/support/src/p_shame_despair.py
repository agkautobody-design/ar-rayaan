from .lib import Pack
from .sources import H, Q, bg, clin, fq


def build():
    p = Pack('shame_despair', 'support', 'shame', 'hadi',
             'Shame, guilt, hopelessness, feeling beyond forgiveness and thoughts of ending life: listen first, ask directly about suicide, hand over to crisis lines and doctors.',
             base_tags=['shame', 'despair'])
    A = p.add
    SU, MH, AF = clin('who_suicide'), clin('who_mhgap'), clin('afsp')

    A('orient', "I'm an app, not a doctor or a counsellor. I'll listen without judging. You can say anything here. What's weighing on you?", tags=['opening', 'honesty'])
    A('orient', "It sounds like things feel very heavy. I'm here. Tell me what's been happening, in your own words.", tags=['opening'])
    A('orient', "You don't have to have the right words. Start anywhere.", tags=['opening'])

    A('reflect', "It sounds like you feel ashamed of yourself.", tags=['shame'])
    A('reflect', "It sounds like you feel you have let everyone down, including Allah.", tags=['guilt', 'faith'])
    A('reflect', "Things feel hopeless, and you can't see a way out.", tags=['hopelessness'])
    A('reflect', "You are exhausted by carrying this.", tags=['exhaustion'])
    A('reflect', "It sounds like you feel you don't deserve help.", tags=['worthlessness'])
    A('reflect', "You are lonely with this.", tags=['isolation'])
    A('reflect', "It sounds like you've been hard on yourself for a long time.", tags=['self-criticism'])
    A('reflect', "Part of you is still reaching out, and I'm glad.", tags=['hope', 'effort'])

    A('ask', "Are you having thoughts of ending your life?", tags=['suicide-check'], risk='high', ask=True, src=[AF, MH, SU], dns=['Ask directly, once, without softening; never "you are not thinking of doing something silly".', 'If yes or unsure, go to the crisis flow at once.'])
    A('ask', "Do you have a plan, or the means to hurt yourself nearby?", tags=['suicide-check'], risk='high', ask=True, src=[MH], dns=['Only after a yes; do not ask for method details; go to the safety card.'], stage=['crisis'])
    A('ask', "Is someone with you right now, or could someone be?", tags=['safety'], risk='high', src=[MH], ask=True, stage=['crisis'])
    A('ask', "What has made it feel this heavy lately?", tags=['explore'])
    A('ask', "When did you last feel even a little lighter?", tags=['strengths', 'hope'])
    A('ask', "Who knows how you're feeling?", tags=['support'], dns=['Never push disclosure.'])
    A('ask', "What would help you get through tonight?", tags=['safety-plan'], src=[MH])

    A('affirm', "Telling me is not weakness.", tags=['effort'])
    A('affirm', "I'm glad you said it out loud.", tags=['effort'])
    A('affirm', "You're still here and still talking. That matters.", tags=['effort', 'hope'])

    A('explain', "Feeling this way can make everything look hopeless, but those feelings can change, especially with support. Many people who felt like this are glad they got through it.", tags=['hope', 'treatment'], src=[SU], ev='B', trig=['no hope', 'it will never change'])
    A('explain', "Shame tells you that you are the problem. Guilt says you did something wrong. They are different, and shame is not a fair judge of who you are.", tags=['shame-guilt'], src=[bg('RES_H1 3.10', 'Shame versus guilt distinction is standard counselling content; clinician to confirm.')], ev='C', trig=['i hate myself', 'i am disgusting'])
    A('explain', "Low mood, worry and sleeplessness are common and treatable. A doctor can help, and a talking therapy or medicine may help. You can ask for either, or both.", tags=['depression', 'treatment'], src=[SU, MH], ev='B', trig=['depressed', 'cannot sleep', 'anxious'], dns=['No diagnosis, no medicine names.'])
    A('explain', "Reaching out for help is something many people find hard. You've done it just now.", tags=['effort'])
    A('explain', "Thoughts of ending your life are more common than people think, and they don't mean you will act on them. They are a sign you need more support, and there are people who can give it.", tags=['suicide', 'normalising'], src=[SU, AF], ev='B', trig=['thoughts of suicide', 'wish i was dead'])

    A('plan-step', "One small step: tell one person you trust that you're not okay. It can be one sentence. Shall we work out what to say?", tags=['disclosure-choice'], ask=True, src=[MH], dns=['Offer, never demand.'])
    A('plan-step', "One small step: put distance between you and anything you could use to hurt yourself tonight, or ask someone to hold it. Can you do that?", tags=['means-safety'], ask=True, src=[MH, AF], risk='high', dns=['No method names.'])
    A('plan-step', "One small step: make an appointment with a doctor and say, \"I haven't been coping.\" That is enough.", tags=['doctor', 'script'], ask=True, src=[MH])
    A('plan-step', "One small step: for the next hour, be in a room with other people, or on the phone with someone. Isolation makes it worse.", tags=['company'], ask=True, src=[MH], ev='C')

    A('safety', "If you are thinking about ending your life, please contact your emergency number or a crisis line now. You don't have to be sure. If you can, don't be alone, and stay away from anything you could use to hurt yourself.", tags=['suicide', 'crisis'], src=[SU, MH, AF], risk='high', fixed=True,
      trig=['kill myself', 'want to die', 'end my life', 'suicide', 'better off dead'], dns=['Join with helplines.json scope suicide. Never leave the person with only a rebuttal.'], stage=['crisis'])
    A('safety', "If you have already taken something or hurt yourself, call your emergency number now. Telling someone is the next thing to do.", tags=['suicide', 'emergency'], src=[MH, SU], risk='high', fixed=True, trig=['i took pills', 'i cut myself', 'i have taken'], stage=['crisis'])
    A('safety', "If you can't stay safe tonight, please call your emergency number or go to an emergency department. You deserve care, not shame.", tags=['suicide', 'emergency'], src=[MH], risk='high', fixed=True, stage=['crisis'])

    A('referral', "A crisis line can listen at any hour, for free. The lines for your country are listed below, and I can show them again any time.", tags=['helpline'], dns=['Join with helplines.json scope suicide; verified only.'], fixed=True, trig=['helpline', 'who can i call'])
    A('referral', "A doctor can help with how you're feeling. You can say: \"I've been feeling hopeless and I need help.\"", tags=['doctor', 'script'], src=[MH], fixed=True)
    A('referral', "If it would help to talk to someone who understands your faith, some Muslim counsellors and helplines take calls like this. The list below shows what exists in your country.", tags=['muslim-counsellor'], dns=['Only verified services.'], fixed=True)

    A('islamic', "The Qur'an tells people who have wronged themselves not to despair of Allah's mercy, for He forgives all sins. Feeling beyond forgiveness is a feeling, not a fact.", src=[Q('39:53'), Q('4:28')], tags=['mercy', 'despair'], trig=['allah will not forgive me', 'beyond forgiveness', 'too late'])
    A('islamic', "The Prophet taught that Allah is more pleased with the repentance of His servant than a man who finds his lost camel in the desert. Turning back is always welcome.", src=[H('bukhari:6308', 'RES_H2 1.1'), H('muslim:2744', 'RES_H2 1.1')], tags=['tawbah', 'mercy'], trig=['again', 'i keep falling'])
    A('islamic', "The Prophet taught that no fatigue, sorrow, sadness or hurt befalls a believer without Allah wiping away some of their sins. Hard feelings are not a sign Allah has left you.", src=[H('bukhari:5641', 'RES_H2 2.2')], tags=['hardship', 'mercy'], trig=['allah is punishing me', 'why is allah doing this'])
    A('islamic', "Illness of the mind or heart is an illness like any other. The Prophet encouraged seeking treatment, so seeing a doctor or counsellor is in keeping with the faith.", src=[H('tirmidhi:2038', 'RES_H2 2.5'), H('ibnmajah:3438', 'RES_H2 2.5')], tags=['treatment', 'mental-health'], trig=['is therapy haram', 'is it a lack of faith'])
    A('islamic', "The Prophet taught that none of you should wish for death because of a hardship. If it feels that way, please reach out now. Allah's mercy is bigger than the feeling.", src=[H('bukhari:5671', 'RES_H2 4.5')], tags=['suicide', 'mercy'], risk='high', trig=['wish i was dead', 'i want to die'], dns=['Never use as the only response; always join with crisis support.'])
    A('islamic', "Scholars differ on some questions about suicide and its consequences, and I can't give a ruling. What I can tell you is that you are loved, you matter, and there is help tonight.", src=[fq('Scholars differ on the ruling and consequences; no source opened for this brief', 'RES_H2 4.5', 'institution')], tags=['suicide', 'fiqh'], disputed=True, schools=['hanafi', 'maliki', 'shafii', 'hanbali'], ev='D', risk='high', trig=['will i go to hell if i', 'is suicide unforgivable'], dns=['Never describe what happens after death to someone at risk.'])

    A('family', "If someone you love says they feel hopeless, ask them directly if they're thinking of ending their life. Asking doesn't plant the idea. Listen, stay with them, and help them reach a crisis line or a doctor.", tags=['family-of', 'suicide'], src=[AF, MH], risk='high')
    A('summary', "What I've heard: it feels very heavy, you feel {topic}, and you want some relief. Let's make sure you have someone to turn to tonight.", tags=['summary'], slots=['topic'], src=[MH])
    return [p]
