from .know import kpack, K
from .sources import Q, HV, lesson, xl

S = "Qur'an text"


def build():
    p = kpack('academy_lessons', 'academy',
              'Key points from Academy lessons (Understanding the Qur\'an, Creed, Dawah) as short retrievable facts, each pointing back to its lesson. The lesson stays the source of record.',
              ['academy', 'lesson'])

    def A(text, src, course, lid, trig, tags=(), **k):
        return K(p, 'lesson-fact', text, [lesson(course, lid)] + src, cross=[xl(course, lid)], tags=list(tags), trig=trig, **k)

    # Understanding the Qur'an
    A("The Qur'an began as speech, not paper. The first word revealed was iqra, read or recite. It came in pieces over twenty-three years, and every Ramadan Jibril reviewed the whole Qur'an with the Prophet.",
      [Q('96:1', S), Q('25:32', S), HV('bukhari:3851'), HV('bukhari:4998')], 'und', 'und.u1.l1', ['how was the quran revealed', 'twenty three years', 'first revelation', 'iqra'], ['quran', 'revelation'])
    A("Allah promised to guard the Qur'an: it is He who sent down the reminder and He who will guard it. Muslims believe the promise was carried out through people, who memorised it and wrote it down.",
      [Q('15:9', S), Q('75:17-19', S)], 'und', 'und.u1.l2', ['is the quran preserved', 'quran changed', 'who collected the quran'], ['quran', 'preservation'])
    A("The Qur'an says it was sent down as an Arabic Qur'an so that people might understand, and that Allah made it easy for remembrance. Many who do not speak Arabic have memorised it.",
      [Q('12:2', S), Q('54:17', S)], 'und', 'und.u1.l3', ['why is quran in arabic', 'arabic quran', 'memorise without arabic'], ['quran', 'arabic'])
    A("A translation is a bridge, not the Qur'an itself. A word like muttaqeen has been rendered in several ways and each catches only part of it. The Qur'an asks people to reflect on its verses.",
      [Q('38:29', S), Q('47:24', S)], 'und', 'und.u2.l1', ['is translation the quran', 'reading quran in english', 'translation of quran'], ['quran', 'translation'])
    A("Tartil is reciting slowly and clearly, giving each letter its due. Anas said the Prophet used to prolong the sounds. The one who struggles to recite and finds it hard has two rewards, so keep going slowly.",
      [Q('73:4', S), HV('bukhari:5045'), HV('muslim:798')], 'und', 'und.u2.l2', ['tartil', 'how to recite quran', 'struggling to recite', 'quran recitation hard'], ['quran', 'tajweed'])
    A("Small and steady beats large and rare. The Prophet said the most beloved deed to Allah is the most regular and constant, even if it is little. Set a daily portion of the Qur'an you can keep.",
      [HV('bukhari:6464'), Q('17:106', S)], 'und', 'und.u3.l1', ['daily quran portion', 'how much quran per day', 'finish quran quickly', 'consistency'], ['quran', 'routine'])
    A("The Qur'an calls itself a healing and a mercy for the believers, and the Prophet said Allah created no disease without creating its treatment. Use both: recite, and see a doctor.",
      [Q('17:82', S), Q('10:57', S), HV('bukhari:5678')], 'und', 'und.u3.l2', ['quran healing', 'ruqyah and doctor', 'is quran a cure'], ['quran', 'healing'], clinician=True, risk='medium',
      dns=['Never imply recitation replaces medical care.'])
    A("The Prophet said to recite the Qur'an, for it will come as an intercessor on the Day of Resurrection for those who recite it. Abandoning it includes not listening, not pondering and not acting on it, as Ibn Kathir lists.",
      [HV('muslim:804')], 'und', 'und.u3.l3', ['abandoned quran', 'quran intercede', 'neglect of quran'], ['quran'])

    # Creed (aqid)
    A("Surah Ar-Rahman opens by naming Allah the Most Merciful, then lists what His mercy did: He taught the Qur'an, created man and taught him clear speech. Surah Al-Ikhlas describes Him in four short verses.",
      [Q('55:1-4', S), Q('112:1-4', S)], 'aqid', 'aqid.u1.l1', ['how does quran introduce allah', 'mercy first', 'surah rahman'], ['allah', 'mercy'])
    A("Ayat al-Kursi is the greatest verse in the Qur'an, as the Prophet told Ubayy ibn Ka'b. It says Allah is Ever-Living and Sustaining, that neither drowsiness nor sleep overtakes Him, and that nobody can intercede except by His leave.",
      [Q('2:255', S), HV('muslim:810')], 'aqid', 'aqid.u1.l2', ['ayat al kursi', 'greatest verse', 'ayatul kursi meaning'], ['allah', 'dhikr'])
    A("The basmala names mercy twice, Ar-Rahman and Ar-Raheem. Ibn Kathir says Ar-Rahman covers every kind of mercy Allah has, while Ar-Raheem is the mercy that reaches the believers. The Prophet said Allah made mercy in one hundred parts and sent one part down to earth.",
      [Q('1:1', S), Q('33:43', S), HV('bukhari:6000'), HV('muslim:2752')], 'aqid', 'aqid.u1.l3', ['rahman and raheem difference', 'meaning of bismillah', 'mercy of allah'], ['allah', 'mercy'])
    A("The names of Allah are not different gods. The Qur'an says to call on Allah or call on Ar-Rahman, for the best names belong to Him. Scholars explain counting the names as counting, memorising, understanding and acting on them.",
      [Q('17:110', S), Q('20:8', S)], 'aqid', 'aqid.u1.l4', ['99 names', 'names of allah meaning', 'learn the names'], ['allah', 'names'],
      dns=['Do not quote the ninety-nine-names hadith as authentic; its graders call the Tirmidhi version weak.'])
    A("The Qur'an names some prophets and says there are others it has not told us about. A Muslim believes in all of them without difference, and believes Muhammad is the seal of the prophets.",
      [Q('2:285', S), Q('4:164', S), Q('33:40', S)], 'aqid', 'aqid.u2.l3', ['do muslims believe in jesus', 'prophets by name', 'seal of the prophets'], ['prophets'])
    A("Allah is with us in three ways, say scholars: by knowledge and sight with everyone, by help and support with the believers, and by answering those who call. The Qur'an says He is closer than the jugular vein.",
      [Q('57:4', S), Q('20:46', S), Q('2:153', S), Q('50:16', S)], 'aqid', 'aqid.u3.l1', ['is allah near', 'allah is with you', 'closer than jugular vein'], ['allah', 'nearness'])
    A("On the Day of Judgment the scales are just and no soul is wronged, even by an atom's weight. The Prophet said rights will be returned to their owners. This is good news for the person who was treated unjustly.",
      [Q('21:47', S), Q('99:7-8', S), HV('muslim:2582'), HV('bukhari:2449')], 'aqid', 'aqid.u3.l2', ['day of judgment fair', 'justice on the last day', 'scales'], ['akhira', 'justice'])

    # Dawah
    A("Dawah means invitation, not forcing and not winning an argument. The Qur'an tells the Prophet to invite to the way of his Lord with wisdom and good instruction. Anyone can invite: a parent, a classmate or a neighbour.",
      [Q('16:125', S), HV('bukhari:3925')], 'daw', 'daw.u1.l1', ['what is dawah', 'how to invite to islam', 'sharing islam'], ['dawah'])
    A("The Qur'an names three doors: wisdom, which is knowing what to say, how and when, good instruction given with care, and argument only in the best manner. The Prophet gave different answers to different people.",
      [Q('16:125', S), HV('bukhari:26')], 'daw', 'daw.u1.l2', ['how to talk about islam', 'wisdom in dawah', 'debate islam'], ['dawah'])
    A("Repel evil with what is better, and the one who was an enemy may become a close friend. The Prophet had the chance to ask for harm to those who rejected him and chose hope for them instead.",
      [Q('41:34', S), HV('bukhari:3231')], 'daw', 'daw.u1.l3', ['when someone mocks my faith', 'respond to insults', 'taif'], ['dawah', 'patience'])
    A("Character is the loudest sermon. Even an opponent, Abu Sufyan, said the Prophet had never been accused of lying before his message. The Qur'an warns against saying what you do not do, which means words and deeds should match.",
      [HV('bukhari:7'), Q('61:2-3', S), HV('muslim:2674')], 'daw', 'daw.u1.l4', ['live your islam', 'character dawah', 'be a good example'], ['dawah', 'character'])
    A("Gentleness does not water down the truth. The Prophet said kindness adds beauty to anything it is in. Gentleness changes how you say the message, not what the message is.",
      [HV('muslim:2594')], 'daw', 'daw.u3.l1', ['how to be gentle dawah', 'kind but firm', 'gentleness'], ['dawah', 'gentleness'])
    A("Speak from knowledge. The Qur'an forbids saying about Allah what you do not know. When you do not know, say so. The Prophet said knowledge leaves when the scholars go and people take ignorant leaders who give rulings without knowledge.",
      [Q('7:33', S), Q('17:36', S), HV('bukhari:100')], 'daw', 'daw.u3.l2', ['i dont know the answer', 'speak without knowledge', 'fatwa without knowledge'], ['dawah', 'knowledge'])
    A("Deliver the message and leave the result with Allah. The Qur'an tells the Prophet he is only a reminder and not a controller over them, and that he does not guide whom he likes, but Allah guides whom He wills.",
      [Q('88:21-22', S), Q('16:82', S), Q('28:56', S)], 'daw', 'daw.u3.l3', ['they wont accept islam', 'guidance is from allah', 'my family refuses islam'], ['dawah', 'tawakkul'])
    return [p]
