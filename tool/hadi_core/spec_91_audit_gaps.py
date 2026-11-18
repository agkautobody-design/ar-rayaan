# Answers added after the 18 Nov 2026 audit, for questions the built-in library
# used to refuse (docs/hadi_coverage.md). Qur'an words and hadith numbers are
# checked by build.py; every hadith here also has an ok verdict in
# tool/hadith_verdicts. Each answer says what is established and what is
# a difference of opinion, and none gives a ruling on a person's own case.

E('surah-longest',
  m=[r'\blongest (?:surah|chapter|sura)\b', r'\b(?:which|what) (?:surah|chapter|sura) is the longest\b', r'\bbiggest (?:surah|chapter)\b'],
  topic='longest surah',
  go=['/quran'],
  text="""
The longest surah is Al-Baqarah (surah 2), with 286 verses. The longest single verse in the Qur'an is also in it: the verse about writing down debts ({QR 2:282}).
""",
  review='Counts from the bundled Qur\'an text; no reviewer needed beyond a spot check.')

E('surah-shortest',
  m=[r'\bshortest (?:surah|chapter|sura)\b', r'\b(?:which|what) (?:surah|chapter|sura) is the shortest\b', r'\bsmallest (?:surah|chapter)\b'],
  topic='shortest surah',
  go=['/quran'],
  text="""
The shortest surah is Al-Kawthar (surah 108), with three verses ({QR 108:1}). Surahs 103 (Al-Asr) and 110 (An-Nasr) are also three verses but longer in words.
""",
  review='Counts from the bundled Qur\'an text.')

E('revelation-first',
  m=[r'\bfirst (?:revelation|ayah|verse|verses|surah)\b', r'\bwhat (?:was|is) (?:first )?revealed first\b', r'\bfirst thing (?:revealed|that was revealed)\b',
     r'\bhow did (?:the )?(?:prophets?|muhammads?) (?:revelation|wahy) begin\b', r'\bbeginning of (?:the )?(?:revelation|wahy)\b',
     r'\bcave of hira\b', r'\bghar e? ?hira\b', r'\bhira cave\b', r'\bwhat happened (?:at|in) (?:the )?cave\b'],
  topic='first revelation',
  go=['/academy/seerah', '/quran'],
  text="""
The first verses revealed were the opening of Surah Al-Alaq: {Q 96:1|Recite in the name of your Lord who created}.

Aisha described how it began ({H bukhari:3|Aisha said the revelation began with true dreams, then he loved seclusion and used to worship in the cave of Hira, and returned to Khadijah}). In that report the angel came and said Read, he answered that he was not a reader, the angel pressed him three times and then recited the first verses of Al-Alaq, and he went home trembling to Khadijah, who comforted him and took him to Waraqa ibn Nawfal.

The report says that Khadijah reassured him that Allah would never disgrace him, because he kept family ties, spoke the truth, helped the weak and honoured guests. Tradition places this in the month of Ramadan, when he was about forty.
""",
  review='The Bukhari report is checked; the month and the age are the usual dates given by the seerah books and were not checked here.')

E('taqwa',
  m=[r'\bwhat (?:is|does) taqwa\b', r'\bmeaning of taqwa\b', r'\btaqwa meaning\b', r'\bwhat is piety\b', r'\btaqwah\b'],
  topic='taqwa',
  go=['/academy/aqeedah'],
  text="""
Taqwa is being conscious of Allah in a way that makes you guard yourself against what displeases Him and hold on to what pleases Him. It is often translated as God-consciousness, piety or fear of Allah, and it sits in the heart but shows in what a person does.

The Qur'an makes it the measure of worth in Allah's eyes: {Q 49:13|Indeed, the most noble of you in the sight of Allah is the most righteous of you}. It is also what the fast is meant to build: {QR 2:183}.
""",
  review='Definition as commonly given by the classical commentators; wording is the app\'s own.')

E('inshallah-meaning',
  m=[r'\b(?:meaning|mean|means) (?:of )?in ?sha{1,2} ?a?llah\b', r'\bwhat (?:is|does) (?:the )?(?:meaning of )?in ?sha{1,2} ?a?llah\b', r'\binshaa?llah (?:meaning|mean)\b', r'\bwhat does in sha allah mean\b'],
  x=[r'\b(?:ruling|halal|haram)\b'],
  topic='inshaAllah',
  text="""
In shaa Allah means "if Allah wills". It is said when speaking about the future, because every plan depends on His will. The Qur'an teaches it: never say you will certainly do something tomorrow ({QR 18:23}) without adding "if Allah wills" ({QR 18:24}).

It is meant as humility and trust, not as a polite way of avoiding a promise. A promise made with the intention of keeping it is still a promise.
""",
  review='Standard meaning and the verse that teaches it.')

E('mashallah-meaning',
  m=[r'\b(?:meaning|mean|means) (?:of )?ma ?sha{1,2} ?a?llah\b', r'\bwhat (?:is|does) (?:the )?(?:meaning of )?ma ?sha{1,2} ?a?llah\b', r'\bmashaa?llah (?:meaning|mean)\b'],
  topic='maashaa Allah',
  text="""
Maa shaa Allah means "what Allah has willed (has come to be)". Muslims say it when they admire something, to remember that the good came from Allah. The Qur'an gives the phrase in the story of the two gardens: {Q 18:39|What Allah willed [has occurred]; there is no power except in Allah}.

Many scholars also teach saying it, with a blessing, when you see something that pleases you, so that admiration does not turn into envy. That practical use is a scholarly view, not a verse.
""",
  review='Meaning and verse checked; the evil-eye use is a scholarly view and is labelled as one.')

E('astaghfirullah-meaning',
  m=[r'\b(?:meaning|mean|means) (?:of )?astaghfirullah\b', r'\bwhat (?:is|does) (?:the )?(?:meaning of )?astaghfirullah\b', r'\bastaghfirullah (?:meaning|mean)\b', r'\bwhat does astaghfir\w* mean\b'],
  topic='astaghfirullah',
  text="""
Astaghfirullah means "I ask Allah for forgiveness". It is the plain words of istighfar, and it is said after a sin, after a mistake, and as a regular habit. Nuh said to his people: {Q 71:10|Ask forgiveness of your Lord}.

Even the Prophet ﷺ did it constantly ({H bukhari:6307|Abu Hurayrah reported the Prophet said that he asked Allah's forgiveness and turned to Him in repentance more than seventy times every day}).
""",
  review='Meaning and the two sources checked.')

E('juz-hizb',
  m=[r'\bwhat is (?:a |an |the )?(?:juz|jus|para|siparah|sipara)\b', r'\bwhat is (?:a |an |the )?(?:hizb|rub|manzil)\b', r'\bjuz meaning\b', r'\bhow many (?:juz|paras?|hizb)\b', r'\bwhat is a hizb\b'],
  topic='juz and hizb',
  go=['/quran'],
  text="""
A juz (also called para in South Asia) is one of thirty roughly equal parts of the Qur'an, made so that it can be read in a month, one a day. The parts do not follow surah boundaries.

A hizb is half a juz, so there are sixty hizb. Each hizb is split again into four quarters, which are marked in many printed copies. These divisions are for reading and memorising, and are not part of the revealed text.
""",
  review='Reading divisions as used in the common printed mushaf.')

E('tafsir-meaning',
  m=[r'\bwhat is (?:a )?tafs?[ei]r\b', r'\btafs?[ei]r (?:meaning|mean)\b', r'\bmeaning of tafs?[ei]r\b', r'\bwhat is quran(?:ic)? (?:exegesis|commentary)\b'],
  topic='tafsir',
  go=['/quran'],
  text="""
Tafsir is the explanation of the Qur'an: the meaning of its words, the reasons for revelation and what its rulings and lessons are. The Qur'an says the Prophet's task included this: {Q 16:44|that you may make clear to the people what was sent down to them}.

Scholars explain the Qur'an first by the Qur'an, then by the Prophet's own words, then by the Companions and the early scholars, and by the Arabic language. Well-known works include those of at-Tabari, Ibn Kathir and al-Qurtubi. A translation is not a tafsir, which is why a verse is better understood with a reliable commentary and a qualified teacher.
""",
  review='General description; works named are widely used classical tafsirs.')

E('imam-muslim',
  m=[r'\bwho (?:is|was) imam muslim\b', r'\bwho (?:is|was) muslim ibn al ?hajjaj\b', r'\babout imam muslim\b', r'\bsahih muslim author\b', r'\bwho (?:wrote|compiled) sahih muslim\b'],
  topic='Imam Muslim',
  go=['/hadith'],
  text="""
Imam Muslim ibn al-Hajjaj an-Naysaburi (died 261 AH, 875 CE) compiled Sahih Muslim, one of the two most trusted hadith collections together with Sahih al-Bukhari. He was a student of al-Bukhari and of many other scholars, and he set strict conditions for what went into his book.

In the hadith sciences the "two Sahihs" are the first of the six main collections (the Kutub as-Sittah), alongside Abu Dawud, at-Tirmidhi, an-Nasa'i and Ibn Majah.
""",
  review='Dates and standing as given in standard biographical works; not checked in the original sources here.')

E('bilal',
  m=[r'\bwho (?:is|was) bilal\b', r'\babout bilal\b', r'\bbilal ibn rabah\b', r'\bbilal ibn rabaah\b', r'\bfirst muadhdhin\b', r'\bfirst muezzin\b'],
  topic='Bilal ibn Rabah',
  go=['/academy/seerah'],
  text="""
Bilal ibn Rabah, a Companion born in Makkah to an Abyssinian family, was enslaved when he accepted Islam and was tortured for refusing to give it up. Abu Bakr bought and freed him. The Prophet ﷺ made him the first muadhdhin, the one who gives the call to prayer.

His standing is shown in a report from Abu Hurayrah ({H bukhari:1149|the Prophet asked Bilal after the Fajr prayer what his best deed since Islam was, because he had heard the sound of his footsteps in front of him in Paradise, and Bilal said he always prayed after making wudu}).
""",
  review='The Bukhari report is checked; his birth, his torture and his purchase by Abu Bakr are the usual seerah account and are labelled Seerah report (source not checked).')

E('hamza',
  m=[r'\bwho (?:is|was) hamz[ae]h?\b', r'\babout hamz[ae]h?\b', r'\bhamz[ae]h? ibn abdul? ?muttalib\b', r'\blion of allah\b'],
  topic='Hamza ibn Abd al-Muttalib',
  go=['/academy/seerah'],
  text="""
Hamza ibn Abd al-Muttalib was the Prophet's ﷺ uncle and also his foster-brother and close companion. He accepted Islam in Makkah and was known for his courage, and was called the Lion of Allah. He was killed as a martyr at the Battle of Uhud in the third year after the Hijrah, and the Prophet ﷺ grieved deeply for him.
""",
  review='Seerah report (source not checked): the usual account from the early biographies, with no hadith number given.')

E('battle-uhud',
  m=[r'\bwhat happened (?:at|in|during) (?:the )?(?:battle of )?uhud\b', r'\bbattle of uhud\b', r'\btell me about uhud\b', r'\bwhat is uhud\b', r'\bwhy did (?:the )?muslims lose (?:at )?uhud\b'],
  topic='Battle of Uhud',
  go=['/academy/seerah'],
  text="""
Uhud was fought near Madinah in the third year after the Hijrah, after the Muslims had won at Badr and Quraysh came back to take revenge. Early on the Muslims were winning, but some of the archers the Prophet ﷺ had placed on the hill left their post, thinking the battle was won. The enemy cavalry attacked from behind, many Muslims were killed, among them Hamza, and the Prophet ﷺ himself was wounded.

The Qur'an speaks of it and its lessons, including that the losses were a test and a cause for repentance and for steadiness: {QR 3:152}, {QR 3:155}.
""",
  review='Seerah report (source not checked): the outline is the common account; no hadith number is given.')

E('battle-trench',
  m=[r'\bwhat happened (?:at|in|during) (?:the )?(?:battle of )?(?:the )?(?:trench|khandaq|ahzab)\b', r'\bbattle of (?:the )?(?:trench|khandaq|ahzab)\b', r'\btell me about (?:the )?(?:trench|khandaq|ahzab)\b'],
  topic='Battle of the Trench',
  go=['/academy/seerah'],
  text="""
The Battle of the Trench (also called al-Ahzab, "the confederates") took place at Madinah in the fifth year after the Hijrah, when several tribes joined against the Muslims. On the advice of the Companion Salman al-Farisi they dug a trench across the open side of the city, which stopped the enemy's cavalry. After about a month of siege and a bitter storm the confederates withdrew.

The Qur'an recalls it: {Q 33:9|remember the favor of Allah upon you when armies came to [attack] you and We sent upon them a wind and armies [of angels] you did not see}.
""",
  review='The verse is checked; the dates and Salman\'s advice are the usual seerah account (Seerah report, source not checked).')

E('prophet-death',
  m=[r'\bhow did (?:the )?(?:prophet|muhammad|messenger)s? ?(?:muhammad )?(?:die|pass away|death)\b', r'\bdeath of (?:the )?(?:prophet|muhammad)\b', r'\bwhen did (?:the )?prophet (?:die|pass away)\b', r'\bhow did (?:the )?prophet die\b'],
  topic='death of the Prophet',
  go=['/academy/seerah'],
  text="""
The Prophet ﷺ died in Madinah in the eleventh year after the Hijrah, after a short illness, in the house of Aisha. She described it: {H bukhari:4449|Aisha said that Allah's Messenger died in her house on the day of her turn, leaning against her chest}.

The Qur'an had told him that this would come to everyone: {Q 39:30|Indeed, you are to die, and indeed, they are to die}. During his illness Abu Bakr was asked to lead the prayers; after his death Abu Bakr told the Muslims that whoever worshipped Muhammad should know that he had died, but whoever worshipped Allah should know that Allah is ever-living and does not die.
""",
  review='Aisha\'s report and the verse are checked; the date and Abu Bakr\'s words are the usual account (Seerah report, source not checked).')

E('walimah',
  m=[r'\bwhat is (?:a |the )?wali?ma(?:h)?\b', r'\bwali?ma(?:h)? (?:meaning|mean|feast|dinner|food)\b', r'\bwedding feast\b', r'\bmeaning of wali?ma(?:h)?\b'],
  topic='walimah',
  go=['/academy/family-life'],
  text="""
The walimah is the wedding feast, held after the marriage is made. It is a sunnah, and scholars teach that it should be simple and that the invitation should not be limited to the rich. The Prophet ﷺ told Abd ar-Rahman ibn Awf to hold one: {H bukhari:5167|Anas reported that when Abd ar-Rahman ibn Awf married, the Prophet asked what dowry he gave and told him to hold a walimah even if it is with one sheep}.

Accepting an invitation to one is also encouraged, as long as nothing forbidden is going on there.
""",
  review='The hadith is checked; the rest is the common teaching.')

E('silat-ar-rahim',
  m=[r'\bwhat is sil(?:a|at|ah|atu|at ?ur) ?(?:al|ar|ur)? ?rahi?[mn]\b', r'\bsilat? ?(?:al|ar)? ?rahim\b', r'\b(?:how|ways) to keep (?:family )?(?:ties|relations)\b', r'\bkeep(?:ing)? (?:the )?(?:ties of )?kinship\b', r'\bmaintain (?:family )?ties\b', r'\bkeep family ties\b'],
  topic='keeping family ties',
  go=['/academy/family-life'],
  text="""
Silat ar-rahim means keeping the ties of kinship: visiting, calling, helping and treating relatives well, even when they have not done the same. The Qur'an puts it with fearing Allah: {Q 4:1|and the wombs}.

The Prophet ﷺ linked it to blessing in life and provision ({H bukhari:5986|Anas reported the Prophet said that whoever wants his provision increased and his life lengthened should keep good relations with his relatives}).

Keeping ties does not mean putting up with abuse: if a relative is harming you, you can keep your distance and stay safe, while still wishing them well and doing what you can at a safe distance.
""",
  review='The verse and hadith are checked; the last paragraph is the app\'s own safeguarding line, not a ruling.')

E('best-character',
  m=[r'\bbest (?:character|manners|akhlaq|akhlaaq)\b', r'\b(?:good|best) (?:character|akhlaq) in islam\b', r'\bwhat is (?:good )?(?:akhlaq|akhlaaq|character)\b', r'\bislamic (?:manners|etiquette|character)\b'],
  topic='good character',
  text="""
Islam puts good character at the centre of faith. Allah describes the Prophet ﷺ: {Q 68:4|And indeed, you are of a great moral character}. He taught that the best of people are those with the best manners ({H bukhari:6035|Abdullah ibn Amr reported the Prophet used to say that the best among you are the best in character}).

Honesty, patience, kindness, keeping promises, and holding back anger are the qualities the sources keep returning to.
""",
  review='Verse and hadith checked; the closing list is a summary.')

E('modesty-haya',
  m=[r'\bwhat is (?:modesty|haya|hayaa|hayaa)\b', r'\bmodesty in islam\b', r'\bhaya(?:a)? (?:in|of|meaning)\b'],
  x=[r'\b(?:hijab|dress|clothing|wear|cover)\b'],
  topic='modesty (haya)',
  text="""
Haya is a quality of shame, shyness and self-respect that stops a person from doing what is wrong or shameful and shows in speech, behaviour and the way a person treats others. It is not only about clothing. The Prophet ﷺ said that it is a part of faith: {H bukhari:24|Abdullah ibn Umar reported that the Prophet passed by a man from the Ansar rebuking his brother about being shy, and said to leave him, because haya is a part of faith}.
""",
  review='Hadith checked; the description is a summary of the common definition.')

E('riya-showing-off',
  m=[r'\bwhat is riya\b', r'\briy[aā]\b', r'\bshowing off (?:in|my) (?:worship|prayer|good deeds)\b', r'\bdoing good (?:deeds )?to be seen\b'],
  topic='riya',
  text="""
Riya is doing an act of worship or a good deed to be seen and praised by people, rather than for Allah alone. The Qur'an warns of the sort of worshippers who pray in front of others and remember Allah only a little ({QR 4:142}), and it speaks of those who show off in the prayer ({QR 107:4}-6).

The remedy the scholars give is to renew the intention often, to hide some good deeds, and to ask Allah for sincerity. A slip into wanting praise is something to correct and ask forgiveness for, not a reason to stop doing good.
""",
  review='Verses cited by reference only; remedies are the common teaching of the scholars of the heart.')

E('charity-secretly',
  m=[r'\bsecret(?:ly)? charity\b', r'\bgive (?:charity|sadaqah|sadaqa|zakat) (?:secretly|in secret)\b', r'\bcharity (?:in secret|secretly)\b', r'\bhow to give (?:charity|sadaqah) (?:secretly|quietly)\b'],
  topic='secret charity',
  go=['/zakat'],
  text="""
Giving in secret is praised in the Qur'an: {Q 2:271|If you disclose your charitable expenditures, they are good; but if you conceal them and give them to the poor, it is better for you}. The Prophet ﷺ listed among the seven people Allah shades on the Day of Judgment {H bukhari:1423|Abu Hurayrah reported the Prophet said that among the seven shaded by Allah on the day when there will be no shade but His is a man who gives charity so secretly that his left hand does not know what his right hand has given}.

Ways to do it: give cash or an envelope to a person directly, give to a charity or an anonymous fund, or pay an invoice for someone without saying who paid. Giving openly is not wrong, and it can encourage others, but secret charity guards the sincerity of the giver.
""",
  review='Verse and hadith checked; the practical ways are the app\'s own suggestions.')

E('months-rajab',
  m=[r'\bwhat is (?:the )?(?:islamic )?(?:month of )?rajab\b', r'\brajab (?:month|meaning)\b', r'\bsacred months?\b', r'\bfour sacred months\b'],
  topic='Rajab and the sacred months',
  go=['/calendar'],
  text="""
Rajab is the seventh month of the Islamic calendar and one of the four sacred months, in which fighting is forbidden and wrongdoing is especially grave: {QR 9:36}. The Prophet ﷺ named them ({H bukhari:3197|Abu Bakra reported the Prophet said that the year has twelve months, of which four are sacred: Dhul-Qa'dah, Dhul-Hijjah and Muharram together, and Rajab}).

No particular prayer or fast for Rajab is established in the authentic hadith, and reports that give fixed rewards for specific acts in Rajab are generally graded weak by hadith scholars. The Isra and Mi'raj is often connected to the 27th of Rajab, but the date is not established with certainty.
""",
  review='Hadith and the sacred-month verse checked; the remarks on weak reports and on the date of the Isra are the common scholarly position and need a scholar to confirm the wording.')

E('months-sha ?ban',
  m=[r'\bwhat is (?:the )?(?:islamic )?(?:month of )?sha ?ban\b', r'\bsha ?ban (?:month|meaning|fasting)\b', r'\bnight of bara ?at\b', r'\bshab[\- ]?e[\- ]?bara ?at\b', r'\b15th (?:of )?sha ?ban\b', r'\bnisf sha ?ban\b', r'\bmid ?sha ?ban\b'],
  topic='Sha\'ban',
  go=['/calendar'],
  text="""
Sha'ban is the month before Ramadan. The Prophet ﷺ fasted more in it than in any other month except Ramadan ({H bukhari:1969|Aisha reported that she never saw the Prophet fast a whole month except Ramadan and never saw him fast more in a month than in Sha'ban}).

The 15th night of Sha'ban, called the Night of Bara'at in South Asia, is where scholars differ. Some hold that reports about it strengthen each other and that praying and asking forgiveness that night is fine as a private act. Many others hold that the reports are weak, that no special prayer or gathering is established, and that fixing a ritual for it is an innovation. If you want to be safe, fast as the Prophet ﷺ did in Sha'ban and ask forgiveness at any time of the year, and ask a qualified scholar about the rest.
""",
  review='The hadith is checked; the account of the scholarly difference over the 15th night is a summary and needs a scholar to confirm the wording.')

E('months-muharram',
  m=[r'\bwhat is (?:the )?(?:islamic )?(?:month of )?muharram\b', r'\bmuharram (?:month|meaning)\b', r'\bfirst of muharram\b', r'\bislamic new year\b', r'\bhijri new year\b', r'\bwhat is ashura\b', r'\bashura\b'],
  topic='Muharram and Ashura',
  go=['/calendar'],
  text="""
Muharram is the first month of the Islamic (Hijri) calendar and one of the four sacred months ({QR 9:36}). The calendar counts from the Hijrah, the migration to Madinah; it was fixed in the time of Umar, not by the Prophet ﷺ, so the new year has no prescribed worship of its own.

The tenth of Muharram is Ashura, a day of fasting. When the Prophet ﷺ came to Madinah he found the Jews fasting it for the day Allah saved Musa, and he said that the Muslims have a better claim to Musa and fasted it too ({H bukhari:2004|Ibn Abbas reported the Prophet came to Madinah, saw the Jews fasting on Ashura because Allah saved Bani Israel from their enemy that day, and said that he had more right to Musa than they did, so he fasted it and ordered the fast}). Many scholars recommend fasting the day before or after it as well.
""",
  review='Hadith and verse checked; the Hijri calendar origin and the recommendation to add a day are the common account.')

E('mawlid',
  m=[r'\bwhat is (?:the )?(?:mawlid|mawlid an nabi|mawlid un nabi|milad un nabi|mawlid al nabi|maulid)\b', r'\b(?:mawlid|milad)(?: an| un| al)?(?: nabi)?\b'],
  topic='Mawlid',
  go=['/calendar'],
  text="""
The Mawlid an-Nabi is the celebration of the birthday of the Prophet ﷺ, held on or around the 12th of Rabi al-Awwal in many countries. It was not done by the Prophet ﷺ, the Companions or the first generations, and scholars disagree about it today.

Some scholars permit or encourage it as a way of sending blessings on the Prophet ﷺ, feeding people and remembering his life, as long as nothing forbidden is done. Others hold that adding a yearly celebration that the first generations did not do is an innovation. Everyone agrees that loving him is a duty, that sending blessings on him ({QR 33:56}) and following his sunnah are worship all year round, and that his birth date is itself recorded differently in the sources.

If this is a question for your own household, ask a qualified scholar you trust; it is a difference between recognised positions and not a question that Hadi settles.
""",
  review='Both positions are stated as held by scholars; needs a scholar to confirm the wording. The verse is cited by reference.')

E('dhul-hijjah-virtues',
  m=[r'\b(?:virtues?|merits?|importance|best days?) of dhul ?hijjah\b', r'\bfirst ten days of dhul ?hijjah\b', r'\b10 days of dhul ?hijjah\b', r'\bwhat is (?:the )?(?:month of )?dhul ?hijjah\b'],
  topic='Dhul Hijjah',
  go=['/calendar'],
  text="""
Dhul Hijjah is the twelfth month and the month of Hajj. Its first ten days are the best days of the year for good deeds ({H bukhari:969|Ibn Abbas reported the Prophet said that no good deed done on other days is better than those done in the first ten days of Dhul-Hijjah, not even jihad, except a man who goes out with his life and wealth and returns with nothing}).

People increase prayer, Qur'an, dhikr, charity and, if they are not on Hajj, fasting, especially on the Day of Arafah (the 9th). The 10th is Eid al-Adha.
""",
  review='Hadith checked; the list of deeds is the common teaching; fasting Arafah has its own reports not cited here.')

E('qurbani',
  m=[r'\bwhat is qurbani\b', r'\bqurbani (?:meaning|mean)\b', r'\bwhat is udhiyah\b', r'\budh?hiy?a(?:h)?\b', r'\beid al ?adha sacrifice\b', r'\bwhat is (?:the )?sacrifice (?:on|at|in) eid\b'],
  topic='qurbani',
  go=['/calendar'],
  text="""
Qurbani (udhiyah) is the sacrifice of an animal on Eid al-Adha and the days after it, in memory of Ibrahim's willingness to sacrifice his son ({QR 37:102}). Its meat is shared: some for the family, some for relatives and some for the poor.

The Qur'an says what Allah looks for in it: {Q 22:37|what reaches Him is piety from you}. Scholars differ on whether it is obligatory (the Hanafi view, for those who have the means) or a strongly recommended sunnah (the view of most others), so ask a scholar of your school about your own case.
""",
  review='Verse checked; the difference of opinion is the common one and needs a scholar to confirm the wording.')

E('dua-properly',
  m=[r'\bhow (?:to|do i|can i|should i) (?:make|do|say) du?a(?:h)? (?:properly|correctly|right|well)\b', r'\bhow to make (?:a )?dua\b', r'\betiquettes? of (?:du?a(?:h)?)\b', r'\bconditions of (?:du?a(?:h)?)\b', r'\bhow to (?:ask|call on|supplicate to) allah\b'],
  x=[r'\b(?:for|against)\b.*\b(?:enemy|someone|him|her)\b'],
  topic='how to make dua',
  go=['/adhkar'],
  text="""
There is no set form for du'a; you may speak to Allah in any language and with your own words. The things that scholars teach from the sources are:
- Begin by praising Allah and sending blessings on the Prophet ﷺ, and end the same way.
- Face the qibla and raise your hands if you can.
- Ask with sincerity and certainty, and keep asking: {Q 40:60|Call upon Me; I will respond to you}.
- Ask for what is permitted, and not for sin or for the cutting of family ties.
- Pick the best times: the last third of the night, between the adhan and iqamah, in sujud, and on Friday.
- Do not become hopeless because it is not answered yet. Answers come as the thing asked for, as a harm turned away, or as a reward kept for the Hereafter.
""",
  review='Verse checked; the list is a summary of the common teaching and cites no hadith numbers, so it is labelled Hadith report (reference not checked) where it refers to the sources.')

E('tasbih-after-salah',
  m=[r'\btas[hb]ee?h(?:at)? after (?:salah|salat|prayer|namaz)\b', r'\bdhikr after (?:salah|salat|prayer|namaz)\b', r'\bwhat to say after (?:salah|salat|prayer|namaz)\b', r'\bafter (?:the )?prayer (?:dhikr|adhkar|tasbih)\b', r'\b33 (?:times )?subhanallah\b'],
  topic='dhikr after the prayer',
  go=['/adhkar'],
  text="""
After the obligatory prayer the Sunnah is to say astaghfirullah three times, then the tasbih: Subhanallah 33 times, Alhamdulillah 33 times and Allahu Akbar 33 times, then to finish the hundred with "La ilaha illallahu wahdahu la sharika lah..." The Adhkar section has the full texts in Arabic with transliteration and meaning.
""",
  review='Hadith report (reference not checked): the practice is well known; the numbers are not cited here.')

E('procrastinating-prayer',
  m=[r'\bstop procrastinating (?:my )?(?:prayer|salah|salat)\b', r'\bprocrastinat\w* (?:my |the )?(?:prayer|salah|salat)\b', r'\bkeep (?:delaying|putting off) (?:my )?(?:prayer|salah)\b', r'\bhow to pray (?:on time|regularly)\b', r'\bi (?:always )?(?:delay|put off) (?:my )?(?:prayers?|salah)\b'],
  topic='praying on time',
  go=['/prayer'],
  text="""
Praying on time is a duty ({QR 4:103}), and a delay for no reason is serious. The practical things that help most people:
- Set the adhan notification on and treat it as the start of the prayer, not a reminder to start later.
- Pray as soon as the time comes in, before you start another task.
- Make wudu at once; it often breaks the habit of putting it off.
- Pick one prayer to be solid on first, and add one more each week.
- If you miss one, make it up as soon as you remember, and do not let one miss turn into a pile.

If this is a heavy struggle, you are not the only one, and starting again today is what counts. Ask Allah for help: no one finds the strength to pray except by His help.
""",
  review='Reference to the verse only; the practical steps are the app\'s own and are not a ruling.')

E('closer-to-allah',
  m=[r'\bhow (?:do|can|to) i (?:get|become|draw|grow) closer to allah\b', r'\bhow to (?:get|become|be|draw) closer to allah\b', r'\bhow to increase (?:my )?(?:iman|faith)\b', r'\bhow (?:do|can) i increase (?:my )?(?:iman|faith)\b', r'\bstrengthen (?:my )?(?:iman|faith)\b', r'\bboost (?:my )?(?:iman|faith)\b'],
  x=[r'\b(?:lost|losing|leaving|left)\b'],
  topic='getting closer to Allah',
  go=['/prayer', '/adhkar', '/quran'],
  text="""
The sources point to a few steady things rather than one big one:
- Pray the five prayers on time, and add some voluntary prayer, which is a way to draw near to Allah.
- Read some Qur'an every day, even a page, with the meaning.
- Make dhikr and ask forgiveness often.
- Be good to people, give in charity, and keep family ties.
- Keep company that reminds you of Allah, and leave what hardens the heart.

Small and regular is better than large and then dropped. If your faith feels low right now, that is common, and it rises and falls: {QR 13:28}.
""",
  review='The Qur\'an reference is checked; the rest is the common guidance of the scholars of the heart.')


E('prophet-childhood',
  m=[r'\b(?:prophet|muhammad)s? (?:childhood|early life|youth|boyhood)\b', r'\bchildhood of (?:the )?(?:prophet|muhammad)\b', r'\bwhen was (?:the )?prophet born\b', r'\bbirth of (?:the )?prophet\b'],
  topic='the Prophet\'s childhood',
  go=['/academy/seerah'],
  text="""
The Prophet Muhammad ﷺ was born in Makkah, in the tribe of Quraysh. He was born an orphan: his father Abdullah died before his birth and his mother Aminah died when he was about six. His grandfather Abd al-Muttalib looked after him, and then his uncle Abu Talib. As a baby he was nursed in the desert by Halimah as-Sa'diyyah, as was the custom among the Arabs. As a young man he worked as a shepherd and a trader, and was known in Makkah as as-Sadiq al-Amin, the truthful, the trustworthy.

The Qur'an reminds him of it: {Q 93:6|Did He not find you an orphan and give [you] refuge}.
""",
  review='Seerah report (source not checked): the usual account from the early biographies; the verse is checked.')

E('names-boys',
  m=[r'\bislamic names? for (?:a )?(?:boys?|baby boys?|sons?)\b', r'\b(?:muslim|arabic) (?:baby )?(?:boy )?names?\b', r'\bnames? for (?:my )?(?:baby )?(?:boy|son)\b', r'\bboys? names? (?:in|from) islam\b', r'\bgood names? for (?:a )?boy\b'],
  x=[r'\b(?:girl|daughter)\b'],
  topic='names for boys',
  go=['/games/names99', '/academy/family-life'],
  text="""
There is no list that Islam requires, but the sources give some guidance: choose a name with a good meaning, and avoid names that carry a bad meaning, or that claim a quality that belongs only to Allah. A common choice is a name of servitude to Allah, such as Abdullah or Abd ar-Rahman, a name of a prophet (Ibrahim, Yusuf, Musa, Isa, Muhammad), or of a Companion (Umar, Ali, Uthman, Bilal, Salman).

If you pick a name from the 99 Names of Allah, it is joined with Abd ("servant of"), as in Abd al-Karim. The Names of Allah section of the app lists them with their meanings.
""",
  review='General guidance; no hadith number cited.')

E('name-change-convert',
  m=[r'\bdo i (?:need|have|must) (?:to )?change (?:my )?name\b', r'\bchange (?:my )?name (?:after|when|if) (?:i )?(?:convert|revert|becom|embrac|accept)\w*\b', r'\bmuslim name (?:after|when) (?:convert|revert)\w*\b', r'\bshould i take (?:a )?muslim name\b', r'\b(?:new muslim|revert|convert) (?:name|names)\b'],
  topic='changing your name after converting',
  go=['/new-muslim'],
  text="""
You do not have to change your name to become a Muslim, and changing it does not make you more Muslim. What matters is whether the meaning of your name is acceptable. The scholars say a name should be changed only if its meaning is wrong, for example if it claims servitude to someone other than Allah, or means something bad.

The Prophet ﷺ himself changed names with a bad or self-praising meaning ({H bukhari:6192|Abu Hurayrah reported that Zaynab's name was Barrah, and it was said that by it she was claiming goodness for herself, so the Prophet changed her name to Zaynab}). Many new Muslims keep their given name, add an Islamic name for use in the community, or take a new one; all three are accepted. It is a personal choice, and a change of name can have legal steps in your country as well.
""",
  review='Hadith checked; the guidance on when a name should change is the common scholarly view and needs a scholar to confirm the wording.')

E('treat-wife',
  m=[r'\bhow (?:should|do|to|can) (?:i |a man |a husband )?(?:to )?treat (?:my |his |a )?wife\b', r'\bhusband(?:s)? (?:duties|rights|responsibilit\w+) (?:to|towards) (?:his |a )?wife\b', r'\bbe a good husband\b', r'\bhow to be a good husband\b', r'\btreating (?:my |a )?wife\b'],
  x=[r'\b(?:hit|beat|strike|obey|punish)\b'],
  topic='how to treat your wife',
  go=['/academy/family-life'],
  text="""
The Qur'an commands husbands: {Q 4:19|live with them in kindness}. The Prophet ﷺ taught the same ({H bukhari:5186|Abu Hurayrah reported the Prophet said that whoever believes in Allah and the Last Day should not harm his neighbour, and that he advised them to treat women well}).

In practice scholars list: being patient and gentle, providing and spending on her fairly, speaking kindly, consulting her, helping at home as the Prophet ﷺ did, protecting her dignity, and never humiliating or hurting her. Nothing in Islam gives a husband the right to hit, frighten or control his wife. If a marriage is in difficulty, a trusted family member, imam or counsellor can help.
""",
  review='Verse and hadith checked; the list of practical duties is a summary of scholarly teaching and the last two sentences are the app\'s own safeguarding line.')

E('duha-prayer',
  m=[r'\bwhat is (?:the )?(?:duha|dhuha|doha|chasht|zuha) (?:prayer|salah|salat|namaz)\b', r'\b(?:duha|dhuha|doha|chasht) (?:prayer|salah|salat|namaz)\b', r'\bforenoon prayer\b', r'\bhow many rakats? (?:is|in) (?:the )?(?:duha|dhuha|chasht)\b'],
  topic='Duha prayer',
  go=['/prayer'],
  text="""
Duha is a voluntary prayer in the forenoon, from a little after sunrise until shortly before the sun reaches its highest point. It is prayed as two rak'ahs or more, in pairs. Abu Hurayrah reported that the Prophet ﷺ advised him three things not to leave ({H bukhari:1981|Abu Hurayrah reported the Prophet advised him to fast three days each month, to pray two rak'ahs of Duha, and to pray witr before sleeping}).

Scholars differ on how often to pray it, and on how many rak'ahs at most; two is enough and shows the sunnah.
""",
  review='Hadith checked; the wording on the time and on the scholarly difference needs a scholar to confirm.')

E('talbiyah',
  m=[r'\bwhat is (?:the )?talbi?yah\b', r'\btalbi?yah (?:meaning|words|text|translation)\b', r'\blabbaik(?:a)? allahumma labbaik\b', r'\bmeaning of labbaik\b'],
  topic='Talbiyah',
  go=['/adhkar'],
  text="""
The talbiyah is what pilgrims say from the time they enter ihram for Hajj or Umrah. Ibn Umar reported the words of the Prophet ﷺ ({H bukhari:1549|Abdullah ibn Umar reported that the talbiyah of the Messenger of Allah was Labbayk Allahumma labbayk, labbayka la sharika laka labbayk, innal-hamda wan-ni'mata laka wal-mulk, la sharika lak}).

Transliteration: Labbayk, Allahumma labbayk. Labbayka la sharika laka labbayk. Innal-hamda wan-ni'mata laka wal-mulk. La sharika lak.

Meaning: "Here I am, O Allah, here I am. Here I am, You have no partner, here I am. Indeed all praise, favour and sovereignty are Yours. You have no partner."
""",
  review='Hadith checked; the English meaning is the app\'s own.')

E('tarwiyah',
  m=[r'\bwhat is (?:the )?(?:day of )?(?:tarwi?yah|tarwiyyah)\b', r'\b(?:day|yawm) (?:al ?|of )?tarwi?yah\b', r'\b8th (?:of )?dhul ?hijjah\b', r'\beighth (?:of )?dhul ?hijjah\b'],
  topic='Day of Tarwiyah',
  go=['/calendar'],
  text="""
The Day of Tarwiyah is the 8th of Dhul Hijjah, the first day of the main rites of Hajj. Pilgrims put on ihram (if they are doing Hajj Tamattu' they put it on again from where they are staying), go to Mina, and pray Dhuhr, Asr, Maghrib, Isha and Fajr there, shortening the four-rak'ah prayers, and stay until after sunrise on the 9th, when they go to Arafah. Those who are not on Hajj are not asked to do anything special on that day, but it is among the best days of the year ({QR 22:28}).
""",
  review='Hadith report (reference not checked): the sequence of rites is the standard account; confirm the details with a Hajj guide of your school.')

E('ruku-dhikr',
  m=[r'\bwhat (?:do|should) i (?:say|recite|read) (?:in|during) (?:the )?ruku\b', r'\bruku (?:dhikr|dua|tasbih|supplication|words)\b', r'\bwhat to (?:say|recite|read) in ruku\b', r'\bwhat is said in ruku\b', r'\bsubhana rabbi?yal ?azee?m\b'],
  topic='what to say in ruku',
  go=['/prayer'],
  text="""
In ruku (bowing) the usual words are Subhana rabbiyal-azim, which means glory be to my Lord, the Most Great, said three times or more. The wording echoes the command to exalt the name of your Lord, the Most Great ({QR 56:74}). When you rise you say Sami'allahu liman hamidah, which means Allah hears the one who praises Him, and then Rabbana wa lakal-hamd, which means Our Lord, to You is the praise. The Prayer guide in the app has the whole prayer, with transliteration and meaning.
""",
  review='Hadith report (reference not checked): the words are the standard ones; the verse is cited by reference.')

E('khutbah-meaning',
  m=[r'\bwhat is (?:the )?(?:khutbah|khutba|khutbat|jumuah khutbah|friday sermon)\b', r'\bkhutbah (?:meaning|mean|in islam)\b', r'\bfriday sermon\b'],
  topic='the khutbah',
  go=['/stories'],
  text="""
The khutbah is the sermon given by the imam before the Friday (Jumu'ah) prayer. Allah commands the Muslims to come to it and to the prayer: {Q 62:9|when [the adhan] is called for the prayer on the day of Jumu'ah [Friday], then proceed to the remembrance of Allah and leave trade}.

It has two parts with a short sit between them: praising Allah, sending blessings on the Prophet ﷺ, reminding the people of taqwa, and teaching something from the Qur'an and the sunnah. Worshippers listen in silence. The Eid prayers also have a khutbah, after the prayer.
""",
  review='Verse checked; the structure of the khutbah is the common account, with small differences between schools.')

E('illness-patience',
  m=[r'\b(?:how|ways) to (?:patiently )?(?:bear|endure|handle|cope with|deal with) (?:an )?(?:illness|sickness|disease|pain)\b', r'\bpatien(?:ce|tly) (?:with|in|during) (?:an )?(?:illness|sickness|disease|pain)\b', r'\bsabr (?:in|with|during) (?:an )?(?:illness|sickness|disease)\b', r'\bhow to be patient (?:in|during|with) (?:illness|sickness)\b'],
  topic='patience in illness',
  go=['/sakina'],
  text="""
Illness is a test, and the sources are gentle about it. The Qur'an says to give good news to the patient ({QR 2:155}). The Prophet ﷺ said that nothing afflicts a Muslim, down to the prick of a thorn, except that Allah removes some of his sins by it ({H bukhari:5641|Abu Said al-Khudri and Abu Hurayrah reported the Prophet said that no fatigue, disease, sorrow, sadness, hurt or distress befalls a Muslim, even the prick of a thorn, but that Allah expiates some of his sins by it}).

Practical things: seeking treatment is part of faith, and being patient does not mean hiding pain or pretending you are not hurting. Say what you feel to Allah, keep up the prayer as far as you can (a sick person prays in the way they are able), and let people help you. If you are low or afraid, please talk to someone you trust and to your doctor; the Sakinah section and Need help now are there for the hard days.
""",
  review='Hadith checked; the verse is cited by reference; the practical paragraph is the app\'s own and not medical advice.')

E('gratitude-shukr',
  m=[r'\bhow to be (?:more )?(?:grateful|thankful)\b', r'\bgratitude in islam\b', r'\bshukr (?:in|meaning|of)\b', r'\bwhat is shukr\b', r'\bhow to (?:thank|show gratitude to) allah\b'],
  topic='gratitude (shukr)',
  text="""
Shukr, gratitude, is shown by the heart (knowing every blessing is from Allah), by the tongue (saying Alhamdulillah) and by action (using the blessing in what pleases Him). The Qur'an promises: {Q 14:7|If you are grateful, I will surely increase you [in favor]}.

The Prophet ﷺ prayed at night until his feet swelled, and when asked why, said he wanted to be a thankful servant ({H bukhari:1130|Al-Mughirah reported the Prophet used to pray until his feet or legs swelled, and when asked about it he said should I not be a thankful servant}). Some things that help: say Alhamdulillah deliberately for specific blessings, thank people, give a little in charity, and look at those who have less than you in worldly things.
""",
  review='Verse and hadith checked; the closing suggestions are the app\'s own.')

E('istisqa',
  m=[r'\bwhat is (?:the )?(?:salat|salah|prayer of )?(?:al )?istisqa\b', r'\bistisqa\b', r'\brain prayer\b', r'\bprayer for rain\b'],
  topic='Istisqa (prayer for rain)',
  go=['/prayer'],
  text="""
Istisqa is the prayer asking Allah for rain when there is drought. The Prophet ﷺ went out to the open prayer area, asked Allah for rain, faced the qibla, turned his cloak over, and prayed two rak'ahs ({H bukhari:1012|Abdullah ibn Zayd reported the Prophet went out to the prayer ground, invoked Allah for rain, faced the qibla, turned his cloak, and prayed two rak'ahs}). Scholars differ on details such as the sermon and the order, so follow the practice of your school or your local imam.
""",
  review='Hadith checked; the difference over details is stated generally and needs a scholar to confirm.')

E('hadith-meaning',
  m=[r'^(?:hadees|hadis|hadeeth|ahadith|ahadees)$', r'\bwhat is (?:a )?(?:hadees|hadis|hadeeth|hadith)\b', r'\bwhere (?:can|do) i (?:find|read|look up) (?:a )?(?:hadith|hadees|hadeeth)\b', r'\bhow to find (?:a )?hadith\b'],
  x=[r'\b(?:about|on) (?:prayer|fasting|zakat|hajj)\b'],
  topic='what a hadith is',
  go=['/hadith', '/sources'],
  text="""
A hadith is a report of what the Prophet ﷺ said, did or approved. Together with the Qur'an it is the basis of Islamic teaching. Scholars collected hadith in books and graded them for how reliable the chain of narrators is. The two most trusted collections are Sahih al-Bukhari and Sahih Muslim, followed by Sunan Abu Dawud, Jami' at-Tirmidhi, Sunan an-Nasa'i and Sunan Ibn Majah (the six books).

In the app, the Hadith section lets you read and search; every hadith Hadi quotes carries its collection and number so you can look it up, and its grade where the collection is not Bukhari or Muslim.
""",
  review='General description; the six-book list is standard.')


E('names-allah-rahman-wadud',
  m=[r'\bwhat (?:is|does) (?:the name )?(?:ar ?|al ?)rahman\b', r'\b(?:meaning|mean) of (?:ar ?|al ?)?rahman\b', r'\bwhat (?:is|does) (?:the name )?(?:al ?)?wadud\b', r'\b(?:meaning|mean) of (?:al ?)?wadud\b'],
  x=[r'\b(?:surah|chapter)\b.*\b55\b'],
  topic='names of Allah: ar-Rahman and al-Wadud',
  go=['/games/names99'],
  text="""
Ar-Rahman means the Entirely Merciful, whose mercy covers all creation: {Q 1:3|The Entirely Merciful, the Especially Merciful}. Surah 55 is named after it. Al-Wadud is the Most Loving: Allah says He is {Q 85:14|the Forgiving, the Affectionate}. The Names of Allah section lists all ninety-nine with their meanings.
""",
  review='Verses checked; names glossed with the translation in the bundled text.')

E('surah-yasin',
  m=[r'\bwhat is surah (?:ya ?sin|yaseen|yasin)\b', r'\bsurah (?:ya ?sin|yaseen|yasin) (?:about|meaning|summary)\b', r'\bwhat is (?:ya ?sin|yaseen) about\b'],
  topic='Surah Ya-Sin',
  go=['/quran'],
  text="""
Surah Ya-Sin is the 36th surah, revealed in Makkah, with 83 verses ({QR 36:1}). It is about the truth of revelation and the Prophet's message, the story of the people of a town who rejected their messengers, signs of Allah in the earth, the night and the sun, and the resurrection and the final reckoning.

Many reports give it special virtues, such as reading it for the dying or for needs. Hadith scholars grade most of those reports as weak, so read it for the meaning and for the reward of reading the Qur'an in general, and do not treat any particular use as established unless a qualified scholar tells you so.
""",
  review='Surah details checked; the remark on the grading of the virtue reports is the common scholarly position and needs a scholar to confirm the wording.')
