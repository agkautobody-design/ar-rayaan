# Everyday-life answers (18 Nov 2026). Hadi is allowed to help with ordinary
# life, with one rule: each answer says which part is general common sense and
# which part comes from the Qur'an or from scholars, and none gives a ruling on
# a person's own case or medical, legal or financial advice. Qur'an refs are
# checked by build.py. No hadith numbers are cited here on purpose.

E('shower-wudu',
  m=[r'\b(?:wudu|ablution|wudhu|wuzu)\b.*\b(?:shower|showering|bath|bathing|bathroom)\b',
     r'\b(?:shower|showering|bath|bathing)\b.*\b(?:wudu|ablution|wudhu|wuzu)\b',
     r'\bwash(?:ing)? for prayer (?:in|while|when) (?:the )?(?:shower|bath)\b'],
  topic='wudu in the shower',
  go=['/academy', '/prayer'],
  text="""
Yes, many scholars accept wudu done in the shower, as long as you do what wudu is. The Qur'an names the parts: the face, the arms to the elbows, wiping the head and the feet ({QR 5:6}).

What matters is that water reaches each of those parts, and that you intend it as wudu. If you shower with that intention and wash those parts, it counts for most scholars. The schools differ on details: whether the order must be kept (face, arms, head, feet), and whether the parts must be washed one right after the other without a long gap. If you follow a school, follow its rule: the safest way in any school is to do the parts in the usual order with your intention, even in the shower.

Many scholars also hold that a full ghusl done with the intention to purify includes wudu, so you do not need to repeat it.

If you are unsure, the simple way is to step out of the flow, do the wudu in order under the running water, and then pray. This is the difference-of-opinion view, not a ruling on your case; for that ask a scholar of your school.
""",
  review='Scholar review needed: schools differ on tartib and muwalat; wording is a summary of the common positions.')

E('everyday-sleep',
  m=[r'\b(?:how (?:to|do i)|tips? (?:to|for)) (?:sleep|sleep better|fall asleep)\b', r'\bcant sleep\b', r'\binsomnia\b', r'\b(?:sleep|sleeping) (?:well|better|routine|schedule)\b', r'\bhow much sleep\b'],
  x=[r'\b(?:prayer|salah|dua|dhikr|adhkar|sunnah)\b'],
  topic='sleep',
  go=['/adhkar'],
  text="""
General advice (not medical): most adults do best on seven to nine hours, at regular times, with screens put away for the last hour, a cooler dark room, and less caffeine after midday. If you lie awake most nights for weeks, see a doctor.

From Islam: the Qur'an counts sleep among the signs of Allah's care ({QR 30:23}) and calls the night a time of rest ({QR 78:9}). The Sunnah bedtime du'as and the night prayer are in the Dhikr and Du'a screen if you want to end the day that way.
""",
  review='General health advice is common guidance, not medical; Qur\'an refs are checked.')

E('everyday-healthy-eating',
  m=[r'\b(?:how (?:to|do i)|tips? (?:to|for)) (?:eat|eating) (?:healthy|healthier|better|well)\b', r'\bhealthy (?:eating|diet|food)\b', r'\beat(?:ing)? less\b', r'\boverea?ting\b'],
  x=[r'\b(?:halal|haram|ruling|fasting|ramadan)\b'],
  topic='eating well',
  text="""
General advice (not medical): more vegetables, fruit, water and whole foods, less sugar and fried food, and smaller portions eaten slowly. A doctor or dietitian is the right person for a condition or a specific diet.

From Islam: the Qur'an says to eat of what is lawful and good ({QR 2:168}) and not to waste or go to excess ({QR 7:31}). Scholars take that as a principle for food as for everything else: eat to be well, give thanks, and do not eat to excess.
""",
  review='General nutrition advice is not medical; Qur\'an refs are checked.')

E('everyday-money-saving',
  m=[r'\bhow (?:to|do i|can i) (?:save|saving) money\b', r'\bbudget(?:ing)?\b', r'\bget out of debt\b', r'\bhow (?:to|do i) manage (?:my )?money\b', r'\bspend(?:ing)? less\b'],
  x=[r'\b(?:zakat|riba|interest|mortgage|invest\w*|stocks?|crypto\w*|halal|haram)\b'],
  topic='saving money',
  go=['/zakat', '/academy/transactions'],
  text="""
General advice (not financial advice): write down what comes in and goes out for a month, pay the bills and debts first, set aside a fixed amount as soon as you are paid, and cut the small regular costs you do not notice. An emergency fund of a few months of costs comes before anything else.

From Islam: the Qur'an praises those who are neither wasteful nor stingy but between the two ({QR 25:67}), and warns against waste ({QR 17:26}). For halal and haram in money matters, ask me about the specific question, and for zakat there is a calculator.
""",
  review='General money advice, not financial advice; Qur\'an refs are checked.')

E('everyday-job-work',
  m=[r'\b(?:how (?:to|do i)|tips? (?:to|for)) (?:find|get|look for) (?:a )?(?:job|work|employment)\b', r'\bjob (?:search|hunting)\b', r'\b(?:how to|tips for) (?:do )?(?:well|better) at work\b', r'\bwork(?:place)? (?:advice|ethics)\b', r'\bhow to be (?:a )?good (?:employee|worker|boss)\b'],
  x=[r'\b(?:halal|haram|ruling|interview)\b'],
  topic='work and jobs',
  go=['/academy/transactions'],
  text="""
General advice: tell people you know that you are looking, keep your CV short and specific, apply steadily rather than in bursts, and prepare for each interview by learning what the employer actually does.

From Islam: work done honestly is worship, and the Qur'an tells believers to spread out in the land and seek Allah's bounty after prayer ({QR 62:10}). Do the work you are paid for properly, be honest about your hours, and be fair to those who work for you. If a job is in a doubtful area, ask me about that specific work.
""",
  review='General career advice; Qur\'an ref is checked.')

E('everyday-study',
  m=[r'\bhow (?:to|do i|can i) (?:study|learn|revise|focus|concentrate)\b', r'\bstudy (?:tips|habits|routine|better)\b', r'\bexam (?:stress|tips|prep|preparation)\b', r'\bhow to memori[sz]e\b'],
  x=[r'\b(?:quran|qur an|hifz|surah|arabic|english|french|spanish|german|urdu|language|languages)\b'],
  topic='studying',
  go=['/academy/hifz'],
  text="""
General advice: study in short blocks with breaks, test yourself instead of rereading, sleep before an exam rather than cramming all night, and put the phone in another room.

From Islam: the Qur'an teaches a du'a for more knowledge ({QR 20:114}), and asks whether those who know are equal to those who do not ({QR 39:9}). Ask Allah for ease before you start, then do the work: both are part of it.
""",
  review='General study advice; Qur\'an refs are checked.')

E('everyday-parenting',
  m=[r'\b(?:how (?:to|do i)|tips? (?:to|for)) (?:raise|parent|discipline) (?:my )?(?:kids?|children|child|toddler|teen\w*)\b', r'\bparenting (?:advice|tips|help)\b', r'\bmy (?:kid|child|son|daughter|toddler|teenager) (?:wont|will not|refuses|is not listening)\b', r'\btantrums?\b'],
  x=[r'\b(?:abuse|hit|beat|hurt)\w*\b'],
  topic='parenting',
  go=['/academy/family', '/kids'],
  text="""
General advice: be calm and consistent, set a few clear rules and keep them, explain the reason, notice good behaviour more than bad, and give regular one to one time. Children copy what they see more than what they are told. For a serious or lasting difficulty, a doctor or a family counsellor can help.

From Islam: the Qur'an tells believers to guard themselves and their families ({QR 66:6}), and a parent's du'a for their children is part of the work ({QR 25:74}). The Family section of the Academy has more.
""",
  review='General parenting advice; Qur\'an refs are checked.')

E('everyday-neighbours-manners',
  m=[r'\b(?:how (?:to|do i)|tips? (?:to|for)) (?:treat|deal with|be good to) (?:my )?(?:neighbou?rs?|guests?|co-?workers?|colleagues?)\b', r'\bgood manners\b', r'\bhow (?:to|do i) be polite\b', r'\bneighbou?rs? (?:rights|noise|problem)\b'],
  x=[r'\b(?:ruling|halal|haram)\b'],
  topic='neighbours and manners',
  go=['/academy/character'],
  text="""
General advice: greet them, keep noise down at night, return what you borrow, bring a dish on occasions, and speak to them privately and kindly before a small problem becomes a big one.

From Islam: the Qur'an puts kindness to the neighbour next to kindness to parents and relatives ({QR 4:36}), and tells us to speak to people well ({QR 2:83}). The Character section of the Academy goes further.
""",
  review='General manners advice; Qur\'an refs are checked.')

E('everyday-time-management',
  m=[r'\b(?:how (?:to|do i)|tips? (?:to|for)) (?:manage|use|organi[sz]e|plan) (?:my )?(?:time|day)\b', r'\btime management\b', r'\bbe more productive\b', r'\bprocrastinat\w*\b'],
  x=[r'\b(?:prayer|salah|salat)\b'],
  topic='using time well',
  go=['/prayer'],
  text="""
General advice: choose the one or two things that matter most each day and do them first, keep a short list, and protect a block of time without interruptions. The five prayers give a day its natural frame: plan around them rather than squeezing them in.

From Islam: the Qur'an swears by time and says people are at a loss except those who believe, do good, and urge one another to truth and patience ({QR 103:1}). Prayer Times shows when each prayer begins where you are.
""",
  review='General productivity advice; Qur\'an ref is checked.')

E('everyday-travel',
  m=[r'\b(?:how (?:to|do i)|tips? (?:to|for)) (?:travel|plan a trip|pack)\b', r'\btravel(?:l?ing)? tips\b', r'\bwhat to pack\b', r'\bplanning a (?:trip|holiday|vacation)\b'],
  x=[r'\b(?:hajj|umrah|qasr|shorten\w*|combine\w*|jam)\b'],
  topic='travelling',
  go=['/prayer', '/qibla', '/masajid'],
  text="""
General advice: check the weather, keep copies of your documents, carry a charger and some water, and tell someone your plan. Look up where you will stay before you arrive.

For a Muslim traveller the app helps with the prayer side: Prayer Times and Qibla work from your location, and the Mosques screen shows places to pray nearby. If you want the rules for shortening or joining prayers on a journey, ask me that directly.
""",
  review='General travel advice; app pointers only, no ruling.')

E('last-surah-revealed',
  m=[r'\blast (?:surah|sura|chapter) (?:that )?(?:was )?revealed\b', r'\b(?:which|what) (?:surah|sura|chapter) was (?:the )?last (?:revealed|to be revealed)\b', r'\blast (?:ayah|verse) (?:that )?(?:was )?revealed\b', r'\blast thing (?:that )?(?:was )?revealed\b'],
  topic='last revelation',
  go=['/quran'],
  text="""
Scholars give more than one answer, because the reports differ.

For the last complete surah, the view most often given is An-Nasr (surah 110), reported from Ibn Abbas ({QR 110:1}). For the last verses, the reports name different ones, and the ones most often mentioned are the verse that warns of the Day you are returned to Allah ({QR 2:281}), and the verse that says the religion is completed ({QR 5:3}), which was revealed at the farewell pilgrimage.

So there is no single agreed answer, and I would not state one as settled. A tafsir book by a recognised scholar lays out the reports.
""",
  review='Scholar review needed: the reports differ and the order depends on which one is preferred.')

E('something-inspiring',
  m=[r'\b(?:(?:tell|give) me )?something (?:inspiring|uplifting|motivating|encouraging)\b', r'\binspire me\b', r'\bmotivate me\b', r'\bi need (?:some )?(?:motivation|inspiration|encouragement)\b'],
  x=[r'\b(?:suicid\w*|kill myself|end it|hopeless|worthless|depress\w*)\b'],
  topic='encouragement',
  go=['/stories', '/feelings'],
  text="""
Here is one from the Qur'an: with hardship comes ease, and the verse says it twice ({QR 94:5}, {QR 94:6}). The difficulty you are in is real, and the promise is that it is not the end of the story.

Another: Allah does not burden a soul beyond what it can bear ({QR 2:286}).

If you would like more, the Stories screen has the lives of the prophets, and For Your Heart has verses and du'as for how you feel today.
""",
  review='Qur\'an refs only; encouragement, not advice.')

E('dua-anxiety',
  m=[r'\b(?:dua|supplication|prayer)s?\b.*\b(?:anxiety|anxious|worry|worries|worried|stress|stressed|sorrow|grief|distress|distressed|sadness|sad|heavy heart|overwhelmed)\b',
     r'\b(?:anxiety|anxious|worry|worries|worried|stress|stressed|sorrow|grief|distress|distressed|sadness|overwhelmed)\b.*\b(?:dua|supplication)s?\b',
     r'\bwhat (?:do i|should i|can i|to) (?:say|recite|read)\b.*\b(?:anxious|anxiety|worried|worry|stressed|sad|distressed|overwhelmed)\b',
     r'\b(?:say|recite|read)\b.*\b(?:when|if|while)\b.*\b(?:anxious|worried|stressed|sad|distressed|overwhelmed)\b'],
  topic='a du\'a for worry and anxiety',
  go=['/adhkar'],
  text="""
The Prophet ﷺ used to ask Allah for refuge from worry and sadness ({H bukhari:6369|Anas reported that the Prophet used to say: O Allah, I seek refuge in You from worry and grief, from weakness and laziness, from miserliness and cowardice, from the burden of debt and from being overpowered by men}):

{AR bukhari:6369|اللهم إني أعوذ بك من الهم والحزن|وغلبة الرجال}

Allahumma inni a'udhu bika minal-hammi wal-hazan, wal-'ajzi wal-kasal, wal-bukhli wal-jubn, wa dala'id-dayni wa ghalabatir-rijal.
Meaning: O Allah, I seek refuge in You from worry and grief, from weakness and laziness, from miserliness and cowardice, from the burden of debt and from being overpowered by people.

You can say it at any time, in any language you pray in, and as often as you need. The Qur'an also speaks of hearts finding rest in remembering Allah ({QR 13:28}).

A du'a is a strong help, and it sits alongside the other help, not instead of it. If anxiety is heavy or does not lift, talking to someone you trust or to a doctor is part of looking after yourself, and it is no sign of weak faith. If you want to talk, tell me and I will stay with it.
""",
  review='Scholar review needed: the du\'a is cited to Sahih al-Bukhari 6369 (checked); the transliteration is typed by hand; the closing advice is general wellbeing guidance, not medical.')
