# Purity: wudu, ghusl, tayammum, impurity, and the rules around menstruation.

E('touch-quran-wudu',
  m=[r'\b(?:touch|touching|hold|holding|carry|carrying|read|reading|recite|reciting|open|opening)\b.*\b(?:quran|mushaf)\b.*\b(?:without|with no|wudu|ablution|impure|janabah|period|menstruat\w*|unclean)\b',
     r'\b(?:quran|mushaf)\b.*\b(?:without wudu|without ablution|not in wudu|without being pure|while impure|in janabah)\b',
     r'\bwudu\b.*\b(?:touch|hold|read|recite|carry)\w*\b.*\b(?:quran|mushaf)\b', r'\b(?:quran|mushaf)\b.*\bwudu\b',
     r'\b(?:quran|mushaf)\b.*\b(?:phone|screen|app|tablet|digital|ebook|online)\b.*\b(?:wudu|touch|impure|bathroom|toilet)\b',
     r'\b(?:phone|screen|app|tablet|digital)\b.*\bquran\b.*\b(?:wudu|touch|bathroom|toilet)\b', r'\bquran\b.*\b(?:bathroom|toilet)\b'],
  topic='quran touching',
  text="""
Touching the physical copy of the Qur'an (the mushaf):
- Most scholars, including the four schools, say you should be in wudu to touch or carry the written Qur'an, based on {Q 56:77-79|None touch it except the purified}. Many explain this verse as being about the angels in the heavenly record, and use other reports to support the ruling.
- A minority of scholars say it is not required, as there is no clear text; many modern scholars take the cautious view and say wudu is best.
- A person in janabah (and, in most views, a woman in her period) should not touch a mushaf directly. They may hold it with a cloth, or use a translation or a phone.

Reciting the Qur'an without wudu (from memory or from a screen) is allowed. A person in janabah or a menstruating woman is a school matter: the Hanafi, Shafi'i and Hanbali schools restrict reciting; the Maliki school allows a menstruating woman to recite, and so do some other scholars, since the report quoted for the ban is graded weak ({HW tirmidhi:131|The Prophet is reported to have said the menstruating woman and the one in janabah do not recite anything of the Qur'an}).

On a phone, tablet or computer: most contemporary scholars say a screen showing the Qur'an is not treated like a printed mushaf, so you may touch the device without wudu, but you should still treat it with respect and not take it into the toilet if you can avoid it. This is the common view, and some are stricter.

When in doubt, make wudu first; it costs little and it is the way of respect.
""",
  go=['/quran'],
  review='Touching the mushaf, janabah and screens are fiqh positions taken from standard teaching, not text-checked here.')

E('wudu-barriers',
  m=[r'\bnail ?(?:polish|varnish|paint|lacquer)\b', r'\bmanicure\b', r'\bgel nails?\b', r'\bacrylic nails?\b', r'\b(?:make ?up|lipstick|foundation|sunscreen|sunblock|moisturi[sz]er|lotion|cream)\b.*\b(?:wudu|ghusl|prayer)\b',
     r'\b(?:wudu|ghusl)\b.*\b(?:make ?up|lipstick|foundation|sunscreen|sunblock|moisturi[sz]er|lotion|cream|henna|mehndi|tattoo|plaster|bandage|cast|sticker|glue|wax|paint)\b',
     r'\b(?:cast|plaster|bandage|splint|dressing)\b.*\b(?:wudu|ghusl|wipe)\b', r'\bhenna\b.*\b(?:wudu|prayer)\b', r'\bwater (?:reach|reaching|barrier)\b'],
  topic='wudu',
  text="""
Wudu and ghusl are valid only if water reaches the skin and hair it has to wash. Anything that forms a layer which water cannot pass through stops the wash from counting.

- Nail polish, gel or acrylic nails, wax, thick paint, glue, and waterproof makeup: they block the water, so remove them before wudu. Many women pray without polish for this reason, or use a breathable "wudu-friendly" polish that lets water through (some scholars accept it).
- Henna and dye: they stain but do not form a layer, so wudu is valid.
- Lotion and oil on the skin: valid as long as water still touches the skin.
- Plaster, bandage or a cast on a wound: wash the rest, and wipe wet hands over the cover (scholars allow this when removing it would harm you or delay healing). The Shafi'i school also asks for tayammum for the covered part.
- A tattoo under the skin: wudu is valid.
- Rings and watches: move them so water goes beneath, or take them off.

If you are not sure that water reached, wash again. Ask your imam for your own case.
""",
  go=['/huda/guide?id=huda-wudu'],
  review='Breathable polish, wiping over a cast and a bandage are positions of contemporary scholars and standard teaching, not text-checked here.')
E('wudu-fard',
  m=[r'\b(?:obligatory|fard|farz|essential|required|mandatory|compulsory|pillars?|rukn|arkan|minimum)\b.*\bwudu\b',
     r'\bwudu\b.*\b(?:obligatory|fard|farz|essential|required|mandatory|compulsory|pillars?|rukn|arkan|minimum)\b',
     r'\bconditions? of wudu\b', r'\bwhat is (?:needed|required) (?:for|in) wudu\b', r'\bfard acts? of wudu\b'],
  x=[r'\b(?:break|breaks|breaking|invalidat\w*|nullif\w*|cancel\w*)\b'],
  topic='wudu',
  text="""
The Qur'an names the obligatory acts of wudu: {Q 5:6|wash your faces and your forearms to the elbows and wipe over your heads and wash your feet to the ankles}. So four acts are agreed:
1. Wash the whole face (from the hairline to the chin, and ear to ear).
2. Wash both arms up to and including the elbows.
3. Wipe the head (the Hanafi school says about a quarter of it; the Shafi'i school says a few hairs; the Maliki and Hanbali schools say the whole head).
4. Wash both feet up to and including the ankles.

Some schools add more obligations. The Shafi'i, Maliki and Hanbali schools require the intention (niyyah) in the heart; the Hanafi school counts it as a sunnah. The Shafi'i and Hanbali schools also require doing the four acts in this order. The Maliki and Hanbali schools require doing them without a long break in between. Rinsing the mouth and nose is a sunnah in wudu in most views, though the Hanbali school makes it obligatory.

Everything else (bismillah, washing the hands first, rinsing, washing three times, the right side first, the siwak, the du'a after) is sunnah. Washing once is enough for the obligation.

To learn the full wudu step by step, see the Wudu guide.
""",
  go=['/huda/guide?id=huda-wudu'],
  review='The extra obligations by school (intention, order, continuity, how much of the head) are standard fiqh teaching, not text-checked here.')

E('wudu-howto',
  m=[r'\bhow (?:to|do (?:i|we|you)|can i|should i|is) (?:make|perform|do|take|done|made|performed|taken)\b.*\bwudu\b',
     r'\bsteps? (?:of|for|to|in) (?:making |doing |performing )?wudu\b', r'\bwudu steps?\b', r'\bmethod of wudu\b',
     r'\bwudu (?:step by step|for beginners|procedure|method|how)\b', r'\bwhat is wudu\b', r'\blearn wudu\b',
     r'\bteach me wudu\b', r'\bhow to wash for prayer\b', r'\bperform (?:the )?wudu\b', r'^wudu$', r'\bhow to do ablution\b'],
  x=[r'\b(?:break|breaks|invalidat\w*|nullif\w*|fard|obligatory|sleep|socks?|khuff|nail ?polish|no water|tayammum)\b'],
  topic='wudu',
  text="""
Wudu is the washing you do before prayer. Allah says: {Q 5:6|wash your faces and your forearms to the elbows and wipe over your heads and wash your feet to the ankles}. The Prophet ﷺ taught it by doing it, as 'Uthman showed it ({H bukhari:159|Uthman called for water, washed his hands three times, rinsed his mouth and nose, washed his face and arms to the elbows three times, wiped his head and washed his feet to the ankles three times, and said the Prophet taught that whoever does wudu like this and prays two rak'ahs with full attention is forgiven his earlier sins}).

The steps:
1. Make the intention in your heart and say "Bismillah".
2. Wash both hands up to the wrists, three times.
3. Rinse your mouth three times.
4. Sniff water into your nose and blow it out, three times.
5. Wash your face three times, from the hairline to the chin and ear to ear.
6. Wash your right arm to the elbow, then your left, three times each.
7. Wipe your head once with wet hands, from the front back to the nape and forward again; wipe the ears too.
8. Wash your right foot to the ankle, then your left, three times each, between the toes as well.
9. Say the shahadah and, if you like, the du'a after wudu.

The only obligatory parts are the face, the arms, the head and the feet. The rest are sunnah, but do them all if you can. Do not waste water. The Wudu guide in this app shows it step by step.
""",
  go=['/huda/guide?id=huda-wudu'],
  review='The wiping of the ears and the exact path of the head wipe are standard teaching, not text-checked here.')

E('wudu-breakers',
  m=[r'\b(?:break|breaks|breaking|broke|broken|invalidat\w*|nullif\w*|cancel\w*|void\w*|undo\w*|end|ends|ruin\w*)\b.*\bwudu\b',
     r'\bwudu\b.*\b(?:break|breaks|breaking|broke|broken|invalidat\w*|nullif\w*|cancel\w*|void\w*|again|valid|remain|still|stay|stays|last|lasts|renew)\b',
     r'\bdo i (?:need|have) to (?:redo|repeat|renew|make) wudu\b', r'\bneed (?:to )?(?:make|do|renew|redo) wudu (?:again|after)\b',
     r'\bwhat (?:cancels?|breaks?|invalidates?) (?:my |the )?(?:wudu|ablution)\b', r'\bis my wudu (?:valid|broken|still)\b',
     r'\b(?:sleep|sleeping|asleep|nap|dozed|dozing|fell asleep|drowsy)\b.*\bwudu\b', r'\bwudu\b.*\b(?:sleep|sleeping|asleep|nap|dozed|touch\w*|blood|bleed\w*|vomit\w*|laugh\w*|camel|private part|wind|gas|fart\w*|doubt\w*|unsure|not sure)\b',
     r'\btouch(?:ing)? (?:my |a |the )?(?:private part|genital|penis|woman|wife|husband|spouse)\b.*\b(?:wudu|prayer)\b',
     r'\b(?:wudu|ablution)\b.*\b(?:touch\w*)\b'],
  x=[r'\b(?:quran|mushaf)\b'],
  topic='wudu',
  why='These are the things that make a person need a fresh wudu, because they are a state of impurity from the body.',
  text="""
Wudu is broken by what leaves the body and by loss of consciousness. All schools agree on these:
- Urine, stool and wind (and the thin fluid called madhy). The Prophet ﷺ said the prayer of someone who has passed wind is not accepted until he makes wudu ({H bukhari:135|The Prophet said the prayer of one who passes wind or urine is not accepted until he does wudu}).
- Deep sleep, fainting, madness or intoxication, anything that takes away your awareness. Safwan ibn Assal reported that on a journey the Prophet ﷺ told them to keep their socks on for three days, except for janabah, but not for urine, stool or sleep, meaning these need a fresh wudu ({H tirmidhi:96|Safwan ibn Assal reported the Prophet told them on a journey not to remove their socks for three days and nights except for janabah, but not for defecating, urinating or sleep}).
- Janabah (emission, intercourse) needs a full ghusl, not only wudu.

Light dozing while sitting up, without losing awareness, does not break it. The Companions used to wait for the night prayer until they were nodding off, and then prayed without a new wudu ({H abudawud:200|Anas said the Companions used to wait for the night prayer until their heads dropped from dozing, then they prayed without making wudu}).

Sleeping lying down or leaning breaks it. The schools differ on whether it also breaks when you sleep sitting firmly on the ground.

The schools differ on these:
- Touching your private part with the hand: it breaks wudu in the Shafi'i and Hanbali schools (and in the Maliki school if with desire); not in the Hanafi school.
- Touching a woman's skin: it breaks wudu in the Shafi'i school; in the Maliki and Hanbali schools only if with desire; not in the Hanafi school.
- Flowing blood or a big vomit: it breaks wudu in the Hanafi school and, if a lot, in the Hanbali school; not in the Shafi'i and Maliki schools.
- Eating camel meat: it breaks wudu in the Hanbali school ({H muslim:360|A man asked the Prophet about wudu after mutton, and he said do it if you wish, and asked about camel meat and he said yes, do wudu}).

If you doubt whether you broke it, leave the doubt: your wudu stays. The Prophet ﷺ said that a man who imagines he has broken wind in prayer should not leave unless he hears a sound or smells something ({H bukhari:137|The Prophet said a man who imagined he had passed wind in prayer should not leave unless he hears a sound or smells something}).
""",
  go=['/huda/guide?id=huda-wudu'],
  review='The school-by-school differences on touching, blood, vomit and sleeping posture are standard fiqh teaching, not text-checked here.')

E('ghusl',
  m=[r'\bghusl\b', r'\bfull bath\b', r'\britual bath\b', r'\bbath after (?:sex|intercourse|period|menstrua\w*)\b',
     r'\bjanabah\b', r'\bjunub\b', r'\bwet dream\b', r'\bnocturnal emission\b', r'\bmajor (?:impurity|ablution)\b',
     r'\bpurif\w* after (?:sex|intercourse|marital)\b', r'\bwash after (?:sex|intercourse)\b', r'\bwhen is (?:a )?(?:bath|ghusl) (?:needed|required|obligatory)\b',
     r'\bhow to (?:take|do|perform) (?:a )?(?:full )?bath\b'],
  x=[r'\b(?:dead|deceased|body|corpse|janazah|funeral|mayyit)\b', r'\b(?:game|story)\b'],
  topic='ghusl',
  text="""
Ghusl is the full washing of the body that you must do after janabah (major impurity). Allah says: {Q 5:6|if you are in a state of janabah, then purify yourselves}, and {QR 4:43}.

When it is required:
- After sexual intercourse (even without emission).
- After an emission of semen, awake or in a dream. A woman who has a wet dream does ghusl if she sees a discharge ({H bukhari:282|Umm Sulaim asked if a woman needs a bath after a wet dream, and the Prophet said yes, if she notices a discharge}). If you wake up and see no wetness, ghusl is not required.
- When menstruation ends, and when postnatal bleeding (nifas) ends.

How to do it (the Prophet's way): {HS bukhari:248|Aisha described the Prophet's bath after janabah: he washed his hands, made wudu as for prayer, ran wet fingers through the roots of his hair, poured three handfuls of water on his head, and then poured water over the rest of his body}.
1. Intend in your heart and say "Bismillah".
2. Wash your hands and private parts, and remove any impurity from the body.
3. Make wudu as for prayer.
4. Pour water over your head three times, reaching the roots of the hair.
5. Pour water over your right side, then your left, so that water reaches the whole body, including the mouth, nose and under the nails.

The obligatory minimum: wash the whole body so that no spot, including the mouth and nose, stays dry, with the intention (the Hanafi school counts rinsing the mouth and nose as obligatory and the intention as a sunnah; the Shafi'i school requires the intention). A woman need not undo her braids if water reaches the roots of her hair.

A complete ghusl, with the mouth and nose rinsed, is enough to pray after: most scholars say it does the job of wudu too. The Prophet ﷺ's own practice, shown above, was to make wudu within it.
""",
  go=['/huda/guide?id=huda-ghusl'],
  review='Which acts are obligatory in ghusl per school, braids, and whether a single ghusl replaces wudu are standard fiqh teaching, not text-checked here.')

E('tayammum',
  m=[r'\btayammum\b', r'\bdry ablution\b', r'\bpurif\w* with (?:earth|dust|soil|sand)\b',
     r'\b(?:no|without|cannot find|cant find|lack of|run out of) water\b.*\b(?:pray|prayer|wudu|ghusl|purif\w*)\b',
     r'\b(?:pray|prayer|wudu)\b.*\b(?:no|without) water\b', r'\bwater is not available\b', r'\bcan i pray without wudu\b',
     r'\bwhen is it allowed to skip wudu\b', r'\bcannot use water\b', r'\bcant use water\b', r'\bwater harms\b'],
  topic='tayammum',
  text="""
Tayammum is the dry purification: using clean earth in place of wudu or ghusl when you cannot use water. Allah says: {Q 5:6|if you are ill or on a journey or one of you comes from the place of relieving himself or you have contacted women and do not find water, then seek clean earth and wipe over your faces and hands with it}.

When it is allowed:
- There is no water within reach, and you have looked for it (or it is clearly not there).
- Using water would harm you: an illness, a wound, or a danger that cold water would make it worse.
- The water you have is needed for drinking, for yourself or others.

How to do it: the Prophet ﷺ taught 'Ammar ibn Yasir to strike the earth with his palms, blow into them, and wipe the face and the hands with them ({H bukhari:338|Ammar told Umar that the Prophet said it would have been enough to strike the earth with his hands, blow in them, then wipe his face and hands}).
1. Intend and say "Bismillah".
2. Strike the clean earth (soil, sand, dust, or a clean stone with dust) once with both palms and blow off the excess.
3. Wipe your face with your hands, then wipe the backs of your hands.

The schools differ on the details: the Hanafi and Shafi'i schools say strike twice, wiping the face with the first and the arms to the elbows with the second. The Maliki school says two strikes too, with the hands to the wrists obligatory and to the elbows recommended. The Hanbali school, following the hadith above, says one strike and wipe the face and the hands to the wrists. Either way the tayammum takes the place of wudu or ghusl. It breaks like wudu does, and when water becomes available. The Prophet ﷺ said the earth has been made a place of prayer and a means of purification for his Ummah ({H bukhari:335|The Prophet said among five things given to him: the earth was made for him and his followers a place for prayer and a means of tayammum, so a person can pray wherever the time of prayer comes}).
""",
  go=['/huda/guide?id=huda-tayammum'],
  review='The one-strike versus two-strike and elbows versus wrists difference per school, and the list of situations, are standard fiqh teaching, not text-checked here.')

E('najasa',
  m=[r'\bnajasa\b', r'\btypes? of (?:impurity|impurities|najasa|filth)\b', r'\bimpurit(?:y|ies)\b', r'\bwhat (?:is|are) (?:najis|najasa|impure|unclean|filthy)\b',
     r'\bis (?:it|this|my) (?:najis|clean|pure|impure|najasa)\b', r'\bhow (?:to|do i) (?:clean|purify|remove) (?:najasa|impurity|urine|blood)\b',
     r'\bare (?:dogs?|cats?|pigs?|blood|semen|urine|vomit|alcohol|wine|saliva) (?:najis|impure|pure|clean|filthy)\b',
     r'\b(?:cat|dog)s?\b.*\b(?:impure|najasa|najis|clean|unclean)\b', r'\bwhat things are najis\b',
     r'\b(?:urine|blood|semen|madhy|mazi|wadi|vomit)\b.*\b(?:on|in) (?:my )?(?:clothes?|body|prayer|floor|mat)\b',
     r'\bclothes?\b.*\b(?:urine|blood|najis|impure)\b', r'\bmadhy\b', r'\bmazi\b', r'\bwadi\b'],
  topic='najasa',
  text="""
Najasa is physical impurity that must be removed from your body, clothes and place of prayer before you pray. It is different from the impurity of janabah or hadath, which wudu and ghusl remove.

Things that most scholars hold to be najis (impure):
- Urine and stool of humans, and the thin fluid madhy and thick fluid wadi (washing the private part and the clothes it touched).
- Flowing blood, and menstrual blood.
- Dead animals (not killed by proper slaughter), except fish and locusts, and the flesh of swine ({QR 5:3}).

The schools differ on:
- Semen: najis in the Hanafi and Maliki schools; pure in the Shafi'i and Hanbali schools (though wiped away as a courtesy).
- Alcohol: najis in most views, though some modern scholars say its impurity is spiritual, not physical.
- A dog: the Prophet ﷺ said that when a dog drinks from your vessel, wash it seven times ({H bukhari:172|The Prophet said if a dog drinks from a vessel of one of you he must wash it seven times}). The Shafi'i and Hanbali schools take the dog's saliva as najis and wash seven times; the Maliki school takes the dog as pure and the washing as a ruling of worship; the Hanafi school takes the saliva as najis but differs on the number of washes. Cats are not unclean: the Prophet ﷺ said of a cat that it is not unclean, it is one of those that go round among you ({H abudawud:75|Abu Qatadah let a cat drink from his wudu water and said the Prophet said it is not unclean, it is one of those that go round among you}).

How to remove it: wash with clean water until the colour, smell and taste of the najasa are gone. If something had been spilled in a masjid, the Prophet ﷺ told them to pour a bucket of water over it ({H bukhari:220|A Bedouin urinated in the mosque and the Prophet told them to leave him, then pour a bucket of water over the place, and said they were sent to make things easy}). A small amount that is hard to avoid is excused, within the limits each school sets.

If you are unsure whether something is najis, the default is that it is clean. Do not make yourself anxious over doubts.
""",
  go=['/huda'],
  review='The list of najasat, and the semen, alcohol and dog positions per school, are standard fiqh teaching, not text-checked here.')

E('menstruation',
  m=[r'\bmenstrua\w*\b', r'\bhaid\w*\b', r'\bhayd\b', r'\bmonthly (?:cycle|bleeding|course)\b', r'\bmenses\b', r'\bnifas\b',
     r'\bpostnatal bleeding\b', r'\bpostpartum bleeding\b', r'\bistihadah?\b', r'\bmenopause\b',
     r'^(?=.*\b(?:my|her|the|a|during|on|while|with|have|having|got|get|when|if)\b.{0,12}\bperiods?\b)(?=.*\b(?:pray\w*|fast\w*|ramadan|quran|masjid|hajj|umrah|tawaf|husband|wife|woman|women|girl|girls|intimacy|sex|bath|ghusl|clean|pure|impure|miss\w*|make up|touch|read|recite|enter|allowed|permissible|can|cant|cannot|should|must|do|does|ends?|stopp?ed?)\b)'],
  x=[r'\b(?:history|era|prophet s time|time of the|years|decade|century|grace period|waiting period|iddah|probation|trial period|notice period|free period|school period|class period)\b',
     r'\b(?:game|story|stories|app|screen)\b', r'\b(?:pill|pills|delay|postpone|medicine|tablet|injection)\b'],
  topic='period',
  text="""
Menstruation (haid) is a natural state, not a sin or a shame, and Allah has made special allowances in it.

While a woman has her period:
- She does not pray, and she does not make those prayers up afterwards. A woman asked A'ishah about it and she said, in the time of the Prophet ﷺ they were not ordered to make up the prayers they had missed ({H muslim:335|A'ishah said that in the time of the Prophet the women who had their courses were ordered to make up the fasts but not the prayers}).
- She does not fast, but she does make up the missed days of Ramadan later ({H bukhari:1951|The Prophet said a woman does not pray and does not fast when menstruating}).
- She does not do tawaf of the Kaaba.
- Intercourse is not allowed until she is clean and has bathed. Allah says: {Q 2:222|keep away from wives during menstruation. And do not approach them until they are pure}. Everything else with her husband is allowed in the schools' view.
- The Qur'an: most scholars say she should not touch the mushaf directly (use a cloth or a phone). Reciting it is a school matter: the Hanafi, Shafi'i and Hanbali schools restrict it, while the Maliki school and a number of other scholars allow it, especially for a student, a teacher or anyone who fears forgetting. The report usually quoted for the ban is graded weak ({HW tirmidhi:131|The Prophet is reported to have said the menstruating woman and the one in janabah do not recite anything of the Qur'an}). Dhikr, du'a and listening to the Qur'an are fine for everyone.
- Entering the masjid: the schools differ (the Hanafi, Maliki and Hanbali schools forbid it; the Shafi'i school allows passing through).

When the bleeding stops, she makes ghusl and resumes prayer and fasting. The usual length and how to count it differ by school; if the bleeding is irregular or continues beyond the usual days (istihadah, bleeding of illness), the woman is treated as pure: she makes wudu for each prayer and prays and fasts as normal. Postnatal bleeding (nifas) also stops prayer and fasting and lasts until it ends, up to about forty days in the view of most scholars.

For a particular case, ask a scholar or a trusted woman scholar; this is general information only.
""",
  go=['/huda/guide?id=huda-ghusl'],
  review='Quran touching, entering the masjid, istihadah and the nifas limit are school positions from standard fiqh teaching, not text-checked here.')


E('istinja',
  m=[r'\bistinja\b', r'\b(?:toilet|bathroom|lavatory|restroom|relieving myself|relieve myself|call of nature)\b.*\b(?:etiquette|manners|rules|how|clean|wash|islam|dua|sunnah|adab|qibla|hand)\b',
     r'\b(?:etiquette|manners|rules|adab|sunnah)\b.*\b(?:toilet|bathroom|lavatory|restroom|call of nature)\b', r'\bhow (?:to|do i) clean (?:myself )?after (?:the )?toilet\b',
     r'\bclean(?:ing)? (?:myself |yourself )?after (?:using )?(?:the )?(?:toilet|bathroom|urinat\w*|defecat\w*)\b', r'\btoilet paper\b', r'\bwater or (?:tissue|paper|toilet paper)\b',
     r'\bface (?:the )?qibla\b.*\b(?:toilet|urinat\w*|relie\w*)\b', r'\bwhich hand\b.*\b(?:toilet|clean|wash)\b', r'\bwhat (?:do|should) (?:i|we) (?:say|recite) (?:when|before) (?:entering|going to|going into) (?:the )?(?:toilet|bathroom|lavatory)\b',
     r'\burinat\w* (?:standing|while standing)\b', r'\b(?:pee|peeing) standing\b'],
  topic='toilet',
  text="""
Cleaning yourself after the toilet is called istinja, and it is a basic part of Islamic cleanliness. The manners that come down from the Prophet ﷺ:
- Clean yourself with water if it is available. The Prophet ﷺ's servant Anas used to bring a tumbler of water for this ({H bukhari:150|Anas said that when the Prophet went to relieve himself, he and another boy followed with a tumbler full of water}). Tissue, stones or similar are also enough, if used until clean and in an odd number.
- Use the left hand for cleaning, and do not touch your private part with the right hand ({H bukhari:153|The Prophet said that when anyone goes to the lavatory he should neither touch his penis nor clean his private parts with his right hand}).
- Do not face the qibla or turn your back on it in an open place when relieving yourself, and do not clean with fewer than three stones or with dung or bone ({H muslim:262|Salman said the Prophet forbade facing the qibla at the time of excretion or urination, cleaning with the right hand or with fewer than three pebbles, or with dung or bone}).
- The du'a on entering is "Bismillah, Allahumma inni a'udhu bika minal-khubuthi wal-khaba'ith" (O Allah, I seek refuge in You from the male and female devils) and on leaving "Ghufranaka". Enter with the left foot and leave with the right.
- Keep your body and clothes free of urine splashes; guard against drops afterwards. If you pass urine standing, make sure no spray touches you.

Wudu is needed afterwards for prayer, since urine and stool break wudu.
""",
  go=['/huda/guide?id=huda-wudu'],
  review='The entering du\'a and leaving words and the left foot/right foot order are standard teaching, not text-checked here (the hadith cited cover the water, hand and qibla points).')
