# Marriage, family, parents, children. Abuse and hitting come first and are answered firmly.

E('abused-spouse',
  m=[r'\bmy (?:husband|wife|spouse|partner|father|dad|mother|mom|brother|in laws?|fiance\w*|boyfriend|girlfriend) (?:hits|beats|beat|hit|slaps|slapped|abuses|abused|hurts|hurt|is (?:violent|abusive)|threatens|chokes|punches)\b',
     r'\b(?:i am|i m|im) (?:being )?(?:abused|beaten|hit|hurt by my)\b', r'\babusive (?:marriage|husband|wife|home|relationship|parents?|father)\b',
     r'\b(?:afraid|scared|terrified) of my (?:husband|wife|father|dad|partner)\b', r'\b(?:husband|wife) (?:beats|hits|abuses) me\b', r'\bdomestic (?:violence|abuse)\b.*\b(?:me|my|i)\b', r'\bi (?:am|m) a victim of (?:domestic|abuse)\b'],
  topic='abuse',
  text="""
I am sorry. What is happening to you is not your fault, and Islam does not ask you to bear violence.

First, your safety: if you are in danger right now, go to a safe place and call your local emergency number. Tell someone you trust (a relative, a friend, a doctor), and keep a record of injuries and messages. A local domestic-violence service, which you can find through your doctor or an online search for your country, can help in secret.

Islam gives you rights: Allah commands living with a spouse "in kindness" ({QR 4:19}), the Prophet ﷺ never struck a woman or a servant with his hand ({H muslim:2328|A'isha reported that the Prophet never beat anyone with his hand, neither a woman nor a servant, except when fighting in the cause of Allah}), and when a husband broke his wife's arm, the Prophet ﷺ ordered that she be set free from him ({H nasai:3497|Thabit ibn Qais hit his wife and broke her arm, and the Prophet sent for him and told him to take what she owed him and let her go}). A wife can ask for separation by khul' or through a court, and a girl or woman does not need to stay with someone who harms her.

An imam or scholar can support you, but you do not have to ask permission to protect yourself, and you should not be asked to keep quiet. If you want, you can also ask me about khul' and divorce in general.
""",
  review='Khul and court separation are described in general terms; nothing here is a legal ruling.')

E('hitting-wife',
  m=[r'\b(?:hit|hits|hitting|beat|beats|beating|slap|slaps|slapping|strike|striking|smack|spank|discipline|disciplining|punish|punishing|hurt|hurting)\b.*\b(?:wife|wives|women|woman|spouse|girlfriend)\b',
     r'\b(?:wife|wives|women|woman)\b.*\b(?:hit|hits|hitting|beat|beaten|beating|slap|strike|striking|struck)\b',
     r'\bhusband\b.*\b(?:allowed|permitted|right|permission)\b.*\b(?:hit|beat|strike|discipline)\b', r'\b4 ?:? ?34\b', r'\bnushuz\b', r'\bwife beating\b', r'\bbeat(?:ing)? (?:their|your|his|a) wi(?:fe|ves)\b', r'\bdomestic (?:violence|abuse)\b', r'\bmen are in charge of women\b'],
  x=[r'\b(?:my (?:husband|father|dad|brother|in laws?) (?:hits|beats))\b'],
  topic='wife',
  text="""
No. Hitting a wife in anger, to control her or to make her afraid, is wrong in Islam, and a man who does it is answerable to Allah for it. The Prophet ﷺ never did it. {HS muslim:2328|A'isha reported that the Prophet never beat anyone with his hand, neither a woman nor a servant, except when fighting in the cause of Allah}. He also said: {HS bukhari:5204|None of you should flog his wife as he flogs a slave and then have sexual intercourse with her in the last part of the day}.

The verse people quote is {Q 4:34|But those [wives] from whom you fear arrogance - [first] advise them; [then if they persist], forsake them in bed; and [finally], strike them. But if they obey you [once more], seek no means against them}. It is about a husband facing serious, persistent misconduct, it comes last after advice and separation in bed, and the scholars restrict it heavily:
- In his farewell sermon the Prophet ﷺ allowed only a beating that does not harm ({H tirmidhi:1163|In the farewell Hajj the Prophet told the people to be good to women, and if they commit clear misconduct, to abandon their beds and beat them with a beating that is not harmful}).
- Never on the face, and never insulting her ({H abudawud:2142|Mu'awiyah al-Qushayri asked what is the wife's right over her husband; the Prophet said to feed her when you eat, clothe her when you clothe yourself, not strike her on the face and not revile her}).
- Many scholars say that at most it is symbolic, such as a touch with a folded cloth or a siwak, that causes no pain, bruise or mark and no humiliation, and that leaving it is better. In today's world it should not be used, and any hurt or injury is a sin and a crime.
- When many women went to his family to complain about their husbands, he said those men are not the best of you ({H ibnmajah:1985|The Prophet said do not beat the female slaves of Allah, and later said that seventy women had come to the family of Muhammad complaining about their husbands, and that those men are not the best of you}).

The right course in a marital problem is to speak kindly, make peace, and, if needed, bring two fair relatives ({QR 4:35}). Allah describes marriage as {Q 30:21|He placed between you affection and mercy}, and {HS tirmidhi:1162|Abu Hurairah narrated the Prophet said the most complete of the believers in faith is the one with the best character, and the best of you are those who are best to your women}.

If you are being hit, or you are afraid for your safety, ask me about abuse and I will tell you what you can do.
""",
  review='The restriction of 4:34 to a symbolic act (siwak/folded cloth) is reported in classical tafsir attributed to some companions; the attribution was not text-checked here and is stated without a named source. Flagged for scholar review.')

E('nikah-basics',
  m=[r'\bnikah\b', r'\bnikkah\b', r'\bmahr\b', r'\bmehr\b', r'\bdowry\b', r'\bbridal gift\b', r'\bwali\b', r'\bguardian\b.*\b(?:marriage|marry|nikah)\b', r'\b(?:conditions|requirements|pillars) of (?:a )?(?:marriage|nikah)\b', r'\bhow (?:do|to|can) (?:i |we )?(?:get )?married\b', r'\bmarriage contract\b',
     r'\bforced marriage\b', r'\barranged marriage\b', r'\bmarry without (?:my )?(?:parents?|family|wali|father)\b', r'\bwalima\b', r'\bis (?:marriage|nikah) (?:compulsory|obligatory|fard|sunnah|required|mandatory)\b', r'\bwhy (?:should|do) (?:i|muslims?) (?:get )?marr(?:y|ied)\b', r'^marriage$', r'\bhow to marry\b', r'\bwhat is marriage\b', r'\bislamic wedding\b', r'\bengagement\b'],
  x=[r'\b(?:games?|story|prophet s marriage|marriages of the prophet)\b', r'\b(?:non muslim|christian|jewish|jew|hindu|buddhist|atheist)\b'],
  topic='marriage',
  go=['/huda/guide?id=huda-nikah', '/academy/family-life'],
  text="""
Marriage (nikah) is a sunnah the Prophet ﷺ encouraged, and he forbade giving up marriage for worship ({H ibnmajah:1849|Samurah reported the Messenger of Allah forbade celibacy}). It is a strong covenant: Allah calls it a solemn covenant ({QR 4:21}), and {Q 30:21|He placed between you affection and mercy}.

What makes a nikah valid (the schools differ in detail):
- Consent of both. A woman must not be married against her will: {HS bukhari:5136|The Prophet said a matron should not be given in marriage without consulting her, and a virgin not without her permission, which is her silence}. A forced marriage is wrong.
- A guardian (wali) for the woman: {HS tirmidhi:1101|Abu Musa narrated the Messenger of Allah said there is no marriage except with a wali}. The Hanafi school allows a mature woman to contract her own marriage with the same conditions of suitability; the other schools require the wali.
- Mahr (bridal gift) given to the wife, which belongs to her: {Q 4:4|And give the women [upon marriage] their [bridal] gifts graciously}. Its amount is by agreement and does not have to be large.
- Two witnesses and an open announcement (as most scholars require), and an offer and acceptance in clear words. A feast (walima) follows.

Seek a person of faith and character; the Prophet ﷺ said that a woman is married for wealth, family, beauty and religion, so choose the one with religion ({H bukhari:5090|The Prophet said a woman is married for four things: her wealth, her family status, her beauty and her religion, so marry the religious one}).

A couple living together without a valid nikah is not married, whatever the civil paper says, and a nikah without registration may be a problem for your rights in your country, so many scholars advise doing both.
""",
  review='The detail of conditions (witnesses, wali, Hanafi view on a woman contracting herself) varies by school; described in general terms. Flagged for scholar review.')

E('divorce-overview',
  m=[r'\bdivorce\b', r'\btalaq\b', r'\btalaaq\b', r'\bkhula\w*\b', r'\biddah\b', r'\biddat\b', r'\bwaiting period\b.*\b(?:divorce|widow)\b', r'\bseparat\w*\b.*\b(?:husband|wife|marriage)\b', r'\bwhat is islam s view on divorce\b'],
  gate=False,
  topic='divorce',
  text="""
Divorce is allowed in Islam as a last resort, but it is the most disliked of the permitted things in the view of Allah: this is reported in a hadith, which some scholars grade weak, so I do not rely on it. What is firmly established is the Qur'an's guidance: {Q 2:229|Divorce is twice. Then, either keep [her] in an acceptable manner or release [her] with good treatment}, and {Q 65:2|retain them according to acceptable terms or part with them according to acceptable terms}.

How it works, in outline:
- Before divorce, try to settle: speak, bring a fair relative from each side ({QR 4:35}), or make a settlement ({QR 4:128}).
- Talaq is pronounced by the husband. The wife waits a set period (iddah) so that they may reconcile, and he must not turn her out of the house during it ({QR 65:1}).
- The wife can also seek separation: khul' (she returns the dower and is released), as the Prophet ﷺ did in the case of Thabit ibn Qais's wife ({H bukhari:5273|The wife of Thabit ibn Qais said she did not blame him for his character or religion but disliked behaving in an un-Islamic manner if she stayed with him, and the Prophet asked her to give back the garden and told Thabit to accept it}), or through a court.
- A wife should not ask for divorce without a good reason: {HS abudawud:2226|Thawban reported the Prophet said if any woman asks her husband for divorce without a strong reason, the odour of Paradise will be forbidden to her}.
- Children and money matters: the rights of the wife and children stay, including maintenance and kind treatment.

The details are where the schools and the laws of each country differ, in particular on repeated or written talaq, so I cannot say whether a divorce has taken place in your case. Please ask a qualified scholar or Islamic court with the exact words and circumstances.
""",
  review='Hadith on divorce being most hated is mentioned as disputed in grade and not relied on. The outline of talaq/khul/iddah is general; case details to scholars.')

E('interfaith-marriage',
  m=[r'\b(?:marry|marrying|marriage|married|wed|date|dating)\b.*\b(?:non muslim|christian|jewish|jew|hindu|buddhist|sikh|atheist|kafir|disbeliever|people of the book|ahl al kitab)\b',
     r'\b(?:non muslim|christian|jewish|jew|hindu|buddhist|sikh|atheist|kafir|disbeliever)\b.*\b(?:marry|marrying|marriage|husband|wife|spouse)\b', r'\binterfaith\b', r'\binter faith\b', r'\bmixed marriage\b', r'\bmarry outside (?:islam|the faith)\b'],
  topic='interfaith',
  text="""
The rulings differ for a man and a woman:
- A Muslim woman may not marry a non-Muslim man. This is agreed among scholars, based on {QR 2:221} and {Q 60:10|they are not lawful [wives] for them, nor are they lawful [husbands] for them}. He may marry her if he accepts Islam.
- A Muslim man may marry a chaste woman from the People of the Book (Jews and Christians): {Q 5:5|And [lawful in marriage are] chaste women from among the believers and chaste women from among those who were given the Scripture before you, when you have given them their due compensation}. Most scholars allow it, with the warning that the children should be raised on Islam and that it is preferable to marry a Muslim. Some modern scholars discourage it where it harms the family's faith. Marriage with a woman who follows no scripture (an atheist, or most other religions) is not allowed until she becomes Muslim; scholars differ on some groups.

Allah also said: {Q 2:221|And do not marry polytheistic women until they believe}. Practical advice: raise this early, and ask a scholar who knows your law and circumstances.
""",
  review='Interfaith marriage rules: the general majority position is described; groups outside the People of the Book vary. Flagged for scholar review.')

E('dating-relationships',
  m=[r'\bboy ?friends?\b', r'\bgirl ?friends?\b', r'\bdating\b', r'\bdate (?:a|someone|my|him|her)\b', r'\bpre ?marital\b', r'\bpremarital\b', r'\bcourtship\b', r'\b(?:talk|text|chat|speak|message|go out)\w* (?:to|with) (?:a )?(?:girl|girls|boy|boys|guy|guys|opposite gender|opposite sex|non mahram|him|her)\b',
     r'\bhalal (?:dating|relationship|courtship)\b', r'\bharam relationship\b', r'\b(?:kiss|kissing|hug|hugging|touch|touching|holding hands)\b.*\b(?:before marriage|boyfriend|girlfriend|haram)\b', r'\bzina\b', r'\bfornication\b', r'\bsex before marriage\b', r'\bpre ?marital sex\b',
     r'\bhave (?:a )?crush\b', r'\bin love with\b', r'\bfalling in love\b', r'\bwant to get married but\b', r'\bhow to find (?:a )?(?:spouse|husband|wife)\b', r'\bfind (?:a )?(?:spouse|husband|wife|partner)\b'],
  x=[r'\b(?:non muslim|christian|jewish|hindu)\b', r'\b(?:guilt\w*|ashamed|regret\w*|heartbroken|broke up|breakup|cheated|cry\w*|depress\w*|lonely|i feel)\b'],
  topic='dating',
  text="""
I am not assuming anything about you, and this is only the general guidance. Islam does not allow a private romantic relationship (boyfriend or girlfriend) outside marriage, but it does give a clean path to love and companionship, which is marriage.

What the texts say: Islam closes the doors that lead to wrongdoing, so private meetings, flirting and physical contact outside marriage are avoided. Men and women are told to lower their gaze and guard themselves ({QR 24:30}). The Prophet ﷺ also said: {HS bukhari:3006|It is not permissible for a man to be alone with a woman}.

What is allowed: meeting a possible spouse with a family member present, asking about each other's religion and character, speaking about marriage openly, and then proceeding quickly to engagement and nikah. Many Muslim couples meet through family, community, mosque events or trusted marriage services. Love in marriage is a sign of Allah: {Q 30:21|He placed between you affection and mercy}.

If you have already crossed the line, or have a relationship now, do not despair. Stop what is forbidden, turn to Allah in repentance, and if you wish to be together, ask for her or his hand through the family. Allah says: {Q 39:53|do not despair of the mercy of Allah}. If you want, I can say more about repentance or about finding a spouse.
""",
  go=['/huda/guide?id=huda-nikah', '/academy/family-life'],
  review='Dating and chaperoned meetings: standard views; not text-checked beyond the cited texts.')

E('polygamy',
  m=[r'\bpolygam\w*\b', r'\bpolygyn\w*\b', r'\b(?:four|4|two|second|more than one) wi(?:fe|ves)\b', r'\bmarry (?:two|three|four|more than one)\b', r'\bwhy can (?:a )?(?:muslim )?(?:man|men) (?:have|marry) (?:more|four|multiple)\b', r'\bsecond marriage\b', r'\bsecond wife\b'],
  topic='polygamy',
  text="""
Islam permits a man to marry up to four wives, with a strict condition of justice. The Qur'an says: {Q 4:3|marry those that please you of [other] women, two or three or four. But if you fear that you will not be just, then [marry only] one}. And it also says that perfect equality in feeling is beyond people ({QR 4:129}), so what is required is fairness in what he can control: housing, maintenance, time and treatment. Not being able to be just means he should marry only one.

It is a permission, not a duty or a recommendation for everyone, and many Muslims never practise it. Cruelty or neglect of a wife is a sin, and a woman can set a condition in her marriage contract that her husband will not take a second wife, which many scholars accept. The law of the country you live in also applies, and in many countries a second marriage needs to be registered or is not allowed.

Scholars differ on whether the first wife's consent is needed; a husband should, at minimum, be honest with her and fair.
""",
  review='Whether the first wife\'s consent is required is described as a difference; the stipulation that a contract may bar a second marriage is the view of some schools, not text-checked.')

E('spouse-rights',
  m=[r'\b(?:rights|duties|responsibilit\w*|obligations?) of (?:a |the )?(?:husband|wife|spouse|husbands|wives)\b', r'\b(?:husband|wife) (?:and|or) (?:wife|husband)\b.*\b(?:rights|duties)\b', r'\bwhat (?:does|do) (?:a )?(?:husband|wife) (?:owe|have to)\b',
     r'\bhow (?:to|can i|do i) be (?:a )?(?:good|better) (?:husband|wife|spouse)\b', r'\bgood (?:husband|wife)\b', r'\bmarriage (?:advice|problems?|tips)\b', r'\b(?:fight|fighting|argue|arguing|quarrel\w*) with (?:my )?(?:husband|wife|spouse)\b', r'\bmy (?:husband|wife) (?:and i|doesn t|does not|won t|will not|is not|ignores)\b', r'\bmaintenance\b.*\b(?:wife|husband)\b'],
  x=[r'\b(?:hits?|beats?|abus\w*|afraid|scared)\b'],
  topic='marriage',
  text="""
Marriage in Islam is a partnership with rights on both sides; the duties are not on one side only. Allah says {Q 2:228|And due to the wives is similar to what is expected of them, according to what is reasonable}, and calls the couple a source of {Q 30:21|affection and mercy}.

For the husband: to provide for his family, to treat his wife well and live with her in kindness ({QR 4:19}). {HS tirmidhi:1162|Abu Hurairah narrated the Prophet said the most complete of the believers in faith is the one with the best character, and the best of you are those who are best to your women}. And: {HS ibnmajah:1977|The best of you is the one who is best to his wife, and I am the best of you to my wives}.

For the wife: to keep the trust of the marriage, to protect the home and herself in his absence, and, as the scholars explain, to cooperate with her husband in what is right ({QR 4:34} describes righteous women as {Q 4:34|devoutly obedient, guarding in [the husband's] absence what Allah would have them guard}). Both should be honest and loyal to each other.

If you disagree, speak calmly, forgive the small things ({QR 4:19} says perhaps you dislike a thing and Allah makes therein much good), and ask family or a counsellor to help you, as in {QR 4:35}. {HS muslim:1468|Abu Huraira reported the Prophet said act kindly towards women, and a believing man should not hate a believing woman: if he dislikes one of her characteristics, he will be pleased with another}.
""",
  go=['/huda/guide?id=huda-nikah'],
  review='Description of the wife\'s duties follows the classical summary; the detail is a matter of fiqh and culture. Flagged for scholar review.')

E('parents',
  m=[r'\bparents?\b', r'\bmother\b', r'\bmom\b', r'\bmum\b', r'\bfather\b', r'\bdad\b', r'\bobey (?:my )?(?:parents|mother|father)\b', r'\bdisobey\w*\b.*\b(?:parents|mother|father)\b', r'\brespect(?:ing)? (?:my )?(?:parents|mother|father|elders)\b', r'\bnursing home\b', r'\bold age home\b', r'\bcare for (?:my )?(?:old|elderly|aging)\b',
     r'\bparents? (?:are|aren t|is) (?:non muslim|not muslim|divorced|angry|upset|unhappy)\b', r'\bparents? (?:don t|do not|won t|will not) (?:let|allow|accept|support|approve)\b', r'\bparents? (?:want|force|forcing)\b', r'\bbirr\b', r'\bwalidain\b', r'\bparent\w* (?:rights?|status|rank)\b', r'\bparadise.*\bmothers?\b', r'\bmothers? s? ?feet\b'],
  x=[r'\b(?:prophet s (?:mother|father|parents)|aminah|abdullah)\b', r'\b(?:game|story|stories)\b', r'\bin law\b', r'\b(?:fasting|zakat)\b', r'\b(?:dua|duas|supplication|supplications|du a)\b', r'\b(?:died|passed away|funeral|janazah)\b'],
  topic='parents',
  text="""
Honouring parents is one of the greatest duties in Islam, second only to worship of Allah in the Qur'an: {Q 17:23|your Lord has decreed that you not worship except Him, and to parents, good treatment. Whether one or both of them reach old age [while] with you, say not to them [so much as], "uff," and do not repel them but speak to them a noble word}. {QR 31:14} reminds that the mother carried the child in weakness upon weakness.

Mother first, then father. {HS bukhari:5971|A man asked the Prophet who is more entitled to the best companionship, and he said your mother three times and then your father}. Staying with a mother who needs you can come before even going out to fight. {HS nasai:3104|Jahimah asked to go out and fight and the Prophet asked if he had a mother, and told him to stay with her, for Paradise is beneath her feet}. The Prophet ﷺ also said that a person who finds his parents in old age and does not enter Paradise because of them is humbled ({H muslim:2551|Abu Huraira reported the Prophet said let him be humbled into dust, he who sees his parents in old age but does not enter Paradise}).

Limits: obedience is for what is good and lawful. If they order a sin, you do not obey, but you stay kind: {Q 31:15|do not obey them but accompany them in [this] world with appropriate kindness}. That holds even for parents who are not Muslim. {HS bukhari:7257|The Prophet said no obedience for evil deeds, obedience is required only in what is good}.

In practice: visit, call, serve them, make du'a for them, and care for them in old age at home where you can; if you truly cannot, a good nursing arrangement with frequent visits is a last resort, not a first choice. If a parent is hard on you, patience and gentle words remain your duty, while you protect yourself from real harm. Ask me about a specific situation if you wish.
""",
  go=['/huda/guide?id=huda-parents'],
  review='Nursing-home remarks are practical guidance, not a text ruling; flagged for scholar review.')

E('children-parenting',
  m=[r'\b(?:raise|raising|rais\w*|teach\w*|bring up|bringing up) (?:my |our |the )?(?:kids?|children|child|son|daughter|boy|girl|teen\w*)\b', r'\bparenting\b', r'\b(?:kids?|children|child|son|daughter)\b.*\b(?:pray|prayer|salah|quran|fast|hijab|islam)\b', r'\bwhen (?:should|do|does) (?:a )?(?:kids?|child|children|boy|girl)\b.*\b(?:pray|start|fast|hijab|wear)\b',
     r'\bchildren s rights\b', r'\brights of (?:the )?(?:child|children|kids)\b', r'\bdiscipline (?:my )?(?:kids?|children|child)\b', r'\bhit(?:ting)? (?:my |a )?(?:kids?|children|child)\b', r'\bbeat(?:ing)? (?:my |a )?(?:kids?|children|child)\b', r'\bspank\w* (?:my |a )?(?:kids?|children|child)\b', r'\bat what age\b.*\b(?:pray|fast|hijab)\b'],
  x=[r'\b(?:app|screen|kids mode|kids section|kids zone|child mode|game|games)\b'],
  topic='children',
  text="""
Children are a trust. Allah says: {Q 66:6|O you who have believed, protect yourselves and your families from a Fire}, and the Prophet ﷺ showed mercy to children, saying {HS bukhari:5997|Whoever is not merciful to others will not be treated mercifully}.

Worship: parents are told to teach it gradually. {HS abudawud:494|The Prophet said command a boy to pray when he reaches the age of seven years, and when he becomes ten, beat him for prayer}. Scholars explain the beating as only a light, non-injurious reminder, if at all, and most advise gentleness, patience and example instead. Fasting and hijab are not obligatory until puberty; families begin training earlier in a gentle way, with encouragement and no pressure that harms the child.

Fairness: do not favour one child over another in gifts. The Prophet ﷺ asked a man whether he had given the like of the gift to each of his sons ({H bukhari:2587|An-Nu'man ibn Bashir said his father gave him a gift, and the Prophet asked whether he had given the like of it to every one of his sons}). Never kill or harm children from fear of poverty: {Q 17:31|do not kill your children for fear of poverty. We provide for them and for you}.

Hitting a child as a punishment in anger, or in a way that hurts or leaves a mark, is not from the guidance of the Prophet ﷺ. Teach by love, example, du'a and patience. The For Children section of this app is made for children to learn in a safe way.
""",
  go=['/huda/guide?id=huda-children-deen'],
  review='Scholars on discipline of children: described as gentle and non-injurious; the exact allowances vary. Flagged for scholar review.')
