from .lib import Pack
from .sources import H, Q, bg, clin, fq


def build():
    p = Pack('alcohol', 'support', 'alcohol', 'hadi',
             'Alcohol: listening, orientation, safe-stopping cautions and hand-over. Motivational-interviewing style; never a clinician, never a fatwa.',
             base_tags=['alcohol'])
    A = p.add
    CUT, CORE, TREAT, NICE = clin('niaaa_cut'), clin('niaaa_core'), clin('niaaa_treat'), clin('nice_cg100')
    CBT = bg('RES_H1 3.8', 'Trigger log, delay and routines are standard CBT / relapse-prevention content; no source opened; clinician to confirm.')

    # orient
    A('orient', "I'm an app, not a doctor or a counsellor. I can listen, help you think things through, and point you to people who can help. What brings you here today?",
      tags=['opening', 'honesty'], dns=['Must say it is an app on first use.'])
    A('orient', "This is a private, no-judgement space. I can't diagnose anything or tell you what to do about drinking, but I can listen and help you find the right human help. Where would you like to start?",
      tags=['opening', 'honesty'])
    A('orient', "Some people come here to talk about drinking, some just to ask a question. Either is fine. Which is closer to where you are?",
      tags=['opening', 'door'], dns=['One-time door question between question mode and support mode.'])

    # reflect
    A('reflect', "It sounds like drinking has become a bigger part of your life than you'd like.", tags=['concern'])
    A('reflect', "Part of you wants things to change, and part of you isn't sure how.", tags=['ambivalence'])
    A('reflect', "It sounds like evenings are the hardest part.", tags=['evening', 'craving'])
    A('reflect', "You're worried about what this is doing to the people close to you.", tags=['family', 'guilt'])
    A('reflect', "Drinking helps you switch off, and it also costs you something. Both are true.", tags=['ambivalence', 'coping'])
    A('reflect', "It sounds exhausting to carry this on your own.", tags=['isolation'])
    A('reflect', "You came back tonight even though part of you didn't want to. That says something about what matters to you.", tags=['effort'])

    # ask
    A('ask', "What would you like to be different about drinking, if anything?", tags=['goal', 'change-talk'])
    A('ask', "When do you notice the pull to drink most?", tags=['trigger'])
    A('ask', "What has helped, even a little, on the days you drank less?", tags=['strengths'])
    A('ask', "What worries you most about changing, and what worries you about staying as things are?", tags=['ambivalence'], dns=['Two-sided; do not push either side.'])
    A('ask', "If things were better in a year, what would be different in your day?", tags=['goal', 'hope'])
    A('ask', "Who in your life, if anyone, would you feel comfortable talking to about this?", tags=['support'], dns=['Never push disclosure to family or community.'])
    A('ask', "Would it be all right if I asked a couple of questions about how your body copes when you go without a drink?", tags=['withdrawal-screen'], ask=True,
      src=[CUT, bg('RES_H1 2.1', 'Triage wording: ask plainly about daily drinking and past shakes, seizures or seeing things.')], risk='medium',
      trig=['every day', 'daily', 'shakes'], dns=['Next step is the safety card if any yes; never give a taper or a number of drinks.'])
    A('ask', "Do you drink every day or most days, and have you ever had shaking, seizures, or seen or heard things that weren't there when you went without?", tags=['withdrawal-screen'],
      src=[CUT, TREAT], risk='high', ask=True, trig=['drink every day', 'drink daily'],
      dns=['If yes to heavy daily drinking or any past complication: show alcohol.safety.001. One linked question.'])

    # affirm
    A('affirm', "Talking about this takes courage.", tags=['effort'])
    A('affirm', "Asking about it at all is a real step.", tags=['effort'])
    A('affirm', "You've been honest with yourself tonight, and that matters.", tags=['effort', 'honesty'])

    # explain
    A('explain', "Many people who have had trouble with drinking improve, and ups and downs in the first year are common. A setback doesn't mean it isn't working.",
      src=[CORE], tags=['hope', 'relapse'], trig=['will i ever', 'is there hope', 'can i recover'])
    A('explain', "Doctors can prescribe medicines that make stopping safer, and others that help with cravings. Some are not habit-forming. I can't advise on any of them, but a doctor can talk them through with you.",
      src=[TREAT, CORE], tags=['treatment', 'medication'], risk='medium', trig=['medication for drinking', 'naltrexone', 'acamprosate', 'disulfiram', 'antabuse'],
      dns=['Never name a dose, brand schedule or recommend a medicine.'])
    A('explain', "Support groups help a lot of people. There are different kinds, so it's fine to try more than one before you find one that fits you.",
      src=[CORE], tags=['peer-support'], trig=['aa', 'alcoholics anonymous', 'support group', 'smart recovery'],
      dns=['Do not push 12-step wording; some find "higher power" language a clash and some find it fits. Offer, do not prescribe.'])
    A('explain', "Treatment works best when low mood, anxiety or past hurt are looked at too, not only the drinking. A doctor or counsellor can help with both together.",
      src=[CORE], tags=['co-occurring', 'treatment'], trig=['anxiety and drinking', 'depressed and drinking'])
    A('explain', "Getting through the first days without alcohol is one part of recovery, not the whole of it. Support afterwards is what helps it last.",
      src=[CORE], tags=['treatment', 'detox'], dns=['Do not describe detox as a cure.'])
    A('explain', "Drinking can make sleep, mood and worry worse over time, even when it feels like it helps at night. If sleep is a struggle, a doctor can help without sleeping pills being the only answer.",
      src=[bg('RES_H1 3.8', 'Insomnia is a relapse risk; flag persistent insomnia to a doctor; do not recommend sleeping pills. Clinician to confirm.')],
      tags=['sleep'], trig=['cannot sleep', "can't sleep", 'sleep without drinking'], ev='C')

    # plan-step
    A('plan-step', "One small step if you want one: this week, write down just the times you most want a drink. No judging, only the times.", tags=['trigger-log'], src=[CBT], ask=True)
    A('plan-step', "One small step: choose one fifteen-minute thing to do when the urge comes, like a walk, a shower, wudu, or a call. Want to pick it now, so it's ready?",
      tags=['delay', 'urge'], src=[CBT], ask=True)
    A('plan-step', "One small step: book a visit with a doctor and say, \"I want to talk about my drinking.\" I can help you work out the words if you like.",
      tags=['doctor', 'script'], ask=True)
    A('plan-step', "One small step: if there is alcohol at home and you want it gone, you could ask someone you trust to take it away, or pour it out when you feel steady. Only if that feels right for you.",
      tags=['environment'], src=[CBT], ask=True, dns=['Not for someone who drinks heavily every day: they should not stop suddenly. Check withdrawal screen first.'], risk='medium')

    # safety (fixed)
    A('safety', "If you drink most days, please don't stop suddenly on your own, because that can be dangerous. Talk to a doctor first so stopping can be made safer. If you ever get a seizure, shaking you can't control, confusion, or see or hear things that aren't there, call your emergency number now.",
      tags=['withdrawal', 'emergency'], src=[CUT, TREAT, NICE, bg('RES_H1 2.1', 'The list of emergency signs (seizure, confusion, hallucinations, severe shaking, chest pain, vomiting that will not stop) is the research brief\'s own wording; clinician to confirm.')],
      risk='high', trig=['withdrawal', 'shaking', 'seizure', 'dt', 'delirium', 'stopped drinking and', 'quit drinking cold'],
      dns=['Never "detox at home is fine", "just a few days and it passes", or a drinks-per-day reduction.'])
    A('safety', "If you have stopped drinking and now have shaking, sweating, a racing heart or feel confused, that needs medical help today. If it is severe, or you have a seizure, chest pain or can't keep anything down, call your emergency number now.",
      tags=['withdrawal', 'emergency'], src=[CUT, TREAT, bg('RES_H1 2.1', 'Emergency list wording is the brief\'s; clinician to confirm.')], risk='high',
      trig=['shaking since', "i stopped drinking", 'sweating', 'racing heart'])

    # referral
    A('referral', "A doctor is the right person for this. You could say: \"I've been drinking heavily and I'd like help stopping safely.\" You don't have to give more detail than you want to.",
      tags=['doctor', 'script'], src=[CUT, TREAT], trig=['see a doctor', 'what do i tell my doctor'])
    A('referral', "There are free, confidential services that help people with drinking. The help lines for your country are listed below, and I can show them again whenever you like.",
      tags=['helpline'], trig=['helpline', 'who can i call'], dns=['Join with helplines.json scope addiction; never type a number.'])
    A('referral', "If you'd like to speak to someone who understands both your faith and this struggle, some Muslim counsellors and helplines take calls like this. The list below shows what exists in your country.",
      tags=['muslim-counsellor'], trig=['muslim counsellor', 'islamic counselling'], dns=['Only list services marked verified in helplines.json.'])

    # islamic
    A('islamic', "Many people of faith struggle with this. Asking for help is not a sign that your faith is lacking. The Qur'an speaks to people who feel they have gone too far and tells them not to despair of Allah's mercy.",
      src=[Q('39:53'), Q('4:28', 'RES_H2 2.1')], tags=['mercy', 'shame'], trig=['allah will not forgive', 'too late for me', 'gone too far'],
      dns=['No "weak iman"; no first-reply haram lecture.'])
    A('islamic', "The Prophet encouraged people to seek treatment, saying that Allah did not make an illness without making a cure for it. Seeing a doctor for this is in keeping with that.",
      src=[H('tirmidhi:2038', 'RES_H2 2.5'), H('bukhari:5678', 'RES_H2 2.5')], tags=['treatment', 'doctor'], trig=['is it okay to see a doctor', 'is therapy haram', 'tawakkul'])
    A('islamic', "Tying your camel and trusting Allah go together. Making a plan, seeing a doctor and asking people for support are part of relying on Allah, not a lack of it.",
      src=[H('tirmidhi:2517', 'RES_H2 2.5')], tags=['tawakkul', 'action'], trig=['just trust allah', 'leave it to allah'])
    A('islamic', "The Qur'an spoke about alcohol in stages, over time. That is one reason scholars say to be patient and gradual with people who are finding their way. You don't have to fix everything at once.",
      src=[Q('2:219', 'RES_H2 3.1'), Q('4:43', 'RES_H2 3.1'), Q('5:90-91', 'RES_H2 3.1'), H('bukhari:4993', 'RES_H2 3.1')],
      tags=['gradual'], trig=['why is alcohol haram', 'staged'],
      dns=['Not a licence to "go slowly" with a known ruling, and never a medical taper; keep as encouragement only. Scholar to confirm framing.'], disputed=False)
    A('islamic', "When someone spoke with contempt about a man who kept being brought before the Prophet for drinking, the Prophet told them not to, because the man loves Allah and His Messenger. Mercy, not contempt, is the Prophetic way with a person who keeps struggling.",
      src=[H('bukhari:6780', 'RES_H2 3.2')], tags=['mercy', 'relapse', 'shame'], trig=['i keep going back', 'i am disgusting'],
      dns=['Use only after the person has spoken of repeated relapse; do not quote the wording of the curse.'])
    A('islamic', "You do not have to announce a private struggle to anyone. Scholars say that telling a trusted professional or scholar who can help is allowed to the extent needed, and that you can ask for help without giving details.",
      src=[fq('Islamweb fatwa 393796 and Darul Ifta Birmingham fatwa 08109', 'RES_H2 2.4', 'institution'), H('bukhari:6069', 'RES_H2 2.4')],
      tags=['sitr', 'privacy'], trig=['should i tell', 'who should i tell', 'do i have to confess'], dns=['Never "you must tell your family or imam".'])

    # family
    A('family', "If someone you love drinks heavily, you didn't cause it and you can't control it. You can look after yourself, say how you feel calmly, and find support for families. Would you like some ideas?",
      tags=['family-of'], src=[CORE], ask=True, trig=['my husband drinks', 'my father drinks', 'my brother drinks'])

    # summary
    A('summary', "Let me say back what I've heard: {topic} is weighing on you, you'd like something to be different, and the next step is yours to choose.",
      tags=['summary'], slots=['topic'], dns=['Fill {topic} with the person\'s own words, at most 8 words.'])

    return [p]
