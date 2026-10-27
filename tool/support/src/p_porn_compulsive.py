from .lib import Pack
from .sources import H, Q, bg, clin, fq


def build():
    p = Pack('porn_compulsive', 'support', 'porn', 'hadi',
             'Pornography use and compulsive sexual behaviour: private, shame-aware, no diagnosis, no forced disclosure, no marriage as a cure.',
             base_tags=['porn'])
    A = p.add
    CSBD = clin('csbd')
    CBT = bg('RES_H1 3.10', 'Trigger planning, blocking tools and urge delay are standard relapse-prevention content (no source opened); clinician to confirm.')

    A('orient', "I'm an app, not a counsellor. This is private, and nothing you say here will be judged. I can listen and help you find the right human help if you want it. What would you like to talk about?", tags=['opening', 'honesty', 'privacy'])
    A('orient', "A lot of people struggle with this and never tell anyone. You can say as much or as little as you like. Where would you like to start?", tags=['opening', 'shame'])
    A('orient', "Is this about how often, about what you watch, about what it is doing to your life, or something else?", tags=['opening', 'door'])

    A('reflect', "It sounds like this has become a heavy secret to carry.", tags=['secrecy', 'shame'])
    A('reflect', "You want to stop, and you keep ending up back here.", tags=['ambivalence', 'relapse'])
    A('reflect', "It sounds like the shame afterwards is worse than the thing itself.", tags=['shame'])
    A('reflect', "You're worried about what it's doing to your relationship, your focus or your sleep.", tags=['concern'])
    A('reflect', "It sounds like it comes when you're lonely, stressed or tired.", tags=['trigger', 'coping'])
    A('reflect', "Part of you wants to feel clean again, and part of you feels stuck.", tags=['ambivalence'])
    A('reflect', "You are tired of the cycle.", tags=['relapse'])

    A('ask', "What would you like to be different?", tags=['goal'])
    A('ask', "When does it tend to happen, such as time of day, place or mood?", tags=['trigger'])
    A('ask', "What has helped, even a bit, on the days it didn't happen?", tags=['strengths'])
    A('ask', "How is it affecting your day, your sleep or your relationships?", tags=['impact'])
    A('ask', "Is there anyone you trust enough to tell, or is it easier to keep this private for now?", tags=['support'], dns=['Never push disclosure; privacy is a valid choice.'])
    A('ask', "Has any of this crossed into something that hurts someone else, or that you are afraid of?", tags=['safety-check'], risk='high', ask=True,
      dns=['If a child is involved or at risk, move to the safeguarding flow; do not continue with generic support.'])

    A('affirm', "It takes courage to speak about something so private.", tags=['effort'])
    A('affirm', "You're still trying, and that matters.", tags=['effort', 'hope'])
    A('affirm', "Wanting to understand this is a good sign.", tags=['effort'])

    A('explain', "Many people find that it helps to understand what sits underneath the urge, such as stress, loneliness or boredom. A counsellor can help with that.", src=[CSBD], tags=['trigger', 'treatment'], ev='C', trig=['why do i do this', 'cannot stop'])
    A('explain', "Researchers describe compulsive sexual behaviour as a pattern some people struggle to control, and it can be treated. It is not a sign that you are a bad person.", src=[CSBD], tags=['csbd', 'treatment'], ev='C', trig=['addiction', 'addicted', 'compulsive'],
      dns=['Never diagnose or label; never say "you have CSBD".'])
    A('explain', "Blocking tools, changing where and when you use your phone, and sleeping on time can make urges easier to ride out. They help most alongside support from a person.", src=[CBT], tags=['environment', 'tools'], ev='C', trig=['filter', 'blocker'])
    A('explain', "Urges rise and fall. Many people find that waiting fifteen minutes and doing something else makes them pass.", src=[CBT], tags=['urge', 'delay'], ev='C', trig=['urge', 'craving'])
    A('explain', "Slipping up is common and it doesn't wipe out the progress you made. What matters is what you do next.", src=[CBT], tags=['relapse', 'hope'], ev='C', trig=['slipped', 'relapsed', 'again'])
    A('explain', "Some people find therapy and a peer group each help in different ways. You can try one without the other.", src=[CSBD], tags=['peer-support', 'treatment'], ev='C')

    A('plan-step', "One small step: choose one change to your phone or evenings that makes it a little harder, like leaving the phone outside the bedroom. Want to choose one together?", tags=['environment'], src=[CBT], ask=True, ev='C')
    A('plan-step', "One small step: when the urge comes, move to another room and do one thing for fifteen minutes, like a walk, wudu or a call. Shall we pick the thing now?", tags=['urge', 'delay'], src=[CBT], ask=True, ev='C')
    A('plan-step', "One small step: write down the times it tends to happen, just as information, without judging yourself.", tags=['trigger-log'], src=[CBT], ask=True, ev='C')

    A('safety', "If looking at pornography involves children in any way, that is a crime and it harms real children. Please don't carry on alone. Contact a child-protection service or the police, or a specialist service that helps people who are worried about their own thoughts. I can show the lines for your country.", tags=['csam', 'child-safety'], src=[bg('RES_H1 10.1', 'Child sexual abuse material: refer to specialist prevention and child-protection services; clinician and safeguarding review required.')], risk='high', ev='C',
      trig=['child porn', 'children', 'minors', 'underage'], dns=['Do not reassure; do not offer coping tips; route to safeguarding. Needs legal and safeguarding review per country.'])
    A('safety', "If you've been thinking about harming yourself because of shame or fear of being found out, please contact a crisis line or your emergency number now. Nothing you have done means help is out of reach.", tags=['suicide', 'shame', 'crisis'], src=[clin('who_suicide'), clin('who_mhgap')], risk='high',
      trig=['kill myself', 'end it', 'cannot live with this'], dns=['Join with helplines.json scope suicide.'])

    A('referral', "A counsellor or therapist can help with this without judging you. You could say: \"I'm struggling to control my pornography use and I'd like support.\" You don't need to share details.", tags=['counsellor', 'script'], src=[CSBD], ev='C', trig=['therapist', 'counsellor'])
    A('referral', "A doctor can help if this is tied to low mood, worry, sleep or relationship stress. You could say: \"I'd like to talk about something private that is affecting me.\"", tags=['doctor', 'script'])
    A('referral', "Some Muslim counsellors work with this struggle and understand the faith side. The list below shows what is available in your country.", tags=['muslim-counsellor'], dns=['Only list services marked verified in helplines.json.'], trig=['muslim counsellor'])

    A('islamic', "This struggle does not take you out of the mercy of Allah. The Qur'an tells people who have wronged themselves not to despair of His mercy.", src=[Q('39:53'), Q('4:28')], tags=['mercy', 'shame'], trig=['allah hates me', 'too late for me'])
    A('islamic', "The Prophet taught that Allah accepts repentance, and the Qur'an describes Him as one who loves those who turn back to Him. Returning after a slip is part of that path, not the end of it.", src=[H('tirmidhi:3537', 'RES_H2 1.1'), Q('2:222', 'RES_H2 1.1')], tags=['tawbah', 'relapse'], trig=['i keep doing it', 'repent again'])
    A('islamic', "The Qur'an speaks about lowering the gaze and guarding modesty, for men and women. Many people find that practical steps, like changing their environment, go along with that teaching.", src=[Q('24:30-31', 'RES_H2 4.3')], tags=['gaze', 'environment'], trig=['lower my gaze', 'is it haram'],
      dns=['Not a rebuke. Never "marry to fix it"; never "pray more instead".'])
    A('islamic', "The Prophet advised a person who was struck by a sudden glance to turn the eyes away. A slip of the eye is not the end of your worth.", src=[H('muslim:2159', 'RES_H2 4.3')], tags=['gaze', 'mercy'], trig=['sudden glance'])
    A('islamic', "You do not have to announce a private struggle to anyone. Scholars say that you can ask a trusted professional or scholar for help to the extent needed, without publicising it.", src=[H('bukhari:6069', 'RES_H2 2.4'), H('muslim:2990', 'RES_H2 2.4'), fq('Islamweb fatwa 393796 and Darul Ifta Birmingham fatwa 08109', 'RES_H2 2.4', 'institution')], tags=['sitr', 'privacy'], trig=['should i tell', 'confess'],
      dns=['Never "you must tell your family or imam".'])
    A('islamic', "Scholars differ on how to treat this, and I can't give a ruling. If you want to ask about a specific situation, a scholar you trust, ideally alongside a counsellor, can advise you.", src=[fq('Contrast: IslamOnline fatwa by Sheikh Ahmad al-Khalili advises admitting to Allah and a trusted Muslim and does not mention professional help', 'RES_H2 4.3', 'institution')], tags=['fiqh', 'scholar-handoff'], disputed=True, schools=['hanafi', 'shafii', 'maliki', 'hanbali'], ev='D', trig=['is it zina', 'ruling'])

    A('family', "If your partner has told you about this, your feelings matter too, and you don't have to cope on your own. A counsellor can help you, and you can ask for support for yourself without deciding anything about the relationship.", tags=['partner', 'family-of'], src=[CSBD], ev='C', trig=['my husband watches', 'my wife found out'],
      dns=['If there is coercion or abuse, move to the domestic abuse flow.'])
    A('summary', "What I've heard: it's a private struggle, you feel {topic}, and you'd like something to change. The next step is yours.", tags=['summary'], slots=['topic'])
    return [p]
