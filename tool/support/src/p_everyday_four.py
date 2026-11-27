from .lib import Pack
from .sources import H, Q, bg, clin


def _pack(name, topic, desc, tag, spec):
    p = Pack(name, 'support', topic, 'hadi', desc, base_tags=[tag])
    A = p.add
    G = bg('RES_H1 10.1', spec['bg'])
    MH = clin('who_mhgap')
    for t in spec['orient']:
        A('orient', t, tags=['opening'])
    for t, trig in spec['reflect']:
        A('reflect', t, tags=[tag], trig=trig)
    for t in spec['ask']:
        A('ask', t, tags=['explore'])
    A('ask', "Has it ever got so heavy that you felt you couldn't go on?", tags=['safety-check'], risk='high', ask=True, src=[MH], dns=['If yes or unclear, ask directly about suicide and go to the crisis flow.'])
    for t in spec['affirm']:
        A('affirm', t, tags=['validation'])
    for t, trig in spec['explain']:
        A('explain', t, tags=[tag, 'normal'], src=[G], ev='C', trig=trig)
    for t in spec['step']:
        A('plan-step', t, tags=['coping'], ask=True, src=[G], ev='C')
    A('plan-step', spec['faith_step'], tags=['faith'], ask=True)
    A('safety', "If this ever turns into feeling you can't go on, or thoughts of ending your life, please contact your emergency number or a crisis line now. You matter, and people can help tonight.", tags=['suicide', 'crisis'], src=[clin('who_suicide'), MH], risk='high', fixed=True, stage=['crisis'], dns=['Join with helplines.json scope suicide.'])
    A('referral', spec['referral'], tags=['doctor', 'script'], src=[G, MH], ev='C', fixed=True, trig=['weeks', 'months', 'worse', 'work', 'sleep'])
    for t, refs, trig in spec['islamic']:
        A('islamic', t, src=refs, tags=['mercy'], trig=trig)
    A('family', spec['family'], tags=['family-of'], src=[G], ev='C', trig=['my wife', 'my husband', 'my son', 'my daughter', 'my friend'])
    A('summary', "What I've heard: {topic} has been weighing on you, and you want it to ease. We found one small step, and you can come back for another.", tags=['summary'], slots=['topic'])
    return p


LOW = dict(
    bg="Low mood: behavioural activation, routine, light, movement and connection help; persistent low mood or loss of interest for two weeks or more should go to a clinician. General teaching; clinician to confirm.",
    orient=["I'm glad you're here. I'm an app, not a doctor, but I can listen and we can find one small thing for today. How has your heart been?",
            "You don't have to be able to explain it. Low days often come without a reason. Tell me what they feel like."],
    reflect=[("It sounds like everything takes more effort than it used to.", ['tired', 'effort', 'motivation']),
             ("It sounds like the colour has gone out of things.", ['empty', 'numb', 'nothing', 'enjoy']),
             ("You're carrying this quietly while other people see you coping.", ['pretend', 'fine', 'hide']),
             ("It sounds like you're being very hard on yourself for feeling this way.", ['useless', 'lazy', 'burden'])],
    ask=["What has changed in the last few weeks?", "What does a day look like from waking to sleeping?", "Is there one thing you still manage even on the heavy days?", "How are you eating and sleeping?"],
    affirm=["Getting through the day while feeling like this is real effort, even if no one sees it.", "Reaching out is not weakness; it is you looking after yourself."],
    explain=[("Low mood is a state, not a verdict on who you are. Heavy thoughts like I am useless are symptoms speaking, not facts.", ['useless', 'worthless', 'burden']),
             ("When energy is low, waiting to feel motivated rarely works. Doing a tiny action first often lifts the feeling a little, not the other way round.", ['motivation', 'cant start', 'lazy']),
             ("Daylight, a short walk, regular meals and regular sleep are small but real supports for mood.", ['sleep', 'tired', 'walk'])],
    step=["One small step: open a window or step outside for five minutes of daylight, then tell me how it felt.", "One small step: pick the easiest task on your list, set a five minute timer, and stop when it rings.", "One small step: send one message to one safe person, even just a greeting."],
    faith_step="One small step: pray one prayer as you are, however you feel, and then say your own words to Allah, even only: ya Allah, I am tired.",
    referral="If low mood has lasted two weeks or more, or is affecting your sleep, appetite, work or your sense of hope, a doctor can help and treatment works. You can say: \"I have felt low for weeks and I want help with it.\"",
    islamic=[("Allah told His Messenger that He had not left him and was not displeased with him. Low seasons are not a sign that Allah has left you.", [Q('93:3', 'RES_H2 2.2')], ['abandoned', 'left', 'forsaken', 'allah']),
             ("The Prophet taught that no worry, sorrow or hardship reaches a believer without Allah using it to lift some of their wrongs. Your pain is seen.", [H('muslim:2573', 'RES_H2 4.8')], ['why', 'pain', 'suffering']),
             ("With hardship comes ease, the Qur'an says, twice over. It does not say the ease is quick, only that it is promised.", [Q('94:5-6', 'RES_H2 2.2')], ['hope', 'ease', 'when'])],
    family="If someone you love seems low, you don't need to cheer them up. Sit with them, ask how they are, and keep inviting them to small things without pressure.")

LONELY = dict(
    bg="Loneliness: small regular contact, shared activity and a reliable routine reduce it; persistent loneliness with low mood should go to a clinician. General teaching; clinician to confirm.",
    orient=["I'm glad you came. You can talk to me as long as you like. What's making things feel lonely?",
            "Loneliness is more common than people say out loud. Tell me what it looks like for you."],
    reflect=[("It sounds like there are people around you but nobody who really knows you.", ['nobody', 'alone', 'no one']),
             ("It sounds like you moved or something changed and the people you counted on aren't there now.", ['moved', 'new city', 'left']),
             ("It sounds like you miss being known, not only being around people.", ['miss', 'known', 'understood']),
             ("Evenings and weekends can be the loudest time.", ['night', 'weekend', 'evening'])],
    ask=["When did you last feel properly connected to someone?", "Is it the lack of people, or the lack of anyone who understands?", "What did you used to enjoy with others?", "Is there someone you've drifted from and miss?"],
    affirm=["Wanting people is healthy; it means you are built for connection.", "Telling me is a first step toward finding your people."],
    explain=[("Loneliness is a signal, like hunger, that connection is needed. It is not a sign that you're unlikeable.", ['unlikeable', 'boring', 'nobody']),
             ("Friendship usually grows from repeated small contact in the same place, not from big gestures. A weekly class, a masjid circle or a volunteer shift adds up.", ['friends', 'make friends', 'new']),
             ("Online time can leave you more alone than you started. Choosing one real call over an hour of scrolling often feels better.", ['phone', 'scrolling', 'online'])],
    step=["One small step: message one person you've drifted from with a simple, how are you?", "One small step: choose one regular thing this week, a class, the masjid, a walk group, and put it in your calendar.", "One small step: say salam to one neighbour or someone at the masjid and ask one question about them."],
    faith_step="One small step: pray one of your prayers in jama'ah, at the masjid or with someone at home, and stay five minutes after.",
    referral="If loneliness has lasted weeks and is pulling your mood down, a counsellor can help, and many services also offer friendly listening calls. You can say: \"I feel very isolated and I want help.\"",
    islamic=[("Allah says He is near, and answers the one who calls on Him. You are never actually alone in your dua.", [Q('2:186', 'RES_H2 2.2')], ['alone', 'near', 'dua']),
             ("Allah says He is closer to a person than their own jugular vein. Even when no one knows you, He does.", [Q('50:16', 'RES_H2 2.2')], ['known', 'unseen', 'allah']),
             ("Allah calls the believers brothers and sisters. Looking for your people is part of your deen, not a weakness.", [Q('49:10', 'RES_H2 2.2')], ['community', 'brothers', 'ummah'])],
    family="If someone you love is lonely, a regular small invitation is worth more than a rare big one. Keep it simple and keep it going.")

ANGER = dict(
    bg="Anger: noticing early signs, pausing, slow breathing and leaving the situation briefly reduce harm; anger that leads to violence or fear at home needs professional support. General teaching; clinician to confirm.",
    orient=["I'm glad you said it. Anger is a feeling, not a character defect, and it usually sits on top of something else. What's been happening?",
            "No judgment here. Tell me what sets it off and what you do afterwards."],
    reflect=[("It sounds like it goes from nothing to boiling very fast.", ['fast', 'snap', 'explode']),
             ("It sounds like you hate who you become when it happens.", ['hate', 'regret', 'sorry']),
             ("It sounds like you are under pressure from many sides.", ['stress', 'work', 'money']),
             ("It sounds like the people close to you are bearing the worst of it, and that worries you.", ['wife', 'kids', 'family'])],
    ask=["What usually happens just before it rises?", "What does your body do first: jaw, chest, hands?", "What is underneath it: hurt, fear, tiredness, feeling disrespected?", "What happens afterwards, to you and to the people around you?", "Has anyone ever been hurt or afraid of you when you were angry?"],
    affirm=["Being worried about your anger is a good sign. People who don't care don't ask.", "You can change how you respond, even if you can't change that the feeling comes."],
    explain=[("Anger has a ladder: first the body tightens, then thoughts sharpen, then words and actions follow. The earlier you step off, the easier it is.", ['explode', 'snap', 'fast']),
             ("Taking a break works when you say it plainly: I am too angry to talk well, I will come back in twenty minutes. And then you do come back.", ['walk away', 'argument', 'fight']),
             ("Slow breathing, cold water on the face and a walk lower the body's heat quickly. The thoughts get fairer after.", ['calm', 'cool', 'down'])],
    step=["One small step: next time you feel the first tightening, say out loud I need a break, and leave the room for ten minutes.", "One small step: breathe in for four, out for six, five times, before you reply to anything that stirred you.", "One small step: tonight, write what triggered you and what was underneath. Patterns show up on paper."],
    faith_step="One small step: when anger comes, change position, sit if standing or lie down if sitting, and make wudu. Cold water helps.",
    referral="If anger leads to shouting, breaking things or frightening people, a counsellor can teach real tools for it. You can say: \"I get angry in ways I regret and I want to change.\" If anyone is in danger, call your emergency number.",
    islamic=[("The Prophet taught that the strong person is not the one who defeats others, but the one who controls themselves in anger.", [H('bukhari:6114', 'RES_H2 knowledge')], ['strong', 'control', 'angry']),
             ("Allah praises those who restrain their anger and forgive people, and says He loves those who do good.", [Q('3:134', 'RES_H2 2.2')], ['forgive', 'restrain', 'anger']),
             ("Allah accepts those who return to Him after harming others. Making amends is part of repair, not the end of your worth.", [H('muslim:2744', 'RES_H2 knowledge')], ['regret', 'sorry', 'apologise'])],
    family="If someone near you has a temper, protect your own safety first. When things are calm, say what you've seen, in short sentences, and what you need. If you feel unsafe, contact local support.")

WASWAS = dict(
    bg="Intrusive doubts and compulsions: reassurance-seeking and rechecking keep them going; treatment with a clinician (exposure and response prevention) is effective. General teaching; clinician to confirm.",
    orient=["I'm glad you told me. These doubts are exhausting, and they are far more common than people admit. What do they say to you?",
            "No judgment. Tell me what keeps coming back and what you do to quiet it."],
    reflect=[("It sounds like no matter how many times you check, it never feels finished.", ['again', 'repeat', 'check', 'redo']),
             ("It sounds like the doubts target the things you love most, your prayer and your faith.", ['prayer', 'wudu', 'salah', 'faith']),
             ("It sounds like you're afraid these thoughts mean something terrible about you.", ['blasphem', 'evil', 'thoughts']),
             ("It sounds like you spend a lot of time and energy just trying to be sure.", ['sure', 'certain', 'clean'])],
    ask=["What are the thoughts or doubts, in your own words?", "What do you do afterwards to feel safe, repeat, wash, ask someone?", "How long does it take, and what has it taken from your day?", "Do you feel relief that lasts, or does it come back?"],
    affirm=["The fact that these thoughts distress you shows how much you care about doing right.", "Telling someone is brave. These doubts lose some of their grip when spoken."],
    explain=[("Intrusive thoughts are common and do not reflect your will. What matters is that you hate them, and that is not how a person who wants them feels.", ['blasphem', 'evil', 'thoughts', 'intrusive']),
             ("Repeating, rechecking and reassurance bring a short relief and teach the mind to ask again. Gently resisting the urge, a little more each day, is how the loop weakens.", ['repeat', 'check', 'again', 'sure']),
             ("Scholars distinguish ordinary doubt from obsessive doubt. For the person caught in waswas, the guidance is generally to ignore the doubt rather than keep checking. A qualified scholar who understands this can confirm what applies to you.", ['wudu', 'prayer', 'salah', 'doubt'])],
    step=["One small step: when the doubt comes, say it's waswas, I will not check, and do the next thing you were doing. Notice that you can bear the discomfort.", "One small step: choose one repeating habit and cut it by one repetition today.", "One small step: write the thought down and the urge that followed. Naming it separates you from it."],
    faith_step="One small step: seek refuge in Allah from the whisperer once, calmly, and carry on with your prayer without redoing it.",
    referral="Waswas and OCD respond well to treatment. A doctor or therapist who knows exposure and response prevention can help, and a scholar can advise on religious rulings. You can say: \"I have repeating doubts and rituals that take over my day.\"",
    islamic=[("Allah says to seek refuge in Him from the whisperer who whispers in the hearts of people. Refuge is the answer, not an argument.", [Q('114:4-5', 'RES_H2 2.2')], ['whisper', 'shaytan', 'waswas']),
             ("Allah does not burden a soul beyond what it can bear. He does not hold you to what you cannot control, including thoughts that arrive uninvited.", [Q('2:286', 'RES_H2 2.2')], ['punish', 'sin', 'burden'])],
    family="If someone you love has waswas or OCD, don't join the rituals or reassure endlessly. Be kind, say you believe it is hard, and encourage treatment.")


def build():
    return [
        _pack('low_mood', 'low_mood', 'Low mood and heaviness: listen first, small activating steps, hope without pressure, and when a doctor helps.', 'low-mood', LOW),
        _pack('loneliness', 'loneliness', 'Loneliness and isolation: being known, small regular connection, community, and Allah being near.', 'loneliness', LONELY),
        _pack('anger', 'anger', 'Anger and temper: notice early, pause, name what is underneath, repair, and when to get support.', 'anger', ANGER),
        _pack('waswas_ocd', 'waswas_ocd', 'Waswas and OCD-type doubts: intrusive thoughts are not you, resist rechecking, treatment works, scholar can confirm rulings.', 'waswas', WASWAS),
    ]
