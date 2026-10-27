from .know import kpack, K
from .sources import Q, HV, guide, xg, fq

S = "Qur'an text"


def build():
    p = kpack('prayer_howto', 'prayer_howto',
              'How to pray, purify and keep the prayer: wudu, ghusl, tayammum, wiping over socks, the prayer step by step, times, congregation, Friday, travel, missed prayers, with where the four schools differ. Drawn from the Huda guides in the app.',
              ['prayer', 'howto'])
    F = lambda *a, **k: K(p, 'fact', *a, **k)
    Hw = lambda *a, **k: K(p, 'howto', *a, **k)
    Fq = lambda *a, **k: K(p, 'faq', *a, **k)
    Dh = ['hanafi', 'maliki', 'shafii', 'hanbali']

    # ---- before prayer / wudu
    Hw("To pray you need to be in wudu, with a clean body, clothes and place, the awrah covered, and the time of that prayer entered. Then you face the qiblah.",
       [guide('huda-prayer'), Q('2:144', S), HV('bukhari:135')], cross=[xg('huda-prayer')], tags=['prayer-conditions'],
       trig=['conditions of prayer', 'before i pray', 'what do i need to pray', 'how to prepare for prayer'])
    Hw("The intention for prayer is in the heart. You settle on which prayer you are praying. It is not reported that the Prophet spoke the intention aloud.",
       [guide('huda-prayer'), HV('bukhari:1')], cross=[xg('huda-prayer')], tags=['niyyah', 'intention'], trig=['intention for prayer', 'niyyah', 'say the intention'])
    Hw("Wudu in order: say Bismillah, wash both hands, rinse the mouth and nose, wash the face, wash the arms up to the elbows, wipe the head and ears, then wash the feet up to the ankles. The washing is done three times.",
       [guide('huda-wudu'), Q('5:6', S), HV('bukhari:159')], cross=[xg('huda-wudu')], tags=['wudu', 'steps'],
       trig=['how to make wudu', 'wudu steps', 'how to do ablution', 'how to wash for prayer'])
    F("The Qur'an itself names four parts of wudu: the face, the arms to the elbows, the head wipe, and the feet to the ankles.",
      [guide('huda-wudu'), Q('5:6', S)], cross=[xg('huda-wudu')], tags=['wudu'],
      trig=['what does the quran say about wudu', 'parts of wudu', 'fard of wudu'])
    F("Wudu is broken by anything that leaves the front or back passage, such as urine, stool or wind. All four schools agree on this.",
      [guide('huda-wudu'), HV('bukhari:135')], cross=[xg('huda-wudu')], tags=['wudu', 'breaks-wudu'],
      trig=['what breaks wudu', 'does wind break wudu', 'nullifiers of wudu'])
    F("Some things that break wudu are disputed. Touching the private part breaks it in the Shafi'i and Hanbali schools and not in the Hanafi school, and the Maliki view depends on how and why. Scholars differ, so follow one school or ask a teacher.",
      [guide('huda-wudu')], cross=[xg('huda-wudu')], tags=['wudu', 'madhhab'], schools=['shafii', 'hanbali', 'hanafi', 'maliki'],
      trig=['does touching break wudu', 'madhhab wudu difference', 'camel meat wudu', 'vomit wudu'])
    F("Wiping the head in wudu is done differently by the schools. Scholars differ: the Maliki and Hanbali schools say the whole head, the Hanafi school at least a quarter, and the Shafi'i school some part of it.",
      [guide('huda-wudu')], cross=[xg('huda-wudu')], tags=['wudu', 'madhhab'], schools=Dh, trig=['how much of the head to wipe', 'masah of head'])
    Fq("If you are not sure whether your wudu broke, do not leave the prayer on a doubt. The Prophet said to leave only if you hear a sound or smell something.",
       [guide('huda-wudu'), HV('bukhari:137')], cross=[xg('huda-wudu')], tags=['wudu', 'doubt', 'waswas'],
       trig=['not sure if wudu broke', 'doubt in wudu', 'waswas wudu'], dns=['Kind tone; for persistent doubt that distresses, also point to the Sakina area and a qualified person.'])
    Hw("Ghusl is the full wash. Make the intention, wash the hands and private parts, make a full wudu, pour water over the head three times with the fingers reaching the roots, then wash the rest of the body, starting with the right side.",
       [guide('huda-ghusl'), HV('bukhari:248')], cross=[xg('huda-ghusl')], tags=['ghusl', 'steps'],
       trig=['how to do ghusl', 'ghusl steps', 'full bath for prayer'])
    F("Ghusl is required after intercourse, after emission of semen, and after menstruation or post-natal bleeding ends.",
      [guide('huda-ghusl')], cross=[xg('huda-ghusl')], tags=['ghusl'], trig=['when is ghusl required', 'when do i need ghusl', 'janabah'])
    F("Rinsing the mouth and nose in ghusl is required in the Hanafi and Hanbali schools and a sunnah in the Maliki and Shafi'i schools. Scholars differ on this, so follow your school or ask a teacher.",
      [guide('huda-ghusl')], cross=[xg('huda-ghusl')], tags=['ghusl', 'madhhab'], schools=Dh, trig=['rinse mouth ghusl', 'ghusl madhhab'])
    Hw("Tayammum is the dry purification for when there is no water, when water would harm you, or in danger from extreme cold. Make the intention, strike the palms on clean earth, then wipe the face and the hands.",
       [guide('huda-tayammum'), Q('5:6', S), HV('bukhari:341')], cross=[xg('huda-tayammum')], tags=['tayammum'],
       trig=['tayammum', 'dry ablution', 'no water for wudu', 'sick cant use water'])
    F("The number of strikes in tayammum differs. Scholars differ: the Hanafi and Shafi'i schools say two strikes with the hands wiped to the elbows, the Hanbali school one strike to the wrists, and the Maliki school one strike to the wrists with a second to the elbows recommended.",
      [guide('huda-tayammum')], cross=[xg('huda-tayammum')], tags=['tayammum', 'madhhab'], schools=Dh, trig=['how many strikes tayammum'])
    Hw("Wiping over socks replaces washing the feet if you put the socks on while in wudu. For a resident the time is one day and night, and for a traveller three days and nights. Wipe the top of the socks once.",
       [guide('huda-masah'), HV('muslim:276')], cross=[xg('huda-masah')], tags=['masah', 'socks'],
       trig=['wipe over socks', 'masah on khuff', 'can i wipe over socks'])
    F("The time limit for wiping over socks is not the same in every school. Scholars differ: the Hanafi, Shafi'i and Hanbali schools give one day and night for a resident and three for a traveller, while the relied-upon Maliki view sets no time limit.",
      [guide('huda-masah')], cross=[xg('huda-masah')], tags=['masah', 'madhhab'], schools=Dh, trig=['masah duration', 'how long can i wipe over socks'])

    # ---- the prayer
    Hw("Begin by saying Allahu Akbar and raising the hands, then place the right hand over the left. Recite al-Fatihah, then another surah or some verses in the first two rak'ahs.",
       [guide('huda-prayer'), HV('bukhari:735'), HV('bukhari:756')], cross=[xg('huda-prayer')], tags=['salah', 'steps', 'standing'],
       trig=['how to pray', 'how do i start prayer', 'takbir', 'steps of salah'])
    F("Where the hands are placed in standing prayer is disputed. Scholars differ: the Hanafi school says below the navel and the Shafi'i school says above it, and the guide notes the prayer is valid in each case.",
      [guide('huda-madhhab-overview'), fq('Dorar al-Saniyya Fiqh Encyclopedia and Islamic Institute of Toronto fatwa, via huda-madhhab-overview', 'RES_H2 knowledge', 'institution', ['hanafi', 'shafii'])],
      cross=[xg('huda-madhhab-overview')], tags=['salah', 'madhhab', 'hands'], schools=['hanafi', 'shafii'],
      trig=['where to put hands in prayer', 'hands on chest or navel'])
    Hw("In the bowing, say Allahu Akbar, bend with the hands on the knees and the back level, and say the glorification of the Lord in bowing. Rise saying that Allah hears those who praise Him, and stand fully upright.",
       [guide('huda-prayer'), HV('bukhari:735')], cross=[xg('huda-prayer')], tags=['salah', 'ruku'], trig=['how to bow in prayer', 'ruku', 'what to say in ruku'])
    Hw("In prostration, the forehead with the nose, both hands, both knees and the toes of both feet touch the ground. Say the glorification of the Lord Most High and ask Allah for what you need.",
       [guide('huda-prayer'), HV('bukhari:812')], cross=[xg('huda-prayer')], tags=['salah', 'sujud'], trig=['how to prostrate', 'sujud', 'seven parts'])
    F("The daily prayers have these units: Fajr is two rak'ahs, Dhuhr four, Asr four, Maghrib three and Isha four. After the second rak'ah of a prayer of three or four, you sit for the first tashahhud and then stand.",
      [guide('huda-prayer')], cross=[xg('huda-prayer')], tags=['salah', 'rakah'], trig=['how many rakat', 'rakah count', 'fajr rakat', 'maghrib rakat'])
    Hw("End the prayer with the last sitting: the tashahhud, blessings on the Prophet, and a dua. Then give the salaam, turning the face to the right and then to the left.",
       [guide('huda-prayer'), HV('bukhari:3370')], cross=[xg('huda-prayer')], tags=['salah', 'tashahhud', 'salaam'], trig=['how to end prayer', 'tashahhud', 'taslim'])
    F("Do each position calmly. The Prophet told a man who prayed in a hurry to go back and pray again, and then taught him to be at ease in the bowing, the standing, the prostration and the sitting.",
      [guide('huda-prayer'), HV('bukhari:757')], cross=[xg('huda-prayer')], tags=['salah', 'calm'], trig=['pray fast', 'rushing prayer', 'tumaninah'])
    Fq("A new Muslim who cannot yet recite al-Fatihah can say words of glorification and praise that the Prophet taught a man in that position, and learn al-Fatihah as soon as possible.",
       [guide('huda-prayer'), HV('abudawud:832')], cross=[xg('huda-prayer')], tags=['salah', 'new-muslim'], trig=['cannot memorise fatihah', 'new muslim prayer', 'dont know fatiha'])
    F("Al-Fatihah is a pillar of the prayer in the Maliki, Shafi'i and Hanbali schools. Scholars differ: in the Hanafi school it is wajib, so the prayer is valid without it but it should be repeated. Behind an imam, the schools also differ on whether to recite.",
      [guide('huda-prayer')], cross=[xg('huda-prayer')], tags=['salah', 'fatihah', 'madhhab'], schools=Dh, trig=['recite fatiha behind imam', 'fatihah pillar'])

    # ---- times, congregation, Friday
    F("The five prayers have set times. Fajr lasts until the sun begins to rise, Dhuhr until Asr comes, Asr until the sun turns yellow, Maghrib until the twilight has gone, and Isha until the middle of the night.",
      [guide('huda-prayer-times'), Q('4:103', S), HV('muslim:612')], cross=[xg('huda-prayer-times')], tags=['prayer-times'],
      trig=['prayer times', 'when does asr end', 'time of isha', 'end time of fajr'])
    F("When Asr and Isha begin is not the same in every school. Scholars differ: the Hanafi school starts Asr when a shadow is twice the object, the other three when it equals the object. For Isha the Hanafi view of Abu Hanifa waits for the white twilight to go.",
      [guide('huda-prayer-times')], cross=[xg('huda-prayer-times')], tags=['prayer-times', 'madhhab'], schools=Dh, trig=['asr hanafi time', 'when does asr start', 'isha time difference'])
    F("There are three times when voluntary prayer is forbidden: as the sun begins to rise until it is fully up, at midday when it stands at its height until it passes, and as it nears setting until it sets.",
      [guide('huda-prayer-times'), HV('muslim:831')], cross=[xg('huda-prayer-times')], tags=['prayer-times', 'forbidden-times'], trig=['forbidden times for prayer', 'can i pray at sunrise'])
    F("The Prophet said that the prayer in congregation is twenty-seven times better than praying alone. Walk to it calmly and do not hurry when you hear the iqamah.",
      [guide('huda-congregation'), HV('bukhari:645')], cross=[xg('huda-congregation')], tags=['congregation'], trig=['congregational prayer reward', 'jamaah', 'pray in mosque'])
    F("The ruling on praying in congregation for men differs. Scholars differ: the Hanafi and Maliki schools say an emphasised sunnah, the Shafi'i school a collective obligation, and the Hanbali school a personal obligation for men able to attend.",
      [guide('huda-congregation')], cross=[xg('huda-congregation')], tags=['congregation', 'madhhab'], schools=Dh, trig=['is jamaah obligatory', 'must men pray in mosque'])
    Hw("In the rows, stand shoulder to shoulder and keep them straight, as the Prophet taught. Follow the imam and do not go ahead of him: bow when he bows and rise when he rises.",
       [guide('huda-congregation'), HV('bukhari:723'), HV('bukhari:689')], cross=[xg('huda-congregation')], tags=['congregation', 'rows'], trig=['straighten rows', 'follow the imam', 'how to stand in jamaah'])
    Hw("For Friday prayer, bathe and use perfume if you have it, go early, and listen to the sermon in silence. The prayer is two rak'ahs after the khutbah. If you miss it, pray Dhuhr.",
       [guide('huda-jumuah'), HV('bukhari:877'), HV('bukhari:934')], cross=[xg('huda-jumuah')], tags=['jumuah'], trig=['friday prayer', 'jumuah', 'khutbah', 'what to do on friday'])
    F("The minimum number for a valid Friday prayer is not agreed. Scholars differ: the Hanafi school requires the imam and three men, the Maliki about twelve, and the Shafi'i and Hanbali schools forty resident men in the relied-upon view.",
      [guide('huda-jumuah')], cross=[xg('huda-jumuah')], tags=['jumuah', 'madhhab'], schools=Dh, trig=['how many for jumuah', 'minimum for friday prayer'])

    # ---- forgetting, travel, qada
    Fq("If you forget the first sitting and stand up, do not go back. Finish the prayer and make two prostrations before the salaam, as the Prophet did.",
       [guide('huda-sujud-sahw'), HV('bukhari:1224')], cross=[xg('huda-sujud-sahw')], tags=['sujud-sahw'], trig=['forgot first tashahhud', 'sujud sahw', 'forgot in prayer'])
    F("Whether the two prostrations for forgetting come before or after the salaam differs. Scholars differ: the Hanafi school says always after, the Shafi'i always before, and the Maliki and Hanbali schools depend on the case.",
      [guide('huda-sujud-sahw')], cross=[xg('huda-sujud-sahw')], tags=['sujud-sahw', 'madhhab'], schools=Dh, trig=['sujud sahw before or after salam'])
    F("When travelling, the four-rak'ah prayers can be shortened to two. Fajr and Maghrib are not shortened. Allah says there is no blame in shortening the prayer when you travel.",
      [guide('huda-travel-prayer'), Q('4:101', S)], cross=[xg('huda-travel-prayer')], tags=['travel', 'qasr'], trig=['shorten prayer travel', 'qasr', 'traveller prayer'])
    F("The distance and the length of stay for shortening differ. Scholars differ: the Hanafi school gives about 77 kilometres, the other three about 80 to 83, and the schools set different limits on how long a stay makes you a resident.",
      [guide('huda-travel-prayer')], cross=[xg('huda-travel-prayer')], tags=['travel', 'madhhab'], schools=Dh, trig=['how far to shorten prayer', 'travel distance qasr'])
    Fq("If you are ill and cannot stand, pray sitting; if you cannot sit, pray on your side. This is what the Prophet told a man who had piles.",
       [guide('huda-travel-prayer'), HV('bukhari:1117')], cross=[xg('huda-travel-prayer')], tags=['illness', 'prayer'], trig=['pray sitting', 'sick cant stand', 'how to pray when ill'])
    Fq("A missed prayer is still owed. Pray it as soon as you remember, as the same prayer with the same number of rak'ahs.",
       [guide('huda-qada'), HV('bukhari:597')], cross=[xg('huda-qada')], tags=['qada', 'missed-prayer'], trig=['missed prayer', 'make up prayer', 'qada', 'slept through fajr'])
    F("The order for making up missed prayers differs. Scholars differ: the Hanafi, Maliki and Hanbali schools require order in set cases, while the Shafi'i school treats order as recommended.",
      [guide('huda-qada')], cross=[xg('huda-qada')], tags=['qada', 'madhhab'], schools=Dh, trig=['order of missed prayers', 'qada order'])
    Fq("If you owe many prayers from years of not praying, make an honest estimate, pray them alongside your daily prayers until the count is cleared, and ask forgiveness. This is advice from the scholars, not a hadith. The four schools say they are still owed.",
       [guide('huda-qada')], cross=[xg('huda-qada'), xg('huda-tawba')], tags=['qada', 'tawbah'], trig=['years of missed prayers', 'i have not prayed for years', 'many missed prayers'],
       dns=['Gentle and hopeful; no shaming; a minority view exists, so for a hard case point to a scholar.'])

    # ---- night, istikhara, adhan, mosque
    Hw("Istikhara is a prayer for guidance on a permitted choice: pray two rak'ahs that are not the obligatory prayer, say the dua the Prophet taught, name the matter, then consult people and decide. You do not need a dream.",
       [guide('huda-istikhara'), HV('bukhari:6382')], cross=[xg('huda-istikhara')], tags=['istikhara'], trig=['istikhara', 'how to pray istikhara', 'guidance prayer', 'decision prayer'])
    Hw("The night prayer is prayed two rak'ahs at a time, and the Prophet said to make witr the last prayer of the night. Aisha reported that he did not go beyond eleven rak'ahs.",
       [guide('huda-tahajjud'), HV('bukhari:990'), HV('bukhari:998'), HV('bukhari:1147')], cross=[xg('huda-tahajjud'), xg('huda-witr')], tags=['tahajjud', 'witr'], trig=['tahajjud', 'night prayer', 'how to pray witr'])
    F("Witr is disputed in its ruling. Scholars differ: in the Hanafi school it is wajib, and in the Maliki, Shafi'i and Hanbali schools a strongly emphasised sunnah.",
      [guide('huda-witr')], cross=[xg('huda-witr')], tags=['witr', 'madhhab'], schools=Dh, trig=['is witr obligatory', 'witr ruling'])
    Hw("When you hear the adhan, repeat what the caller says, and at the calls to prayer and to success say that there is no power and no strength except with Allah. After it, send blessings on the Prophet and make the dua he taught.",
       [guide('huda-adhan'), HV('muslim:385')], cross=[xg('huda-adhan')], tags=['adhan'], trig=['what to say after adhan', 'reply to adhan', 'dua after adhan'])
    Hw("Mosque manners: enter with the right foot and ask for the doors of mercy, pray two rak'ahs before you sit, keep your voice low, and keep away from strong smells such as raw garlic or onion.",
       [guide('huda-mosque'), HV('bukhari:444'), HV('bukhari:855')], cross=[xg('huda-mosque')], tags=['mosque', 'adab'], trig=['mosque manners', 'enter mosque dua', 'tahiyyat al-masjid'])
    return [p]
