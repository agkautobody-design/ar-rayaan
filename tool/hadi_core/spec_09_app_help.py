# Help about the app itself. Every statement here is checked against the screen's own text
# (test/hadi_eval/app_help_facts_test.dart reads the screens and fails if they drift).
# Game rules are not here: they are built at runtime from the game list (hadi_game_help.dart).

E('hadi-about',
  m=[r'\bwhat can (?:you|hadi) do\b', r'\bwhat (?:do|can) you (?:help|know)\b', r'\bwhat are you\b', r'\bwho are you\b', r'\bwho is hadi\b', r'\bwho made you\b', r'\bwho (?:built|created|developed) (?:you|hadi)\b', r'\bhow can you help\b', r'\bwhat (?:is|s) hadi\b', r'\bwhat can i ask\b', r'\bwhat should i ask\b', r'\bhelp me\b$', r'^help$', r'\bwhat topics\b', r'\bwhat do you cover\b', r'\bwhat are your (?:features|abilities|capabilities)\b', r'\bhow (?:do|does) (?:you|hadi) work\b',
     r'\bare you (?:an? )?(?:ai|bot|robot|human|real|person|chatgpt|scholar|sheikh|shaykh|imam|mufti|alim)\b', r'\bis this (?:an? )?(?:ai|bot|human|person)\b', r'\bcan i trust you\b', r'\bare you reliable\b', r'\bare your answers (?:correct|right|accurate|reliable)\b', r'\bcan you make mistakes\b', r'\bdo you make mistakes\b',
     r'\bcan you (?:issue|give|make) (?:me )?(?:a )?fatwa\b', r'\bwhat is a fatwa\b.*\byou\b', r'\bdo you give fatwas?\b', r'\bcan you give (?:islamic )?rulings?\b'],
  x=[r'\b(?:hits?|beats?|divorce|talaq|my husband|my wife)\b'],
  topic='about hadi',
  text="""
I am Hadi, the guide inside this app. I am not a scholar, a sheikh or a mufti, and I cannot issue a fatwa. I answer from a built-in library of the Qur'an and the Sunnah, show where each answer comes from (the source card gives the collection, the number, and for hadith the grade and who graded it), and take you to the right screen of the app.

I can help with:
- Worship: wudu, ghusl, prayer, fasting, zakat, Hajj and Umrah, funerals.
- What is halal and haram in food, money and everyday life, and family and marriage questions.
- The basics of belief, the Prophet's life, the companions and Islamic history.
- Du'as, and where to find things in the app: Qur'an, Prayer Times, Qibla, Games, the Academy and more.

Who has reviewed this: no one yet. The app's own words are "Not yet scholar-reviewed. No named scholar has reviewed this app yet. We check every citation we can, we say so when we cannot, and we will name a reviewer here only once one has agreed to be named."

Where the schools of law differ, I say so and do not pick one for you. For a ruling on your own case (a divorce, an inheritance, a debt), I will not guess: a qualified scholar who can ask you questions must answer. I can be wrong, so please treat my answers as a study aid and check the source. If I do not know something, I say so.

I answer in English only. Ask me anything about Islam or the app, for example "how many rak'ahs is Fajr", "is gelatin halal" or "how do I play Ludo".
""",
  go=['/sources'],
  review='Statements about scope and limits only.')

E('streaks-points',
  m=[r'\bstreaks?\b', r'\bpoints?\b.*\b(?:app|hadi|game|games|quran|prayer|worship|earn|get|score|reward)\b', r'\b(?:app|hadi|game|games|worship)\b.*\bpoints?\b', r'\bcoins?\b', r'\bbadges?\b', r'\bleaderboards?\b', r'\blevels? up\b', r'\bgamif\w*\b', r'\bdays returned\b', r'\bcome back (?:streak|calendar)\b', r'\breward(?:s)? (?:in|for) the app\b', r'\bdoes the app (?:track|count|score)\b', r'\bwhat is keep my streaks\b', r'\bturn (?:off|on) streaks?\b'],
  x=[r'\b(?:good deeds?|hasanat|hasanah|reward from allah|reward in|rewards? of)\b'],
  topic='streaks',
  text="""
Streaks are optional and are off until you turn them on. The switch is called "Keep my streaks": you find it in Settings under "Coming back", and on the Streaks screen.

When it is on, the app keeps a private calendar, on your device only, of the days you read the Qur'an, do dhikr and tasbeeh, log a prayer, or come back to the app. The calendar is gentle on purpose: one day off each week is forgiven. There are no points, coins, ranks or leaderboards for worship anywhere in the app; the calendar only helps you see your own pattern, and your reward is with Allah. The prayer calendar is read from your own prayer log, stays private and can never be shared. If you switch streaks off, the saved days are erased; your prayer log stays as it is.
""",
  go=['/streaks', '/settings'],
  review='Checked against the Streaks and Settings screens by test/hadi_eval/app_help_facts_test.dart.')

E('language-help',
  m=[r'\b(?:change|switch|set|choose|pick|select|use) (?:the |my )?(?:app )?language\b', r'\blanguage (?:of|in|for|settings?|options?|menu)\b.*\b(?:app|hadi)\b', r'\b(?:app|hadi)\b.*\blanguages?\b', r'\bis (?:the )?(?:app|hadi) (?:available|translated|offered) in\b', r'\b(?:does|can) (?:the )?(?:app|hadi) (?:speak|understand|support|answer in|reply in|work in|talk in)\b', r'\b(?:app|hadi) in (?:urdu|arabic|bangla|bengali|french|turkish|malay|indonesian|hindi|spanish|german|english)\b',
     r'\b(?:urdu|arabic|bangla|bengali|french|turkish|malay|indonesian|hindi|spanish|german) (?:version|language|translation|support)\b.*\b(?:app|hadi)\b', r'\btranslate the app\b', r'\blanguage and voice\b', r'\blanguage \& voice\b', r'\bwhich languages\b', r'\bwhat languages\b', r'\bavailable languages\b', r'\bvoice (?:reading|read aloud|reader)\b', r'\bread (?:it |answers? |text )?aloud\b', r'\btext to speech\b', r'\bmy language\b'],
  x=[r'\b(?:learn|teach|lessons?|school|arabic letters|quranic arabic|grammar)\b'],
  topic='language',
  text="""
You change the language on the Language & Voice screen: open the menu and choose "Language & Voice" (or Settings, then the language row). The app offers English, Urdu, Arabic, Indonesian, French, Turkish, Bangla and Malay, but not all of them are translated yet, and the screen says so for each one:
- Arabic, Bangla and Urdu: the menu and tab names, the titles on the Home screen, the first questions you see when you open the app, and the top of Settings are translated. These are first drafts waiting for a native speaker to check them. Arabic and Urdu also turn the layout right-to-left.
- Indonesian: only the Language & Voice labels are translated.
- French, Turkish and Malay: not translated yet; the app stays in English.

Lessons, stories, hadith, my answers, the prayer screens and every long text are still in English, with the original Arabic for scripture. I answer in English only. Natural human-sounding voices are not available yet: until they are, the device reads the words in its own voice.
""",
  go=['/settings/language'],
  review='Checked against the Language & Voice screen by test/hadi_eval/app_help_facts_test.dart.')

E('downloads-offline',
  m=[r'\bdownloads?\b', r'\bdownload(?:ing)? (?:the )?(?:quran|recitation|audio|surah|reciter|ayah|app|nasheed|content|duas?|lessons?)\b', r'\boffline\b', r'\bwithout (?:the )?(?:internet|wifi|wi fi|data|network)\b', r'\bno (?:internet|wifi|wi fi|network|connection|signal)\b', r'\b(?:work|works|working|use|using) (?:the )?(?:app )?(?:offline|without internet)\b', r'\bsave (?:the )?(?:recitation|audio|surah|quran)\b', r'\bstorage\b', r'\bdata usage\b', r'\bmobile data\b', r'\bhow much space\b', r'\bdelete (?:a |my |the )?downloads?\b', r'\bremove (?:a |my |the )?downloads?\b'],
  x=[r'\b(?:hadith|youtube|spotify)\b', r'\b(?:hadi|you|ai)\b.*\boffline\b', r'\boffline (?:mode|ai|hadi)\b'],
  topic='downloads',
  text="""
Most of the app works without the internet. The Qur'an text, the stories, the guides and the duas are already inside the app. What you can download is recitation audio, so you can listen with no connection.

To do it, open Downloads (from the menu). Pick a reciter and download a surah or more; each row shows its size, whether it is waiting, downloading, paused or on your device. A few points:
- Downloads are for the reciter you have chosen only; change the reciter on that screen if you want another.
- "Wi-Fi only" is a switch so that big downloads wait for Wi-Fi and do not use mobile data. Your phone only guesses which network it is on, so check before a big download.
- You can pause at any time and delete any download later to free the space.
- In a web browser, downloads are kept in the browser's storage, and the app still needs the internet to open. The Android app keeps everything on the phone and opens with no internet.
""",
  go=['/downloads'],
  review='Checked against the Downloads screen by test/hadi_eval/app_help_facts_test.dart.')

E('kids-help',
  m=[r'\b(?:kids?|children|child) (?:section|mode|corner|area|zone|page|part|feature|profile|profiles|friendly|safe)\b', r'\bfor children\b', r'\bis (?:the )?app (?:safe|suitable|ok|okay|good) for (?:kids?|children|my (?:kid|child|son|daughter))\b', r'\b(?:kids?|children) (?:in|on) (?:the )?app\b', r'\bmy (?:kid|kids|child|children|son|daughter)s? (?:use|using|play|playing|learn|learning)\b.*\bapp\b', r'\bparental (?:controls?|gate|check)\b', r'\bfamily wing\b', r'\bchild profiles?\b', r'\bwhere (?:are|is) (?:the )?(?:kids?|children)\b', r'\bapp for (?:kids?|children)\b', r'\bteach (?:my )?(?:kids?|children) (?:with|using|in) (?:the )?app\b', r'\bletters? for (?:kids?|children)\b'],
  x=[r'\b(?:how to raise|parenting|discipline|hit|beat|spank|pray at what age|what age)\b'],
  topic='kids',
  text="""
The For Children section has three doors: the Arabic letters (learn them one at a time), Games (play and learn), and the Stories school (stories with a lesson to talk about). On the Home screen it is the "For Children" tile. A grown-up can sit with the child.

About privacy: the app is a general-audience app and is not directed to children under 13. In the Family Wing a parent can add child profiles that keep only a first name or nickname and the child's progress in the Arabic letters, and they stay on the device. No age, photo, voice, e-mail, phone number or location is asked for. Adding or removing a child sits behind a parent check. The online game tables (Ludo and Shatranj with a friend, using a six-letter code) are off for every child unless a parent switches them on. The full text is in the Privacy policy screen.
""",
  go=['/academy/family'],
  review='Checked against kChildrenPrivacyBody and the For Children screen by test/hadi_eval/app_help_facts_test.dart.')

E('school-setting',
  m=[r'\b(?:change|switch|set|choose|pick|select|update|find|where is|how do i set)\b.*\b(?:my )?(?:school of (?:law|thought)|madhhab|madhab|mazhab)\b', r'\b(?:my )?(?:school of (?:law|thought)|madhhab)\b.*\b(?:setting|settings|menu|app|hadi|change|set|choose|select)\b', r'\bwhich school (?:does|do) (?:hadi|you|the app) follow\b', r'\bwhat madhhab (?:are you|is hadi|does hadi)\b', r'\bare you (?:hanafi|shafii|maliki|hanbali|sunni|shia)\b', r'\bset (?:to )?(?:hanafi|shafii|maliki|hanbali)\b', r'\bhanafi (?:mode|setting)\b', r'\bwhy does hadi (?:ask|say) .*school\b'],
  topic='madhhab setting',
  text="""
Open the Hadi screen, tap the menu in the corner and choose "Your school of law". You can pick Not sure, Hanafi, Shafi'i, Maliki or Hanbali. It is kept on your device only.

What it changes: where the four schools differ, I name your school's view first and say plainly that other schools differ. I never say another school is wrong. If you pick "Not sure", I say that the schools differ and do not pick one for you. Where I do not hold a verified text for a single school, I say that and point you to a scholar of your school.

I answer from the Sunni tradition: the Qur'an and the Sunnah, with the four Sunni schools of law. I am a study aid, not a mufti.
""",
  review='Checked against the Hadi screen sheet and kHadiScopeNote by test/hadi_eval/app_help_facts_test.dart.')

E('privacy-free-ads',
  m=[r'\bis (?:my )?(?:data|privacy|information|chat|chats|conversation|conversations|messages?) (?:private|safe|secure|stored|shared|sold|saved|recorded|tracked|kept)\b', r'\b(?:privacy|privacy policy|terms of service|terms and conditions)\b', r'\bdo you (?:track|store|save|record|sell|share|collect|log) (?:my |our )?(?:data|chats?|conversations?|messages?|questions?|location)\b', r'\bwho (?:sees|reads|can see|can read) (?:my )?(?:chats?|questions?|messages?|data|conversations?)\b',
     r'\bdoes (?:the )?app (?:have|show|contain|run) (?:ads|adverts|advertising|advertisements)\b', r'\bany ads\b', r'\badvert\w*\b', r'\bis (?:the )?app (?:free|paid|premium|subscription)\b', r'\bis (?:this|it) (?:free|paid)\b', r'\bhow much (?:does|do|is) (?:the )?(?:app|it) cost\b', r'\b(?:subscription|premium|pro version|in app purchase|paywall|pricing|price of the app)\b', r'\bwho (?:owns|runs|made|built|funds) (?:the |this )?app\b', r'\bwho is behind (?:the )?app\b',
     r'\bdelete (?:my )?(?:account|data|history|chats?|conversation|conversations)\b', r'\bclear (?:my )?(?:chat|history|conversations?|data)\b', r'\bdo i need (?:an? )?(?:account|login|sign ?up|api key)\b', r'\bsign in\b', r'\bapi key\b', r'\bis (?:it|hadi) online\b', r'\bdoes hadi (?:need|use|work) (?:the )?(?:internet|online|api|ai)\b', r'\bis (?:hadi|this) (?:an? )?(?:offline|online)\b'],
  x=[r'\boffline\b', r'\b(?:who (?:runs|owns|funds|pays for|is behind|made|built|created)|owner of|funded|funds it|funding|company behind)\b', r'\b(?:data of|big data|quran data)\b'],
  topic='privacy',
  text="""
What I can tell you, from the app's own Privacy policy screen:
- Your settings, bookmarks, progress, reflections and saved conversations with me are stored on your device. You can clear them by clearing the app's data.
- I answer from a library built into the app, which does not leave your device. Only if you choose to add your own key for an AI provider are your key and the messages of that conversation sent to that provider, under its terms. Messages that look like a personal crisis are answered on the device and are not sent or saved.
- Accounts: if you create one, sign-in uses Firebase Authentication. You can delete your account and data from Settings: the "Delete my account" link opens the Delete account screen. What you post in the Majlis is public.
- Prayer times, Qibla and the mosque finder use the location you give or allow; the app contacts services such as prayer-time and map services and audio servers to work.
- The policy says: "We do not sell personal data or show advertising based on it."

What I cannot tell you: I do not have a price list or a statement about future plans, so I will not guess whether anything will be paid or free later. The Terms and Privacy screens are the place to read the exact words; the policy there is marked as a draft.
""",
  review='Quotes and paraphrases the Privacy policy screen; checked by test/hadi_eval/app_help_facts_test.dart.')

E('wasia-who',
  m=[r'\bwho is wasia\b', r'\bwhat is wasia\b', r'\bwho s wasia\b', r'^wasia$', r'\btell me about wasia\b', r'\bis wasia (?:real|a person|an ai|a robot|ai)\b'],
  topic='academy',
  text="""
Wasia is the AI teacher of the Wasia Academy, the letter school built with love. She teaches the Arabic alphabet, reads with the child, and speaks in three voices: student, parent, and a Teachers' Corner for parents. Shall I take you there?
""",
  go=['/academy/gate'],
  review='Restates the app\'s existing description of Wasia; no Islamic ruling.')

E('academy-help',
  m=[r'\bwhat is (?:the )?(?:wasia )?academy\b', r'\bwasia\b', r'\b(?:wasia )?academy\b.*\b(?:what|how|where|start|begin|open|lessons?|courses?|schools?)\b', r'\bhow (?:do|to|can) i (?:start|begin|use) (?:the )?academy\b', r'\bwhere (?:is|are) (?:the )?(?:academy|lessons|courses)\b', r'\bi want to learn (?:islam|arabic|quran|prayer)\b.*\bapp\b', r'\bwhat (?:lessons|courses|schools) (?:are|do you have|does the app have)\b', r'\bletter school\b', r'\bschool of letters\b', r'\bteacher in the app\b'],
  x=[r'\b(?:hifz|memori[sz]e)\b'],
  topic='academy',
  text="""
The Wasia Academy is the learning part of the app. It is on the Home screen as "Wasia Academy: learn with your teacher". It opens the school of Arabic letters, with Wasia as your teacher, and the other schools for learning step by step, such as Qur'anic Arabic, Aqeedah, Seerah, Hadith, Family life, Ramadan Mode, Hifz and Hajj and Umrah.

Start with the Arabic letters if you are a beginner. A parent can set up child profiles in the Family Wing. For a quick answer rather than a course, ask me.
""",
  go=['/academy'],
  review='Describes the Academy entry point only; Academy lesson content is not summarised here.')

E('games-general',
  m=[r'\bhow (?:does|do) (?:scoring|score|scores|points|winning) work\b', r'\bscoring\b', r'\bhow (?:do|to) (?:i )?win\b', r'\bhow does (?:the )?game (?:end|work)\b', r'\bhints?\b.*\bgame\b', r'\bis there a timer\b', r'\bgame (?:settings?|options?)\b',
     r'\bresume\b', r'\bcontinue (?:a |my |the )?(?:game|playing)\b', r'\bfinish (?:a |my |the )?game\b', r'\bunfinished game\b', r'\bgame history\b', r'\bmy (?:game )?history\b', r'\bpast games\b', r'\bprevious games\b', r'\bwhere (?:is|are) my (?:game|games|results?|history|score|scores)\b', r'\bsaved games?\b', r'\bpractice (?:with|a) friend\b', r'\bplay (?:with|against) (?:a )?friend\b', r'\bplay online\b'],
  x=[r'\b(?:chess|shatranj|ludo|memory|trivia|timeline|names|lineage|hijrah|word|quran knowledge|stories trivia|hifz)\b'],
  topic='games',
  text="""
The Games screen lists every game that works today, in four groups: Islamic (such as Qur'an Knowledge, Stories Trivia, the 99 Names, Lineage Challenge and the Hijrah Journey), Strategy (Shatranj, which is chess), Family (Ludo) and Words and puzzles. Ask me about a game by name, for example "how do I play Ludo", and I will tell you the rules and how to start.

Scoring: the quizzes show how many you got right out of the total, and after each answer you see the source. There is no timer in the quizzes. Hints are free: a hint hides two wrong answers, and you get three free hints in a game. Nothing is sold, and there are no ratings, coins or leaderboards. Memorising the Qur'an in Hifz practice has no score.

A game you started and did not finish is shown at the top of the Games screen under "Continue playing". Finished games appear in Game history (button at the bottom of the Games screen), which is kept on this device only; you can clear it there. Playing Ludo or Shatranj with a friend on another device uses a six-letter code and needs the internet and the online hall to be switched on; if it is not, the app tells you.
""",
  go=['/games', '/games/history'],
  review='Checked against the Games hub, history and registry by test/hadi_eval/app_help_facts_test.dart.')
