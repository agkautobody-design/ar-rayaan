from .lib import Pack
from .sources import H, Q, bg, clin, fq


def build():
    p = Pack('being_heard', 'support', 'distress', 'hadi',
             'Being heard: sadness, anxiety, loneliness, feeling far from Allah, overwhelm and comparison. Listen first; accompany; never judge, never rush to fix.',
             base_tags=['distress'])
    A = p.add
    G = bg('RES_H1 10.1', 'Emotional support: listening, validation and small steps help; persistent or disabling distress should go to a clinician. General teaching; no source opened; clinician to confirm.')
    MH = clin('who_mhgap')
    SAM = clin('samaritans')

    A('orient', "I'm glad you came here. I'm an app, not a counsellor, but I can listen for as long as you like. What's on your heart?", tags=['opening', 'honesty'])
    A('orient', "You don't need the right words here. You can start anywhere, and I will stay with it.", tags=['opening'])
    A('orient', "Thank you for saying something. Nothing has to be solved in this conversation. What would you like me to know first?", tags=['opening'])

    A('reflect', "It sounds like this has been sitting on you for a while.", tags=['heavy'])
    A('reflect', "You sound worn down by it, and still you showed up here.", tags=['exhaustion'])
    A('reflect', "It sounds lonely, carrying this without anyone to say it to.", tags=['isolation', 'lonely'], trig=['alone', 'lonely', 'nobody'])
    A('reflect', "It sounds like your mind is not giving you much rest.", tags=['fear', 'anxiety'], trig=['anxious', 'anxiety', 'worry', 'overthinking'])
    A('reflect', "You're hurting, and you're not even sure why.", tags=['sadness', 'unclear'], trig=['sad', 'cry', 'crying', 'empty', 'numb'])
    A('reflect', "It sounds like you feel far from Allah right now, and that distance hurts.", tags=['far-from-allah'], trig=['allah', 'prayer', 'praying', 'iman', 'salah'])
    A('reflect', "It sounds like everyone else's life looks easier than yours, and that comparison is crushing you.", tags=['comparison'], trig=['everyone', 'comparing', 'behind', 'instagram', 'tiktok'])
    A('reflect', "You are worried about your home and the people in it, and it is wearing you down.", tags=['concern', 'home'], trig=['home', 'family', 'marriage'])
    A('reflect', "It sounds like you needed to say it more than you needed an answer.", tags=['heard'], trig=['heard', 'listen', 'vent', 'advice'])

    A('ask', "What does a day like this actually look like for you?", tags=['story'])
    A('ask', "When did you last feel a little lighter?", tags=['exceptions'])
    A('ask', "Is there anyone in your life who knows even a piece of this?", tags=['support'])
    A('ask', "What is the heaviest part of it right now?", tags=['priority'])
    A('ask', "How are you sleeping and eating through all this?", tags=['self-care'], risk='medium')
    A('ask', "Are there moments when it gets so heavy you feel you can't go on?", tags=['safety-check'], risk='high', ask=True, src=[MH], dns=['If yes or unclear, ask directly about suicide and go to the crisis flow.'])
    A('ask', "If one small thing could be different by tonight, what would it be?", tags=['goal'])

    A('affirm', "Saying it out loud takes something. You did that.", tags=['validation'])
    A('affirm', "Carrying this and still getting through your days is not nothing.", tags=['strength'])
    A('affirm', "Wanting to be heard is not weakness. It is human.", tags=['validation'])
    A('affirm', "However tangled it feels, you are still here, still trying.", tags=['strength'])

    A('explain', "Sadness and anxiety are body and heart signals, not character flaws. They often ease with rest, food, people and time. When they do not, that is a reason to get support, not a reason for shame.", tags=['normal'], src=[G], ev='C', trig=['normal', 'wrong with me'])
    A('explain', "A mind that keeps replaying worries is trying to protect you, badly. Slow breathing, naming what you see around you, and writing the worry down can quiet it enough to sleep.", tags=['anxiety', 'coping'], src=[G, MH], ev='C', trig=['racing', 'overthinking', 'cant sleep', 'worry'])
    A('explain', "Loneliness can sit beside people too. Being surrounded and still unseen is one of the loneliest feelings there is, and it is real.", tags=['lonely'], src=[G], ev='C', trig=['alone', 'lonely', 'nobody'])
    A('explain', "Comparing your inside to other people's outside will always hurt. What you see online is a display shelf, not a life.", tags=['comparison', 'social-media'], src=[G], ev='C', trig=['everyone', 'instagram', 'tiktok', 'comparing', 'behind'])
    A('explain', "Feeling far from Allah is a feeling many sincere people go through, sometimes for a season. The feeling is not a verdict on you.", tags=['far-from-allah', 'normal'], src=[G], ev='C', trig=['allah', 'iman', 'prayer', 'praying', 'salah'])
    A('explain', "Exhaustion makes every problem look permanent. Tired people are not broken people; they are tired. Rest is part of repair, not laziness.", tags=['exhaustion'], src=[G], ev='C', trig=['tired', 'exhausted', 'drained', 'burnout'])

    A('plan-step', "One small step: send one honest sentence to one safe person today. Who comes to mind?", tags=['support'], ask=True)
    A('plan-step', "One small step: eat something, drink water, and give yourself ten minutes with no screen. Your body carries this too.", tags=['self-care'], ask=True, src=[G], ev='C')
    A('plan-step', "One small step: write down the one thing weighing most, in plain words. Getting it out of your head and onto paper shrinks it.", tags=['coping'], ask=True, src=[G], ev='C')
    A('plan-step', "One small step: make wudu slowly and sit for two quiet minutes afterwards, saying whatever is in your heart to Allah, in your own words.", tags=['far-from-allah', 'salah'], ask=True, trig=['allah', 'iman', 'prayer', 'salah'])
    A('plan-step', "One small step: take a short walk without your phone, even to the end of the street and back. Movement loosens what sitting tightens.", tags=['self-care', 'anxiety'], ask=True, src=[G], ev='C')

    A('safety', "If this heaviness ever turns into feeling you can't go on, or thoughts of ending your life, please contact your emergency number or a crisis line now. You matter, and there are people who can help tonight.", tags=['suicide', 'crisis'], src=[clin('who_suicide'), MH], risk='high', fixed=True, trig=['ending', 'hopeless', 'pointless'], dns=['Join with helplines.json scope suicide.'], stage=['crisis'])

    A('referral', "If this has been heavy for weeks, a doctor or counsellor can genuinely help. You can say: \"I've been struggling and I need to talk to someone.\"", tags=['counsellor', 'script'], src=[G, MH], ev='C', fixed=True, trig=['weeks', 'months', 'always', 'worse'])
    A('referral', "A listening service lets you talk to a real person, any hour, without explaining yourself first. The list below shows what is available in your country.", tags=['listening'], src=[SAM], ev='B', fixed=True)

    A('islamic', "Allah says in the Qur'an not to despair of His mercy, and that He forgives all sins. Nothing you have done or felt has closed His door.", src=[Q('39:53', 'RES_H2 2.2')], tags=['mercy', 'despair'], trig=['forgive', 'despair', 'hopeless', 'ashamed'])
    A('islamic', "The Prophet taught that no worry, sorrow or harm reaches a believer without Allah wiping away some of their sins through it. Your pain is seen, and it is not wasted.", src=[H('muslim:2573', 'RES_H2 4.8'), H('bukhari:5642', 'RES_H2 4.8')], tags=['hardship', 'mercy'], trig=['why', 'pain', 'suffering'])
    A('islamic', "The Qur'an promises that with hardship comes ease, and that Allah does not burden a soul beyond what it can bear. You are not expected to feel fine yet.", src=[Q('94:5-6', 'RES_H2 2.2'), Q('2:286', 'RES_H2 2.2')], tags=['ease', 'mercy'], trig=['bear', 'much', 'hard'])
    A('islamic', "The Qur'an says hearts find rest in the remembrance of Allah. Remembrance can be small: one quiet moment, one short phrase, one honest dua in your own words.", src=[Q('13:28', 'RES_H2 knowledge')], tags=['dhikr', 'far-from-allah'], trig=['allah', 'peace', 'calm', 'salah', 'prayer'])
    A('islamic', "Even some companions of the Prophet once told him they felt their faith dip when they left his company, and he did not condemn them for it. Feelings of distance are part of being human, and the way back is gentle.", src=[H('muslim:2750', 'RES_H2 2.3')], tags=['far-from-allah', 'normal'], trig=['iman', 'numb', 'distant', 'hypocrite'])
    A('islamic', "The Prophet taught that Allah is more pleased with a servant who turns back to Him than a traveller who finds what they thought was lost. Coming back, even slowly, is loved.", src=[H('bukhari:6308', 'RES_H2 2.3')], tags=['return', 'mercy'], trig=['back', 'return', 'again', 'ashamed'])
    A('islamic', "The Prophet taught that your body has a right over you. Rest, food and sleep are not a lack of faith; they are part of it.", src=[H('bukhari:6134', 'RES_H2 knowledge')], tags=['rest', 'self-care'], trig=['tired', 'exhausted', 'sleep', 'rest'])
    A('islamic', "The Prophet taught that when a servant raises their hands in dua, Allah does not return them empty. You can ask Him for exactly what you need, in your own language.", src=[H('tirmidhi:3556', 'RES_H2 2.5'), H('abudawud:1488', 'RES_H2 2.5')], tags=['dua', 'hope'], trig=['dua', 'ask', 'hope'])

    A('family', "If someone you love is carrying something heavy, you don't need the perfect words. Sit with them, listen without fixing, and keep showing up after the first day.", tags=['friend', 'family-of'], src=[G], ev='C', trig=['friend', 'wife', 'husband', 'son', 'daughter'])
    A('summary', "What I've heard: {topic} is weighing on you, and you want to feel steadier. You don't have to carry it alone.", tags=['summary'], slots=['topic'])
    return [p]
