# Knowledge pack C (20 Nov 2026): concepts, qualities, Qur'an stories and prayer du'as found
# missing by a second 150-question probe. Hadith are read against the corpus by build.py.
# Where the Qur'an is cited without quoted words the answer only paraphrases the verse's subject.

E('ihsan-meaning',
  m=[r'\b(?:what is|whats|define|meaning of|explain) (?:ihsan|ihsaan|excellence in faith)\b', r'\b(?:ihsan|ihsaan)\b.*\b(?:mean|hadith|jibril|gabriel|worship)\b', r'\bworship allah as if you (?:see|saw) (?:him|allah)\b'],
  topic='ihsan',
  text="""
Ihsan means doing good with excellence, and in worship it means awareness that Allah sees you. In the hadith of Gabriel, Abu Hurayrah reported that the angel asked the Prophet ﷺ about Ihsan, and he answered: {HS bukhari:50|to worship Allah as if you see Him, and if you cannot achieve this state, then to know that He sees you}.

In the same hadith Gabriel asked about faith, which the Prophet ﷺ described as belief in Allah, His angels, the meeting with Him, His messengers and the resurrection, and about Islam, which he described as worshipping Allah alone, prayer, zakat and fasting Ramadan.
""",
  review='Scholar review needed: the first sentence is the app\'s short definition; the summary of the hadith stops at the answer on Ihsan.')

E('halal-haram-general',
  m=[r'^(?:what is|whats|define|meaning of|explain) (?:halal|haram|halal and haram|haram and halal)$', r'^what (?:does )?(?:halal|haram) mean$', r'\bhow (?:do|can) (?:i )?(?:know|tell) (?:if )?(?:something|it) is (?:halal|haram)\b', r'\bwhat (?:are|is) (?:the )?(?:doubtful|unclear|grey|gray) (?:matters|things|areas)\b', r'\bshubuhat\b'],
  topic='halal and haram',
  text="""
Halal means permitted and haram means forbidden. The Prophet ﷺ said, as reported by An-Nu'man ibn Bashir: {HS bukhari:52|the lawful is clear and the unlawful is clear, and in between are doubtful matters that most people do not know, so whoever avoids the doubtful has protected his religion and his honour}.

For particular cases such as food, money or a product, ask me about that case; I answer from the Qur'an, hadith and the scholars' views, and I do not rule on your own situation.
""",
  review='Scholar review needed: the summary stops before the shepherd example.')

E('bidah-innovation',
  m=[r'\b(?:what is|whats|define|meaning of|explain) (?:bidah|bidaah|bida a|bid ah|innovation in (?:islam|religion))\b', r'\b(?:bidah|bidaah|innovation)\b.*\b(?:islam|hadith|religion|sin|mawlid|good)\b', r'\bis (?:there|it) (?:a )?good (?:bidah|innovation)\b', r'\bevery innovation is (?:misguidance|error)\b'],
  topic='bid\'ah',
  text="""
Bid'ah means innovation. Aisha reported the Prophet ﷺ saying: {HS bukhari:2697|if somebody innovates something which is not in harmony with the principles of our religion, that thing is rejected}. And in his sermons, as Jabir reported, he said {HS muslim:867|the best of speech is the Book of Allah, the best guidance is the guidance of Muhammad, the most evil affairs are the innovations, and every innovation is error}.

Scholars differ on what counts. Some say every new religious practice is bid'ah; others divide innovations into good and bad. The difference is in how the words "every innovation" are understood, so I do not label a particular practice. For a specific one, ask a scholar of your school.
""",
  review='Scholar review needed: the last paragraph states the difference of opinion in general terms, with no named scholar.')

E('itikaf-seclusion',
  m=[r'\b(?:what is|whats|define|meaning of|explain) (?:itikaf|i tikaf|e tikaf|etikaf|itikaaf)\b', r'\b(?:itikaf|i tikaf|etikaf)\b.*\b(?:how|rules|conditions|last ten|days|nights|reward|woman|women)\b', r'\bhow (?:do|to|can) (?:i )?(?:do|perform|make|observe) (?:itikaf|i tikaf|etikaf)\b'],
  topic='itikaf',
  go=['/academy'],
  text="""
I'tikaf is staying in the masjid for worship for a period, usually in the last days of Ramadan. Ibn Umar reported: {HS bukhari:2025|Allah's Messenger ﷺ used to practise i'tikaf in the last ten days of the month of Ramadan}.

The Qur'an mentions it in the verses on fasting, where it speaks of those in i'tikaf in the masjids ({QR 2:187}).

The conditions (minimum time, leaving for needs, who may do it) differ between the schools, and I do not give one school's rules as the answer; ask a scholar of your school.
""",
  review='Scholar review needed: conditions are intentionally not stated; confirm.')

E('rahmah-mercy',
  m=[r'\b(?:what is|whats|define|meaning of|explain) (?:rahmah|rahma|mercy in islam|compassion in islam)\b', r'\b(?:mercy|compassion|merciful)\b.*\b(?:islam|hadith|prophet|quran|allah)\b', r'\b(?:be|being) merciful\b', r'\bar rahman\b.*\bmean\b'],
  topic='mercy',
  text="""
Rahmah is mercy. The Qur'an says Allah sent the Prophet ﷺ as a mercy to the worlds ({QR 21:107}).

Jarir reported the Prophet ﷺ saying: {HS bukhari:6013|he who is not merciful to others will not be treated mercifully}.

So mercy is both something Allah shows to people and something people are told to show one another.
""",
  review='Scholar review needed.')

E('adl-justice',
  m=[r'\b(?:what is|whats|define|meaning of|explain) (?:adl|justice|fairness)(?: in islam)?$', r'\b(?:justice|fairness|just)\b.*\b(?:islam|quran|allah|command)\b', r'\bbe just even (?:against|to)\b', r'\bwhat does islam say about justice\b'],
  topic='justice',
  text="""
Adl is justice. The Qur'an says Allah commands justice and doing good ({QR 16:90}), and tells believers to stand firmly for justice as witnesses to Allah, even against themselves or their parents or relatives ({QR 4:135}). It also says not to let hatred of a people lead you away from justice ({QR 5:8}).
""",
  review='Scholar review needed: the verses are paraphrased, not quoted.')

E('amanah-trust',
  m=[r'\b(?:what is|whats|define|meaning of|explain) (?:amanah|amana|trust in islam|a trust)\b', r'\b(?:amanah|amana)\b', r'\bkeep(?:ing)? (?:a )?(?:trust|promise|promises)\b.*\b(?:islam|quran|hadith)\b', r'\b(?:what does islam say about|islam on) (?:keeping )?(?:promises|trust|being trustworthy)\b'],
  topic='trust',
  text="""
Amanah is a trust: whatever someone puts in your care, and every duty you hold. The Qur'an says Allah commands you to return trusts to their owners ({QR 4:58}).

The Prophet ﷺ listed betrayal of trust among the signs of a hypocrite ({H bukhari:33}).
""",
  review='Scholar review needed.')

E('qadr-destiny',
  m=[r'\b(?:what is|whats|define|meaning of|explain) (?:qadr|qadar|qada|destiny|fate|predestination|taqdir)\b', r'\b(?:qadr|qadar|taqdir)\b.*\b(?:free will|choice|islam|belief|mean)\b', r'\bdo (?:we|humans|people) have free will\b', r'\bis (?:everything|my life) (?:written|predestined|destined)\b'],
  topic='qadr',
  text="""
Qadr is Allah's decree, one of the six articles of faith. The Qur'an says that everything has been created with a measure ({QR 54:49}), and that no disaster strikes the earth or yourselves except that it is in a record before it is brought into being ({QR 57:22}).

Muslim scholars hold that this does not remove human choice or responsibility: people are accountable for what they choose. That is the scholars' position in general terms; the sources do not settle every question about how the two fit, and I do not go beyond them.
""",
  review='Scholar review needed: the second paragraph states the mainstream scholarly position without a named scholar.')

E('ikhlas-sincerity',
  m=[r'\b(?:what is|whats|define|meaning of|explain) (?:ikhlas|ikhlaas|sincerity)(?: in islam)?\b', r'\bhow (?:to|do i|can i) (?:be|have|get|become) sincere\b', r'\b(?:sincerity|ikhlas)\b.*\b(?:allah|worship|deeds|actions|intention)\b'],
  x=[r'\b(?:surah|sura)\b'],
  topic='sincerity',
  text="""
Ikhlas is sincerity: doing worship purely for Allah. The Qur'an says people were only commanded to worship Allah, sincere to Him in religion ({QR 98:5}), and tells the Prophet ﷺ to worship Allah, making the religion sincerely His ({QR 39:2}).

The opposite is riya, doing a deed to be seen by people. Ask me about it if you want.
""",
  review='Scholar review needed.')

E('shaytan-iblis',
  m=[r'\b(?:what is|whats|who is|who was|tell me about|explain) (?:shaytan|shaitan|satan|iblis|the devil|devil)\b', r'\bwhy (?:did|does) (?:shaytan|iblis|satan) (?:refuse|hate|rebel|disobey)\b', r'\b(?:iblis|shaytan)\b.*\b(?:adam|jinn|angel|fire|created|refuse)\b'],
  x=[r'\b(?:dua|du a|protect\w*|refuge|waswas\w*|whisper\w*|haram)\b'],
  topic='Iblis and Shaytan',
  text="""
Iblis is the one who refused when Allah told the angels to prostrate to Adam. The Qur'an says he refused and was arrogant and became one of the disbelievers ({QR 2:34}), and that his reason was that he was made from fire while Adam was from clay ({QR 7:12}).

The Qur'an calls Shaytan a clear enemy to humankind ({QR 35:6}) and tells people to take him as an enemy. For what to say against his whispers, ask me for the du'a for protection.
""",
  review='Scholar review needed: whether Iblis was an angel or a jinn is a difference of opinion and is not stated here.')

E('shahid-martyr',
  m=[r'\b(?:what is|whats|define|meaning of|explain|who is) (?:a )?(?:shaheed|shahid|martyr|martyrdom)\b', r'\b(?:martyr|shaheed|shahid)\b.*\b(?:islam|quran|paradise|reward|dead)\b'],
  x=[r'\b(?:terror\w*|suicide|bomb\w*|attack)\b'],
  topic='shahid',
  text="""
Shahid means witness, and it is the word for a martyr. The Qur'an says not to think of those killed in the way of Allah as dead; they are alive with their Lord, provided for ({QR 3:169}).

I am not listing every kind of shahid or ruling on a particular case here; for that ask a scholar.
""",
  review='Scholar review needed: the kinds of shahid in the hadith are intentionally not listed.')

E('islamic-calendar',
  m=[r'\b(?:what is|whats|explain|tell me about) (?:the )?(?:islamic|hijri|muslim) (?:calendar|year|months)\b', r'\bhow many months (?:are )?(?:in|are there in) (?:the )?(?:islamic|hijri|lunar) (?:year|calendar)\b', r'\b(?:hijri|islamic) (?:calendar|year)\b.*\b(?:start|begin|count|moon)\b', r'\bwhen does the (?:islamic|hijri) (?:year|calendar) (?:start|begin)\b'],
  topic='the Islamic calendar',
  go=['/prayer'],
  text="""
The Islamic (Hijri) calendar is a lunar calendar of twelve months. The Qur'an says the number of months with Allah is twelve ({QR 9:36}), four of them sacred.

Years are counted from the Hijrah, the migration of the Prophet ﷺ to Madinah. A lunar year is about eleven days shorter than a solar year, so Ramadan and the other months move through the seasons. The first month is Muharram.
""",
  review='Scholar review needed: the counting from the Hijrah and the eleven-day figure are general facts with no hadith cited.')

E('people-of-the-cave',
  m=[r'\b(?:what is|whats|tell me|story of|who (?:are|were)|explain) (?:the )?(?:people|companions|youths?|young men|sleepers) of (?:the )?cave\b', r'\bashab (?:al )?kahf\b', r'\bseven sleepers\b', r'\b(?:story of|about) (?:the )?(?:cave|surah al kahf)\b'],
  topic='the People of the Cave',
  go=['/quran'],
  text="""
The story is told in Surah Al-Kahf, which begins by saying the youths of the cave were one of Allah's wonders ({QR 18:9}). In outline: some young believers fled their people to protect their faith, took refuge in a cave, and Allah caused them to sleep for years ({QR 18:10-12}). When they woke, they thought they had slept only a day or part of one ({QR 18:19}), and the people of the town found out about them.

The Qur'an notes that people disagree about their number, and says Allah knows best ({QR 18:22}). The lesson stressed is to rely on Allah and keep faith in hardship.
""",
  review='Scholar review needed: the outline follows the verses cited.')

E('dhul-qarnayn',
  m=[r'\b(?:who (?:is|was)|tell me about|story of|what is the story of|explain) (?:dhul|dhu al|zul|zul al|dhu l) ?qarnayn\b', r'\b(?:dhul|zul|dhu) ?qarnayn\b', r'\balexander the great\b.*\b(?:quran|islam)\b'],
  topic='Dhul-Qarnayn',
  go=['/quran'],
  text="""
Dhul-Qarnayn is a righteous ruler whose story is in Surah Al-Kahf ({QR 18:83}). The Qur'an says Allah gave him power on earth and means to everything ({QR 18:84}), and that he travelled to the west and the east. He met a people who asked for protection from Ya'juj and Ma'juj, and he built a barrier against them ({QR 18:93-98}), then said it was a mercy from his Lord.

Who he was is a matter of difference among scholars, and I do not name him.
""",
  review='Scholar review needed: the identity of Dhul-Qarnayn is intentionally not stated.')

E('luqman-wisdom',
  m=[r'\b(?:who (?:is|was)|tell me about|story of|what is the story of|explain) luqman\b', r'\bluqman\b.*\b(?:wisdom|advice|son|surah)\b', r'\bsurah luqman\b', r'\bluqman s (?:advice|wisdom)\b'],
  topic='Luqman',
  go=['/quran'],
  text="""
Luqman is a man to whom Allah gave wisdom ({QR 31:12}), and the surah named after him records his advice to his son. He tells him not to associate anything with Allah, because shirk is a great wrong ({QR 31:13}); to establish prayer, enjoin good and forbid evil and be patient ({QR 31:17}); not to turn his cheek away from people in pride, and to be moderate in his walk and lower his voice ({QR 31:18-19}).
""",
  review='Scholar review needed: the advice is paraphrased from the verses cited.')

E('prophet-nuh',
  m=[r'\b(?:who (?:is|was)|tell me about|story of|what is the story of|explain) (?:prophet )?(?:nuh|noah|nooh)\b', r'\b(?:nuh|noah|nooh)\b.*\b(?:ark|flood|boat|ship|people|story|prophet)\b', r'\bsurah nuh\b'],
  topic='Prophet Nuh',
  go=['/quran'],
  text="""
Nuh called his people to worship Allah alone for a very long time. The Qur'an says he stayed among them a thousand years less fifty ({QR 29:14}), and Surah Nuh (surah 71) records how he called them night and day ({QR 71:5}). Allah told him to build the ship ({QR 11:37}), and the flood came ({QR 11:40}).

The surah named after him gives his du'a for his people and the believers.
""",
  review='Scholar review needed: the account follows the verses cited.')

E('prophet-ayyub',
  m=[r'\b(?:who (?:is|was)|tell me about|story of|what is the story of|explain) (?:prophet )?(?:ayyub|ayub)\b', r'\b(?:ayyub|ayub)\b.*\b(?:patience|illness|sickness|story|prophet|trial)\b'],
  topic='Prophet Ayyub',
  go=['/quran'],
  text="""
Ayyub is the Qur'an's example of patience in sickness and loss. He called to his Lord that harm had touched him and that He is the most merciful of the merciful ({QR 21:83}), and Allah answered, removed his harm and gave him his family and more like them ({QR 21:84}). Surah Sad also describes him as an excellent servant, one who constantly turned to Allah ({QR 38:44}).
""",
  review='Scholar review needed: details beyond the verses (the length or kind of his illness) are not stated.')

E('prophet-sulayman',
  m=[r'\b(?:who (?:is|was)|tell me about|story of|what is the story of|explain) (?:prophet )?(?:sulayman|suleiman|sulaiman|solomon)\b', r'\b(?:sulayman|suleiman|solomon)\b.*\b(?:jinn|birds|ants|wind|kingdom|queen|bilqis|sheba|story)\b', r'\bqueen of sheba\b|\bbilqis\b'],
  topic='Prophet Sulayman',
  go=['/quran'],
  text="""
Sulayman was a prophet and a king, the son of Dawud. The Qur'an says Allah gave him knowledge ({QR 27:15}) and that he was given the language of the birds ({QR 27:16}). His armies of jinn, men and birds were gathered before him ({QR 27:17}), and he heard an ant tell the others to enter their homes ({QR 27:18}). He also wrote to the queen of Saba, who came to believe ({QR 27:44}).

The surah says all of this was by Allah's favour, and Sulayman asked to be grateful for it ({QR 27:19}).
""",
  review='Scholar review needed: the account is limited to verses cited.')

E('prophet-dawud',
  m=[r'\b(?:who (?:is|was)|tell me about|story of|what is the story of|explain) (?:prophet )?(?:dawud|daud|dawood)\b', r'\b(?:dawud|dawood|prophet david)\b.*\b(?:psalms|zabur|goliath|jalut|iron|mountains|story)\b'],
  topic='Prophet Dawud',
  go=['/quran'],
  text="""
Dawud was a prophet and a king. The Qur'an says Allah gave him the Zabur ({QR 4:163}), that the mountains and birds joined him in glorifying Allah ({QR 38:18-19}), and that Allah made iron soft for him ({QR 34:10}). It also records that he killed Jalut (Goliath), and that Allah gave him kingdom and wisdom ({QR 2:251}).
""",
  review='Scholar review needed: the account is limited to verses cited.')

E('prophet-adam',
  m=[r'\b(?:who (?:is|was)|tell me about|story of|what is the story of|explain) (?:prophet )?(?:aadam)\b', r'\bprophet adam\b', r'\b(?:adam|aadam)\b.*\b(?:first man|created|clay|eve|hawwa|paradise|garden|tree|story)\b', r'\bwho was the first (?:man|human|person)\b'],
  topic='Prophet Adam',
  go=['/quran'],
  text="""
Adam is the first human being and a prophet. The Qur'an says Allah told the angels He would place a vicegerent on earth ({QR 2:30}), taught Adam the names ({QR 2:31}), and told the angels to prostrate to him; Iblis refused ({QR 2:34}). Adam and his wife were told to live in the Garden but not to approach one tree ({QR 2:35}); Shaytan made them slip, and they were sent down to the earth ({QR 2:36}). Adam then received words from his Lord and Allah accepted his repentance ({QR 2:37}).
""",
  review='Scholar review needed: the account is limited to verses cited; the name of the tree and the kind of the "tree" are not stated.')

E('opening-dua-prayer',
  m=[r'\b(?:what is|whats|what s) (?:the )?(?:opening|starting|first|istiftah|thana|sana) (?:dua|du a|supplication)\b', r'\bdua (?:of|for) (?:the )?(?:opening|istiftah|starting the prayer)\b', r'\bwhat (?:to|do i|should i) say (?:after|between) (?:the )?(?:takbir|takbeer|allahu akbar)\b', r'\bwhat (?:to|do i|should i) (?:say|recite) (?:at|in) (?:the )?(?:start|beginning) of (?:the )?(?:prayer|salah|salat)\b', r'\ballahumma ba ?id (?:bayni|baini)\b'],
  topic='opening du\'a of prayer',
  go=['/prayer'],
  text="""
Abu Hurayrah reported that he asked the Prophet ﷺ what he said in the pause between the takbir and the recitation, and the Prophet ﷺ answered: {HS bukhari:744|"O Allah, set me apart from my sins as You set the east and west apart from each other; O Allah, clean me from sins as a white garment is cleaned of dirt; O Allah, wash my sins with water, snow and hail"}.

In Arabic it begins: Allahumma ba'id bayni wa bayna khatayaya kama ba'adta baynal-mashriqi wal-maghrib. Other openings are reported too, and the schools differ on which they use; I do not pick one school's opening.
""",
  review='Scholar review needed: other openings and the schools\' preferences are stated in general terms only.')

E('dhikr-after-prayer',
  m=[r'\b(?:what (?:to|do i|should i) (?:say|recite|do)|dua|du a|dhikr|adhkar)\b.*\bafter (?:the |each )?(?:prayer|salah|salat|namaz|fard prayer)\b', r'\bafter (?:the |each )?(?:prayer|salah|salat)\b.*\b(?:say|recite|dhikr|tasbih|tasbeeh|33)\b', r'\b(?:33|thirty three)\b.*\b(?:subhanallah|alhamdulillah|allahu akbar)\b', r'\bwhat (?:is|are) the (?:dhikr|adhkar|tasbeeh) after (?:salah|prayer)\b'],
  topic='dhikr after prayer',
  go=['/adhkar', '/tasbeeh'],
  text="""
Abu Hurayrah reported that poor Companions complained that the wealthy had higher ranks because they gave more in charity. The Prophet ﷺ answered: {HS bukhari:843|say "Subhan Allah", "Alhamdulillah" and "Allahu Akbar" thirty-three times each after every obligatory prayer}.

The Tasbeeh counter in the app can count it. Different hadith give slightly different totals; I am giving the one cited here.
""",
  review='Scholar review needed: the note on other reports with different totals is stated in general terms.')

E('sujud-dua-closeness',
  m=[r'\b(?:what is|whats|what s) (?:the )?(?:dua|du a|supplication) (?:in|during) (?:sujud|sajda|sajdah|prostration)\b', r'\bwhat (?:to|do i|should i) (?:say|do|ask|recite) (?:in|during) (?:sujud|sajda|sajdah|prostration)\b', r'\b(?:can i|may i|should i) (?:make|do) (?:dua|du a) (?:in|during) (?:sujud|sajda|prostration)\b', r'\bhow (?:to|do i|can i) (?:get|become|be) (?:closer|close|near) (?:to )?allah\b', r'\bhow (?:do|can) i (?:gain|increase|build) (?:closeness|nearness) (?:to|with) allah\b'],
  topic='nearness to Allah',
  go=['/adhkar'],
  text="""
Abu Hurayrah reported the Prophet ﷺ saying: {HS muslim:482|the nearest a servant comes to his Lord is when he is prostrating himself, so make du'a in it}.

The Qur'an says the same: prostrate and draw near ({QR 96:19}). So sujud is a time to ask Allah in your own words, in whatever language you speak, as the hadith says to make du'a in it. For other ways to get closer, the Qur'an says Allah is near and answers when called ({QR 2:186}).
""",
  review='Scholar review needed: "in whatever language" is the scholars\' general view; the hadith does not specify.')

E('learn-teach-quran',
  m=[r'\bhow (?:to|do i|can i|should i) (?:memori[sz]e|memorise|hifz|learn by heart|revise)\b.*\b(?:quran|qur an|koran)\b', r'\bhow (?:to|do i|can i) (?:start|begin) (?:learning|memori[sz]ing|reading)\b.*\b(?:quran|qur an)\b', r'\b(?:best|how to) (?:way|method) (?:to )?(?:memori[sz]e|learn)\b.*\b(?:quran|qur an)\b', r'\bhow (?:to|do i|can i|should i) (?:read|recite) (?:the )?(?:quran|qur an)\b', r'\b(?:reward|virtue|benefit)\b.*\b(?:teach|teaching|learn|learning)\b.*\b(?:quran|qur an)\b'],
  x=[r'\b(?:without wudu|period|menstruat\w*|touch\w*|ruling|haram)\b'],
  topic='learning the Qur\'an',
  go=['/quran'],
  text="""
'Uthman reported the Prophet ﷺ saying: {HS bukhari:5027|the best among you are those who learn the Qur'an and teach it}.

On memorising, Abu Musa reported: {HS bukhari:5033|commit yourself to the Qur'an, for by Him in whose Hand is my soul, it is more prone to escape than a camel in its tether}. The Qur'an says to recite it slowly and distinctly ({QR 73:4}), and that Allah made it easy to remember ({QR 54:17}).

Practical points such as a daily portion, revision and a teacher are the scholars' and teachers' advice, not hadith; the Qur'an screen has the reader, and the daily portion guide is in the app.
""",
  review='Scholar review needed: the last paragraph is general study advice without a cited source.')

E('humility-forgiveness',
  m=[r'\bhow (?:to|do i|can i|should i) (?:be|become|stay|remain) humble\b', r'\b(?:what is|whats|define|meaning of|explain) (?:humility|tawadu|tawaadu)\b', r'\bhow (?:to|do i|can i|should i) forgive (?:someone|somebody|a person|them|him|her|people|others|my \w+)\b', r'\b(?:forgiving|forgive) (?:others|people|someone)\b.*\b(?:islam|quran|hadith|reward|allah)\b', r'\bhow to let go of (?:anger|grudges?|resentment)\b'],
  topic='humility and forgiving others',
  text="""
Abu Hurayrah reported the Prophet ﷺ saying: {HS muslim:2588|charity does not decrease wealth, no one forgives another except that Allah increases his honour, and no one humbles himself for Allah except that Allah raises his status}.

The Qur'an asks believers to pardon and overlook, and says: would you not love that Allah forgive you ({QR 24:22})? It also praises those who restrain anger and pardon people ({QR 3:134}).
""",
  review='Scholar review needed: the summary covers all three statements in the report.')

E('women-in-the-masjid',
  m=[r'\b(?:can|may|is it allowed for|are) (?:a )?(?:women|woman|females?|ladies|girls?) (?:allowed )?(?:to )?(?:go|pray|attend|come|enter|visit)\b.*\b(?:mosque|masjid)\b', r'\b(?:women|woman|females?|ladies)\b.*\b(?:mosque|masjid)\b.*\b(?:allowed|permitted|pray|prayer|attend|jamaah|jummah|jumuah)\b', r'\bwomen s? (?:section|area|prayer)\b.*\b(?:mosque|masjid)\b'],
  x=[r'\b(?:period|menstruat\w*|imam|lead|leader)\b'],
  topic='women in the masjid',
  go=['/huda/guide?id=huda-mosque'],
  text="""
Ibn Umar reported that the Prophet ﷺ said: {HS bukhari:900|do not stop Allah's women from going to Allah's mosques}.

So women may go to the masjid. The scholars discuss conditions such as safety and dress, and say that for women the prayer at home is also valid; the schools differ in how they weigh these. I do not give a ruling on a particular situation.
""",
  review='Scholar review needed: the second paragraph summarises the scholars\' discussion in general terms.')

E('ummah-meaning',
  m=[r'\b(?:what is|whats|define|meaning of|explain) (?:the )?(?:ummah|umma|ummah of muhammad|muslim ummah)\b', r'\b(?:ummah|umma)\b.*\b(?:mean|meaning|brotherhood|one body|united)\b', r'\bwhat does (?:the )?ummah mean\b'],
  topic='the ummah',
  text="""
The ummah is the community of Muslims worldwide. The Qur'an says: you are the best community brought out for mankind, enjoining what is right and forbidding what is wrong and believing in Allah ({QR 3:110}), and: this ummah of yours is one ummah, and I am your Lord, so worship Me ({QR 21:92}).
""",
  review='Scholar review needed.')

E('fatwa-imam-mufti',
  m=[r'\b(?:what is|whats|define|meaning of|explain) (?:a |an |the )?(?:fatwa|fatawa|mufti|imam|sheikh|shaykh|alim|scholar|ulama)\b', r'\bdifference between (?:a |an )?(?:imam|mufti|sheikh|shaykh|scholar|alim)\b', r'\bwho (?:is|are) (?:the )?(?:mufti|imam|ulama|scholars)\b', r'\bwhat is the role of (?:an |the )?(?:imam|mufti|scholar)\b'],
  topic='fatwa, imam, mufti',
  text="""
A fatwa is a scholar's answer to a question about Islamic law. A mufti is the scholar qualified to give fatwas. An imam, in a masjid, is the person who leads the prayer, and often teaches and advises the community; the word is also used for the great scholars of the schools. A shaykh or alim is a person of religious knowledge.

A fatwa is an opinion given on a case, not a revelation, and it can differ between scholars and schools. That is why I give the range of views and do not issue fatwas.
""",
  review='Scholar review needed: general definitions with no hadith cited.')

E('fiqh-ijma-qiyas',
  m=[r'\b(?:what is|whats|define|meaning of|explain) (?:fiqh|ijma|ijmaa|qiyas|usul al fiqh|usul|ijtihad)\b', r'\bsources of (?:islamic )?(?:law|fiqh|sharia|shariah)\b', r'\bhow (?:do|did) scholars (?:decide|derive|get) (?:rulings|laws)\b', r'\bwhere does (?:islamic law|sharia|shariah) come from\b'],
  topic='sources of Islamic law',
  go=['/huda/guide?id=huda-madhhab-overview'],
  text="""
Fiqh is the scholars' understanding of Islamic law, drawn from the sources. The agreed primary sources are the Qur'an and the Sunnah. Beyond them, scholars use ijma (the agreement of scholars on a ruling) and qiyas (extending a ruling to a new case with the same reason). Ijtihad is the scholar's effort to reach a ruling from the sources.

The schools weigh these sources differently, which is why they sometimes differ. The app's guide on the four schools explains how.
""",
  review='Scholar review needed: general definitions of usul, no hadith cited; the schools differ in how they weigh secondary sources.')
