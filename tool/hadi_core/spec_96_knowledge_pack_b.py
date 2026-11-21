# Knowledge pack B (20 Nov 2026): common questions found missing by a 100-question probe.
# Every hadith is read against the hadith-api English text by build.py; weak reports are
# not cited. Where scholars differ, the answer says so and gives no personal ruling.

E('istighfar-sayyid',
  m=[r'\bsayyid(?:ul|ul-| al| ul)? ?istighfar\b', r'\b(?:best|greatest|master|most (?:superior|excellent)) (?:way|dua|du a|words?|form)?\s*(?:of|for)? ?(?:asking )?(?:for )?(?:forgiveness|istighfar|repentance)\b',
     r'\bwhat (?:is|should i say for|do i say for) (?:the )?(?:dua|du a)? ?(?:for|of) (?:forgiveness|istighfar)\b', r'\bdua (?:for|to ask) forgiveness\b', r'\bhow (?:do|can|should) i ask (?:allah )?for forgiveness\b'],
  topic='asking forgiveness',
  go=['/adhkar'],
  text="""
The Prophet ﷺ called one du'a the best way of asking forgiveness. Shaddad ibn Aws reported: {HS bukhari:6306|the most superior way of asking forgiveness is to say "O Allah, You are my Lord, there is no god but You, You created me and I am Your servant, I keep Your covenant and promise as best I can, I seek refuge in You from the evil I have done, I acknowledge Your favour upon me and I acknowledge my sin, so forgive me, for none forgives sins but You"}.

He added that whoever says it with firm faith in the day and dies that day before evening is among the people of Paradise, and likewise at night. Starting words: Allahumma anta Rabbi la ilaha illa anta, khalaqtani wa ana 'abduka.
""",
  review='Scholar review needed: the transliteration is only the opening; confirm before showing the full Arabic.')

E('tawbah-repent',
  m=[r'\bhow (?:do|can|should|to) (?:i )?(?:repent|make tawbah|do tawbah|make tawba|do tawba)\b', r'\b(?:what is|whats|meaning of|explain) (?:tawbah|tawba|repentance)\b',
     r'\b(?:will|does|would|can) allah forgive (?:me|my sins|everything|any sin|big sins|a sinner)\b', r'\bconditions? of (?:tawbah|tawba|repentance)\b',
     r'\bi (?:committed|did|made) (?:a )?(?:big |major )?sin\b.*\b(?:forgive|forgiven|repent|tawbah)\b'],
  topic='repentance',
  go=['/adhkar'],
  text="""
Repentance (tawbah) means turning back to Allah. The Qur'an invites it sincerely: turn to Allah in sincere repentance ({QR 66:8}), and says Allah loves those who repent ({QR 2:222}).

The Prophet ﷺ described Allah's joy at it: Anas reported that {HS muslim:2747|Allah is more pleased with the repentance of a servant who turns to Him than a man on a camel in a waterless desert who loses it with his food and drink and then finds it}.

Scholars usually list the parts of repentance as: stop the sin, feel regret, resolve not to return, and, if someone's right was wronged, return it or ask their pardon. That list is the scholars' summary, not a hadith quotation. For a specific sin, ask a scholar.
""",
  review='Scholar review needed: the list of conditions is the common summary of scholars, no named scholar.')

E('sabr-patience',
  m=[r'\b(?:what is|whats|meaning of|explain|define) (?:sabr|patience|being patient)\b', r'\b(?:how|why) (?:do|can|should|to) (?:i )?(?:have|be|stay|keep|show|practise|practice) (?:sabr|patient|patience)\b',
     r'\b(?:sabr|patience)\b.*\b(?:islam|quran|hadith|reward|hardship|trial|test)\b', r'\bhow to (?:cope|deal) with (?:hardship|trials|tests|difficult times)\b'],
  x=[r'\bfast\w*\b'],
  topic='patience',
  text="""
Sabr is patience: holding yourself steady in hardship, in obedience and away from sin. The Qur'an says: seek help through patience and prayer, for Allah is with the patient ({QR 2:153}).

The Prophet ﷺ taught that {HS muslim:2999|a believer's affairs are all good: if he has an occasion for delight he thanks Allah and there is good in it, and if he gets into trouble and endures it patiently there is good in it}. And {HS bukhari:1469|nobody is given a blessing better and greater than patience}.
""",
  review='Scholar review needed: the first sentence is the app\'s short definition.')

E('hasad-envy',
  m=[r'\b(?:what is|whats|define|meaning of|explain) (?:hasad|envy|jealousy)\b', r'\b(?:hasad|envy|envious|jealous|jealousy)\b.*\b(?:islam|quran|hadith|sin|haram|cure|stop|remove)\b',
     r'\bhow (?:to|do i|can i) (?:stop|get rid of|overcome|remove|deal with) (?:hasad|envy|jealousy)\b', r'\bwhat to do if i am (?:jealous|envious)\b'],
  topic='envy',
  text="""
Hasad is envy: disliking a blessing someone has, and wishing it were taken from them. It is different from wishing for the same good for yourself, which scholars do not count as hasad.

The Prophet ﷺ said: {HS bukhari:6064|beware of suspicion, do not look for others' faults, do not spy, do not envy one another, and do not desert one another, but be servants of Allah and brothers}. Scholars advise giving thanks for what you have and praying for good for the other person; that advice is the scholars' guidance, not a hadith quotation.
""",
  review='Scholar review needed: the summary stops at the part of the hadith that names envy.')

E('kibr-pride',
  m=[r'\b(?:what is|whats|define|meaning of|explain) (?:kibr|kibar|arrogance|pride)\b', r'\b(?:kibr|arrogance|arrogant|pride)\b.*\b(?:islam|quran|hadith|sin|paradise|haram)\b',
     r'\bis (?:it )?(?:haram|a sin) to be (?:proud|arrogant)\b', r'\b(?:atom|mustard seed) of (?:pride|arrogance)\b'],
  topic='pride',
  text="""
Ibn Mas'ud reported the Prophet ﷺ saying: {HS muslim:91|he who has in his heart the weight of a mustard seed of pride will not enter Paradise}. A man asked whether liking fine clothes and shoes counts. The Prophet ﷺ answered that Allah is beautiful and loves beauty, and that pride is disdaining the truth and holding people in contempt ({H muslim:91}).

So taking care of how you look is not pride; rejecting the truth and looking down on people is.
""",
  review='Scholar review needed.')

E('hypocrisy-signs',
  m=[r'\b(?:what is|whats|define|meaning of|explain) (?:nifaq|hypocrisy|a hypocrite|munafiq|munafiqun)\b', r'\b(?:signs?|characteristics?|traits?) of (?:a )?(?:hypocrite|hypocrisy|munafiq|nifaq)\b', r'\bhypocrit\w*\b.*\b(?:hadith|islam|signs?)\b'],
  topic='signs of hypocrisy',
  text="""
Abu Hurayrah reported the Prophet ﷺ saying: {HS bukhari:33|the signs of a hypocrite are three: when he speaks he lies, when he promises he breaks it, and when he is trusted he betrays the trust}.

Scholars explain that this describes hypocrisy in conduct, and warn a believer to check himself against it; it is not a judgment you pass on another person's faith.
""",
  review='Scholar review needed: the explanation of conduct versus belief is the scholars\' view, no named scholar.')

E('sadaqah-jariyah',
  m=[r'\b(?:what is|whats|define|meaning of|explain) (?:sadaqah|sadaqa|sadaqat) ?(?:jariyah|jariya)\b', r'\bongoing (?:charity|reward)\b', r'\bcontinuous charity\b', r'\bwhat (?:deeds|good) (?:continue|keep (?:giving|going)) after (?:death|you die)\b', r'\bdeeds? that continue after death\b'],
  topic='ongoing charity',
  go=['/zakat'],
  text="""
Abu Hurayrah reported the Prophet ﷺ saying: {HS muslim:1631|when a man dies his deeds come to an end except three: recurring charity, knowledge from which people benefit, or a pious son who prays for him}.

Sadaqah jariyah is the first: charity whose benefit keeps going, such as a well, a school or a masjid. Scholars give these as examples; the hadith names the category.
""",
  review='Scholar review needed: the examples are the scholars\' usual illustrations.')

E('good-friends',
  m=[r'\b(?:what|who) is a good (?:friend|companion)\b', r'\b(?:choose|choosing|pick|picking|find|finding) (?:good )?(?:friends|a friend|companions?)\b', r'\b(?:friends?|friendship|companions?)\b.*\b(?:islam|hadith|quran|influence|bad|evil|good)\b'],
  x=[r'\b(?:opposite|boyfriend|girlfriend|dating)\b'],
  topic='good friends',
  text="""
The Prophet ﷺ gave a picture, reported by Abu Musa: {HS bukhari:5534|a good companion and an evil one are like a person carrying musk and a person blowing a pair of bellows: the musk carrier gives you perfume, or you buy some or at least smell a good scent, while the bellows blower burns your clothes or you get a bad smell}.

So friends rub off on you. Choose people who remind you of Allah and are kind and honest.
""",
  review='Scholar review needed: the last sentence is the app\'s advice.')

E('dua-best-time',
  m=[r'\b(?:best|good|right|accepted|answered) (?:time|times|moment|moments|place|state) (?:to|for) (?:make |making |do |doing )?(?:dua|du a|supplication)\b', r'\bwhen (?:is|are) (?:dua|du a|duas)\b.*\b(?:accepted|answered)\b',
     r'\bwhen (?:does|will) allah (?:accept|answer) (?:my )?(?:dua|du a)\b', r'\b(?:dua|du a)\b.*\b(?:accepted|answered)\b.*\b(?:time|when|night|prostrat\w*)\b'],
  topic='best times for dua',
  go=['/adhkar'],
  text="""
Two reports are clear. Jabir reported the Prophet ﷺ saying: {HS muslim:757|there is an hour in the night in which no Muslim asks Allah for good in this world and the next without Allah giving it to him, and that applies to every night}.

And Abu Hurayrah reported: {HS muslim:482|the nearest a servant comes to his Lord is when he is prostrating himself, so make du'a in it}.

The Qur'an also tells you Allah is near and answers: when My servants ask about Me, I am near, I answer the call of the caller when he calls ({QR 2:186}).
""",
  review='Scholar review needed: the hadith does not say which hour of the night.')

E('dua-answered',
  m=[r'\bhow (?:do|can|should|to) (?:i )?(?:make|get|have) (?:my )?(?:dua|du a|duas|prayers?) (?:accepted|answered|work|come true)\b', r'\bwhy (?:is|isnt|isn t|was|wasnt) (?:my )?(?:dua|du a|duas) (?:not )?(?:accepted|answered)\b', r'\bwhy (?:does|did|do) allah (?:not|never|doesnt|doesn t) (?:answer|accept) (?:my )?(?:dua|du a|duas|prayers?)\b', r'\bdua (?:not|isnt|isn t) (?:answered|accepted)\b'],
  topic='when dua seems unanswered',
  go=['/adhkar'],
  text="""
The Qur'an says: call on Me and I will respond to you ({QR 40:60}), and: I am near, I answer the call of the caller when he calls on Me ({QR 2:186}).

Scholars teach that an answer can come in different forms: what you asked, something better, or something kept back for you. That teaching is the scholars' explanation, not a quotation I can name here. What the sources do say is to ask with certainty in Allah, with presence of heart, and to keep asking.

If a du'a seems unanswered, that does not mean you are rejected; stay patient and keep asking.
""",
  review='Scholar review needed: the forms of an answer are the scholars\' explanation, no named source here.')

E('condolences',
  m=[r'\bhow (?:do|can|should|to) (?:i )?(?:give|offer|say|send|express|write) (?:my )?(?:condolences|sympathy)\b', r'\bwhat (?:to|do i|should i|can i) say (?:to|when) (?:someone|somebody|a person|a friend|my \w+)?\s*(?:who )?(?:lost|loses|lose|has lost|is grieving|is mourning|is sad)\b', r'\b(?:condolences|condolence)\b.*\b(?:islam|islamic|muslim|dua|say)\b', r'\bwhat to say (?:at|in) (?:a )?(?:funeral|death|bereavement)\b'],
  topic='condolences',
  text="""
The Prophet ﷺ gave his own words when his daughter sent news that her child was dying. Usama ibn Zayd reported: {HS bukhari:1284|he sent word to her that whatever Allah takes is His, whatever He gives is His, and everything with Him has a fixed term, so she should be patient and hope for Allah's reward}.

Many people use words like these to console someone: that what Allah took belonged to Him, that He decides the term, and that patience is rewarded. Reported also in the same hadith: the Prophet ﷺ wept, showing that grief is not wrong.
""",
  review='Scholar review needed: the final sentence summarises the continuation of the report.')

E('wedding-dua',
  m=[r'\b(?:wedding|marriage|nikah|newlywed|congratulat\w*)\b.*\b(?:dua|du a|say|words|wish|wishes|message|supplication)\b', r'\b(?:dua|du a|supplication)\b.*\b(?:wedding|marriage|nikah|newlywed|newly married|bride|groom)\b', r'\bwhat (?:to|do i|should i) say (?:to|when|at) (?:a )?(?:newly ?weds?|someone (?:who )?(?:gets|got|is getting) married|wedding|marriage|nikah)\b', r'\bbaraka ?allahu laka\b'],
  x=[r'\b(?:haram|ruling|age|conditions?|rights?|divorce)\b'],
  topic='wedding du\'a',
  text="""
Abu Hurayrah reported how the Prophet ﷺ congratulated a man on his marriage: {HS abudawud:2130|he said "May Allah bless for you and may He bless on you and combine both of you in good"}.

In Arabic: Baraka Allahu laka wa baraka 'alayka wa jama'a baynakuma fi khayr.
""",
  review='Scholar review needed: Arabic transliteration is given as in the report.')

E('hasbunallah-fear',
  m=[r'\b(?:dua|du a|supplication|dhikr|words?|what to say)\b.*\b(?:fear|afraid|scared|terrified|danger|threat|worry|worried)\b', r'\b(?:fear|afraid|scared|terrified|danger)\b.*\b(?:dua|du a|supplication|what to say|say)\b', r'\bhasbunallah\b', r'\bhasbiyallah\b', r'\bwhat (?:to|do i|should i) say when (?:i am |im |i m )?(?:scared|afraid|frightened)\b'],
  x=[r'\b(?:nightmare|dream|anxiety|haram|ruling)\b'],
  topic='words for fear',
  go=['/adhkar'],
  text="""
Ibn Abbas reported: {HS bukhari:4563|"Allah is sufficient for us and He is the best disposer of affairs" was said by Abraham when he was thrown into the fire, and by Muhammad when people told them an army was gathering against them, and it only increased their faith}.

The words are from the Qur'an ({QR 3:173}). In Arabic: Hasbunallahu wa ni'mal wakil.
""",
  review='Scholar review needed.')

E('anger-refuge',
  m=[r'\b(?:dua|du a|supplication|words?|what to say|what should i say)\b.*\b(?:angry|anger|furious|rage|mad)\b', r'\bwhat (?:to|do i|should i) say when (?:i am |im |i m |i get |i feel )?(?:angry|furious|mad)\b', r'\b(?:angry|anger)\b.*\b(?:audhu|auzu|seek refuge|a udhu)\b', r'\bhow (?:to|do i|can i) (?:control|calm|stop|manage) (?:my )?(?:anger|temper)\b'],
  topic='when angry',
  text="""
Sulayman ibn Surad reported that two men were abusing each other before the Prophet ﷺ and one became furious with his face turning red. The Prophet ﷺ said: {HS bukhari:6115|"I know a word which, if he said it, would make his anger go away: I seek refuge with Allah from Satan, the outcast"}.

In Arabic: A'udhu billahi minash-shaytanir-rajim. Another report in the same collection says the strong person is the one who controls himself in anger ({HS bukhari:6114|the strong is not the one who overcomes people by strength, but the one who controls himself while in anger}).
""",
  review='Scholar review needed: the second report is cited separately from the first.')

E('aisha',
  m=[r'\b(?:who (?:is|was)|tell me about|story of|life of|about) (?:aisha|aishah|ayesha|ayisha|a isha)\b', r'\b(?:aisha|aishah|ayesha)\b.*\b(?:wife|prophet|who|mother of the believers|scholar)\b'],
  x=[r'\b(?:age|married at|marriage age|nine|six)\b'],
  topic='Aisha bint Abi Bakr',
  text="""
Aisha was a wife of the Prophet ﷺ and the daughter of Abu Bakr. The Prophet ﷺ died in her house, leaning on her chest (Sahih al-Bukhari 4449).

Abu Musa reported the Prophet ﷺ saying: {HS bukhari:3769|the superiority of Aisha to other women is like the superiority of tharid, an Arabic dish, to other meals}.

She narrated a large number of hadith and is one of the most important sources of knowledge about the Prophet's ﷺ home life.
""",
  review='Scholar review needed: the final sentence is a general statement and needs a named source.')

E('adhan-meaning',
  m=[r'\b(?:what is|whats|meaning of|explain|define) (?:the )?(?:adhan|azan|athan|iqamah|iqama|call to prayer)\b', r'\bhow (?:is|does) (?:the )?(?:adhan|azan|athan|iqamah|iqama) (?:said|go|work)\b', r'\bdifference between (?:the )?(?:adhan|azan|athan) and (?:the )?(?:iqamah|iqama)\b'],
  topic='adhan and iqamah',
  go=['/prayer'],
  text="""
The adhan is the call to prayer, and the iqamah is the call made when the prayer is about to start. Anas reported that {HS bukhari:603|Bilal was ordered to pronounce the adhan by saying its wordings twice and the iqamah by saying its wordings once}.

I am not giving the wording here; the Prayer screen has the times, and ask me if you want the sources for the wording.
""",
  review='Scholar review needed: schools differ on the exact repetition in the iqamah; this report is one narration.')

E('adhan-dua',
  m=[r'\b(?:dua|du a|supplication|what (?:to|do i|should i) say)\b.*\b(?:after|when (?:i )?hear|hearing|listening to)\b.*\b(?:adhan|azan|athan|call to prayer|muadhdhin|muezzin)\b', r'\b(?:after|when (?:i )?hear|hearing)\b.*\b(?:adhan|azan|athan|call to prayer)\b.*\b(?:say|dua|du a)\b', r'\bwhat (?:to|do i|should i) (?:say|reply|respond|answer) (?:when|to) (?:the )?(?:adhan|azan|athan|muadhdhin|muezzin)\b', r'\bwasilah\b'],
  topic='what to say at the adhan',
  go=['/adhkar'],
  text="""
When you hear the adhan, repeat what the muadhdhin says. Abdullah ibn Amr reported the Prophet ﷺ saying: {HS muslim:384|when you hear the muadhdhin, repeat what he says, then send blessings on me, for whoever sends one blessing on me Allah sends ten on him, then ask Allah for al-Wasilah for me, a rank in Paradise}.

After the adhan, Jabir reported: {HS bukhari:614|whoever after hearing the adhan says "O Allah, Lord of this perfect call and of the prayer to be established, give Muhammad the Wasilah and the virtue, and raise him to the praised station You promised him", my intercession for him will be allowed on the Day of Resurrection}.
""",
  review='Scholar review needed: both reports are summarised; confirm Arabic.')

E('rakats-fajr',
  m=[r'\bhow many (?:rakat|rakats|rakah|rakahs|raka ?ah|rakaat|rakaats|units|rak ahs?) (?:is|are|in|for|do|does|of) (?:the )?(?:fajr|dawn|morning)\b', r'\b(?:fajr|dawn)\b.*\bhow many (?:rakat|rakats|rakah|rakahs|raka ?ah|rakaat|units)\b', r'\bfajr (?:rakat|rakats|rakah|rakahs|rakaat)\b', r'\bsunnah (?:of )?fajr\b'],
  topic='Fajr rakats',
  go=['/prayer'],
  text="""
Fajr has two rak'ahs as the obligatory prayer, and the Prophet ﷺ prayed two more rak'ahs of sunnah before it. Aisha reported he said: {HS muslim:725|the two rak'ahs at dawn are better than this world and what it contains}.

The app's Prayer guide shows how each prayer is performed. This answer is the general position; the schools agree on two obligatory rak'ahs.
""",
  review='Scholar review needed: the two obligatory rak\'ahs are the agreed position and no hadith is cited for them here.')

E('best-dhikr-tawhid',
  m=[r'\b(?:what is|whats|meaning of|explain|define) (?:the )?(?:kalimah|kalima|shahada|shahadah|la ilaha illallah|la ilaha illa allah|tawhid statement)\b', r'\b(?:best|greatest|most (?:virtuous|beloved|excellent)) (?:dhikr|remembrance|words?|phrase|statement)\b', r'\bmeaning of la ilaha illa ?(?:allah|allah)\b', r'\bwhat does la ilaha illallah mean\b'],
  topic='La ilaha illa Allah',
  go=['/adhkar', '/tasbeeh'],
  text="""
La ilaha illa Allah means there is no god but Allah. The Qur'an says: know that there is no god but Allah ({QR 47:19}).

Jabir reported the Prophet ﷺ saying: {HS tirmidhi:3383|the best remembrance is "there is none worthy of worship except Allah" and the best supplication is "All praise is due to Allah"}. And 'Uthman reported: {HS muslim:26|he who died knowing that there is no god but Allah entered Paradise}.

Scholars explain that knowing it means understanding and acting on it, not saying it alone.
""",
  review='Scholar review needed: the final sentence is the scholars\' explanation, no named scholar.')

E('subhanallah-meaning',
  m=[r'\b(?:what is|whats|meaning of|what does|explain) (?:the )?(?:subhanallah|subhan allah|subhanallahi|subhan allah|tasbeeh|tasbih)\b', r'\bwhat does subhan ?allah mean\b', r'\b(?:benefit|reward|virtue) of (?:saying )?(?:subhanallah|subhan allah|alhamdulillah)\b', r'\bwhat does alhamdulillah mean\b'],
  topic='Subhan Allah and Alhamdulillah',
  go=['/tasbeeh', '/adhkar'],
  text="""
Subhan Allah means glory be to Allah: declaring Him far above any fault or likeness. Alhamdulillah means all praise is for Allah.

Abu Hurayrah reported the Prophet ﷺ saying: {HS bukhari:6406|there are two expressions, light on the tongue, heavy in the balance and dear to the Merciful: "Subhan Allah al-Azim" and "Subhan Allah wa bihamdihi"}. Abu Malik al-Ash'ari reported {HS muslim:223|Alhamdulillah fills the scale, and Subhan Allah and Alhamdulillah fill what is between the heavens and the earth}.

The Tasbeeh counter in the app is for these.
""",
  review='Scholar review needed: the meanings in the first paragraph are the app\'s short definitions.')

E('jinn-what-are',
  m=[r'\b(?:what (?:are|is)|who (?:are|is)|explain|tell me about) (?:the )?(?:jinn|jinns|djinn|jinni)\b', r'\bare (?:jinn|jinns|djinn) (?:real|in the quran)\b', r'\b(?:jinn|jinns|djinn)\b.*\b(?:made of|created from|created|fire|quran)\b'],
  x=[r'\b(?:possess\w*|exorcis\w*|ruqyah|ruqya|black magic|sihr|magic)\b'],
  topic='the jinn',
  text="""
The jinn are a creation of Allah, unseen by us and given free will like humans. The Qur'an says Allah created humankind and jinn only to worship Him ({QR 51:56}), and that the jinn were created from smokeless fire ({QR 55:15}).

There is a surah named after them, Surah Al-Jinn, which begins with a group of them hearing the Qur'an and saying it is a wonderful recitation ({QR 72:1}). Some of them believe and some do not.

I do not give details beyond what the Qur'an states, and I do not diagnose possession or magic. For that, speak to a scholar.
""",
  review='Scholar review needed: the answer only restates three verses.')

E('hasanat-reward',
  m=[r'\b(?:what (?:is|are)|meaning of|explain) (?:a |the )?(?:hasanat|hasanah|hasana|good deeds?)\b', r'\bhow many (?:hasanat|hasanah|rewards?) (?:for|do i get)\b', r'\b(?:ten|10) (?:times|fold) (?:reward|hasanat|good)\b', r'\bwhat is the reward for (?:a )?good deeds?\b'],
  topic='hasanat',
  text="""
Hasanat (singular hasanah) are good deeds and their reward. The Qur'an says: whoever brings a good deed will have ten times the like of it ({QR 6:160}), and whoever brings an evil deed is only paid the like of it.

So a good deed is multiplied, and a sin is counted as one. I am not giving counts for specific deeds here.
""",
  review='Scholar review needed.')

E('dua-knowledge-exam',
  m=[r'\b(?:dua|du a|supplication)\b.*\b(?:knowledge|study|studying|exam|exams|test|tests|school|memoris\w*|memoriz\w*|learning|homework)\b', r'\bwhat (?:to|do i|should i) say (?:before|when) (?:i )?(?:study|studying|an exam|a test|learn|learning|taking an exam)\b', r'\bdua before (?:an )?(?:exam|test|studying)\b', r'\brabbi (?:zidni|zidnee) ilma\b'],
  topic='dua for knowledge and exams',
  go=['/adhkar'],
  text="""
The Qur'an gives the du'a: and say, "My Lord, increase me in knowledge" ({QR 20:114}).

Prophet Musa asked Allah for ease when given a hard task: my Lord, expand my chest, ease my task for me, and untie the knot from my tongue so they may understand my speech ({QR 20:25-28}). Many students use these words before an exam or a hard task.

Making the effort comes first and the du'a goes with it; I am not citing a hadith for exam du'as.
""",
  review='Scholar review needed: the use of the Musa du\'a before exams is common practice, not a stated Sunnah.')

E('rizq-provision',
  m=[r'\b(?:dua|du a)\b.*\b(?:rizq|rizk|provision|sustenance|wealth|money|income|job|work)\b', r'\bhow (?:do|can|should|to) (?:i )?(?:increase|get|ask for|seek) (?:my )?(?:rizq|rizk|provision|sustenance)\b', r'\b(?:what is|meaning of|explain) (?:rizq|rizk)\b', r'\bwho provides (?:for )?(?:us|everyone|sustenance)\b'],
  x=[r'\b(?:debt|haram|riba|interest)\b'],
  topic='rizq',
  go=['/adhkar'],
  text="""
Rizq is what Allah provides: money, food, health, family and more. The Qur'an says there is no creature on earth but its provision is on Allah ({QR 11:6}), and that whoever has taqwa, Allah makes a way out for him and provides for him from where he does not expect ({QR 65:2-3}).

Seeking provision is a duty of effort, and trust in Allah goes with it. Ali reported a du'a the Prophet ﷺ taught: {HS tirmidhi:3563|"O Allah, suffice me with Your lawful against Your prohibited, and make me independent of all besides You by Your grace"}, and he said Allah would fulfil even a mountain of debt.
""",
  review='Scholar review needed: the du\'a is cited for lawful provision, and the hadith is graded hasan.')

E('dua-debt',
  m=[r'\b(?:dua|du a|supplication)\b.*\b(?:debt|debts|loan|owe|owing|in debt)\b', r'\bwhat (?:to|do i|should i) say (?:when|if) (?:i am |im |i m )?in debt\b', r'\bhow (?:to|do i|can i) (?:pay|get out of|repay) (?:my )?debts? (?:islam|islamic|dua|with allah)\b'],
  x=[r'\b(?:interest|riba|haram|ruling|mortgage)\b'],
  topic='dua for debt',
  go=['/adhkar'],
  text="""
Ali reported that the Prophet ﷺ taught this du'a: {HS tirmidhi:3563|"O Allah, suffice me with Your lawful against Your prohibited, and make me independent of all besides You by Your grace"}, and said that if you had a debt like a mountain, Allah would fulfil it for you.

In Arabic: Allahumma-kfini bihalalika 'an haramik, wa aghnini bifadlika 'amman siwak. The Prophet ﷺ also sought refuge from being heavily in debt, in a du'a recorded in Sahih al-Bukhari 6369. Paying what you owe, with the effort of earning, goes with the du'a.
""",
  review='Scholar review needed: the du\'a is graded hasan; the last sentence is the app\'s advice.')

E('dua-new-clothes',
  m=[r'\b(?:dua|du a|supplication|what (?:to|do i|should i) say)\b.*\b(?:new clothes|new clothing|new garment|new dress|new shirt|new shoes|wearing something new|put(?:ting)? on (?:something )?new|wear(?:ing)? (?:new|clothes))\b', r'\bwhat (?:to|do i|should i) say (?:when|if) (?:i )?(?:wear|put on|buy) (?:something )?new\b'],
  topic='dua for new clothes',
  go=['/adhkar'],
  text="""
Abu Sa'id al-Khudri reported: {HS abudawud:4020|when the Prophet ﷺ put on a new garment he mentioned it by name, whether turban or shirt, and said "O Allah, praise be to You as You have clothed me with it, I ask You for its good and the good of that for which it was made, and I seek refuge in You from its evil and the evil of that for which it was made"}.

Abu Nadrah added that when a Companion put on a new garment, he was told: may you wear it out, and may Allah give you another in its place.
""",
  review='Scholar review needed.')

E('dua-bad-dream',
  m=[r'\b(?:dua|du a|supplication|what (?:to|do i|should i) (?:say|do))\b.*\b(?:bad dream|bad dreams|nightmare|nightmares|scary dream|evil dream|disturbing dream)\b', r'\b(?:bad dream|bad dreams|nightmare|nightmares|scary dream)\b.*\b(?:islam|islamic|dua|what to do|say|sunnah)\b', r'\bwhat (?:to|do i|should i) do (?:after|if i have|when i have|when i get) (?:a )?(?:bad dream|nightmare)\b'],
  topic='after a bad dream',
  text="""
Abu Qatada reported the Prophet ﷺ saying: {HS bukhari:5747|a good dream is from Allah and a bad dream is from Satan, so if anyone sees something he dislikes in a dream, when he wakes he should blow three times on his left side and seek refuge with Allah from its evil, and it will not harm him}.

In Arabic the refuge is: A'udhu billahi min sharri ma ra'ayt. Do not fear it: the hadith says it will not harm you.
""",
  review='Scholar review needed: the Arabic phrase is the usual wording for the refuge, not quoted from this report.')

E('dua-shaytan-protection',
  m=[r'\b(?:dua|du a|supplication|how)\b.*\b(?:protect\w*|safe\w*|refuge|defen\w*|guard)\b.*\b(?:shaytan|satan|devil|whisper\w*|waswas|waswasa)\b', r'\b(?:protect|protection|refuge|safe)\b.*\b(?:from|against)\b.*\b(?:shaytan|satan|the devil)\b', r'\bhow (?:to|do i|can i) (?:stop|resist|fight|defeat|beat|avoid) (?:the )?(?:shaytan|satan|devil|whispers|waswas)\b', r'\bwaswas(?:a)?\b'],
  x=[r'\b(?:house|home|sleep|dream)\b'],
  topic='protection from Shaytan',
  go=['/adhkar'],
  text="""
The Qur'an says: if an evil suggestion from Satan comes to you, seek refuge in Allah, for He is the Hearing, the Knowing ({QR 7:200}). It also gives a du'a: my Lord, I seek refuge in You from the whisperings of the devils ({QR 23:97}).

The Prophet ﷺ taught the same words to someone furious: {H bukhari:6115}. So "A'udhu billahi minash-shaytanir-rajim" is the first thing to say. The last three surahs, Al-Ikhlas, Al-Falaq and An-Nas, are also commonly recited for refuge; I am not citing a hadith for that here.
""",
  review='Scholar review needed: the mention of the last three surahs is common practice with no hadith cited here.')

E('dua-new-baby-name',
  m=[r'\b(?:dua|du a|supplication)\b.*\b(?:newborn|new born|new baby|newly born|baby (?:is )?born|birth)\b', r'\bhow (?:to|do i|should i) (?:name|choose a name for) (?:a |my |the )?(?:baby|child|son|daughter|newborn)\b', r'\bwhat (?:are|is) (?:the )?(?:best|good|recommended) (?:names?|name) (?:for|in|according to) (?:a )?(?:baby|child|islam|the prophet)\b', r'\bwhat to say (?:when|to) (?:someone|a friend|a person|a muslim)? ?(?:has|had|gets|got|having) a (?:baby|child|newborn)\b', r'\bislamic (?:naming|names?) (?:for|of) (?:a )?(?:baby|child)\b', r'\b(?:what is|whats|explain) (?:the )?aqiqah\b'],
  topic='newborn and naming',
  text="""
Ibn Umar reported the Prophet ﷺ saying: {HS muslim:2132|the names dearest to Allah are Abdullah and Abd al-Rahman}. Scholars also recommend a name with a good meaning and a good link to Allah's servants or prophets; that recommendation is the scholars' guidance, not a quotation.

For congratulating parents, Muslims commonly pray that Allah bless the child and make the parents grateful. I am not citing a hadith for that wording. For the aqiqah (a sacrifice on the seventh day), I have not checked a source to cite here, so please ask a scholar.
""",
  review='Scholar review needed: aqiqah is flagged as not covered on purpose.')

E('dua-ibrahim',
  m=[r'\b(?:dua|du a|supplication|prayer)\b.*\b(?:ibrahim|abraham|ibraheem)\b', r'\b(?:ibrahim|abraham|ibraheem)\b.*\b(?:dua|du a|supplication|prayed|asked)\b', r'\b(?:who was|tell me about|story of|life of) (?:prophet )?(?:ibrahim|abraham|ibraheem)\b'],
  topic='Prophet Ibrahim',
  go=['/quran'],
  text="""
Ibrahim is called Allah's friend, and the Qur'an gives his du'as. At the Ka'bah he and Ismail asked: our Lord, accept this from us, You are the Hearing, the Knowing ({QR 2:127}). He prayed for the land to be safe and for his offspring to establish prayer ({QR 14:35-37}), and asked forgiveness for himself and his parents ({QR 14:41}).

When he was thrown into the fire, he said "Allah is sufficient for us and the best disposer of affairs" (Sahih al-Bukhari 4563).
""",
  review='Scholar review needed: Bukhari 4563 is cited in the closing sentence in plain text.')

E('story-musa',
  m=[r'\b(?:story|tale|life) of (?:prophet )?(?:musa|moses|moosa)\b', r'\b(?:who was|tell me about) (?:prophet )?(?:musa|moses|moosa)\b', r'\b(?:musa|moses|moosa)\b.*\b(?:story|pharaoh|firaun|fir aun|red sea|staff|torah)\b'],
  topic='Prophet Musa',
  go=['/quran'],
  text="""
Musa is the prophet named most often in the Qur'an. He was raised in Pharaoh's house, was sent to Pharaoh with signs, and led the Children of Israel out of Egypt ({QR 20:77}). He spoke with Allah ({QR 4:164}), and was given the Torah.

The full account is spread across many surahs, with a long telling in Surah Ta-Ha and Surah Al-Qasas. I am only giving a short outline; ask me about a part of it.
""",
  review='Scholar review needed: the outline is from the surahs named.')
