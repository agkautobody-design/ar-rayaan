from .know import kpack, K
from .sources import Q, HV, guide, lesson, qa, xg, xl, xq

S = "Qur'an text"
P = 'the-path'


def build():
    p = kpack('new_muslim_faq', 'new_muslim',
              'First questions from someone new to Islam: the shahada, first steps, wudu, first prayer, the past, and not being overwhelmed. From the Path course and guides in the app.',
              ['new-muslim', 'faq'])
    N = lambda *a, **k: K(p, 'faq', *a, age=('adult', '13-17'), **k)

    N("How do I become a Muslim? By saying the shahada with understanding and sincerity: there is no god but Allah, and Muhammad is the Messenger of Allah. You do not need a special place or a witness to mean it, though many people say it with others around them.",
      [lesson(P, 'path.u0.l1'), HV('bukhari:8'), Q('34:28', S)], cross=[xl(P, 'path.u0.l1')], tags=['shahada'], trig=['how to become muslim', 'how to convert', 'say shahada', 'accept islam'],
      dns=['No pressure; do not rush a person; scholar to confirm the line about witnesses.'])
    N("What does the shahada mean? The first half takes away every false object of worship and affirms Allah alone. The second half says Allah sent Muhammad to all people with the Qur'an, so you trust what he told and follow his way of worship.",
      [lesson(P, 'path.u0.l1'), Q('34:28', S)], cross=[xl(P, 'path.u0.l1')], tags=['shahada'], trig=['meaning of shahada', 'la ilaha illallah', 'what does la ilaha illa allah mean'])
    N("What do I do first after saying the shahada? The Prophet taught that the next duty is the five daily prayers. You do not need to do everything at once. Begin with wudu, then your first prayer, then Al-Fatihah, one lesson at a time.",
      [lesson(P, 'path.u0.l1'), HV('bukhari:39')], cross=[xl(P, 'path.u0.l1'), xl(P, 'path.u1.l1')], tags=['first-steps'], trig=['what next after shahada', 'first steps new muslim', 'new muslim guide'])
    N("Is my past forgiven when I become Muslim? The Prophet said that Islam wipes out what came before it. A new Muslim begins with a clean page, and the Qur'an tells those who feel they have gone too far not to despair of Allah's mercy.",
      [lesson(P, 'path.u0.l1'), HV('muslim:121'), Q('39:53', S)], cross=[xl(P, 'path.u0.l1'), xl('daw', 'daw.u2.l4')], tags=['past', 'mercy'], trig=['is my past forgiven', 'what about my past', 'sins before islam'])
    N("Why do we wash before prayer? The Qur'an commands wudu, and the Prophet said the prayer of one who has broken their wudu is not accepted until they make it again. The Qur'an names four parts: the face, the arms to the elbows, wiping the head, and the feet to the ankles.",
      [lesson(P, 'path.u1.l1'), Q('5:6', S), HV('bukhari:135')], cross=[xl(P, 'path.u1.l1'), xg('huda-wudu')], tags=['wudu'], trig=['why wudu', 'wudu steps', 'how to make wudu', 'parts of wudu'])
    N("I missed a spot in wudu, what now? A man left a fingernail-sized spot dry and the Prophet told him to go back and make his wudu well. A missed part is easy to fix: wash it and carry on. No one is shamed for it.",
      [lesson(P, 'path.u1.l1'), HV('muslim:243')], cross=[xl(P, 'path.u1.l1')], tags=['wudu'], trig=['missed a spot wudu', 'dry spot wudu', 'is my wudu valid'])
    N("What breaks wudu? Scholars agree on what comes out of the front or back passage, such as urine, stool and wind, and on deep sleep or fainting. Scholars differ on light sleep while sitting, bleeding, vomiting and touching: the Hanafi, Maliki, Shafi'i and Hanbali schools each hold their own view. Doubt alone does not break wudu.",
      [lesson(P, 'path.u1.l1'), HV('bukhari:135')], cross=[xl(P, 'path.u1.l1'), xg('huda-wudu')], tags=['wudu', 'ikhtilaf'], schools=['hanafi', 'maliki', 'shafii', 'hanbali'], trig=['what breaks wudu', 'does touching break wudu', 'does bleeding break wudu'])
    N("What if I do not know the prayer yet? The Prophet once told a man to go back and pray again until he prayed well, then taught him: say the takbir, recite, bow until at ease, stand, prostrate until at ease, sit until at ease, and do the same through the prayer. Learn it a step at a time.",
      [lesson(P, 'path.u2.l1'), HV('bukhari:757')], cross=[xl(P, 'path.u2.l1'), xg('huda-prayer')], tags=['prayer', 'learning'], trig=['i dont know how to pray', 'how to pray', 'first prayer', 'cant memorise prayer'])
    N("What if I miss a prayer? The Prophet said whoever forgets a prayer or sleeps through it should pray it when they remember it. With several missed prayers, scholars differ on order and method, and the Hanafi, Maliki, Shafi'i and Hanbali schools each give their own detail, so ask a trusted teacher.",
      [qa(2), HV('bukhari:597'), HV('muslim:684')], cross=[xq(2), xg('huda-qada')], tags=['qada'], schools=['hanafi', 'shafii', 'maliki', 'hanbali'], trig=['missed prayer', 'make up prayers', 'qada prayer', 'overslept fajr'])
    N("Do I have to do everything perfectly? No. The Prophet said the religion is easy and that whoever makes it too hard for himself will not be able to keep it up. Do what you can, keep it steady, and build slowly.",
      [lesson(P, 'path.u0.l1'), HV('bukhari:39')], cross=[xl(P, 'path.u0.l1'), xl('daw', 'daw.u2.l2')], tags=['ease', 'new-muslim'], trig=['overwhelmed', 'too much to learn', 'i keep failing', 'not perfect muslim'])
    N("Do I have to learn Arabic right away? You will need a few short Arabic phrases for prayer, which the Path teaches word by word. Understanding the meaning matters, and a translation is a bridge to it.",
      [lesson(P, 'path.u3.l1'), lesson('und', 'und.u2.l1')], cross=[xl(P, 'path.u3.l1'), xl('und', 'und.u2.l1')], tags=['arabic', 'quran'], trig=['do i need arabic', 'learn arabic quickly', 'quran in english'])
    N("How should one treat relatives who are not Muslim? Kindness stays. The Qur'an says that if they push you to join others with Allah, do not follow them in that, but keep good company with them in this world.",
      [qa(14), Q('31:15', S)], cross=[xq(14), xg('huda-parents')], tags=['family', 'parents'], trig=['family not muslim', 'parents against my conversion', 'telling my family'],
      dns=['No instruction to hide or to disclose; if there is a threat of harm, move to the support pack.'], risk='medium')
    N("Do I have to tell people I became Muslim? There is no rule to announce it. You decide when and how, based on your safety and wellbeing. If you fear for your safety, speak to a trusted person in your local mosque or a convert support group.",
      [guide('huda-parents')], cross=[xg('huda-parents')], tags=['privacy', 'new-muslim'], trig=['hide that im muslim', 'announce conversion', 'should i tell my family'],
      dns=['Do not tell someone to hide or to announce; scholar and safeguarding review.'], risk='medium', clinician=True)
    N("I feel lonely as a new Muslim. Many new Muslims do. Start small: say salam, visit a mosque at a quiet time, ask for a new-Muslim class or a buddy, and keep learning one lesson a day.",
      [guide('huda-greeting')], cross=[xg('huda-greeting'), xg('huda-mosque')], tags=['loneliness', 'community'], trig=['lonely new muslim', 'no muslim friends', 'where to find community'])
    return [p]
