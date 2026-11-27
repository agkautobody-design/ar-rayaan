from .lib import Pack
from .sources import H, Q, bg, clin


def build():
    p = Pack('anxiety_panic', 'support', 'anxiety', 'hadi',
             'Anxiety, panic, racing thoughts and sleepless worry: calm the body first, name what is happening, take one small step, know when a doctor helps.',
             base_tags=['anxiety'])
    A = p.add
    G = bg('RES_H1 10.1', 'Anxiety and panic: slow breathing, grounding and gradual return to avoided things are standard first steps; persistent or disabling anxiety should go to a clinician. General teaching; no source opened; clinician to confirm.')
    MH = clin('who_mhgap')

    A('orient', "I'm glad you're here. I'm an app, not a doctor, but I can walk you through steadying yourself and then we can talk about what's behind it. What's happening right now?", tags=['opening', 'honesty'])
    A('orient', "Let's slow this down together. You don't have to explain everything first. Is your body racing right now, or is it mostly your thoughts?", tags=['opening'])
    A('orient', "Anxiety is exhausting, and you're not being dramatic. Tell me what it's like for you and we'll find one thing that helps today.", tags=['opening'])

    A('reflect', "It sounds like your mind won't give you a minute of quiet.", tags=['racing'], trig=['racing', 'overthinking', 'cant stop', 'switch off'])
    A('reflect', "That sounds frightening, your body reacting as if something terrible is about to happen.", tags=['panic'], trig=['panic', 'heart racing', 'shaking', 'cant breathe'])
    A('reflect', "You're bracing for the worst, and bracing all day is exhausting.", tags=['worry'], trig=['worst', 'what if', 'dread'])
    A('reflect', "It sounds like the nights are the hardest, when everything gets louder.", tags=['sleep'], trig=['night', 'sleep', 'awake', '3am'])
    A('reflect', "You've been holding this together on the outside while it's loud on the inside.", tags=['hidden'], trig=['pretend', 'fine', 'hide'])
    A('reflect', "Part of you knows it may not happen, and the fear is still real. Both are true.", tags=['fear'], trig=['irrational', 'silly', 'know its'])

    A('ask', "Right now, is it more in your body, your thoughts, or both?", tags=['triage'])
    A('ask', "When did it start getting louder, a day ago, a month ago, longer?", tags=['history'])
    A('ask', "What is the worry saying to you at the moment? Put it in one sentence.", tags=['story'])
    A('ask', "Is there something specific coming up, or does it come without a reason?", tags=['trigger'])
    A('ask', "How have you been sleeping, eating and moving this week?", tags=['self-care'], risk='medium')
    A('ask', "What have you been avoiding because of it?", tags=['avoidance'])
    A('ask', "Has it ever got so heavy that you felt you couldn't go on?", tags=['safety-check'], risk='high', ask=True, src=[MH], dns=['If yes or unclear, ask directly about suicide and go to the crisis flow.'])

    A('affirm', "You came here instead of fighting it alone in silence. That counts.", tags=['validation'])
    A('affirm', "Feeling this and still getting through your day is real strength, even if it doesn't feel like it.", tags=['strength'])
    A('affirm', "Asking for help with a hard feeling is a sensible thing to do, not a failure.", tags=['validation'])

    A('explain', "A panic attack feels like danger, but it is the body's alarm going off with no fire. It rises, peaks, and passes, usually within minutes. Fighting it feeds it; riding it out lets it fall.", tags=['panic', 'normal'], src=[G], ev='C', trig=['panic', 'attack', 'dying'])
    A('explain', "Slow breathing helps because a long out-breath tells the body it is safe. In through the nose for a count of four, out through the mouth for a count of six, for a few minutes.", tags=['breathing', 'coping'], src=[G], ev='C', trig=['breathe', 'breathing', 'calm'])
    A('explain', "Grounding pulls the mind out of the future and into the room: name five things you can see, four you can feel, three you can hear, two you can smell, one you can taste.", tags=['grounding', 'coping'], src=[G], ev='C', trig=['grounding', 'spiral', 'spinning'])
    A('explain', "Avoiding what scares you brings relief now and makes the fear bigger later. Facing it in small, planned steps, with a trusted person if you can, is how fear shrinks.", tags=['avoidance'], src=[G], ev='C', trig=['avoid', 'avoiding', 'scared to'])
    A('explain', "Late caffeine, little sleep and skipped meals can make anxiety louder. Changing them will not cure it, but it can turn the volume down.", tags=['body', 'sleep'], src=[G], ev='C', trig=['coffee', 'caffeine', 'sleep', 'skipping'])
    A('explain', "A worry written down is smaller than a worry going round in your head. Some people set ten minutes a day as worry time, and when a worry appears outside it, they say: later, at ten past six.", tags=['worry-time', 'coping'], src=[G], ev='C', trig=['overthinking', 'worry', 'loop'])

    A('plan-step', "One small step right now: breathe in for four, out slowly for six, five times. Tell me how your body feels after.", tags=['breathing'], ask=True, src=[G], ev='C')
    A('plan-step', "One small step: put both feet flat on the floor, press them down, and name five things you can see. It brings you back into the room.", tags=['grounding'], ask=True, src=[G], ev='C')
    A('plan-step', "One small step: splash cold water on your face or hold something cool for thirty seconds. It can settle a racing body quickly.", tags=['body'], ask=True, src=[G], ev='C')
    A('plan-step', "One small step: write the worry in one line and next to it, what you would say to a friend who told you the same thing.", tags=['coping'], ask=True, src=[G], ev='C')
    A('plan-step', "One small step: make wudu slowly, feeling the water, and pray two rak'ahs without rushing, or sit quietly for two minutes and speak to Allah in your own words.", tags=['salah', 'faith'], ask=True)
    A('plan-step', "One small step tonight: screens off thirty minutes before bed, and if your mind starts, get up, write what it's saying, and go back to bed.", tags=['sleep'], ask=True, src=[G], ev='C')
    A('plan-step', "One small step this week: pick one thing you've been avoiding and do the smallest first piece of it, only five minutes.", tags=['avoidance'], ask=True, src=[G], ev='C')

    A('safety', "If you have chest pain, pain spreading to your arm or jaw, or trouble breathing that does not ease, call your emergency number now. Do not assume it is anxiety. If thoughts of ending your life come, contact your emergency number or a crisis line now.", tags=['chest-pain', 'emergency', 'suicide'], src=[clin('who_suicide'), MH], risk='high', fixed=True, stage=['crisis'], dns=['Join with helplines.json scope suicide.'])
    A('referral', "If anxiety is stopping you from sleeping, working or going out, or has lasted weeks, a doctor can help, and talking therapy works well for it. You can say: \"I have been anxious for a while and it is getting in the way of my life.\"", tags=['doctor', 'script'], src=[G, MH], ev='C', fixed=True, trig=['weeks', 'months', 'work', 'cant sleep'])
    A('referral', "If you want to talk to a real person tonight, a listening service is free and open when you need it. The list below shows what is available in your country.", tags=['listening'], src=[clin('samaritans')], ev='B', fixed=True)

    A('islamic', "The Prophet taught a du'a for exactly this: seeking refuge in Allah from worry and sorrow, from weakness and laziness, from fear and being overwhelmed. It is on the du'a page, and you can say it in your own language as well.", src=[H('bukhari:6369', 'RES_H2 4.8')], tags=['dua', 'worry'], trig=['dua', 'worry', 'sorrow', 'allah'])
    A('islamic', "The Qur'an says hearts find rest in the remembrance of Allah. A few slow words of dhikr with a slow breath can be one part of settling yourself, not the only part.", src=[Q('13:28', 'RES_H2 knowledge')], tags=['dhikr', 'calm'], trig=['peace', 'calm', 'dhikr', 'remembrance'])
    A('islamic', "Allah says He does not burden a soul beyond what it can bear, and that with hardship comes ease. Feeling overwhelmed is not a sign that your faith is lacking; it means you need support as well as faith.", src=[Q('2:286', 'RES_H2 2.2'), Q('94:5-6', 'RES_H2 2.2')], tags=['ease', 'mercy'], trig=['too much', 'cant take', 'bear'])
    A('islamic', "The Prophet taught that no worry or anxiety reaches a believer without Allah using it to lift some of their wrongs. Your anxiety is seen, and it is not wasted.", src=[H('muslim:2573', 'RES_H2 4.8')], tags=['hardship', 'mercy'], trig=['why', 'suffering', 'punishment'])
    A('islamic', "The Prophet taught that your body has a right over you. Sleep, food and rest are part of caring for what Allah gave you, and part of worship.", src=[H('bukhari:6134', 'RES_H2 knowledge')], tags=['rest', 'self-care'], trig=['tired', 'sleep', 'rest'])

    A('family', "If someone you love has anxiety, you don't need to talk them out of it. Stay calm, breathe slowly beside them, ask what helps, and don't tell them there is nothing to worry about.", tags=['family-of'], src=[G], ev='C', trig=['my wife', 'my husband', 'my son', 'my daughter', 'my friend'])
    A('summary', "What I've heard: {topic} has been loud, and you want your body and mind to settle. We found a first small step, and you can come back and try another.", tags=['summary'], slots=['topic'])
    return [p]
