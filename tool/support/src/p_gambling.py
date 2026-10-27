from .lib import Pack
from .sources import H, Q, bg, clin, fq


def build():
    p = Pack('gambling', 'support', 'gambling', 'hadi',
             'Gambling, betting, gaming loot boxes and trading-as-betting: listening, debt and safety hand-over, faith framing without shame.',
             base_tags=['gambling'])
    A = p.add
    CBT = bg('RES_H1 3.9', 'Self-exclusion, spending limits and urge delay are standard gambling-treatment content (no source opened); clinician to confirm.')
    DEBT = bg('RES_H1 6', 'Debt, gambling and self-harm risk: debt advice and a doctor are the routes; clinician to confirm.')
    SUI = clin('who_suicide')

    A('orient', "I'm an app, not a counsellor or a money adviser. I can listen, help you think, and point you to people who can help with gambling and with debt. What's going on for you?", tags=['opening', 'honesty'])
    A('orient', "This is a private space with no judgement. I can't fix the money side, but I can help you find someone who can. Where would you like to start?", tags=['opening', 'honesty'])
    A('orient', "Is this about betting, cards, casino games, an app, or gaming with in-game purchases? Any of them is fine to talk about.", tags=['opening', 'door'])

    A('reflect', "It sounds like gambling has taken more than money from you.", tags=['concern'])
    A('reflect', "Part of you hopes the next bet will fix it, and part of you knows it might not.", tags=['ambivalence', 'chasing'])
    A('reflect', "It sounds like you are carrying this and the worry about money all alone.", tags=['isolation', 'debt'])
    A('reflect', "You're afraid of what happens when people find out.", tags=['secrecy', 'fear'])
    A('reflect', "It sounds like the rush and the regret come as a pair.", tags=['ambivalence'])
    A('reflect', "You want to protect the people who depend on you.", tags=['family', 'values'])

    A('ask', "What would you most like to be different about gambling?", tags=['goal', 'change-talk'])
    A('ask', "When do you feel the pull strongest?", tags=['trigger'])
    A('ask', "What has helped on the days you didn't bet?", tags=['strengths'])
    A('ask', "Is the money side the most urgent thing right now, or is it how you feel?", tags=['priority'])
    A('ask', "Who knows about the money situation, if anyone, and who would you trust with it?", tags=['support'], dns=['Never push disclosure.'])
    A('ask', "Has any of this made you feel that life isn't worth it?", tags=['safety-check', 'suicide'], risk='high', ask=True,
      src=[SUI, bg('RES_H1 6', 'Gambling and debt carry raised suicide risk (brief); ask directly and kindly.')],
      dns=['If yes, move to the crisis flow; do not carry on with gambling advice.'])

    A('affirm', "Talking about money and gambling is hard. Thank you for trusting me with it.", tags=['effort'])
    A('affirm', "Wanting to stop chasing losses takes real honesty.", tags=['effort', 'honesty'])
    A('affirm', "You're looking for a way through, and that matters.", tags=['effort', 'hope'])

    A('explain', "Gambling problems are common, and people do recover. Support usually combines talking help, practical steps with money, and often peers who have been there.", src=[CBT], tags=['hope', 'treatment'], ev='C',
      trig=['can i stop', 'is there hope'])
    A('explain', "Many places let you block yourself from betting sites, apps and venues. This is called self-exclusion, and it takes the decision out of the moment. A helpline can tell you what exists where you live.", src=[CBT], tags=['self-exclusion'], ev='C',
      trig=['block betting', 'self exclusion', 'ban myself'])
    A('explain', "Chasing losses, betting more to win back what you lost, is one of the most common traps. Stopping the chase is hard, and it is a good thing to bring to a counsellor.", src=[CBT], tags=['chasing'], ev='C',
      trig=['win it back', 'chasing', 'one more bet'])
    A('explain', "Free, confidential debt advice exists in many countries, and advisers have seen this before. Contact one before you borrow more, and before you sign anything.", src=[DEBT], tags=['debt', 'advice'], ev='C',
      trig=['loan', 'debt', 'owe', 'borrowed'])
    A('explain', "Some games and apps use loot boxes and similar tricks that work like betting. If this is about gaming, the same support applies, and you are not silly for finding it hard to stop.", src=[bg('RES_H1 10.6', 'Loot-box evidence was not researched; clinician to confirm.')], tags=['loot-boxes', 'gaming'], ev='C', age=['13-17', 'adult'],
      risk='medium', trig=['loot box', 'fifa packs', 'skins', 'in-app purchases'])

    A('plan-step', "One small step: ask the bank or the betting provider about blocking gambling payments or setting a limit you can't change in the moment. Want help working out what to say?", tags=['limits', 'script'], src=[CBT], ask=True, ev='C')
    A('plan-step', "One small step: tell yourself you'll wait fifteen minutes before any bet, and do one other thing in that time, like a walk, wudu or a call. Shall we choose that thing now?", tags=['delay', 'urge'], src=[CBT], ask=True, ev='C')
    A('plan-step', "One small step: write down what you owe, to whom, and the dates. You don't have to fix it today, but a clear list helps an adviser help you.", tags=['debt', 'list'], src=[DEBT], ask=True, ev='C')

    A('safety', "If you feel you can't go on because of the money or the gambling, you matter more than any debt. Please contact your emergency number or a crisis line now. The lines for your country are listed below.", tags=['suicide', 'crisis'], src=[SUI, clin('who_mhgap')], risk='high',
      trig=['kill myself', 'end it', 'cannot go on', "can't face them"], dns=['Join with helplines.json scope suicide; do not minimise.'])
    A('safety', "If someone is threatening or frightening you over what you owe, please contact the police or a local advice service. You shouldn't have to handle that on your own.", tags=['threat', 'loan-sharks'], src=[DEBT], ev='C', risk='high',
      trig=['loan shark', 'threatening me', 'collectors'])

    A('referral', "A gambling helpline can listen, and often offers counselling and a way to block gambling. The lines for your country are listed below, and I can show them again whenever you like.", tags=['helpline'], dns=['Join with helplines.json scope addiction or gambling; never type a number.'], trig=['helpline', 'who can i call'])
    A('referral', "A debt adviser can talk to the people you owe and work out a plan. In many places this is free. You could say: \"I'm in debt because of gambling and I'd like help with a plan.\"", tags=['debt', 'script'], src=[DEBT], ev='C', trig=['debt advice'])
    A('referral', "A doctor can help if gambling is linked to low mood, worry or sleep. You could say: \"I've been gambling and I'm struggling to stop.\"", tags=['doctor', 'script'])

    A('islamic', "Gambling is not what defines you. The Qur'an says Allah is the one who accepts repentance, and tells people who have gone too far not to despair of His mercy.", src=[Q('39:53'), Q('4:28')], tags=['mercy', 'shame'], trig=['allah will not forgive', 'i am a gambler'])
    A('islamic', "The Qur'an names gambling together with intoxicants and says their harm is greater than their benefit, and that Satan wants to create enmity and keep people from remembrance of Allah. Many people find this a reason to protect themselves with practical steps, not only guilt.", src=[Q('2:219', 'RES_H2 3.1'), Q('5:90-91', 'RES_H2 3.1')], tags=['maysir', 'meaning'], trig=['is gambling haram', 'why is gambling haram'],
      dns=['Do not use as a rebuke; the ruling is not disputed, the tone is the point.'])
    A('islamic', "Scholars differ on whether money won through gambling can be kept or must be given away. I can't give a ruling. A scholar you trust can help you with that and with any debts you owe.", src=[fq('Muftionline (South Africa) answer on gambling debts; NZF Knowledge Bank on zakat to debtors', 'RES_H2 4.2', 'institution'),
      bg('RES_H2 11', 'No fatwa on winnings was opened (RES_H2 gaps); scholars to supply.')], tags=['winnings', 'debt', 'fiqh'], disputed=True, schools=['hanafi', 'maliki', 'shafii', 'hanbali'], ev='C',
      trig=['can i keep the winnings', 'haram money', 'what do i do with the money'], dns=['Never state a ruling on winnings. Scholar to approve.'])
    A('islamic', "Making a plan and asking for help is part of relying on Allah, not a lack of it. The Prophet said to tie your camel and then trust.", src=[H('tirmidhi:2517', 'RES_H2 2.5')], tags=['tawakkul', 'action'], trig=['just trust allah'])
    A('islamic', "The Prophet taught that a person in hardship should be given time to repay. If you are in debt, asking for time, or for help with a plan, is not shameful.", src=[H('muslim:1563', 'RES_H2 4.2')], tags=['debt', 'mercy'], trig=['i cannot repay', 'cannot pay back'])
    A('islamic', "The Prophet taught a supplication asking Allah to suffice you with what is lawful so that you need not turn to what is forbidden. Many people in debt find it comforting.", src=[H('tirmidhi:3563', 'RES_H2 4.2')], tags=['dua', 'debt'], trig=['dua for debt'],
      dns=['Arabic of the dua only via the verified phrase registry; none typed here.'])

    A('family', "If someone you love gambles, you did not cause it and you can't control it. You can protect your own money and peace, and find support for families. Would you like to hear about that?", tags=['family-of'], ask=True, src=[CBT], ev='C',
      trig=['my husband gambles', 'my son bets', 'my father gambled'])
    A('summary', "So far: {topic} is weighing on you, you'd like the gambling and the money to feel different, and the next step is yours to choose.", tags=['summary'], slots=['topic'])
    A('summary', "What I've heard: you want to stop chasing, you're worried about {topic}, and you're ready to talk to someone. Does that sound right?", tags=['summary'], slots=['topic'], ask=True)
    return [p]
