"""Second set of growth packs for Hadi: character in daily life (anger, forgiveness,
the tongue, humility, sincerity), family roles, work money and study, questions of
faith and heart (suffering, doubt, worry, peace), and improving worship. Practical
"what can I do" answers from verified Qur'an and hadith and the app's own guides.
Tags beginning go- name a screen offered as a button."""
from .know import kpack, K
from .sources import Q, HV, guide, xg

S = "Qur'an text"


def _pk(name, desc, tags):
    p = kpack(name, name, desc, tags, audience='hadi')
    return (p,
            lambda *a, **k: K(p, 'howto', *a, **k),
            lambda *a, **k: K(p, 'faq', *a, **k))


def inner_character():
    p, Hw, Fq = _pk('character_in_daily_life',
                    'Anger, forgiving someone who hurt you, guarding the tongue and gossip, humility, and keeping your intention sincere.',
                    ['character', 'akhlaq'])
    Hw("Anger is a wave you can learn to ride. Say that you seek refuge in Allah, sit down if you are standing, lie down if you are sitting, and make wudu with cool water. Stay quiet until it drops, because words said in anger are the ones people regret. The Prophet said the strong person is the one who controls himself in anger.",
       [HV('bukhari:6114'), Q('3:134', S)], cross=[xg('huda-speech')],
       tags=['anger', 'angry', 'temper', 'control', 'calm', 'rage', 'go-character'],
       trig=['stop being angry', 'control my anger', 'i get angry easily', 'anger problem', 'how to calm down when angry', 'i lose my temper', 'how to stop shouting', 'i am always angry'],
       dns=['If anger is with violence or fear of harming someone, move to safety and support; do not give a lecture.'])
    Hw("Forgiving does not mean saying it did not hurt. It means choosing not to carry it. Start by asking Allah to ease your heart, wish the person guidance, and decide that you will not take revenge. You can forgive and still keep distance or set limits. Allah loves those who pardon, and the Prophet said forgiving raises a person in honour.",
       [Q('42:40', S), Q('24:22', S), HV('muslim:2588')], cross=[xg('huda-hardship')],
       tags=['forgive', 'forgiveness', 'hurt', 'grudge', 'pardon', 'betrayed', 'resentment'],
       trig=['forgive someone who hurt me', 'how do i forgive', 'how to forgive someone', 'i cant forgive', 'hard to forgive', 'let go of a grudge', 'someone betrayed me', 'let go of resentment'],
       dns=['Never push someone to reconcile with an abuser; forgiving is not staying in danger.'])
    Hw("To guard the tongue, pause before you speak and ask: is it true, is it needed, is it kind. The Prophet said whoever believes in Allah and the Last Day should speak good or stay silent. Backbiting is saying about someone what they would dislike, even if it is true. When a conversation turns that way, change the subject or leave it, and make dua for the person.",
       [HV('bukhari:6018'), HV('muslim:2589'), Q('49:12', S)], cross=[xg('huda-speech')],
       tags=['tongue', 'gossip', 'gossiping', 'backbiting', 'ghibah', 'speech', 'words', 'go-character'],
       trig=['how to stop gossiping', 'control my tongue', 'stop gossiping', 'how to stop backbiting', 'i gossip too much', 'avoid ghibah', 'how to watch my words', 'stop talking about people'])
    Hw("Humility is not thinking little of yourself; it is not thinking of yourself too much. Serve someone without being asked, accept advice without arguing, thank people who teach you, and say I do not know when you do not. The Prophet said Allah revealed that you should be humble so that none boasts over another.",
       [HV('muslim:2865'), Q('25:63', S)],
       tags=['humble', 'humility', 'pride', 'arrogance', 'ego', 'modest'],
       trig=['become more humble', 'how to be humble', 'i am too proud', 'how to remove arrogance', 'how to remove pride', 'how to control my ego'])
    Hw("Keeping your intention sincere is an ongoing job. Before an act of worship, take one breath and say silently that it is for Allah. If you notice you want to be seen, do not stop the good deed; just correct the intention and carry on. Do some good in secret that only Allah knows. The Prophet said deeds are by intentions.",
       [HV('bukhari:1'), Q('98:5', S), Q('107:4-6', S)],
       tags=['intention', 'niyyah', 'sincerity', 'ikhlas', 'riya', 'showing-off', 'pure'],
       trig=['make my intention sincere', 'purify my intention', 'avoid showing off in worship', 'how to avoid riya', 'riya', 'ikhlas', 'sincerity in worship', 'keep my niyyah pure', 'pure intention', 'how to keep my intention pure', 'how to be sincere to allah'])
    Hw("To leave a sin, make it harder to reach and fill the gap. Remove what triggers it, change your company and your routine, and replace it with something good at the same time of day. When you slip, do not wait: make tawbah at once and do a good deed after it. Allah says good deeds wipe out bad ones, and the door of tawbah stays open.",
       [Q('11:114', S), HV('tirmidhi:1987'), Q('39:53', S)], cross=[xg('huda-tawba')],
       tags=['sin', 'sinning', 'haram', 'temptation', 'bad-habit', 'quit', 'go-tawba'],
       trig=['stop sinning', 'how to stop sinning', 'stay away from haram', 'how to leave a sin', 'i keep falling into the same sin', 'how to stop a bad habit', 'overcome temptation', 'i keep doing the same sin'],
       dns=['No shaming. If the matter is addiction, point to the support area for that topic.'])
    Hw("Good company matters more than people admit. The Prophet compared a good companion to a perfume seller and a bad one to a blacksmith: one gives you something or a pleasant scent, the other may burn your clothes or leave a bad smell. Spend more time with people who remind you of Allah, and stay kind to the rest without following them.",
       [HV('bukhari:2101'), Q('18:28', S)],
       tags=['friends', 'friendship', 'company', 'peer', 'pressure', 'influence', 'community'],
       trig=['peer pressure', 'handle peer pressure', 'bad friends', 'how to find good friends', 'make friends in the community', 'make friends', 'friends in the community', 'how to make muslim friends', 'friends who pull me away', 'lonely as a muslim'])
    Hw("With a difficult person at work or in the family, answer what is bad with what is better. Allah says that good and evil are not equal, and that then the one between whom and you was enmity may become like a close friend. Stay calm, keep your voice low, say what you need once and clearly, and keep your own conduct clean. You do not have to let anyone mistreat you; set limits politely, and speak to someone senior if needed.",
       [Q('41:34-35', S), Q('25:63', S)], cross=[xg('huda-speech')],
       tags=['coworker', 'boss', 'colleague', 'difficult', 'conflict', 'workplace', 'toxic', 'neighbour'],
       trig=['difficult coworker', 'difficult boss', 'deal with a difficult person', 'toxic coworker', 'a person at work hates me', 'i have a conflict at work', 'how to deal with rude people', 'my boss is unfair'],
       dns=['If it is harassment or abuse, tell them to report it and seek help; do not tell them to just be patient.'])
    return [p]


def family_roles():
    p, Hw, Fq = _pk('family_roles_growth',
                    'Being better to parents, as a husband or wife, finding a spouse, and bringing up children in the deen with warmth.',
                    ['family', 'relationships'])
    Hw("Your parents hold a special place: Allah places kindness to them right after worshipping Him. Call or visit more often than you think you need to, say thank you, speak softly even when you disagree, make dua for them, and help without being asked. When they are hard to live with, patience and gentle speech are still your part. A person asked who most deserved his good company, and the Prophet said his mother, three times.",
       [Q('17:23-24', S), HV('bukhari:5971'), Q('31:14', S)], cross=[xg('huda-parents')],
       tags=['parents', 'mother', 'father', 'relationship', 'kindness', 'elderly', 'go-character'],
       trig=['improve my relationship with my parents', 'be better to my parents', 'how to treat my parents', 'my parents and i fight', 'how to make my mother happy', 'honour my parents', 'parents are difficult'],
       dns=['If the parent is abusive, safety first; do not tell the person to endure harm.'])
    Hw("To be a better husband, be gentle, listen, share the work at home, and speak well of her to others. The Prophet said the best of you are the best to your families, and that he was the best to his. Money and provision matter, and so do time and warmth. Ask her what would make her feel looked after, then do one of those things this week.",
       [Q('30:21', S), Q('4:19', S), HV('tirmidhi:3895')], cross=[xg('huda-nikah')],
       tags=['husband', 'marriage', 'spouse', 'better', 'wife', 'mawaddah'],
       trig=['better husband', 'be a good husband', 'how to be a better husband', 'how to treat my wife', 'how to please my wife', 'husband duties'])
    Hw("To be a better wife, the same marriage rules of kindness and respect apply to both. Speak openly and kindly, thank him for what he does, protect his trust, and agree on how you run the home together. Allah says He placed love and mercy between spouses, and marriage grows when both give more than they take.",
       [Q('30:21', S), Q('4:19', S)], cross=[xg('huda-nikah')],
       tags=['wife', 'marriage', 'husband', 'spouse', 'better', 'mawaddah'],
       trig=['better wife', 'be a good wife', 'how to be a better wife', 'how to treat my husband', 'wife duties', 'how to keep my marriage strong'])
    Hw("When looking for a spouse, start with character and deen, then make istikhara and ask people you trust who know the person. The Prophet advised choosing the one who is religious. Pray, be honest about your expectations, involve your family, and do not rush. Allah says that He will enrich those who are single if they are righteous.",
       [HV('bukhari:5090'), Q('24:32', S)], cross=[xg('huda-istikhara'), xg('huda-nikah')],
       tags=['spouse', 'marriage', 'nikah', 'istikhara', 'single', 'proposal'],
       trig=['find a spouse', 'how do i find a spouse', 'looking for marriage', 'how to find a husband', 'how to find a wife', 'i want to get married', 'how to choose a spouse', 'cant find someone to marry'])
    Hw("Teach children to pray by praying with them, not by pressure. Let them stand beside you from about age three or four, make it warm and short, praise effort, and start seriously around seven. Say the words aloud, show them the movements, and make dua for them by name. Allah says to order your family to pray and be steady on it yourself.",
       [Q('20:132', S), Q('66:6', S)], cross=[xg('huda-children-deen')],
       tags=['children', 'kids', 'teach', 'prayer', 'parenting', 'family', 'tarbiyah'],
       trig=['teach my kids to pray', 'teach my children to pray', 'my child wont pray', 'get my kids to pray', 'how to raise muslim kids', 'how to make my children love islam', 'raise my kids in islam'])
    Hw("Children copy what they see more than what they hear. Be the person you want them to become: let them see you pray, say sorry, speak gently, and be honest. Keep the home calm, keep Islam warm, and keep talking with them so they bring their questions to you. Make dua for them often; it is a duty and a gift.",
       [Q('25:74', S), Q('31:17', S)], cross=[xg('huda-children-deen')],
       tags=['role-model', 'parenting', 'children', 'example', 'home', 'teens'],
       trig=['good role model for my kids', 'be a role model', 'raise good children', 'raising teenagers in islam', 'my teenager is drifting', 'good parent', 'how to be a better parent'])
    return [p]


def work_money_study():
    p, Hw, Fq = _pk('work_money_study_growth',
                    'Halal income and finding work, managing money, steady study and exam stress, discipline, time and the phone.',
                    ['work', 'money', 'study'])
    Hw("Seek halal income and work with your own hands where you can. The Prophet said no one eats better food than that earned by his own work. Avoid anything with interest, deceit or harm, be honest in dealings, and accept less rather than something doubtful. Allah is the provider, and He says that those who are mindful of Him get a way out and provision from where they do not expect.",
       [HV('bukhari:2072'), Q('2:168', S), Q('65:2-3', S)], cross=[xg('huda-earning')],
       tags=['halal', 'income', 'job', 'work', 'rizq', 'earning', 'career', 'provision'],
       trig=['find a halal job', 'halal income', 'make halal income', 'how to earn halal', 'halal work', 'choosing a career as a muslim', 'is my job halal', 'i cant find a job'],
       dns=['No rulings on specific jobs or products; point to the Earning guide and a scholar for a specific case.'])
    Hw("To manage money well, spend on needs before wants, give something first however small, avoid debt you do not need, and keep a simple record. The Prophet said it is better to cut wood and sell it than to go asking people. Pay what you owe on time. Zakat purifies what is left, and Allah says to be neither miserly nor wasteful.",
       [Q('25:67', S), Q('17:29', S), HV('bukhari:1470')], cross=[xg('huda-zakat')],
       tags=['money', 'budget', 'spending', 'debt', 'savings', 'finance', 'wealth'],
       trig=['manage money as a muslim', 'how to manage my money', 'i am in debt', 'how to budget', 'save money islam', 'stop wasting money', 'how to get out of debt'],
       dns=['No investment advice; the app is not a licensed adviser.'])
    Hw("For exam stress, make a plan you can keep: short blocks, rest between them, sleep, and a prayer when you feel tight. Ask Allah for ease with the dua of Musa: my Lord, expand my chest and ease my task. Do your best, and place the result with Him. Stress is not a sign you are failing; it means this matters to you.",
       [Q('20:25-28', S), Q('94:5-6', S), Q('65:3', S)], cross=[xg('huda-knowledge')],
       tags=['exam', 'exams', 'stress', 'study', 'student', 'anxious', 'school', 'university'],
       trig=['exam stress', 'stressed about exams', 'how to study for exams', 'i am scared of my exam', 'dua for exams', 'study as a muslim', 'i cant focus on studying', 'how to study better'],
       dns=['If stress sounds like panic or hopelessness, move to the student support area.'])
    Hw("Discipline grows from small promises kept. Choose one daily act, tie it to a fixed time, remove the thing that pulls you away, and start the same minute each day. The Prophet said that many people lose two blessings: health and free time. A short, steady habit beats a big plan you drop.",
       [HV('bukhari:6412'), HV('bukhari:6464')],
       tags=['discipline', 'laziness', 'lazy', 'phone', 'procrastination', 'focus', 'productivity'],
       trig=['be more disciplined', 'how to be disciplined', 'overcome laziness', 'i am lazy', 'stop wasting time on my phone', 'phone addiction', 'too much screen time', 'how to use my time well', 'i waste my time'],
       dns=['Never shame; one small step.'])
    Hw("Being busy does not close the door to the Qur'an. Allah says to recite what is easy. Read one page or even a few verses a day, listen while you travel, and keep one verse in mind through the day. Learning and teaching the Qur'an is the best of deeds, so start small and stay with it.",
       [Q('73:20', S), HV('bukhari:5027')], cross=[xg('huda-quran-daily')],
       tags=['quran', 'busy', 'learn', 'daily', 'recite', 'go-quran'],
       trig=['learn the quran when i am busy', 'no time for quran', 'how to read quran daily', 'how to start reading quran', 'how to finish the quran', 'make time for the quran', 'learn quran as an adult'])
    return [p]


def faith_heart():
    p, Hw, Fq = _pk('faith_and_heart',
                    'Hard questions of faith and heart: why there is suffering, trusting Allah\'s plan, doubts, feeling like a hypocrite, worry, fear, and finding peace.',
                    ['faith', 'heart'])
    Fq("Suffering is one of the hardest questions, and the answer is not simple. The Qur'an says life is a test, that Allah will try people with fear, hunger and loss, and that the patient are given glad tidings. The Prophet said that no tiredness, illness, worry or sorrow touches a believer without Allah wiping away some of their sins for it. Your pain is real, it is not hidden from Allah, and it is not wasted.",
       [Q('2:155-157', S), Q('67:2', S), HV('bukhari:5641')], cross=[xg('huda-hardship')],
       tags=['suffering', 'test', 'pain', 'evil', 'why', 'hardship', 'injustice', 'allah-allows'],
       trig=['why does allah allow suffering', 'why does allah let bad things happen', 'why is there suffering', 'why does allah test me', 'why is life so hard', 'why do good people suffer', 'why did this happen to me'],
       dns=['Do not say suffering is deserved or a punishment. Be gentle; if grief or despair is heavy, the support path comes first.'])
    Hw("Trusting Allah's plan means doing your part and calming your heart about the rest. You may dislike something that is good for you and love something that is bad, and Allah knows while you do not. Make dua for what you want, keep working, and when a door closes, ask for what is better. Allah is enough for the one who relies on Him.",
       [Q('2:216', S), Q('65:3', S), HV('bukhari:6340')], cross=[xg('huda-istikhara')],
       tags=['trust', 'plan', 'qadar', 'tawakkul', 'decree', 'wisdom', 'acceptance'],
       trig=['trust allah\'s plan', 'trust allahs plan', 'how to accept qadr', 'accept allahs decree', 'allah has a plan', 'why did allah take this from me', 'how do i accept what happened'])
    Hw("Doubts come to everyone, and having them is not disbelief. When such thoughts arise, the Prophet taught to say that you believe in Allah and stop dwelling on them. Ask your questions openly, read the answers, and speak with someone who knows. Do not let a thought you dislike convince you that you have lost your faith.",
       [HV('muslim:134'), Q('2:260', S)], cross=[xg('huda-knowledge')],
       tags=['doubt', 'doubts', 'faith', 'questions', 'iman', 'whisper', 'atheism', 'unsure'],
       trig=['doubt in my faith', 'i have doubts about islam', 'i doubt allah', 'question my faith', 'losing my faith', 'is it wrong to doubt', 'i am not sure i believe', 'thoughts against allah'],
       dns=['Never call the person a disbeliever. If the thoughts are intrusive and distressing, point to the waswas support area.'])
    Fq("Feeling like a hypocrite worries only people who care about sincerity. The Companion Hanzala felt the same when his heart changed between the Prophet's gathering and home life, and the Prophet told him that if you were always as you are with me, the angels would shake your hand, but it is an hour and an hour. Hearts rise and fall. Keep doing the good, stay with good people, and ask Allah to keep your heart firm.",
       [HV('muslim:2750'), HV('tirmidhi:3522')], cross=[xg('huda-adhkar')],
       tags=['hypocrite', 'hypocrisy', 'nifaq', 'iman', 'fluctuate', 'heart', 'fake'],
       trig=['feel like a hypocrite', 'am i a hypocrite', 'my iman goes up and down', 'my faith goes up and down', 'iman fluctuates', 'i feel fake'])
    Hw("When you are worried or sad, say the Prophet's dua: O Allah, I seek refuge in You from worry and grief. Then do one small thing that is in your hands, speak to someone you trust, and rest. Remembering Allah brings the heart rest. If the worry is heavy or does not lift, speak to a doctor or counsellor too; that is also a means Allah gave you.",
       [HV('bukhari:6369'), Q('13:28', S)], cross=[xg('huda-adhkar')],
       tags=['worry', 'worried', 'anxious', 'anxiety', 'sad', 'grief', 'dua', 'stress', 'go-adhkar'],
       trig=['what should i say when i am worried', 'dua for worry', 'dua for anxiety', 'dua for sadness', 'i am worried all the time', 'what to say when stressed', 'dua when i am sad'],
       dns=['If the person describes panic, hopelessness or self-harm, use the support path, not this answer.'])
    Hw("A broken relationship hurts, and you are allowed to grieve it. Do not rush yourself. Make wudu and pray, ask Allah to take away the pain and replace it with what is better, limit contact and what keeps the wound open, and lean on family or friends you trust. Allah says you may dislike something that is good for you, and that with hardship there is ease.",
       [Q('2:216', S), Q('94:5-6', S), Q('13:28', S)], cross=[xg('huda-hardship')],
       tags=['breakup', 'heartbreak', 'relationship', 'ex', 'divorce', 'rejected', 'broken-heart'],
       trig=['get over a breakup', 'i got dumped', 'my heart is broken', 'heartbroken', 'how to move on from someone', 'how to get over someone', 'broke up with me', 'how to heal a broken heart'],
       dns=['Gentle. If the person is in despair or says they cannot go on, the support path comes first.'])
    Hw("To overcome fear, name it, do what you can about it, then place the rest with Allah. Say that Allah is enough for us and the best of guardians; this is what the believers said when people told them to fear, and it increased their faith. Fear shrinks when you act on it a step at a time and do not face it alone.",
       [Q('3:173', S), Q('2:286', S)],
       tags=['fear', 'afraid', 'scared', 'courage', 'tawakkul', 'worry'],
       trig=['overcome fear', 'i am scared', 'how to stop being afraid', 'dua for fear', 'how to be brave', 'i am afraid of the future'])
    Hw("Peace comes from remembering Allah, doing good, and accepting what you cannot change. Allah says hearts find rest in His remembrance, and that whoever does good as a believer, He gives a good life. Pray on time, keep a few minutes of quiet remembrance, be thankful for one thing at the end of each day, and give something to someone.",
       [Q('13:28', S), Q('16:97', S)], cross=[xg('huda-adhkar')],
       tags=['peace', 'happy', 'happiness', 'contentment', 'calm', 'joy', 'inner-peace', 'go-adhkar'],
       trig=['how to find peace', 'inner peace', 'how to be happy', 'find happiness in islam', 'i want peace in my heart', 'how to be content', 'i am not happy'],
       dns=['If low mood has lasted and affects daily life, mention that a doctor or counsellor can help; do not diagnose.'])
    Fq("Signs that Allah loves a person are not a checklist, but the Qur'an gives the path: Allah says that if you love Him, follow the Prophet and Allah will love you, and He says He loves those who do good and those who turn back to Him. Doing the obligatory well, adding voluntary prayer and remembrance, and being kind to people are the way. If you want closeness, that wish is itself a good sign.",
       [Q('3:31', S), Q('2:195', S), Q('2:222', S)], cross=[xg('huda-nawafil')],
       tags=['love', 'allah-loves', 'closeness', 'wali', 'sign', 'voluntary'],
       trig=['signs allah loves you', 'does allah love me', 'how to make allah love me', 'how do i know allah loves me', 'how to be beloved to allah'])
    Hw("Dua works best when you ask with presence and certainty. Begin by praising Allah and sending blessings on the Prophet, ask for what you need in plain words, ask with firm hope, and repeat it. Choose good times: the last third of the night, between adhan and iqamah, and while prostrating. Ask for both this life and the next, and keep asking.",
       [Q('2:186', S), Q('40:60', S), HV('bukhari:6340')],
       tags=['dua', 'supplication', 'asking', 'prayer', 'make-dua', 'etiquette'],
       trig=['make dua properly', 'how to make dua', 'how to ask allah', 'best time for dua', 'etiquette of dua', 'how to make my dua accepted'])
    Hw("The best dhikr is the one you will keep. Start with a few: say subhan Allah, alhamdulillah and Allahu akbar after each prayer, and ask forgiveness often. The Prophet said two words are light on the tongue, heavy on the scale and beloved to the Merciful: subhan Allah wa bihamdihi, subhan Allah al-Azim. Pair it with something you already do each day.",
       [HV('bukhari:6406'), Q('33:41', S)], cross=[xg('huda-adhkar')],
       tags=['dhikr', 'best', 'tasbih', 'remembrance', 'istighfar', 'go-adhkar'],
       trig=['best dhikr', 'what is the best dhikr', 'which dhikr should i do', 'dhikr for beginners', 'easy dhikr', 'what should i say daily'])
    return [p]


def worship_better():
    p, Hw, Fq = _pk('worship_better',
                    'Improving your prayer, starting the five daily prayers from nothing, praying on time, and getting out of the habit of delaying.',
                    ['worship', 'prayer'])
    Hw("To improve your salah, change one thing at a time. Pray earlier in the time, slow each position, learn the meaning of what you recite, and pray as the Prophet taught. Add the regular sunnah prayers and a short remembrance afterwards. Allah says the believers are those who are humble in their prayer.",
       [Q('23:1-2', S), HV('bukhari:631'), HV('bukhari:757')], cross=[xg('huda-prayer'), xg('huda-nawafil')],
       tags=['salah', 'prayer', 'improve', 'better', 'quality', 'slow', 'sunnah', 'go-prayer'],
       trig=['improve my salah', 'improve my prayer', 'pray better', 'make my prayer better', 'better salah', 'how to pray properly', 'my prayer is rushed', 'i rush my prayer'])
    Hw("If you are starting from nothing, start with one prayer and add the next every week or two. Pray it on time, even if short, and learn the words for it first. Build up to five without guilt about the past. Every prayer you add is a win, and Allah accepts what you do, not what you could not yet do.",
       [HV('bukhari:6464'), Q('2:286', S)], cross=[xg('huda-prayer'), xg('huda-prayer-times')],
       tags=['start', 'beginner', 'five', 'prayers', 'pray', 'regular', 'begin', 'go-prayer'],
       trig=['start praying five times a day', 'how to start praying', 'start praying again', 'i never prayed', 'how to start salah', 'i want to start praying', 'how to begin praying', 'how to pray five times a day'],
       dns=['No guilt about past prayers; no talk of sin.'])
    Hw("If you keep delaying the prayer, make it automatic. Set the prayer times in the app, put a small action right before each one (water, wudu, a quick tidy), and pray as soon as the call comes. Tell someone near you so you pray together. The Prophet said the most beloved deed to Allah is prayer at its proper time.",
       [HV('bukhari:527'), Q('4:103', S)], cross=[xg('huda-prayer-times')],
       tags=['delay', 'late', 'on-time', 'procrastinate', 'prayer', 'habit', 'go-prayer'],
       trig=['stop procrastinating on prayer', 'i delay my prayers', 'i pray late', 'pray on time', 'how to pray on time', 'i keep missing prayers', 'i always pray late'],
       dns=['No shame; one small step to start with.'])
    return [p]


def build():
    out = []
    for f in (inner_character, family_roles, work_money_study, faith_heart, worship_better):
        out.extend(f())
    return out
