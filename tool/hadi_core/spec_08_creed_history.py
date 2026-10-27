# Creed, knowledge, history. Neutral on contested political history; sourced where the sources are open to us.

E('pillars-iman',
  m=[r'\bpillars? of (?:iman|imaan|faith|belief)\b', r'\b(?:six|6) (?:pillars|articles) of (?:iman|imaan|faith|belief)\b', r'\barticles of (?:faith|belief|iman)\b', r'\bwhat (?:do|does) (?:muslims?|islam) believe\b', r'\bwhat is iman\b', r'\bwhat is (?:imaan|faith)$', r'\bbasic beliefs? (?:of|in) islam\b', r'\bbeliefs? of (?:muslims?|islam)\b', r'\bwhat must (?:a )?muslim believe\b'],
  topic='iman',
  text="""
Iman (faith) has six articles. When the angel Jibreel asked the Prophet ﷺ about iman, he answered: {H muslim:8|The Prophet said that iman is to affirm your faith in Allah, in His angels, in His Books, in His Messengers, in the Day of Judgment, and to affirm your faith in the divine decree about good and evil}.

1. Allah: that He is One, with no partner ({QR 112:1}).
2. His angels.
3. His books: the Qur'an, and the earlier revelations as they were sent down (such as the Torah and the Gospel).
4. His messengers: from Adam to Muhammad ﷺ, the last of them ({QR 33:40}).
5. The Last Day: the resurrection, reckoning, Paradise and the Fire.
6. The divine decree (qadar): that everything happens by Allah's knowledge and will, while we are still responsible for our choices.

The Qur'an lists the first five in {QR 2:285} and {QR 4:136}. The five pillars of Islam are separate: the shahada, prayer, zakat, fasting in Ramadan and Hajj ({H bukhari:8|Ibn Umar reported the Prophet said Islam is based on five: to testify that none has the right to be worshipped but Allah and Muhammad is Allah's Messenger, to offer prayer, to pay zakat, to perform Hajj, and to fast in Ramadan}).
""",
  go=['/academy/aqeedah'],
  review='None beyond the cited texts; the one-line gloss of qadar is a standard summary.')

E('become-muslim',
  m=[r'\b(?:become|becoming|convert|converting|revert|reverting|embrace|embracing|accept|accepting|join) (?:to )?(?:a )?(?:islam|muslim)\b', r'\bi want to (?:become|be|convert|revert|embrace|accept|join)\b.*\b(?:muslim|islam)\b', r'\bhow (?:do|can|to) (?:i|someone|one|you) (?:become|convert|revert|embrace|accept|join)\b', r'\bshahada\b', r'\bshahadah\b', r'\btestimony of faith\b', r'\bconversion to islam\b',
     r'\bhow to (?:become|convert|revert) \w*\b', r'\bnew muslim\b', r'\bjust (?:converted|reverted|became a muslim)\b', r'\bi (?:recently )?(?:converted|reverted)\b', r'\bwhat do i need to do to (?:become|be) (?:a )?muslim\b', r'\bwelcome to islam\b'],
  topic='shahada',
  text="""
Welcome. Becoming a Muslim is simple: say the shahada (the declaration of faith), knowing what it means and meaning it:

أشهد أن لا إله إلا الله وأشهد أن محمداً رسول الله
Ash-hadu an la ilaha illa Allah, wa ash-hadu anna Muhammadan rasulu Allah.
"I bear witness that there is no god but Allah, and I bear witness that Muhammad is the Messenger of Allah."

You can say it alone, to Allah, at any time; no priest, certificate or special place is needed. Many people say it before a witness or at a mosque so that the community knows and can help, and that is a good thing to do, but it is not what makes you a Muslim. This is the first of the five pillars ({H bukhari:8|Ibn Umar reported the Prophet said Islam is based on five: to testify that none has the right to be worshipped but Allah and Muhammad is Allah's Messenger, to offer prayer, to pay zakat, to perform Hajj, and to fast in Ramadan}).

Good to know:
- Your earlier sins are forgiven. The Prophet ﷺ said: {H muslim:121|Amr ibn al-As reported the Prophet asked him, Are you not aware that Islam wipes out all the previous misdeeds?}.
- Taking a bath on accepting Islam is recommended: {H abudawud:355|Qays ibn Asim came to the Prophet intending to embrace Islam, and the Prophet commanded him to take a bath with water boiled with the leaves of the lote tree}.
- Learn step by step: first to pray (see the How to Pray guide), then fasting, and the rest as you can. Nobody expects you to know everything at once. Allah says {Q 22:78|has not placed upon you in the religion any difficulty}.

The New Muslim path in this app walks you through the basics. If you want to talk with someone, a nearby masjid will welcome you.
""",
  go=['/new-muslim', '/huda/guide?id=huda-prayer'],
  review='The bath on accepting Islam and what to say are standard practice; Arabic shahada is the universally known text.')

E('bismillah-meaning',
  m=[r'\bbismillah\b', r'\bbismillahi\b', r'\bbasmala\w*\b', r'\bbasmalah\b', r'\bin the name of allah\b.*\bmean\w*\b', r'\bwhy (?:do )?muslims? say bismillah\b', r'\bwhen (?:to|should i) say bismillah\b'],
  x=[r'\b(?:slaughter\w*|halal meat|zabiha)\b'],
  topic='bismillah',
  text="""
Bismillah is short for "Bismillahi r-Rahmani r-Rahim": "In the name of Allah, the Entirely Merciful, the Especially Merciful" ({QR 1:1}). It is the first verse of the Qur'an's opening chapter, and it begins every surah except Surah At-Tawbah.

Muslims say it to begin an action in Allah's name: eating, drinking, entering the home, starting wudu, studying, travelling. The Prophet ﷺ told a boy: {H bukhari:5376|Umar ibn Abi Salama said the Prophet told him to mention the name of Allah, eat with his right hand and eat from what is nearest to him}. Saying "Bismillah" reminds you that you do it with Allah's help and for what He allows.

At the end, "Alhamdulillah" (all praise is due to Allah) is said to thank Him.
""",
  go=['/adhkar'],
  review='Only cited texts.')

E('salam-meaning',
  m=[r'\bassalamu? ?alaikum\b', r'\bas salamu? ?alaykum\b', r'\bassalamualaikum\b', r'\bsalam alaikum\b', r'\bsalaam\b', r'\bwhat (?:does|is) salam\b', r'\bmeaning of (?:salam|salaam|assalam\w*)\b', r'\bhow (?:do|to) (?:i )?(?:greet|reply to) (?:a )?(?:muslim|salam)\b', r'\bwa alaikum\b', r'\bwalaikum\b', r'\bislamic greeting\b', r'\bmuslim greeting\b', r'^greet\w*$'],
  x=[r'\b(?:game|story)\b'],
  topic='salam',
  text="""
"As-salamu alaykum" means "peace be upon you". The reply is "Wa alaykumu s-salam" ("and upon you peace"), and Muslims often add "wa rahmatullahi wa barakatuh" ("and Allah's mercy and blessings"). It is the greeting of Muslims, and it is also a prayer for the other person.

The Qur'an commands: {Q 4:86|And when you are greeted with a greeting, greet [in return] with one better than it or [at least] return it [in a like manner]}. The Prophet ﷺ was asked what is best in Islam and said to feed people and to greet those you know and those you do not know ({H bukhari:12|Abdullah ibn Amr reported a man asked the Prophet which deeds of Islam are good, and he said to feed the poor and greet those whom you know and those whom you do not know}).
""",
  go=['/huda/guide?id=huda-greeting'],
  review='None beyond the cited texts.')

E('isra-miraj',
  m=[r'\bisra\b', r'\bmiraj\b', r'\bmi raj\b', r'\bnight journey\b', r'\bascension\b', r'\bburaq\b', r'\bsidrat\b', r'\blote tree\b', r'\bwhy (?:do )?(?:we|muslims?) pray (?:five|5) times\b', r'\bwhere (?:did|do) the (?:five|5) prayers come from\b', r'\bwhen (?:was|did) the (?:five|5) prayers? (?:made|become) (?:obligatory|fard)\b'],
  topic='isra',
  text="""
The Isra is the night journey in which Allah took the Prophet ﷺ from the Sacred Mosque in Makkah to the Aqsa Mosque in Jerusalem: {Q 17:1|Exalted is He who took His Servant by night from al-Masjid al-Haram to al-Masjid al-Aqsa, whose surroundings We have blessed, to show him of Our signs}. The Mi'raj is his ascension through the heavens to the Lote Tree of the Utmost Boundary, mentioned in {QR 53:13}-18.

The hadith adds details: he was carried on the Buraq, led the prophets in prayer in Jerusalem ({H muslim:162|Anas reported the Prophet said he was brought al-Buraq, mounted it and came to the Temple in Jerusalem, tethered it to the ring used by the prophets, entered the mosque and prayed two rak'ahs}), and he was ascended through the heavens. In the report in Bukhari, Allah first enjoined fifty daily prayers; on Musa's advice the Prophet ﷺ asked for a reduction until it became five, and Allah said these five are equal to fifty in reward ({H bukhari:349|Abu Dhar reported the Prophet described how Jibreel opened his chest and washed it with Zamzam, ascended with him through the heavens, and Allah enjoined fifty prayers, which were reduced to five, and Allah said they are equal to fifty in reward}).

This is why the five daily prayers are called a gift from the Mi'raj. Scholars differ on the exact date of the night, and the Prophet ﷺ did not set a day for celebrating it, so there is no authentic date to mark.
""",
  review='The date of the Isra and Mi\'raj is described as disputed; no authentic day is given. Flagged for scholar review.')

E('four-caliphs',
  m=[r'\b(?:four|4) (?:rightly guided )?caliphs?\b', r'\brightly guided caliphs?\b', r'\brashidun\b', r'\bkhulafa\b', r'\bkhulafa e rashideen\b', r'\bkhulafa ar rashidun\b', r'\bwho (?:was|were) the (?:first|second|third|fourth) caliphs?\b', r'\bwho (?:was|is) the first caliph\b', r'\bsucceeded the prophet\b', r'\bafter the prophet died\b', r'\bsuccessors? of the prophet\b'],
  topic='caliphs',
  text="""
The four Rightly Guided Caliphs (al-Khulafa ar-Rashidun) led the Muslim community after the Prophet ﷺ passed away in the year 11 AH (632 CE), in this order:
1. Abu Bakr as-Siddiq (11-13 AH), the Prophet's close companion in the cave of the Hijrah ({QR 9:40}).
2. Umar ibn al-Khattab (13-23 AH), who expanded the state and gathered the people behind one imam for Taraweeh.
3. Uthman ibn Affan (23-35 AH), under whom the Qur'an was copied into the standard written copies.
4. Ali ibn Abi Talib (35-40 AH), cousin and son-in-law of the Prophet ﷺ.

All four were among the ten the Prophet ﷺ gave glad tidings of Paradise ({H tirmidhi:3747|Abdur-Rahman ibn Awf narrated the Prophet said Abu Bakr is in Paradise, Umar is in Paradise, Uthman is in Paradise, Ali is in Paradise, Talhah, az-Zubayr, Abdur-Rahman ibn Awf, Sa'd ibn Abi Waqqas, Sa'id ibn Zayd and Abu Ubaidah ibn al-Jarrah are in Paradise}). Sunni Muslims count these four as the Rightly Guided Caliphs; Shia Muslims hold a different view on the question of leadership after the Prophet ﷺ (see the answer on Sunni and Shia). This app does not rank Muslim groups.
""",
  go=['/stories'],
  review='Dates of the caliphates and the standard-copy detail are from standard history, not text-checked here. Flagged for scholar review. The Sunni/Shia sentence is deliberately neutral.')

E('companions-sahabah',
  m=[r'\bcompanions? of the prophet\b', r'\bthe prophet s companions\b', r'\bsahabah?\b', r'\bsahabi\b', r'\bprophet s companions\b', r'\bwho (?:are|were) the (?:companions|sahabah)\b', r'\btell me about the (?:prophet s )?companions\b', r'\bthe ten promised paradise\b', r'\basharah mubashshar\w*\b', r'\bten companions\b'],
  topic='companions',
  text="""
A companion (sahabi) is a person who met the Prophet ﷺ, believed in him, and died as a Muslim. They learned Islam from him directly and passed it to us, and they are the best generation. Allah says: {Q 9:100|And the first forerunners [in the faith] among the Muhajireen and the Ansar and those who followed them with good conduct - Allah is pleased with them and they are pleased with Him}. The Prophet ﷺ said: {H bukhari:3651|Abdullah reported the Prophet said the best people are those living in my generation, and then those who will follow them, and then those who will follow the latter}.

Among them: the four Rightly Guided Caliphs (Abu Bakr, Umar, Uthman, Ali); the ten given glad tidings of Paradise ({H tirmidhi:3747|Abdur-Rahman ibn Awf narrated the Prophet said Abu Bakr is in Paradise, Umar is in Paradise, Uthman is in Paradise, Ali is in Paradise, Talhah, az-Zubayr, Abdur-Rahman ibn Awf, Sa'd ibn Abi Waqqas, Sa'id ibn Zayd and Abu Ubaidah ibn al-Jarrah are in Paradise}); the Prophet's wives and daughters; and many Muhajirun and Ansar. Their stories are in the Stories section of this app.
""",
  go=['/stories'],
  review='None beyond the cited texts.')

E('badr',
  m=[r'\bbadr\b', r'\bbattle of badr\b', r'\bghazwat? badr\b', r'\bday of the criterion\b', r'\bfurqan\b.*\bbattle\b'],
  topic='badr',
  text="""
Badr was the first major battle between the Muslims of Madinah and the Quraysh of Makkah, fought in Ramadan in the year 2 AH. The Muslims were few and poorly armed, the Makkan army about three times as many, and Allah gave the believers victory: {Q 3:123|And already had Allah given you victory at [the battle of] Badr while you were few in number}.

On the numbers, Umar reported: {H muslim:1763|Umar reported that on the day of Badr the Prophet cast a glance at the polytheists, who were one thousand, while his own companions were three hundred and nineteen, then turned towards the qiblah and made du'a to his Lord}. Al-Bara said that the Badr fighters were about three hundred and ten and some, like the companions of Talut ({H bukhari:3959|Al-Bara said they used to say that the warriors of Badr were over three hundred and ten, as many as the companions of Saul who crossed the river with him}). Allah reminded them that He sent help with the angels ({QR 8:9}) and that victory is only from Him ({QR 3:126}).

The Qur'an calls it the day of the Furqan (the Criterion), when truth was separated from falsehood. Those who fought at Badr are honoured among the companions.
""",
  review='The date (Ramadan, 2 AH) and the "about three times" figure are from standard history and not text-checked here; the numbers cited are from the two hadith above.')

E('karbala',
  m=[r'\bkarbala\b', r'\bkerbela\b', r'\bashura\b.*\b(?:husain|husayn|hussain|karbala)\b', r'\bhusayn\b', r'\bhusain\b', r'\bhussain\b', r'\bimam hussain\b', r'\bday of ashura\b'],
  x=[r'\b(?:fast|fasting|musa|moses|pharaoh)\b'],
  topic='karbala',
  text="""
Karbala is a place in Iraq where Husayn ibn Ali, the grandson of the Prophet ﷺ, was killed on 10 Muharram in the year 61 AH (680 CE), together with members of his family and companions, by the forces of the Umayyad caliph Yazid. Husayn and his brother Hasan are loved by Muslims of every school: {H tirmidhi:3768|Abu Sa'id narrated the Messenger of Allah said Al-Hasan and Al-Husayn are the chiefs of the youths of Paradise}.

Muslims of all backgrounds regard the killing of the Prophet's grandson as a great tragedy and a grave wrong. They differ in how it is remembered and in what it means politically; Shia communities mourn it publicly in Muharram, while Sunni communities generally remember it without formal mourning rites. This app does not take sides in those differences; for details, ask a scholar of the tradition you follow.

Note that 10 Muharram, Ashura, is also a day of fasting for all Muslims, for reasons that go back to the days of Musa; ask me about fasting on Ashura.
""",
  review='Karbala: date and basic facts are from standard history, not hadith-verifiable here; the description of how communities remember it is deliberately general. Flagged for scholar review.')

E('sunni-shia',
  m=[r'\bsunni\b', r'\bsunnis\b', r'\bshia\b', r'\bshi a\b', r'\bshiite\b', r'\bshi ite\b', r'\bsunni (?:and|vs|versus|or) shia\b', r'\bshia (?:and|vs|versus|or) sunni\b', r'\bdifference between sunni\b', r'\bwhich (?:sect|group) (?:is|are) (?:right|correct|true|better)\b', r'\bsects? (?:in|of) islam\b', r'\bwhy (?:are|do) (?:there|muslims) (?:so many )?(?:sects|divisions|groups)\b', r'\bmuslim sects\b', r'\bwhich is better\b.*\b(?:sunni|shia|school|madhhab)\b'],
  x=[r'\b(?:change|choose|school of law|my school|madhab|madhhab setting)\b.*\b(?:app|setting|settings|menu)\b'],
  topic='sects',
  text="""
Sunni and Shia Muslims share the core of Islam: they believe in one God, in Muhammad ﷺ as His final messenger ({QR 33:40}), in the Qur'an, the angels, the Last Day, and they pray towards the same Ka'bah, fast in Ramadan, give zakat, and perform Hajj.

The main historical difference is over who was entitled to lead the community after the Prophet ﷺ: Sunnis accept the leadership of Abu Bakr, Umar, Uthman and Ali in that order, while Shia hold that Ali and his descendants were the rightful leaders. From this follow differences in some hadith collections, in schools of law, and in some practices.

I cannot say which group is "better", and this app does not rank Muslims. Allah tells believers to hold together and not divide: {Q 3:103|And hold firmly to the rope of Allah all together and do not become divided}, and {Q 49:10|The believers are but brothers, so make settlement between your brothers}. For questions of belief and practice, ask a scholar of the tradition you follow.
""",
  review='The Sunni/Shia description is a neutral, minimal account; flagged for scholar review by both traditions if possible.')

E('surah-asr',
  m=[r'\bsurah? (?:al )?(?:asr|al asr|103)\b', r'\bchapter (?:al )?asr\b', r'\bsurat(?:ul)? ?(?:al )?asr\b', r'\bsurah by time\b', r'\bwal asr\b', r'\bwal-asr\b', r'\bmankind is in loss\b', r'\bqur an 103\b', r'\b103[: ]1\b'],
  topic='asr',
  text="""
Surah Al-Asr (103) is the shortest surah that sums up the way out of loss:

{Q 103:1-3|By time, Indeed, mankind is in loss, Except for those who have believed and done righteous deeds and advised each other to truth and advised each other to patience.}

It says that every person is at a loss unless four things come together: faith, righteous deeds, advising one another to the truth, and advising one another to patience. Time is the capital of life, and it passes either in gain or in loss. You can read and hear the surah in the Qur'an screen.
""",
  go=['/quran'],
  review='Verse text matches the bundled Saheeh International; the short gloss is a standard summary.')

E('ibrahim-sacrifice',
  m=[r'\bibrahim\b.*\b(?:sacrific\w*|son|ismail|ishmael|isaac|dream|knife)\b', r'\babraham\b.*\b(?:sacrific\w*|son|ishmael|isaac|dream|knife)\b', r'\bstory of (?:ibrahim|abraham)\b', r'\bwhy (?:do )?muslims? sacrifice\b', r'\b(?:sacrifice|qurbani|udhiyah)\b.*\b(?:ibrahim|abraham|eid)\b', r'\bwhat is (?:the )?(?:eid al adha|eid ul adha|bakra eid)\b', r'\bwhy (?:do )?(?:we|muslims?) celebrate eid al adha\b'],
  topic='ibrahim',
  text="""
The Qur'an tells that Ibrahim (Abraham) saw in a dream that he must sacrifice his son, and the son agreed: {Q 37:102|indeed I have seen in a dream that I [must] sacrifice you, so see what you think}. The son answered: {Q 37:102|do as you are commanded. You will find me, if Allah wills, of the steadfast}. When both had submitted, Allah called to him: {Q 37:105|You have fulfilled the vision}, and {Q 37:107|We ransomed him with a great sacrifice}, a ram in place of the son.

It was a trial of obedience and love, and shows that Allah does not want human life but obedience and sacrifice from the heart. The Qur'an does not name the son in these verses; the majority of scholars say it was Ismail, and some say Ishaq.

Eid al-Adha remembers this. Muslims who can afford it offer a sacrifice of an animal (udhiyah/qurbani) and share the meat with family and the poor, and pilgrims complete the rites of Hajj. The sacrifice is itself an act of worship, not a payment for sins.
""",
  review='Identity of the son is described as a difference among scholars; the udhiyah description is general.')

E('prophet-biography',
  m=[r'\bwho (?:was|is) (?:prophet )?(?:muhammad|mohammed|mohammad)\b', r'\btell me about (?:prophet |the prophet )?(?:muhammad|mohammed|mohammad)\b', r'\bbiography of (?:the )?(?:prophet|muhammad)\b', r'\blife of (?:the )?prophet\b', r'\bseerah\b.*\b(?:summary|overview|short|brief)\b', r'\bbrief (?:life|history) of (?:the )?prophet\b', r'\bwhen was (?:the )?prophet (?:muhammad )?(?:born|died)\b', r'\bhow old was (?:the )?prophet\b', r'\bwhere was (?:the )?prophet (?:born|buried)\b', r'\bwho is the prophet\b', r'\bwho was the prophet\b',
     r'\bwho (?:was|is) the last prophet\b', r'\bwho is the last prophet\b', r'\bwhat did the prophet (?:do|look like|eat)\b'],
  x=[r'\b(?:wives|wife|marriage|aisha|ayesha|khadijah|khadija|sahabah|companions)\b', r'\b(?:picture|image|draw|photo)\b'],
  topic='prophet',
  text="""
Muhammad ﷺ is the last Messenger of Allah ({Q 33:40|Muhammad is not the father of [any] one of your men, but [he is] the Messenger of Allah and last of the prophets}). In outline:
- He was born in Makkah, around 570 CE, in the tribe of Quraysh; he was orphaned young and was known among his people as the truthful and trustworthy (as-Sadiq al-Amin).
- At the age of forty he began to receive the revelation. {H bukhari:3902|Ibn Abbas said the Prophet started receiving the Divine Inspiration at the age of forty, stayed in Makkah for thirteen years, was ordered to migrate, lived as an emigrant for ten years and died at sixty-three}. It began in the cave of Hira, with the first words of Surah Al-Alaq ({QR 96:1}): "Recite in the name of your Lord who created". Bukhari describes the beginning in {H bukhari:3|Aisha said the revelation began with true dreams, then he loved seclusion and used to worship in the cave of Hira, and returned to Khadijah}.
- In Makkah he invited people to worship Allah alone, and many suffered for it. After the hardship at Ta'if, when the people there did not respond, the angel of the mountains offered to crush them and he refused, hoping that Allah would bring from them people who worship Him alone ({H bukhari:3231|Aisha asked the Prophet about the hardest day and he said it was the day at Aqaba when he went to Ibn Abd Yalil and he did not respond, and the angel of the mountains offered to let two mountains fall on them, and he said no, hoping Allah would bring from them those who worship Allah alone}).
- He migrated to Madinah (the Hijrah), built the first community there, and returned to Makkah in the conquest, a few years before his death.
- He died in Madinah at the age of sixty-three ({H muslim:2348|Anas reported the Messenger of Allah died when he was sixty-three years old, and so did Abu Bakr and Umar}). He left no wealth: {H bukhari:2916|Aisha said the Prophet died while his iron armor was mortgaged to a Jew for thirty sa of barley}.

Allah describes him as {Q 68:4|of a great moral character} and as {Q 21:107|a mercy to the worlds}. The Seerah section of the Academy has his life in detail. His image is never drawn in Islam, out of respect.
""",
  go=['/academy/seerah'],
  review='Birth year and his youthful reputation are from standard seerah, not text-checked here; the age, duration and death are from Bukhari 3902 and Muslim 2348; conquest of Makkah year is not given.')

E('quran-what',
  m=[r'\bwhat is (?:the )?(?:quran|qur an|koran)\b', r'\bwho wrote (?:the )?(?:quran|qur an|koran)\b', r'\bwhat is the holy book\b', r'\bwhat is islam s holy book\b', r'\bis the (?:quran|qur an|koran) (?:changed|preserved|authentic|real|original|corrupted)\b', r'\bhow many (?:surahs|chapters|suras)\b', r'\bhow (?:was|is) the (?:quran|qur an|koran) (?:revealed|compiled|preserved|collected)\b', r'\btell me about the (?:quran|qur an|koran)\b', r'\bwhen was the (?:quran|qur an|koran) revealed\b', r'\bquran (?:overview|introduction|summary)\b', r'\bwhy (?:is|was) the (?:quran|qur an) in arabic\b'],
  x=[r'\b(?:in this app|screen|bookmark|download|tafsir tab|reciter|audio)\b', r'\bvs\b', r'\bdifference between\b', r'\b(?:game|games|quiz|trivia|play)\b'],
  topic='quran',
  text="""
The Qur'an is the word of Allah, revealed to the Prophet Muhammad ﷺ through the angel Jibreel ({QR 2:97}), in Arabic, in stages over about twenty-three years (the thirteen years in Makkah and ten in Madinah of {H bukhari:3902|Ibn Abbas said the Prophet started receiving the Divine Inspiration at the age of forty, stayed in Makkah for thirteen years, was ordered to migrate, lived as an emigrant for ten years and died at sixty-three}). It began in the month of Ramadan: {Q 2:185|The month of Ramadhan [is that] in which was revealed the Qur'an, a guidance for the people}, on the Night of Decree ({QR 97:1}).

It has 114 chapters (surahs), from Al-Fatihah to An-Nas. It is a guidance for belief, worship, character and daily life, and it is the central miracle of Islam. Allah promised to guard it: {Q 15:9|Indeed, it is We who sent down the Qur'an and indeed, We will be its guardian}. It was memorised and written down during the Prophet's life, and Muslims have recited it by heart ever since, which is why the same text is read across the world.

Reading it, understanding it, and acting on it are all rewarded. You can read and hear it in the Qur'an screen of this app, and the Hifz planner helps you memorise it.
""",
  go=['/quran'],
  review='Number of surahs is the commonly agreed 114; the "twenty-three years" follows from the cited hadith (13 plus 10).')

E('hadith-what',
  m=[r'\bwhat is (?:a |the )?hadith\b', r'\bwhat are hadiths?\b', r'\bwhat are ahadith\b', r'\bwhat is (?:the )?sunnah\b', r'\bwhat is sunnah\b', r'\bhadith (?:grades?|grading|classification|authenticity)\b', r'\bsahih (?:vs|versus|and|or) (?:hasan|daif|weak)\b', r'\bwhat is (?:a )?(?:sahih|hasan|daif|da if|weak|fabricated|mawdu) hadith\b', r'\bwhat does sahih mean\b', r'\bhow (?:do|can) (?:i|we) know (?:if )?(?:a )?hadith is (?:authentic|sahih|real)\b', r'\bsix books of hadith\b', r'\bsihah sitta\b', r'\bkutub al sittah\b', r'\bmajor hadith collections\b', r'\bhadith collections?\b'],
  x=[r'\b(?:game|games|quiz|trivia|play)\b'],
  topic='hadith',
  text="""
A hadith is a report of what the Prophet ﷺ said, did, or approved. Together these reports are his sunnah, the second source of Islamic teaching after the Qur'an. Each report has a text and a chain of narrators (isnad) back to the Prophet ﷺ.

The scholars of hadith graded reports by the reliability of the chain and text:
- Sahih (authentic): sound chain and text.
- Hasan (good): slightly less strong, but still reliable.
- Da'if (weak): has a defect; not used as evidence for rulings, and may be mentioned only with its grade stated.
- Mawdu' (fabricated): invented; it must not be attributed to the Prophet ﷺ.

The six major collections are Sahih al-Bukhari, Sahih Muslim, Sunan Abu Dawud, Jami' at-Tirmidhi, Sunan an-Nasa'i and Sunan Ibn Majah. The first two are the most trusted, and a report found in both is called "agreed upon". The other four mix reports of different grades, so each report must be graded: this app shows the grade and the grader next to a hadith from those four. Look at the source card under an answer to see the collection, the number and the grade. For rulings, ask a qualified scholar.
""",
  go=['/hadith', '/sources'],
  review='Standard definitions; nothing cited from a specific report.')

E('quran-vs-hadith',
  m=[r'\b(?:difference|different|distinction) between (?:the )?(?:quran|qur an|koran) and (?:the )?hadiths?\b', r'\b(?:quran|qur an|koran) (?:vs|versus|or|and) hadiths?\b', r'\bhadiths?\b.*\b(?:vs|versus|or|and)\b.*\b(?:quran|qur an|koran)\b', r'\bwhy (?:do )?(?:we|muslims?) need (?:the )?(?:hadith|sunnah)\b', r'\bis (?:the )?hadith (?:needed|necessary|required|a source)\b', r'\bquran only\b', r'\bquranists?\b', r'\bcan we follow only the quran\b', r'\bis the hadith (?:the )?word of allah\b', r'\bis the sunnah (?:from|part of) the (?:quran|qur an)\b'],
  topic='hadith',
  text="""
The Qur'an is the word of Allah, revealed in Arabic words and preserved letter by letter. A hadith is a report of the words and actions of the Prophet ﷺ, passed on by narrators, and is graded for its reliability. Both are sources of guidance, and Muslims are told to take both.

The Qur'an itself says to follow the Messenger: {Q 59:7|And whatever the Messenger has given you - take; and what he has forbidden you - refrain from}, {Q 4:80|He who obeys the Messenger has obeyed Allah}, and that he is there to explain it: {Q 16:44|And We revealed to you the message that you may make clear to the people what was sent down to them}. The details of prayer, zakat and Hajj, for example, are known mainly through his practice.

The Prophet ﷺ also warned against dropping this: {H abudawud:4604|Al-Miqdam ibn Ma'dikarib narrated the Prophet said I have been given the Qur'an and something like it, yet the time is coming when a man replete on his couch will say keep to the Qur'an, what you find in it permissible treat as permissible, and what you find prohibited treat as prohibited}.

Because hadiths vary in strength, always check the grade; a weak or invented report is not evidence. Use the source card in this app.
""",
  review='None beyond the cited texts.')

E('kaaba',
  m=[r'\bkaaba\b', r'\bka aba\b', r'\bkabah\b', r'\bka bah\b', r'\bkaba\b', r'\bthe cube\b', r'\bblack stone\b', r'\bhajar al aswad\b', r'\bwhy (?:do )?muslims? (?:face|pray towards) (?:the )?(?:kaaba|mecca|makkah)\b', r'\bwho built the (?:kaaba|ka aba)\b', r'\bdo muslims worship the (?:kaaba|black stone)\b', r'\bwhy (?:do )?muslims? go to (?:mecca|makkah)\b'],
  x=[r'\b(?:tawaf|circumambulat\w*|umrah|hajj|ihram)\b.*\b(?:how|steps|do)\b', r'\b(?:direction|find|compass|app)\b'],
  topic='kaaba',
  text="""
The Ka'bah is the cube-shaped House of Allah in the middle of the Sacred Mosque in Makkah. It is the direction (qiblah) that Muslims face in prayer: {Q 2:144|So turn your face toward al-Masjid al-Haram. And wherever you [believers] are, turn your faces toward it [in prayer]}.

Allah says it was the first house of worship for mankind: {Q 3:96|Indeed, the first House [of worship] established for mankind was that at Makkah - blessed and a guidance for the worlds}. It was raised by Ibrahim and his son Ismail: {Q 2:127|And [mention] when Abraham was raising the foundations of the House and [with him] Ishmael}. Pilgrims circle it in the rite of tawaf during Hajj and Umrah, and Hajj to it is a duty for those who are able ({QR 3:97}).

Muslims do not worship the Ka'bah or the Black Stone set in its corner; they worship Allah alone. The Ka'bah is a sign of unity: all Muslims in the world pray in its direction. The Qibla screen in this app shows the direction from where you are.
""",
  go=['/qibla'],
  review='None beyond the cited texts; the Black Stone note is a general statement of belief.')

E('who-is-allah',
  m=[r'\bwho is (?:allah|god)\b', r'\bwhat is allah\b', r'\bwho is the god of (?:islam|muslims)\b', r'\bwho do muslims worship\b', r'\bis allah (?:a different god|god|the same as god)\b', r'\bwhat do muslims believe about (?:allah|god)\b', r'\bdescribe allah\b', r'\bwhat is tawheed\b', r'\bwhat is tawhid\b', r'\bwhat is shirk\b', r'\bwhat does allah mean\b', r'\bwhere is allah\b', r'\bdoes allah exist\b', r'\bprove (?:that )?(?:allah|god)\b', r'\bhow many gods\b', r'\bis there only one god\b', r'\bis allah real\b'],
  x=[r'\b(?:99|ninety nine|names game|names of allah game|game)\b'],
  topic='allah',
  text="""
Allah is the Arabic name of the One God, Creator and Lord of everything, the same God worshipped by Ibrahim, Musa and Isa. The Qur'an gives the simplest description in Surah Al-Ikhlas: {Q 112:1|He is Allah, [who is] One}, {Q 112:2|Allah, the Eternal Refuge}, {Q 112:3|He neither begets nor is born}, {Q 112:4|Nor is there to Him any equivalent}.

Some of what He tells us about Himself:
- {Q 42:11|There is nothing like unto Him, and He is the Hearing, the Seeing}: nothing in creation resembles Him.
- {Q 59:22|He is Allah, other than whom there is no deity, Knower of the unseen and the witnessed. He is the Entirely Merciful, the Especially Merciful}.
- {Q 2:255|Allah - there is no deity except Him, the Ever-Living, the Sustainer of [all] existence. Neither drowsiness overtakes Him nor sleep.}

This oneness (tawhid) is the heart of Islam. Worshipping anything with Him is shirk: {Q 4:48|Allah does not forgive association with Him, but He forgives what is less than that for whom He wills}. Muslims know Him through His Names; the 99 Names game and screen in this app teach them.
""",
  go=['/games/names99'],
  review='The "same God as Ibrahim, Musa and Isa" line is a standard theological statement, not text-checked here.')

E('angels-jibreel',
  m=[r'\bjibreel\b', r'\bjibril\b', r'\bgabriel\b', r'\bmikail\b', r'\bmichael\b.*\b(?:angel|islam)\b', r'\bwho (?:are|were) (?:the )?angels\b', r'\bwhat are angels\b', r'\bangels? (?:in|of) islam\b', r'\bwhat do muslims believe about angels\b', r'\bare angels (?:male|female|real)\b', r'\bwhat are angels made of\b', r'\bwho is the angel of death\b', r'\bmalik al mawt\b', r'\bazrail\b', r'\bazrael\b', r'\bisrafil\b', r'\bkiraman katibin\b', r'\bguardian angels?\b', r'\brecording angels?\b', r'\bwho are munkar\b', r'\bangels?\b'],
  x=[r'\b(?:game|story|stories|angel investor)\b'],
  topic='angels',
  text="""
Angels are creatures of Allah, made from light, who obey Him and do what they are told: {Q 66:6|angels, harsh and severe; they do not disobey Allah in what He commands them but do what they are commanded}. The Prophet ﷺ said: {H muslim:2996|A'isha reported the Prophet said the angels were created from light, the jinn from the spark of fire, and Adam from what has been described to you}. They are not male or female, and not partners with Allah.

Jibreel (Gabriel) is the angel of revelation who brought the Qur'an to the Prophet ﷺ: {Q 2:97|Whoever is an enemy to Gabriel - it is [none but] he who has brought the Qur'an down upon your heart}. He also came in the form of a man to teach the Companions their religion, asking about Islam, iman and ihsan ({H muslim:8|The Prophet said that iman is to affirm your faith in Allah, in His angels, in His Books, in His Messengers, in the Day of Judgment, and to affirm your faith in the divine decree about good and evil}). Mikail (Michael) is named in {QR 2:98}.

Other angels do other tasks: recording deeds, protecting, taking souls, and guarding Paradise and the Fire. The Qur'an and hadith do not give details of every one, so the guidance is to believe in what is told and not to guess beyond it. Belief in the angels is the second article of iman.
""",
  review='The tasks of angels are described generally; only the cited texts are claimed. Names not in the Qur\'an or the cited hadith (such as Israfil and Azrail) are not asserted.')

E('afterlife-death',
  m=[r'\bwhat happens (?:after|when) (?:you |we |a person |someone )?(?:die|death|dying)\b', r'\bafter death\b', r'\bafterlife\b', r'\bthe hereafter\b', r'\bwhat is barzakh\b', r'\bbarzakh\b', r'\bgrave\b.*\b(?:torment|questioning|punishment|life)\b', r'\bday of judg(?:e)?ment\b', r'\bjudgment day\b', r'\bresurrection\b', r'\bhow do muslims believe (?:about|in) death\b', r'\bakhirah\b', r'\bakhira\b', r'\bwhat is paradise\b', r'\bwhat is jannah\b', r'\bwhat is hell\b', r'\bwhat is jahannam\b', r'\bwhat is the day of resurrection\b', r'\bis there life after death\b', r'\bheaven and hell\b', r'\bwill i go to (?:heaven|hell|paradise|jannah|jahannam)\b', r'\bscales\b.*\b(?:deeds|judg\w*|mizan)\b', r'\bmizan\b', r'\bsirat\b'],
  x=[r'\b(?:my|his|her|our) (?:father|mother|dad|mom|son|daughter|husband|wife|brother|sister|friend|grandfather|grandmother) (?:died|passed|is dead|has died)\b', r'\bfuneral\b'],
  topic='afterlife',
  text="""
Muslims believe that death is not the end but the move to the next stage. Here is what the Qur'an and hadith tell us.

- Death: the soul is taken, and the person enters the barzakh, a barrier between this life and the Day of Resurrection. The Qur'an says of those who wish to return: {Q 23:100|No! It is only a word he is saying; and behind them is a barrier until the Day they are resurrected}.
- Resurrection: all people will be raised, and each will be reckoned. {Q 21:47|And We place the scales of justice for the Day of Resurrection, so no soul will be treated unjustly at all. And if there is [even] the weight of a mustard seed, We will bring it forth.}
- Accountability: {Q 99:7-8|So whoever does an atom's weight of good will see it, And whoever does an atom's weight of evil will see it.}
- Then Paradise (Jannah) for the believers and the Fire (Jahannam) for those who reject and do wrong, subject to Allah's mercy and justice. Belief in the Last Day is the fifth article of iman ({H muslim:8|The Prophet said that iman is to affirm your faith in Allah, in His angels, in His Books, in His Messengers, in the Day of Judgment, and to affirm your faith in the divine decree about good and evil}).

Details such as the questioning in the grave and the bridge are reported in authentic hadith but are matters of the unseen, so we believe in what is told and do not argue about how. Allah is the Most Merciful: {Q 39:53|do not despair of the mercy of Allah}.
""",
  go=['/academy/aqeedah'],
  review='The grave and the bridge are mentioned but not cited; anything beyond the cited verses is general.')

E('mahdi',
  m=[r'\bmahdi\b', r'\bal mahdi\b', r'\bimam mahdi\b', r'\bthe expected one\b', r'\bwho is the mahdi\b', r'\bwill the mahdi come\b'],
  topic='mahdi',
  text="""
The Mahdi ("the guided one") is a man from the Prophet's family who, according to reports, will appear near the end of time and fill the earth with justice. The reports are in Abu Dawud: {H abudawud:4283|Ali ibn Abi Talib narrated the Prophet said if only one day of this time remained, Allah would raise up a man from my family who would fill this earth with justice as it has been filled with oppression}.

Please note:
- The reports come with different details (name, signs, timing). Scholars differ on how strong they are, and some doubt them. Sunni and Shia traditions also describe him differently.
- Belief in the Mahdi is not one of the six articles of faith. A Muslim is not asked to look for him.
- Be careful of anyone who claims to be the Mahdi, or says the signs have appeared. Many such claims have misled people. The Prophet ﷺ spoke of Isa ibn Maryam too, who will return as a just ruler ({H bukhari:3448|Abu Huraira reported the Prophet said, by Him in whose hands is my soul, the son of Mary will soon descend among you and judge mankind justly}).
""",
  review='Mahdi reports: the contested strength is stated without a ruling; flagged for scholar review.')

E('china-knowledge',
  m=[r'\bseek knowledge (?:even )?(?:as far as|even in|even unto|to) china\b', r'\bknowledge (?:even )?(?:in|as far as|to) china\b', r'\bchina\b.*\b(?:knowledge|hadith)\b', r'\b(?:knowledge|hadith)\b.*\bchina\b', r'\bseek(?:ing)? knowledge\b.*\b(?:hadith|authentic|sahih|obligatory|duty)\b', r'\bis seeking knowledge (?:obligatory|a duty|an obligation|fard|compulsory)\b', r'^seeking knowledge$', r'\bislam and (?:education|knowledge)\b', r'\bimportance of (?:knowledge|education)\b'],
  topic='knowledge',
  text="""
No: "Seek knowledge even in China" is not an authentic hadith. It is not found in Bukhari, Muslim or the other major collections, and hadith scholars treat it as weak or invented, so it should not be attributed to the Prophet ﷺ. It is often quoted for the real point that knowledge is worth travelling for.

What is established is that Islam values knowledge highly. Allah says: {Q 39:9|Are those who know equal to those who do not know}, and told the Prophet ﷺ to ask {Q 20:114|My Lord, increase me in knowledge}. A related saying in Ibn Majah, "Seeking knowledge is a duty upon every Muslim", is widely quoted: {HW ibnmajah:224|Anas ibn Malik narrated the Prophet said seeking knowledge is a duty upon every Muslim}. It is graded weak by hadith scholars, so it is not used as evidence, though scholars agree on the point that learning the religion one needs (how to pray, fast and live) is a duty.

The Seeking Knowledge guide in this app has authentic texts on the subject.
""",
  go=['/huda/guide?id=huda-knowledge'],
  review='The statement that the China saying is weak/invented is the near-unanimous view of hadith scholars but is not text-checked here (it is not in the hadith corpus used). The Ibn Majah report is cited as weak with its grader.')

E('allah-loves-me',
  m=[r'\bdoes allah (?:love|care about|hear|see|know|forgive|remember|accept) me\b', r'\bwill allah (?:love|forgive|accept|hear|help|punish|ever forgive) me\b', r'\bis allah (?:angry|upset|mad|disappointed|punishing|testing) (?:with|at) me\b', r'\bis allah (?:punishing|testing) me\b', r'\bdoes allah hate me\b', r'\ballah (?:hates|abandoned|forgot|left|ignores|ignored) me\b', r'\bwill allah ever forgive\b', r'\bdoes allah forgive (?:all|every|big|major|everything)\b', r'\bis there hope for me\b', r'\bi feel (?:far|distant) from allah\b', r'\bi feel allah (?:doesn t|does not|isn t) \w+\b', r'\bcan allah forgive\b', r'\bi (?:committed|did) (?:a )?(?:big|major|terrible|huge|bad) sin\b', r'\bi m a (?:bad|terrible|sinful) muslim\b'],
  gate=True,
  topic='mercy',
  text="""
Yes. Allah is far more loving and merciful than we imagine, and He wants you to come back to Him.

He describes Himself as {Q 85:14|the Forgiving, the Affectionate}, and says {Q 7:156|My mercy encompasses all things}. The Prophet ﷺ once saw a mother who found her child among the captives and held him to her chest, and asked his companions if they thought she would throw her child in the fire. They said no, and he said: {H bukhari:5999|The Prophet said Allah is more merciful to His slaves than this lady is to her son}.

If you have sinned, even greatly, the door is open: {Q 39:53|do not despair of the mercy of Allah}. Repentance (tawbah) is to stop the sin, feel regret, ask Allah to forgive you, resolve not to return, and, if you wronged a person, put the wrong right. Allah loves this: {Q 2:222|Indeed, Allah loves those who are constantly repentant and loves those who purify themselves}. Start by praying, making du'a in your own words, and doing a small good deed today. If you are feeling lost, hopeless or in pain, please also talk with someone you trust.
""",
  go=['/huda/guide?id=huda-tawba'],
  review='None beyond the cited texts.')

E('jihad-peace',
  m=[r'\bis islam (?:a )?(?:religion of )?(?:peace|violent|violence|peaceful|terroris\w*)\b', r'\bdoes islam (?:promote|teach|allow|encourage|support|permit) (?:violence|terroris\w*|killing|war|murder)\b', r'\bwhat is jihad\b', r'\bmeaning of jihad\b', r'\bjihad\b', r'\bterroris\w*\b.*\b(?:islam|muslims?)\b', r'\b(?:islam|muslims?)\b.*\bterroris\w*\b', r'\bislam and (?:violence|terror\w*|war)\b', r'\bkill(?:ing)? (?:non muslims?|infidels?|kafirs?|innocent)\b', r'^peace$', r'\bwhat does islam say about (?:violence|war|killing|peace)\b', r'\bis it (?:halal|allowed|permissible) to kill\b', r'\bsword verse\b', r'\bfight (?:the )?(?:infidels?|disbelievers|non muslims?)\b'],
  topic='peace',
  text="""
Islam's teaching is to protect life and to be just to everyone. The Qur'an says that killing an innocent person is like killing all of mankind: {Q 5:32|whoever kills a soul unless for a soul or for corruption [done] in the land - it is as if he had slain mankind entirely. And whoever saves one - it is as if he had saved mankind entirely}. Terror against civilians is a major sin and has no place in Islam, whoever does it and in whatever name.

Jihad means "striving". The greater part of it is the struggle against one's own desires and for good conduct. Fighting is permitted only in limited cases of defence against wrongs, with firm limits: {Q 2:190|Fight in the way of Allah those who fight you but do not transgress. Indeed. Allah does not like transgressors}, {Q 22:39|Permission [to fight] has been given to those who are being fought, because they were wronged}. The Prophet ﷺ forbade the killing of women and children ({H bukhari:3015|Ibn Umar reported that in some of the Prophet's battles a woman was found killed, so the Messenger of Allah forbade the killing of women and children}), and warned against harming people under a treaty ({H bukhari:3166|Abdullah ibn Amr reported the Prophet said whoever killed a person having a treaty with the Muslims shall not smell the smell of Paradise}).

Kindness to people of other faiths who do not fight you is commanded: {Q 60:8|Allah does not forbid you from those who do not fight you because of religion and do not expel you from your homes - from being righteous toward them and acting justly toward them}, and {Q 2:256|There shall be no compulsion in [acceptance of] the religion}. Whether any particular war is lawful is a question for qualified scholars, not for individuals or groups.
""",
  review='Fighting only for defence is stated per the cited verses; the classical fiqh of jihad includes further discussion that is not summarised here. Flagged for scholar review.')

E('other-religions',
  m=[r'\bis (?:christianity|judaism|hinduism|buddhism|sikhism|atheism|catholicism|christian\w*) (?:true|right|correct|the truth|false|wrong|the true religion)\b', r'\b(?:do|did) you think (?:that )?(?:christianity|judaism|hinduism|buddhism|atheism|islam|christians|jews) (?:is|are) (?:true|right|correct)\b', r'\bwhich (?:religion|faith) is (?:true|right|correct|the truth|the best|better)\b', r'\bis islam (?:the )?(?:only )?(?:true|right|correct|best|only) (?:religion|way|faith)\b', r'\bis islam (?:the )?(?:only|one) (?:way|path|religion)\b',
     r'\bwhy (?:islam|is islam|should i choose islam|choose islam|be a muslim)\b', r'\bwhat does islam say about (?:christians?|jews?|hindus?|buddhists?|atheists?|other religions|non muslims?|people of other faiths)\b', r'\bwill (?:non muslims?|christians?|jews?|hindus?|atheists?|people of other (?:faiths?|religions?)) go to (?:hell|heaven|paradise|jahannam|jannah)\b', r'\bdo (?:muslims|you) respect (?:other religions|christians|jews)\b', r'\bis jesus (?:god|the son of god|divine)\b', r'\btrinity\b', r'\bwhat do muslims (?:believe|think) about (?:jesus|isa|christ)\b', r'\bdid jesus die on the cross\b', r'\bcrucifix\w*\b', r'\bwhat is the difference between islam and christianity\b', r'\bislam (?:vs|versus|and) christianity\b'],
  topic='religions',
  text="""
I answer from Islam, so I can tell you what Muslims believe, and I will not mock or attack anyone's faith.

Muslims believe that Allah sent messengers to every people with one message, to worship Him alone, and that Muhammad ﷺ is the last of them. So Muslims say that the religion with Allah is Islam, meaning submission to Him ({Q 3:19|Indeed, the religion in the sight of Allah is Islam}), the way of Ibrahim: {Q 3:67|Abraham was neither a Jew nor a Christian, but he was one inclining toward truth, a Muslim [submitting to Allah]}.

On Jesus (Isa): Muslims honour him as one of the greatest messengers, born miraculously to Maryam, and a word from Allah. The Qur'an says: {Q 4:171|The Messiah, Jesus, the son of Mary, was but a messenger of Allah and His word which He directed to Mary and a soul [created at a command] from Him}, and teaches that he is not God or the son of God, and rejects the Trinity, and says that to claim Allah is the third of three is disbelief: {Q 5:73|And there is no god except one God}. The Qur'an also compares his creation to that of Adam ({QR 3:59}). So Muslims and Christians agree on his honour and miracles, and differ on who he is.

How Muslims are told to treat others: {Q 2:256|There shall be no compulsion in [acceptance of] the religion}, {Q 29:46|do not argue with the People of the Scripture except in a way that is best}, and in the last words of Surah Al-Kafirun: {Q 109:6|For you is your religion, and for me is my religion}. Whom Allah admits to Paradise is for Him to judge; a Muslim's duty is to invite with kindness and wisdom and to be just to everyone.
""",
  review='Statements on Christian belief are limited to what the Qur\'an says and what Muslims therefore believe; the final judgment on individuals is left to Allah. Flagged for scholar review.')
