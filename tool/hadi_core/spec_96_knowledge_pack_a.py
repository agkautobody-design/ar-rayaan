# Knowledge pack A (20 Nov 2026): everyday du'as and manners. Every hadith is read
# against the hadith-api English text by build.py; weak reports are not cited as
# evidence. Run with HADI_PACK=1 python3 tool/hadi_core/build.py (builds only this
# pack into hadi_core_pack_data.dart; the older hand-edited data file is untouched).
# No answer here rules on a person's own case: where scholars differ it says so.

E('home-enter-say',
  m=[r'\b(?:what|which) (?:do|should|must|can|are) (?:i|we|you|one|a muslim) (?:say|supposed to say|recite|read)\b.*\b(?:enter(?:ing)?|walk(?:ing)? into|come(?:s)? into|arriv(?:e|ing) (?:at|home)|get(?:ting)? home)\b.*\b(?:home|house|apartment|flat|room)\b',
     r'\b(?:dua|du a|supplication|dhikr|words?) (?:for |when |before |upon |on )?(?:enter(?:ing)?|coming into|going into|arriving|returning|entry)\b.*\b(?:home|house)\b',
     r'\b(?:enter(?:ing)?|entering into|entry (?:to|into)) (?:the |a |my |your )?(?:home|house)\b.*\b(?:dua|du a|supplication|say|recite|sunnah)\b',
     r'\bwhat (?:to|do i|should i) say (?:when|as|before) (?:i )?(?:enter|come in|go in|get home|arrive home|walk in)\b',
     r'\b(?:home|house) (?:entering|entry) (?:dua|du a|supplication)\b'],
  x=[r'\b(?:mosque|masjid|toilet|bathroom|haram|ruling)\b'],
  topic='entering the home',
  go=['/adhkar'],
  text="""
The Sunnah when you go into your home is to mention Allah's name. The Prophet ﷺ said: {HS muslim:2018|when a person enters his house and mentions the name of Allah when entering and while eating, Satan says to himself that there is no place to spend the night and no evening meal for him there, but when he enters without mentioning Allah's name, Satan says he has found a place to spend the night}.

So the simple practice is to say "Bismillah" (in the name of Allah) as you enter. The Qur'an also tells believers to greet one another when entering houses, with a greeting from Allah ({QR 24:61}), so saying "As-salamu alaykum" to the people inside, or to the house if it is empty, is part of it too.

A longer du'a for entering and leaving the home is reported in Abu Dawud, but its chain is graded weak by the scholars I checked, so I do not give it as a Sunnah wording.
""",
  review='Scholar review needed: confirm the bismillah and salam wording and the note on the weak Abu Dawud du\'a.')

E('home-protect-surah',
  m=[r'\b(?:which|what) (?:surah|sura|surat|ayah|ayat|verse|verses|quran|dua|du a)\b.*\b(?:protect|protects|protection|bless|blessing|hang|hung|put|place|read|recite)\b.*\b(?:home|house|door|entrance|doorway|entry)\b',
     r'\b(?:surah|sura|surat|ayah|ayat|verse|verses)\b.*\b(?:hang|hung|hanging|over|above|on)\b.*\b(?:entrance|door|doorway|entry|front door)\b',
     r'\b(?:protect|protecting|protection|bless|blessing|safe(?:guard)?) (?:of |for |my |the |our )?(?:home|house)\b.*\b(?:quran|surah|sura|verse|ayah|ayat|dua|du a|recite|read)\b',
     r'\b(?:quran|surah|sura|verse|ayah|ayat|dua|du a|recite|read)\b.*\b(?:protect|protecting|protection|bless|blessing|safe(?:guard)?) (?:of |for |my |the |our )?(?:home|house)\b',
     r'\bhow (?:do|can|should) i (?:protect|bless|purify|cleanse|safeguard|keep (?:safe|protected)) (?:my |the |our )?(?:home|house|family)\b',
     r'\bprotect(?:ing)? (?:my |the |our )?(?:home|house)\b',
     r'\bwhat (?:keeps?|drives?|chases?|makes?) (?:shaytan|satan|devil|jinn)s? (?:away|out|leave)\b.*\b(?:home|house)\b'],
  x=[r'\b(?:haram|ruling|permissible|allowed|halal)\b'],
  topic='protecting the home',
  go=['/adhkar', '/quran'],
  text="""
The reports are about reciting, not hanging. Abu Hurayrah reported the Prophet ﷺ saying: {HS muslim:780|do not make your houses into graveyards, for Satan runs away from the house in which Surah Al-Baqarah is recited}. So reading Al-Baqarah, or parts of it, at home is the practice the hadith points to.

Other well-known recitations: the last two verses of Al-Baqarah ({QR 2:285-286}), as reported by Abu Mas'ud: {HS bukhari:5009|the Prophet said that whoever recites the last two verses of Surat Al-Baqarah at night, that is sufficient for him}; and Ayat al-Kursi ({QR 2:255}), which Abu Hurayrah was taught as a guard for the night ({HS bukhari:2311|Abu Hurayrah was taught that reciting Ayat al-Kursi at bedtime means Allah appoints a guard and no devil comes near until morning}). Also saying Bismillah as you enter and leave.

About hanging verses or writing them over the door: I did not find a report where the Prophet ﷺ did that or told people to. Scholars differ on wearing or hanging Qur'anic verses as protection,. Many scholars therefore advise relying on recitation and du'a rather than on a hung object. For a ruling on a framed verse in your own home, please ask a scholar of your school.
""",
  review='Scholar review needed: the note on hanging verses summarises a difference of opinion; no ruling given.')

E('travel-dua',
  m=[r'\b(?:dua|du a|supplication|dhikr|words?)\b.*\b(?:travel|travelling|traveling|journey|trip|car|vehicle|plane|flight|riding|mount|setting out)\b',
     r'\b(?:travel|travelling|traveling|journey|trip|car|vehicle|plane|flight|riding|setting out)\b.*\b(?:dua|du a|supplication)\b',
     r'\bwhat (?:to|do i|should i) say (?:when|before|as) (?:i )?(?:travel|get in(?:to)? (?:a |the |my )?(?:car|vehicle|taxi)|board|start (?:a |my |the )?(?:trip|journey)|set out|take off)\b',
     r'\bsubhana (?:alladhi|allazi|lladhi) sakhkhara\b'],
  x=[r'\b(?:prayer|salah|shorten|qasr|combine|jam|fasting|ramadan|haram|ruling)\b'],
  topic='travel du\'a',
  go=['/adhkar'],
  text="""
Ibn Umar reported how the Prophet ﷺ began a journey: {HS muslim:1342|whenever he mounted his camel to set out on a journey he said Allahu Akbar three times and then said "Glory be to Him who subjected this to us, and we could not have done it ourselves, and to our Lord we shall return"}.

The words are from the Qur'an ({QR 43:13-14}). People say them when they get into a car, board a plane or start any trip. The full du'a in the hadith continues with asking Allah for goodness and piety on the journey; the Dhikr and Du'a screen has it in full.
""",
  review='Scholar review needed: confirm the continuation wording before quoting it in full.')

E('sneeze-etiquette',
  m=[r'\bwhat (?:to|do i|should i|do you) say (?:when|if|after) (?:i |you |someone |he |she )?sneez(?:e|es|ed|ing)\b',
     r'\b(?:sneez(?:e|es|ed|ing)|achoo)\b.*\b(?:dua|du a|say|islam|islamic|sunnah|respond|reply|etiquette|manners)\b',
     r'\b(?:dua|du a|islamic|islam|sunnah|etiquette|manners)\b.*\bsneez(?:e|es|ed|ing)\b',
     r'\b(?:yarhamukallah|yarhamuka allah|yarhamuk allah|tashmeet|tashmit)\b'],
  topic='sneezing',
  text="""
Abu Hurayrah reported the Prophet ﷺ saying: {HS bukhari:6224|if anyone of you sneezes he should say "Al-hamdu lillah" (praise be to Allah), and his Muslim brother or companion should say to him "Yarhamuka Allah" (may Allah have mercy on you), and when he says that the sneezer should reply "Yahdikum Allah wa yuslih balakum" (may Allah guide you and put your affairs right)}.

So: the one who sneezes says Alhamdulillah, the listener says Yarhamukallah, and the sneezer answers Yahdikumullah wa yuslihu balakum.
""",
  review='Scholar review needed: the summary is of the first part of the report; the reply wording is as in the hadith.')

E('rain-dua',
  m=[r'\bwhat (?:to|do i|should i|do you) say (?:when|if|during|as) (?:it )?(?:rains?|raining|rainfall|there is rain|it is raining)\b',
     r'\b(?:dua|du a|supplication)\b.*\b(?:rain|raining|rainfall|storm|thunder)\b',
     r'\b(?:rain|raining|rainfall)\b.*\b(?:dua|du a|supplication|sunnah|islam|islamic)\b'],
  x=[r'\b(?:istisqa|prayer for rain|salat|salah)\b'],
  topic='rain du\'a',
  go=['/adhkar'],
  text="""
Aisha reported: {HS bukhari:1032|whenever Allah's Messenger ﷺ saw the rain he used to say "O Allah, let it be a strong, fruitful rain"}.

In Arabic: Allahumma sayyiban nafi'a. Many people also make du'a while it rains, since scholars count it as a time when du'a is hoped to be accepted; I am not citing a report for that here.
""",
  review='Scholar review needed: the note on du\'a during rain is the scholars\' view with no hadith cited here.')

E('morning-evening-protection',
  m=[r'\b(?:dua|du a|dhikr|adhkar|supplication|words?)\b.*\b(?:protect|protection|protected|harm|safe(?:ty)?|sudden)\b.*\b(?:morning|evening|every (?:day|night)|day|night)\b',
     r'\b(?:protect\w*)\b.*\b(?:dua|du a|dhikr|adhkar)\b.*\b(?:morning|evening)\b',
     r'\b(?:morning|evening)\b.*\b(?:dua|du a|dhikr|adhkar)\b.*\b(?:protect\w*)\b',
     r'\bbismillahi? ?(?:alladhi|allazi|lladhi) la yadurru\b',
     r'\b(?:protect\w*)\b.*\b(?:from )?(?:harm|sudden affliction|calamity)\b.*\b(?:dua|du a|dhikr|say|recite)\b',
     r'\bnothing (?:on|in) (?:earth|the earth|heaven|the heavens) can (?:cause )?harm\b'],
  x=[r'\b(?:haram|ruling)\b'],
  topic='morning and evening protection',
  go=['/adhkar'],
  text="""
Uthman ibn Affan reported the Prophet ﷺ saying: {HS tirmidhi:3388|there is no servant who says every morning and every evening "In the name of Allah, with whose name nothing on earth or in the heavens can cause harm, and He is the Hearing, the Knowing" three times, but nothing will harm him}.

Abu Dawud has the same report with sudden affliction named ({HS abudawud:5088|whoever says it three times will not suffer a sudden affliction until the morning, and whoever says it in the morning will not suffer sudden affliction until the evening}).

In Arabic: Bismillahi alladhi la yadurru ma'a ismihi shay'un fil-ardi wa la fis-sama'i wa huwa as-Sami'u al-'Alim. It is a trust in Allah, not a charm: the protection is by His permission.
""",
  review='Scholar review needed: confirm the closing line about trust in Allah, which is the app\'s wording, not a quotation.')

E('backbiting',
  m=[r'\b(?:what is|whats|define|meaning of|explain) (?:backbiting|gheebah|ghibah)\b',
     r'\b(?:backbiting|gheebah|ghibah|gossip(?:ing)?|speaking ill|talking behind (?:someones|his|her|their|my) back)\b',
     r'\bis (?:it )?(?:backbiting|gheebah|ghibah) if (?:it is|its|he|she) (?:true|there)\b'],
  topic='backbiting',
  text="""
The Prophet ﷺ defined it: {HS muslim:2589|backbiting is talking about your brother in a way he does not like}. When he was asked what if what is said is true of the brother, he explained that if it is true that is backbiting, and if it is not true it is slander.

The Qur'an forbids it with a vivid picture: do not spy on one another or backbite, would any of you like to eat the flesh of his dead brother ({QR 49:12}). Scholars list narrow exceptions, such as warning someone about a real danger or asking a scholar about an injustice; for your own case, ask a scholar.
""",
  review='Scholar review needed: the exceptions are from the scholars\' lists and must be confirmed by a named scholar.')

E('smile-charity',
  m=[r'\b(?:is )?(?:smiling|a smile|smile)\b.*\b(?:charity|sadaqah|sadaqa|sunnah|reward|islam)\b',
     r'\b(?:charity|sadaqah|sadaqa)\b.*\b(?:smile|smiling|kind word|small act|every good|without money|no money)\b',
     r'\bhow (?:can|do) i give (?:charity|sadaqah|sadaqa)\b.*\b(?:without money|no money|nothing|for free)\b',
     r'\b(?:every )?good (?:deed|act)\b.*\b(?:charity|sadaqah|sadaqa)\b'],
  topic='small acts that are charity',
  go=['/zakat'],
  text="""
Abu Dharr reported the Prophet ﷺ saying: {HS tirmidhi:1956|your smiling in the face of your brother is charity, commanding good and forbidding evil is charity, giving directions to a man lost in the land is charity, helping a man of poor sight is charity, and removing a rock, a thorn or a bone from the road is charity}.

So charity is not only money. Zakat itself is a fixed duty on wealth, and the Zakat calculator in the app is for that.
""",
  review='Scholar review needed: the summary lists the first items of the report only.')

E('love-one-another-salam',
  m=[r'\b(?:how|what) (?:do|can|should) (?:i|we) (?:increase|spread|grow) (?:love|brotherhood|friendship)\b',
     r'\b(?:spread(?:ing)?|giv(?:e|ing)) (?:the )?(?:salam|salaam|greeting|greetings)\b',
     r'\b(?:hadith|saying)\b.*\b(?:love one another|love each other)\b',
     r'\byou will not (?:enter paradise|believe)\b.*\blove\b'],
  topic='love and greeting',
  text="""
Abu Hurayrah reported the Prophet ﷺ saying: {HS muslim:54|you will not enter Paradise until you believe, and you will not believe until you love one another. Shall I not direct you to something that, if you do it, you will love one another? Spread the greeting of peace among yourselves}.

So the Prophet ﷺ named the way: spreading "As-salamu alaykum" among yourselves.
""",
  review='Scholar review needed: the summary closes the report with the instruction to spread the greeting.')

E('dhikr-living-dead',
  m=[r'\b(?:why|what is the) (?:benefit|reward|importance|value|point) (?:of )?(?:dhikr|remembering allah|remembrance)\b',
     r'\b(?:why|how) (?:should|do|must) (?:i|we) (?:do|make|say) dhikr\b',
     r'\b(?:living|alive)\b.*\b(?:dead)\b.*\b(?:dhikr|remembers?|remembering|praises?)\b',
     r'\bwhat is dhikr\b'],
  topic='dhikr',
  go=['/adhkar', '/tasbeeh'],
  text="""
Dhikr means remembering Allah: with the tongue (saying His praise), and with the heart. The Qur'an says: remember Me and I will remember you ({QR 2:152}).

Abu Musa reported the Prophet ﷺ saying: {HS bukhari:6407|the example of the one who remembers his Lord compared to the one who does not is that of a living creature compared to a dead one}.

The Tasbeeh counter and the Dhikr and Du'a screen are in the app.
""",
  review='Scholar review needed: the first sentence is a short general definition by the app.')

E('yunus-dua',
  m=[r'\b(?:dua|du a|supplication|prayer)\b.*\b(?:yunus|yunis|jonah|dhun nun|dhul nun|whale|fish)\b',
     r'\b(?:yunus|yunis|jonah|dhun nun|dhul nun)\b.*\b(?:dua|du a|supplication|said|prayed|called)\b',
     r'\bla ilaha illa anta subhanaka\b',
     r'\bdua (?:when|for) (?:i am |im |in )?(?:distress|trouble|hardship|difficulty|anguish)\b'],
  topic='dua of Yunus',
  go=['/adhkar'],
  text="""
When Prophet Yunus was in the darkness of the whale, the Qur'an records his call: there is no god but You, glory be to You, I was among the wrongdoers ({QR 21:87}), and says that Allah answered him and saved him ({QR 21:88}).

Sa'd reported the Prophet ﷺ said: {HS tirmidhi:3505|the supplication of Dhun-Nun when he supplicated in the belly of the whale was "There is none worthy of worship except You, glory be to You, I was among the wrongdoers"}, and that no Muslim calls on Allah with it for anything except that Allah answers him.

In Arabic: La ilaha illa anta subhanaka inni kuntu min adh-dhalimin.
""",
  review='Scholar review needed: the closing clause of the hadith is paraphrased; confirm full wording.')

E('tawakkul-tie-camel',
  m=[r'\b(?:what is|whats|explain|meaning of) (?:tawakkul|tawakul|trust in allah|reliance on allah)\b',
     r'\b(?:tawakkul|tawakul)\b.*\b(?:action|effort|work|do (?:my )?part|tie|camel)\b',
     r'\b(?:tie|tying)\b.*\bcamel\b',
     r'\bshould i (?:just )?(?:do nothing|rely on allah|trust allah)\b.*\b(?:effort|try|work|means)\b'],
  topic='tawakkul',
  text="""
A man asked the Prophet ﷺ whether he should tie his camel and rely on Allah or leave it loose and rely on Allah. {HS tirmidhi:2517|He answered "Tie it and rely on Allah"}.

That is the usual meaning scholars give of tawakkul: do the means that are in your hand, then put the result with Allah. The Qur'an says: when you have decided, then rely on Allah ({QR 3:159}).
""",
  review='Scholar review needed: the "usual meaning" line is a summary of scholars\' explanation, no named scholar cited.')

E('ayat-kursi-benefit',
  m=[r'\b(?:what is|whats|benefit|benefits|virtue|virtues|reward|importance|meaning) (?:of )?(?:ayat|ayah|aya) (?:al )?kursi\b',
     r'\bayat(?:ul)? ?kursi\b',
     r'\bthrone verse\b',
     r'\b(?:verse|ayah|ayat) of the throne\b'],
  topic='Ayat al-Kursi',
  go=['/quran'],
  text="""
Ayat al-Kursi is verse 255 of Surah Al-Baqarah ({QR 2:255}), the verse of the Throne. Abu Hurayrah was told this by a thief, and the Prophet ﷺ confirmed it was true: {HS bukhari:2311|Abu Hurayrah was taught that reciting Ayat al-Kursi at bedtime means Allah appoints a guard and no devil comes near until morning}.

I do not give other rewards here beyond this report.
""",
  review='Scholar review needed: the summary stops at the bedtime report on purpose.')

E('eat-after-forgot-bismillah',
  m=[r'\b(?:forgot|forget|forgotten|forgetting) to say bismillah\b',
     r'\bwhat if (?:i |you )?forget to (?:mention|say) (?:allahs? name|bismillah)\b.*\b(?:eat|eating|food|meal)\b',
     r'\b(?:dua|du a|what to say|say) after (?:eating|finishing (?:a )?meal|food|a meal)\b',
     r'\b(?:alhamdulillah|alhamdu lillah|alhamdu lillahi) (?:alladhi|allazi|lladhi) at amani\b'],
  topic='etiquette of eating',
  text="""
If you forget to say Bismillah at the start of the meal: Aisha reported the Prophet ﷺ said {HS abudawud:3767|when one of you eats he should mention Allah's name, and if he forgets to do so at the beginning he should say "In the name of Allah at the beginning and at the end of it"}.

After the meal: Mu'adh ibn Anas reported the Prophet ﷺ said {HS tirmidhi:3458|whoever eats food and then says "All praise is due to Allah who fed me this and granted it to me without any strength or power from me", his earlier sins will be forgiven}.

And for children and everyone at the table: {HS bukhari:5376|the Prophet told the boy Umar ibn Abi Salamah to mention the name of Allah, eat with his right hand, and eat from what is nearer to him}.
""",
  review='Scholar review needed: the forgiveness line in Tirmidhi is as stated in the report.')
