# Round 11 additions. They sit before the topic files so a specific answer is found first.

E('divorce-unsafe',
  m=[r'\b(?:khula\w*|khul|divorc\w*|talaq|separat\w*|leav\w*|end(?:ing)?|escap\w*|get out|break up|annul\w*)\b.*\b(?:unsafe|not safe|abus\w*|violen\w*|hits|hit|hitting|beats|beating|beaten|hurts|hurting|harm\w*|afraid|scared|frightened|danger\w*|threat\w*|controlling|coerc\w*|fear)\b',
     r'\b(?:unsafe|not safe|abus\w*|violen\w*|hits|hit|hitting|beats|beating|beaten|hurts|hurting|harm\w*|afraid|scared|frightened|danger\w*|threat\w*|controlling)\b.*\b(?:khula\w*|khul|divorc\w*|talaq|separat\w*|leave (?:him|my husband|the marriage)|leaving (?:him|my husband|the marriage)|end the marriage)\b',
     r'\bcan (?:a |the )?(?:woman|wife|muslim woman|i) (?:ask for|get|seek|file for|apply for) (?:a )?(?:khula\w*|khul|divorc\w*)\b.*\b(?:safe|abus\w*|hit|hits|beat|beats|harm\w*|afraid|scared)\b'],
  x=[r'\b(?:my (?:son|daughter|friend|sister|mother|mom|aunt|cousin|neighbou?r|client|student)|her husband|his wife)\b.*\b(?:hits|beats|abus\w*)\b.*\b(?:what should|how can i help|how do i help)\b'],
  topic='divorce',
  text="""
Your safety comes first. If you are in danger now, go to a safe place and call your local emergency number. The help lines on this screen can talk it through with you in confidence.

Islam does not ask you to stay in a marriage where you are being hurt or frightened. Allah commands that a wife be kept in kindness or released with kindness, and forbids keeping her to harm her: {Q 2:231|and do not keep them, intending harm, to transgress [against them]}. {Q 4:19|And live with them in kindness}. And if a couple separates, {Q 4:130|Allah will enrich each [of them] from His abundance}.

What a woman can do, in general terms:
- Khul': she asks to be released, usually by returning the mahr or what is agreed, as in the case of Thabit ibn Qais's wife ({H bukhari:5273|The wife of Thabit ibn Qais said she did not blame him for his character or religion but disliked behaving in an un-Islamic manner if she stayed with him, and the Prophet asked her to give back the garden and told Thabit to accept it}).
- A judge or a recognised Islamic court can end a marriage in which the wife is being harmed, even if the husband refuses. Many scholars, and the family courts of many Muslim countries, allow this. The schools differ on the conditions and on whether his agreement is needed for khul', so a scholar who knows your school and your country should confirm the steps for you.
- The warning about a woman who asks for divorce "without a strong reason" ({HS abudawud:2226|Thawban reported the Prophet said if any woman asks her husband for divorce without a strong reason, the odour of Paradise will be forbidden to her}) is about asking without cause. Being harmed is a cause. It is not a warning to a woman in danger.
- Your country's own law is separate and open to you: a protective order, a shelter, a lawyer or the police can help whether or not an imam is involved. You do not need anyone's permission to be safe.

Leaving can be the most dangerous time, so plan it with a domestic violence service: where you will go, your papers and phone, and someone you trust who knows. Staying is not a failure, and neither is leaving. This is general information, not a ruling on your case, and it is waiting for scholar review. A scholar who understands abuse, or a Muslim women's service, can support you without pressing you to stay.
""",
  go=['/support'],
  review='Khul, judicial dissolution for harm (darar) and the Abu Dawud warning about asking for divorce without cause are described in general terms for a woman who is not safe; the schools\' conditions and the claim that many courts allow dissolution for harm need a scholar and a lawyer to confirm. Wording must be read by someone who works with abuse survivors.')

E('abuse-verse-434',
  m=[r'\b(?:does|do|is|are|did) (?:the )?(?:quran|islam|quran say|religion|god|allah)\b.*\b(?:allow\w*|permit\w*|say|says|let\w*|right)\b.*\b(?:hit|hits|beat|beats|strike|hurt|hurts)\b.*\b(?:me|her|my wife|wife)\b',
     r'\b(?:husband|he|man) (?:is |was )?(?:allowed|permitted|right) to (?:hit|beat|strike|hurt) (?:me|her|his wife|my wife)\b',
     r'\b(?:allowed|permitted) to (?:hit|beat|strike) me\b', r'\b4 ?:? ?34\b.*\b(?:hits|hit|beats|beat|hurts|abus\w*|me|my husband)\b', r'\b(?:hits|hit|beats|beat|hurts|abus\w*)\b.*\b4 ?:? ?34\b'],
  x=[r'\b(?:what does 4 ?:? ?34 mean|explain 4 ?:? ?34|meaning of 4 ?:? ?34|tafsir)\b'],
  topic='abuse',
  text="""
No. Nothing in Islam gives anyone the right to hit you, frighten you or control you by force. If he is hurting you, your safety comes first: go to a safe place and call your local emergency number if you are in danger. The help lines on this screen are for you.

I will not answer you with a verse in place of your safety, but you asked about 4:34, so here is what it does and does not say. {Q 4:34|But those [wives] from whom you fear arrogance - [first] advise them; [then if they persist], forsake them in bed; and [finally], strike them. But if they obey you [once more], seek no means against them} is about serious, persistent misconduct and comes last, after advice and separation in bed. Scholars set hard limits on it: not on the face, not to hurt, not to humiliate; many say at most a symbolic touch, and that leaving it is better; and many say that today it should not be used at all. Beating a wife to control her, in anger, or to leave marks is not what the verse allows. It is harm, and Islam forbids harm.

The Prophet ﷺ never struck a woman ({HS muslim:2328|A'isha reported that the Prophet never beat anyone with his hand, neither a woman nor a servant, except when fighting in the cause of Allah}). He warned the men who beat their wives that they are not the best of you ({H ibnmajah:1985|The Prophet said do not beat the female slaves of Allah, and later said that seventy women had come to the family of Muhammad complaining about their husbands, and that those men are not the best of you}). When a husband broke his wife's arm, the Prophet told him to let her go ({H nasai:3497|Thabit ibn Qais hit his wife and broke her arm, and the Prophet sent for him and told him to take what she owed him and let her go}).

You can ask me about khul' and what a woman can do if she is not safe at home. This is general information, not a ruling on your case, and it is waiting for scholar review.
""",
  go=['/support'],
  review='Reads 4:34 with the restrictions the scholars place on it and says plainly that violence is not allowed. The attribution of "at most symbolic" and "better left" to scholars is a summary of views already in the hitting-wife answer and needs a scholar to confirm. Wording must be read by someone who works with abuse survivors.')

E('share-chat',
  m=[r'\b(?:share|send|forward|export|email|e mail|print|post|screenshot|show)\b.*\b(?:this |our |the |my |whole |entire |full )?(?:chat|conversation|thread|messages?)\b.*\b(?:friend|someone|family|brother|sister|mum|mom|dad|wife|husband|teacher|imam|scholar|others?|people|whatsapp|facebook|instagram|online)\b',
     r'\bcan i (?:share|send|forward|export|email|print|save) (?:this|our|the|my|whole|entire|full)?\s*(?:chat|conversation|thread)\b',
     r'\b(?:share|send|forward|export|email|print|save) (?:this |our |the |my )?(?:chat|conversation|thread)\b',
     r'\b(?:is|are) (?:this|our|the|my) (?:chat|conversation|thread|messages?) (?:private|saved|stored|shared|public|visible|recorded|kept)\b',
     r'\b(?:how|where) (?:do|can) i (?:share|send|export|save) (?:this |our |the |my )?(?:chat|conversation)\b'],
  topic='sharing',
  text="""
No. A whole chat cannot be shared from the app, and that is on purpose: what you ask me can be personal.

My side of the chat is not saved or sent anywhere. It stays on screen for this visit only, and it is gone when you leave, clear it, or close the app. So there is no chat to forward.

What you can share:
- Each of my replies has a "Copy this reply" button. It copies that one reply, with its sources, and a line saying it is from Ar-Rayaan. Your question and the rest of the conversation are not included.
- Verses, hadith, du'as and stories have their own Share button. It shows exactly what will be sent before anything is copied, and nothing is posted for you.
- A screenshot is your own choice. Look at the screen first: it will show your own words.

If you want a friend or a teacher to see an answer, copy that reply, or ask them to put the same question to me.
""",
  go=['/settings'],
  review='Describes what the app does today (nothing is saved; Copy this reply copies one reply). No religious content.')

E('hadi-memory-settings',
  m=[r'\b(?:where|how)\b.*\b(?:change|turn off|turn on|stop|switch|set|control|manage|see|delete|clear|forget)\b.*\b(?:remember\w*|memory|know about me|knows about me)\b',
     r'\b(?:what|how much)\b.*\b(?:do you|does hadi|does hadi) (?:remember|know)\b.*\b(?:about me|me)\b',
     r'\b(?:do you|does hadi) (?:remember|keep|store|save) (?:anything|things|what)\b.*\b(?:about me|i say|i tell)\b'],
  topic='privacy',
  text="""
Here is what I keep, and where you control it.

- I do not save our chat. It stays on screen for this visit only and is gone when you leave, clear it, or close the app.
- Settings has a switch called "Hadi remembers you". It is off by default. It only lets me greet you by the name on your account, and only when I answer through an AI service you set up yourself; the name goes to that service with your question. As a guest there is no name, so it changes nothing.
- Settings, then Support & wellbeing, holds the check-in, private mode, quick exit and the safe word.
- To forget everything at once, say "forget everything" in this chat, or use New conversation in the menu.
""",
  go=['/settings'],
  review='Describes what the app does today. No religious content.')
