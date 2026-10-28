# Zakat, Hajj and Umrah, and money.

E('zakat-fitr',
  m=[r'\bzakat (?:al )?fitr\b', r'\bfitra\b', r'\bfitrana\b', r'\bsadaqat(?:ul)? fitr\b', r'\bfitr(?:ah)? (?:amount|charity)\b', r'\bcharity of (?:eid|ramadan|fitr)\b',
     r'\bramadan (?:charity|zakat)\b', r'\beid (?:charity|zakat)\b'],
  topic='zakat fitr',
  text="""
Zakat al-fitr (also called fitrah) is a charity every Muslim gives at the end of Ramadan, so that the poor can celebrate Eid too, and it also purifies the fast.

Who pays: every Muslim who has food beyond their needs for the day of Eid, for themselves and for those they support, including children.

How much: the Prophet ﷺ fixed it at one sa' of dates or barley per person ({H bukhari:1503|Ibn Umar said the Prophet made zakat al-fitr a sa' of dates or barley on every Muslim, and ordered it be paid before people go out to the Eid prayer}). A sa' is about 2.5 to 3 kg of staple food. Many people give its money value, and the Hanafi school allows this; other schools prefer food. The Hanafi school accepts half a sa' of wheat, as the people did in Madinah ({H bukhari:1511|Ibn Umar said the Prophet made one sa' of dates or barley incumbent on everyone as zakat al-fitr, and the people then substituted half a sa' of wheat}). Your local masjid announces the yearly amount in money.

When: before the Eid prayer; it may be paid a few days before Eid, and it is best to give it early so the poor can use it. If given after the prayer it is counted as ordinary charity.

Who receives it: the poor and needy, as with zakat.
""",
  go=['/zakat'],
  review='The size of the sa\' in kilograms, the money-value allowance per school, and when it may be paid are standard fiqh teaching, not text-checked here.')

E('zakat-recipients',
  m=[r'\bwho (?:can|may|should|is allowed to|is eligible to) (?:receive|get|take) (?:the )?(?:zakat|it|sadaqah|charity)\b', r'\bwho (?:is|are) (?:eligible|entitled) (?:for|to receive) (?:the )?zakat\b',
     r'\brecipients? of zakat\b', r'\bwho (?:to|do i) give zakat to\b', r'\bwho gets zakat\b', r'\bto whom (?:is|can|should) zakat\b', r'\bzakat (?:recipients?|beneficiar\w*|eligib\w*)\b',
     r'\beight categories\b', r'\b8 categories\b', r'\bcan i give zakat to (?:my )?(?:parents?|mother|father|wife|husband|children|son|daughter|relatives?|family|brother|sister|masjid|mosque|school|non muslims?)\b',
     r'\bgive zakat to\b', r'\bwho can receive\b', r'\bwho can i give\b.*\bzakat\b'],
  x=[r'\bfitr\b'],
  topic='zakat',
  text="""
Allah names exactly who receives zakat: {Q 9:60|Zakah expenditures are only for the poor and for the needy and for those employed to collect [zakah] and for bringing hearts together [for Islam] and for freeing captives [or slaves] and for those in debt and for the cause of Allah and for the [stranded] traveler}. So the eight categories are:
1. The poor (fuqara) and 2. the needy (masakin): those without enough to meet their basic needs.
3. Those employed to collect and distribute it.
4. Those whose hearts are to be won over to Islam or kept firm.
5. Freeing slaves and captives.
6. Those in debt (who cannot pay).
7. In the cause of Allah.
8. The stranded traveller.

Not zakat-eligible: those who pay zakat themselves (rich people), and, by agreement of the scholars, your own parents, grandparents, children and grandchildren (you support them already), and your spouse. Other relatives such as siblings, uncles and cousins who are poor can receive it, and giving to them carries a double reward. A masjid building or a school can receive sadaqah; whether zakat can go to them is a question on which scholars differ (it usually goes to the poor, to debtors and to Allah's cause as the scholars define it). Non-Muslims: zakat is for the poor Muslims, though non-Muslims may be given sadaqah, and some scholars allow zakat for those whose hearts are being reconciled.

Pay zakat to a person or organisation you trust to give it correctly. The Zakat guide has more.
""",
  go=['/huda/guide?id=huda-zakat', '/zakat'],
  review='Non-eligible relatives, whether masjids or schools can receive zakat, and non-Muslims are school positions from standard fiqh teaching, not text-checked here.')

E('zakat-jewelry',
  m=[r'\bzakat\b.*\b(?:jewel\w*|ornaments?|gold|silver|bangles?|necklace|wedding ring|dowry|mahr)\b', r'\b(?:jewel\w*|ornaments?|gold|silver|bangles?|necklace|wedding ring)\b.*\bzakat\b'],
  topic='zakat',
  text="""
It depends on the school.
- The Hanafi school: yes. Gold and silver jewelry that reaches the nisab (85 g of gold or 595 g of silver in total, counting your own savings with it) is zakatable, even if you wear it.
- The Maliki, Shafi'i and Hanbali schools: no zakat on jewelry that a woman wears in a normal, permitted way. Jewelry kept as savings, in bars or coins, or not worn, is zakatable in all the schools.

The Zakat screen in this app shows both positions. If you follow no particular school, the careful course is to pay zakat on it; a scholar can advise you. Rate: 2.5% of its current market value, once a lunar year has passed and the total reaches the nisab. Silver or gold in other forms (bars, coins) is always zakatable.
""",
  go=['/zakat'],
  review='Jewelry positions per school are standard fiqh teaching (and match the Zakat screen); not text-checked here.')

E('zakat-due',
  m=[r'\bwhen (?:is|does|do|should|must|will|did|are)\b.*\bzakat\b.*\b(?:due|payable|pay|paid|obligatory|required|owed|fall|falls|start|starts|begin|begins|become|becomes|calculated)\b',
     r'\bwhen (?:to|do i|should i|must i|can i|shall i) (?:pay|give|calculate|work out) (?:my |the )?zakat\b',
     r'\bzakat\b.*\b(?:due date|deadline|hawl|lunar year|one year|a year|yearly|annual\w*|every year|each year|what date|which day|which month)\b',
     r'\bhawl\b', r'\bwhen is it (?:due|payable)\b.*\bzakat\b'],
  x=[r'\b(?:fitr|fitra|recipients?)\b'],
  topic='zakat',
  text="""
Zakat falls due when your zakatable wealth has stayed at or above the nisab for one full lunar year (the hawl). The one-year condition is taught by all four schools, and it rests on reports such as {HW abudawud:1573|Ali reported the Prophet said when you possess two hundred dirhams and one year passes on them, five dirhams are payable, and nothing is due on gold until it reaches twenty dinars, then half a dinar once a year has passed}. Al-Albani graded the same report sahih, so the graders differ. That is why I give you the rule the schools agree on and not one proof.

How to find your date:
- Your zakat date is the day your wealth first reached the nisab. A year later, if you still hold at least the nisab, pay 2.5% of what you hold that day.
- A lunar year is about 354 days, so the date moves about 11 days earlier in the calendar each year.
- Many people choose one fixed day every year, such as the 1st of Ramadan, to keep it simple, and work out their zakat on that day. If you do, use the same day each year. Ask a scholar if you are changing your date.
- If your wealth drops below the nisab part-way through the year, the schools differ: the Hanafi school looks at the two ends of the year, and the other schools restart the count when it falls below.
- Pay it soon after it falls due. Unpaid zakat does not disappear with time; it stays owed.
- Crops are different: their zakat is due at the harvest ({Q 6:141|give its due [zakah] on the day of its harvest}).

Zakat al-fitr is a separate charity at the end of Ramadan; ask me about it by name. The Zakat screen works out the amount once you know your date.
""",
  go=['/zakat', '/huda/guide?id=huda-zakat'],
  review='The one-year condition and the choice of a fixed date are standard fiqh teaching; the Hanafi versus other schools position on wealth that falls below the nisab mid-year is a school difference not text-checked here. The hawl report is cited as da\'if per Darussalam with the al-Albani grade stated as a difference.')

E('zakat-debts',
  m=[r'\bzakat\b.*\b(?:debts?|loans?|owe|owed|owing|mortgage\w*|credit cards?|liabilit\w*|borrow\w*|in debt|instal?lments?|arrears|bills)\b',
     r'\b(?:debts?|loans?|owe|owed|owing|mortgage\w*|credit cards?|liabilit\w*|in debt|instal?lments?)\b.*\bzakat\b'],
  x=[r'\b(?:recipients?|who can receive|who gets|eligib\w*)\b'],
  topic='zakat',
  text="""
Debts you owe can reduce the wealth you pay zakat on, but only debts that are due now, and the schools differ:
- The Hanafi, Maliki and Hanbali schools take the debts you owe away from your cash and gold before they work out whether you have reached the nisab and what you pay on. Zakat is paid on what is left.
- The Shafi'i school's usual position is that debts do not reduce it: the full amount you hold is counted. The Zakat screen lets you choose, and shows the working for both.
- Contemporary scholars often count only the instalments that are due within the year for a long loan such as a mortgage, not the whole loan. Ask a scholar if you have one.
- Money other people owe you and that you can collect counts as your wealth. Money you cannot expect to get back does not, until you have it.
- A debt does not cancel zakat if you are still over the nisab after taking it off. Repaying a debt that is due is also a duty, so do both.

Allah names "those in debt" among the people who may receive zakat ({QR 9:60}). If your debts are heavy, you may be one of them.

This is general guidance. For an exact figure with a business, a pension or a mortgage, ask a qualified scholar.
""",
  go=['/zakat', '/huda/guide?id=huda-zakat'],
  review='The treatment of debts differs by school (Hanafi, Maliki and Hanbali deduct; the usual Shafi\'i position does not) and the contemporary view on instalments of a long loan is a modern opinion; none of it is text-checked here.')

E('zakat-amount',
  m=[r'\bnisab\b', r'\bhow (?:much|many)\b.*\bzakat\b', r'\bzakat\b.*\bhow (?:much|many)\b', r'\bzakat (?:rate|amount|percentage|percent|share)\b', r'\b(?:2.5|two and a half)\b.*\b(?:zakat|percent|%)\b',
     r'\b(?:zakat|percent|%)\b.*\b(?:2.5|two and a half)\b', r'\bwhat (?:percent|percentage|fraction|part) .*\bzakat\b', r'\bzakat\b.*\bwhat (?:percent|percentage|fraction)\b'],
  x=[r'\b(?:fitr|fitra|fitrana|recipients?)\b', r'\b(?:calculate|calculator|work out|app)\b'],
  topic='zakat',
  text="""
The rate is 2.5% (one fortieth) of your zakatable wealth, once it has reached the nisab and a lunar year has passed on it. For example, if your zakatable wealth on your zakat date is 10,000 and that is above the nisab, you pay 250.

The nisab is the minimum: the value of 85 grams of gold or 595 grams of silver. The Prophet ﷺ set the silver measure at five awqiyah, which is 200 dirhams ({H bukhari:1447|The Prophet said there is no zakat on less than five awaq of silver, nor on less than five camels or five wasqs of produce}). Silver is the lower figure, so more people reach it and more of the poor are helped. Many scholars today use the silver measure; some use gold. The Zakat calculator lets you choose, and can fill in today's gold and silver prices.

Zakat is paid on what is left after the debts you owe that are due, if you follow the Hanafi, Maliki or Hanbali view; ask me "what about debts" for that. Crops and livestock have their own rates; ask a scholar.

For your own figure, open the Zakat calculator. It keeps your numbers on your device.
""",
  go=['/zakat', '/huda/guide?id=huda-zakat'],
  review='The rate, the nisab figures and the choice between silver and gold are standard fiqh teaching and match the Zakat screen; only Bukhari 1447 (the silver measure) is cited.')

E('zakat-nisab-rate',
  m=[r'\bnisab\b', r'\bhow much zakat\b', r'\bhow (?:much|many) (?:is|do i|should i|to|zakat)\b.*\bzakat\b', r'\bzakat\b.*\bhow much\b', r'\bzakat (?:rate|amount|percentage|percent)\b', r'\b(?:2.5|two and a half)\b.*\bzakat\b',
     r'\bzakat\b.*\b(?:2.5|two and a half)\b', r'\bwho (?:must|has to|should|needs to) pay zakat\b', r'\bwho is (?:required|obliged) to pay zakat\b',
     r'\bcalculate zakat\b', r'\bhow to (?:calculate|work out|pay) zakat\b',
     r'\bwhat is zakat\b', r'\bzakat on (?:gold|silver|savings|money|cash|jewel\w*|business|stocks?|shares?|property|house|car|salary|crypto|investments?|rental|land|pension|retirement)\b',
     r'\bis zakat (?:due|payable|required|obligatory) on\b', r'\bzakat (?:and|for) (?:gold|silver|savings|jewel\w*)\b', r'\bdo i (?:pay|owe) zakat\b'],
  x=[r'\b(?:fitr|recipients?)\b'],
  topic='zakat',
  text="""
Zakat is the third pillar of Islam: an obligatory charity on wealth, given to those in need. It purifies your wealth and soul. Allah pairs it with prayer again and again, for example {Q 2:43|establish prayer and give zakah}.

Who must pay: every adult, sane Muslim whose savings reach the nisab (minimum threshold) and who has held them for a full lunar year (the hawl), after deducting debts that are due.

The nisab is the value of 85 grams of gold or 595 grams of silver. The Prophet ﷺ set the silver nisab at five awqiyah, which is 200 dirhams ({H bukhari:1447|The Prophet said there is no zakat on less than five awaq of silver, nor on less than five camels or five wasqs of produce}). The gold nisab is 20 dinars, about 85 grams. Many scholars today use the silver measure, because it is lower and helps the poor; the Zakat calculator lets you choose.

The rate is 2.5% of the zakatable wealth on the day your year is complete.

What counts: cash, savings and money owed to you that you can collect, gold and silver (bullion, coins and stored jewelry), business stock and goods held for sale, and shares or investments held for trade. Your home, your car and tools for your work are not zakatable. Worn jewelry is a school matter (the Hanafi school counts it; the Maliki, Shafi'i and Hanbali schools do not).

The Zakat screen in this app works out the nisab and your zakat with these rules. It keeps your numbers on your device. For a complex case (pensions, a business, shares, rent), ask a scholar.
""",
  go=['/zakat', '/huda/guide?id=huda-zakat'],
  review='The nisab figures, the rate, and what is and is not zakatable are standard fiqh teaching and match the Zakat screen; only Bukhari 1447 (the silver measure) is cited.')

E('hajj-mahram',
  m=[r'\b(?:woman|women|female|lady|ladies|wife|girl|sister|mother)\b.*\b(?:hajj|umrah)\b.*\b(?:mahram|without|alone|husband|group|travel)\b',
     r'\b(?:hajj|umrah)\b.*\b(?:mahram)\b', r'\bmahram\b.*\b(?:hajj|umrah|travel)\b', r'\b(?:woman|women|female|lady)\b.*\b(?:travel\w*)\b.*\b(?:mahram|alone|without)\b',
     r'\btravel\w* without (?:a )?mahram\b', r'\bwoman travel\w*\b', r'\bwomen travel\w*\b', r'\bwhat is (?:a )?mahram\b', r'\bwho is (?:a )?mahram\b', r'\bmahram\b'],
  topic='mahram',
  text="""
A mahram is a man a woman can never marry because of blood, marriage or nursing (such as her father, brother, son, uncle, or her husband). The Prophet ﷺ said that a woman should not travel except with a mahram ({H bukhari:1862|Ibn Abbas reported the Prophet said a woman should not travel except with a mahram, and a man got up to say his wife was going for Hajj and he had enlisted for a battle, so the Prophet told him to go with his wife}) ({H muslim:1341|Ibn Abbas reported the Prophet said no one should be alone with a woman except when a mahram is with her, and the woman should not travel except with a mahram}).

On Hajj and Umrah, the schools differ:
- The Hanafi and Hanbali schools make the mahram a condition: a woman without one is not required to go on Hajj, and should not go.
- The Shafi'i and Maliki schools allow a woman to go in a safe group of trustworthy women when the road is safe, as a condition of ability.
- Today many scholars and authorities allow a woman to join an organised, safe pilgrimage group, relying on the safety of modern travel, while others still require the mahram. The authorities in charge of the pilgrimage also set their own entry rules, so check them before you book.

This is a real question with different opinions, so a woman in this position should ask a scholar she trusts. The Hajj is for those who are able ({Q 3:97|to Allah from the people is a pilgrimage to the House - for whoever is able to find thereto a way}).
""",
  go=['/academy/hajj-umrah-pack'],
  review='The school positions on the mahram for Hajj and the contemporary group-travel view are standard fiqh teaching and contested; flagged for scholar review.')

E('hajj-days',
  m=[r'\bdays? of hajj\b', r'\bhajj (?:days?|steps?|rites?|rituals?|schedule|timeline|itinerary|order|process|procedure)\b', r'\bwhat (?:happens|do (?:pilgrims|muslims|they) do) (?:on|during|in) hajj\b',
     r'\bsteps? (?:of|in|for) hajj\b', r'\bhow (?:to|do (?:i|we|you)) (?:perform|do) hajj\b', r'\brites? of hajj\b', r'\bpillars? of hajj\b', r'\bhow is hajj performed\b',
     r'\bwhen is hajj\b', r'\bwhich month is hajj\b', r'\bday of arafah\b', r'\barafah\b', r'\bmuzdalifah\b', r'\bmina\b', r'\bjamarat\b', r'\bstoning of the devil\b', r'\btawaf\b',
     r'\bsa i\b', r'\bsai\b', r'\bihram\b', r'\bmiqat\b', r'\btamattu\b', r'\bwhat is hajj\b', r'\bhajj (?:explained|basics|guide|for beginners)\b'],
  x=[r'\b(?:difference|vs|versus|compare)\b', r'\b(?:mahram|woman|women|female)\b'],
  topic='hajj',
  text="""
Hajj is the pilgrimage to Makkah, the fifth pillar of Islam, obligatory once in a lifetime for every Muslim who is able. Allah says: {Q 3:97|to Allah from the people is a pilgrimage to the House - for whoever is able to find thereto a way}. When the Prophet ﷺ told people it was obligatory and someone asked if it was every year, he stayed silent and then said that if he had said yes it would have been required, and it would have been too hard ({H muslim:1337|The Prophet told the people Allah had made Hajj obligatory; a man asked if it was every year, and he kept quiet three times and then said that had he said yes it would have been obligatory})

Hajj has fixed days in the month of Dhul Hijjah (the twelfth month):
- 8 Dhul Hijjah (Yawm at-Tarwiyah): enter ihram (for those in Makkah) and go to Mina, praying and spending the day and night there.
- 9 Dhul Hijjah (the Day of Arafah): stand at Arafah from after noon until sunset, in du'a and dhikr. This is the heart of Hajj; without it there is no Hajj. After sunset, go to Muzdalifah, pray Maghrib and Isha together, sleep there and collect pebbles.
- 10 Dhul Hijjah (Eid al-Adha): after Fajr, go to Mina and throw seven pebbles at the large pillar (Jamrat al-Aqabah), offer the sacrifice, shave or trim the hair (men), and go to Makkah for Tawaf al-Ifadah and the Sa'i of Safa and Marwah.
- 11, 12 (and 13 for those who stay) Dhul Hijjah: in Mina, throw seven pebbles at each of the three pillars each day after midday. Those in a hurry may leave on the 12th before sunset.
- Farewell tawaf at the Kaaba before leaving Makkah.

The main pillars (arkan) are ihram, standing at Arafah, Tawaf al-Ifadah and the Sa'i (the Hanafi school counts the Sa'i as wajib instead). There are three forms: Tamattu' (Umrah first, then Hajj), Qiran (both together) and Ifrad (Hajj alone). The Prophet ﷺ said that whoever performs Hajj for Allah's pleasure and avoids bad conduct returns as if newly born ({H bukhari:1521|The Prophet said whoever performs Hajj for Allah's pleasure and avoids sexual relations and sins returns as if born anew}).

The Hajj guides in this app cover each step in detail.
""",
  go=['/huda/guide?id=huda-hajj-overview', '/academy/hajj-umrah-pack'],
  review='The day-by-day order, the pillars and wajibs per school, and the forms of Hajj are standard fiqh teaching, not text-checked here.')

E('hajj-vs-umrah',
  m=[r'\bhajj\b.*\bumrah\b.*\b(?:difference|different|same|vs|versus|compare|between)\b', r'\b(?:difference|different|between)\b.*\bhajj\b.*\bumrah\b', r'\bumrah\b.*\bhajj\b.*\b(?:difference|different|same|vs|versus|compare|between)\b',
     r'\bwhat is umrah\b', r'\bumrah (?:steps?|rites?|rituals?|explained|guide|basics|how|process)\b', r'\bhow (?:to|do (?:i|we|you)) (?:perform|do) umrah\b', r'\bsmall hajj\b', r'\blesser pilgrimage\b',
     r'\bumrah (?:compulsory|obligatory|fard|mandatory|required|sunnah)\b', r'\bis umrah (?:compulsory|obligatory|fard|mandatory|required|sunnah)\b'],
  topic='umrah',
  text="""
Umrah is the "lesser pilgrimage": a shorter, voluntary journey to the Kaaba that can be done at any time of the year. Hajj is the major pilgrimage with fixed days, obligatory once on every Muslim who is able.

Umrah has four parts: (1) enter ihram at the miqat with the intention for Umrah, (2) circle the Kaaba seven times (tawaf), (3) walk between Safa and Marwah seven times (sa'i), (4) shave or trim the hair (men shave or trim; women trim a fingertip's length). That is all; it takes a few hours.

Hajj includes similar acts (ihram, tawaf, sa'i) but adds standing at Arafah, the night at Muzdalifah, stoning the pillars in Mina, and the sacrifice, over five or six fixed days in Dhul Hijjah.

The difference in ruling: Hajj is a pillar of Islam. Umrah is obligatory once for those able in the Shafi'i and Hanbali schools, and a strongly recommended sunnah in the Hanafi and Maliki schools. The Prophet ﷺ said that one Umrah is an expiation for the sins between it and the previous one, and the reward of an accepted Hajj is nothing less than Paradise ({H bukhari:1773|The Prophet said Umrah is an expiation for the sins committed between it and the previous one, and the reward of an accepted Hajj is nothing except Paradise}). Umrah does not replace Hajj.
""",
  go=['/huda/guide?id=huda-umrah', '/academy/hajj-umrah-pack'],
  review='The ruling on Umrah per school and the details of trimming are standard fiqh teaching, not text-checked here.')

E('credit-card',
  m=[r'\bcredit cards?\b', r'\bcharge cards?\b'],
  x=[r'\b(?:debt|nisab|zakat)\b'],
  topic='credit cards',
  text="""
A credit card is a loan tool, so the answer depends on how it is used, not on the plastic. The problem is interest (riba): {Q 2:275|Allah has permitted trade and has forbidden interest}, and the Prophet ﷺ cursed everyone involved in it ({H muslim:1598|Jabir said the Prophet cursed the accepter of interest, its payer, the one who records it and the two witnesses, and said they are all equal}).

- Carrying a balance that is charged interest is riba, and it is not allowed.
- Paying the full balance before any interest is charged: many contemporary scholars allow having and using the card on that basis, as long as you are sure you can pay in time and you do not take on interest or late charges you could avoid.
- Some scholars are stricter and say not to take a conventional card at all, because the agreement you sign states interest on late payment.
- Safer options: a debit card, a charge card that must be paid in full each month, or a card from an Islamic provider where one exists.

Which view to follow in your own case is for a qualified scholar. The Tayyib Finance section of this app lists halal options.
""",
  go=['/finance'],
  review='The two scholarly positions (allowed when paid in full; avoid the conventional card) are standard contemporary teaching, not text-checked here.')

E('riba-interest',
  m=[r'\briba\b', r'\binterest\b.*\b(?:haram|halal|islam|allowed|permissible|forbidden|prohibited|sin|bank|loan|mortgage|savings|account|credit)\b', r'\b(?:haram|halal|islam|allowed|permissible|forbidden|prohibited|sin)\b.*\binterest\b',
     r'\busury\b', r'\bbank interest\b', r'\binterest (?:on|from|in) (?:my )?(?:savings|bank|account|loan|deposit)\b', r'\bwhat to do with (?:bank )?interest\b', r'\bsavings account\b',
     r'\bcredit cards?\b', r'\bpersonal loans?\b', r'\bstudent loans?\b', r'\bcar loans?\b', r'\bis (?:it )?(?:haram|halal|ok|okay|allowed) to (?:take|get|have|use) (?:a )?(?:loan|credit)\b'],
  x=[r'\b(?:mortgage|house loan|home loan)\b'],
  topic='riba',
  text="""
Riba (interest, usury) is forbidden in Islam. Allah says: {Q 2:275|Allah has permitted trade and has forbidden interest}, and {Q 2:278-279|fear Allah and give up what remains [due to you] of interest, if you should be believers}. The Prophet ﷺ cursed the one who takes interest, the one who pays it, the one who records it, and the two witnesses ({H muslim:1598|Jabir said the Prophet cursed the accepter of interest, its payer, the one who records it and the two witnesses, and said they are all equal}).

What this covers: interest on loans and credit cards, interest on savings accounts and fixed deposits, and any agreement where a loan carries an extra amount stated in advance. Paying a late fee that grows with time is interest too.

What to do:
- Borrow only when needed, from interest-free sources first (family, a qard hasan loan from a community fund, an employer).
- Use a halal alternative: Islamic banks and finance firms (profit-sharing, lease-to-own, cost-plus sale), where available.
- A credit card that you pay off in full every month, so no interest is ever charged, is considered acceptable by many scholars, though some avoid cards with interest-bearing terms; ask a scholar.
- Interest your bank puts into your account: take it out and give it away to the poor or for public good, with no intention of reward for yourself (the view of most scholars today). Do not keep it. If you can, move to an interest-free account.
- If you are already in a loan with interest, you do not tear up the contract, but you repent, pay it off as soon as you can, and avoid new ones.

For mortgages, see the separate answer. Ask a scholar for your own situation. The Tayyib Finance section of this app lists halal options.
""",
  go=['/finance'],
  review='The treatment of bank interest (give it away), credit cards paid in full, and existing loans are contemporary-scholar positions; not text-checked here.')

E('mortgage',
  m=[r'\bmortgage\w*\b', r'\bhome loans?\b', r'\bhouse loans?\b', r'\bbuy(?:ing)? (?:a |my )?(?:house|home|property|flat|apartment)\b', r'\bhome financing\b', r'\bislamic mortgage\b', r'\bhalal mortgage\b', r'\bhome purchase\b'],
  topic='mortgage',
  text="""
A conventional mortgage charges interest, and interest (riba) is forbidden ({QR 2:275}), so most scholars say a conventional mortgage is not allowed.

Muslims living in Western countries are divided. Some contemporary scholars and councils allow a conventional mortgage as an exception when it is a real need (a family home, no halal option available, renting is not a realistic way to house the family), on the principle of necessity in Islamic law. Others say that necessity here is rare, the prohibition is firm, and renting is possible, so a conventional mortgage is not allowed. This is a genuine disagreement among scholars, and I will not pick one for you.

The widely accepted route is a halal home finance product: a diminishing partnership (musharakah), lease-to-own (ijarah) or cost-plus (murabaha) arrangement from an Islamic finance provider. These are structured so that no loan interest is charged. Ask a scholar to check the contract before you sign.

Meanwhile, saving for a larger deposit or renting a home is always allowed. For your own decision, please talk to a qualified scholar who knows the local options.
""",
  go=['/finance'],
  review='The scholars\' disagreement on conventional mortgages for Muslims in the West is described neutrally; flagged for scholar review.')

E('crypto-stocks-insurance',
  m=[r'\b(?:bitcoin|btc|ethereum|eth|crypto\w*|altcoin\w*|nft\w*|dogecoin|token\w*)\b', r'\b(?:stock|stocks|share|shares|equities|investing|investment|investments|day trading|forex|trading|options trading|etf|etfs|mutual funds?|index funds?|dividends?)\b.*\b(?:halal|haram|allowed|permissible|islam\w*|sharia|shariah|forbidden)\b',
     r'\b(?:halal|haram|allowed|permissible|islam\w*|sharia|shariah|forbidden)\b.*\b(?:stock|stocks|share|shares|equities|investing|investment|investments|day trading|forex|trading|options|etf|etfs|mutual funds?|index funds?|dividends?)\b',
     r'\b(?:insurance|takaful)\b', r'\bshort ?selling\b', r'\bmargin\b.*\btrading\b'],
  topic='investing',
  text="""
Bitcoin and other crypto: scholars disagree. Some say it is permitted as a commodity or digital asset, subject to the usual rules (no fraud, no interest, no gambling-style speculation). Others say it is not allowed because it has no real backing, is highly uncertain (gharar), and is mostly used for speculation. Because of this real difference, please ask a scholar you trust before you buy; do not buy something you do not understand.

Stocks and shares: owning a share in a real business is generally permitted by most contemporary scholars, if the business itself is halal (not alcohol, pork, gambling, interest-based banking, adult entertainment) and the share is not mostly debt-funded or interest-earning. Many halal screening services and Islamic funds exist for this. Day trading, margin trading, short selling, and options are widely seen as speculative or involving interest, and many scholars forbid them.

Insurance: conventional insurance has uncertainty and an element of gambling, and many scholars forbid it, while allowing what the law requires (such as car insurance) because of need. Takaful (cooperative insurance) is the Islamic alternative.

Everything here is general, and these are areas where scholarly opinions differ. Check with a qualified scholar or an Islamic finance advisor for your own money. The Tayyib Finance section may help.
""",
  go=['/finance'],
  review='Crypto, stock screening, trading and insurance are contested contemporary issues and are described neutrally; flagged for scholar review.')

E('gambling-lottery',
  m=[r'\b(?:gambl\w*|lotter\w*|casino\w*|betting|bet|bets|raffle\w*|poker|scratch cards?|sweepstake\w*|maysir|wager\w*|sports betting|loot box\w*)\b'],
  x=[r'\b(?:game|games|story|stories)\b.*\b(?:play|ludo|chess)\b'],
  topic='gambling',
  text="""
Gambling is forbidden in Islam. Allah says: {Q 5:90|intoxicants, gambling, [sacrificing on] stone alters [to other than Allah], and divining arrows are but defilement from the work of Satan, so avoid it that you may be successful}. In another verse, {Q 2:219|In them is great sin and [yet, some] benefit for people. But their sin is greater than their benefit}.

This includes casinos, betting on sports, lotteries, raffles where you pay and may win a prize, scratch cards, and games where you pay real money for chance outcomes (including loot boxes, according to many scholars). A prize won through gambling is haram money.

What is allowed: a fair prize in a skill contest where the prize is paid by a sponsor (not from the entrants' fees), and games for fun with no stake. If you have won money by gambling, many scholars say to give it away to the poor without expecting reward, and to repent and stop.
""",
  go=['/finance'],
  review='The handling of past winnings is the view of many scholars; not text-checked here.')
