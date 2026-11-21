# Knowledge pack E (20 Nov 2026): family, neighbours, seerah moments and a few practice questions
# found missing by a fourth probe. Hadith are read against the corpus by build.py.
# Contested rulings are deliberately not answered here.

E('family-ties-kinship',
  m=[r'\b(?:importance of|keep\w*|maintain\w*|break\w*|cut\w*|sever\w*|strengthen\w*) (?:the )?(?:family |kinship )?ties\b', r'\bsilat (?:al )?rahim\b', r'\bties of kinship\b', r'\bkeep\w* (?:in )?touch with (?:my )?(?:relatives|family)\b', r'\bqat(?:i|a)?\s?(?:ah|a) (?:al )?rahim\b'],
  topic='keeping family ties',
  go=['/huda'],
  text="""
Keeping the ties of kinship is a duty the Qur'an links with fearing Allah ({QR 4:1}).

Abu Hurayrah reported the Prophet ﷺ saying: {HS bukhari:5985|whoever is pleased to have his provision widened and his life prolonged should keep good relations with his relatives}.

Jubayr ibn Mut'im reported the Prophet ﷺ saying: {HS bukhari:5984|the one who cuts the bond of kinship will not enter Paradise}.

Keeping ties can be as simple as a call, a visit, a gift or a kind word, even when the relative has not kept theirs. If a relative is harming you, you may keep your distance and still be polite; ask a scholar about a hard case.
""",
  review='Scholar review needed: the last paragraph is general guidance; scholars discuss the limits when a relative causes harm.')

E('raising-daughters',
  m=[r'\braising (?:my )?(?:daughters?|girls)\b', r'\b(?:reward|virtue|blessing) (?:of )?(?:having|raising|bringing up|looking after|caring for) (?:daughters?|girls)\b', r'\bdaughters? in islam\b', r'\bbring(?:ing)? up (?:two |my )?(?:daughters?|girls)\b'],
  topic='raising daughters',
  go=['/huda'],
  text="""
Anas reported the Prophet ﷺ saying: {HS muslim:2631|whoever brings up two girls properly until they reach maturity, he and I will come on the Day of Resurrection like this, and he joined his fingers}.

The hadith is about caring for girls well: feeding, educating, protecting and treating them with kindness and fairness. It is a reward the Prophet ﷺ gave to the father or guardian who does this.
""",
  review='Scholar review needed: the narrator\'s name was not shown in the corpus line; confirm Anas, and the second paragraph is a general explanation.')

E('choosing-spouse',
  m=[r'\bwhat (?:to|should i|do i) look for in (?:a |my )?(?:spouse|husband|wife|partner)\b', r'\bhow (?:do|should|can) i (?:choose|pick|select|find) (?:a |my )?(?:spouse|husband|wife)\b', r'\bwho (?:is|should i marry|is the best to marry)\b.*\bmarry\b', r'\bwhom should i marry\b', r'\bbest (?:person|man|woman) to marry\b', r'\bqualities (?:of|in) (?:a )?(?:good )?(?:spouse|husband|wife)\b'],
  topic='choosing a spouse',
  go=['/huda'],
  text="""
Abu Hurayrah reported the Prophet ﷺ saying: {HS bukhari:5090|a woman is married for four things: her wealth, her family, her beauty and her religion, so marry the one with religion}.

The Qur'an describes marriage as a sign of Allah: He made spouses from yourselves so you may find rest in them, and placed affection and mercy between you ({QR 30:21}). It also urges marrying those who are single and righteous ({QR 24:32}).

Many scholars apply the same advice to men: look for faith and good character first. If you cannot decide, pray the two-rak'ah istikhara prayer, take counsel from people you trust, and meet the person with a guardian or family involved.
""",
  review='Scholar review needed: the hadith speaks of choosing a wife; applying it to men and the closing advice are scholars\' general guidance.')

E('hudaybiyyah',
  m=[r'\b(?:hudaybiyyah|hudaybiyah|hudaibiyah|hudaibiyyah|hudaibiya|hudaybiya)\b', r'\b(?:treaty|truce|pact) (?:of|at) (?:al )?hud\w+\b'],
  topic='the Treaty of Hudaybiyyah',
  go=['/stories'],
  text="""
In the sixth year after the Hijrah the Prophet ﷺ set out toward Makkah to perform 'Umrah and the Quraysh tried to stop him. Al-Miswar ibn Makhramah and Marwan reported: {HS bukhari:2731|the Prophet ﷺ set out at the time of Hudaybiyyah, his camel sat down, and he said she was stopped by the One who stopped the elephant; he said that if the Quraysh asked for anything that honoured Allah's sanctities he would grant it}.

He told their envoy Budayl that he had come to perform 'Umrah and not to fight, and offered a truce. The long hadith goes on to the talks that followed.

Surah Al-Fath opens with Allah saying: We have given you a clear victory ({QR 48:1}). Many scholars say it was revealed after Hudaybiyyah, and that the truce opened the way for the later conquest of Makkah.
""",
  review='Scholar review needed: the year and the link of Al-Fath to Hudaybiyyah are the scholars\' accounts and carry no named source here; the treaty terms are not given.')

E('conquest-makkah',
  m=[r'\b(?:conquest|opening|victory) of (?:makkah|mecca|makka)\b', r'\bfath (?:al )?(?:makkah|mecca)\b', r'\b(?:how|when|what happened when) (?:did )?(?:the prophet|muhammad|prophet muhammad)?.*\b(?:conquer\w*|enter\w*|return\w*) (?:to )?(?:makkah|mecca)\b', r'\bsurah (?:an )?nasr\b'],
  topic='the conquest of Makkah',
  go=['/stories'],
  text="""
Abdullah (ibn Mas'ud) reported: {HS bukhari:4287|when the Prophet ﷺ entered Makkah on the day of the conquest there were 360 idols around the Ka'bah, and he struck them with a stick saying that truth has come and falsehood will neither start nor return}.

This echoes the verse {QR 17:81}. Ibn Abbas reported the Prophet ﷺ saying on that day: {HS bukhari:3077|there is no migration after the conquest, but striving and good intentions, and when you are called to strive, respond}.

Surah An-Nasr speaks of Allah's help and the conquest, and of people entering Allah's religion in crowds ({QR 110:1-3}).
""",
  review='Scholar review needed: the Bukhari summaries are brief and the verse link is the app\'s own connection.')

E('farewell-sermon',
  m=[r'\bfarewell (?:sermon|speech|khutbah|hajj|pilgrimage)\b', r'\blast (?:sermon|speech|khutbah) of (?:the )?(?:prophet|muhammad)\b', r'\bkhutbat(?:ul)? (?:al )?wada\b', r'\bwhat did the prophet say (?:in|at) (?:his )?(?:last|final) (?:hajj|sermon)\b'],
  topic='the Farewell Sermon',
  go=['/hadith'],
  text="""
On the Day of Sacrifice in his last Hajj the Prophet ﷺ gave a sermon. Ibn Abbas reported: {HS bukhari:1739|he asked which day, which town and which month it was, and when they said it was sacred he said that their blood, their property and their honour are sacred to one another like this day, in this town, in this month; he repeated it, asked whether he had conveyed the message, and told those present to pass it on to those absent}.

That sermon is also known for its words that the Muslims should not return to disbelief after him by striking one another's necks.

The same Hajj is linked to the verse {QR 5:3}, in which Allah says He has perfected the religion for the believers.
""",
  review='Scholar review needed: other narrations of the sermon (about rights of women, riba, and holding to the Qur\'an) are not given here; the link of 5:3 to that Hajj is the scholars\' account.')

E('taif-journey',
  m=[r'\b(?:story of |what happened (?:at|in) |tell me about )(?:the )?(?:taif|ta if)\b', r'\bprophet\b.*\b(?:taif|ta if)\b', r'\b(?:taif|ta if)\b.*\b(?:prophet|muhammad|stoned|angel of the mountains)\b', r'\bangel of the mountains\b', r'\byear of (?:sorrow|grief|sadness)\b'],
  topic='the Prophet\'s journey to Ta\'if',
  go=['/stories'],
  text="""
Aisha asked the Prophet ﷺ whether he had met a day harder than Uhud. {HS bukhari:3231|he said the hardest was the day of 'Aqabah, when he presented himself to Ibn Abd Yalil and was not answered; he left overwhelmed with sorrow, and at Qarn ath-Tha'alib Gabriel and the Angel of the Mountains came and offered to crush the people between two mountains, but he said no, hoping Allah would bring from them people who worship Allah alone}.

It shows his mercy: he was offered revenge and chose hope for them instead. Allah describes him as a mercy to the worlds ({QR 21:107}).

The hadith does not itself name Ta'if or give the year; scholars link it to his journey to Ta'if, which is also known as the 'year of sorrow' with the deaths of Khadijah and Abu Talib. Those details are the scholars' account.
""",
  review='Scholar review needed: the identification of the day of Aqabah with Ta\'if and the year of sorrow are the scholars\' accounts, not stated in the hadith.')

E('ansar-muhajirun',
  m=[r'\b(?:who (?:are|were)|what (?:are|is|were)|tell me about|meaning of) (?:the )?(?:ansar|muhajir\w*|muhajireen|muhajiroon)\b', r'\b(?:ansar|muhajir\w*)\b.*\b(?:difference|meaning|who|brother\w*|madinah|medina)\b', r'\bbrotherhood (?:between|of) (?:the )?(?:ansar|muhajir\w*)\b'],
  topic='the Muhajirun and the Ansar',
  go=['/stories'],
  text="""
The Muhajirun are the Companions who left Makkah for Allah's sake; the Ansar ('helpers') are the people of Madinah who gave them shelter and support.

The Qur'an praises both: the poor emigrants who were driven from their homes ({QR 59:8}), and those who made their home in Madinah, love those who came to them and prefer them over themselves even in need ({QR 59:9}). It also speaks of the foremost of the emigrants and the helpers ({QR 9:100}).

Anas reported the Prophet ﷺ saying: {HS bukhari:17|love of the Ansar is a sign of faith and hatred of the Ansar is a sign of hypocrisy}.
""",
  review='Scholar review needed.')

E('zuhd-detachment',
  m=[r'\bzuhd\b', r'\bwhat is (?:the )?(?:asceticism|detachment from (?:this )?(?:world|dunya))\b', r'\bbe in this world (?:as|like) a (?:stranger|traveller|traveler)\b', r'\bdetach\w* from (?:this )?(?:world|dunya)\b'],
  topic='zuhd and being a traveller in this world',
  go=['/hadith'],
  text="""
Zuhd is not owning less for its own sake; it is keeping the world in your hand and not in your heart.

Ibn Umar reported: {HS bukhari:6416|the Prophet ﷺ took hold of his shoulder and said to be in this world as if a stranger or a traveller}. Ibn Umar used to say that in the evening you should not expect the morning, nor in the morning the evening, and to take from your health for your sickness and from your life for your death.

The Qur'an reminds that the life of this world is only play and amusement while the home of the Hereafter is better for those who fear Allah ({QR 6:32}).
""",
  review='Scholar review needed: the first sentence is a common description of zuhd without a named source.')

E('days-of-tashreeq',
  m=[r'\b(?:days? of )?(?:tashreeq|tashriq|tashreek|tashrik)\b', r'\bdays? after (?:eid|eid ul adha|eid al adha|adha)\b.*\b(?:eating|fasting|takbir)\b'],
  topic='the days of Tashriq',
  go=['/calendar'],
  text="""
The days of Tashriq are the three days after the Day of Sacrifice (the 11th, 12th and 13th of Dhul Hijjah).

Nubayshah al-Hudhali reported the Prophet ﷺ saying: {HS muslim:1141|the days of Tashriq are days of eating and drinking}. Because of this, fasting on those days is generally not allowed, with a narrow exception reported for pilgrims who could not afford a sacrificial animal; ask a scholar about your case.

They are also days of remembering Allah, as Allah says: remember Allah during the numbered days ({QR 2:203}).
""",
  review='Scholar review needed: the dates, the fasting ruling and the exception are the scholars\' accounts; the hadith line given is only the first part of the narration.')

E('newborn-sunnah',
  m=[r'\bwhat (?:should|do|to|must) (?:i|we|you) do (?:when|after|once) (?:a |the |my )?(?:baby|child|son|daughter|newborn) (?:is )?(?:born|arrives?)\b', r'\bsunnah\w* (?:of|for|after|at) (?:a )?(?:new ?born|birth|baby)\b', r'\bnew ?born\b.*\b(?:sunnah|islam\w*|do)\b', r'\btahnik\b', r'\bwhat (?:is|are) (?:the )?(?:sunnah|rights of) (?:a )?(?:new ?born|baby)\b'],
  topic='what is done when a baby is born',
  go=['/huda'],
  text="""
Abu Musa reported: {HS bukhari:5467|a son was born to him and he took him to the Prophet ﷺ, who named him Ibrahim, put a chewed date in his mouth (tahnik), prayed for blessing for him and returned him}.

Samurah reported the Prophet ﷺ saying: {HS abudawud:2838|a boy is in pledge for his 'aqiqah, which is sacrificed for him on the seventh day, when his head is shaved and he is named}.

So: give thanks, give a good name, say a du'a for the child, and the 'aqiqah is done around the seventh day. Scholars differ on whether the 'aqiqah is strongly recommended or obligatory, and on the details such as the number of animals.
""",
  review='Scholar review needed: the last paragraph is the scholars\' general account; the details of the aqiqah are not given.')

E('good-names-child',
  m=[r'\b(?:choos\w*|pick\w*|best|good|islamic|beautiful) names? for (?:my |a |the )?(?:baby|child|son|daughter|boy|girl)\b', r'\bnames? (?:dearest|most beloved|best) to allah\b', r'\bwhat (?:name|names) (?:should|can) i (?:give|name)\b', r'\bwhich names? (?:are|is) (?:best|disliked|forbidden|haram) (?:in islam)?\b'],
  topic='choosing a name for a child',
  go=['/huda'],
  text="""
Ibn Umar reported the Prophet ﷺ saying: {HS muslim:2132|the names dearest to Allah are Abdullah and Abd al-Rahman}.

Choose a name with a good meaning, preferably that of a prophet, a righteous person or a servant of Allah (Abd followed by one of His names). Avoid names with a bad meaning, or names that claim a quality that belongs to Allah alone.

For the du'a at the naming, see the du'a for a new baby.
""",
  review='Scholar review needed: the guidance after the hadith is general advice from scholars and is not cited.')

E('tarawih-prayer',
  m=[r'\btara[wv]ee?h\b', r'\btarawih\b', r'\bhow many (?:rakats?|rakahs?|rakaat|raka ?ah) (?:in|for|is|are) (?:the )?tara\w*\b', r'\bnight prayers? in ramadan\b', r'\bqiyam (?:al )?(?:layl|lail) (?:in )?ramadan\b'],
  topic='the Tarawih prayer',
  go=['/ramadan'],
  text="""
Tarawih is the voluntary night prayer of Ramadan, prayed after the 'Isha' prayer, often in congregation.

Aisha was asked how the Prophet ﷺ prayed in Ramadan: {HS bukhari:1147|she said he never exceeded eleven rak'ahs in Ramadan or other months, four, then four, then three}.

Under 'Umar, the people were gathered behind a single reciter: {HS bukhari:2010|Abd ar-Rahman ibn Abd al-Qari reported that 'Umar gathered the people behind Ubayy ibn Ka'b}. Scholars differ on the number of rak'ahs: the schools commonly pray twenty and some pray eight with witr. Both are accepted by scholars, and the most important thing is to pray it with calm and presence.
""",
  review='Scholar review needed: the figures twenty and eight are the schools\' positions, not cited here.')

E('eclipse-prayer',
  m=[r'\b(?:solar|lunar|sun|moon)? ?eclipse\b', r'\bsalat(?:ul)? (?:al )?(?:kusuf|khusuf|kusoof)\b', r'\bprayer (?:of|for|during) (?:an |the )?eclipse\b'],
  topic='the eclipse prayer',
  go=['/prayer'],
  text="""
Aisha reported: {HS bukhari:1044|in the Prophet's lifetime the sun eclipsed and he led the people in a prayer with long standing, a long bow, a second shorter standing and bow, and long prostrations, in each rak'ah; then he gave a sermon, and said the sun and moon are two signs of Allah that do not eclipse for anyone's death or life, so when you see it remember Allah, say takbir, pray and give charity}.

It is two rak'ahs, each with two standings and two bows, as described, followed by a short sermon.
""",
  review='Scholar review needed: the second paragraph is a short description of the form of the prayer; the sermon wording is only part of the narration.')
