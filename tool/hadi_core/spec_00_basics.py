# Basics that beginners ask first. This file is read before the others, so its matchers are narrow.

E('pillars-islam',
  m=[r'\b(?:five|5) pillars\b', r'\bpillars? of islam\b', r'\bwhat are the pillars\b', r'\bislamic pillars\b', r'\barkan e islam\b', r'\barkan ul islam\b'],
  x=[r'\b(?:iman|imaan|faith|belief)\b'],
  topic='pillars of islam',
  text="""
Islam rests on five pillars. {HS bukhari:8|Ibn Umar reported the Prophet said Islam is based on five: to testify that none has the right to be worshipped but Allah and Muhammad is Allah's Messenger, to offer prayer, to pay zakat, to perform Hajj, and to fast in Ramadan}.

1. The testimony of faith (shahada): that there is no god but Allah and that Muhammad ﷺ is His messenger.
2. Prayer (salah): the five daily prayers.
3. Zakat: the obligatory charity given from wealth that reaches the nisab.
4. Fasting (sawm) in the month of Ramadan.
5. Hajj: the pilgrimage to Makkah, once in a lifetime for those who are able.

These are the acts of worship that hold the rest of the religion up. The six articles of belief (iman) are a separate list; ask me about those too.
""",
  go=['/academy/aqeedah'],
  review='Plain restatement of the hadith.')

E('eid-festivals',
  m=[r'\bwhat is eid\b', r'\bwhat (?:is|are) (?:the )?(?:two )?eids?\b', r'\beid al ?fitr\b', r'\beid ul ?fitr\b', r'\beid al ?adha\b', r'\beid ul ?adha\b', r'\bbakra eid\b', r'\bmeethi eid\b', r'\bhow do muslims celebrate eid\b', r'\bwhen is eid\b', r'\bdifference between (?:the two )?eids?\b', r'\btwo eids\b', r'^eid$', r'^eid mubarak$', r'\bhow (?:to|do (?:i|we)) celebrate eid\b'],
  x=[r'\b(?:prayer|salah|namaz|zakat|fitrah|fitra|story|dream|knife|son|ismail|ishmael|qurbani|udhiyah|dua|takbir|greeting)\b'],
  topic='eid',
  text="""
Muslims have two festivals in the year, and both are days of worship, joy and giving.

- Eid al-Fitr falls on the 1st of Shawwal and ends the month of fasting. Zakat al-fitr is given before the Eid prayer so the poor can celebrate as well.
- Eid al-Adha falls on the 10th of Dhul Hijjah, after the day of Arafah in Hajj. It remembers Ibrahim's obedience, and those who can afford it offer a sacrifice. Allah says the sacrifice is about devotion, not the meat: {Q 22:37|Their meat will not reach Allah, nor will their blood, but what reaches Him is piety from you}.

Both days begin with the Eid prayer in congregation. On Eid al-Adha the Prophet ﷺ taught that the prayer comes first and the sacrifice after it ({H bukhari:5545|Al-Bara reported the Prophet said on the day of Eid al-Adha that the first thing we do is pray and then return to slaughter, and whoever slaughtered before the prayer, it is only meat given to his family}).

Fasting is not allowed on these two days: {HS bukhari:1990|Umar said the Prophet forbade fasting on the day you break your fast and the day you eat the meat of your sacrifices}.

Islam has no other festivals for the community, and the Prophet ﷺ said there is an Eid for every people ({H bukhari:952|Aisha said Abu Bakr protested at two girls singing in her house, and the Prophet said leave them, for there is an Eid for every people and this is our Eid}). Ask me how to pray the Eid prayer, about zakat al-fitr, or about Ibrahim's story.
""",
  go=['/calendar'],
  review='The dates are stated as the Hijri days; the actual day follows the moon sighting, which I say elsewhere.')

E('laylat-qadr',
  m=[r'\blaylat(?:ul|ul-| al| el)? ?(?:al |el )?-?qadr\b', r'\blailat(?:ul)? ?(?:al )?-?qadr\b', r'\bnight of (?:power|decree|qadr|destiny)\b', r'\bshab e qadr\b', r'\bshab-e-qadr\b'],
  topic='laylat al-qadr',
  text="""
Laylat al-Qadr, the Night of Decree, is the night the Qur'an began to be revealed, and it falls in Ramadan. Allah says: {Q 97:1-5|Indeed, We sent the Qur'an down during the Night of Decree. And what can make you know what is the Night of Decree? The Night of Decree is better than a thousand months. The angels and the Spirit descend therein by permission of their Lord for every matter. Peace it is until the emergence of dawn}.

Its date is not fixed. {HS bukhari:2017|Aisha reported the Prophet said to look for Laylat al-Qadr in the odd nights of the last ten days of Ramadan}. So people give those nights extra prayer, Qur'an and du'a.

A'ishah asked what to say if she found the night, and the Prophet ﷺ taught her a short du'a, "Allahumma innaka afuwwun tuhibbul-afwa fa'fu anni" (O Allah, You are Pardoning and You love to pardon, so pardon me). It is reported in {HW tirmidhi:3513|Aisha asked the Prophet what to say if she knew the Night of Al-Qadr, and he taught her to say O Allah, You are Pardoning, You love pardon, so pardon me}. The graders differ on that report (some call it sahih, one calls it weak), and the du'a is a good one to say in any case.
""",
  go=['/ramadan'],
  review='tirmidhi:3513 is graded sahih by Al-Albani and da\'if by Zubair Ali Zai; cited as disputed, not as firm evidence.')

E('friday-sunnah',
  m=[r'\bsunn?ah (?:of|on|for) (?:friday|jumuah|jumah)\b', r'\bfriday (?:sunn?ah|etiquette|manners|etiquettes|rituals|habits|traditions)\b', r'\bwhat (?:to do|should i do|do muslims do) on friday\b', r'\bwhat is sunn?ah on friday\b', r'\bsunn?ahs? of jumuah\b', r'\bjumuah (?:sunn?ah|etiquette|manners)\b', r'\bwhy is friday (?:special|important|holy|blessed)\b', r'\bsignificance of friday\b', r'\bwhat to do before jumuah\b'],
  topic='friday',
  text="""
Friday is the best day of the week: {HS muslim:854|Abu Hurayrah reported the Prophet said the best day on which the sun has risen is Friday, on which Adam was created}.

What is taught for Friday:
- Wash (ghusl) and go early. {HS bukhari:881|Abu Hurayrah reported the Prophet said whoever bathes on Friday like the bath of janabah and goes early to the prayer, it is as if he offered a camel in sacrifice, and the reward lessens for each later hour}.
- Clean your teeth with the siwak and wear perfume if you have it: {H bukhari:880|Abu Said reported the Prophet said the Friday bath is compulsory for every adult male Muslim, with cleaning the teeth with siwak and using perfume if available}. (The scholars differ on whether the bath itself is obligatory or strongly recommended.)
- Go to the prayer when the adhan is called and leave trade for it: {Q 62:9|when [the adhan] is called for the prayer on the day of Jumu'ah [Friday], then proceed to the remembrance of Allah and leave trade}. Afterwards: {Q 62:10|when the prayer has been concluded, disperse within the land and seek from the bounty of Allah, and remember Allah often}.
- Listen to the khutbah quietly.

Ask me about the Friday prayer itself, who must attend, and how many rak'ahs it has.
""",
  go=['/prayer'],
  review='The scholars\' difference on the Friday ghusl is stated, not resolved.')

E('tawheed-shirk',
  m=[r'\btawh?[ei]+d\b', r'\btauh?[ei]+d\b', r'\bwhat is shirk\b', r'\bshirk\b', r'\bassociating (?:partners|others) with allah\b', r'\bwhat is the greatest sin\b', r'\bunforgivable sin\b', r'\bis shirk forgiven\b', r'\boneness of allah\b'],
  x=[r'\b(?:game|names)\b'],
  topic='tawheed and shirk',
  text="""
Tawheed is the belief that Allah is One in His being and in His right to be worshipped, with no partner. Allah says: {Q 112:1-4|He is Allah, [who is] One, Allah, the Eternal Refuge. He neither begets nor is born, Nor is there to Him any equivalent}.

Shirk is the opposite: giving someone or something else a share in what belongs to Allah alone, such as worshipping, praying to or relying completely on another besides Him. The Qur'an treats it as the gravest wrong. Luqman told his son not to associate anything with Allah: {Q 31:13|Indeed, association [with him] is great injustice}. And {Q 4:48|Indeed, Allah does not forgive association with Him, but He forgives what is less than that for whom He wills}. That verse is about dying while still committing it; the door of repentance stays open for a living person.

The Prophet ﷺ explained what Allah's right is: {HS bukhari:2856|Mu'adh reported the Prophet said Allah's right on His servants is that they worship Him alone and associate nothing with Him, and the servants' right on Allah is that He does not punish the one who associates nothing with Him}.
""",
  go=['/academy/aqeedah'],
  review='Scope kept to Qur\'an 112, 31:13, 4:48 and the hadith of Mu\'adh; no classification of types is given.')

E('iddah',
  m=[r'\biddah\b', r'\biddat\b', r'\bidda\b', r'\bwaiting period\b.*\b(?:divorce|widow|death|husband|woman|women|wife)\b', r'\b(?:divorce|widow|death|husband|woman|women|wife)\b.*\bwaiting period\b', r'\bhow long must a (?:widow|divorced woman) wait\b', r'\b4 months and 10 days\b', r'\bfour months and ten days\b'],
  topic='iddah',
  text="""
Iddah is the waiting period a woman keeps after a divorce or the death of her husband. The Qur'an sets it:
- Divorce, for a woman who has her periods: {Q 2:228|Divorced women remain in waiting for three periods}.
- Divorce, for one who no longer has periods or has not had them: {Q 65:4|their period is three months}.
- Pregnancy, whether after a divorce or a death: {Q 65:4|for those who are pregnant, their term is until they give birth}.
- A widow: {Q 2:234|wait four months and ten [days]}.
- Divorce before the marriage was consummated: {Q 33:49|divorce them before you have touched them, then there is not for you any waiting period to count concerning them}.

During the iddah of a divorce the Qur'an tells the husband not to put her out of her home ({QR 65:1}). The details of what a widow may and may not do, and how to count the days in your case, differ in practice; ask a qualified scholar about your own situation.
""",
  go=['/huda/guide?id=huda-nikah'],
  review='Only what the verses state; the widow\'s conduct rules are left to a scholar on purpose.')

E('mahr',
  m=[r'\bmahr\b', r'\bmehr\b', r'\bdowry\b', r'\bbridal gift\b', r'\bbride price\b', r'\bbride gift\b', r'\bhaq mehr\b'],
  topic='mahr',
  text="""
Mahr is the gift a husband gives his wife on marriage. It is her right, and it belongs to her: {Q 4:4|And give the women [upon marriage] their [bridal] gifts graciously. But if they give up willingly to you anything of it, then take it in satisfaction and ease}.

It does not have to be money. When a man had little, the Prophet ﷺ asked him to look for something, even an iron ring, and then married them for what he knew of the Qur'an ({H bukhari:5087|Sahl ibn Sa'd reported a woman offered herself in marriage, and a man who owned little was told to look for something even an iron ring, and was married to her for the Qur'an he knew}). So it is agreed between the two of them, and kept simple.

If the husband divorces her before the marriage is consummated, half of the agreed mahr is due unless it is waived ({QR 2:237}). A lavish mahr is not required, and the family or the husband should not make it a burden. The schools differ on whether there is a minimum amount, so ask a scholar of your school for the exact rule.
""",
  go=['/huda/guide?id=huda-nikah'],
  review='The schools\' difference on a minimum is mentioned without numbers.')

E('madhhab-which',
  m=[r'\bwhich madhh?ab\b', r'\bwhich (?:school|mazhab) (?:of (?:law|fiqh) )?(?:is|do|should|are)\b', r'\bbest madhh?ab\b', r'\bwhat madhh?ab\b', r'\bwhat school (?:of (?:law|thought) )?do you follow\b', r'\bwhich school (?:of (?:law|thought) )?do you follow\b', r'\bdo you follow (?:a|any) (?:madhh?ab|school)\b', r'\bshould i follow a madhh?ab\b', r'\bdo i have to follow a madhh?ab\b'],
  topic='madhhab',
  text="""
I do not follow one school and I do not rank them. A madhhab is a school of Islamic law, a way of working out rulings from the Qur'an and the Sunnah. The four well-known Sunni schools are Hanafi, Maliki, Shafi'i and Hanbali. They agree on belief and on the main acts of worship, and differ on some details (for example the number of rak'ahs of witr, or whether jewelry is subject to zakat). I say so when an answer depends on the school.

Which one is right for you is a personal choice that most people make by where they live and whom they learn from. The Qur'an teaches: {Q 16:43|ask the people of the message if you do not know}. So pick a qualified scholar or teacher you trust, follow their guidance consistently and do not mix and match to find the easiest ruling. For a question about your own case, ask that scholar.
""",
  go=['/huda/guide?id=huda-madhhab-overview'],
  review='Neutral description only; the examples of differences are those already in the witr and jewelry answers.')

E('mothers-feet',
  m=[r'\b(?:paradise|jannah|heaven)\b.*\b(?:feet|foot)\b.*\b(?:mothers?|mom|mum)\b', r'\b(?:mothers?|mom|mum)\b.*\b(?:feet|foot)\b.*\b(?:paradise|jannah|heaven)\b', r'\bat the feet of (?:the |your )?(?:mothers?|mom|mum)\b', r'\bunder (?:the |your )?(?:mothers?|mom|mum)s? feet\b'],
  topic='paradise and mothers',
  text="""
The saying comes from a real report, with a different wording from the one you often see on posters. A man named Jahimah came to the Prophet ﷺ wanting to go out to fight and asked his advice. {HS nasai:3104|Jahimah asked to go out and fight and the Prophet asked if he had a mother, and told him to stay with her, for Paradise is beneath her feet}. It is graded sound by the scholars the app uses.

The meaning is that serving and staying close to your mother is a path to Paradise. The Qur'an also puts kindness to parents right after the worship of Allah: {Q 17:23|And your Lord has decreed that you not worship except Him, and to parents, good treatment}.
""",
  go=['/sources'],
  review='Wording of the poster version not judged here; only the nasai report is cited.')
