from .know import kpack, K
from .sources import Q, HV, guide, lesson, qa, xg, xl, xq

S = "Qur'an text"
D = 'daw'


def build():
    p = kpack('misconceptions', 'misconceptions',
              'Common doubts and misunderstandings about Islam, answered gently from the Qur\'an and authentic hadith, using the Dawah school and the Q&A bank in the app. Answers start with listening, not debate.',
              ['misconception', 'doubt'])
    M = lambda *a, **k: K(p, 'misconception', *a, age=('adult',), **k)

    M("Why do bad things happen? Start with care, not a lecture. The Qur'an says Allah tests people with fear, loss and hardship, gives good news to the patient, never burdens a soul beyond its capacity, and that with hardship comes ease. We cannot always say why a particular thing happened to a particular person, and it is wrong to tell someone their suffering was a punishment.",
      [lesson(D, 'daw.u2.l1'), Q('2:155-156', S), Q('2:286', S), Q('94:5-6', S)], cross=[xl(D, 'daw.u2.l1')], tags=['suffering', 'qadar'], trig=['why do bad things happen', 'why does god allow suffering', 'why is there evil'],
      dns=['If the person is grieving, offer presence first; never say a loss was a punishment.'])
    M("The Prophet said that no fatigue, illness, sorrow or harm reaches a Muslim, even a thorn's prick, but Allah expiates some of their wrongs for it. Hardship is not proof that Allah has left someone.",
      [lesson(D, 'daw.u2.l1'), HV('bukhari:5641')], cross=[xl(D, 'daw.u2.l1')], tags=['suffering', 'sabr'], trig=['is my illness a punishment', 'is god angry with me', 'why am i suffering'])
    M("The believer's affair is all good. The Prophet said that if good reaches them they are thankful, and if hardship reaches them they are patient, and both are good for them.",
      [lesson(D, 'daw.u2.l1'), HV('muslim:2999')], cross=[xl(D, 'daw.u2.l1')], tags=['sabr', 'shukr'], trig=['patience and gratitude', 'affair of the believer'])
    M("Islam is too strict. The Qur'an says Allah intends ease for you and not hardship, and has placed no difficulty on you in the religion. Aisha said that when the Prophet was given a choice between two matters he chose the easier, as long as it was not wrong.",
      [lesson(D, 'daw.u2.l2'), Q('2:185', S), Q('22:78', S), HV('bukhari:6126')], cross=[xl(D, 'daw.u2.l2')], tags=['ease', 'strict'], trig=['islam is too strict', 'too many rules', 'islam is hard', 'islam is difficult'])
    M("Ease does not mean dropping what is required. Prayer and fasting remain, and Allah gave concessions in hardship: the sick and the traveller may delay or shorten some acts. When describing Islam, say that the rules exist, and put mercy and ease first.",
      [lesson(D, 'daw.u2.l2'), Q('2:185', S)], cross=[xl(D, 'daw.u2.l2')], tags=['ease', 'concessions'], trig=['can i skip prayer if hard', 'is islam flexible', 'rules and ease'])
    M("The Prophet said the religion is easy, and whoever overburdens himself in it will not be able to continue, so aim for the mark, stay near it and take heart. A new Muslim can begin with what is required and build slowly.",
      [lesson(D, 'daw.u2.l2'), HV('bukhari:39')], cross=[xl(D, 'daw.u2.l2')], tags=['ease', 'new-muslim'], trig=['too much at once', 'overwhelmed new muslim', 'where to start'])
    M("The Qur'an was written by Muhammad. The Qur'an mentions this claim and answers it with a challenge: bring a surah like it. It also says he did not recite or write scripture before it. Muslims believe it is the word of Allah. You are not expected to prove it to anyone, only to understand the answer.",
      [lesson(D, 'daw.u2.l3'), Q('10:38', S), Q('17:88', S), Q('29:48', S)], cross=[xl(D, 'daw.u2.l3')], tags=['quran', 'authorship'], trig=['quran written by muhammad', 'who wrote the quran', 'did muhammad make up the quran'])
    M("Surah Abasa begins by correcting the Prophet for frowning at a blind man who came to him. People who give this argument say a person who made up a book might not include a passage that corrects himself. It is offered for reflection, not as a proof.",
      [lesson(D, 'daw.u2.l3'), Q('80:1-10', S)], cross=[xl(D, 'daw.u2.l3')], tags=['quran', 'authorship'], trig=['abasa', 'prophet frowned', 'quran corrects prophet'])
    M("Jubayr ibn Mut'im, not yet a Muslim, heard the Prophet recite Surah At-Tur in the Maghrib prayer. At the verses asking whether they were created from nothing or are the creators, he said his heart was about to fly. He later became Muslim.",
      [lesson(D, 'daw.u2.l3'), HV('bukhari:4854'), Q('52:35-37', S)], cross=[xl(D, 'daw.u2.l3')], tags=['quran', 'effect'], trig=['jubayr', 'effect of quran', 'surah at tur'])
    M("I have done too much wrong for Allah to forgive me. The Qur'an speaks to exactly this person and tells them not to despair of Allah's mercy. It says Allah forgives all sins, for He is the Forgiving, the Merciful.",
      [lesson(D, 'daw.u2.l4'), Q('39:53', S)], cross=[xl(D, 'daw.u2.l4'), xq(8)], tags=['mercy', 'despair'], trig=['allah will not forgive me', 'i have done too much', 'too late to repent', 'beyond forgiveness'],
      dns=['If despair is mixed with thoughts of self-harm, move to the shame and despair support pack.'], clinician=True, risk='medium')
    M("The Prophet told of a man who killed ninety-nine people and asked a monk if he could be forgiven. He kept seeking, set out for a village of good people, and died on the way. The angels of mercy took him because he was nearer to that village. The door of return stays open.",
      [lesson(D, 'daw.u2.l4'), HV('bukhari:3470')], cross=[xl(D, 'daw.u2.l4')], tags=['mercy', 'tawba'], trig=['man who killed ninety nine', 'can murderer be forgiven', 'story of repentance'])
    M("Allah is more pleased with a servant's repentance than a man who lost his animal with his food and drink in the desert and then finds it. A believer's fear of past mistakes is a sign of life in the heart, not a sign of rejection.",
      [lesson(D, 'daw.u2.l4'), HV('bukhari:6308'), HV('muslim:2744')], cross=[xl(D, 'daw.u2.l4')], tags=['mercy', 'tawba'], trig=['allah happy with repentance', 'does allah accept tawba', 'guilt after sin'])
    M("Allah says that if a person comes with wrongs nearly as great as the earth and meets Him without associating anything with Him, He will come with forgiveness nearly as great. The hadith is graded acceptable by several scholars who differ on the level.",
      [lesson(D, 'daw.u2.l4'), HV('tirmidhi:3540')], cross=[xl(D, 'daw.u2.l4')], tags=['mercy', 'hope'], trig=['sins like the earth', 'forgiveness as great as the earth'])
    M("For someone coming to Islam, the Prophet said that Islam wipes out what came before it. For a Muslim who slips, the way back is sincere repentance, and the door stays open.",
      [lesson(D, 'daw.u2.l4'), HV('muslim:121')], cross=[xl(D, 'daw.u2.l4')], tags=['new-muslim', 'tawba'], trig=['past before islam forgiven', 'does islam erase my past', 'my past life'])
    M("Waswas, or whispers and doubts, are a trial and not a sign that faith is gone. The Prophet said Allah has forgiven his followers the evil thoughts that cross their minds as long as they are not acted on or spoken.",
      [qa(6), HV('bukhari:5269'), HV('muslim:127')], cross=[xq(6)], tags=['waswas', 'doubt'], trig=['waswas', 'whispers', 'blasphemous thoughts', 'doubts about faith'],
      dns=['Do not argue with intrusive thoughts; if distress is high, suggest the support pack and a clinician.'], clinician=True, risk='medium')
    M("Anger. When a man asked for advice, the Prophet said only: do not become angry, and repeated it. He said the strong one is who controls himself in anger. Practical steps are in the Q&A answer.",
      [qa(13), HV('bukhari:6116'), HV('bukhari:6114'), HV('muslim:2609')], cross=[xq(13)], tags=['anger'], trig=['i get angry', 'anger in islam', 'control my anger'])
    M("Is it wrong to cry when someone dies? No. The Prophet's eyes shed tears when his son Ibrahim was dying, and he called it mercy. Grief is not a lack of faith.",
      [qa(15)], cross=[xq(15)], tags=['grief'], trig=['is crying haram', 'crying for the dead', 'cry at funeral'])
    M("What is the ruling on music? Scholars differ, and this answer does not settle it. The majority of classical scholars across the four schools held that instruments are not permitted, while allowing the hand-drum on occasions such as weddings and Eid. Some scholars permit it under conditions. Ask a trusted scholar.",
      [qa(1)], cross=[xq(1)], tags=['music', 'ikhtilaf'], schools=['hanafi', 'maliki', 'shafii', 'hanbali'], trig=['is music haram', 'listening to music', 'singing in islam'])
    return [p]
