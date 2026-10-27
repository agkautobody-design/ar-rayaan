# Prayer: counts, times, conditions, and the acts people ask about by name.
# Specific questions come first: the first entry that matches answers.

E('witr',
  m=[r'\bwitr\b'],
  x=[r'\b(?:app|game|screen|guide)\b'],
  topic='witr',
  text="""
Witr is the odd-numbered prayer of the night, prayed after Isha and before Fajr. The Prophet ﷺ told us to make it the last prayer of the night ({H bukhari:998|The Prophet said to make witr your last prayer at night}).

How many rak'ahs depends on the school:
- Hanafi: witr is wajib (a strongly obligatory prayer, just below fard). It is three rak'ahs with one salam, with the qunut du'a said in the third rak'ah before the ruku'.
- Shafi'i, Maliki and Hanbali: witr is a strongly recommended sunnah (sunnah mu'akkadah). It can be one rak'ah or three, five and so on up to eleven. Most people pray two rak'ahs, give the salam, then one rak'ah.

The Prophet ﷺ taught the night prayer as pairs of rak'ahs, with one rak'ah at the end if you fear that dawn is near, to make the total odd ({H muslim:749|A man asked about the night prayer: it is pairs of rak'ahs, and if you fear morning is near, pray one rak'ah to make your prayer an odd number}).

If you miss witr, the Hanafi school says to make it up; the others say it is a missed sunnah. Ask a scholar of your school for the details of qunut.
""",
  go=['/huda/guide?id=huda-witr'],
  review='Hanafi wajib/3 rak\'ahs and the other schools\' sunnah/1-11 are standard fiqh teaching, not text-checked here.')

E('taraweeh',
  m=[r'\btaraweeh\b', r'\bnight prayers? (?:in|of) ramadan\b', r'\bramadan night prayers?\b'],
  x=[r'\b(?:app|screen|guide|reminder)\b'],
  topic='taraweeh',
  text="""
Taraweeh is the extra night prayer of Ramadan, prayed after Isha, usually in congregation at the masjid. It is a strongly recommended sunnah, not an obligation. It is prayed two rak'ahs at a time.

How many rak'ahs: the schools and communities differ, and all of it is accepted.
- Eight rak'ahs plus witr (eleven in all): this follows A'ishah's account that the Prophet ﷺ never prayed more than eleven rak'ahs at night, in Ramadan or outside it ({H bukhari:1147|A'ishah said the Prophet never exceeded eleven rak'ahs at night in Ramadan or other months}).
- Twenty rak'ahs plus witr: the view of the Hanafi, Shafi'i and Hanbali schools, and what many masjids follow. Praying taraweeh together behind one reciter goes back to Umar, who gathered the people for it in Ramadan ({H bukhari:2010|Umar saw people praying in scattered groups in Ramadan and gathered them behind one reciter, saying what a good innovation this is}).

You may pray it at home alone if you cannot reach the masjid. Praying longer with a calm, unhurried recitation matters more than the number.
""",
  go=['/huda/guide?id=huda-taraweeh'],
  review='Which schools hold 8 or 20 rak\'ahs is standard teaching, not text-checked here.')

E('eid-prayer',
  m=[r'\beid prayer\b', r'\bprayer (?:of|for|on) eid\b', r'\bhow (?:to|do (?:i|we|you)) pray eid\b',
     r'\beid (?:salah|namaz)\b', r'\bpray eid\b', r'\beid prayer (?:rakah|steps)\b'],
  x=[r'\b(?:app|screen|game|date|when is)\b'],
  topic='eid',
  text="""
The Eid prayer (for Eid al-Fitr and Eid al-Adha) is two rak'ahs prayed in congregation, usually in an open ground or large masjid, after the sun has risen about a spear's length. There is no adhan and no iqamah.

How it goes:
1. Make the intention and say the opening takbir.
2. Extra takbirs: the Maliki, Shafi'i and Hanbali schools say seven takbirs in the first rak'ah (after the opening) and five in the second, raising the hands with each. The Hanafi school says three extra takbirs in each rak'ah.
3. Recite al-Fatihah and a surah, then finish each rak'ah as in any prayer.
4. After the salam, the imam gives the khutbah. The Prophet ﷺ prayed first and gave the khutbah after ({H bukhari:957|The Prophet prayed the Eid of Adha and Eid of Fitr, then gave the khutbah after the prayer}).

Ruling: the Hanafi school calls it wajib, the Maliki and Shafi'i schools a strongly recommended sunnah, and the Hanbali school a communal duty (fard kifayah). Women are encouraged to attend; those who are menstruating stay out of the prayer area but share in the du'a.

Before the Eid al-Fitr prayer it is a sunnah to eat some dates: the Prophet ﷺ never went out on that day until he had eaten some ({H bukhari:953|Anas said the Prophet did not go out on the day of Eid al-Fitr until he had eaten some dates, an odd number}). Zakat al-fitr is paid before people go out to the prayer ({H bukhari:1503|Ibn Umar said the Prophet made zakat al-fitr a sa' of dates or barley on every Muslim, and ordered it be paid before people go out to the Eid prayer}).
""",
  review='Number of extra takbirs per school, the rulings, and the women-attending detail are standard fiqh teaching, not text-checked here.')

E('jumuah-basics',
  m=[r'\bjumuah (?:prayer )?(?:rakah|how many)\b', r'\bhow many rakah\b.*\bjumuah\b',
     r'\bwhat is jumuah\b', r'\bis jumuah (?:obligatory|fard|compulsory|wajib|mandatory)\b',
     r'\bjumuah (?:obligatory|fard|compulsory|mandatory)\b', r'\bmust (?:i|women|woman) (?:attend|go to|pray) jumuah\b',
     r'\bwomen\b.*\bjumuah\b', r'\bfriday prayers?\b', r'\bjumuah\b'],
  x=[r'\b(?:masjid|masajid|mosque|mosques|near me|nearest|closest|nearby)\b', r'\b(?:app|screen|game|guide|khutbah|khutba|sermon)\b'],
  topic='jumuah',
  text="""
Jumu'ah (the Friday prayer) is two rak'ahs, prayed in congregation at the time of Dhuhr, in place of Dhuhr. Before it, the imam gives two short sermons (khutbahs), and listening to them is part of the prayer.

Who must attend: every free adult Muslim man who is a resident (not travelling) and is able to go. When the call is made on Friday, the Qur'an says: {Q 62:9|then proceed to the remembrance of Allah and leave trade}. Women, travellers, the sick and children are not required to attend, but a woman may go if she wishes, and if she prays at home she prays Dhuhr (four rak'ahs).

Sunnah acts of the day: ghusl, clean clothes, perfume (for men), going early, reciting Surah al-Kahf, and sending more blessings on the Prophet ﷺ.

If you miss Jumu'ah, pray Dhuhr. Neglecting it is serious: the Prophet ﷺ said people must stop neglecting the Friday prayer or Allah will seal their hearts ({H muslim:865|The Prophet said from his pulpit that people must cease to neglect the Friday prayer or Allah will seal their hearts and they will be among the negligent}).
""",
  go=['/huda/guide?id=huda-jumuah'],
  review='Who must attend, and the sunnah acts of Friday, are standard fiqh teaching, not text-checked here.')

E('travel-prayer',
  m=[r'\bshorten(?:ed|ing)? (?:the )?prayers?\b', r'\bqasr\b', r'\bshortened prayers?\b',
     r'\b(?:travel|traveling|travelling|traveller|traveler|journey|trip|safar)\b.*\bprayers?\b',
     r'\bprayers?\b.*\b(?:travel|traveling|travelling|traveller|traveler|journey|trip|safar|airplane|plane|flight)\b',
     r'\bcombine\b.*\bprayers?\b', r'\bjam\b', r'\bpray(?:ing)? (?:on|in) (?:a |the )?(?:plane|airplane|train|bus|car|ship|boat)\b'],
  x=[r'\b(?:times? (?:today|now|tomorrow)|app screen|game)\b'],
  topic='travel prayer',
  text="""
A traveller may shorten the four-rak'ah prayers (Dhuhr, Asr and Isha) to two rak'ahs. Fajr (2) and Maghrib (3) stay as they are. This is a mercy from Allah: {Q 4:101|there is no blame upon you for shortening the prayer}. Umar asked the Prophet ﷺ about it, and he said it is a charity from Allah, so accept His charity ({H muslim:686|Umar asked about shortening when people were safe, and the Prophet said it is a charity Allah has given you, so accept it}).

When it applies: on a journey of about 80 km (roughly 50 miles) or more, by the view of most scholars. Some scholars say there is no fixed distance. You begin shortening when you leave your town. How long you can keep shortening in one place differs: the Shafi'i, Maliki and Hanbali schools say up to about four days of staying; the Hanafi school says up to fifteen days.

Combining: the Shafi'i, Maliki and Hanbali schools allow a traveller to join Dhuhr with Asr, and Maghrib with Isha, at the time of either. The Prophet ﷺ did this, delaying Dhuhr to Asr when he set out before noon ({H bukhari:1111|When the Prophet set out before noon he delayed Dhuhr until Asr time and prayed them together}). The Hanafi school allows joining only at Arafah and Muzdalifah during Hajj. You may not skip a prayer or push it out of its day.

On a plane or train: face the qibla as far as you can and pray seated if you cannot stand. If the time will run out, pray in your seat; do not leave a prayer to be made up unless you have to.
""",
  go=['/huda/guide?id=huda-travel'],
  review='Distance, stay-length, combining by school and plane-prayer details are standard fiqh teaching, not text-checked here.')

E('sitting-prayer',
  m=[r'\bpray(?:ing)? (?:sitting|seated|lying|while sitting|in a chair|on a chair|from a chair)\b',
     r'\bsit(?:ting)? down\b.*\bpray\b', r'\bpray\b.*\bsit(?:ting)? down\b',
     r'\b(?:sick|ill|illness|injured|elderly|disabled|disability|wheelchair|bed ?ridden|back pain|knee pain|surgery|pregnan\w*)\b.*\bprayers?\b',
     r'\bprayers?\b.*\b(?:when|if) (?:i am|im|i m) (?:sick|ill|injured|unwell|pregnant)\b',
     r'\bcannot stand\b.*\bprayers?\b', r'\bcant stand\b.*\bprayers?\b', r'\bprayers? (?:in|on) (?:a )?(?:chair|wheelchair|bed)\b',
     r'\bprayers?\b.*\bunable to stand\b', r'\bprayers?\b.*\bsick(?:ness)?\b'],
  x=[r'\b(?:fast\w*|ramadan|zakat|janazah|funeral)\b'],
  topic='sick prayer',
  text="""
Yes. Prayer is never dropped because of illness; it is made easier. If you cannot stand, pray sitting; if you cannot sit, pray lying on your side. The Prophet ﷺ told 'Imran ibn Husayn, who had piles: pray standing, and if you cannot, then sitting, and if you cannot, then on your side ({H bukhari:1117|Imran ibn Husayn had piles and asked about the prayer; the Prophet said pray standing, if you cannot then sitting, if you cannot then on your side}).

How: if you can stand for part of the prayer, stand for that part. If you can stand but not go down to the ground, stand for the standing and bow and prostrate by nodding. If you cannot go down, nod your head for ruku' and again, lower, for sujud. Sitting on a chair is acceptable when sitting on the floor is not possible. The Qur'an says {Q 2:286|Allah does not charge a soul except [with that within] its capacity}.

If you are too ill to pray at the right time, you may combine Dhuhr with Asr and Maghrib with Isha according to the Hanbali school (and some Shafi'i and Maliki scholars); otherwise pray each as best you can. Keep praying as long as you have your mind; if you lose consciousness, ask a scholar about making it up.

The Illness and Patience guide has more help.
""",
  go=['/huda/guide?id=huda-illness'],
  review='Combining during illness (Hanbali and some others) and unconscious-person rulings are school positions from standard fiqh, not text-checked here.')

E('missed-prayers',
  m=[r'\b(?:make up|makeup|make-up|catch up|compensate|repay|replace)\b.*\b(?:missed|skipped|forgotten|lost|old|past|backlog)\b.*\bprayers?\b',
     r'\bmissed prayers?\b', r'\bqada\b.*\bprayers?\b', r'\bprayers? qada\b', r'\bqada prayers?\b',
     r'\bmiss(?:ed|ing)?\b.*\b(?:prayers?|fajr|dhuhr|asr|maghrib|isha)\b',
     r'\b(?:skip(?:ped)?|overslept|slept through|sleep through|woke up late for)\b.*\b(?:prayers?|fajr|dhuhr|asr|maghrib|isha)\b',
     r'\bforgot (?:to pray|my (?:prayers?|fajr|dhuhr|asr|maghrib|isha)|about (?:the )?(?:prayers?|fajr|dhuhr|asr|maghrib|isha))\b',
     r'\bhaven t prayed\b', r'\bdidn t pray\b.*\b(?:years|long|months)\b', r'\bnot prayed for\b', r'\bstopped praying\b',
     r'\bprayers? (?:i|i have) (?:missed|skipped|not prayed)\b', r'\bmake up\b.*\bprayers?\b', r'\bprayers? make up\b'],
  x=[r'\b(?:fast\w*|ramadan|period|menstrua\w*|cycle)\b'],
  topic='missed prayers',
  gate=True,
  why='The Prophet ﷺ said a forgotten prayer has no expiation except to pray it, so it is prayed when remembered; for a prayer left on purpose, most scholars hold the debt is still there, so it is made up along with sincere repentance.',
  text="""
If you missed a prayer because you slept through it or forgot, pray it as soon as you remember. The Prophet ﷺ said: if anyone forgets a prayer, he should pray it when he remembers it, and it has no expiation except that ({H bukhari:597|The Prophet said whoever forgets a prayer should pray it when he remembers it, there is no expiation but that; then he recited the verse about establishing prayer for My remembrance}) ({H muslim:684|Anas reported the same: he who forgets the prayer should pray it when he remembers it}).

If you left a prayer on purpose or over a long time (years): that is a serious matter, so start with sincere tawbah (repentance) and begin praying on time from today. Most scholars (all four schools) say the missed prayers are still owed and should be made up. A minority say they cannot be made up and the way out is repentance and voluntary prayers. Follow the view of your school and ask a trusted scholar if you are unsure.

How to make them up: pray each missed prayer in its own rak'ah count (Fajr as 2, Dhuhr as 4 and so on), in order if you can. If you do not know how many you missed, estimate honestly and pray until you are sure you have covered them. A practical way is to pray one or two make-up prayers after each of today's prayers until the debt is done, without leaving your current prayers on time. A woman does not make up prayers missed during her period.

The Making Up Missed Prayers guide in this app lays out the method.
""",
  go=['/huda/guide?id=huda-qada'],
  review='Deliberately missed prayers: majority (make up) versus minority (cannot make up), the order and "one with each prayer" method are fiqh teaching, not text-checked here.')

E('prayer-socks-shoes',
  m=[r'\bsocks?\b', r'\bkhuff\w*\b', r'\bmasah\b', r'\bwip(?:e|ing) over\b', r'\bshoes?\b.*\bprayers?\b',
     r'\bprayers?\b.*\b(?:shoes?|sandals?|slippers?|footwear)\b', r'\bpray(?:ing)? (?:in|with|wearing) (?:shoes?|sandals?|socks?)\b'],
  x=[r'\b(?:game|app)\b'],
  topic='socks',
  text="""
Praying in socks or shoes is valid as long as they are clean (free of najasa). Anas was asked whether the Prophet ﷺ prayed with his shoes on, and said yes ({H bukhari:386|Anas was asked if the Prophet ever prayed with his shoes on and said yes}). Many masjids keep carpets clean, so shoes are taken off there out of respect; follow the local custom for the place you are in.

Wiping over socks instead of washing the feet in wudu (masah): you may wipe over leather socks (khuffs) if you put them on after you had a complete wudu. The time limit is one day and night for a resident and three days and nights for a traveller ({H muslim:276|Ali said the Prophet set three days and nights for a traveller and one day and one night for a resident}).

Ordinary cotton or wool socks: the schools differ. The Hanbali school accepts any covering thick enough to walk in; the Hanafi school accepts thick socks that stay up by themselves; the Shafi'i school requires leather or waterproof socks. Many scholars today accept thick socks. If your socks are thin, wash your feet. The schools also differ on when the period starts counting (from your first wudu-break after putting them on, or from your first wipe), so ask your imam if you rely on this.

Wiping ends when the time ends, when you take the socks off, or when a bath (ghusl) becomes due.
""",
  go=['/huda/guide?id=huda-wudu'],
  review='Which socks permit wiping per school, and how the period is counted, are standard fiqh teaching, not text-checked here.')

E('qibla-direction',
  m=[r'\bqibla\b', r'\bdirection (?:of|for|to) (?:the )?(?:prayer|kaaba|makkah)\b', r'\bwhich way (?:to|do i) (?:face|pray)\b',
     r'\bwhere (?:do|should) i face\b', r'\bface (?:the )?(?:kaaba|makkah)\b'],
  x=[r'\b(?:story|stories|why did|change of|changed|history|jerusalem|aqsa)\b'],
  topic='qibla',
  text="""
The qibla is the direction of the Kaaba in Makkah, which every Muslim faces in prayer. Allah says: {Q 2:144|turn your face toward al-Masjid al-Haram. And wherever you [believers] are, turn your faces toward it [in prayer]}.

If you can see the Kaaba, face it itself. If you are far away, facing its direction is enough: you do not need perfect accuracy. If you cannot work out the direction, do your best with a compass, an app or by asking, and your prayer stands even if you were slightly off.

In the app, the Qibla screen works out the exact bearing from your location. It needs your location (asked only when you tap the button) or the city you choose in Prayer Times. The direction is worked out on your device. The live compass uses your phone's magnetic sensor, so keep away from metal and magnets; it may show a static dial on a desktop computer.

On a journey, the Prophet ﷺ prayed his voluntary prayers on the back of his mount facing whichever way it went, but never the obligatory prayer ({H bukhari:1098|Ibn Umar said the Prophet prayed the optional prayers on his mount facing any direction, and witr too, but never the compulsory prayer on it}).
""",
  go=['/qibla'],
  review='Facing the direction (not the exact point) when far away is the majority view; not text-checked here.')

E('prayer-times-overview',
  m=[r'\b(?:five|5) (?:daily )?prayers?\b', r'\bdaily prayers?\b', r'\bnames? of (?:the )?(?:five )?(?:daily )?prayers?\b',
     r'\bprayer times? (?:in islam|are|of)\b', r'\bwhen (?:is|does|do|should|can) (?:i |we )?(?:pray )?(?:the )?(?:fajr|dhuhr|asr|maghrib|isha)\b',
     r'\btime (?:of|for) (?:the )?(?:fajr|dhuhr|asr|maghrib|isha)\b', r'\b(?:fajr|dhuhr|asr|maghrib|isha) (?:time|ends?|starts?|begins?)\b',
     r'\bwhen does (?:fajr|dhuhr|asr|maghrib|isha)\b', r'\bwhat are the prayers\b', r'\bwhen to pray\b', r'\bhow many (?:times|prayers) (?:a|per|in a|each|every) day\b', r'\btimes? of prayers? (?:per|in a|each|every) day\b', r'\bprayers? times? (?:per|in a|each|every) day\b', r'\bhow often do muslims pray\b',
     r'\bwhat is the (?:last|first) time for\b', r'\bwhen does.*prayer (?:start|end|begin)\b'],
  x=[r'\b(?:today|tomorrow|now|tonight|my|near|nearby|app|city|location|alarm|reminder|notification)\b'],
  topic='prayer times',
  text="""
The five daily prayers and when each is prayed:
- Fajr (dawn): from true dawn, when the white thread of dawn shows, until sunrise.
- Dhuhr (midday): from just after the sun passes its highest point until Asr begins.
- Asr (afternoon): from when an object's shadow equals its height (Hanafi: twice its height) until sunset. The best time ends when the sun turns yellow.
- Maghrib (sunset): from sunset until the red twilight has gone (the Hanafi school waits for the white twilight to go).
- Isha (night): from the end of twilight until midnight, and by necessity until Fajr begins.

The Prophet ﷺ said the time of Fajr lasts until the first part of the sun appears, Dhuhr until Asr comes, Asr until the sun turns yellow, Maghrib until the twilight disappears, and Isha until half the night has passed ({H muslim:612|The Prophet gave the time of each prayer: Fajr until the sun starts to rise, Zuhr until Asr, Asr until the sun turns yellow, Maghrib until the twilight goes, Isha until half the night}). The Qur'an says {Q 4:103|prayer has been decreed upon the believers a decree of specified times}, and the white thread of dawn is in {QR 2:187}.

The exact minutes for where you are depend on the calculation method. The Prayer Times screen shows today's times for your location, with alerts.
""",
  go=['/prayer'],
  review='The Asr and Maghrib/Isha limits by school are standard fiqh teaching, not text-checked here.')

E('prayer-rakahs',
  m=[r'\bhow many\b.*\brakah\b', r'\bnumber of rakah\b', r'\brakah\b.*\b(?:in|of|for|is|are)\b.*\b(?:fajr|dhuhr|asr|maghrib|isha|each|every|five|daily|fard|obligatory)\b',
     r'\b(?:fajr|dhuhr|asr|maghrib|isha)\b.*\b(?:how many|rakah)\b', r'\bhow many (?:fard|obligatory|farz) (?:prayers?)\b',
     r'\b(?:fajr|dhuhr|asr|maghrib|isha)\b.*\bsunnah\b', r'\bsunnah\b.*\b(?:fajr|dhuhr|asr|maghrib|isha)\b',
     r'\brawatib\b', r'\bsunnah (?:prayers?|rakah)\b'],
  x=[r'\b(?:tahajj?ud|tahajud|qiyam|duha|ishraq|tarawee?h|istikhara|janazah|eid)\b', r'\b(?:app|screen)\b'],
  topic='rakahs',
  text="""
The five daily prayers have 17 obligatory (fard) rak'ahs: Fajr 2, Dhuhr 4, Asr 4, Maghrib 3, Isha 4. On Friday, Jumu'ah (2 rak'ahs with the khutbah) takes the place of Dhuhr. A traveller shortens the four-rak'ah prayers to 2.

Alongside them are the regular sunnah prayers (rawatib). The Prophet ﷺ promised a house in Paradise for twelve of them each day: four before Dhuhr, two after it, two after Maghrib, two after Isha and two before Fajr ({H tirmidhi:415|Umm Habibah heard the Prophet say a house in Paradise for whoever prays twelve rak'ahs in a day and night: four before Zuhr and two after, two after Maghrib, two after Isha and two before Fajr}). The two before Fajr are the most emphasised. The schools differ on which are strongly emphasised and on extra ones (for example, four before Asr), so follow your school.

Witr (odd rak'ahs after Isha) is separate; see the Witr guide.
""",
  go=['/huda/guide?id=huda-nawafil', '/huda/guide?id=huda-witr'],
  review='Which sunnahs each school emphasises is standard fiqh teaching, not text-checked here.')

E('prayer-conditions',
  m=[r'\bconditions? (?:of|for) (?:the )?prayers?\b', r'\bprerequisites? (?:of|for) (?:the )?prayers?\b',
     r'\bshurut\b', r'\bwhat (?:is|are) (?:needed|required) (?:for|before) (?:the )?prayers?\b', r'\bbefore (?:i |we )?(?:start|begin) (?:the )?prayers?\b',
     r'\bwhat makes (?:a |the )?prayers? (?:valid|accepted|sahih)\b', r'\bvalid(?:ity)? of (?:the )?prayers?\b',
     r'\bprayers? (?:conditions?|requirements?)\b', r'\bpillars? of (?:the )?prayers?\b', r'\bfard (?:acts )?of (?:the )?prayers?\b',
     r'\bwhat breaks (?:the |my )?prayers?\b', r'\bwhat invalidates (?:the |my )?prayers?\b',
     r'\bhow many (?:pillars?|fards?)\b.*\bprayers?\b', r'\bpillars? of salah\b', r'\bwhat nullif\w+ (?:the )?prayers?\b'],
  topic='prayer conditions',
  text="""
Before you pray, six conditions must be met:
1. You are a Muslim, of sound mind, and past puberty (children are gently taught to pray from about seven, but it is not yet an obligation on them).
2. The time of that prayer has begun. {Q 4:103|prayer has been decreed upon the believers a decree of specified times}.
3. You are pure: wudu for the small impurity, ghusl for the big one. The Prophet ﷺ said the prayer of someone who has broken wudu is not accepted until he makes wudu ({H bukhari:135|The Prophet said the prayer of one who passes wind or urine is not accepted until he does wudu}).
4. Your body, clothes and prayer place are free of najasa (physical impurity).
5. Your awrah is covered: for a man from the navel to the knee, for a woman her whole body except the face and hands (the Hanafi school also leaves the feet).
6. You face the qibla and make the intention in your heart.

Inside the prayer, the pillars (without which it is not valid) are standing if you can, the opening takbir, reciting al-Fatihah, ruku', rising from it, sujud (twice in each rak'ah), the sitting between them, the last sitting with the tashahhud, blessings on the Prophet ﷺ in it, and the salam. The schools count a few of these differently (for example, the Hanafi school treats the Fatihah as wajib, not a pillar), so ask your imam if you are unsure.

What breaks the prayer: breaking wudu, speaking on purpose, a lot of unnecessary movement, eating or drinking, turning away from the qibla, laughing aloud, and leaving a pillar on purpose.
""",
  go=['/huda/guide?id=huda-prayer'],
  review='The list of pillars and what breaks the prayer varies slightly by school; it is a general summary of standard fiqh teaching, not text-checked here.')

E('fatiha-in-prayer',
  m=[r'\bfatiha\b', r'\balfatiha\b', r'\bopening (?:chapter|surah|of the book)\b', r'\bumm(?:ul)? (?:al )?(?:kitab|quran)\b',
     r'\b(?:minimum|least|smallest) .*\brecit\w*.*\bprayers?\b', r'\bwhat (?:do i|should i|to) recite\b.*\bprayers?\b',
     r'\brecit\w* (?:in|during) (?:the )?prayers?\b', r'\bwhich surah.*\bprayers?\b', r'\bhow much quran.*\bprayers?\b',
     r'\bsurah.*\bin (?:the )?prayers?\b', r'\bdo i have to recite\b.*\bprayers?\b'],
  x=[r'\b(?:meaning|tafsir|translat\w*|virtue|benefit|read me|show me|play)\b'],
  topic='fatiha',
  text="""
Yes. Reciting al-Fatihah (the opening chapter of the Qur'an) is part of every rak'ah, and the Prophet ﷺ said: whoever does not recite al-Fatihah in his prayer, his prayer is invalid ({H bukhari:756|Ubadah ibn as-Samit reported that the Prophet said the prayer of someone who does not recite the Opening of the Book is not valid}) ({H muslim:394|Ubadah reported the same: there is no prayer for one who does not recite Fatihat al-Kitab}).

The schools differ on the detail. The Shafi'i, Maliki and Hanbali schools make al-Fatihah a pillar in every rak'ah. The Hanafi school makes the Fatihah wajib in every rak'ah of the obligatory prayers (leaving it on purpose is sinful and you repeat the prayer) and says some recitation of the Qur'an in the first two rak'ahs fulfils the pillar. After the Fatihah, in the first two rak'ahs, you add another surah or a few verses. In the last rak'ah of a three- or four-rak'ah prayer, al-Fatihah alone is enough.

Behind an imam: the schools differ on whether you recite the Fatihah behind him in the loud prayers; follow your school.

If you do not yet know it by heart, say the words as best you can and keep learning. A man who could not memorise any Qur'an asked the Prophet ﷺ for something that would be enough; he told him to say "Glory be to Allah, praise be to Allah, there is no god but Allah, Allah is most great, and there is no might and no strength but in Allah" ({H abudawud:832|A man who could not learn the Qur'an was told to say glory be to Allah, praise be to Allah, there is no god but Allah, Allah is most great, and there is no might nor strength but in Allah}).
""",
  go=['/quran'],
  review='Fatihah as pillar versus wajib per school, and recitation behind the imam, are standard fiqh teaching, not text-checked here.')

E('tashahhud-salawat',
  m=[r'\btashahhud\b', r'\bat ?tahiyyat\b', r'\btahiyyat\b', r'\blast sitting\b', r'\bfinal sitting\b',
     r'\bwhat (?:do i|should i|to) (?:say|recite|read) (?:when|in|during) (?:the )?(?:sitting|jalsa|qaada)\b',
     r'\bsalawat\b', r'\bdurood\b', r'\bdarood\b', r'\bsalat ?\w* ibrahim\b', r'\bibrahimiyya\b', r'\bsend(?:ing)? blessings? on the prophet\b',
     r'\bwhat (?:do i|should i) say after tashahhud\b'],
  x=[r'\b(?:virtue|reward|benefit|friday)\b'],
  topic='tashahhud',
  text="""
The tashahhud is said sitting in the second rak'ah of prayers of three or four rak'ahs (the short form), and in the last sitting of every prayer. The Prophet ﷺ taught Ibn Mas'ud its words ({H bukhari:831|Ibn Mas'ud reported that the Prophet taught the tashahhud: greetings, prayers and good words are for Allah; peace be on you O Prophet; peace on us and on Allah's righteous servants; I bear witness there is no god but Allah and Muhammad is His servant and messenger}):

{AR bukhari:831|التحيات لله|الصالحين} {AR bukhari:831|أشهد أن لا|ورسوله}

At-tahiyyatu lillahi was-salawatu wat-tayyibat. As-salamu 'alayka ayyuhan-nabiyyu wa rahmatullahi wa barakatuh. As-salamu 'alayna wa 'ala 'ibadillahis-salihin. Ash-hadu an la ilaha illallah, wa ash-hadu anna Muhammadan 'abduhu wa rasuluh.

Meaning: all greetings, prayers and good things are for Allah. Peace be upon you, O Prophet, and the mercy of Allah and His blessings. Peace be upon us and upon the righteous servants of Allah. I bear witness that there is no god but Allah, and I bear witness that Muhammad is His servant and messenger.

In the last sitting, after the tashahhud, you send blessings on the Prophet ﷺ. The Prophet ﷺ taught his companions to say ({H bukhari:3370|Ka'b ibn Ujrah said the companions asked the Prophet how to send blessings on him and his household; he told them to say: O Allah, send blessings on Muhammad and his family as You sent on Ibrahim and his family, You are praiseworthy and glorious; and bless Muhammad and his family as You blessed Ibrahim and his family}):

{AR bukhari:3370|اللهم صل على محمد|حميد مجيد} {AR bukhari:3370|اللهم بارك|حميد مجيد}

Allahumma salli 'ala Muhammadin wa 'ala ali Muhammad, kama sallayta 'ala Ibrahima wa 'ala ali Ibrahim, innaka hamidun majid. Allahumma barik 'ala Muhammadin wa 'ala ali Muhammad, kama barakta 'ala Ibrahima wa 'ala ali Ibrahim, innaka hamidun majid.

Then you may ask Allah for whatever you wish before the salam. In the second sitting of a three- or four-rak'ah prayer, the schools differ on whether to stop at the tashahhud or add the blessings: ask your imam.
""",
  go=['/huda/guide?id=huda-prayer'],
  review='The transliteration is typed by hand from the Arabic shown; please have a reader check the transliteration. The practice of the second sitting differs by school.')

E('sujud-sahw',
  m=[r'\bsujud (?:as |al |of )?sahw\b', r'\bsujud sahu\b', r'\bsajdah sahw\b', r'\bforgetfulness prostration\b',
     r'\bprostration of forgetfulness\b', r'\bforgot\b.*\b(?:rakah|tashahhud|sujud|ruku|sit)\b', r'\bforget\b.*\b(?:rakah|tashahhud)\b',
     r'\b(?:lost count|not sure|unsure|doubt)\b.*\brakah\b', r'\bmistake (?:in|during) (?:the )?prayers?\b',
     r'\badded (?:an )?extra rakah\b', r'\bprayed (?:an )?extra\b', r'\bsahw\b', r'\bmade a mistake\b.*\bprayers?\b',
     r'\bcounted wrong\b', r'\bhow (?:do|to) (?:i )?fix.*mistake.*prayer\b'],
  topic='sujud sahw',
  text="""
Sujud as-sahw (the prostration of forgetfulness) is two extra prostrations you make when you forget something in the prayer: you add a rak'ah or movement, leave out a required act (like the middle sitting), or are unsure how many rak'ahs you prayed. After them you sit and give the salam.

When you make it differs between the schools:
- Hanafi: after the salam (one salam, then the two prostrations, then tashahhud and the final salam).
- Shafi'i: before the final salam.
- Maliki: before the salam when something was left out, after it when something was added.
- Hanbali: follows the hadiths, so before the salam in most cases, after it where the Prophet ﷺ did so.

Both ways are in the Sunnah. When the Prophet ﷺ got up from the middle sitting without sitting, he made two prostrations before the salam ({H bukhari:829|Ibn Buhaina reported the Prophet stood after two rak'ahs without sitting and made two prostrations before giving the salam}). When he gave the salam after two rak'ahs by mistake, then completed the prayer, he made two prostrations after the salam ({H bukhari:1229|Abu Huraira reported the Prophet finished after two rak'ahs by mistake, Dhul-Yadayn pointed it out, he prayed two more, gave the salam and made two prostrations}).

If you are unsure how many rak'ahs you prayed, the Prophet ﷺ said to put the doubt aside, build on what you are sure of and make two prostrations ({H muslim:571|Abu Sa'id reported the Prophet said that if one is in doubt about how much he prayed he should put the doubt aside, base it on what he is sure of and make two prostrations before the salam}). The sujud does not repair a pillar you left out; that must be prayed again.
""",
  review='Per-school timing of the prostrations is standard fiqh teaching, not text-checked here.')

E('prayer-pray-howto',
  m=[r'\bhow (?:to|do (?:i|we|you)|can i|should i) (?:pray|perform (?:the )?prayers?|do (?:the )?prayers?|offer (?:the )?prayers?|make (?:the )?prayers?)\b$',
     r'\bhow (?:to|do (?:i|we|you)|can i|should i) pray (?:salah|prayer|properly|correctly|step by step)?$',
     r'\bhow to pray\b.*\b(?:step by step|for beginners|for a beginner|for new muslims?|properly|correctly|the right way|in islam)\b',
     r'\bteach me (?:how )?to pray\b', r'\bsteps? (?:of|for|to) (?:the )?prayers?\b', r'\bprayers? steps?\b', r'\bi (?:want|need) to learn (?:how )?to pray\b',
     r'\bhow (?:to|do i) start praying\b', r'\bbeginner.*prayers?\b', r'\bhow to perform salah\b',
     r'\bwhat (?:is|are) the (?:steps|actions) (?:of|in) (?:the )?prayers?\b',
     r'\bhows? (?:do|to) (?:i|we) pray\b', r'\b(?:learn|learning) (?:how )?to pray\b', r'\bpray(?:ing)? (?:as|for) an? (?:absolute )?beginner\b', r'\bnew to (?:praying|prayer|salah|namaz)\b',
     r'\b(?:fajr|dhuhr|zuhr|asr|maghrib|isha) (?:prayer |salah |namaz )?step by step\b', r'\bstep by step\b.*\b(?:fajr|dhuhr|zuhr|asr|maghrib|isha|salah|namaz|prayer)\b', r'\bnamaz (?:kaise|ka tarika)\b', r'\bnamaz parhne ka tarika\b'],
  x=[r'\b(?:janazah|funeral|eid|jumuah|friday|witr|taraweeh|tahajjud|istikhara|travel\w*|sick|sitting|dhuhr|asr|maghrib|isha|women|woman|child|kid)\b'],
  topic='how to pray',
  text="""
Here is a two-rak'ah prayer from start to finish. Be in wudu, face the qibla, and stand where you will pray.
1. Stand and make the intention in your heart. Say "Allahu akbar" (raise your hands to the ears or shoulders) and fold your hands over your chest or navel (the schools differ), right over left.
2. Recite the opening du'a (optional in some schools), say "A'udhu billahi minash-shaytanir-rajim", then "Bismillah" and al-Fatihah, and say "Amin". Then recite another surah or a few verses, such as Surah al-Ikhlas.
3. Say "Allahu akbar" and bow (ruku'): back straight, hands on knees. Say "Subhana Rabbiyal-'Azim" (Glory to my Lord, the Mighty) three times.
4. Rise saying "Sami'allahu liman hamidah" (Allah hears whoever praises Him), then "Rabbana wa lakal-hamd" (Our Lord, to You is the praise). Stand straight.
5. Say "Allahu akbar" and go down to prostration (sujud): forehead, nose, both palms, both knees and the toes of both feet on the ground. Say "Subhana Rabbiyal-A'la" (Glory to my Lord, the Most High) three times.
6. Say "Allahu akbar", sit up briefly, then prostrate a second time with the same words.
7. Stand up for the second rak'ah and repeat from step 2 (without the opening du'a).
8. After the second sujud of the last rak'ah, sit and say the tashahhud, then the blessings on the Prophet ﷺ.
9. Give the salam, turning your head right then left: "As-salamu 'alaykum wa rahmatullah".

Three- and four-rak'ah prayers: sit for the tashahhud after the second rak'ah, then stand for the rest and sit again at the end. Fard Fajr is 2, Dhuhr 4, Asr 4, Maghrib 3, Isha 4.

The How to Pray guide in this app shows each step in order. If you are learning, pray at your own pace and ask your imam to watch and correct you.
""",
  go=['/huda/guide?id=huda-prayer'],
  review='Hand positions, the opening du\'a and the placement of the hands vary by school; this is the general outline of standard teaching, not text-checked here.')
