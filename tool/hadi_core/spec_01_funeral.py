# Funeral prayer and the care of the dead. The P0 of the Oct 2026 audit: "How
# do I pray janazah?" had been answered with the ordinary prayer outline.

E('janazah-prayer',
  m=[r'\bjanazah\b', r'\bfuneral\b', r'\bprayer (?:for|over) (?:the |a )?(?:dead|deceased)\b',
     r'\b(?:dead|deceased) (?:body|person|muslim)\b.*\bprayer\b'],
  x=[r'\b(?:wash\w*|bath\w*|bury\w*|burial|shroud\w*|kafan|coffin|grave\w*|cemeter\w*|condolence\w*|console\w*|mourn\w*|grief|grieving|cry\w*|wail\w*|hurt\w*|attend\w*|women|woman|ladies|late)\b',
     r'\b(?:story|stories|game|chess|app|screen|ludo)\b'],
  topic='janazah',
  text="""
The funeral prayer (salat al-janazah) is prayed standing, with four takbirs. There is no ruku' (bowing) and no sujud (prostration), no adhan and no iqamah: the prayer is takbirs, recitation and du'a, then the salam. It is a communal duty (fard kifayah): when enough Muslims pray it, the rest are relieved.

Before you begin: be in wudu and face the qibla. The body lies in front of the imam and the people stand behind him in rows. The Prophet ﷺ stood level with the middle of a woman's body when he prayed over her ({H bukhari:1331|Samurah ibn Jundab prayed behind the Prophet over a woman who had died in childbirth; he stood by the middle of the bier}); where the imam stands for a man differs between the schools.

The steps:
1. Make the intention in your heart, then say the first takbir, "Allahu Akbar".
2. After the first takbir: the Shafi'i and Hanbali schools recite al-Fatihah here, and Ibn Abbas did and said it is the Sunnah ({H bukhari:1335|Talhah prayed a funeral prayer behind Ibn Abbas, who recited al-Fatihah and said it is the Prophet's tradition}). The Hanafi school recites the opening praise (thana') instead.
3. Second takbir, then send blessings on the Prophet ﷺ, as in the last sitting of every prayer.
4. Third takbir, then make du'a for the deceased and for the Muslims. The Prophet's du'a, as 'Awf ibn Malik remembered it, begins: Allahumma-ghfir lahu, warhamhu, wa 'afihi, wa'fu 'anhu. In meaning: O Allah, forgive him, have mercy on him, give him peace and pardon him, honour his resting place and make it wide, wash him clean of his faults, give him a better home and family, admit him to Paradise and protect him from the trial of the grave and the Fire ({H muslim:963|'Awf ibn Malik remembered the Prophet's du'a over a dead man: forgive him, have mercy on him, make his grave wide, wash him with water, snow and hail, admit him to Paradise and protect him from the torment of the grave and the Fire}).
5. Fourth takbir. The Hanafi school then pauses briefly and gives the salam; the Shafi'i and Hanbali schools make a short du'a first.
6. Give the salam to the right (many scholars also to the left).

Four takbirs is what the Prophet ﷺ said when he prayed over the Negus ({H bukhari:1245|The Prophet told the people of the Negus's death on the day he died, lined them up at the prayer ground and said four takbirs}). One companion reported that the Prophet once said five ({H muslim:957|Zayd ibn Arqam usually said four takbirs over a funeral but once said five, and said the Prophet had done the same}); the schools follow four.

Recitation after each takbir differs between the schools, so follow your own school or ask your imam. These school details are the standard teaching of the schools and are waiting for scholar review.
""",
  go=['/huda/guide?id=huda-janazah-prayer'],
  review='Recitation after each takbir, the salam, and where the imam stands are school positions taken from standard fiqh teaching; not checked against the fiqh books here.')

E('janazah-care',
  m=[r'\b(?:wash\w*|bath\w*|shroud\w*|kafan|coffin)\b.*\b(?:dead|deceased|body|corpse|janazah)\b',
     r'\b(?:dead|deceased|body|corpse|janazah)\b.*\b(?:wash\w*|bath\w*|shroud\w*|kafan|coffin|bury\w*|burial)\b',
     r'\bburial\b', r'\bhow (?:to|do (?:we|you|i)|are) (?:bury|buried)\b', r'\bghusl (?:of )?(?:the )?(?:mayyit|dead|deceased)\b',
     r'\bwhat happens (?:to|when) (?:a )?(?:muslim|someone|person) (?:dies|die)\b'],
  topic='janazah',
  text="""
When a Muslim dies, the community owes them three things: washing, shrouding with a funeral prayer, and burial, done without delay.

Washing: the body is washed with water, in an odd number of washes (three, five or more), starting with the right side and the parts of wudu, and camphor goes in the last wash ({H bukhari:1253|The Prophet told the women washing his daughter to wash her three or five times or more with water and lotus leaves, adding camphor at the end}). Men wash men and women wash women; a husband and wife may wash each other according to the schools.

Shrouding: the Prophet himself was wrapped in three plain white cotton sheets, with no shirt and no turban ({H bukhari:1264|The Prophet was shrouded in three white Yemeni cotton sheets, without a shirt or a turban}). Then the funeral prayer is prayed.

Burial: the Prophet said to hurry with the funeral ({H bukhari:1315|The Prophet told people to hurry with the dead body: if the person was righteous it is forwarding them to good, otherwise it is putting an evil off their necks}). The body is laid in the grave on its right side facing the qibla.

For the details of washing, shrouding and burying, the Huda guides in this app go step by step. Where your school differs, ask your imam.
""",
  go=['/huda/guide?id=huda-janazah-wash', '/huda/guide?id=huda-janazah-burial'],
  review='Right-side/qibla burial and the husband-wife washing rule are standard fiqh teaching, not text-checked here.')
