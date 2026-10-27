# Fasting and Ramadan. Specific "does X break the fast" questions come first.

_FAST = r'(?:fast\w*|ramadan|roza|saum|sawm|siyam)'

E('fast-teeth',
  m=[r'\b(?:brush\w*|toothpaste|tooth paste|toothbrush|mouthwash|miswak|siwak|siwaak|floss\w*|clean(?:ing)? (?:my |the )?teeth|rins\w* (?:my |the )?mouth|gargl\w*|dental|dentist)\b'],
  x=[r'\b(?:before prayer|every prayer|for prayer|wudu)\b(?!.*' + _FAST + r')', r'\b(?:game|story)\b'],
  topic='fasting',
  text="""
Yes, you may brush your teeth while fasting. It does not break the fast as long as you do not swallow the toothpaste or water. Use a little paste, spit it all out and rinse your mouth well. If some goes down by accident, the fast is still valid: the Qur'an says {Q 33:5|there is no blame upon you for that in which you have erred but [only for] what your hearts intended}.

The Prophet ﷺ greatly valued cleaning the teeth with the siwak: he said that if it were not hard on his followers he would order them to use it for every prayer ({H bukhari:887|The Prophet said that if it were not hard on his followers he would have ordered the siwak for every prayer}). The Shafi'i school dislikes using the siwak after midday while fasting, because of the smell of the fasting mouth, so if you follow it, brush before noon. Some scholars prefer to avoid strong-tasting paste in the day and brush at suhoor and after iftar; that is a matter of care, not a requirement.

The same is true in wudu: rinse your mouth and nose, but do not sniff water deep into your nose while fasting. The Prophet ﷺ said: snuff up water freely unless you are fasting ({H abudawud:2366|The Prophet told Laqit ibn Saburah to snuff water up freely unless he is fasting}).
""",
  go=['/huda/guide?id=huda-fasting'],
  review='The Shafi\'i dislike of siwak after midday is standard fiqh teaching, not text-checked here. The mouth/paste rule is the general view.')

E('fast-medicine',
  m=[r'\b(?:medicine|medication|medications|meds?|pill|pills|tablet|tablets|capsule|capsules|ibuprofen|paracetamol|acetaminophen|panadol|aspirin|antibiotic\w*|painkiller\w*|pain killer\w*|syrup|cough|insulin|diabetes|diabetic|blood pressure|prescription|drugs?)\b.*\b' + _FAST + r'\b',
     r'\b' + _FAST + r'\b.*\b(?:medicine|medication|medications|meds?|pill|pills|tablet|tablets|capsule|capsules|ibuprofen|paracetamol|acetaminophen|panadol|aspirin|antibiotic\w*|painkiller\w*|pain killer\w*|syrup|cough|insulin|diabetes|diabetic|blood pressure|prescription)\b',
     r'\b(?:take|taking|swallow\w*)\b.*\b(?:medicine|medication|pill|pills|tablet|tablets|ibuprofen|paracetamol)\b.*\b(?:while|during|when|if)\b.*\b' + _FAST + r'\b'],
  x=[r'\b(?:injection|inhaler|drops?|puffer|patch|suppository|nasal spray|spray)\b'],
  topic='fasting',
  text="""
Swallowed medicine such as a tablet, capsule or syrup breaks the fast, because it goes into the stomach by the mouth. This holds for ibuprofen, paracetamol, antibiotics and the like. I cannot tell you whether any medicine is right for you or safe to delay: for that, ask your doctor or pharmacist.

What the religion gives you is ease. Allah says: {Q 2:185|Allah intends for you ease and does not intend for you hardship}. If you are ill, and fasting would worsen it or you cannot go without the medicine, you may break the fast, take the medicine, and make up the days later: {Q 2:184|whoever among you is ill or on a journey [during them] - then an equal number of days [are to be made up]}. If your illness is long-term with no hope of recovering, you give a ransom of feeding a poor person for each day instead ({QR 2:184}).

Before you break a fast, see if you can plan the medicine for suhoor and after iftar. Ask your doctor about long-acting forms that cover the day, and ask a scholar if your case is unclear. A person whose doctor says they must not fast should not fast; it is not weakness in faith.
""",
  go=['/huda/guide?id=huda-fasting'],
  review='The fidyah for long-term illness and the general rule for oral medicine are standard fiqh teaching, not text-checked here.')

E('fast-injection-tests',
  m=[r'\b(?:injection\w*|inject\w*|vaccin\w*|jab|drip|iv|intravenous|blood test|blood tests|blood draw|donat\w* blood|give blood|cupping|insulin shot|anaesthe\w*|anesthe\w*|dialysis|catheter)\b.*\b' + _FAST + r'\b',
     r'\b' + _FAST + r'\b.*\b(?:injection\w*|vaccin\w*|jab|drip|intravenous|blood test|blood tests|blood draw|donat\w* blood|give blood|cupping|insulin shot|anaesthe\w*|anesthe\w*|dialysis|catheter|surgery)\b'],
  topic='fasting',
  text="""
Most contemporary scholars say these do not break the fast, as nothing is taken as food or drink by the mouth or throat: a blood test, giving blood, a vaccine, and a medical injection (such as insulin, an antibiotic or a painkiller). A drip that gives nourishment (glucose, a feeding drip) is treated like food and breaks the fast. Some scholars are stricter, so if you are unsure, plan these for after iftar.

Whatever your case, if the treatment is needed, your health comes first. The Qur'an allows the sick to break the fast and make up the days: {Q 2:185|Allah intends for you ease and does not intend for you hardship}. Ask your doctor for the timing and a scholar if your case is complicated.
""",
  go=['/huda/guide?id=huda-fasting'],
  review='Non-nutritional injections, blood tests and drips are the position of most contemporary fatwa bodies; not text-checked here.')

E('fast-drops-inhaler',
  m=[r'\b(?:eye ?drops?|ear ?drops?|nose ?drops?|nasal spray|nasal drops?|inhaler|inhalers|asthma|puffer|ventolin|nebuli[sz]er|oxygen|patch|suppository|skin cream|ointment|lotion)\b.*\b' + _FAST + r'\b',
     r'\b' + _FAST + r'\b.*\b(?:eye ?drops?|ear ?drops?|nose ?drops?|nasal spray|nasal drops?|inhaler|inhalers|asthma|puffer|ventolin|nebuli[sz]er|oxygen|patch|suppository|ointment)\b'],
  topic='fasting',
  text="""
The scholars differ here, so be careful and, where you can, choose the safer course:
- Eye drops and ear drops: most contemporary scholars say they do not break the fast, because they are not food or drink. Some classical scholars say the taste reaching the throat does. If you can use them at night, do.
- Nose spray and drops: avoid them if you can; anything that reaches the throat is treated like drink.
- An asthma inhaler: many contemporary fatwa bodies say it does not break the fast, since it is a vapour and not food or drink; some scholars are stricter. If asthma is a risk, the need to breathe comes first, and you can make the day up if a scholar rules it broken.
- Skin creams, patches and ointments: these do not break the fast.

If you must use something and it may break the fast, health comes first. Allah gives ease: {Q 2:185|Allah intends for you ease and does not intend for you hardship}. Ask your doctor about timing and a scholar about your case.
""",
  go=['/huda/guide?id=huda-fasting'],
  review='Eye and ear drops, nose sprays, and inhalers are contested; the positions given are those of many contemporary fatwa bodies, not text-checked here.')

E('fast-smoking',
  m=[r'\b(?:smok\w*|cigarette\w*|vap(?:e|es|ing)|vapor\w*|e ?cig\w*|shisha|hookah|nicotine|tobacco|chewing gum|gum|snuff|paan)\b.*\b' + _FAST + r'\b',
     r'\b' + _FAST + r'\b.*\b(?:smok\w*|cigarette\w*|vap(?:e|es|ing)|vapor\w*|e ?cig\w*|shisha|hookah|nicotine|tobacco|chewing gum|gum|paan)\b'],
  topic='fasting',
  text="""
Smoking breaks the fast: the smoke is drawn on purpose into the throat and lungs, and nicotine is taken as a substance. Vaping, shisha and chewing tobacco do too. Chewing gum is best avoided in the day: the flavour dissolves and may be swallowed. If you smoke, Ramadan is a good time to stop, with the help of your doctor: you manage without it from dawn to sunset, and many people find that is the start of quitting.

If you smoked by mistake, forgot you were fasting, or something went down without intending it, the fast is not broken: the Qur'an says {Q 33:5|there is no blame upon you for that in which you have erred but [only for] what your hearts intended}.
""",
  go=['/huda/guide?id=huda-fasting'],
  review='Chewing gum is stated as best avoided, not as a ruling; the rest is the general view.')

E('fast-forgot-accident',
  m=[r'\b(?:forgot|forgetfully|forgotten|by mistake|accidentally|by accident|unintentionally|without (?:thinking|meaning|realizing|realising)|did not realise|didn t realise|swallowed (?:a )?(?:fly|insect|dust|smoke|water)|water (?:went|going) down|swallowed (?:my )?(?:saliva|spit)|saliva|spit|spitting|phlegm|mucus|dust|fly)\b.*\b' + _FAST + r'\b',
     r'\b' + _FAST + r'\b.*\b(?:forgot|forgetfully|by mistake|accidentally|by accident|unintentionally|swallowed (?:a )?(?:fly|insect|dust|smoke|water)|water (?:went|going) down|saliva|phlegm|mucus|dust)\b',
     r'\b(?:ate|eat|eaten|drank|drink|drunk|had) .*\b(?:forgot|forgetting) .*\b(?:fast\w*|fasting)\b', r'\bforgot i was fasting\b', r'\bforgot (?:that )?(?:i was|it was) (?:fasting|ramadan)\b'],
  topic='fasting',
  text="""
If you eat or drink because you forgot you were fasting, your fast is still valid. The Prophet ﷺ said: if somebody eats or drinks forgetfully, he should complete his fast, for what he ate or drank was given to him by Allah ({H bukhari:1933|The Prophet said that if somebody eats or drinks forgetfully he should complete his fast, for Allah gave him what he ate or drank}). Stop as soon as you remember. You do not make it up.

The same ease applies to things you do not intend or cannot avoid: a fly or dust going down your throat, water going down when rinsing your mouth in wudu (provided you did not exaggerate), a dream with wetness, or your own saliva. The Qur'an says {Q 33:5|there is no blame upon you for that in which you have erred but [only for] what your hearts intended}.

Phlegm that reaches the mouth should be spat out rather than swallowed on purpose; if it goes down by itself, the fast stands.
""",
  go=['/huda/guide?id=huda-fasting'],
  review='The treatment of phlegm and water in wudu are general views; the main ruling is cited.')

E('fast-intimacy-kiss',
  m=[r'\b(?:kiss\w*|hug\w*|embrac\w*|touch\w*|cuddl\w*|intimacy|intimate|sex|sexual|intercourse|masturbat\w*|wet dream|wife|husband|spouse)\b.*\b' + _FAST + r'\b',
     r'\b' + _FAST + r'\b.*\b(?:kiss\w*|hug\w*|embrac\w*|intimacy|intimate|sex|sexual|intercourse|masturbat\w*|wet dream|wife|husband|spouse)\b'],
  x=[r'\b(?:iftar|suhoor) (?:with|invit\w*)\b'],
  topic='fasting',
  text="""
Between sunrise and sunset in Ramadan:
- Intercourse breaks the fast, and doing it deliberately in the day of Ramadan is a major matter that requires a penalty (kaffarah) on top of making the day up. A man told the Prophet ﷺ he had been ruined for having relations with his wife while fasting; the Prophet ﷺ gave him the way of atonement: freeing a slave if he can, otherwise fasting two months in a row, otherwise feeding sixty poor people ({H bukhari:1936|A man told the Prophet he was ruined because he had relations with his wife while fasting; the Prophet asked if he could free a slave, then fast two months, then feed sixty poor people}). The Hanafi and Maliki schools put the same penalty on deliberate eating and drinking; the Shafi'i and Hanbali schools apply it to intercourse only.
- Kissing and embracing your spouse are allowed if you can control yourself. A'ishah said the Prophet ﷺ used to kiss and embrace his wives while fasting, and that he had more power to control his desires than any of you ({H bukhari:1927|Aisha said the Prophet used to kiss and embrace his wives while fasting and he had more control over his desires than any of you}). If it leads you to go further, avoid it in the day.
- Releasing semen on purpose (by hand or any other way) breaks the fast and needs a make-up day, and the person should repent; a wet dream does not break it.
- The night is free: Allah allows relations with your wife from sunset until dawn ({QR 2:187}).

If the fast was broken by a slip, make up the day and ask Allah's forgiveness; ask a scholar if you are unsure which rule applies.
""",
  go=['/huda/guide?id=huda-fasting'],
  review='The kaffarah applying to eating (Hanafi, Maliki) versus intercourse only (Shafi\'i, Hanbali), and masturbation, are standard fiqh teaching, not text-checked here.')

E('fast-vomit',
  m=[r'\b(?:vomit\w*|throw\w* up|threw up|puk\w*|nause\w*|sick to (?:my )?stomach)\b.*\b' + _FAST + r'\b',
     r'\b' + _FAST + r'\b.*\b(?:vomit\w*|throw\w* up|threw up|puk\w*)\b'],
  topic='fasting',
  text="""
If vomit comes up on its own (you are ill, or something upset your stomach), your fast is not broken and you do not make it up. If you make yourself vomit on purpose, the fast is broken and you must make the day up. A report attributed to the Prophet ﷺ says the same, but scholars grade it differently (al-Albani sahih, Darussalam da'if), so the ruling rests on the general view of the scholars rather than on it.

If some vomit goes back down your throat against your will, the fast stands; if you swallow it on purpose, the fast is broken.
""",
  go=['/huda/guide?id=huda-fasting'],
  review='Vomiting ruling is the majority view; the report usually quoted is graded differently by graders, so it is not cited.')

E('fast-breakers',
  m=[r'\b(?:invalidat\w*|nullif\w*|break|breaks|breaking|broke|spoil\w*|ruin\w*|void\w*|cancel\w*|ends?)\b.*\b' + _FAST + r'\b',
     r'\bwhat (?:breaks|invalidates|nullifies|spoils) (?:the |my |a )?(?:fast|fasting)\b', r'\bdoes\b.*\bbreak (?:the |my )?(?:fast|fasting)\b',
     r'\bwhat (?:is|are) (?:the )?(?:things? )?(?:that )?(?:allowed|permitted|not allowed|forbidden|haram|prohibited) (?:while|when|during) (?:fast\w*|ramadan)\b'],
  x=[r'\b(?:iftar|suhoor|say|dua|recite|eat first|meal|when (?:do|should|can))\b'],
  topic='fasting',
  text="""
What breaks the fast (all schools agree):
- Eating or drinking on purpose, anything that reaches the stomach by the mouth (including swallowed medicine and smoking).
- Marital intercourse in the day (with a penalty if deliberate).
- Deliberately making yourself vomit.
- Menstruation or postnatal bleeding, even a moment before sunset.
- Deliberately releasing semen.
- Leaving the intention, or choosing to stop the fast.

What does not break it: eating or drinking by forgetting ({H bukhari:1933|The Prophet said that if somebody eats or drinks forgetfully he should complete his fast, for Allah gave him what he ate or drank}); things you did not intend such as dust, a fly, or water going down while rinsing; a wet dream; brushing your teeth without swallowing; a bath, swimming or rain on you; perfume or smelling food; kissing your spouse without going further; blood tests and most injections; eye drops and skin creams; swallowing your own saliva.

Each of those has its own answer: ask me about the one you have in mind. Fasting also means guarding the tongue: lying and backbiting do not break the fast but spoil its reward.
""",
  go=['/huda/guide?id=huda-fasting'],
  review='Summary list of what does and does not break the fast is the general view of the schools; details are in the specific entries.')

E('fast-exempt',
  m=[r'\b(?:exempt\w*|excus\w*|allowed to (?:skip|miss|break|not)|permitted to (?:skip|miss|break|not)|who (?:does|do|is|are) not have to|who need not|who can skip|who can miss|who must not|who should not|not required to)\b.*\b' + _FAST + r'\b',
     r'\b' + _FAST + r'\b.*\b(?:exempt\w*|excus\w*|not obligatory on|not required|skip|miss)\b',
     r'\bwho (?:is|are) exempt\b', r'\bwho (?:can|may) (?:skip|break|miss|not) (?:the )?(?:fast|fasting|ramadan)\b',
     r'\b(?:pregnan\w*|breastfeed\w*|nursing|elderly|old age|travell?er\w*|travell?ing|sick|ill|illness|child|children|kids?|menstruat\w*|period|mental\w*)\b.*\b' + _FAST + r'\b.*\b(?:allowed|permit\w*|must|have to|obligatory|exempt|need|required|should|can)\b',
     r'\bi am (?:pregnant|sick|ill|travelling|traveling|old|elderly|breastfeeding)\b.*\b' + _FAST + r'\b',
     r'\b' + _FAST + r'\b.*\b(?:when|while|if)\b.*\b(?:pregnan\w*|breastfeed\w*|nursing|sick|ill|travell?ing|period)\b',
     r'\bfasting (?:when|while|if) (?:i am |im )?(?:pregnant|sick|ill|travell?ing|old|breastfeeding)\b', r'\bfasting while (?:pregnant|sick|ill|travell?ing|breastfeeding)\b',
     r'\bcan i (?:skip|miss|break|not fast)\b'],
  x=[r'\b(?:ibuprofen|medicine|medication|pill|tablet|injection|drops?|inhaler|vomit\w*)\b'],
  topic='fasting',
  text="""
Fasting Ramadan is obligatory on every adult Muslim who is sane and able. These people are excused:
- The sick, if fasting would harm them or delay recovery, and travellers: they break the fast and make up the same number of days later. Allah says: {Q 2:184|whoever among you is ill or on a journey [during them] - then an equal number of days [are to be made up]}. The Qur'an also says {Q 2:185|Allah intends for you ease and does not intend for you hardship}.
- Women in menstruation or postnatal bleeding: they must not fast, and they make the days up later (not the prayers).
- Pregnant or breastfeeding women who fear harm to themselves or the baby: they may break the fast. The schools differ on what follows: the Hanafi school says make the days up; the Shafi'i and Hanbali schools add a ransom of feeding a poor person for each day if the fear is for the baby only; some scholars say only the ransom.
- The elderly, and the chronically ill with no hope of recovery, who cannot fast: they give a ransom of feeding one poor person for each day ({QR 2:184}).
- Children before puberty: not obliged, though they can be gently encouraged.
- Those who have lost their minds: not obliged.

If you break the fast for a valid reason, do not feel guilty or hide it; it is Allah's permission. For your own case, ask a scholar or your doctor.
""",
  go=['/huda/guide?id=huda-fasting'],
  review='Pregnant and nursing women: make-up versus ransom per school is standard fiqh teaching, not text-checked here.')

E('fast-makeup-fidyah',
  m=[r'\b(?:make up|makeup|qada|compensate|repay|replace|owe|owed)\b.*\b(?:missed |skipped |broken |old )?(?:fast\w*|ramadan|days)\b',
     r'\b(?:missed|skipped|broken)\b.*\b(?:fast\w*|ramadan)\b', r'\bfidyah\b', r'\bkaffarah\b', r'\bkaffara\b', r'\bransom\b.*\bfast\w*\b',
     r'\bfeed(?:ing)? (?:a )?poor\b.*\b' + _FAST + r'\b', r'\bhow (?:many|much) .*\bfidyah\b', r'\bfast\w* (?:i|we) (?:missed|owe)\b',
     r'\bbroke my fast\b', r'\bbreak my fast (?:on purpose|deliberately|intentionally)\b', r'\bbroken fast\b'],
  topic='fidyah',
  text="""
Three different things, often mixed up:
1. Qada (making up). If you miss days of Ramadan for a valid reason (illness, travel, period, pregnancy), fast the same number of days before the next Ramadan comes, one day for each day missed. They need not be in a row. Allah says: {Q 2:184|an equal number of days [are to be made up]}. If you are late by years, still make them up, and ask a scholar whether anything extra is due (the Hanafi school says nothing extra).
2. Fidyah (ransom). For someone who cannot fast and cannot make it up (a very old person, a chronic illness): feed one poor person for each day missed ({QR 2:184}). The amount is a meal or its value; the schools set it differently (about half a sa' of wheat, around 1.6 kg, in the Hanafi school; a mudd, about 750 g of staple food, in the others). Ask your masjid for the local figure.
3. Kaffarah (penalty). For deliberately breaking a Ramadan fast by intercourse (and, in the Hanafi and Maliki schools, by eating or drinking on purpose): free a slave, or if not possible fast two months in a row, or if not possible feed sixty poor people ({H bukhari:1936|A man told the Prophet he was ruined because he had relations with his wife while fasting; the Prophet asked if he could free a slave, then fast two months, then feed sixty poor people}). On top of it, make up the day.

If you broke a fast on purpose in some other way, repent sincerely, make the day up and ask a scholar about the penalty for your school.
""",
  go=['/huda/guide?id=huda-fasting'],
  review='Fidyah amounts per school, the delay-in-making-up rule, and whether kaffarah covers eating/drinking are standard fiqh teaching, not text-checked here.')

E('suhoor-iftar',
  m=[r'\bsuhoor\b', r'\biftar\b', r'\bbreak(?:ing)? (?:the |my |a )?(?:fast|fasting)\b', r'\bwhat (?:do|should) (?:i|we) (?:eat|say|recite) (?:at|before|for|when) (?:iftar|suhoor|breaking)\b',
     r'\bwhen (?:do|should|can) (?:i|we) (?:break|start|stop|end) (?:the |my )?(?:fast|fasting)\b', r'\bfasting (?:times?|hours)\b', r'\bwhen does (?:the )?fast (?:start|begin|end)\b',
     r'\b(?:pre ?dawn|dawn) meal\b', r'\bwhen to stop eating\b', r'\bdua (?:for|at|when) (?:breaking|iftar|opening)\b', r'\bopen(?:ing)? (?:my |the )?fast\b',
     r'\bintention (?:for|of) (?:the )?(?:fast|fasting)\b', r'\bniyyah (?:for|of) (?:the )?(?:fast|fasting|ramadan)\b', r'\bniyyat\b'],
  x=[r'\b(?:game|story|recipe|recipes|app|reminder|alarm|schedule|plan|timetable)\b'],
  topic='iftar',
  text="""
Suhoor (the pre-dawn meal) and iftar (the meal that ends the fast) are both sunnah.

Suhoor: eat before dawn; the Prophet ﷺ said: take suhoor, for there is a blessing in it ({H bukhari:1923|The Prophet said to take suhoor as there is a blessing in it}). Eat and drink until the white thread of dawn appears clearly from the black thread of night ({QR 2:187}); stop when the Fajr time begins.

Iftar: break the fast at sunset, without delay. The Prophet ﷺ said the people will keep to the right path as long as they hasten to break the fast ({H bukhari:1957|The Prophet said the people will remain on the right path as long as they hasten the breaking of the fast}). His practice was to break his fast with fresh dates before praying, then dried dates, and if there were none, a few sips of water ({H abudawud:2356|Anas said the Prophet used to break his fast with fresh dates before praying, or dry dates, or a few mouthfuls of water}).

The du'a: the Prophet ﷺ is reported to have said when breaking the fast: "Dhahaba az-zama'u wabtallatil-'urooqu wa thabatal-ajru in sha' Allah" (the thirst has gone, the veins are moist, and the reward is confirmed, if Allah wills) ({H abudawud:2357|Ibn Umar reported the Prophet said when he broke his fast: thirst has gone, the veins are moist and the reward is sure if Allah wills}).

The intention is in the heart. It is enough to decide the night before that you will fast tomorrow (some schools require the night-before intention for a fard fast; the Hanafi school accepts it up to before midday for Ramadan). No words need to be said aloud.
""",
  go=['/huda/guide?id=huda-fasting'],
  review='The intention timing per school (night before versus before midday) is standard fiqh teaching, not text-checked here. The transliteration of the iftar du\'a is typed by hand and should be checked by a reader.')

E('fast-voluntary',
  m=[r'\bvoluntary fast\w*\b', r'\bsunnah fast\w*\b', r'\bnafl fast\w*\b', r'\bfast(?:ing)? on (?:monday|thursday|mondays|thursdays|arafah|ashura|aashura)\b',
     r'\bsix days of shawwal\b', r'\bshawwal\b.*\bfast\w*\b', r'\bfast\w*\b.*\bshawwal\b', r'\bwhite days\b', r'\bayyam al bid\b', r'\bashura\b', r'\bday of arafah\b.*\bfast\w*\b',
     r'\bfast\w* (?:of|on) (?:the )?day of arafah\b', r'\bwhich days? (?:can|should) (?:i|we) fast\b', r'\bwhen can i fast\b', r'\bfasting outside ramadan\b', r'\bfast(?:ing)? other than ramadan\b',
     r'\bforbidden (?:days? to|to) fast\b', r'\bdays? (?:not|never) to fast\b', r'\bfast(?:ing)? on eid\b', r'\bfast(?:ing)? on friday\b', r'\bfast(?:ing)? every other day\b'],
  topic='voluntary fasting',
  text="""
Besides Ramadan, these fasts are encouraged:
- Six days of Shawwal (the month after Ramadan): the Prophet ﷺ said whoever fasts Ramadan and follows it with six days of Shawwal, it is as if he fasted all the time ({H muslim:1164|Abu Ayyub reported the Prophet said whoever fasted Ramadan and followed it with six days of Shawwal, it is as if he fasted perpetually}).
- The Day of Arafah (9 Dhul Hijjah) for someone who is not on Hajj, and Ashura (10 Muharram), with the 9th or 11th as well: the Prophet ﷺ hoped Allah would forgive the sins of the previous and coming year for Arafah, and of the previous year for Ashura ({H muslim:1162|Abu Qatadah reported the Prophet was asked about fasting; he said he hoped fasting Arafah would atone for the preceding and coming year and fasting Ashura for the preceding year}).
- Mondays and Thursdays, and the three "white days" (13th, 14th and 15th of each lunar month): sunnah fasts that the Prophet ﷺ kept regularly.
- The fast of Dawud (alternate days) is the best regular fasting, though demanding.

Days on which fasting is forbidden: the two Eids (Eid al-Fitr and Eid al-Adha) and, for most scholars, the three days after Eid al-Adha (the days of tashriq) except for pilgrims who cannot offer a sacrifice. Many scholars also dislike fasting only on Friday on its own, or only on Saturday.

A woman needs her husband's agreement for a voluntary fast when he is at home (the schools take this as a courtesy to him). Do not fast so much that you cannot do your duties. A person who owes make-up days should clear them first.
""",
  go=['/huda/guide?id=huda-fasting'],
  review='The Monday/Thursday and white-day fasts, forbidden days, and the husband\'s consent are standard teaching; only the Shawwal and Arafah/Ashura hadith are cited here.')

E('ramadan-basics',
  m=[r'\bwhat is ramadan\b', r'^(?:about )?ramadan$', r'^explain ramadan$', r'^ramadan (?:explained|basics|meaning)$', r'\bwhy (?:do|are) (?:muslims?|we) (?:fast|fasting)\b', r'\bwhy fast\b', r'\bpurpose of (?:the )?(?:fast|fasting|ramadan)\b', r'\bwhy is ramadan\b',
     r'\bwhat is (?:the )?(?:fast|fasting)\b', r'\bhow (?:do|to|does) (?:i |we |you )?(?:fast|start fasting|keep a fast|observe)\b', r'\brules of (?:the )?(?:fast|fasting|ramadan)\b',
     r'\bfasting (?:rules|basics|for beginners|explained)\b', r'\bwhat (?:is|are) the (?:rules|conditions|pillars) of (?:the )?(?:fast|fasting|ramadan)\b',
     r'\bwhat is sawm\b', r'\bwhat does (?:ramadan|fasting) mean\b', r'\bwhat is laylat(?:ul)? ?(?:al)? ?qadr\b', r'\bwhat should i do in ramadan\b', r'\bwhat (?:to do|do muslims do) in ramadan\b'],
  x=[r'\b(?:app|screen|calendar|date|dates|when is|which day|time)\b'],
  topic='fasting',
  text="""
Ramadan is the ninth month of the Islamic calendar, the month in which the Qur'an was revealed. Fasting (sawm) in it is one of the five pillars of Islam. Allah says: {Q 2:183|decreed upon you is fasting as it was decreed upon those before you that you may become righteous}, and {Q 2:185|The month of Ramadhan [is that] in which was revealed the Qur'an}.

What fasting is: from true dawn (Fajr) until sunset (Maghrib) you give up food, drink and marital relations, with the intention to obey Allah. It also means guarding the tongue and the eyes. The Prophet ﷺ said that whoever does not give up false speech and bad conduct, Allah has no need of his giving up food and drink ({H bukhari:1903|The Prophet said whoever does not give up forged speech and evil actions, Allah has no need of his leaving his food and drink}).

Who: every adult Muslim who is sane and able; those who are ill, travelling, menstruating, pregnant or old are excused as explained in the exemptions. A day of fasting begins with suhoor, ends with iftar, and is filled with prayer, Qur'an, charity and good character. The last ten nights hold Laylat al-Qadr, better than a thousand months (the night of the Qur'an's descent, {QR 97:1-3}).

The Ramadan screen and the Islamic Calendar in this app help with the days and times. The Fasting guide goes step by step.
""",
  go=['/huda/guide?id=huda-fasting', '/ramadan'],
  review='The general account; each cited item is verified against its source.')

E('ramadan-date',
  m=[r'\bwhen (?:is|does|will|do) ramadan\b', r'\bramadan (?:date|dates|start|starts|begin|begins|ends|end|this year|next year|2026|2027|2025)\b', r'\bwhat (?:date|day) is ramadan\b',
     r'\bwhen (?:is|does) eid\b', r'\beid (?:date|dates|this year|next year|2026|2027)\b', r'\bwhen (?:is|does|will) (?:the )?(?:next )?(?:eid|hajj|muharram|ashura|laylat|shab e|shaban|rajab)\b',
     r'\bislamic (?:new year|date|dates)\b', r'\bhijri (?:date|dates|calendar|year)\b', r'\btoday s (?:islamic|hijri) date\b', r'\bwhat is the (?:islamic|hijri) date\b',
     r'\bmoon ?sighting\b', r'\bsight(?:ing)? (?:of )?(?:the )?(?:new )?moon\b', r'\bcalculation or sighting\b', r'\bwhen (?:is|are) (?:the )?(?:islamic )?(?:holidays?|festivals?|events?)\b'],
  topic='calendar',
  text="""
I cannot give you the exact date, because the Islamic months begin with the sighting of the new moon, and countries and communities differ on sighting versus astronomical calculation. The Prophet ﷺ taught to fast when you see the crescent and to stop when you see it.

The Islamic Calendar screen in this app shows the expected dates of Ramadan, Eid and the other days for the current Hijri year, worked out by calculation. The start of Ramadan itself is confirmed by the moon-sighting authority in your country, or by your local masjid, which you should follow. The Ramadan screen helps you through the month.
""",
  go=['/calendar', '/ramadan'],
  review='None: the answer points to the calendar and the local authority rather than stating a date.')
