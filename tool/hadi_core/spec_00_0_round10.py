# Round 10 fixes (fix pass A). These entries come FIRST in the order, so every pattern here is narrow.
# Each one answers a question the round-10 testers asked and Hadi got wrong (a neighbouring answer, a
# decline, or a pack blurb). Where scholars differ the text says so, and every entry that needs a
# scholar carries a review note (it is picked up by tool/scholar_review/build_register.py).

E('app-free-cost',
  m=[r'\bis (?:this |the |your )?(?:app|ar rayaan|arrayaan|hadi|everything|it) (?:really |completely |totally |actually |fully |all )?(?:free|paid|free to use|free of charge)\b',
     r'\bhow much (?:does|do|is) (?:the |this )?(?:app|hadi|it|ar rayaan|arrayaan) cost\b', r'\bhow much (?:is|does) (?:it|this) cost\b',
     r'\b(?:do|will|would|must|have) i (?:have to |need to |actually )?pay (?:for |to use )?(?:the |this |it |hadi |anything)\b',
     r'\b(?:is there|are there) (?:a |any )?(?:subscriptions?|premium|paywall|paid plans?|in app purchases?|hidden (?:fees|costs|charges)|charges?)\b',
     r'\b(?:subscription|premium|paywall|paid plan|pro version|in app purchases?|hidden (?:fees|costs|charges))\b',
     r'\bfree to use\b', r'\bcost anything\b', r'\bwill (?:it|the app|hadi) (?:stay|always be|remain|be) free\b', r'\bis there a free (?:version|plan)\b'],
  x=[r'\b(?:zakat|nisab|sadaqah|hajj|umrah|fidyah|kaffarah|fine|debt|loan)\b'],
  topic='privacy',
  text="""
Yes, it is free today. This is what the Settings screen says, under "What is free": "Everything in this app is free today, including Hādi, and nothing asks for a card. A paid plan for extra live answers is planned but not open yet. Connecting your own AI account is optional and advanced: it is under the More options menu (top right) on the Hādi screen."

So the prayer times, the Qur'an, the lessons, the games, the stories and I are all free to use now, with no account needed. There are no points, coins or ranks anywhere in the app, and the Privacy policy says: "We do not sell personal data or show advertising based on it."

What I cannot tell you is what will be paid for in future, or its price: I have no price list, and I will not guess. The Terms and Privacy screens in Settings are the place to read the exact words, and they are marked as drafts.
""",
  go=['/settings'],
  review='Quotes the Settings "What is free" card and the Privacy policy line; checked against the screens. The policy itself is still a draft awaiting a lawyer.')

E('app-tracking',
  m=[r'\b(?:does|is|do|are) (?:this |the |your )?(?:app|ar rayaan|arrayaan|hadi|you|it) (?:track|tracking|tracks|spy|spying|spies|watch|watching|watches|monitor|monitoring|monitors|record|recording|records|collect|collecting|collects|sell|selling|sells|listen|listening|listens|log|logging|logs|store|stores|storing|share|shares|sharing)\b.*\b(?:me|my|us|our|data|location|chats?|conversations?|information|activity|usage)\b',
     r'\bam i being (?:tracked|watched|monitored|recorded|spied on)\b', r'\bwhat (?:data|information) (?:does|do) (?:this |the )?(?:app|hadi|you) (?:collect|store|keep|save|have|take|gather|log|share)\b',
     r'\bis (?:this |the )?app (?:spyware|spying on me|watching me)\b', r'\b(?:any |is there |are there )(?:tracking|trackers|spyware|analytics|telemetry)\b', r'\bdoes (?:this |the )?app (?:have|use|contain|include) (?:tracking|trackers|analytics|telemetry)\b'],
  x=[r'\b(?:prayers?|streaks?|progress|fasts?|fasting|reading|points?|score|scores|habits?|kids?|children|child)\b'],
  topic='privacy',
  text="""
Here is what the app's own Privacy policy and screens say, without adding anything:
- Your settings, bookmarks, progress, reflections and your chats with me are stored on your device. Clearing the app's data erases them.
- "We do not sell personal data or show advertising based on it."
- The Sources screen and the Support and wellbeing screen both say that nothing there is sent to analytics, and I know of no analytics or advertising service in the app.
- My answers come from a library built into the app. Only if you add your own AI key do your messages go to that provider. Messages that look like a personal crisis are answered on the device and are not sent or saved.
- A few features do reach outside services to work, and the policy lists them: prayer-time and map services, audio servers for recitation, and GitHub for updated content (which shows your IP address to that service). Location is used only if you give or allow it. If you play a YouTube or Spotify track in the Player, that service's player loads and may set cookies or show its own advertising.
- If you make an account, sign-in uses Firebase Authentication, and you can delete the account from Settings.
- A report about one of my answers is sent only when you press Send.
- The private log (totals of what you read and do) is off until you switch it on, and stays on your device.

The policy is marked as a draft and does not yet give a contact address, so please read it yourself in Settings.
""",
  go=['/settings'],
  review='Summarises the Privacy policy sections and screens; checked against the screens. The policy is a draft awaiting a lawyer, and has no contact address yet.')

E('app-notifications',
  m=[r'\b(?:turn|switch|stop|disable|enable|mute|silence|get rid of|remove|cancel|block|manage|change|set|set up|setup|control|configure|schedule)\b.*\b(?:notifications?|alerts?|reminders?)\b',
     r'\bnotifications?\b', r'\bhow (?:do|can) i get (?:prayer |adhan |azan )?(?:notifications?|alerts?|reminders?)\b', r'\b(?:prayer|adhan|azan) (?:alerts?|reminders?)\b', r'\bremind me\b.*\b(?:pray|prayer|prayers|adhan|fajr|dhuhr|asr|maghrib|isha)\b',
     r'\bwhy (?:am i getting|do i keep getting|does the app (?:send|keep sending))\b.*\b(?:alerts?|reminders?|notifications?|messages?)\b', r'\bstop (?:the )?(?:app )?(?:buzzing|pinging|beeping|bothering)\b'],
  x=[r'\b(?:zakat|hadith|ramadan|fasting|fast)\b.*\bhow (?:much|many)\b'],
  topic='notifications',
  text="""
The app has two kinds of reminders, and you control each one yourself:
- Prayer alerts: open Prayer Times. Each prayer has a bell next to it. Tap the bell to switch that prayer's alert on or off (when it is on the bell reads "Turn off the Fajr alert", for example). Lower on the same screen, the Phone notifications card has "Also remind me before", where you pick No or a number of minutes. On the Android and iPhone apps the notification arrives even when the app is closed; in a web browser, alerts only work while the page is open.
- Zakat reminders: each one has its own switch on the Zakat screen.

To stop notifications from the phone itself, use your phone's settings: Apps, then Ar-Rayaan, then Notifications. Nothing in this app sends a notification you have not switched on.
""",
  go=['/prayer', '/zakat'],
  review='Checked against the Prayer Times notification card and bell labels; the zakat reminder switches are described only in general terms.')

E('dua-toilet',
  m=[r'\b(?:dua|supplication)s?\b.*\b(?:toilet|bathroom|lavatory|restroom|washroom|latrine|call of nature|relieving)\b',
     r'\b(?:toilet|bathroom|lavatory|restroom|washroom|latrine)\b.*\b(?:dua|supplication)s?\b',
     r'\bwhat (?:do i|should i|to|do we|should we|is it that i should) (?:say|recite|read)\b.*\b(?:enter\w*|leav\w*|exit\w*|go\w* (?:in|to|into)|us\w*|coming out)\b.*\b(?:toilet|bathroom|lavatory|restroom|washroom|latrine)\b',
     r'\bghufranak\b', r'\bkhubuth\b', r'\bdua (?:for )?(?:entering|leaving|exiting) (?:the )?(?:khala|toilet)\b'],
  topic='toilet',
  text="""
On entering the toilet, the Prophet ﷺ used to say ({H bukhari:142|Anas reported that whenever the Prophet went into the toilet he said: O Allah, I seek refuge with You from the male and female evil spirits}):

{AR bukhari:142|اللهم إني أعوذ بك|والخبائث}

Allahumma inni a'udhu bika minal-khubuthi wal-khaba'ith.
Meaning: O Allah, I seek refuge in You from the male and female devils (and from filth and evil).

On coming out, he used to say ({H abudawud:30|Aisha reported that when the Prophet came out of the toilet he said: Ghufranaka, Your forgiveness}):

{AR abudawud:30|غف|رانك}

Ghufranaka. Meaning: I ask You for Your forgiveness.

Say the first before you go in (or before uncovering yourself, if you are outdoors), and the second when you come out. Many people begin with "Bismillah" first, and enter with the left foot and leave with the right; scholars differ on how firm the report for "Bismillah" is, and the du'a above is the part in Sahih al-Bukhari. These are said silently, in the heart or under the breath, not aloud inside the toilet. The rest of the manners are in the istinja answer: ask me "toilet etiquette".
""",
  review='Arabic is copied from the cited hadith by the build script; the transliteration is typed by hand and needs a reader to check it. The Bismillah, foot-order and silent-recitation points are standard teaching, not text-checked here.')

E('faith-doubt',
  m=[r'\b(?:losing|lost|lose|loosing) (?:my |the )?(?:faith|iman|belief|religion|deen)\b', r'\bmy (?:faith|iman|belief) (?:is|has|feels|got|was) (?:weak|weaker|gone|slipping|fading|dying|shaky|shaken|dead|low)\b',
     r'\bi (?:have|am having|keep having|got|ve got|feel) (?:some |many |a lot of |lots of )?doubts?\b', r'\bdoubts? (?:about|in|on|regarding) (?:islam|my faith|my religion|allah|god|the quran|the prophet|religion|everything)\b',
     r'\b(?:struggling|struggle|struggles) (?:with|in) (?:my )?(?:faith|iman|belief|believing)\b', r'\bi (?:am not|m not|am no longer|dont feel|do not feel|dont know if i am|do not know if i am) (?:sure|certain|convinced) (?:i |that i )?(?:believe|still believe|have faith)\b',
     r'\bi (?:dont|do not|cant|cannot|can t) (?:really )?(?:feel|find|have) (?:any |the |my )?(?:faith|iman|belief|connection to (?:allah|god))\b', r'\bquestioning (?:my |the )?(?:faith|islam|religion|iman|belief|everything)\b',
     r'\bi (?:dont|do not) know (?:if|whether|what) (?:i )?(?:believe|to believe)\b', r'\bwhat if (?:islam|it all|religion|everything) (?:is|isnt|is not) (?:true|real|false|wrong)\b'],
  x=[r'\b(?:increase|strengthen|boost|build|improve|renew|refresh|restore)\b', r'\b(?:leave|leaving|quit|quitting|abandon|renounce|exit)\b'],
  topic='faith',
  text="""
Thank you for telling me this. It is not easy to say, and I will not rush to fix you or lecture you.

Doubt is more common than people admit, and it is not the same as having left. Some of the Companions came to the Prophet ﷺ troubled by thoughts they felt were too terrible to say out loud. He did not shame them ({H muslim:132|some Companions told the Prophet they found in their minds thoughts too grave to speak of, and he said that this is the clear faith}). Ibrahim ﷺ asked Allah to show him how He gives life to the dead; when Allah asked "Have you not believed?" he said {Q 2:260|Yes, but [I ask] only that my heart may be satisfied}. Wanting the heart settled is not the same as denying.

Some things that often help:
- Say what the doubt is actually about. Is it a question (why is there suffering, how do I know the Qur'an is preserved, how do I know there is a God)? Is prayer feeling empty? Did someone in the community hurt you? Each needs a different answer. Tell me in your own words and I will answer from the sources where I can, and say plainly where I cannot.
- Do not carry it alone. A trusted teacher or imam who can listen without panicking, or a friend, is worth finding. A scholar can answer what I cannot.
- Keep the small things you can: a short prayer, a few ayat, a single honest sentence to Allah. Faith rises and falls; it is not always at the same height. Allah says: {Q 2:186|And when My servants ask you, [O Muhammad], concerning Me - indeed I am near}.
- If this comes with heaviness, hopelessness or thoughts of harming yourself, please tell me, and I will take that first. "Need help now" opens help lines for your country.

I am an app, not a person or a scholar, and I cannot see your heart. What I can do is stay with the question with you.
""",
  go=['/academy/aqeedah', '/feelings'],
  review='Pastoral wording, not a ruling. The two reports and verses are checked against their sources. Would benefit from a pastoral reader (an imam or counsellor) to check the tone.')

E('apostasy-ruling',
  m=[r'\bapostas\w*\b', r'\bapostates?\b', r'\bmurtad\w*\b', r'\briddah\b', r'\bridda\b',
     r'\b(?:leaving|leave|leaves|left|quit|quitting|abandon\w*|renounc\w*|exit\w*) (?:from )?(?:the )?(?:islam|religion of islam)\b.*\b(?:punish\w*|death|kill\w*|penalty|penalties|ruling|rulings|law|laws|sin|allowed|permitted|haram|consequences?|crime|executed|execution|hell|fire)\b',
     r'\b(?:punish\w*|death|kill\w*|penalty|penalties|ruling|rulings|law|laws|sin|allowed|permitted|haram|consequences?|crime|executed|execution)\b.*\b(?:leaving|leave|leaves|left|quit|quitting|abandon\w*|renounc\w*) (?:from )?(?:the )?islam\b',
     r'\bwhat happens (?:if|when) (?:a )?(?:muslim|someone|you|i|one|people) (?:leave|leaves|left|quit|quits|abandons?) islam\b', r'\bcan (?:a )?(?:muslim|someone|you) (?:leave|quit|abandon) islam\b', r'\bfreedom of (?:religion|belief|faith|conscience)\b', r'\bcompulsion in religion\b',
     r'\bis it (?:true|a fact) that (?:muslims|ex muslims|people who leave islam)\b.*\b(?:killed|executed|die|death)\b', r'\bex muslims?\b'],
  x=[r'\b(?:my|our) (?:son|daughter|child|children|husband|wife|friend|brother|sister|father|mother)\b',
     # A question for a verdict (the punishment, the penalty, the ruling) is
     # a legal question: it goes to the ruling gate and its scholar reply,
     # as it always has, not to a summary from me.
     r'\b(?:punish\w*|penalty|penalties|death|kill\w*|executed|execution|ruling|rulings|verdict|fatwa|crime)\b'],
  topic='apostasy',
  text="""
This is one of the most argued-over questions about Islam, so here is a straight answer with the texts and the disagreement, not a dodge.

What the texts say:
- The Qur'an protects freedom of belief: {Q 2:256|There shall be no compulsion in [acceptance of] the religion}, and {Q 18:29|whoever wills - let him believe; and whoever wills - let him disbelieve}. It warns of the loss in the Hereafter for one who turns back and dies in disbelief ({QR 2:217}). It does not name a punishment for this in the world.
- Hadith: {HS bukhari:3017|Ibn Abbas reported that the Prophet said if somebody discards his religion, kill him}, and {HS bukhari:6878|Abdullah reported the Prophet said the blood of a Muslim who confesses that none has the right to be worshipped but Allah cannot be shed except in three cases: a life for a life, a married person who commits illegal sexual intercourse, and the one who leaves Islam and separates from the community}.

How scholars have read them:
- The majority of classical jurists held that someone who openly leaves Islam is first called to repent, and that if he does not, a court may punish it with death. The schools differ on details, such as the time given to repent and whether a woman is treated the same (the Hanafi school does not put a woman to death for it).
- Other scholars, early and today, read the reports as a penalty for treason, deserting to an enemy or fighting the community (note the words "and separates from the community"), not for a private change of belief. They point to the verses above, and to the bedouin who asked the Prophet to cancel his pledge to Islam and left Madinah: he refused to cancel it, but did not punish him ({H bukhari:7211|Jabir reported that a bedouin pledged himself to Islam, then asked the Prophet three times to cancel his pledge, was refused, and left Madinah}).
- On one point there is wide agreement: this belongs to a lawful court, never to a family, a neighbour or a crowd. A person who hurts someone for leaving Islam is acting against Islam, and breaks the law in most countries.

I do not give rulings, and this is not a verdict. A qualified scholar can tell you the position of a school in detail.
""",
  go=['/sources'],
  review='Balanced summary of a contested question: the classical majority position, the restricted-to-treason reading, and the agreement that no private person may act. Needs a scholar to confirm the attributions (including the Hanafi position on women) and the wording.')

E('leaving-islam-personal',
  m=[r'\b(?:thinking (?:of|about)|want(?:ed)? to|going to|wanna|planning to|considering|should i|about to|ready to|i want out and)\s+(?:be\s+)?(?:leave|leaving|quit|quitting|abandon\w*|renounc\w*|exit\w*|stop being)\b.*\b(?:islam|muslim|religion|faith|deen)\b',
     r'\bwhat do you think (?:about|of) (?:me )?(?:leaving|quitting|abandoning|renouncing)\b.*\b(?:islam|religion|faith)\b', r'\bi (?:dont|do not|no longer|cant|cannot) want to be (?:a )?muslim( anymore| any more| now)?\b',
     r'\bi (?:left|have left|am leaving|am done with|quit|have quit|am quitting|gave up) (?:on )?(?:islam|the religion|my religion|being muslim|my faith)\b', r'\bi (?:no longer|dont|do not|stopped|stop) believ\w* (?:in )?(?:islam|allah|god|the quran|religion)\b',
     r'\bi (?:want|wish) (?:to )?(?:leave|get out of|be out of) islam\b', r'\bi am (?:an? )?(?:ex muslim|exmuslim|atheist|agnostic|apostate)\b', r'\bi (?:became|have become|am becoming) (?:an? )?(?:atheist|agnostic|ex muslim)\b',
     r'\bi (?:hate|am sick of|am tired of|cant stand) (?:being (?:a )?muslim|islam|my religion)\b'],
  x=[r'\b(?:my|our) (?:son|daughter|child|children|husband|wife|friend|brother|sister|father|mother)\b'],
  topic='faith',
  text="""
I am glad you told me, and did not just go quiet with it. I will be honest with you: I will not pretend to be neutral about what Islam teaches, and I will not pressure you either.

What the Qur'an says first is that belief cannot be forced: {Q 2:256|There shall be no compulsion in [acceptance of] the religion}. No person, family or app is meant to frighten you into faith. Muslims also believe that turning away from the truth is serious before Allah ({QR 3:85}), and I would not be honest if I hid that. But the judgment on any heart belongs to Allah, not to me and not to anyone around you.

What I would rather do is hear what is behind it. People step away for very different reasons: honest questions nobody answered well, being hurt by Muslims or by a harsh family or community, grief, a faith that went numb, a new life or relationship, or simply not believing. Those are not the same, and I would speak differently to each. If you want to tell me, I will listen and answer from the sources where I can, and say so where I cannot.

A few things that may matter right now:
- You do not have to decide today, or alone. A teacher or imam who listens without shouting, or a friend, is worth talking to, and so is anyone you trust outside Islam.
- If you are afraid of how your family or community would react, your safety comes first. "Need help now" opens help lines for your country. By default, what you type to me stays on your device.
- Whatever you decide, you are still a person with dignity. No private individual has the right to harm or punish you for it.

Tell me what is behind it, if you like, and I will start there.
""",
  go=['/academy/aqeedah', '/feelings'],
  review='Pastoral wording, not a ruling. It states the Islamic position honestly (no compulsion; turning away is serious before Allah) without threatening. Needs a pastoral reader to check the tone.')

E('nine-five-sword',
  m=[r'\b9 ?:? ?5\b', r'\b(?:surah |sura )?(?:at )?(?:tawbah|taubah|tawba|bara.?ah|baraat)\b.*\b(?:5|five|kill|sword|polytheists|idolaters)\b', r'\bsword verses?\b', r'\bayat? (?:as )?sayf\b',
     r'\bkill (?:the )?(?:polytheists|idolaters|mushrikin|mushrikeen|pagans|disbelievers|unbelievers|infidels|kafirs?|non muslims?)\b', r'\b(?:quran|koran|islam|muslims?)\b.*\b(?:say|says|tell|tells|command|commands|order|orders|teach|teaches|allow|allows)\b.*\bkill\b.*\b(?:non muslims?|disbelievers|infidels|kafirs?|unbelievers|polytheists|idolaters|pagans|christians|jews)\b',
     r'\bfight (?:them|the polytheists|the disbelievers) wherever you find\b', r'\bwherever you find them\b'],
  topic='peace',
  text="""
Surah at-Tawbah 9:5 is often quoted on its own. Read in order, it belongs to a passage about a specific war: the idolaters of Makkah who had broken their treaties with the Muslims.

- The passage opens by ending the treaties with those idolaters who had broken them ({QR 9:1}). In the same breath it protects those who had not: {Q 9:4|Excepted are those with whom you made a treaty among the polytheists and then they have not been deficient toward you in anything or supported anyone against you; so complete for them their treaty until their term [has ended]}.
- Verse 5 then says: {Q 9:5|And when the sacred months have passed, then kill the polytheists wherever you find them and capture them and besiege them and sit in wait for them at every place of ambush. But if they should repent, establish prayer, and give zakah, let them [go] on their way}.
- The very next verse commands protection, not killing: {Q 9:6|And if any one of the polytheists seeks your protection, then grant him protection so that he may hear the words of Allah. Then deliver him to his place of safety}.
- And the reason is given a few verses on: {Q 9:13|Would you not fight a people who broke their oaths and determined to expel the Messenger, and they had begun [the attack upon] you the first time}.

How scholars read it: most take it as addressed to those particular hostile idolaters, at that time and in a state of war, and not as a standing order to kill anyone for not being Muslim. The same book says {Q 60:8|Allah does not forbid you from those who do not fight you because of religion and do not expel you from your homes - from being righteous toward them and acting justly toward them}, and the Prophet ﷺ warned: {HS bukhari:3166|Abdullah ibn Amr reported the Prophet said whoever killed a person having a treaty with the Muslims shall not smell the smell of Paradise}. Some classical commentators did say this verse cancelled the gentler verses on tolerance (the "sword verse" idea); many scholars, early and modern, reject that and keep 9:5 tied to its context of war. Scholars differ, and I am not the one to settle it.

If you want the wider teaching on fighting and peace, ask me "what is jihad?". For a ruling, ask a qualified scholar.
""",
  go=['/quran'],
  review='Reads 9:5 in its context (9:1-13) from the cited verses; the account of the commentators on abrogation is a summary of a disagreement and needs a scholar to confirm. Flagged for scholar review.')

E('app-maker-tradition',
  m=[r'\bwho (?:made|makes|built|builds|created|creates|develops?|developed|owns?|owned|runs?|funds?|funded|is behind|are behind) (?:this|the|your) (?:app|application|company|project)\b.*\b(?:sunni|shia|shiite|sect|madhhab|tradition|school)\b',
     r'\b(?:sunni|shia|shiite|sect|madhhab|tradition|school)\b.*\bwho (?:made|makes|built|builds|created|creates|develops?|developed|owns?|owned|runs?|funds?|funded|is behind|are behind) (?:this|the|your) (?:app|application|company|project)\b',
     r'\bis (?:this|the|your) (?:app|hadi)\b.*\b(?:sunni|shia|shiite|salafi|sufi|barelvi|deobandi|ahmadi|wahhabi|sect)\b', r'\bwhich (?:sect|tradition|madhhab|school|group|branch) (?:is |does )?(?:this |the |your )?(?:app|hadi|ar rayaan)\b',
     r'\bwhat (?:sect|tradition|madhhab|school|branch) (?:is|does) (?:this |the |your )?(?:app|hadi)\b', r'\bare you (?:sunni|shia|shiite|salafi|sufi)\b'],
  topic='about hadi',
  text="""
Two questions, answered plainly.

Who made it: the app does not name an owner, a company or a funder on any screen I can read from, so I have none to give you, and I will not guess one. What it does say: the Terms of Service (in Settings) describe Ar-Rayaan as a study and reflection companion, not a religious authority, and Our Sources says no named scholar has reviewed the app yet.

Sunni or Shia: I answer from the Sunni tradition, from the Qur'an and the Sunnah as the Sunni scholars transmit them, and where schools of law differ I name the Hanafi, Maliki, Shafi'i and Hanbali views. The hadith collections the app cites are the six main Sunni books (Sahih al-Bukhari, Sahih Muslim, and the four Sunan). It does not teach Shia law, and it does not rank or attack any Muslim group; where a question divides Sunni and Shia I say so rather than choose for you. Ask me "what is the difference between Sunni and Shia?" for the neutral account.

On cost: everything in this app, including me, is free today, and nothing asks for a card.
""",
  go=['/sources', '/settings'],
  review='States the tradition the app answers from (Sunni, with the four schools) as the Hadi about-screen already says. Owner and funder are deliberately not named because the app names none; the owner may wish to publish them.')

E('companion-friend',
  m=[r'\b(?:be|become) my (?:friend|companion|buddy|bestie|mate|best friend)\b', r'\b(?:are|r) you my (?:friend|companion|buddy)\b', r'\bcan (?:we|you and i) be (?:friends|best friends|buddies)\b', r'\bi (?:want|need) (?:a |you as a )?(?:friend|someone to talk to|somebody to talk to)\b',
     r'\bi have no (?:friends?|one to talk to|body to talk to)\b', r'\b(?:will|would) you be my friend\b', r'\bdo you (?:like|love|care about|miss) me\b', r'\bcan i (?:talk|vent) to you\b', r'\bcan we (?:just )?(?:talk|chat)\b'],
  topic='about hadi',
  text="""
I would like to be useful to you, and I will be honest about what I am: an app. I am not a person. I do not remember you the way a friend does, I cannot sit with you in a hard hour, and I will not notice if you go quiet. A friend should be a real person, and I do not want to stand in the place of one.

What I can do is talk about Islam and about this app, give you a du'a or a story, think a question through with you, and listen to what is on your mind. You are welcome to do that here, any time.

For the rest, real people: a relative or an old friend you have lost touch with; someone at your local masjid, or a class or halaqah there; a neighbour or colleague; and in a hard season, an imam or counsellor you can see in person. The Prophet ﷺ said {HS tirmidhi:2378|Abu Hurairah reported the Prophet said a man is upon the religion of his friend, so let one of you look at whom he befriends}. I would like you to have good ones.

If you are feeling very alone or low, tell me, and I will stay with that. "Need help now" opens help lines for your country.
""",
  go=['/feelings', '/search'],
  review='Honest-companion wording (what the app is not) and a pointer to real people; the one hadith is cited with its grade. No ruling.')

E('bored',
  m=[r'^(?:im |i am |i m )?(?:so |really |very |just )?bored$', r'\b(?:im|i am|i m|i feel) (?:so |really |very |just )?bored\b', r'\bentertain me\b'],
  topic='about hadi',
  text="""
Let us fix that. A few ideas:
- A story: the Stories section has the prophets, the companions, the Prophet's life and short tales, each with its sources.
- A game: Games has Qur'an knowledge, Stories trivia, the 99 Names, a word search, Ludo and chess. They keep no points, coins or ranks.
- A question: something you have always wondered about Islam. Ask me, and I will answer from the sources or say plainly that I cannot.
- Something small that is good for you: a short du'a, or a few ayat read slowly.

I am an app, so I cannot play or chat like a friend, but I am glad to help you find something worth your time.
""",
  go=['/stories', '/games'],
  review='')

E('evolution',
  m=[r'\bevolution\b', r'\bevolve\w*\b', r'\bdarwin\w*\b', r'\bnatural selection\b', r'\b(?:did|do|were) (?:humans?|we|men|people|adam) (?:come|descend|evolve|created)\w* (?:from|out of) (?:apes?|monkeys?|animals?|primates?)\b', r'\bhuman origins?\b.*\b(?:science|islam)\b'],
  topic='evolution',
  text="""
Short, honest answer: Muslims do not all agree on this, and it is a question for a scholar who also understands the science. I do not have a scholar-reviewed position to give you.

What nearly all scholars agree on: Allah is the Creator of everything, and the Qur'an teaches that Adam was created by Allah from clay and given a soul breathed from Him, and that the angels were told to prostrate to him ({Q 38:71-72|Indeed, I am going to create a human being from clay. So when I have proportioned him and breathed into him of My [created] soul, then fall down to him in prostration}). It also says: {Q 3:59|Indeed, the example of Jesus to Allah is like that of Adam. He created Him from dust}.

Where views divide:
- Many scholars, early and recent, say Adam was created directly and was not descended from earlier creatures, so they reject the evolution of human beings, while some accept change over time in other living things.
- Some contemporary Muslim scholars and scientists accept that the sciences describe how life developed, and read the Qur'an's account of Adam as a special act of Allah within that history.
- Others reject evolutionary theory as a whole, on religious or on scientific grounds.

I will not pick one for you. If it worries your belief, that is a fair question: ask a qualified scholar, ideally one who has studied the science, and keep asking.
""",
  go=['/academy/aqeedah'],
  review='A map of the positions, not a ruling: needs a scholar (ideally one trained in the sciences) to check that each position is fairly described.')

E('women-equality',
  m=[r'\b(?:does|is|do) (?:islam|the quran|muslims?|the religion)\b.*\b(?:women|woman|females?)\b.*\b(?:unequal|inferior|equal|oppress\w*|second class|less than|lower|subordinate|respect\w*|rights|treated)\b',
     r'\bwomen(?:s)? rights (?:in|under) islam\b', r'\bis (?:islam|the quran) (?:sexist|misogynist\w*|patriarchal|oppressive to women)\b', r'\bequality (?:of|between) (?:men and women|women and men|the sexes|genders?)\b', r'\bstatus of (?:women|woman) in islam\b',
     r'\bwhy (?:does|is) islam (?:oppress|mistreat|hate|degrade|discriminate against)\b.*\b(?:women|woman|females?)\b', r'\bislam (?:and|on) (?:women|gender equality|feminism)\b', r'\bare (?:women|men) equal in islam\b', r'\bdoes islam (?:treat|view|see|consider) women\b'],
  x=[r'\b(?:hijab|veil|niqab|burqa|dress|inherit\w*|beat\w*|hit\w*|polygam\w*|testimony|witness\w*|lead\w* prayer|imam)\b'],
  topic='women',
  text="""
A fair answer has two parts: what the texts give women, and where Muslims still argue.

Equal in worth before Allah: {Q 33:35|Indeed, the Muslim men and Muslim women, the believing men and believing women, the obedient men and obedient women, the truthful men and truthful women}, "for them Allah has prepared forgiveness and a great reward". And {Q 16:97|Whoever does righteousness, whether male or female, while he is a believer - We will surely cause him to live a good life}. Both come from one soul ({QR 4:1}), and no one is above another except in righteousness ({QR 49:13}).

Rights the texts give a woman: a share of inheritance of her own ({QR 4:7}), her own earnings and property ({QR 4:32}), the mahr that is hers, and a say in her marriage: {HS bukhari:5136|The Prophet said a matron should not be given in marriage without consulting her, and a virgin not without her permission, which is her silence}. The Prophet ﷺ also said {HS ibnmajah:1978|Abdullah ibn Amr reported the Prophet said the best of you are those who are best to their womenfolk}.

Where there are differences in the rules, which people notice: in most inheritance cases a son's share is twice a daughter's ({QR 4:11}), and in a written debt contract two women may stand in for one male witness ({QR 2:282}). Scholars explain these by the different financial duties the two carry; others, Muslim and not, feel they are unequal, and there is a living debate about how they apply today. Many customs that harm women in Muslim countries come from culture, not from the texts, and Islam does not excuse them.

I cannot settle the debate, and this is not a ruling. If you tell me which rule troubles you, I will take it by itself and give the sources.
""",
  go=['/academy/womens'],
  review='Balanced summary of rights and differences; the explanation of the inheritance and witness rules is the usual scholarly one but contested. Needs a scholar to check, ideally including a woman scholar.')

E('inheritance-half',
  m=[r'\bwhy (?:does|do|is|are|should) (?:a |the )?(?:women|woman|daughters?|sisters?|females?|girls?)\b.*\b(?:inherit\w*|half|share|less)\b', r'\b(?:women|woman|female|daughters?)\b.*\binherit\w*\b.*\b(?:half|less|unfair|unequal|two|2)\b',
     r'\binherit\w*\b.*\b(?:women|woman|female|daughters?)\b.*\b(?:half|less|unfair|unequal)\b', r'\bmale (?:gets|get|receives?|inherits?) (?:double|twice|two)\b', r'\bdouble (?:share|portion)\b.*\b(?:men|male|sons?|brothers?)\b', r'\bwhy do (?:men|sons|brothers) (?:get|inherit|receive) (?:more|double|twice)\b', r'\b4 ?11\b'],
  topic='inheritance',
  text="""
The rule comes from the Qur'an: {Q 4:11|Allah instructs you concerning your children: for the male, what is equal to the share of two females}. It sits alongside the verse that gave women a fixed, obligatory share of their own: {Q 4:7|For men is a share of what the parents and close relatives leave, and for women is a share of what the parents and close relatives leave, be it little or much - an obligatory share}.

It is not "women always get half". The doubling applies to a son and a daughter inheriting from the same parent. In other cases they are equal or the woman receives as much: both parents get a sixth if the deceased left children ({Q 4:11|And for one's parents, to each one of them is a sixth of his estate if he left children}), and brothers and sisters through the mother share equally ({QR 4:12}).

The reasons scholars give (this is explanation, not part of the verse): the man carries financial duties the woman does not. He must pay the mahr, and maintain his wife and children, and often other relatives, whatever his wife owns. A woman's inheritance, mahr and earnings stay hers, and she is not required to spend them on the household. So, they say, the two shares are not the same weight in practice.

Some people still find it unfair, especially in families where women also support the household; Muslim scholars and writers discuss it, and I cannot settle it. The share itself is fixed by the Qur'an. For a real estate, a qualified scholar must work out each person's share, because it depends on who survives.
""",
  go=['/academy/transactions'],
  review='The verse is quoted exactly; the stated reasons are the usual scholarly explanation and are contested. Needs a scholar to check.')

E('handshake-opposite-gender',
  m=[r'\b(?:shak\w*|handshakes?|hand ?shakes?) (?:hands?)?\b.*\b(?:wom[ae]n|girls?|females?|ladies|lady|opposite|non ?mahram|ajnabi|ajnabiyyah|men|man|males?|boys?|coworkers?|colleagues?|boss|teacher|doctor|sister|brother in law)\b',
     r'\b(?:wom[ae]n|girls?|females?|ladies|lady|opposite (?:sex|gender)|non ?mahram|men|man|males?|boys?)\b.*\b(?:shak\w* hands?|hand ?shakes?|handshakes?)\b', r'\b(?:hand ?shake|handshakes)\b.*\b(?:islam|haram|allowed|permissible|halal)\b'],
  topic='etiquette',
  text="""
Scholars differ on this, so I will give you the views and the texts rather than one verdict.

The texts: Aisha reported that when women pledged themselves to the Prophet ﷺ he took the pledge by words alone ({H muslim:1866|Aisha reported that when believing women migrated to Madinah they were tested by the verse of allegiance, and whoever agreed to it, the Messenger said to her: I have accepted your pledge, by words only}), and that his hand never touched the hand of a woman other than one he was permitted to ({H bukhari:7214|Aisha reported that the Prophet used to take the pledge from women by words only, and his hand did not touch any woman's hand except the one his right hand possessed}).

Views:
- Most scholars of the four schools say a man and a woman who are not close relatives (not mahram) should not shake hands, and that this is forbidden, with some allowing it with an old person where desire is not a concern.
- Some contemporary scholars allow it when there is no desire and no other way to be polite, such as at work or in a society where refusing causes real hurt, while saying that not shaking is better.
- Many Muslims politely avoid it either way. A smile, a hand on the chest and a warm greeting ("peace be upon you", or "good to meet you") is accepted by almost everyone, and you can say, kindly, "I do not shake hands, nothing personal".

For your own situation, follow your school or ask a scholar you trust. This is not a ruling.
""",
  go=['/huda'],
  review='A fair summary of a contested point; the hadith are cited with their numbers. The count and attribution of the permissive view need a scholar to check.')

E('wudu-mistakes',
  m=[r'\b(?:common |usual |frequent |typical |big |biggest )(?:mistakes?|errors?)\b.*\bwudu\b', r'\bwudu\b.*\b(?:mistakes?|errors?|wrong|incorrect|invalid|not valid|valid)\b', r'\bwhat (?:do|can|did) (?:i|people|we) (?:do )?wrong\b.*\bwudu\b', r'\bam i doing wudu (?:right|correctly|wrong)\b', r'\bhow (?:do|can) i know (?:if )?my wudu is (?:valid|right|correct|complete)\b'],
  x=[r'\bwhat breaks\b', r'\bwhat nullif\w*\b', r'\bwhat invalidat\w*\b'],
  topic='wudu',
  text="""
Mistakes people often make in wudu, and the points they miss:
- Missing the heels or part of the feet. The Prophet ﷺ saw people hurrying and rubbing wet hands over their feet and called out: {HS muslim:241|Abdullah ibn Amr reported that some people performed ablution hurriedly on a journey and their heels were dry, and the Prophet said woe to dry heels, because of Hell-fire, and told them to make their ablution thorough}.
- Rushing, or wiping instead of washing. The face, the arms to the elbows and the feet must be washed, and the head wiped ({QR 5:6}).
- Skipping the elbows, the area under the chin, or between the fingers and toes, or not wiping the whole head (the schools differ on how much of the head must be wiped).
- Anything on the skin that keeps water from reaching it, such as paint, thick nail polish or wax. Water must touch the skin.
- Wasting water. The Prophet ﷺ made wudu with about a mudd of water ({H bukhari:201|Anas reported that the Prophet used to perform ablution with one mudd of water}). Being careful with water is part of the sunnah.
- Doubting again and again. If you are not sure whether you broke wudu, you stay in wudu until you are certain.

For the exact order of the steps, ask me "how do I make wudu" and I will list them.
""",
  go=['/huda/guide?id=huda-wudu'],
  review='Which points need the whole head wiped, and nail polish, differ by school and are standard teaching, not text-checked here. The two hadith are cited with their numbers.')

E('intentions-hadith-grade',
  m=[r'\b(?:grade|graded|authentic|authenticity|sahih|saheeh|hasan|daif|weak|fabricated|real|true|genuine|source|reference|where is|number|reliable)\b.*\b(?:actions|deeds|works) (?:are|is) (?:only |judged )?(?:by|according to|with) (?:the )?intentions?\b',
     r'\b(?:actions|deeds|works) (?:are|is) (?:only |judged )?(?:by|according to|with) (?:the )?intentions?\b.*\b(?:grade|graded|authentic|authenticity|sahih|saheeh|hasan|daif|weak|fabricated|real|true|genuine|source|reference|number|reliable)\b',
     r'\binnama\w*\b.*\b(?:grade|authentic|sahih|source|number)\b'],
  topic='hadith',
  text="""
"Actions are by intentions" is among the most firmly established of all hadith. It is reported by Umar ibn al-Khattab, and it is the very first hadith in Sahih al-Bukhari ({H bukhari:1}), and also in Sahih Muslim ({H muslim:1907}). Because both Sahih collections include it, scholars call it agreed upon, and neither gives it a separate grade: inclusion in the two Sahihs is the highest level of acceptance. It is also the first of the Forty Hadith of Imam an-Nawawi.

Its meaning, in short: a deed is judged by what the person meant by it, so the same act can be worship or nothing depending on the intention. Look at the source card under this answer, or open the Hadith screen to see it with its number.
""",
  go=['/hadith'],
  review='Collection numbers verified in the hadith corpus; the statement about acceptance of the two Sahihs is the standard view.')

E('pray-in-english',
  m=[r'\b(?:pray|prayer|prayers|recite|read|say|salah)\b.*\bin english\b', r'\bin english\b.*\b(?:pray|prayer|prayers|recite|dua|salah|fatiha|quran)\b',
     r'\b(?:pray|prayer|recite|read|say)\b.*\b(?:in my own language|in my language|in urdu|in bengali|in bangla|in turkish|in any language|in another language|in a language other than arabic|in my mother tongue|in translation)\b',
     r'\bdo i (?:have to|need to|must|really need to) (?:pray|recite|say|read|learn).*\barabic\b', r'\bcan i (?:pray|recite|say|read) .*\b(?:own language|my language|translation)\b', r'\bpray without (?:knowing|learning|memori\w+|speaking|understanding) arabic\b',
     r'\barabic (?:required|necessary|needed|mandatory|compulsory) (?:for|in) (?:the )?prayers?\b', r'\bi (?:dont|do not|cant|cannot) (?:speak|know|read) arabic\b.*\bpray\b', r'\bis it (?:okay|ok|allowed|permissible|valid) to pray in (?:english|another language|my language)\b'],
  topic='prayer words',
  text="""
Scholars differ, so here is the honest picture, then what to do now.

- The Prophet ﷺ taught the prayer in Arabic, and the Qur'an recited in it is Arabic. Most scholars (the Maliki, Shafi'i and Hanbali schools, and the two companions of Abu Hanifa) say the Qur'an and the words of the prayer must be said in Arabic, and that a person who really cannot yet say them says what they can and keeps learning.
- A narrower opinion attributed to Abu Hanifa allowed the Fatihah in another language for someone who cannot recite Arabic; the later Hanafi scholars took the other view. Ask an imam of your school which applies to you.
- Du'as in your own language: outside the prayer, you can ask Allah in any language, right after the salam. Inside the obligatory prayer, scholars differ on whether you may make a du'a in your own words.

What to do now, as a new learner: do not wait to be perfect. If you cannot yet say al-Fatihah, the Prophet ﷺ taught a man who could not memorise any of it to say "Subhanallah, walhamdulillah, wa la ilaha illallah, wallahu akbar, wa la hawla wa la quwwata illa billah" in its place while he learned ({H abudawud:832|A man who could not learn the Qur'an was told to say glory be to Allah, praise be to Allah, there is no god but Allah, Allah is most great, and there is no might nor strength but in Allah}). The New Muslim Path teaches the words step by step: Day 5 for the movements, Day 11 for the Fatihah and this fallback, and Day 13 for this very question.

I am not giving a ruling; ask an imam about your own case.
""",
  go=['/new-muslim', '/huda/guide?id=huda-prayer'],
  review='States the difference among the schools and the Abu Hanifa narration in general terms; needs a scholar to confirm the attributions. The fallback phrase is cited from Abu Dawud 832 (graded hasan by al-Albani).')

E('forgot-prayer-words',
  m=[r'\b(?:what if|if) i (?:forget|forgot|cant remember|cannot remember|dont remember|do not remember|dont know|do not know|mess up|make a mistake in|get stuck in|go blank in)\b.*\b(?:words?|prayers?|recit\w+|fatiha|surah|dua|ayat|verses?|arabic|what to say)\b',
     r'\bi (?:forgot|forget|cant remember|dont remember|dont know|do not know|cannot remember) (?:the |some of the |what to say in |what to recite in )?(?:words|prayers?|recitation|fatiha|surah|what to say|what to recite)\b', r'\bi (?:dont|do not) (?:know|have) (?:any |the )?(?:words|surahs?|fatiha|quran|arabic) (?:to pray|for prayer|for the prayer|yet|memorised|memorized)\b',
     r'\bi cant (?:memorise|memorize|learn|remember) (?:the |any )?(?:fatiha|surahs?|quran|prayers?|words)\b', r'\bnot memori[sz]ed (?:the )?(?:fatiha|prayers?)\b', r'\bwhat (?:do|should) i (?:say|do) (?:if|when) i (?:cannot|cant|dont|do not) (?:know|remember|recite|say) (?:the )?(?:fatiha|words|surah|quran)\b'],
  x=[r'\b(?:rakah|raka|sujud|ruku|forgot (?:the |an )?extra|tashahhud|sit)\b'],
  topic='prayer words',
  text="""
First: do not be afraid, and do not stop praying. Everyone who learns the prayer goes blank at times, and Allah sees the effort.

- If you are in the prayer and cannot recall a word, say what you can, stay still, and carry on. A slip does not need you to start again.
- If you have not yet learned al-Fatihah, the Prophet ﷺ taught a man who could not memorise any of the Qur'an to say "Subhanallah, walhamdulillah, wa la ilaha illallah, wallahu akbar, wa la hawla wa la quwwata illa billah" in its place until he learned it ({H abudawud:832|A man who could not learn the Qur'an was told to say glory be to Allah, praise be to Allah, there is no god but Allah, Allah is most great, and there is no might nor strength but in Allah}). The Path (Day 11) has these words in Arabic with the sound and the meaning.
- Use the New Muslim Path to learn a little each day, and keep a card with the words beside you at first. Listen to a reciter for the sound.
- If you forget a whole act (a bow, a prostration, a sitting) or are unsure how many rak'ahs you prayed, there is a remedy: ask me "what is sujud as-sahw?".

If the question is about a prayer you already prayed and you are worried about whether it counts, a teacher can tell you; I cannot rule on it.
""",
  go=['/new-muslim', '/huda/guide?id=huda-sujud-sahw'],
  review='The fallback phrase is cited from Abu Dawud 832 (graded hasan by al-Albani); the encouragement not to restart after a slip in recitation is general advice, not text-checked.')

E('sitting-in-prayer-words',
  m=[r'\bwhat (?:do|should|can|to) (?:i |we |you )?(?:say|recite|read|do)\b.*\b(?:sit|sitting|sat|sit down|sit in|between the two|in the middle|after the second)\b.*\b(?:prayers?|rakah)\b',
     r'\bwhat (?:do|should|to) (?:i |we )?(?:say|recite|read)\b.*\b(?:when|while) (?:i )?(?:sit|sitting|sat)\b', r'\bwhat (?:to|do i|should i) (?:say|recite|read) (?:in|during) (?:the )?(?:last |second |final |first )?(?:sitting|sit)\b',
     r'\bwords (?:of|for) (?:the )?(?:sitting|sit)\b', r'\bwhat (?:comes|do i say|do we say) after (?:the )?(?:second |last )?(?:rakah|sujud|prostration)\b'],
  topic='tashahhud',
  text="""
There are two sittings, with different words.

Sitting between the two prostrations (in every rak'ah): say "Rabbighfir li", meaning "My Lord, forgive me" ({H abudawud:874|Hudhayfah described the Prophet's night prayer: between the two prostrations he said, My Lord, forgive me, My Lord, forgive me}).

The sitting at the end of the second rak'ah (and the last sitting of every prayer): say the tashahhud. The Prophet ﷺ taught Ibn Mas'ud its words ({H bukhari:831|Ibn Mas'ud reported that the Prophet taught the tashahhud: greetings, prayers and good words are for Allah; peace be on you O Prophet; peace on us and on Allah's righteous servants; I bear witness there is no god but Allah and Muhammad is His servant and messenger}):

{AR bukhari:831|التحيات لله|الصالحين} {AR bukhari:831|أشهد أن لا|ورسوله}

At-tahiyyatu lillahi was-salawatu wat-tayyibat. As-salamu 'alayka ayyuhan-nabiyyu wa rahmatullahi wa barakatuh. As-salamu 'alayna wa 'ala 'ibadillahis-salihin. Ash-hadu an la ilaha illallah, wa ash-hadu anna Muhammadan 'abduhu wa rasuluh.

Meaning: all greetings, prayers and good things are for Allah. Peace be upon you, O Prophet, and the mercy of Allah and His blessings. Peace be upon us and upon the righteous servants of Allah. I bear witness that there is no god but Allah, and I bear witness that Muhammad is His servant and messenger.

In the last sitting, after this, you also send blessings on the Prophet ﷺ and then give the salam (ask me "salawat in prayer" for those words). The New Muslim Path teaches all of this on Days 5, 13 and 21.
""",
  go=['/new-muslim', '/huda/guide?id=huda-prayer'],
  review='The transliteration is typed by hand from the Arabic shown; please have a reader check it. The second sitting of a three- or four-rak\'ah prayer differs by school (some stop at the tashahhud).')
