# Knowledge pack F (21 Nov 2026): animals, trees, virtues, the grave, the last day.
# Hadith are read against the corpus by build.py. Short answers; each is flagged for review.

E('kindness-to-animals',
  m=[r'\b(?:kind\w*|mercy|merciful|compassion\w*|good|treat\w*|cruel\w*|rights?) (?:to|towards|toward|for|of) (?:animals?|pets?|dogs?|cats?|birds?)\b', r'\banimals? (?:in|and) islam\b', r'\bislam\b.*\b(?:animals?|pets)\b', r'\breward (?:for|of) (?:feeding|giving water to|watering) (?:an? )?(?:animals?|dogs?|cats?|birds?)\b'],
  topic='kindness to animals',
  go=['/hadith'],
  text="""
Islam teaches mercy to every living creature.

Abu Hurayrah reported the Prophet ﷺ telling of a thirsty man who found a panting dog: {HS bukhari:2363|the man filled his shoe with water and watered the dog, and Allah thanked him and forgave him}. When the people asked whether there is a reward for serving animals, he said yes, there is a reward for serving any living creature.

So feeding, watering and caring for an animal is a good deed, and causing it needless suffering is not allowed.
""",
  review='Scholar review needed: the last sentence is a general conclusion; scholars give detail on hunting, slaughter and keeping pets.')

E('planting-trees-reward',
  m=[r'\b(?:plant\w*|sow\w*) (?:a |some )?(?:trees?|seeds?|crops?|gardens?)\b', r'\breward (?:for|of) (?:planting|growing) (?:a )?(?:tree|seeds?|garden)\b', r'\btrees? (?:in|and) islam\b', r'\bislam\b.*\b(?:planting|trees)\b'],
  topic='the reward of planting a tree',
  go=['/hadith'],
  text="""
Anas ibn Malik reported the Prophet ﷺ saying: {HS bukhari:2320|there is no Muslim who plants a tree or sows seeds, and then a bird, a person or an animal eats from it, but it is counted as a charity for him}.

The reward continues for as long as anything benefits from it, which is why scholars place it among ongoing charity (sadaqah jariyah).
""",
  review='Scholar review needed: the second paragraph is the scholars\' common explanation.')

E('surah-mulk-virtue',
  m=[r'\b(?:virtue|benefit|reward|merit|power|importance) (?:of )?(?:reciting |reading )?(?:surah |sura )?(?:al )?(?:mulk|tabarak)\b', r'\b(?:surah |sura )?(?:al )?(?:mulk|tabarak)\b.*\b(?:virtue|benefit|reward|grave|intercede|night|bed)\b', r'\bwhy (?:should i|do we) (?:read|recite) (?:surah |sura )?(?:al )?mulk\b'],
  topic='the virtue of Surah Al-Mulk',
  go=['/quran'],
  text="""
Abu Hurayrah reported the Prophet ﷺ saying: {HS tirmidhi:2891|there is a surah of thirty verses that intercedes for a man until he is forgiven, Tabarak Alladhi bi-Yadihil-Mulk}.

That is Surah Al-Mulk, the 67th surah. Many Muslims recite it each night.
""",
  review='Scholar review needed: the nightly habit is a practice and not in this hadith.')

E('munkar-nakir-grave',
  m=[r'\b(?:munkar|nakir|nakeer|munkir)\b', r'\btwo angels (?:in|of|who) (?:the )?grave\b', r'\bquestion\w* (?:in|of) (?:the )?grave\b', r'\bwhat happens (?:in|at) (?:the )?grave\b', r'\bfirst night in (?:the )?grave\b'],
  topic='the questioning in the grave',
  go=['/hadith'],
  text="""
Abu Hurayrah reported the Prophet ﷺ saying: {HS tirmidhi:1071|when the deceased is buried two angels, black and blue-eyed, come, one called Al-Munkar and the other An-Nakir, and ask what he used to say about this man; the believer says that he is Allah's slave and His Messenger, and his grave is made wide and lit for him and he is told to sleep like a newlywed}.

The same hadith says the hypocrite gives the answer 'I heard people saying something and said it', and his grave is squeezed. This is part of the life of the barzakh, which is known only through revelation.

Allah says about the believers: Allah keeps firm those who believe with the firm word in this life and in the Hereafter ({QR 14:27}).
""",
  review='Scholar review needed: the second paragraph paraphrases the rest of the narration from the corpus; confirm the wording and how scholars explain the barzakh.')

E('dajjal-warning',
  m=[r'\b(?:dajjal|dajaal|antichrist|anti christ|one eyed (?:liar|impostor|deceiver))\b', r'\bwho is (?:the )?dajjal\b'],
  topic='the Dajjal',
  go=['/hadith'],
  text="""
The Dajjal is the great deceiver who will appear near the end of time.

Anas reported the Prophet ﷺ saying: {HS bukhari:7131|no prophet was sent without warning his people about the one-eyed liar, who is blind in one eye while your Lord is not, and the word Kafir will be written between his eyes}.

The Prophet ﷺ also taught believers to seek refuge from the trial of the Dajjal at the end of the prayer. Details of his coming are reported in many narrations, and scholars advise learning them from reliable books.
""",
  review='Scholar review needed: the seeking of refuge is stated from general knowledge and not cited here; add the narration (Muslim 588) before approval if the reviewer agrees.')

E('firdaws-paradise',
  m=[r'\b(?:firdaws|firdous|firdaus|al firdaws)\b', r'\b(?:levels?|grades?|degrees?|ranks?) of (?:paradise|jannah)\b', r'\bhighest (?:part|level|place) (?:of|in) (?:paradise|jannah)\b', r'\bwhat should i ask allah for in jannah\b'],
  topic='the levels of Paradise and Al-Firdaws',
  go=['/hadith'],
  text="""
Abu Hurayrah reported the Prophet ﷺ saying: {HS bukhari:2790|Paradise has a hundred grades, each as far from the next as heaven is from earth, and when you ask Allah ask for Al-Firdaws, which is the best and highest part of Paradise}.

Allah says of the believers who keep their prayers: they will inherit Al-Firdaws, and they will stay in it forever ({QR 23:10-11}).
""",
  review='Scholar review needed: the Bukhari narration also connects the hundred grades to those who strive in Allah\'s cause; the summary here keeps only the part about asking for Al-Firdaws.')

E('walking-to-masjid-reward',
  m=[r'\b(?:reward|virtue|benefit) (?:of|for) (?:walking|going) to (?:the )?(?:masjid|mosque)\b', r'\b(?:walking|going on foot) to (?:the )?(?:masjid|mosque)\b', r'\bfootsteps? (?:to|toward|towards) (?:the )?(?:masjid|mosque)\b', r'\bevery step (?:to|toward|towards) (?:the )?(?:masjid|mosque)\b'],
  topic='the reward of walking to the masjid',
  go=['/prayer'],
  text="""
Anas reported that the people of Banu Salimah wanted to move closer to the Prophet ﷺ, and he said: {HS bukhari:655|for every step toward the mosque there is a reward, and your footprints are counted}.

So even a long walk to the masjid is rewarded.
""",
  review='Scholar review needed: the summary shortens a longer narration.')

E('friday-virtue',
  m=[r'\b(?:virtue|excellence|merit|importance|best|blessing) (?:of )?(?:the )?(?:day of )?(?:friday|jumuah|jummah|jumah|jumua)\b', r'\bwhy is (?:friday|jumuah|jummah|jumah) (?:special|important|blessed|the best)\b', r'\bwhat (?:happened|happens) on (?:a )?friday\b', r'\bsend\w* blessings? on (?:the )?prophet on friday\b', r'\bsalawat on friday\b'],
  topic='the virtue of Friday',
  go=['/huda'],
  text="""
Abu Hurayrah reported the Prophet ﷺ saying: {HS muslim:854|the best day on which the sun has risen is Friday; on it Adam was created and made to enter Paradise, and on it he was expelled from it, and the Last Hour will take place on a Friday}.

So Friday is a day for ghusl, Jumu'ah prayer, Surah Al-Kahf, and sending blessings on the Prophet ﷺ.
""",
  review='Scholar review needed: the last paragraph lists customs reported elsewhere (ghusl, Surah Al-Kahf); each needs its own source before approval.')

E('first-judged-bloodshed',
  m=[r'\bfirst (?:thing|matter|case|cases)\b.*\b(?:judg\w*|decid\w*|reckon\w*|questioned|asked)\b', r'\b(?:judged|decided|reckoned) first\b', r'\bwhat will (?:be )?(?:judged|decided) first\b'],
  x=[r'\bprayer\b', r'\bsalah\b', r'\bsalat\b'],
  topic='the first cases judged between people',
  go=['/hadith'],
  text="""
'Abdullah ibn Mas'ud reported the Prophet ﷺ saying: {HS tirmidhi:1396|the first cases to be judged between the people are those of bloodshed}.

This is about disputes between people. As for the worship of a person, scholars quote a separate narration that the first thing the servant is held to account for is the prayer.
""",
  review='Scholar review needed: the final sentence is stated without a source; add the narration (Tirmidhi 413 or Nasa\'i 465) with its grade before approval.')

E('front-rows-prayer',
  m=[r'\b(?:virtue|reward|importance|benefit) (?:of )?(?:the )?(?:first|front) (?:row|rows|saff)\b', r'\bwhy (?:is|are) (?:the )?(?:first|front) rows? (?:best|better|important)\b', r'\bbest rows? (?:for|in) (?:men|women|prayer)\b', r'\bstraight\w* (?:the )?rows? (?:in|for) (?:prayer|salah)\b'],
  topic='the rows in congregational prayer',
  go=['/prayer'],
  text="""
Abu Hurayrah reported the Prophet ﷺ saying: {HS muslim:440|the best rows for men are the first rows and the worst the last, and the best rows for women are the last and the worst for them the first}.

This refers to prayer in a mixed congregation, where the women's rows are behind the men's. Keeping the rows straight and filling the gaps is also part of the prayer.
""",
  review='Scholar review needed: the second paragraph is general explanation; add narrations on straightening rows (Bukhari 723 or Muslim 433) before approval if wanted.')
