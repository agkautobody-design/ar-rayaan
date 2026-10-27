from .know import kpack, K
from .sources import Q, HV, guide, lesson, qa, xg, xl, xq

S = "Qur'an text"


def build():
    p = kpack('islam_basics', 'islam_basics',
              'Beginner Islam: what Islam means, the pillars of Islam and faith, the prophets, angels, the unseen and the decree, all taken from the guides and Academy lessons in the app.',
              ['basics', 'aqidah'])
    B = lambda *a, **k: K(p, 'fact', *a, **k)

    B("Islam means submission to Allah. In one line put together from the sources, Islam is submission to Allah alone, worshipping Him and following the guidance He sent through His messengers, the last of whom is Muhammad. This is a working summary, not a scholar's definition.",
      [guide('huda-what-is-islam'), Q('3:19', S), Q('3:83', S), Q('3:84', S)], cross=[xg('huda-what-is-islam')], tags=['definition'], trig=['what is islam', 'meaning of islam', 'what does muslim mean', 'define islam'])
    B("The five pillars of Islam are the testimony that none deserves worship but Allah and that Muhammad is His Messenger, the prayer, zakat, the pilgrimage, and fasting Ramadan. Ibn Umar reported the Prophet said Islam is built on these five.",
      [guide('huda-what-is-islam'), HV('bukhari:8'), HV('muslim:16')], cross=[xg('huda-what-is-islam'), xq(12)], tags=['pillars'], trig=['five pillars', 'pillars of islam', 'what are the pillars'])
    B("Islam, iman and ihsan come from the hadith of Jibril. Islam is the pillars, iman is belief in Allah, His angels, His books, His messengers, the Last Day and the divine decree, and ihsan is worshipping Allah as though you see Him.",
      [guide('huda-what-is-islam'), HV('muslim:8')], cross=[xg('huda-what-is-islam'), xl('aqid', 'aqid.u2.l2')], tags=['iman', 'ihsan'], trig=['pillars of faith', 'six pillars of iman', 'what is iman', 'what is ihsan', 'hadith of jibril'])
    B("Islam is not a new religion started by Muhammad. The Qur'an says the religion with Allah is Islam and that Ibrahim was a Muslim, one who submits to Allah. The core message of every prophet is the same: worship Allah alone. The detailed laws can differ between communities.",
      [lesson('aqid', 'aqid.u2.l1'), Q('3:19', S), Q('3:67', S), Q('5:48', S)], cross=[xl('aqid', 'aqid.u2.l1')], tags=['prophets', 'continuity'], trig=['is islam a new religion', 'islam before muhammad', 'same message of prophets'])
    B("The main line of messengers named in the Qur'an runs through Adam, Nuh, Ibrahim, Musa and Isa, and ends with Muhammad, the last of the prophets. Muslims believe in all of them and make no difference between them.",
      [lesson('aqid', 'aqid.u2.l1'), Q('3:33', S), Q('33:40', S), Q('2:136', S)], cross=[xl('aqid', 'aqid.u2.l1')], tags=['prophets'], trig=['who are the prophets', 'last prophet', 'prophets in islam'])
    B("Belief in the unseen is the first quality the Qur'an gives to the mindful. The unseen is whatever our senses cannot reach: Allah, the angels, the Last Day. The keys of the unseen are with Allah alone.",
      [lesson('aqid', 'aqid.u2.l2'), Q('2:3', S), Q('6:59', S)], cross=[xl('aqid', 'aqid.u2.l2')], tags=['unseen', 'iman'], trig=['belief in the unseen', 'what is ghayb', 'unseen'])
    B("The angels are creatures of Allah. The Qur'an says they do what they are commanded, and that two angels record what a person does. Believing in them is part of faith.",
      [lesson('aqid', 'aqid.u2.l2'), Q('66:6', S), Q('82:10-12', S)], cross=[xl('aqid', 'aqid.u2.l2')], tags=['angels'], trig=['what are angels', 'angels in islam', 'recording angels'])
    B("Qadar is the divine decree. The Qur'an says Allah created everything with a measure, and also that people choose: whoever wills may take a way to his Lord. Muslims hold both together, that Allah knows and decreed all things and that people are responsible for their choices.",
      [lesson('aqid', 'aqid.u2.l2'), Q('54:49', S), Q('57:22', S), Q('76:29', S), Q('76:30', S)], cross=[xl('aqid', 'aqid.u2.l2')], tags=['qadar'], trig=['what is qadar', 'predestination', 'free will', 'fate in islam'])
    B("Tawhid is the oneness of Allah. Surah Al-Ikhlas states it in four verses: He is Allah, One; Allah, the Eternal; He neither begets nor is begotten; and nothing is comparable to Him.",
      [lesson('aqid', 'aqid.u3.l3'), Q('112:1-4', S)], cross=[xl('aqid', 'aqid.u3.l3')], tags=['tawhid'], trig=['what is tawhid', 'oneness of god', 'who is allah', 'surah ikhlas'])
    B("Allah's mercy overcomes His anger, and He has the most beautiful names, by which He is known. Knowing that He is merciful gives hope, knowing He is just makes us give people their rights, and knowing He sees us makes us act the same in private and in public.",
      [lesson('aqid', 'aqid.u3.l3'), Q('7:180', S), Q('21:47', S)], cross=[xl('aqid', 'aqid.u3.l3')], tags=['names', 'creed'], trig=['names of allah', 'is allah merciful', 'creed in short'])
    B("Muslims pray five times a day: Fajr, Dhuhr, Asr, Maghrib and Isha. Fajr is two units, Dhuhr and Asr and Isha are four each, and Maghrib is three. The Prophet set out when each begins and ends.",
      [lesson('the-path', 'path.u2.l1'), Q('4:103', S), HV('muslim:612')], cross=[xl('the-path', 'path.u2.l1'), xg('huda-prayer')], tags=['prayer'], trig=['how many prayers', 'five daily prayers', 'prayer times names', 'how many rakahs'])
    B("The first prayer of the day, Fajr, and the others are fixed by time, so a prayer can be prayed wherever the time is due. The Prophet said the earth has been made a place of prayer, so a Muslim may pray at work, at school or while travelling.",
      [qa(9), HV('bukhari:335'), HV('muslim:521')], cross=[xq(9)], tags=['prayer', 'work'], trig=['pray at work', 'pray at school', 'where can i pray'])
    B("Al-Fatihah has seven verses and is said in every unit of every prayer. The Prophet said there is no prayer for one who does not recite it, and that Allah answers each part of it when the servant says it.",
      [lesson('the-path', 'path.u3.l1'), HV('bukhari:756'), HV('muslim:395')], cross=[xl('the-path', 'path.u3.l1')], tags=['fatihah'], trig=['what is fatihah', 'surah fatiha', 'opening of quran'])
    B("A revelation, not a book first. The Qur'an was revealed to the Prophet and then preserved. Muslims believe it is guarded word by word, and the Q&A bank notes that listening with attention is part of how it is honoured.",
      [lesson('und', 'und.u1.l1'), qa(7), Q('7:204', S)], cross=[xl('und', 'und.u1.l1'), xq(7)], tags=['quran'], trig=['what is the quran', 'how was quran revealed', 'listen to quran'])
    return [p]
