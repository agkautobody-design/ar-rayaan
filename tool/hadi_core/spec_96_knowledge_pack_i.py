# Knowledge pack I (21 Nov 2026): gentleness, character, shade on the Day, du'a between adhan and iqamah,
# Friday ghusl, haya. Hadith read against the corpus by build.py.

E('gentleness-rifq',
  m=[r'\b(?:gentle|gentleness|rifq|softness)\b.*\b(?:islam|prophet|hadith|allah|sunnah)\b', r'\ballah is gentle\b', r'\b(?:be|being) gentle (?:with|to)\b', r'\bgentleness (?:in|and) islam\b'],
  topic='gentleness',
  go=['/hadith'],
  text="""
Aisha reported the Prophet ﷺ saying: {HS ibnmajah:3689|Allah is Gentle and loves gentleness in all things}.

Gentleness is meant in speech, in teaching, in dealing with family and with those under your care.
""",
  review='Scholar review needed: the second paragraph is a general reading of the hadith.')

E('good-character-scale',
  m=[r'\b(?:good|best) (?:character|manners|akhlaq|conduct)\b.*\b(?:scale|reward|weigh\w*|heavy|heavier|judg\w+|islam)\b', r'\bwhat is (?:the )?heaviest (?:on|in) (?:the )?(?:scale|mizan)\b', r'\bheavi\w+ (?:on|in) (?:the )?(?:believer\w* )?(?:scale|mizan)\b', r'\bakhlaq (?:in|of) islam\b'],
  topic='good character on the Scale',
  go=['/hadith'],
  text="""
Abu ad-Darda' reported the Prophet ﷺ saying: {HS tirmidhi:2002|nothing is heavier on the believer's Scale on the Day of Judgement than good character, and Allah is angered by the shameless, obscene person}.

So good character weighs as much as worship in the Scale, and it is where much of the believer's reward is gained.
""",
  review='Scholar review needed: the second paragraph is a general reading; the narration continues in the corpus line with more than is given here.')

E('world-prison-believer',
  m=[r'\b(?:world|dunya|dunia) is (?:a )?prison\b', r'\bprison (?:for|of) (?:the )?believer\b', r'\bparadise (?:for|of) (?:the )?(?:disbeliever|non ?believer|kafir)\b', r'\bwhy (?:is|do) (?:the )?(?:world|dunya) (?:a )?prison\b'],
  topic='the world as a prison for the believer',
  go=['/hadith'],
  text="""
Abu Hurayrah reported the Prophet ﷺ saying: {HS tirmidhi:2324|the world is a prison for the believer and Paradise for the disbeliever}.

Scholars explain that the believer is held to limits in this world, and what is waiting for him with Allah is better, while the disbeliever's share is only here. It does not mean the believer should hate his life, but that it is not his home.
""",
  review='Scholar review needed: the second paragraph gives the scholars\' explanation and is not cited.')

E('seven-in-the-shade',
  m=[r'\b(?:seven|7) (?:people|persons|types?|kinds?|groups?|men) (?:who )?(?:will be |are )?(?:shaded|in the shade|under (?:the )?(?:shade|throne))\b', r'\b(?:shade|shaded) (?:of|by|under) (?:allah|the throne)\b', r'\bwho will (?:be )?(?:shaded|in allah\w* shade)\b', r'\bday when there (?:is|will be) no shade\b'],
  topic='the seven shaded by Allah on the Day',
  go=['/hadith'],
  text="""
Abu Hurayrah reported the Prophet ﷺ saying: {HS bukhari:1423|seven will be shaded by Allah on the day when there is no shade but His: a just ruler; a young man raised in worshipping Allah; a man whose heart is attached to the mosque; two who love each other for Allah's sake, meeting and parting for it; a man who refuses an attractive woman of rank and says he fears Allah; one who gives charity so secretly his left hand does not know what his right gave; and one who remembers Allah alone and his eyes overflow}.
""",
  review='Scholar review needed.')

E('dua-between-adhan-iqamah',
  m=[r'\b(?:dua|du a|supplication|prayer) (?:made |said |is made )?(?:between|after) (?:the )?adhan and (?:the )?iqamah\b', r'\bbetween (?:the )?adhan and (?:the )?(?:iqamah|iqama|igama)\b', r'\bwhen (?:is|are) (?:dua|duas|supplications?) (?:not rejected|accepted|answered)\b', r'\btimes? (?:when )?(?:dua|duas) (?:is|are) (?:accepted|answered)\b'],
  topic='du\'a between the adhan and the iqamah',
  go=['/adhkar'],
  text="""
Anas ibn Malik reported the Prophet ﷺ saying: {HS tirmidhi:212|the supplication made between the adhan and the iqamah is not rejected}.

So when you hear the adhan, answer it, pray for the Prophet ﷺ and then ask Allah for what you need before the iqamah.
""",
  review='Scholar review needed: the second paragraph adds the steps after the adhan from general guidance and is not cited here.')

E('friday-ghusl-early',
  m=[r'\bghusl (?:on|for) (?:friday|jumu\w*|jumah)\b', r'\b(?:friday|jumu\w*) ghusl\b', r'\bgo\w* early (?:to|for) (?:friday|jumu\w*|jumah)\b', r'\b(?:bath\w*|shower\w*) on friday\b', r'\bfriday sunnah\w*\b', r'\bsunnahs? of (?:friday|jumu\w*|jumah)\b'],
  topic='ghusl and going early on Friday',
  go=['/huda'],
  text="""
Aws ibn Aws reported the Prophet ﷺ saying: {HS tirmidhi:496|whoever performs ghusl on Friday and bathes completely, goes early, gets close, listens and is silent, will have for every step the reward of a year of fasting and standing in prayer}.

So on Friday: wash well, go early to the masjid, sit near the imam, and listen to the khutbah without speaking.
""",
  review='Scholar review needed: the closing line restates the actions in the hadith; other Friday sunnahs are not given.')

E('haya-modesty',
  m=[r'\b(?:haya|hayaa|modesty|bashfulness|shyness|shame) (?:is|in|and|of) (?:faith|iman|islam)\b', r'\b(?:what|meaning) (?:is|of) (?:haya|hayaa)\b', r'\bbranches of (?:faith|iman)\b', r'\bhaya\b', r'\bmodesty (?:in|and) islam\b'],
  topic='haya and the branches of faith',
  go=['/hadith'],
  text="""
Abu Hurayrah reported the Prophet ﷺ saying: {HS bukhari:9|faith consists of more than sixty branches, and haya is a part of faith}.

Haya covers modesty, shame before Allah, self-respect and shyness at doing wrong. It guards the tongue, the eyes and the dress, and keeps a person from wrongdoing in private as well as in public.
""",
  review='Scholar review needed: the second paragraph explains haya in the scholars\' words; the number of branches is not listed.')
