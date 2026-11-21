# Knowledge pack H (21 Nov 2026): prophetic remedies, siwak, zakat al-fitr, time and health,
# conduct hadith. Hadith read against the corpus by build.py. Medical items carry a not-medical-advice line.

E('black-seed-healing',
  m=[r'\b(?:black seed|black cumin|nigella|habbat(?:ul|ul-| al)? ?sauda|habbatus sauda|kalonji|habba tus sawda)\b'],
  topic='black seed',
  go=['/hadith'],
  text="""
Abu Hurayrah reported the Prophet ﷺ saying: {HS bukhari:5688|there is healing in black cumin for all diseases except death}.

Many Muslims take it as seeds or oil. This is a blessing and a sunnah, and it does not replace seeing a doctor and taking the treatment you are given.
""",
  review='Scholar review needed: the second paragraph is a general caution, not a ruling; check wording before approval.')

E('honey-healing',
  m=[r'\b(?:honey|asal)\b.*\b(?:heal\w*|cure|medicine|sunnah|islam|prophet|benefit\w*)\b', r'\b(?:heal\w*|cure|medicine) (?:in|of|from) honey\b', r'\bhoney in (?:islam|the quran|the sunnah)\b', r'\bis honey (?:a |the )?(?:cure|healing|medicine)\b'],
  topic='honey as healing',
  go=['/hadith'],
  text="""
Ibn 'Abbas reported the Prophet ﷺ saying: {HS bukhari:5680|healing is in three things: a gulp of honey, cupping, and branding with fire, but I forbid my followers to use branding with fire}.

The Qur'an also says of the bee that from its bellies comes a drink of varying colours, in which there is healing for people ({QR 16:68-69}).

Honey is a sunnah remedy, taken in moderation. It does not replace a doctor's advice, and it should not be given to babies under one year.
""",
  review='Scholar review needed: the advice on babies and moderation is added from general medical guidance, not from the hadith.')

E('ajwa-dates-morning',
  m=[r'\bajwa\b', r'\b(?:seven|7) dates\b', r'\bdates? (?:in the )?(?:morning|poison|magic|protect\w*)\b', r'\bbenefits? of (?:eating )?dates\b'],
  topic='Ajwa dates in the morning',
  go=['/hadith'],
  text="""
Sa'd ibn Abi Waqqas reported the Prophet ﷺ saying: {HS abudawud:3876|whoever has seven Ajwa dates for his morning meal will not be harmed that day by poison or magic}.

Ajwa dates are a kind of date grown around Madinah. Many Muslims keep this as a morning habit for the blessing in it.
""",
  review='Scholar review needed: the second paragraph is general background; confirm wording and the scholars\' discussion of poison and magic.')

E('health-and-free-time',
  m=[r'\b(?:two|2) (?:blessings?|favou?rs?|gifts?|ni mah|nimah)\b', r'\b(?:health|being healthy) and (?:free|spare|leisure) time\b', r'\bfree time (?:in|and) islam\b', r'\bhow (?:should|do) i (?:use|spend) (?:my )?(?:free|spare) time\b', r'\bvalue of time (?:in|and) islam\b'],
  topic='the blessings of health and free time',
  go=['/hadith'],
  text="""
Ibn 'Abbas reported the Prophet ﷺ saying: {HS bukhari:6412|there are two blessings that many people are deceived into losing: health and free time}.

They are easy to waste because they feel permanent. Use your good health and free hours for prayer, Qur'an, family and good work before they pass.
""",
  review='Scholar review needed: the second paragraph is a general reading of the hadith.')

E('best-muslim-tongue-hand',
  m=[r'\b(?:who|which|what) (?:is|are) (?:the )?(?:best|most virtuous|most excellent|true) muslims?\b', r'\bmuslims? (?:are )?safe from (?:his|her|their) (?:tongue|hand|hands)\b', r'\bwho is a (?:true|real|good|best) muslim\b', r'\bdefinition of a (?:true |real |good )?muslim\b', r'\bbest of muslims\b'],
  x=[r'\bquran\b', r'\bpray\w*\b'],
  topic='the best Muslim',
  go=['/hadith'],
  text="""
Abu Musa reported that the Prophet ﷺ was asked which of the Muslims is the most virtuous. {HS tirmidhi:2504|he said it is the one from whose tongue and hand the Muslims are safe}.

So excellence is measured by how safe people are from your words and your hands, as well as by your worship.
""",
  review='Scholar review needed: the second paragraph states the conclusion drawn by scholars.')

E('be-mindful-of-allah',
  m=[r'\bbe mindful of allah\b', r'\bpreserve allah\b.*\bpreserve you\b', r'\bwhen you ask,? ask allah\b', r'\bhadith (?:of )?(?:ibn abbas|ibn abbas) (?:about )?(?:protection|the pens)\b', r'\bpens (?:are|have been) lifted\b', r'\bpages (?:are|have) dried\b'],
  topic='"Be mindful of Allah and He will protect you"',
  go=['/hadith'],
  text="""
Ibn 'Abbas was behind the Prophet ﷺ one day when he said: {HS tirmidhi:2516|be mindful of Allah and He will protect you; be mindful of Allah and you will find Him before you; when you ask, ask Allah, and when you seek aid, seek Allah's aid; if the whole creation gathered to benefit you, you would get nothing except what Allah has written for you, and if they gathered to harm you, they could harm you only with what Allah has written; the pens are lifted and the pages are dried}.

It teaches reliance on Allah alone and acceptance of His decree, together with taking the means.
""",
  review='Scholar review needed: the last sentence is the usual reading of the hadith, not cited; the summary is shorter than the full narration.')

E('believer-is-mirror',
  m=[r'\bbeliever is (?:the )?(?:believers? )?mirror\b', r'\b(?:believer|muslim) (?:is )?(?:a |the )?mirror of (?:his|the) (?:brother|believer|muslim)\b', r'\bmirror (?:of|to) (?:his|your) (?:brother|believer|muslim)\b', r'\bhow (?:do|should) i advise (?:my )?(?:brother|sister|friend)\b'],
  topic='the believer is the mirror of the believer',
  go=['/hadith'],
  text="""
Abu Hurayrah reported the Prophet ﷺ saying: {HS abudawud:4918|the believer is the believer's mirror, and the believer is the believer's brother who guards him against loss and protects him when he is absent}.

A mirror shows you a flaw without shouting it to others. So advise in private, with care, and look after your brother when he is not there.
""",
  review='Scholar review needed: the second paragraph is a general reading of the hadith.')

E('miswak-siwak',
  m=[r'\b(?:miswak|siwak|miswaak|sewak|tooth ?stick|toothstick)\b', r'\bbrush\w* (?:my )?teeth\b.*\b(?:sunnah|islam|prayer)\b', r'\bsunnah (?:of )?(?:brushing|cleaning) (?:the |my )?teeth\b'],
  topic='the miswak',
  go=['/huda'],
  text="""
Abu Hurayrah reported the Prophet ﷺ saying: {HS bukhari:887|if it had not been hard for my followers, I would have ordered them to clean their teeth with the siwak for every prayer}.

So using the miswak before prayer and wudu is a strong sunnah. A toothbrush also serves the purpose of cleaning the mouth, and the miswak gives the reward of the sunnah if you intend it.
""",
  review='Scholar review needed: the last sentence on the toothbrush is the scholars\' general view and carries no source here.')

E('zakat-fitr-amount',
  m=[r'\b(?:zakat|zakah|sadaqah|sadaqat) (?:ul |al |-)?fitr\b', r'\bfitra\b', r'\bfitrana\b', r'\bhow much (?:is|do i pay for|is the) (?:zakat|sadaqah) (?:ul |al )?fitr\b', r'\bwhen (?:do i|should i|to) pay (?:zakat|sadaqah) (?:ul |al )?fitr\b'],
  x=[r'\bwhat is zakat\b'],
  topic='Zakat al-Fitr',
  go=['/ramadan'],
  text="""
Ibn 'Umar reported: {HS bukhari:1503|the Prophet ﷺ enjoined one sa' of dates or one sa' of barley as Zakat-ul-Fitr on every Muslim, slave or free, male or female, young or old, to be paid before the people went out to the 'Eid prayer}.

So it is due on each person, including children, and is paid before the 'Eid prayer, not after it. The amount today is worked out from the sa' of the staple food of the place, and many scholars allow its value in money; ask a trusted scholar or your masjid for the figure this year.
""",
  review='Scholar review needed: the second paragraph (money value, the amount today) is the scholars\' common view and differs by school; the amounts are not given here.')
