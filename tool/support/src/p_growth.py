"""Growth packs for Hadi: feeling close to Allah, goals and purpose, steady habits,
patience and gratitude, a fresh start, and everyday character. Practical "what can
I do" answers, drawn from verified Qur'an and hadith and from the app's own guides.
Every religious source is checked at build time (Qur'an text, hadith verdicts).
Tags beginning go- name a screen the answer offers as a button (see
KnowledgeAnswerer.routesFor); they are also retrieval words."""
from .know import kpack, K
from .sources import Q, HV, guide, xg

S = "Qur'an text"
AUTH = {'type': 'authored', 'title': 'Practical wording written for this app from the cited sources; scholar review needed'}


def _pk(name, desc, tags):
    p = kpack(name, name, desc, tags, audience='hadi')
    return (p,
            lambda *a, **k: K(p, 'fact', *a, **k),
            lambda *a, **k: K(p, 'howto', *a, **k),
            lambda *a, **k: K(p, 'faq', *a, **k))


def closeness():
    p, F, Hw, Fq = _pk('closeness_to_allah',
                       'Feeling close to Allah: what to do when you want to feel nearer, when prayer feels empty, how to be present in prayer, remembrance, the Qur\'an with meaning, the night prayer, and kindness as worship.',
                       ['closeness', 'spiritual'])
    Hw("Feeling close to Allah is something you can build, and it usually starts small. Slow your prayers down by a few breaths in each position. Say what you really mean in prostration, in your own words. After the prayer, stay seated for a short remembrance of Allah before you reach for your phone. Closeness grows through many small turns toward Him, not one big moment, and Allah says He answers each step you take toward Him with a bigger one.",
       [Q('2:152', S), Q('20:14', S), HV('bukhari:7405')], cross=[xg('huda-adhkar')],
       tags=['closeness', 'allah', 'closer', 'feel', 'feeling', 'presence', 'connection', 'go-adhkar'],
       trig=['feel closer to allah', 'feeling closer to allah', 'feel close to allah', 'feeling close to allah', 'feel allah', 'feeling allah',
             'feel his presence', 'feel connected to allah', 'feeling connected to allah', 'get closer to allah', 'closer to allah',
             'feeling closer', 'feel closer', 'connect with allah', 'draw nearer to allah', 'build a relationship with allah', 'relationship with allah'],
       dns=['Warm and practical; never imply the person is far from Allah or lacking faith.', 'Offer one or two steps, not a programme.'])
    Fq("Feeling nothing in prayer is common, and it does not mean your prayer is empty or that Allah has turned away. Hearts have seasons. The Prophet often asked Allah to make his heart firm, and you can ask the same. Keep praying, and change one thing: slow down, learn what you recite, or add a short voluntary prayer at a quiet time. Closeness often comes back through steady effort, not through waiting to feel it.",
       [HV('tirmidhi:3522'), HV('muslim:2655'), Q('57:16', S)], cross=[xg('huda-prayer')],
       tags=['prayer', 'feeling', 'empty', 'dry', 'heart', 'faith', 'go-adhkar'],
       trig=['feel nothing when i pray', 'feel nothing in prayer', 'pray but feel nothing', 'prayer feels empty', 'prayer feels dry', 'no feeling in prayer',
             'prayer feels like routine', 'prayer feels mechanical', 'feel nothing when i read quran', 'my heart feels hard', 'my heart feels dry'],
       dns=['Never say their faith is weak.', 'If they also describe low mood or hopelessness, the support path comes first, not this answer.'])
    Hw("To be more present in prayer: before you start, take a breath and remember who you are standing before. Learn the meaning of what you recite, even a few lines at a time. Pause in each position until you are still, as the Prophet taught. If your mind wanders, gently bring it back and carry on; you do not need to start over. A quiet corner and a phone left in another room help more than people expect.",
       [Q('23:1-2', S), Q('2:45', S), HV('bukhari:757')], cross=[xg('huda-prayer')],
       tags=['khushu', 'focus', 'prayer', 'distracted', 'concentration', 'wandering'],
       trig=['khushu', 'khushoo', 'focus in prayer', 'focus in salah', 'mind wanders in prayer', 'distracted in prayer', 'distracted in salah',
             'concentrate in prayer', 'concentrate in salah', 'be present in prayer', 'cant focus in prayer', 'how to pray with presence'],
       dns=['If the person describes intrusive doubts about wudu or prayer that distress them, point to the waswas support area instead.'])
    Hw("Remembrance gives the heart rest. Allah says hearts find peace in remembering Him. Choose a few short words and attach them to something you already do: after each prayer, on waking, before sleep, while you walk. The morning and evening adhkar in the app are a ready set. Little and often is better than long and rare.",
       [Q('13:28', S), Q('33:41', S), HV('bukhari:6408')], cross=[xg('huda-adhkar')],
       tags=['dhikr', 'remembrance', 'peace', 'heart', 'calm', 'go-adhkar'],
       trig=['how to do dhikr', 'ways to remember allah', 'peace of heart', 'peace in my heart', 'heart find rest', 'inner peace', 'how to remember allah more',
             'make dhikr a habit', 'where to start with dhikr'])
    Hw("The Qur'an softens hearts when you give it a little time each day. Read a small portion in a language you understand, slowly, and stop where a verse speaks to you. Say it back to yourself and ask what it asks of you today. Even a few verses with attention do more than many pages in a rush.",
       [Q('39:23', S), Q('8:2', S)], cross=[xg('huda-quran-daily')],
       tags=['quran', 'heart', 'soften', 'meaning', 'go-quran'],
       trig=['quran soften my heart', 'connect with the quran', 'feel the quran', 'read quran with meaning', 'understand the quran', 'quran touches my heart',
             'i read quran but feel nothing'])
    Hw("The night is a special time for closeness. Pray two rak'ahs in the last part of the night, even short ones, and make your dua. The Prophet told us that Allah comes down to the lowest heaven in the last third of the night and asks who is asking, so that He may give. Start with one night a week if every night is too much.",
       [HV('bukhari:1145'), Q('32:16', S)], cross=[xg('huda-tahajjud')],
       tags=['night', 'tahajjud', 'closeness', 'dua', 'last-third'],
       trig=['when is allah closest', 'closest to allah at night', 'last third of the night', 'night prayer for closeness', 'best time for dua'])
    Hw("Looking at what Allah made turns the heart toward Him. Spend a few quiet minutes outside or at a window, look at the sky, a tree, the changing light, and think about who made it all and why. Allah praises those who remember Him and reflect on the creation of the heavens and the earth.",
       [Q('3:190', S), Q('3:191', S)],
       tags=['reflection', 'creation', 'nature', 'gratitude', 'tafakkur'],
       trig=['reflect on creation', 'tafakkur', 'feel allah in nature', 'see allah in creation', 'ponder creation'])
    Fq("Allah hears you and He is near. He says that when His servants ask about Him, He is near and answers the one who calls. A reply does not always look like what you asked for, and the Prophet taught us not to give up by saying that we called and nothing came. Keep asking, and keep your thought of Allah good, because He is as His servant thinks of Him.",
       [Q('2:186', S), HV('bukhari:6340'), HV('bukhari:7405')],
       tags=['dua', 'allah', 'answer', 'hears', 'near', 'patience'],
       trig=['does allah hear me', 'will allah answer my dua', 'why is allah not answering', 'allah is not answering my dua', 'dua not answered', 'does allah listen to me', 'how do i know allah hears me'])
    Hw("Kindness is also a way to Allah. The Prophet said that whoever helps his brother with a need, Allah helps him with his own. Do one quiet good thing today for someone who cannot repay you, and keep it between you and Allah. Many people find that their heart opens through service when it feels closed in prayer.",
       [HV('bukhari:2442'), HV('tirmidhi:2018')], cross=[xg('huda-sadaqah')],
       tags=['kindness', 'service', 'closeness', 'help', 'good-deeds'],
       trig=['get closer to allah by helping', 'closeness through good deeds', 'kindness and closeness to allah', 'serve others for allah'])
    Fq("There is no fixed time for feeling close to Allah, and nobody can promise one. What the sources promise is that Allah guides those who strive for Him and is with those who do good. Pick a small daily practice, keep it for a few weeks, and notice what changes. Steady and small is what the Prophet said Allah loves most.",
       [Q('29:69', S), HV('bukhari:6464')],
       tags=['patience', 'closeness', 'steady', 'progress'],
       trig=['how long until i feel close to allah', 'when will i feel close to allah', 'how long does it take to feel allah', 'when will i feel it'])
    return [p]


def goals():
    p, F, Hw, Fq = _pk('goals_and_purpose',
                       'Setting and reaching goals with intention, planning, effort, du\'a and trust; choosing between options; motivation; and what to do when things do not work out.',
                       ['goals', 'purpose'])
    Hw("Work and trust go together. Make your intention clear, break the goal into a step small enough to do this week, start it, ask Allah for success in your own words, and accept the result calmly. Allah says a person gets what he strives for, and tells us to consult others, and once we have decided, to rely on Him.",
       [HV('bukhari:1'), Q('53:39', S), Q('3:159', S)], cross=[xg('huda-istikhara')],
       tags=['goals', 'success', 'plan', 'effort', 'dream', 'achieve', 'accomplish', 'ambition'],
       trig=['accomplish my goals', 'achieve my goals', 'reach my goals', 'how to achieve goals', 'succeed in my goals', 'help me accomplish', 'goals in life',
             'how to reach my dreams', 'help me succeed', 'make my goals come true', 'achieve my dreams'],
       dns=['Practical and encouraging; no promise of a particular outcome.'])
    Hw("Trust in Allah is not sitting still. The Prophet said that if you relied on Allah as He should be relied on, He would provide for you as He provides for the birds, which leave in the morning empty and come back full. They go out and work. Plan, act, then place the result with Allah, who is enough for the one who relies on Him.",
       [HV('tirmidhi:2344'), Q('65:3', S)],
       tags=['tawakkul', 'trust', 'rely', 'provision', 'rizq', 'plans'],
       trig=['tawakkul', 'trust in allah', 'rely on allah', 'how to trust allah', 'trust allah with my plans', 'leave it to allah', 'how to have tawakkul'])
    Hw("When motivation is low, shrink the task until it is almost too small to refuse: one page, five minutes, one phone call. Begin it, and let the habit carry you. The Prophet said that the deeds Allah loves most are the regular ones, even if small. Steady beats strong.",
       [HV('bukhari:6464')],
       tags=['motivation', 'lazy', 'procrastination', 'habit', 'steady'],
       trig=['no motivation', 'how to stay motivated', 'how to get motivated', 'cant stay motivated', 'procrastination', 'i keep procrastinating', 'how to stop being lazy'])
    Hw("When you cannot decide, do three things: gather facts and ask people who know the matter, pray the two rak'ahs of istikhara and ask Allah for what is best, then choose and move forward. Allah says that once you have decided, you rely on Him. You do not need a dream or a sign.",
       [Q('3:159', S)], cross=[xg('huda-istikhara')],
       tags=['decision', 'choose', 'istikhara', 'career', 'consult', 'go-istikhara'],
       trig=['how do i make a decision', 'cant decide', 'which path to choose', 'choosing a career', 'how to choose', 'hard decision', 'big decision'])
    Fq("If a plan fails or a door closes, that is allowed to hurt, and it is also not the end of the road. Learn what you can, adjust, and try again. Allah says He brings about what He wills and has set a measure for everything, and that whoever relies on Him, He is enough for him.",
       [Q('65:3', S), Q('2:216', S)],
       tags=['failure', 'disappointment', 'rejection', 'plans', 'regret', 'retry'],
       trig=['my plans failed', 'didnt get what i wanted', 'failed my goal', 'didnt get the job', 'got rejected', 'i failed my exam', 'my plan did not work', 'things did not work out', 'hopeless about my goals', 'give up on my goals', 'feel like giving up on my goals', 'my goals feel impossible'],
       dns=['If the person sounds hopeless rather than disappointed, move to the support path.'])
    Hw("Ordinary work becomes worship when it is done with a good intention. The Prophet said that deeds are by intentions. Earning to look after your family, studying to be useful, caring for a parent, each can be for Allah. Allah says He made us to worship Him, and worship is wider than the prayer mat.",
       [HV('bukhari:1'), Q('51:56', S)],
       tags=['purpose', 'meaning', 'intention', 'work', 'life', 'niyyah'],
       trig=['what is my purpose', 'purpose in life', 'meaning of my life', 'why am i here', 'how to find purpose', 'my life has no direction'],
       dns=['If the person says life has no point in a way that suggests hopelessness, support path first.'])
    Hw("Make dua for your goal and keep making it. The Prophet said your dua is answered as long as you are not impatient and say that you called and it was not answered. Ask for what you want, ask for what is best, and keep working. Allah is near and answers the one who calls.",
       [HV('bukhari:6340'), Q('2:186', S)],
       tags=['dua', 'success', 'goals', 'patience', 'ask'],
       trig=['dua for success', 'dua to achieve my goals', 'pray for my goals', 'how to make dua for what i want', 'dua for my plans'])
    Hw("A simple way to set goals for your deen: choose one prayer to improve, one small portion of Qur'an you will read, one short remembrance you will say each day, and one kind act each week. Keep it so small you cannot fail, hold it for a month, then add one more thing. Allah says to turn to Him with longing when you have finished your duties.",
       [HV('bukhari:6464'), Q('94:7-8', S)], cross=[xg('huda-quran-daily'), xg('huda-adhkar')],
       tags=['goals', 'deen', 'iman', 'plan', 'routine', 'growth', 'life', 'change', 'go-adhkar'],
       trig=['spiritual goals', 'goals for my deen', 'how to improve my iman', 'how to become more religious', 'how to improve myself spiritually', 'grow in my faith', 'strengthen my iman', 'change my life', 'turn my life around', 'new chapter in my life', 'success in this life and the next', 'successful in this life and the next', 'success in dunya and akhirah', 'dunya and akhirah'])
    return [p]


def habits():
    p, F, Hw, Fq = _pk('consistency_habits',
                       'Building steady worship and daily habits: starting small, tying a habit to something you already do, starting again after missing days without shame, the slump after Ramadan, and waking for Fajr.',
                       ['habits', 'consistency'])
    Hw("Start with the smallest version you can keep every day. The Prophet said that the deed most loved by Allah is the regular one, even if it is little. One short portion of Qur'an, two minutes of remembrance, one prayer prayed on time. Keep that for a few weeks before you add anything.",
       [HV('bukhari:6464')], cross=[xg('huda-quran-daily')],
       tags=['habit', 'consistency', 'steady', 'routine', 'regular', 'small'],
       trig=['build a habit', 'be consistent', 'stay consistent in prayer', 'consistency in worship', 'how to be consistent', 'how do i stay consistent', 'cant stay consistent', 'make worship a habit'],
       dns=['No streaks and no shaming: the owner ruled that the app never shames anyone for missing days.'])
    Hw("Tie the new habit to something you already do every day. After you pray, say your remembrance. After you wake, read a few verses. After you sit for the evening meal, name one blessing. The old habit reminds you of the new one, so you do not rely on remembering or on mood.",
       [HV('bukhari:6464'), Q('33:41', S)], cross=[xg('huda-adhkar')],
       tags=['habit', 'routine', 'anchor', 'daily', 'reminder', 'go-adhkar'],
       trig=['how to remember to read quran', 'how to remember my dhikr', 'daily routine', 'islamic daily routine', 'morning routine', 'how to start my day', 'habit stacking'])
    Fq("Missing a few days is not the end, and you do not have to start from zero or make up a guilt. Allah says not to despair of His mercy. Just do the smallest version today. The Prophet said to do what you are able to do, and the regular deed is the one loved most, so coming back is itself the habit.",
       [Q('39:53', S), Q('2:286', S), HV('bukhari:6464')], cross=[xg('huda-tawba')],
       tags=['missed', 'restart', 'again', 'slip', 'guilt', 'fell-off', 'consistency'],
       trig=['i missed days', 'i missed a few days', 'i broke my routine', 'fell off my routine', 'start again after missing', 'lost my routine', 'i stopped praying for a while', 'how to restart', 'how do i start again after stopping'],
       dns=['Never shame; do not count days or talk about streaks.', 'If the person says they have stopped praying altogether and feels hopeless, offer the fresh-start answer and the support path.'])
    Fq("A drop after Ramadan is very common, and the fix is to keep a small piece of it rather than all or nothing. Choose one thing that worked in Ramadan, for example a short night prayer, a daily portion of Qur'an, or a charity, and carry it forward at a smaller size. The deed loved most is the regular one, not the largest.",
       [HV('bukhari:6464')], cross=[xg('huda-fasting')],
       tags=['ramadan', 'after-ramadan', 'slump', 'iman', 'habit'],
       trig=['after ramadan i stopped', 'lost my iman after ramadan', 'ramadan high is gone', 'keep ramadan habits', 'how to keep ramadan habits', 'iman dropped after ramadan'])
    Hw("To wake for Fajr, start the night before: make the intention to pray, sleep soon after Isha, keep the phone away from the bed, and set the alarm across the room. Say the sleeping remembrance so you sleep with Allah in mind. If you oversleep, pray it as soon as you wake; it is still owed and still accepted.",
       [guide('huda-sleep'), Q('17:78', S)], cross=[xg('huda-sleep'), xg('huda-qada')],
       tags=['fajr', 'wake', 'sleep', 'alarm', 'routine', 'missing', 'missed', 'sleeping'],
       trig=['miss fajr', 'missing fajr', 'i keep missing fajr', 'i always sleep through fajr', 'sleep through my alarm for fajr', 'wake up for fajr', 'cant wake for fajr', 'how to wake up for fajr', 'miss fajr every day', 'sleep through fajr', 'fajr alarm'],
       dns=['No shaming for missed Fajr.'])
    return [p]


def patience():
    p, F, Hw, Fq = _pk('patience_gratitude',
                       'Patience (sabr) and gratitude (shukr) as everyday skills: how to practise each, contentment, envy and comparison, and ease after hardship.',
                       ['sabr', 'shukr', 'character'])
    Hw("Gratitude can be practised. Each night, name three things from the day you are thankful for and say alhamdulillah. Thank a person out loud once a day. Allah says that if you are grateful He will increase you, and the Prophet said a believer's affair is all good: thanks in ease, patience in hardship.",
       [Q('14:7', S), HV('muslim:2999')], cross=[xg('huda-gratitude')],
       tags=['gratitude', 'shukr', 'thankful', 'blessings', 'alhamdulillah'],
       trig=['how to be grateful', 'practice gratitude', 'shukr', 'feel thankful', 'how to be thankful to allah', 'i am ungrateful', 'count my blessings'])
    Hw("Patience is not feeling nothing. It is not letting the pain decide what you do. Cry if you need to, then breathe, pray, and ask Allah for help. Allah says to seek help through patience and prayer, and that He is with the patient. The Prophet said that patience is at the first strike of a hardship, and that whoever tries to be patient, Allah makes him patient.",
       [Q('2:153', S), HV('bukhari:1302'), HV('bukhari:1469')], cross=[xg('huda-hardship')],
       tags=['sabr', 'patience', 'hardship', 'pain', 'endure', 'difficult'],
       trig=['how to be patient', 'sabr', 'patience in hardship', 'how to have patience', 'how to deal with hardship', 'how to be patient with allah', 'how do i have sabr'],
       dns=['If the person describes heavy distress, acknowledge it and offer the support path before advice.'])
    Fq("Hardship is not a sign that Allah has left you. Allah says that with hardship there is ease, and He repeats it twice. The Prophet said that everything is good for a believer, patience in a trial and thanks in comfort. Ease may not come as fast or in the shape you expect, but it is promised.",
       [Q('94:5-6', S), HV('muslim:2999')], cross=[xg('huda-hardship')],
       tags=['hardship', 'ease', 'test', 'hope', 'trial', 'relief'],
       trig=['when will it get easier', 'hardship and ease', 'why am i being tested', 'why does allah test me', 'does hardship ever end', 'ease after hardship'],
       dns=['Hopeful and gentle; no claim that suffering is deserved.'])
    Hw("Comparison steals contentment. When you notice envy, wish good for the person quietly, say alhamdulillah for something of your own, and step away from what feeds it. The Prophet taught not to envy one another, and that whoever holds back from asking people, Allah makes him content.",
       [HV('bukhari:6065'), HV('bukhari:1469')],
       tags=['envy', 'jealous', 'contentment', 'comparison', 'comparing', 'qanaah'],
       trig=['how to stop comparing myself', 'stop comparing myself', 'i compare myself to others', 'i am jealous', 'how to stop envy', 'contentment', 'how to be content', 'how to be happy with what i have'])
    return [p]


def fresh_start():
    p, F, Hw, Fq = _pk('fresh_start_hope',
                       'Starting again after wrong: how repentance works, that the door is open, what to do first, and keeping hope.',
                       ['tawbah', 'hope'])
    Fq("Yes, you can start again. Allah says not to despair of His mercy, because He forgives all sins to the one who returns. The Prophet taught that Allah accepts repentance until the last breath, and that Allah forgives a servant who sins, asks forgiveness, and repeats it. The door is open today.",
       [Q('39:53', S), HV('tirmidhi:3537'), HV('muslim:2758')], cross=[xg('huda-tawba')],
       tags=['tawbah', 'repentance', 'forgiveness', 'fresh-start', 'mercy', 'hope', 'allah', 'go-tawba'],
       trig=['can i start again', 'fresh start', 'new beginning', 'can i repent', 'will allah accept my repentance', 'start over with allah', 'can allah forgive me', 'will allah forgive me', 'does allah forgive everything', 'would allah forgive me', 'is it too late to repent', 'how to return to allah', 'i feel guilty about what i did', 'i feel so guilty', 'guilty about my sins'],
       dns=['No lecture about sin. Hope first. If the person describes despair or self-harm, support path and crisis flow come first.'])
    Hw("Repentance has plain steps: stop what you can stop today, feel real regret, decide not to return, and put right what you owe to people. Then ask Allah for forgiveness in your own words and follow it with a good deed. If you slip, you begin again, because the door does not close.",
       [guide('huda-tawba'), Q('66:8', S)], cross=[xg('huda-tawba')],
       tags=['tawbah', 'repentance', 'steps', 'forgiveness', 'return', 'go-tawba'],
       trig=['how to repent', 'how to make tawbah', 'steps of repentance', 'how do i repent', 'conditions of tawbah', 'how to ask allah for forgiveness'])
    Fq("Allah is happy when you return. The Prophet said that Allah is more pleased with the repentance of His servant than a man who finds his lost mount in the desert. You are not a burden to Him; coming back is the thing He loves.",
       [HV('muslim:2747'), HV('bukhari:6309')],
       tags=['tawbah', 'mercy', 'love', 'return', 'acceptance'],
       trig=['does allah still love me', 'will allah still accept me', 'is allah angry with me', 'allah is happy when i return'])
    Fq("Do not lose hope. The Prophet taught that Allah created mercy in a hundred parts and sent down only one to all of creation. Had anyone known all the mercy Allah holds, he would not lose hope of Paradise. Hope and effort go together: do what you can, and trust the rest to His mercy.",
       [HV('bukhari:6469'), Q('39:53', S)],
       tags=['hope', 'mercy', 'despair', 'forgiveness'],
       trig=['dont lose hope', 'i lost hope in allah', 'mercy of allah', 'how to keep hope', 'how to stay hopeful'],
       dns=['If the person says there is no hope for their life, not just their faith, use the support path.'])
    return [p]


def character():
    p, F, Hw, Fq = _pk('growth_everyday',
                       'Everyday growth: becoming a better person one trait at a time, using prayer times to organise the day, learning step by step, and giving small.',
                       ['growth', 'character'])
    Hw("Grow one trait at a time. Choose one, for example patience, honesty, or gentle speech, and watch for it for a week. The Prophet said the most beloved to him and the closest to him on the Day of Judgement are those with the best character. Small daily choices build it, and the Character course in the app goes through it step by step.",
       [HV('tirmidhi:2018')], cross=[xg('huda-speech')],
       tags=['character', 'akhlaq', 'better', 'person', 'manners', 'improve', 'go-character'],
       trig=['become a better person', 'how to be a better muslim', 'improve my character', 'how to improve myself', 'self improvement', 'how to grow as a person', 'better version of myself', 'work on my character', 'have good manners', 'good manners', 'good character', 'be more polite'])
    Hw("Let the five prayers organise your day. They are decreed at set times, so build your day around them: work and study in the spaces between, and use the minute after each prayer for a short plan for what is next. Many people find the day feels calmer when the prayer is the anchor, not the interruption.",
       [Q('4:103', S)], cross=[xg('huda-prayer-times')],
       tags=['schedule', 'productivity', 'prayer-times', 'day', 'organise'],
       trig=['manage my time', 'time management', 'organize my day', 'be more productive', 'productive muslim', 'plan my day', 'i waste time'])
    Hw("Learn in small steps. Pick one topic you care about, spend ten minutes a day on it, and write down one thing you learned. The Prophet said that if Allah wants good for someone, He gives him understanding of the religion. The Seeking Knowledge guide and the Academy in the app are good places to begin.",
       [HV('bukhari:71')], cross=[xg('huda-knowledge')],
       tags=['learning', 'knowledge', 'study', 'islam', 'academy'],
       trig=['where do i start learning', 'how to increase my knowledge', 'how to study islam', 'how to learn islam', 'i want to learn more about islam', 'how to grow in knowledge'])
    Hw("Give a little, often. Charity does not decrease wealth, the Prophet said, and forgiveness and humility raise a person in honour. A small sum on a regular day, a meal sent to a neighbour, a kind message, each counts. You can start today with something small enough that you will repeat it.",
       [HV('muslim:2588')], cross=[xg('huda-sadaqah')],
       tags=['charity', 'giving', 'kindness', 'sadaqah', 'generosity'],
       trig=['how to be generous', 'small charity ideas', 'sadaqah ideas', 'how to give charity regularly', 'how to be kind', 'how to be more generous'])
    return [p]


def build():
    out = []
    for f in (closeness, goals, habits, patience, fresh_start, character):
        out.extend(f())
    return out
