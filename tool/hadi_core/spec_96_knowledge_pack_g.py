# Knowledge pack G (21 Nov 2026): signs of the Hour, last ten nights, wudu, cleanliness, sincerity,
# yawning, eating with the right hand, ease in religion, mercy. Hadith read against the corpus by build.py.

E('signs-of-the-hour',
  m=[r'\b(?:signs?|portents?|omens?) of (?:the )?(?:hour|last day|day of judg\w+|judg\w+ day|qiyamah|qiyama|end of (?:time|days|the world))\b', r'\b(?:minor|major|small|big) signs? of (?:the )?(?:hour|qiyamah|qiyama|last day)\b', r'\bwhen (?:will|is) (?:the )?(?:hour|qiyamah|end of the world|judg\w+ day) (?:come|coming)\b', r'\bend times?\b'],
  topic='signs of the Hour',
  go=['/hadith'],
  text="""
Anas reported the Prophet ﷺ saying: {HS bukhari:80|among the portents of the Hour are that religious knowledge will be taken away, religious ignorance will prevail, alcohol will be very common, and open illegal sexual intercourse will be widespread}.

The Qur'an says the knowledge of the Hour is with Allah alone ({QR 31:34}). The signs are meant to wake the heart to prepare, not to be used to guess a date.
""",
  review='Scholar review needed: other signs (major and minor) are reported in many narrations and are not listed here; scholars divide them into minor and major.')

E('last-ten-nights-effort',
  m=[r'\b(?:last|final) (?:ten|10) (?:nights?|days?) (?:of )?(?:ramadan)?\b', r'\bwhat (?:did|does) the prophet do (?:in|during) (?:the )?(?:last|final) (?:ten|10)\b', r'\bhow (?:should|do) i (?:spend|use) (?:the )?(?:last|final) (?:ten|10) (?:nights?|days?)\b', r'\b(?:ten|10) (?:nights?|days?) of ramadan\b'],
  x=[r'\bdhul hijjah\b', r'\bdhul hijja\b', r'\bfirst ten\b'],
  topic='the last ten nights of Ramadan',
  go=['/ramadan'],
  text="""
Aisha reported: {HS bukhari:2024|when the last ten days of Ramadan began, the Prophet ﷺ would tighten his waist belt, pray all night, and keep his family awake for prayer}.

Laylat al-Qadr is sought in these nights, and Allah says it is better than a thousand months ({QR 97:1-5}).

So the last ten are for prayer, Qur'an, du'a and waking your family if you can.
""",
  review='Scholar review needed: the last sentence is general guidance; scholars recommend seeking the night in the odd nights and sitting in i\'tikaf.')

E('wudu-forgiveness-reward',
  m=[r'\b(?:reward|virtue|benefit|merit) (?:of )?(?:making |doing |performing )?(?:wudu|ablution|wudhu|wuzu)\b', r'\bwudu\b.*\b(?:forgive\w*|sins?|reward|two rak\w*)\b', r'\b(?:ablution|wudu) (?:and|then) (?:two )?rak\w*\b', r'\bwhat (?:is|are) the (?:rewards?|benefits?) of wudu\b'],
  topic='the reward of wudu',
  go=['/huda'],
  text="""
'Uthman ibn 'Affan performed wudu in front of people and reported the Prophet ﷺ saying: {HS bukhari:159|if anyone performs ablution like mine and prays two rak'ahs without letting his mind wander to other things, his past sins will be forgiven}.

So wudu done well, followed by two focused rak'ahs, is a means of forgiveness.
""",
  review='Scholar review needed: scholars discuss which sins are meant (the minor sins) in this and similar narrations.')

E('religion-is-sincerity',
  m=[r'\b(?:the )?(?:religion|deen|din) is (?:sincerity|naseehah|nasihah|sincere advice|advice)\b', r'\bwhat is (?:naseehah|nasihah|nasiha)\b', r'\bmeaning of (?:naseehah|nasihah|nasiha)\b', r'\bad deen an nasihah\b', r'\bad din an nasiha\b'],
  topic='religion is sincere advice (nasihah)',
  go=['/hadith'],
  text="""
Tamim ad-Dari reported the Prophet ﷺ saying: {HS muslim:55|the religion is sincerity; when asked to whom, he said to Allah, to His Book, to His Messenger, and to the leaders of the Muslims and their masses}.

Nasihah means wishing and doing good for the other, with honesty and care. To Allah it is believing in Him alone; to His Book, to read it, understand it and act by it; to His Messenger, to follow him; and to the people, to advise them gently and not to cheat them.
""",
  review='Scholar review needed: the second paragraph explains the hadith in the usual words of scholars and is not cited.')

E('yawning-manners',
  m=[r'\byawn\w*\b'],
  topic='yawning',
  go=['/hadith'],
  text="""
Abu Hurayrah reported the Prophet ﷺ saying: {HS muslim:2994|yawning is from the devil, so when one of you yawns he should restrain it as far as he can}.

Scholars add that you can cover your mouth with your hand, and not make a sound while you do.
""",
  review='Scholar review needed: covering the mouth is mentioned in a separate narration that is not cited here.')

E('ease-in-religion',
  m=[r'\bis islam (?:hard|difficult|a (?:burden|hardship))\b', r'\bmake things? easy\b', r'\bease (?:in|of) (?:islam|religion|the deen)\b', r'\b(?:islam|religion) is (?:easy|ease|simple)\b', r'\bwhy is islam (?:so )?(?:hard|difficult|strict)\b'],
  topic='ease in the religion',
  go=['/hadith'],
  text="""
Allah says: Allah intends ease for you and does not intend hardship ({QR 2:185}).

Abu Musa reported the Prophet ﷺ saying: {HS abudawud:4835|give people good news and do not scare them; make things easy and do not make them difficult}.

Islam asks for what a person can bear, and has concessions such as shortening the prayer in travel and breaking the fast when ill. Keep to what is required and then add to it by your ability.
""",
  review='Scholar review needed: the concessions named are examples in the second paragraph, and the narration given has a longer wording in the corpus.')

E('mercy-to-children',
  m=[r'\b(?:kiss\w*|hugg?\w*|love|affection|mercy) (?:to|for|toward|towards) (?:your |my )?(?:children|kids|child)\b', r'\bwho is not merciful will not be shown mercy\b', r'\bwhoever is not merciful\b', r'\bshow(?:ing)? mercy to (?:others|people)\b', r'\bkissing (?:your |my )?(?:children|kids|child|grandchild\w*)\b'],
  topic='mercy toward children and others',
  go=['/hadith'],
  text="""
Abu Hurayrah reported that the Prophet ﷺ kissed his grandson al-Hasan, and a man said he had ten children and had never kissed one of them. The Prophet ﷺ looked at him and said: {HS bukhari:5997|whoever is not merciful to others will not be treated mercifully}.

So affection for children, hugging and kissing them, is part of the Sunnah, and mercy is a duty that reaches everyone.
""",
  review='Scholar review needed: the second paragraph states the conclusion drawn by scholars.')
