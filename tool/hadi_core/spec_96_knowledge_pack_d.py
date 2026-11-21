# Knowledge pack D (20 Nov 2026): Qur'an stories, rewards, ethics, du'as and Qur'an facts found
# missing by a third 150-question probe. Hadith are read against the corpus by build.py.
# Contested rulings (medical ethics, insurance, etc.) are deliberately not answered here.

E('story-elephant',
  m=[r'\b(?:story|tale) of (?:the )?(?:elephant|people of the elephant|abraha|abrahah)\b', r'\b(?:what is|tell me about|explain) (?:surah|sura|surat) (?:al )?fil\b', r'\bsurah (?:al )?fil\b', r'\b(?:year of the elephant|ashab (?:al )?fil|people of the elephant)\b'],
  topic='the People of the Elephant',
  go=['/quran'],
  text="""
Surah Al-Fil (surah 105) tells of the people of the elephant. It asks whether you have not seen how your Lord dealt with them ({QR 105:1}): He made their plan go astray ({QR 105:2}), sent flocks of birds against them ({QR 105:3}) that struck them with stones of baked clay ({QR 105:4}), and left them like eaten straw ({QR 105:5}).

The surah does not name the army or its commander. Scholars say it refers to the army that came against the Ka'bah in the year the Prophet ﷺ was born; that is the scholars' reading, not a statement of the surah itself.
""",
  review='Scholar review needed: the last paragraph states the scholars\' reading without a named source.')

E('story-qarun',
  m=[r'\b(?:story|tale) of (?:qarun|qaroon|korah|karun)\b', r'\b(?:who (?:is|was)|tell me about) (?:qarun|qaroon|karun)\b', r'\b(?:qarun|qaroon|karun)\b.*\b(?:wealth|treasure|earth|swallowed|arrogant)\b'],
  topic='Qarun',
  go=['/quran'],
  text="""
Qarun is the Qur'an's example of arrogance in wealth. He was from the people of Musa and was given treasures so great that their keys were a burden to a group of strong men ({QR 28:76}). His people told him not to exult, and to seek the home of the Hereafter with what Allah gave him ({QR 28:77}). He claimed the wealth came by his own knowledge ({QR 28:78}). Then Allah caused the earth to swallow him and his home ({QR 28:81}).
""",
  review='Scholar review needed.')

E('story-firaun',
  m=[r'\b(?:story|tale) of (?:firaun|fir aun|pharaoh|firawn|fir awn)\b', r'\b(?:who (?:is|was)|tell me about) (?:firaun|fir aun|pharaoh|firawn)\b', r'\b(?:firaun|pharaoh)\b.*\b(?:drown\w*|sea|body|mummy|arrogant|lord most high)\b'],
  topic='Fir\'awn (Pharaoh)',
  go=['/quran'],
  text="""
Fir'awn was the tyrant ruler of Egypt in the time of Musa. The Qur'an says he exalted himself in the land and divided its people, weakening a group of them ({QR 28:4}), and that he claimed to be their lord, the most high ({QR 79:24}). He pursued Musa and the Children of Israel and was drowned; when drowning he said he believed, but it was too late ({QR 10:90-91}). The Qur'an says his body would be preserved as a sign for those after him ({QR 10:92}).
""",
  review='Scholar review needed: the verses are paraphrased.')

E('story-talut-jalut',
  m=[r'\b(?:story|tale) of (?:talut|taloot|saul|jalut|jaloot|goliath)\b', r'\b(?:who (?:is|was)|tell me about) (?:talut|taloot|jalut|jaloot|goliath)\b', r'\b(?:talut|taloot|jalut|goliath)\b'],
  topic='Talut and Jalut',
  go=['/quran'],
  text="""
The story is in Surah Al-Baqarah. The leaders of the Children of Israel asked their prophet for a king to fight with ({QR 2:246}), and he told them Allah had appointed Talut ({QR 2:247}). As they marched, Talut tested them at a river, and those who drank more than a sip did not stay with him ({QR 2:249}). The believers who were sure they would meet Allah said how often a small group had beaten a large one by Allah's permission ({QR 2:249}). Dawud killed Jalut (Goliath) and Allah gave him kingdom and wisdom ({QR 2:251}).
""",
  review='Scholar review needed.')

E('story-ismail',
  m=[r'\b(?:story|tale) of (?:prophet )?(?:ismail|ishmael|ismael|ismaeel)\b', r'\b(?:who (?:is|was)|tell me about) (?:prophet )?(?:ismail|ishmael|ismael|ismaeel)\b', r'\b(?:ismail|ishmael)\b.*\b(?:sacrific\w*|ibrahim|abraham|kaaba|ka bah|dream|knife|ram)\b', r'\bwhy do muslims sacrifice\b.*\b(?:ibrahim|abraham|eid)\b'],
  topic='Prophet Ismail',
  go=['/quran'],
  text="""
Ismail is the son of Ibrahim, and the Qur'an describes him as true to his promise, a messenger and prophet ({QR 19:54}). With his father he raised the foundations of the Ka'bah ({QR 2:127}).

Surah As-Saffat tells that Ibrahim saw in a dream that he was to sacrifice his son, and the son said to do what he was commanded and that he would be among the patient ({QR 37:102}). When both submitted, Allah called to Ibrahim that he had fulfilled the vision ({QR 37:104-105}) and ransomed the son with a great sacrifice ({QR 37:107}). The Eid al-Adha sacrifice remembers this.

The Qur'an does not name the son in that passage; scholars differ on whether he was Ismail or Ishaq, and many hold he was Ismail. That is a difference of opinion and I do not decide it here.
""",
  review='Scholar review needed: the last paragraph is stated in general terms; confirm.')

E('story-lut',
  m=[r'\b(?:story|tale) of (?:prophet )?(?:lut|lot|loot)\b', r'\b(?:who (?:is|was)|tell me about) (?:prophet )?(?:lut|loot)\b', r'\b(?:lut|loot)\b.*\b(?:people|sodom|city|cities|wife|punish\w*|destroyed)\b'],
  topic='Prophet Lut',
  go=['/quran'],
  text="""
Lut was sent to a people who had gone astray. The Qur'an says he asked them why they committed an indecency that no one in the worlds had committed before them ({QR 7:80}), and that they only answered by saying to drive his family out of their town ({QR 7:82}). Allah saved Lut and his family except his wife, who was among those who stayed behind ({QR 7:83}). The punishment was a rain upon them ({QR 7:84}), and the cities were overturned ({QR 11:82}).

The Qur'an also notes that his wife was unfaithful to him in faith ({QR 66:10}).
""",
  review='Scholar review needed: the Qur\'an describes the sin in general terms; the answer follows it and adds nothing.')

E('story-salih-thamud',
  m=[r'\b(?:story|tale) of (?:prophet )?(?:salih|saleh|thamud|samud)\b', r'\b(?:who (?:is|was)|tell me about) (?:prophet )?(?:salih|saleh)\b', r'\b(?:salih|saleh|thamud)\b.*\b(?:camel|she camel|people|punish\w*|destroyed|tribe)\b'],
  topic='Prophet Salih and Thamud',
  go=['/quran'],
  text="""
Salih was sent to the people of Thamud, who were told to worship Allah alone and that a she-camel of Allah was a sign for them ({QR 7:73}). They were told to let her graze on Allah's land and not to harm her ({QR 7:73}). They disobeyed and slaughtered the camel, challenging Salih to bring on what he threatened ({QR 7:77}). Then the earthquake seized them, and they lay lifeless in their homes ({QR 7:78}).
""",
  review='Scholar review needed.')

E('story-hud-ad',
  m=[r'\b(?:story|tale) of (?:prophet )?(?:hud|hood|ad|aad|people of ad|people of aad)\b', r'\b(?:who (?:is|was)|tell me about) (?:prophet )?(?:hud|hood)\b', r'\b(?:hud|prophet hud)\b.*\b(?:ad|aad|wind|people)\b', r'\b(?:people of )?(?:ad|aad)\b.*\b(?:hud|wind|tribe|punish\w*|destroyed|iram)\b'],
  topic='Prophet Hud and the people of Ad',
  go=['/quran'],
  text="""
Hud was sent to the people of Ad, who were told to worship Allah alone ({QR 7:65}). They rejected him, and the Qur'an says Allah rescued Hud and those with him and cut off the roots of those who denied ({QR 7:72}). Surah Al-Haqqah says Ad were destroyed by a furious roaring wind ({QR 69:6}).
""",
  review='Scholar review needed.')

E('story-shuayb-madyan',
  m=[r'\b(?:story|tale) of (?:prophet )?(?:shuayb|shuaib|shoaib|jethro|madyan|midian)\b', r'\b(?:who (?:is|was)|tell me about) (?:prophet )?(?:shuayb|shuaib|shoaib)\b', r'\b(?:shuayb|shuaib)\b.*\b(?:madyan|midian|scales|measure|people|people of)\b'],
  topic='Prophet Shu\'ayb and Madyan',
  go=['/quran'],
  text="""
Shu'ayb was sent to Madyan. He called them to worship Allah alone and told them to give full measure and weight and not to cheat people of their things ({QR 7:85}). They rejected him, and the earthquake seized them so that they lay lifeless in their homes ({QR 7:91}).

The story is one of the clearest Qur'anic lessons on honesty in business.
""",
  review='Scholar review needed.')

E('story-zakariyya-yahya',
  m=[r'\b(?:story|tale) of (?:prophet )?(?:zakariyya|zakariya|zechariah|zakaria|yahya|john the baptist)\b', r'\b(?:who (?:is|was)|tell me about) (?:prophet )?(?:zakariyya|zakariya|zechariah|yahya)\b', r'\b(?:zakariyya|zakariya|yahya)\b.*\b(?:dua|du a|son|child|old age|maryam|elderly)\b'],
  topic='Zakariyya and Yahya',
  go=['/quran'],
  text="""
Zakariyya was an elderly prophet who called to his Lord secretly ({QR 19:3}), saying his bones had grown feeble and asking for a successor ({QR 19:4-5}). He was given the good news of a son named Yahya ({QR 19:7}). Zakariyya was surprised, since his wife was barren and he was old ({QR 19:8}), but it was said that this is easy for Allah ({QR 19:9}).

Of Yahya the Qur'an says he was given wisdom as a child ({QR 19:12}), was kind and pure and devout, and was not arrogant or disobedient ({QR 19:13-14}). Peace was upon him the day he was born, the day he dies and the day he is raised ({QR 19:15}).
""",
  review='Scholar review needed.')

E('prophet-idris',
  m=[r'\b(?:who (?:is|was)|tell me about|story of) (?:prophet )?(?:idris|enoch|idrees)\b', r'\b(?:idris|idrees)\b.*\b(?:prophet|raised|high|place)\b'],
  topic='Prophet Idris',
  go=['/quran'],
  text="""
Idris is named twice in the Qur'an. In Surah Maryam he is described as a man of truth and a prophet, and Allah says He raised him to a high station ({QR 19:56-57}). In Surah Al-Anbiya he is listed among those who were patient ({QR 21:85}).

The Qur'an gives little else about him, and I do not give more than it says.
""",
  review='Scholar review needed.')

E('ashab-ukhdud',
  m=[r'\b(?:story|tale) of (?:the )?(?:people of the (?:trench|ditch|pit)|ashab (?:al|ul) ?ukhdud|boy and the king|the boy and the king)\b', r'\bukhdud\b', r'\bsurah (?:al )?buruj\b', r'\bpeople of the (?:ditch|trench|pit)\b'],
  topic='the People of the Trench',
  go=['/quran'],
  text="""
Surah Al-Buruj (surah 85) mentions the people of the trench who kindled a fire ({QR 85:4-5}) and sat by it ({QR 85:6}), watching what they did to the believers ({QR 85:7}). They had no complaint against them except that they believed in Allah, the Almighty, the Praiseworthy ({QR 85:8}).

The fuller story of the boy and the king is in a hadith in Sahih Muslim; I have not read it here in full, so I do not give that version.
""",
  review='Scholar review needed: the full story is intentionally left to the hadith.')

E('sabbath-breakers',
  m=[r'\b(?:story|tale) of (?:the )?(?:sabbath|saturday) (?:breakers|people)\b', r'\bpeople of (?:the )?(?:sabbath|saturday)\b', r'\bashab (?:al )?sabt\b', r'\b(?:people|those) (?:who )?(?:turned into|became) (?:apes|monkeys)\b'],
  topic='the Sabbath-breakers',
  go=['/quran'],
  text="""
Surah Al-A'raf mentions a town by the sea whose people broke the Sabbath: the fish came to them openly on the day they were not to fish and not on other days, as a test for their disobedience ({QR 7:163}). A group of them asked why advise a people Allah will destroy, and the advisers said it was to be free of blame before their Lord ({QR 7:164}). When they persisted, the Qur'an says Allah said to them: be despised apes ({QR 7:166}).

Scholars differ on whether this was literal or figurative; I do not decide it.
""",
  review='Scholar review needed: the difference of opinion is stated in general terms.')

E('moon-splitting',
  m=[r'\b(?:the )?(?:splitting|split|splitting of) (?:of )?(?:the )?moon\b', r'\bmoon (?:was )?split\b', r'\b(?:shaqq|shaqq al) ?qamar\b', r'\bsurah (?:al )?qamar\b'],
  topic='the splitting of the moon',
  go=['/quran'],
  text="""
Surah Al-Qamar begins: the Hour has come near and the moon has split ({QR 54:1}). Ibn Mas'ud reported: {HS bukhari:3636|during the lifetime of the Prophet ﷺ the moon was split into two parts, and the Prophet said "Bear witness to this"}.

The hadith says this happened in the Prophet's lifetime. I do not add detail beyond what the report gives.
""",
  review='Scholar review needed: the Qur\'anic verse has been read by some scholars as an event in the Prophet\'s lifetime and by others as a sign of the end; the answer states only the hadith.')

E('quran-preserved',
  m=[r'\b(?:is|was|has) the (?:quran|qur an|koran) (?:been )?(?:preserved|changed|corrupted|altered|original|unchanged)\b', r'\b(?:how|why) (?:is|was) the (?:quran|qur an) (?:preserved|protected)\b', r'\b(?:preservation|protection) of the (?:quran|qur an)\b', r'\bhas the (?:quran|qur an) (?:ever )?changed\b'],
  topic='preservation of the Qur\'an',
  go=['/quran'],
  text="""
The Qur'an says: indeed We sent down the Reminder, and indeed We will be its guardian ({QR 15:9}).

Muslims point to two means: memorisation, handed down from person to person, and writing. Zayd ibn Thabit reported that after many reciters were killed at the Battle of Yamama, Umar feared that much of the Qur'an would be lost, and Abu Bakr asked Zayd to collect it ({HS bukhari:4986|Abu Bakr sent for Zayd after the people of Yamama were killed, and Umar told Abu Bakr that many reciters had died and he feared more would die and much of the Qur'an be lost, so Zayd was asked to collect it}).

The details of the later compilation under Uthman are in other reports; I am not summarising them here.
""",
  review='Scholar review needed: the summary stops at the request to collect; later steps are intentionally not covered.')

E('quran-miracle',
  m=[r'\b(?:what is|whats|how is|why is) the (?:quran|qur an|koran)(?:s| a| is)? (?:a )?(?:miracle|miraculous)\b', r'\b(?:quran|qur an)\b.*\b(?:miracle|miraculous|challenge|inimitable|ijaz)\b', r'\bwhat is (?:the )?(?:ijaz|challenge of the quran)\b', r'\bproof (?:that )?(?:the )?(?:quran|qur an) is (?:from allah|true|divine)\b'],
  topic='the Qur\'an\'s challenge',
  go=['/quran'],
  text="""
The Qur'an challenges people to produce something like it. It says that if the people and the jinn gathered to produce the like of this Qur'an they could not, even if they helped one another ({QR 17:88}), and it challenges those in doubt to bring a surah like it ({QR 2:23}).

Scholars discuss its language, its message and its preservation as parts of this challenge. That is the scholars' general discussion, not something I can summarise further without a named source.
""",
  review='Scholar review needed: the last sentence refers to general scholarly discussion without a named source.')

E('makki-madani',
  m=[r'\b(?:what is|whats|difference between|meaning of|explain) (?:a )?(?:makki|makkan|madani|madinan|meccan|medinan)\b', r'\b(?:makki|makkan|meccan)\b.*\b(?:madani|madinan|medinan)\b', r'\bwhich surahs? (?:are|were) (?:makki|makkan|madani|madinan|meccan|medinan)\b'],
  topic='Makki and Madani surahs',
  go=['/quran'],
  text="""
Makki surahs were revealed before the Hijrah and Madani surahs after it. Scholars use the labels to group surahs: the Makki ones are often shorter and focus on belief, the afterlife and the call to worship Allah alone, while the Madani ones often include rules for the community. This grouping is the scholars' classification, and some surahs have verses of both.

The Surah list in the app marks where each surah was revealed.
""",
  review='Scholar review needed: general definitions with no hadith cited.')

E('disjointed-letters',
  m=[r'\b(?:what are|what is|meaning of|explain) (?:the )?(?:disjointed|isolated|mysterious|separate|huruf muqatta ?at|muqattaat|muqatta ?at)\b', r'\b(?:alif|alif lam|alif lam mim|ha mim|ya sin|ya seen)\b.*\b(?:mean|meaning|letters)\b', r'\bwhat does (?:alif|alif lam mim|ya sin|ha mim|nun|qaf) mean\b', r'\bletters (?:at|in) the (?:start|beginning) of (?:some )?surahs\b'],
  topic='the disjointed letters',
  go=['/quran'],
  text="""
Some surahs begin with separate letters, such as Alif Lam Mim at the start of Surah Al-Baqarah ({QR 2:1}). Scholars have given several explanations of them, and many say that their meaning is known to Allah. I do not choose one explanation, and the Qur'an itself does not explain them.
""",
  review='Scholar review needed: the statement about scholars\' explanations is general; confirm.')

E('tajweed-meaning',
  m=[r'\b(?:what is|whats|define|meaning of|explain) (?:tajweed|tajwid)\b', r'\bis (?:tajweed|tajwid) (?:obligatory|required|fard|wajib|necessary|important)\b', r'\bwhy (?:is|do i need|should i learn) tajweed\b', r'\bhow (?:to|do i|can i) learn tajweed\b'],
  x=[r'\b(?:haram|ruling)\b'],
  topic='tajweed',
  go=['/quran'],
  text="""
Tajweed is the set of rules for reciting the Qur'an correctly: giving each letter its proper sound and each rule of lengthening, stopping and joining its due. The Qur'an tells you to recite it slowly and distinctly ({QR 73:4}).

How much tajweed is required of every Muslim is discussed by scholars, and I do not give a ruling on it. The best way to learn is with a teacher.
""",
  review='Scholar review needed: the definition is general; the discussion on obligation is left to scholars.')

E('names-of-allah',
  m=[r'\b(?:what are|tell me|list|give me|how many) (?:the )?(?:names of allah|99 names|ninety nine names|asma ul husna|asma al husna|beautiful names)\b', r'\b(?:99|ninety nine) names\b', r'\basma (?:ul|al) ?husna\b', r'\bhow many names (?:does|of) allah\b'],
  topic='the names of Allah',
  go=['/games/names99'],
  text="""
The Qur'an says: to Allah belong the best names, so call on Him by them ({QR 7:180}). Abu Hurayrah reported the Prophet ﷺ saying: {HS bukhari:2736|Allah has ninety-nine names, one hundred minus one, and whoever knows them will go to Paradise}.

The hadith does not say Allah has only ninety-nine names; the number is the ones whose knowledge brings the reward. The Names of Allah game in the app has all ninety-nine.
""",
  review='Scholar review needed: the second paragraph states the usual scholarly reading in general terms.')

E('what-allah-loves',
  m=[r'\b(?:what|who) does allah love\b', r'\bwho (?:does|do) (?:you think )?allah love\b', r'\bthose whom allah loves\b', r'\b(?:allah loves|allah s love)\b.*\b(?:who|whom|what|those)\b', r'\bhow (?:to|do i|can i) (?:get|earn|win|gain) (?:allah s|the love of) (?:allah|love)\b'],
  topic='whom Allah loves',
  text="""
The Qur'an names whom Allah loves. He loves those who do good ({QR 2:195}), those who repent and those who purify themselves ({QR 2:222}), those who are conscious of Him ({QR 3:76}), the patient ({QR 3:146}), those who rely on Him ({QR 3:159}), and those who act justly ({QR 5:42}).

So the way to His love is through these qualities: doing good, repenting, patience, trust in Him and justice.
""",
  review='Scholar review needed: the last sentence is the app\'s summary of the verses.')

E('what-allah-dislikes',
  m=[r'\b(?:what|who) does allah (?:hate|dislike)\b', r'\bwhat (?:are the things|things) allah (?:hates|dislikes)\b', r'\bwho (?:does|do) allah (?:hate|dislike|not love)\b', r'\bthose (?:whom )?allah does not love\b'],
  topic='whom Allah does not love',
  text="""
The Qur'an says Allah does not love those who transgress ({QR 2:190}), the arrogant and boastful ({QR 4:36}), those who cause corruption ({QR 2:205}), and the wasteful ({QR 7:31}).

So these are the qualities to avoid: transgression, arrogance, corruption and waste.
""",
  review='Scholar review needed: the last sentence is the app\'s summary of the verses.')

E('major-sins',
  m=[r'\b(?:what are|list|name|tell me) (?:the )?(?:major sins|great sins|big sins|kabair|kaba ir|kabaair|seven (?:major|great|deadly) sins)\b', r'\b(?:major|great|big|biggest) sins? (?:in|of) islam\b', r'\bwhat is the biggest sin\b', r'\bseven (?:destructive|deadly) sins?\b'],
  topic='major sins',
  text="""
Abu Hurayrah reported the Prophet ﷺ saying: {HS bukhari:2766|avoid the seven great destructive sins: joining others in worship with Allah, sorcery, killing a life Allah has forbidden without a just cause, taking riba, taking an orphan's wealth, fleeing from the battlefield, and accusing chaste women}.

Abu Bakrah reported he said the biggest of the great sins are: {HS bukhari:5976|joining partners with Allah and being undutiful to parents, and a forged statement and false witness}.

These lists are not the only places the major sins are named; scholars have collected more. I give these two lists only.
""",
  review='Scholar review needed: the summaries stop at the items named; the last sentence is general.')

E('lying-in-islam',
  m=[r'\b(?:what is|whats|ruling on|rules? on|islam on|islam say about|what does islam say about) (?:telling )?(?:lies|lying|a lie|white lies?)\b', r'\bis (?:it )?(?:ok|okay|allowed|permissible|halal|haram) to lie\b', r'\bcan (?:i|you|muslims?) lie\b', r'\bis lying (?:a sin|haram|allowed)\b', r'\bwhen is lying allowed\b'],
  topic='lying',
  text="""
Lying is a sin in Islam. Abdullah ibn Mas'ud reported the Prophet ﷺ saying: {HS bukhari:6094|truthfulness leads to righteousness and righteousness leads to Paradise, while falsehood leads to wickedness and wickedness leads to the Fire}.

The hadith in Sahih Muslim 2605 adds: {HS muslim:2605|a liar is not one who tries to bring reconciliation among people and speaks good or conveys good}. In that narration a transmitter notes that exemptions were mentioned for war, reconciliation between people, and between spouses. Scholars discuss what these cover and how far they go, and I do not give a ruling on a particular case.
""",
  review='Scholar review needed: the closing explanation is a narrator\'s comment; scholars differ on its scope.')

E('cheating-trade',
  m=[r'\b(?:what is|whats|ruling on|islam on|islam say about|what does islam say about) (?:cheating|fraud|deception|dishonesty)\b', r'\bis (?:it )?(?:cheating|fraud|deceiving|deception) (?:haram|allowed|a sin)\b', r'\b(?:honesty|honest) in (?:trade|business|selling|buying)\b', r'\b(?:business|trade|trading|selling) (?:ethics|honesty)\b', r'\b(?:islamic|muslim) business ethics\b'],
  x=[r'\b(?:husband|wife|exam|test)\b'],
  topic='honesty in business',
  text="""
The Prophet ﷺ said, as Abu Hurayrah reported: {HS muslim:101|he who acted dishonestly towards us is not of us}.

Hakim ibn Hizam reported about trade: {HS bukhari:2079|if both parties speak the truth and describe the defects and qualities of the goods, they will be blessed in their transaction, and if they tell lies or hide something, the blessing will be lost}.

The Qur'an also tells believers to give full measure and weight ({QR 6:152}).
""",
  review='Scholar review needed: summary stops at the quoted lines.')

E('hoarding-bribery',
  m=[r'\b(?:what is|whats|ruling on|islam on|islam say about|what does islam say about) (?:hoarding|bribery|bribes?|corruption)\b', r'\bis (?:it )?(?:hoarding|bribery|bribing|taking bribes?|paying bribes?) (?:haram|allowed|a sin|permitted)\b', r'\b(?:hoarding|bribe|bribery)\b.*\b(?:hadith|islam|islamic|prophet)\b'],
  topic='hoarding and bribery',
  text="""
On hoarding, Ma'mar reported the Prophet ﷺ saying: {HS muslim:1605|he who hoards is a sinner}. Scholars discuss what this covers, namely holding back basic needs to raise their price, and I do not extend it to a particular case.

On bribery, Abdullah ibn Amr reported: {HS abudawud:3580|the Messenger of Allah ﷺ cursed the one who gives a bribe and the one who takes it}.
""",
  review='Scholar review needed: the explanation of the scope of hoarding is the scholars\' discussion in general terms.')

E('employee-rights',
  m=[r'\b(?:what are|what is|rights of) (?:the )?(?:rights of )?(?:an |the )?(?:employee|employees|worker|workers|labou?rer|labou?rers|staff)\b', r'\b(?:islam|islamic|hadith|prophet)\b.*\b(?:wages|paying (?:workers|employees)|employer|employee)\b', r'\bhow (?:should|to) (?:i|an employer) treat (?:an |my )?(?:employee|employees|workers?)\b', r'\bis it (?:haram|a sin) to (?:not pay|withhold) (?:wages|salary)\b'],
  topic='rights of workers',
  text="""
Abu Hurayrah reported that the Prophet ﷺ said Allah says: {HS bukhari:2227|I will be against three on the Day of Resurrection: one who makes a covenant in My name and betrays it, one who sells a free person and eats the price, and one who hires a labourer, gets the full work from him and does not pay him his wages}.

So paying a worker what was agreed is a serious right. Disputes about particular contracts are for a scholar or a court.
""",
  review='Scholar review needed: the second paragraph is a general conclusion from the hadith.')

E('orphan-sponsorship',
  m=[r'\b(?:what is|whats|reward for|reward of|virtue of|benefit of|islam on|islam say about) (?:sponsoring|looking after|caring for|kafalah|kafala|supporting|helping) (?:an |the )?(?:orphan|orphans)\b', r'\b(?:orphan|orphans)\b.*\b(?:reward|paradise|sponsor|sponsorship|hadith|islam|care)\b', r'\b(?:kafalah|kafala)\b'],
  topic='caring for orphans',
  go=['/zakat'],
  text="""
Sahl ibn Sa'd reported the Prophet ﷺ saying: {HS bukhari:6005|I and the one who looks after an orphan and provides for him will be in Paradise like this}, and he joined his index and middle fingers.

Taking an orphan's wealth wrongly is among the great sins in the hadith on major sins ({H bukhari:2766}).
""",
  review='Scholar review needed.')

E('fitrah-sunnahs',
  m=[r'\b(?:what is|whats|what are|explain) (?:the )?(?:fitrah|fitra|sunnahs? of fitrah|acts of fitrah|natural practices)\b', r'\b(?:circumcision|khitan|trimming (?:the )?nails|clipping (?:the )?nails|cutting (?:the )?nails|armpit hair|pubic hair|shaving pubic)\b', r'\bis (?:it|trimming|cutting|clipping) (?:the )?(?:nails|moustache|mustache)\b', r'\b(?:five|5) (?:things|practices|acts) of (?:the )?fitrah\b'],
  x=[r'\b(?:ruling|haram|fard|wajib)\b'],
  topic='the fitrah practices',
  text="""
Abu Hurayrah reported the Prophet ﷺ saying: {HS muslim:257|five are the acts of fitrah: circumcision, shaving the pubic hair, cutting the nails, plucking the hair under the armpits, and clipping the moustache}.

The Bukhari version lists them too: {HS bukhari:5889|five practices are characteristics of the fitrah: circumcision, shaving the pubic region, clipping the nails and cutting the moustache short}. Scholars discuss whether each is obligatory or recommended, and I do not rule on it here.
""",
  review='Scholar review needed: the status of each practice is intentionally left to scholars.')

E('prophets-character',
  m=[r'\b(?:what was|what is|describe|tell me about) (?:the )?(?:prophet s|prophets|muhammad s|prophet muhammad s) (?:character|manners|ethics|akhlaq|behaviou?r)\b', r'\bhow was the prophet (?:with|towards|to) (?:people|others|children|family)\b', r'\bwhat was the prophet (?:like|s personality)\b', r'\bakhlaq of the prophet\b', r'\b(?:good|best) (?:manners|character|akhlaq)\b.*\b(?:prophet|hadith|islam)\b'],
  topic='the Prophet\'s character',
  go=['/quran'],
  text="""
The Qur'an says to the Prophet ﷺ: you are of great moral character ({QR 68:4}).

Abdullah ibn Amr reported that the Prophet ﷺ {HS bukhari:3559|never used bad language, and used to say that the best among you are those with the best manners and character}.

For stories of his conduct, the Seerah section of the app has them.
""",
  review='Scholar review needed.')

E('dua-protect-children',
  m=[r'\b(?:dua|du a|supplication|protection)\b.*\b(?:protect\w*|safe\w*|guard\w*)?\b.*\b(?:my )?(?:children|kids|child|son|daughter|baby|babies)\b', r'\bhow (?:to|do i|can i) protect (?:my )?(?:children|kids|child|baby)\b.*\b(?:dua|du a|evil eye|shaytan|islam|islamic)\b', r'\bwhat (?:to|do i|should i) (?:say|recite|read) (?:over|for) (?:my )?(?:children|kids|child|baby|son|daughter)\b', r'\buidhukuma bi kalimat\b|\bu idhu\b'],
  x=[r'\b(?:name|naming|aqiqah|newborn|new born|sick|ill|haram|ruling|eating|sleep)\b'],
  topic='du\'a to protect children',
  go=['/adhkar'],
  text="""
Ibn Abbas reported that the Prophet ﷺ used to seek refuge for Al-Hasan and Al-Husayn, saying that their forefather Ibrahim used to seek refuge for Ismail and Ishaq with these words: {HS bukhari:3371|I seek refuge with Allah's perfect words from every devil and from poisonous pests and from every evil, harmful eye}.

In Arabic it begins: U'idhukuma bi kalimatillahit-tammati min kulli shaytanin wa hammatin wa min kulli 'aynin lammah.
""",
  review='Scholar review needed: the Arabic transliteration is the opening only; confirm.')

E('dua-guidance',
  m=[r'\b(?:dua|du a|supplication)\b.*\b(?:guidance|guided|right path|straight path|hidayah|hidaya|steadfast\w*|firm\w*)\b', r'\bwhat (?:to|do i|should i) (?:say|ask|pray) (?:for|to get|to ask for) (?:guidance|hidayah|the right path|steadfastness)\b', r'\bhow (?:to|do i|can i) (?:ask for|get|seek) (?:guidance|hidayah)\b', r'\bihdina (?:as|al) ?sirat\b'],
  topic='du\'a for guidance',
  go=['/adhkar', '/quran'],
  text="""
The most frequent du'a for guidance is in Surah Al-Fatihah: guide us to the straight path ({QR 1:6}), which Muslims recite in every rak'ah of prayer.

Ali reported that the Prophet ﷺ told him to say: {HS muslim:2725|O Allah, direct me to the right path and make me adhere to the straight path}. For steadfastness, the Qur'an gives the du'a: our Lord, do not let our hearts deviate after You have guided us ({QR 3:8}).
""",
  review='Scholar review needed: the summary of Muslim 2725 stops at the du\'a itself; the following instruction about intention is not summarised.')

E('dua-end-of-gathering',
  m=[r'\b(?:dua|du a|supplication|what (?:to|do i|should i) say)\b.*\b(?:end of|ending|leaving|after|when leaving)\b.*\b(?:gathering|meeting|majlis|sitting|party)\b', r'\bkaffarat (?:al )?majlis\b', r'\bwhat (?:to|do i|should i) say (?:before|when) (?:i )?(?:get up|stand up|leave) (?:from )?(?:a |the )?(?:gathering|meeting|sitting|majlis)\b', r'\bexpiation (?:of|for) (?:the )?(?:gathering|meeting|majlis|sitting)\b'],
  topic='du\'a at the end of a gathering',
  go=['/adhkar'],
  text="""
Abu Hurayrah reported the Prophet ﷺ saying: {HS tirmidhi:3433|whoever sits in a sitting and engages in much empty, meaningless speech and then says before getting up "Glory is to You, O Allah, and praise, I bear witness that there is none worthy of worship except You, I seek Your forgiveness and I repent to You", whatever occurred in that sitting will be forgiven to him}.

In Arabic: Subhanaka Allahumma wa bihamdika, ashhadu an la ilaha illa anta, astaghfiruka wa atubu ilayk.
""",
  review='Scholar review needed.')

E('dua-comprehensive',
  m=[r'\b(?:what is|whats|tell me|explain) (?:the )?(?:most (?:comprehensive|common|frequent)|comprehensive|jami|jaami)\b.*\b(?:dua|du a|supplication)\b', r'\brabbana (?:atina|aatina|atinaa|aatinaa) (?:fid|fi d|fil|fi l) ?dunya\b', r'\b(?:dua|du a)\b.*\b(?:good in this world|world and the hereafter|dunya and akhirah|dunya and akhira)\b', r'\bwhat (?:was|is) the prophet s? (?:most )?(?:frequent|common|favou?rite) (?:dua|du a|supplication)\b'],
  topic='the Prophet\'s most frequent du\'a',
  go=['/adhkar'],
  text="""
Anas reported that the most frequent du'a of the Prophet ﷺ was: {HS bukhari:6389|"O Allah, give us good in this world and good in the Hereafter, and save us from the torment of the Fire"}.

It is also a verse of the Qur'an ({QR 2:201}). In Arabic: Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina 'adhaban-nar.
""",
  review='Scholar review needed.')

E('hajj-reward-lahawla',
  m=[r'\b(?:what is the|whats the) (?:reward|virtue|benefit) (?:of|for) (?:performing |doing |going on )?hajj\b', r'\bwhat (?:happens|does hajj do) to (?:your |my |a person s )?sins\b', r'\b(?:reward|virtue|benefit) of hajj\b', r'\b(?:hajj|hajj mabrur|accepted hajj)\b.*\b(?:reward|sins|forgiven|born anew|newborn)\b'],
  topic='the reward of Hajj',
  go=['/huda/guide?id=huda-hajj-intro'],
  text="""
Abu Hurayrah reported the Prophet ﷺ saying: {HS bukhari:1521|whoever performs Hajj for Allah's pleasure and does not have sexual relations nor do wrong, will return as if he were born anew}.

The scholars say the hadith refers to an accepted Hajj; I am not adding conditions to it.
""",
  review='Scholar review needed: the "accepted Hajj" reading is the scholars\' explanation in general terms.')

E('reward-congregation-fajr',
  m=[r'\b(?:what is|whats) the (?:reward|virtue|benefit|difference) (?:of|for|between) (?:praying|prayer|salah|salat) in (?:congregation|jamaah|jamaat|jama ah)\b', r'\b(?:praying|prayer|salah) (?:in )?(?:congregation|jamaah|jamaat)\b.*\b(?:reward|times|better|virtue|twenty|27)\b', r'\b(?:reward|virtue|benefit) of (?:praying )?(?:fajr|the morning prayer|dawn prayer)\b', r'\bhow many times (?:is|better|more) (?:the )?(?:congregation|jamaah)\b'],
  topic='the reward of congregation and Fajr',
  go=['/huda/guide?id=huda-congregation'],
  text="""
Ibn Umar reported the Prophet ﷺ saying: {HS bukhari:645|the prayer in congregation is twenty-seven times superior to the prayer offered by a person alone}.

On Fajr, Jundub reported the Prophet ﷺ saying: {HS muslim:657|he who prayed the morning prayer in congregation is under the protection of Allah}.
""",
  review='Scholar review needed: the Muslim report continues with a warning not summarised here.')

E('reward-feeding-salam-salawat',
  m=[r'\b(?:what is the|whats the) (?:reward|virtue|benefit) (?:of|for) (?:feeding|giving food to|feeding the)\b', r'\b(?:reward|virtue|benefit) of (?:feeding|giving) (?:the )?(?:poor|hungry|needy)\b', r'\b(?:best|good|what are the best) (?:deeds?|actions?|qualities)\b.*\b(?:islam|muslim|feed\w*|greet\w*)\b', r'\b(?:reward|virtue|benefit) of (?:sending |saying |giving )?(?:salawat|durood|darood|salat)\b', r'\b(?:reward|virtue|benefit) of (?:saying )?(?:la hawla|la hawl)\b', r'\bla hawla wa la quwwata illa billah\b'],
  topic='rewards of small deeds',
  go=['/adhkar', '/tasbeeh'],
  text="""
A man asked the Prophet ﷺ which deeds are best in Islam, and he answered, as Abdullah ibn Amr reported: {HS bukhari:12|to feed the poor and greet those whom you know and those whom you do not know}.

On sending blessings on the Prophet ﷺ, Abu Hurayrah reported: {HS muslim:408|he who blesses me once, Allah will bless him ten times}.

On "La hawla wa la quwwata illa billah", Abu Musa reported the Prophet ﷺ said it is {HS bukhari:6384|one of the treasures of Paradise}.
""",
  review='Scholar review needed: the summary of Bukhari 6384 is limited to the statement about the treasures of Paradise.')

E('qur-an-recite-reward',
  m=[r'\b(?:what is the|whats the) (?:reward|virtue|benefit) (?:of|for) (?:reading|reciting) (?:the )?(?:quran|qur an|koran)\b', r'\b(?:reward|virtue|benefit) of (?:reading|reciting) (?:the )?(?:quran|qur an|koran)\b', r'\bhow many (?:hasanat|rewards?|good deeds) (?:for|per) (?:reading|reciting|each letter)\b', r'\b(?:each|every) letter (?:of|in) (?:the )?(?:quran|qur an)\b'],
  topic='the reward of reciting the Qur\'an',
  go=['/quran'],
  text="""
The Qur'an says that those who recite the Book of Allah, establish prayer and spend from what We provided them, secretly and openly, hope for a trade that will never perish ({QR 35:29}), so that Allah gives them their full reward and increases it from His bounty ({QR 35:30}).

The Prophet ﷺ also said, as 'Uthman reported, that {H bukhari:5027}.

I am not giving a count per letter, because I have not checked a graded report to cite.
""",
  review='Scholar review needed: the "count per letter" report is intentionally not given here.')
