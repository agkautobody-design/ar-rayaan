# Food, drink and everyday life: what is halal, and the questions people ask about it.

E('pork',
  m=[r'\bpork\b', r'\bpig\b', r'\bpigs\b', r'\bswine\b', r'\bbacon\b', r'\bham\b', r'\bhot ?dogs?\b.*\b(?:halal|haram|eat|allowed)\b', r'\blard\b', r'\bpepperoni\b', r'\bwhy is pork\b', r'\bwhy (?:can t|cant|do) muslims? (?:not )?eat pork\b'],
  topic='pork',
  text="""
Pork is forbidden for Muslims. Allah says: {Q 2:173|He has only forbidden to you dead animals, blood, the flesh of swine, and that which has been dedicated to other than Allah}. The same is said in {QR 5:3} and {QR 6:145}. This covers the meat and fat (lard) of the pig and foods made from them, such as bacon, ham and pepperoni.

Please also check labels: gelatin, some enzymes, emulsifiers and shortening can come from pigs unless the label says halal, vegetable or beef. See the answer on gelatin.

The exception is necessity: the same verse says {Q 2:173|whoever is forced [by necessity], neither desiring [it] nor transgressing [its limit], there is no sin upon him}. If you eat it by mistake without knowing, there is no sin; just stop when you find out.
""",
  review='Forbidden status and the necessity exception are cited; label advice is general.')

E('alcohol',
  m=[r'\balcohol\b', r'\bwine\b', r'\bbeer\b', r'\bliquor\b', r'\bwhisky\b', r'\bwhiskey\b', r'\bvodka\b', r'\bintoxicant\w*\b', r'\bkhamr\b', r'\bdrinking\b.*\b(?:haram|halal|allowed|islam)\b', r'\bdrunk\b',
     r'\b(?:hand )?sanitizer\b', r'\bvanilla (?:extract|essence)\b', r'\bcook\w* with (?:wine|alcohol)\b', r'\bnon ?alcoholic (?:beer|wine|drinks?)\b', r'\balcohol[- ]free\b', r'\bperfume\b.*\balcohol\b', r'\bkombucha\b'],
  x=[r'\b(?:game|story|stories)\b'],
  topic='alcohol',
  text="""
Alcohol is forbidden in Islam. Allah says: {Q 5:90|intoxicants, gambling, [sacrificing on] stone alters [to other than Allah], and divining arrows are but defilement from the work of Satan, so avoid it that you may be successful}. The Prophet ﷺ said: every intoxicant is khamr and every intoxicant is forbidden ({H muslim:2003|Ibn Umar reported the Prophet said every intoxicant is khamr and every intoxicant is forbidden, and whoever drinks wine in this world and dies addicted to it without repenting will not be given a drink in the Hereafter}). This includes beer, wine, spirits, and drugs that intoxicate.

Questions people often have:
- Cooking with alcohol: avoid it; if it is a recipe that keeps the alcohol in the dish, the dish is forbidden. Many scholars do not allow cooking it away either.
- Hand sanitiser and perfume containing alcohol: used on the outside, most contemporary scholars allow them, since the ruling is on drinking and the alcohol is not for intoxication. Some prefer alcohol-free.
- Non-alcoholic ("0.0%") drinks that taste like beer or wine: scholars differ. Some allow them if truly under about 0.5% and not intoxicating; others dislike them because of the name and imitation. A cautious person avoids them.
- Vinegar, including vinegar that began as wine and has fully turned to vinegar: most scholars allow it, though some dislike making it from wine on purpose. The Prophet ﷺ said the best of condiments is vinegar ({H muslim:2051|A'isha reported the Prophet said the best of condiments is vinegar}).
- Tiny traces from natural fermentation in food (a ripe fruit, bread, or vinegar) are not what is meant.
- Medicine: if there is no alternative, medicine containing alcohol is allowed by necessity; ask your doctor for a non-alcoholic form.

If you slipped, repent and do not return. Allah is forgiving ({QR 39:53}).
""",
  review='Contemporary rulings on perfumes, sanitiser, and 0.0% drinks are described as differences; not text-checked here.')

E('seafood-shrimp',
  m=[r'\b(?:shrimp|prawn|prawns|crab|lobster|oyster|oysters|clam|clams|mussel|mussels|squid|calamari|octopus|shellfish|seafood|sea food|eel|catfish|crustacean\w*|scallop\w*|fish)\b.*\b(?:halal|haram|allowed|permissible|permitted|eat|forbidden|makruh|islam)\b',
     r'\b(?:halal|haram|allowed|permissible|permitted|forbidden|makruh)\b.*\b(?:shrimp|prawn|prawns|crab|lobster|oyster|oysters|clam|clams|mussel|mussels|squid|calamari|octopus|shellfish|seafood|sea food|eel|catfish|crustacean\w*|scallop\w*|fish)\b'],
  topic='seafood',
  text="""
Most of the seafood you ask about is halal. The Qur'an says {Q 5:96|Lawful to you is game from the sea and its food as provision for you and the travelers}. When a man asked the Prophet ﷺ about wudu with sea water, he said its water is pure and what dies in it is lawful to eat ({H abudawud:83|A man asked the Prophet whether they could do wudu with sea water; he said its water is pure and what dies in it is lawful food}).

The schools differ on the detail:
- The Maliki, Shafi'i and Hanbali schools: all sea animals are halal (with some exceptions for harmful ones in some views). That includes fish, shrimp, prawns, crab, lobster, squid and octopus.
- The Hanafi school: fish only is halal without question. Shrimp and prawns are considered fish by many Hanafi scholars and are permitted; other shellfish such as crab and lobster are disliked or forbidden for strict Hanafis, and many Hanafi scholars today allow them.

So shrimp is halal in all the schools according to most scholars; if you follow the Hanafi school strictly, ask your scholar about crab, lobster and other shellfish. Seafood cooked in alcohol or fried in oil also used for pork is another matter.
""",
  review='Hanafi view on shellfish other than fish and shrimp is described in general terms and varies among Hanafi scholars; not text-checked here.')

E('gelatin',
  m=[r'\bgelatin\w*\b', r'\bgelatine\b', r'\bmarshmallows?\b', r'\bgummy\b', r'\bgummies\b', r'\bjello\b', r'\bjelly\b.*\b(?:halal|haram)\b', r'\bcapsules?\b.*\b(?:gelatin|halal|haram)\b', r'\bvaccin\w*\b.*\b(?:pork|gelatin|haram|halal)\b',
     r'\bhidden (?:haram|ingredients?)\b', r'\bfood (?:additives?|e numbers?|ingredients?)\b', r'\be ?[0-9]{3}\b.*\b(?:halal|haram)\b', r'\bhow (?:do|to) (?:i )?check (?:if )?(?:food|a product|ingredients?) (?:is )?halal\b', r'\bis this halal\b'],
  topic='gelatin',
  text="""
Gelatin is made from animal skin and bones, usually pork or beef. Pork is forbidden ({QR 2:173}), so:
- Pork gelatin is haram.
- Gelatin from beef or fish is halal if the cattle were slaughtered in the Islamic way (for beef) or it is from fish.
- Gelatin when the source is not stated: scholars differ. Some (including several fiqh councils) hold that the bones and skin undergo a complete chemical change (istihalah) and so the final product is pure and lawful; others say pork remains pork, so it is not allowed. Because of this real difference, the careful course is to avoid gelatin of unknown source and to choose products marked halal, fish gelatin, pectin or agar.

How to check: look for a halal logo from a certifier you trust; "gelatin" alone does not tell you the animal. Other hidden items include alcohol in flavourings, pork-derived enzymes, lard and some emulsifiers (E441 is gelatin; E120, carmine, is from insects and disputed). Marshmallows, gummy sweets, jelly desserts and some capsules and vaccines commonly contain gelatin.

For medicines and vaccines, many scholars allow them even if gelatin of uncertain source is in them, when there is a need and no alternative; ask your doctor and a scholar.
""",
  review='The istihalah debate on gelatin, carmine, and the medicine allowance are contested positions; flagged for scholar review.')

E('halal-meat',
  m=[r'\bhalal meat\b', r'\bzabiha\b', r'\bzabihah\b', r'\bdhabiha\b', r'\bslaughter\w*\b', r'\bstunn\w*\b', r'\bkosher\b', r'\bsupermarket meat\b', r'\bmeat from (?:a )?(?:non muslim|christian|jewish|supermarket|restaurant)\b',
     r'\bnon muslim\b.*\b(?:meat|food|slaughter)\b', r'\b(?:meat|food)\b.*\b(?:people of the book|ahl al kitab|christians?|jews?)\b', r'\bbismillah\b.*\b(?:eat|meat|slaughter)\b', r'\bhalal (?:food|restaurant|restaurants|certification|certified)\b',
     r'\beat(?:ing)? (?:at|in) (?:a )?(?:non muslim|restaurant|mcdonalds|kfc|fast food)\b', r'\bwhat makes (?:meat|food) halal\b', r'\bhow (?:do|can|to) (?:i|we|you) (?:know|tell|check|find out) (?:if |whether )?(?:the )?(?:meat|food|chicken|beef|this|it) (?:is )?halal\b', r'\bhow to know (?:if )?(?:meat|food) is halal\b', r'\bis (?:kfc|mcdonalds|subway|fast food) halal\b', r'\bchicken\b.*\bhalal\b'],
  x=[r'\b(?:near me|nearby|app|find)\b'],
  topic='halal meat',
  text="""
Meat is halal when the animal is a permitted kind (cattle, sheep, goat, camel, chicken, deer, etc. - not pig, carnivores, or dead animals), and it is slaughtered properly: by a Muslim (or one of the People of the Book), with a sharp knife cutting the throat, saying "Bismillah, Allahu akbar" at the time, so that the blood flows. The Qur'an forbids {QR 5:3} dead animals, blood, pork and what is dedicated to other than Allah.

What about meat from non-Muslims? The Qur'an says {Q 5:5|the food of those who were given the Scripture is lawful for you}. The majority of scholars take this to mean the meat of Jews and Christians who slaughter in their religion's way is allowed. But many say today's industrial slaughter, which may not follow that, is not covered. So:
- Safest: buy meat that is certified halal.
- Kosher meat is accepted by many scholars as it follows a similar slaughter, though some require "Bismillah".
- Supermarket or restaurant meat of unknown slaughter: scholars differ. Some allow it based on the verse above, citing the general rule that food is lawful unless known to be unlawful. Others say it is not allowed unless known to be halal. Following the stricter view is the common practice.
- Stunning: allowed by many scholars if the animal is alive at the cut and would survive the stun; others reject it. Machine slaughter with a recorded "Bismillah" is also debated.
- Fish and seafood do not need slaughter.

If you find yourself eating non-halal meat by mistake or when no halal exists, there is no sin on the one who does not know. Fast food chains differ by country and branch: check the certificate. The Masajid and Halal screen can help you find halal places.
""",
  go=['/masajid'],
  review='Rulings on People of the Book meat, supermarket meat, stunning and machine slaughter are contested and described as differences; flagged for scholar review.')

E('tattoo',
  m=[r'\btattoo\w*\b', r'\bpiercing\w*\b', r'\bear ?piercing\w*\b', r'\bnose ?piercing\w*\b', r'\bbody (?:art|modification)\b', r'\bpermanent makeup\b', r'\bmicroblading\b', r'\bhenna\b.*\b(?:halal|haram|allowed|sunnah)\b'],
  x=[r'\b(?:wudu|ghusl|prayer)\b'],
  topic='tattoo',
  text="""
Permanent tattoos are forbidden according to most scholars. The Prophet ﷺ said that Allah cursed the woman who tattoos and the one who has it done ({H bukhari:5937|The Prophet said Allah has cursed the lady who lengthens hair artificially or has it lengthened, and the one who tattoos or gets tattooed}). The reasons scholars give are that it changes Allah's creation, causes pain and harm, and blocks water in some views.

Practical points:
- If you got a tattoo before you were a Muslim, or before you knew, there is no sin on you now; repent and go forward. Wudu and prayer are valid with a tattoo.
- Removing it: scholars say you are not required to remove a tattoo if removal would cause serious harm or great pain; remove it if that is easily done.
- Henna and other temporary designs that wash off are allowed (for women and in moderation). Medical tattoos (for example, marking a radiation site or hiding a scar) are allowed by necessity.
- Ear piercing for women is allowed; most scholars dislike or forbid body piercing for men that imitates women, and extreme body modification.
""",
  review='Removal of old tattoos, piercings for men, and medical tattoos are standard fiqh positions; not text-checked here.')

E('dogs',
  m=[r'\bdogs?\b', r'\bpuppy\b', r'\bpuppies\b', r'\bguide dogs?\b', r'\bservice dogs?\b', r'\bhunting dogs?\b', r'\bsniffer\b'],
  x=[r'\b(?:najis|najasa|impure)\b', r'\b(?:game|story|stories)\b', r'\bcats?\b'],
  topic='pets',
  text="""
Dogs: scholars differ on keeping and touching them.
- Keeping a dog as a house pet is discouraged: the Prophet ﷺ said that whoever keeps a dog that is neither a watch dog nor a hunting dog loses two qirat of his good deeds every day ({H bukhari:5480|The Prophet said whoever keeps a dog that is neither a watch dog nor a hunting dog will get a daily deduction of two qirat from his good deeds}). Keeping a dog for hunting, herding or guarding is allowed, and most scholars add a guide or service dog for a person who needs it.
- Touching a dog or its saliva: the Shafi'i and Hanbali schools treat the saliva as impure and require washing seven times; the Maliki school treats the dog as pure; see the impurity answer. Dry contact is not a problem in any school.
- The angels: the Prophet ﷺ said the angels of mercy do not enter a house where there is a dog or a picture of a living creature ({H bukhari:3225|Abu Talha heard the Prophet say angels of mercy do not enter a house in which there is a dog or a picture of a living creature}). Scholars explain this in different ways.

Whatever you decide, be kind to dogs: cruelty to any animal is a sin, and feeding or giving water to a thirsty one is rewarded.
""",
  review='Dogs: the angels hadith is explained variously by scholars; a guide dog for the blind is a standard fiqh allowance; not text-checked here.')

E('pets-animals',
  m=[r'\bpets?\b', r'\bcats?\b', r'\bkitten\w*\b', r'\bkeep(?:ing)? (?:a )?(?:bird|birds|fish|rabbit|animals?|hamster|parrot|turtle|horse)\b', r'\banimals?\b.*\b(?:rights|treat\w*|cruel\w*|kind\w*)\b', r'\bcruelty to animals\b', r'\btreat\w* animals\b', r'\banimal rights\b'],
  x=[r'\b(?:game|story|stories)\b', r'\b(?:najis|najasa|impure)\b', r'\b(?:sacrifice|qurbani|udhiyah|aqiqah)\b', r'\bdogs?\b'],
  topic='pets',
  text="""
Cats: yes, you may keep them. The Prophet ﷺ said of the cat that it is not unclean ({H abudawud:75|Abu Qatadah let a cat drink from his wudu water and said the Prophet said it is not unclean, it is one of those that go round among you}). He also warned that a woman entered the Fire because of a cat she had tied up and neither fed nor let go ({H bukhari:3318|The Prophet said a woman entered the Fire because of a cat which she had tied, neither giving it food nor setting it free to eat from the vermin of the earth}). So caring for any animal is rewarded, and cruelty to one is a sin.

Other pets (birds, fish, rabbits and so on) are allowed if you feed them, give them room and do not harm them. Do not keep a bird in a cage so small that it cannot live well. For dogs, ask me about dogs.
""",
  review='Pets: the allowance for other pets is the general view; not text-checked here.')

E('gold-silk-men',
  m=[r'\bgold\b.*\b(?:men|man|male|males|boys?|husband|him)\b', r'\b(?:men|man|male|males|boys?)\b.*\bgold\b', r'\bsilk\b.*\b(?:men|man|male|males)\b', r'\b(?:men|man|male|males)\b.*\bsilk\b', r'\bgold (?:ring|chain|watch|necklace|jewel\w*)\b', r'\bsilver ring\b', r'\bwear(?:ing)? (?:gold|silk|platinum|diamonds?|jewel\w*)\b', r'\bplatinum\b'],
  x=[r'\b(?:zakat|nisab|sell|buy|invest|price|crypto)\b', r'\bgold standard\b'],
  topic='gold',
  text="""
For men, wearing gold and pure silk is forbidden; for women both are allowed. The Prophet ﷺ said: {H tirmidhi:1720|Abu Musa reported the Messenger of Allah said wearing silk and gold has been made unlawful for the males of my Ummah and lawful for its females}. He once pulled a gold ring from a man's hand and threw it away ({H muslim:2090|Ibn Abbas reported the Messenger of Allah saw a man wearing a gold signet ring, pulled it off and threw it away, saying one of you wishes for a live coal from Hell and puts it on his hand}).

Silver is allowed for men, and a silver ring was worn by the Prophet ﷺ ({H bukhari:5865|Abdullah reported the Prophet wore a gold ring, then threw it away when people copied him and wore a silver ring instead}). Other metals such as platinum or steel, and silk mixed with other cloth, are allowed by most scholars; ask a scholar if you are unsure. A gold tooth filling or a gold nose or surgery fixture for medical need is allowed.
""",
  review='Platinum, mixed silk, medical gold are standard views and described as such; not text-checked here.')

E('hair-dye',
  m=[r'\bdy(?:e|ing) (?:my |the )?hair\b', r'\bhair dye\b', r'\bhair colou?r\w*\b', r'\bcolou?r(?:ing)? (?:my |the )?hair\b', r'\bblack dye\b', r'\bgrey hair\b', r'\bgray hair\b', r'\bwhite hair\b',
     r'\bhair extensions?\b', r'\bwigs?\b', r'\bbleach(?:ing)? (?:my |the )?hair\b', r'\bhighlights\b.*\bhair\b', r'\bcut(?:ting)? (?:my |the )?hair\b', r'\bhaircut\b', r'\bqaza\b', r'\bshav\w* (?:my )?(?:head|legs?|armpits?|pubic)\b', r'\bfitrah\b.*\b(?:nails?|hair)\b'],
  topic='hair',
  text="""
Hair colour:
- Grey or white hair: the Prophet ﷺ told Abu Bakr's father, whose hair and beard were white, to change the colour with something but to avoid black ({H muslim:2102|Jabir reported that Abu Quhafah came on the day of the conquest with hair white like hyssop, and the Prophet told them to change it with something but avoid black}). So henna, or a brown or yellow dye, is recommended; black is disliked by most scholars (some scholars allow it for women, or in war).
- Dyeing hair that is not grey for fashion, in a non-black colour, is allowed for both men and women by most scholars, as long as the dye is not a barrier that stops water from reaching the hair (it must be washable-through in wudu: stains are fine; paint-like coatings are not).
- Bleaching or highlights: allowed, within modesty, as long as you are not imitating a way of life that Islam forbids.

Hair extensions: attaching other people's hair is forbidden in the hadith in {H bukhari:5937|The Prophet said Allah has cursed the lady who lengthens hair artificially or has it lengthened, and the one who tattoos or gets tattooed}; most scholars apply it to real human hair, and some extend it to anything attached that looks like your own. Wigs: scholars differ.

Cutting hair: allowed for men and women, with modesty. A woman may trim her hair; she should not cut it to imitate men.

Body hair: removing pubic and underarm hair, clipping the nails and trimming the moustache are part of the fitrah, the natural practices ({H muslim:258|Anas reported a time limit was prescribed for clipping the moustache, cutting the nails, plucking the hair under the armpits and shaving the pubes, that it should not be neglected for more than forty nights}). Removing hair elsewhere, such as legs or arms, is not forbidden for a woman; men should not imitate women in ways that are specific to them. Shaving the whole head is allowed for a man, and is part of the rites of Hajj and Umrah.
""",
  review='Dye colours, extensions and wigs are contested; the positions are standard fiqh teaching, not text-checked here.')

E('birthday-festivals',
  m=[r'\bbirthdays?\b', r'\bcelebrat\w*\b.*\b(?:christmas|easter|halloween|diwali|new year|new year s|valentine\w*|thanksgiving|mother s day|father s day|anniversary|holi|lunar new year|chinese new year|hanukkah|st patrick\w*|april fool\w*|mawlid|milad|prophet s birthday|shab e barat|nisf shaban)\b',
     r'\b(?:christmas|easter|halloween|diwali|new year|new year s|valentine\w*|thanksgiving|mother s day|father s day|holi|lunar new year|chinese new year|hanukkah|mawlid|milad|prophet s birthday|shab e barat|nisf shaban)\b.*\b(?:muslims?|islam|haram|halal|allowed|permissible|celebrate|greet|wish)\b',
     r'\bmerry christmas\b', r'\bhappy (?:new year|diwali|christmas|easter|birthday|holidays?)\b', r'\bwish(?:ing)? (?:my |a )?(?:non muslim|christian|friend|neighbou?r|colleague)\w*\b.*\b(?:christmas|easter|diwali|holiday)\b',
     r'\bcan muslims? celebrate\b', r'\bis it (?:haram|allowed|ok|okay) to celebrate\b', r'\bgift\w* (?:to|for) (?:a )?non muslim\b', r'\bnon muslim (?:holiday|festival|celebration)\w*\b'],
  topic='celebrations',
  text="""
Islam has two festivals for the community: Eid al-Fitr and Eid al-Adha. The Prophet ﷺ said there is an Eid for every people and this is ours ({H bukhari:952|Aisha said Abu Bakr protested at two girls singing in her house, and the Prophet said leave them, for there is an Eid for every people and this is our Eid}).

Birthdays: scholars differ. Many scholars say that marking a birthday as a regular celebration is not from the practice of the Prophet ﷺ and his companions, and so avoid it, and some of them consider it an imitation of others. Other scholars see a birthday party or a gift as a social custom, not worship, and so permitted, as long as it has nothing forbidden in it and is not treated as a religious ritual. Being kind to people on their day, thanking Allah for your life, giving thanks and making du'a is good on any day. Whichever view you follow, do not make it a matter for quarrelling in the family.

Festivals of other faiths (Christmas, Diwali, Easter and so on): most scholars say a Muslim should not take part in the religious rituals or the religious side of another faith's festival, nor give gifts that mark it as worship. Allah also asks us to be good and just to neighbours and co-workers of other faiths: {Q 60:8|Allah does not forbid you from those who do not fight you because of religion and do not expel you from your homes - from being righteous toward them and acting justly toward them}. Many scholars therefore allow a polite greeting or a card in return for theirs, and attending a family or workplace event without joining in the ritual; others are stricter and prefer not to congratulate on a religious day. Both are held by scholars.

Mawlid (the Prophet's birthday), Shab-e-Barat and similar nights: scholars differ widely, some treating them as good remembrance, others as additions to the religion. I will not rule between them; follow a scholar you trust and avoid anything forbidden.
""",
  review='Birthdays, congratulating non-Muslims on festivals, and Mawlid are contested; described as differences among scholars; flagged for scholar review.')

E('voting-politics',
  m=[r'\bvot(?:e|ing|ed)\b', r'\belections?\b', r'\bpolitics\b', r'\bpolitical part\w*\b', r'\bdemocracy\b', r'\bdemocratic\b', r'\bparticipat\w* in (?:politics|government|elections?)\b', r'\bwork(?:ing)? (?:for|in) (?:the )?(?:government|police|army|military)\b'],
  x=[r'\b(?:vote for (?:me|my)|game|poll in (?:the )?app)\b'],
  topic='voting',
  text="""
Scholars differ on voting and political participation in non-Muslim-majority countries and under man-made systems:
- Many contemporary scholars, and fiqh councils for Muslim minorities, say voting is allowed and even encouraged where it helps the community, reduces harm, protects Muslims' rights, or brings a better candidate. They argue from the principle of weighing benefit and harm, and from the Prophet's own treaties and just dealings.
- Some scholars say it is not allowed, because it involves taking part in a system that is not built on Islamic law, or because the candidates support what is forbidden.
- Between these, some say it depends on the circumstances: vote for the lesser harm, or for a candidate who defends justice, when not voting would bring greater harm.

Allah commands justice and honesty in trusts and in rule; Muslims in any country are told to be good citizens who obey the law as long as it does not command disobedience to Allah, and to be just to all. This app takes no side in politics and does not tell you whom to vote for. Ask a local scholar who knows the situation where you live.
""",
  review='Scholars differ on voting; described neutrally; flagged for scholar review.')

E('music',
  m=[r'\bmusic\b', r'\bmusical instruments?\b', r'\bsinging\b', r'\bsongs?\b', r'\bnasheeds?\b', r'\banasheed\b', r'\bduff\b', r'\bdrums?\b', r'\bguitar\b', r'\bpiano\b', r'\bconcerts?\b', r'\bflute\b', r'\bdancing\b',
     r'\blistening to (?:music|songs?|the radio)\b', r'\bis (?:music|singing) (?:haram|halal|allowed)\b'],
  x=[r'\b(?:player|play (?:a|the|some)|app|screen|where|find|open|queue|download)\b'],
  topic='music',
  text="""
Scholars have two positions on music, and both rest on evidence:
- Most classical scholars of the four schools, and many today, say musical instruments (other than the simple hand drum, the duff, at weddings and Eid) are forbidden. They rely on the report that some of the Prophet's followers will treat as lawful fornication, silk, wine and musical instruments ({H bukhari:5590|Abu Amir or Abu Malik al-Ash'ari heard the Prophet say that some of his followers will treat as lawful fornication, silk, wine and musical instruments}). Other scholars question the chain of this report, because Bukhari gives it without a full chain.
- Other scholars, including some classical ones such as Ibn Hazm, and many modern ones, say no clearly authentic text forbids music itself, and that it is allowed when the words and setting are free of what is forbidden.

Both agree that the duff and singing are allowed at weddings and Eid. The Prophet ﷺ defended the girls singing in A'ishah's house, saying there is an Eid for every people ({H bukhari:952|Aisha said Abu Bakr protested at two girls singing in her house, and the Prophet said leave them, for there is an Eid for every people and this is our Eid}).

Nasheeds with only the human voice, or with a duff, are accepted by nearly all scholars if the words are clean. Songs about love affairs, drink or immorality are discouraged by both views. This is a real difference, so follow the scholar you trust and avoid anything that distracts you from prayer and the Qur'an.
""",
  review='Music: two positions described neutrally; flagged for scholar review.')

E('beard',
  m=[r'\bbeards?\b', r'\bshav\w* (?:my )?(?:face|beard)\b', r'\btrim\w* (?:my )?beard\b', r'\bmoustache\b', r'\bmustache\b', r'\bclean shaven\b', r'\bshaving\b', r'\bshave\b'],
  topic='beard',
  text="""
The Prophet ﷺ said: trim the moustache and let the beard grow ({H bukhari:5892|Ibn Umar reported the Prophet said to differ from the polytheists, let the beard grow and trim the moustache}).

The scholars' positions:
- Most scholars (Hanafi, Maliki, Hanbali, and many Shafi'i) say growing the beard is required and shaving is forbidden.
- Some Shafi'i scholars and many modern scholars say it is a strongly recommended sunnah and that shaving is disliked, not a major sin.
- Trimming the beard: many allow trimming what extends beyond a fist's length; some say leave it entirely.

If you cannot grow a full beard, or you are in a job that insists on shaving, ask a scholar about your situation. A beard is not what makes a person a good Muslim; character, prayer and honesty come first.
""",
  review='Beard: school positions described in general terms; not text-checked here.')

E('hijab',
  m=[r'\bhijab\b', r'\bniqab\b', r'\bburqa\b', r'\bheadscarf\b', r'\bhead scarf\b', r'\bveil\w*\b', r'\bcover(?:ing)? (?:my |her |the )?hair\b', r'\bwhy (?:do )?(?:muslim )?(?:women|girls) (?:wear|cover)\b', r'\bmodest(?:y)? dress\b', r'\bawrah\b', r'\bwhat (?:should|must) (?:a )?(?:woman|women|man|men) (?:wear|cover)\b', r'\bdress code\b'],
  x=[r'\b(?:game|story)\b'],
  topic='hijab',
  text="""
Allah tells believing women: {Q 24:31|And tell the believing women to reduce [some] of their vision and guard their private parts and not expose their adornment except that which [necessarily] appears thereof and to wrap [a portion of] their headcovers over their chests}. And in {QR 33:59} He tells the Prophet to say to his wives, daughters and the believing women to bring down over themselves some of their outer garments.

The scholars agree that a woman covers her body in front of men who are not close relatives, and that men also have to cover from navel to knee and lower their gaze ({QR 24:30}). Most say the woman's face and hands may be uncovered, while some say the face too is covered (niqab); both views have scholars behind them. The hijab is a command in Islam, and a woman who is working up to it is still on the path.

Hijab is more than cloth: it is also modesty in behaviour, for men and women alike. Nobody should be forced into it or mocked for it; Allah says {Q 2:256|There shall be no compulsion in [acceptance of] the religion}.
""",
  review='Face covering view differences; standard fiqh; flagged for scholar review.')

E('smoking-vaping',
  m=[r'\bsmok\w*\b', r'\bcigarettes?\b', r'\btobacco\b', r'\bvap(?:e|ing|es)\b', r'\bshisha\b', r'\bhookah\b', r'\bcannabis\b', r'\bmarijuana\b', r'\bweed\b', r'\bdrugs?\b', r'\bcocaine\b', r'\bkhat\b', r'\bnicotine\b'],
  x=[r'\b(?:fasting|fast)\b.*\b(?:break|breaks|invalid\w*)\b'],
  topic='smoking',
  text="""
Smoking and vaping: most scholars today say they are forbidden, because they harm the body and Allah says {Q 2:195|do not throw [yourselves] with your [own] hands into destruction} and {Q 7:157|makes lawful for them the good things and prohibits for them the evil}. Some older scholars called it only disliked, before the harm was known. Shisha and hookah are treated the same.

Drugs that intoxicate, such as cannabis, cocaine and similar, are forbidden for the same reason as alcohol: see the answer on alcohol.

If you are trying to quit, that is a good intention and Allah rewards the effort. Ask a doctor for help, and remember that it breaks the fast (see the fasting answer).
""",
  review='Smoking: majority position with older minority noted; not text-checked here.')

E('superstition-astrology',
  m=[r'\bastrolog\w*\b', r'\bhoroscopes?\b', r'\bzodiac\b', r'\bfortune ?tell\w*\b', r'\bpalm ?read\w*\b', r'\btarot\b', r'\bsuperstiti\w*\b', r'\bfriday (?:the )?13(?:th)?\b', r'\bbad luck\b', r'\bevil eye\b', r'\bblack cat\b', r'\blucky (?:number|charm)s?\b', r'\bmagic\b', r'\bsihr\b', r'\bwitchcraft\b', r'\bamulet\w*\b', r'\btaweez\b', r'\btalisman\w*\b', r'\bjinn possess\w*\b'],
  x=[r'\b(?:game|story)\b'],
  topic='superstition',
  text="""
Islam rejects fortune-telling, astrology, horoscopes and omens of bad luck. Only Allah knows the unseen: {Q 27:65|None in the heavens and earth knows the unseen except Allah}. The Prophet ﷺ also said that whoever goes to a fortune-teller and asks him about anything, his prayer will not be accepted for forty nights ({H muslim:2230|Some of the wives of the Prophet reported the Prophet said whoever goes to a diviner and asks him about anything, his prayer will not be accepted for forty nights}). Believing in the diviner is worse.

So: do not read your horoscope as guidance, do not treat Friday the 13th, a black cat or a number as bad or good luck, and do not wear charms to bring luck or ward off harm; put your trust in Allah. Black magic (sihr) is real in the Qur'an but doing it is a major sin, and you protect yourself with the Qur'an and the morning and evening remembrances.

The evil eye is also real, and the cure is the Qur'anic protections and du'a, not amulets or tying things. If you are worried about harm to you, say Ayat al-Kursi and the last three surahs.
""",
  go=['/adhkar'],
  review='Superstition: hadith on diviners cited; Adhkar route assumed in whitelist.')

E('games-ruling',
  m=[r'\b(?:chess|ludo|backgammon|nardshir|nardashir|dice|dominoes?|playing cards?|card games?|poker|board games?|video games?|gaming|gamers?|playstation|xbox|pubg|fortnite|minecraft|roblox|esports|e sports|monopoly|carrom)\b.*\b(?:haram|halal|allowed|permissible|permitted|forbidden|ruling|sin|sinful|islamic|islam|muslims?|makruh)\b',
     r'\b(?:haram|halal|allowed|permissible|permitted|forbidden|ruling|sin|sinful|makruh)\b.*\b(?:chess|ludo|backgammon|dice|dominoes?|playing cards?|card games?|poker|board games?|video games?|gaming|playstation|xbox|pubg|fortnite|minecraft|roblox|esports|monopoly|carrom)\b',
     r'\b(?:can|may|should|do) (?:muslims?|i|we) (?:play|playing) (?:chess|ludo|backgammon|cards|games|video games|dice|board games|football|sports)\b',
     r'\bis (?:playing|it (?:haram|halal|ok|okay|allowed) to play) (?:chess|ludo|backgammon|cards|games|video games|dice|board games)\b'],
  x=[r'\b(?:how (?:do|to) (?:i )?play|rules|where is|in this app|in the app)\b'],
  topic='games ruling',
  text="""
Scholars have different views here, and it depends on the game.

- Gambling: any game played for money or a stake is gambling and forbidden ({QR 5:90}, and see the answer on gambling). That includes card games with stakes, and loot boxes or paid chances in video games that work like a lottery.
- Backgammon and dice games: the Prophet ﷺ condemned backgammon in strong words ({H muslim:2260|Buraida reported the Messenger of Allah said he who played Nardashir, a game similar to backgammon, is like one who dyed his hand with the flesh and blood of swine}). Many classical scholars apply this to games decided by dice, such as Ludo; others say the report is about backgammon and gambling and does not cover every dice game. Scholars differ on this.
- Chess: the schools differed. The Shafi'i school held it to be disliked rather than forbidden; the Hanafi, Maliki and Hanbali schools held it to be forbidden or strongly disliked, especially when it takes the place of prayer or is played for stakes. Many scholars today allow it as a mental exercise when there is no betting, it does not make you miss prayers or your duties, and it is not played to excess. Please follow the scholar you trust.
- Video games and other games: the game itself is generally allowed when its content is lawful (no immodesty, no gambling, no mockery of religion), and when it does not take you from prayer, family and work. Allah says that Satan wants to turn people from the remembrance of Allah and from prayer through intoxicants and gambling ({QR 5:91}), so watch the time you spend.

In this app, the games are made to teach and have no betting, coins, ratings or purchases.
""",
  go=['/games'],
  review='Games rulings: chess is described with the usual classical school split; dice games and video games are described as differences; flagged for scholar review.')
