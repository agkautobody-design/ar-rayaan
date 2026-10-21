# Verification log: vc

Branch feat/verify-vc. Packs: assets/stories/ghayb.json, modernhadith.json, seerah.json. 34 chapters that were labelled "Seerah report (source not checked)" or "Hadith report (reference not checked)". Everything stays Not yet scholar-reviewed. No chapter or story was deleted; every heading is unchanged.

Method: Ibn Hisham (ed. al-Saqqa, shamela.ws/book/23833) pages opened one at a time with WebFetch (shamela page id = printed page + 23 in vol. 1, + 736 in vol. 2 as the site shows them); hadith opened one page at a time on sunnah.com with WebFetch (no HTTP 429 was hit). WebFetch returns a summary, so a claim was kept only where the summary stated it; a claim the summary did not show was removed or hedged. Verdicts for every hadith read are in tool/hadith_verdicts/vc.json.

Result: 34 of 34 chapters upgraded, 0 left unchecked.

- Seerah pack, Ibn Hisham read: 11 chapters (seerah-01, 02, 05, 08, 09, 15, 21, 23, 25, 26, 28) now labelled "Seerah report".
- Seerah pack, hadith only: seerah-29 (Bukhari 2739, 3092, 2068; Ibn Majah 2697 da'if per Darussalam). No seerah book passage, so the chapter label is removed and the story returns to its original label.
- Ghayb: 19 chapters, hadith read; chapter label removed, story sourceLabel back to Established.
- Modernhadith: 3 chapters, hadith read; chapter label removed, story sourceLabel back to Established.

Note for the lead: test/stories/story_labels_test.dart needs a row in docs/story_audit.md containing "Label: Seerah report. Read:" for each of the 11 stories above (the existing rows for them still describe the unchecked state). The text for each row is the "Read" line below.

| pack | story id | chapter | new label |
|---|---|---|---|
| ghayb | ghayb-2am-dajjal | 1 | chapter label removed (story back to its original label) |
| ghayb | ghayb-2am-hell | 1 | chapter label removed (story back to its original label) |
| ghayb | ghayb-2am-intercession | 1 | chapter label removed (story back to its original label) |
| ghayb | ghayb-2am-shroud | 1 | chapter label removed (story back to its original label) |
| ghayb | ghayb-2am-signs | 1 | chapter label removed (story back to its original label) |
| ghayb | ghayb-2am-where-allah | 1 | chapter label removed (story back to its original label) |
| ghayb | ghayb-2am-why | 1 | chapter label removed (story back to its original label) |
| ghayb | ghayb-2am-why-worship | 1 | chapter label removed (story back to its original label) |
| ghayb | ghayb-israfil | 1 | chapter label removed (story back to its original label) |
| ghayb | ghayb-jinn-listen | 1 | chapter label removed (story back to its original label) |
| ghayb | ghayb-jr-bridge | 1 | chapter label removed (story back to its original label) |
| ghayb | ghayb-jr-gravepunish | 1 | chapter label removed (story back to its original label) |
| ghayb | ghayb-jr-resurrection | 1 | chapter label removed (story back to its original label) |
| ghayb | ghayb-jr-soul | 1 | chapter label removed (story back to its original label) |
| ghayb | ghayb-jr-trumpet | 1 | chapter label removed (story back to its original label) |
| ghayb | ghayb-malak-mawt | 1 | chapter label removed (story back to its original label) |
| ghayb | ghayb-pb-delay | 1 | chapter label removed (story back to its original label) |
| ghayb | ghayb-pb-fame | 1 | chapter label removed (story back to its original label) |
| ghayb | ghayb-unseen-angels | 1 | chapter label removed (story back to its original label) |
| modernhadith | mh-marriage-half | 1 | chapter label removed (story back to its original label) |
| modernhadith | mh-society-muslim | 1 | chapter label removed (story back to its original label) |
| modernhadith | mh-soul-solitude | 1 | chapter label removed (story back to its original label) |
| seerah | seerah-01 | 1 | Seerah report |
| seerah | seerah-02 | 1 | Seerah report |
| seerah | seerah-05 | 1 | Seerah report |
| seerah | seerah-08 | 1 | Seerah report |
| seerah | seerah-09 | 1 | Seerah report |
| seerah | seerah-15 | 1 | Seerah report |
| seerah | seerah-21 | 1 | Seerah report |
| seerah | seerah-23 | 1 | Seerah report |
| seerah | seerah-25 | 1 | Seerah report |
| seerah | seerah-26 | 1 | Seerah report |
| seerah | seerah-28 | 1 | Seerah report |
| seerah | seerah-29 | 1 | chapter label removed (story back to its original label) |

## Per chapter

### ghayb / ghayb-2am-dajjal / chapter 1

- Read: Bukhari 3337, Muslim 2933 and Muslim 809 on sunnah.com; Muslim 2946 and 2937 were already verified on file (tool/hadith_verdicts)
- Removed or changed: 'every prophet after Nuh' (the hadith names Nuh and the prophets after him as warning; wording follows that); 'readable by the literate and illiterate alike' (not in Muslim 2933 as read); 'commanding the sky to rain and the earth to sprout, followed by a paradise-illusion and a fire that is actually coolness' (not re-read; removed); 'the first and last ten verses' (Muslim 809 as read has only the first ten); 'The greatest trial in history is also one of the shortest' and 'the chapter closes in days' (removed).
- New label: none (chapter label removed)

### ghayb / ghayb-2am-hell / chapter 1

- Read: Bukhari 6560 and Muslim 183 on sunnah.com (Abu Sa'id al-Khudri)
- Removed or changed: 'through intercession and then His own mercy' (Muslim 183 as read has the believers' plea and then Allah taking out a handful; wording follows that); 'the monotheists' (Bukhari 6560 says anyone with faith as small as a mustard seed); 'reports in Sahih al-Bukhari and Sahih Muslim; numbers not re-checked here' (numbers added).
- New label: none (chapter label removed)

### ghayb / ghayb-2am-intercession / chapter 1

- Read: Muslim 193, Muslim 183, Muslim 2732 and Abu Dawud 2522 on sunnah.com
- Removed or changed: 'he will say: I am the one for it' (Muslim 193 as read has the people coming to him and no such sentence); 'beneath the Throne' (no Throne in the text read); 'until the judgment begins' (not found); 'pulled out of the Fire by their bonds of faith' (now as Muslim 183 says); 'The believer who teaches a verse, carries a funeral, ... settles two Muslims — is building the same currency the great intercessors will spend. Start banking it tonight.' (no source; removed except the dua for an absent brother). Numbers added.
- New label: none (chapter label removed)

### ghayb / ghayb-2am-shroud / chapter 1

- Read: Bukhari 6507 on sunnah.com
- Removed or changed: 'a report (reference and grading not checked here) describes the believer at death being given good news from his Lord and wishing to meet Him' (now Bukhari 6507); 'The Companion in it is already known' (reworded); 'You will not be alone' (reworded: the sentence presumed more than the sources say).
- New label: none (chapter label removed)

### ghayb / ghayb-2am-signs / chapter 1

- Read: Bukhari 80, Bukhari 7121 and Muslim 8 on sunnah.com
- Removed or changed: 'A reported saying describes the Hour's signs following one another like beads falling from a string' (no collection found; removed together with its source line); 'music and distraction multiplied' (not found in Bukhari 80 / 7121; removed); 'the barefoot Bedouin' (the hadith says barefoot, destitute goat-herds); 'Every generation that reads them is closer than the one before, and none of them needed the date' (removed). Numbers added.
- New label: none (chapter label removed)

### ghayb / ghayb-2am-where-allah / chapter 1

- Read: Muslim 537 on sunnah.com (Mu'awiya ibn al-Hakam)
- Removed or changed: 'the Throne that the hadith describes as the greatest of creation' (not found; the Qur'an's 'angels carry the Throne' is cited instead); 'she pointed up' (the hadith as read has only her words); 'free her, for she is a believer' (the hadith says a believing woman); '2:255 Kursi' removed from sources (not used in the text); 'Muslim, number not re-checked' now Muslim 537.
- New label: none (chapter label removed)

### ghayb / ghayb-2am-why / chapter 1

- Read: Muslim 2865 on sunnah.com ('Iyad ibn Himar)
- Removed or changed: 'Allah says: I created My servants hanif — inclining to truth' as a direct quotation (the page presents it as the Prophet relaying what his Lord taught him; the wording is now a paraphrase); 'the purpose is relationship' (reworded); the claim that this is 'in the Qur'an's usage' of worship (turned into a labelled reflection).
- New label: none (chapter label removed)

### ghayb / ghayb-2am-why-worship / chapter 1

- Read: Muslim 162, Tirmidhi 2621 and Nasa'i 463 on sunnah.com
- Removed or changed: 'Reported in the Sunan of Tirmidhi and an-Nasa'i (reference and grading not checked here)' (numbers and grades added); 'Kings do not call twice. Yours calls five times, and waits.' (kept as reflection, not removed); 'with the reward of fifty' kept (Muslim 162 credits each as ten).
- New label: none (chapter label removed)

### ghayb / ghayb-israfil / chapter 1

- Read: Tirmidhi 2431 on sunnah.com (Abu Sa'id al-Khudri; hasan per al-Tirmidhi and Darussalam; it does not name Israfil)
- Removed or changed: 'Reports in the hadith literature name the angel of the Trumpet as Israfil' (the hadith read says only 'the one with the horn'; the name is now stated as not checked); 'the books have been bound, the graves filled for millennia' and 'because the matter that must happen first is the last person who will ever repent' (no source; the repentance point is kept only as a labelled reflection); 'still being delayed for your sake' (reworded).
- New label: none (chapter label removed)

### ghayb / ghayb-jinn-listen / chapter 1

- Read: Bukhari 773 on sunnah.com (Ibn Abbas)
- Removed or changed: 'the hadith literature places this at a recitation of Fajr (number not checked here)' (now Bukhari 773); 'carried the message to their nation' (kept as 'returned to their people', as the hadith says); 'The same recitation that hardens the arrogant softens the unseen' and 'When you recite aloud at Fajr, you may be preaching to an audience you cannot see — some of them believers since the seventh century' (no source; removed).
- New label: none (chapter label removed)

### ghayb / ghayb-jr-bridge / chapter 1

- Read: Muslim 183 (183a and 183b) on sunnah.com (Abu Sa'id al-Khudri)
- Removed or changed: 'a hadith ... earlier attributed to Sahih al-Bukhari without a number' (the 'thinner than a hair' wording is Abu Sa'id's own statement in Muslim 183, now cited as that); 'some walking, some crawling' (not found; replaced); 'your light will be according to the weight of your faith', the moon, star, lamp, spark, and the light on the big toe that 'shines and goes out' (a report whose source was not found in the six books; removed and replaced by 57:12); 'Even the smallest light crosses' (removed).
- New label: none (chapter label removed)

### ghayb / ghayb-jr-gravepunish / chapter 1

- Read: Bukhari 1374 and Muslim 1913 on sunnah.com
- Removed or changed: 'one who dies on a Friday, or who remembers Allah standing, sitting, and lying down — the morning and evening adhkar — and says the words of light after every prayer, is protected' (Tirmidhi, number not re-checked; not found, removed); 'the squeeze' (Bukhari 1374 as read has the widening of the grave and the hammers); 'proof the grave is an active station, not a metaphor' and 'Five minutes of adhkar is not superstition — it is the deed standing guard at your own grave's head' (removed). Added the ribat hadith Muslim 1913 as the named protection.
- New label: none (chapter label removed)

### ghayb / ghayb-jr-resurrection / chapter 1

- Read: Muslim 2790, Bukhari 6524, 6522 and 6532 on sunnah.com
- Removed or changed: 'mountains moved like drifting clouds (18:47)' (the verse says 'We will remove the mountains'); 'ground level as a bread-board' (the hadith says a white loaf of bread); 'a day the length of fifty thousand years of standing' (the verse does not say standing); 'mankind gathered in three companies — one walking, one riding, one dragged on their faces' (not found in Bukhari 6522, which was read; replaced by what it says); 'the sun will be brought near until the sweat reaches the middle of the ears' (Bukhari 6532 says mouths and ears and no sun is claimed).
- New label: none (chapter label removed)

### ghayb / ghayb-jr-soul / chapter 1

- Read: Muslim 1887 and Bukhari 6507 on sunnah.com
- Removed or changed: 'drop slipping from a waterskin' and 'passed upward from angel to angel with the greeting' (not found in the reports read); 'perched among the fruits of Paradise, then flying back to the throne-lamps' (now as Muslim 1887 has it); 'a report quoted in the later literature has the grave telling the believer that he was the most beloved to it' (not checked; removed); 'every soul is carried to its grave' (replaced by 100:9).
- New label: none (chapter label removed)

### ghayb / ghayb-jr-trumpet / chapter 1

- Read: Bukhari 4814 on sunnah.com (Abu Hurayrah)
- Removed or changed: 'reported in Sahih al-Bukhari and Sahih Muslim; numbers not re-checked here' (now Bukhari 4814 only, the one read); 'the narrator declined to say whether days, months or years' kept as the hadith has it.
- New label: none (chapter label removed)

### ghayb / ghayb-malak-mawt / chapter 1

- Read: Sahih al-Bukhari 6507 on sunnah.com (Ubada ibn al-Samit; Aisha's question; the believer's glad tidings)
- Removed or changed: 'as a drop slips from a waterskin' (the phrase was looked for in Abu Dawud 4753 and not found; removed); 'performed with the care of a duty owed to Allah — not a theft' (reworded to the verse); 'The same angel comes to the tyrant, and the taking is everything the first was not' (replaced by 8:50); 'In the whole library of the Unseen, no card makes the afterlife nearer than this one' (removed).
- New label: none (chapter label removed)

### ghayb / ghayb-pb-delay / chapter 1

- Read: Tirmidhi 2306 on sunnah.com (Abu Hurayrah; hasan gharib per al-Tirmidhi; marked Da'if in the translation)
- Removed or changed: The quotation 'Hasten to deeds before seven: before you are distracted by your livelihood...' (the hadith read lists seven different things; replaced by that list, paraphrased, with its grade); 'the delay is not neutral; every postponement trains the self to forget' (commentary, dropped); 'urgency without panic'.
- New label: none (chapter label removed)

### ghayb / ghayb-pb-fame / chapter 1

- Read: Muslim 1905 and Bukhari 660 on sunnah.com (Abu Hurayrah)
- Removed or changed: The order 'a scholar, a martyr, a generous man' (Muslim 1905 lists the martyr first); 'you were seen in the world, and your wage was paid there; what remains for you here is nothing' (the hadith as read has them dragged into the Fire; the quoted reply is not claimed); 'carried his knowledge for fame' (now: learned, taught and recited the Qur'an so that it would be said); 'That is the fame that pays' (removed). Number added to the Muslim citation.
- New label: none (chapter label removed)

### ghayb / ghayb-unseen-angels / chapter 1

- Read: Bukhari 6408, Muslim 2732, Muslim 2814 and Nasa'i 1282 on sunnah.com
- Removed or changed: 'no platform, no recording, no audience but Him' and 'row upon row rising out of sight' (not in the hadith); 'fill the sky above them' (now 'up to the lowest heaven', as the hadith says); 'Allah mentions them to those near Him' (the hadith has Allah speaking to the angels); the angel who says 'ameen' (Muslim 2732 as read has 'the same be for you too'); the companion 'from the angels' and 'one of light, one of whisper' (Muslim 2814 as read has only the jinn companion); the unnumbered 'angels lower their wings for the seeker of knowledge' source line (removed, not used in the text); 'blessings sent on the Prophet are conveyed to him' replaced by the Nasa'i 1282 wording on greetings.
- New label: none (chapter label removed)

### modernhadith / mh-marriage-half / chapter 1

- Read: Bukhari 5090 on sunnah.com (Abu Hurayrah); Qur'an 23:5-6 and 30:21 against assets/quran/quran.json
- Removed or changed: 'when the servant marries, he has completed half of his religion, so let him fear Allah in the remaining half' (al-Baihaqi; not a Kutub al-Sittah book, chain and grade could not be checked here; removed); 'Half the deen is not a wedding' (reworded). Replaced by Bukhari 5090 and 30:21, both checked. The hadith about 'half the deen' is in the sources as a real saying but was not verified.
- New label: none (chapter label removed)

### modernhadith / mh-society-muslim / chapter 1

- Read: Bukhari 10 (verified on file) and Bukhari 33 on sunnah.com (Abu Hurayrah)
- Removed or changed: 'there is no faith for the one without trustworthiness, and no religion for the one without a covenant' (al-Baihaqi, Shu'ab al-Iman; not a Kutub al-Sittah book and could not be checked; removed and replaced by Bukhari 33, which was read).
- New label: none (chapter label removed)

### modernhadith / mh-soul-solitude / chapter 1

- Read: Bukhari 731 on sunnah.com (Zayd ibn Thabit); Bukhari 3 already verified on file (Aisha; the start of revelation in Hira); Qur'an 7:205 against assets/quran/quran.json
- Removed or changed: 'the best prayer of a man is in his house, except the obligatory' as a quotation 'reported in the Sahih collections; number not re-checked' (now Bukhari 731, paraphrased as the hadith has it); 'seasons in the cave of Hira in chosen solitude (seerah)' (replaced by Bukhari 3); 'The Qur'an commands both gathering and retreat' (7:205 only commands private remembrance; reworded); 'Seerah: Ibn Ishaq' dropped from sources (no Ibn Ishaq passage was read).
- New label: none (chapter label removed)

### seerah / seerah-01 / chapter 1

- Read: Ibn Hisham (ed. al-Saqqa, shamela.ws/book/23833) vol. 1 pp. 43, 45, 52, 53, 54 (shamela ids 66, 68, 75, 76, 77) and p. 158 (id 181)
- Removed or changed: 'Christian ruler of Yemen' (religion not on the pages read; wording now 'had taken control of Yemen'); 'magnificent cathedral' (now 'church'); 'marched with elephants' (the page has one elephant); 'the Kabah humbled an empire'; 'From his first breath, history arranged itself around him'; 'the Arabs called that year forever after' (replaced by what Ibn Ishaq states: the birth in the Year of the Elephant). Added only what was read. 'defiled the church' (the page says a Kinani man went to the church and 'sat' or did something in it; worded neutrally).
- New label: Seerah report

### seerah / seerah-02 / chapter 1

- Read: Ibn Hisham vol. 1 pp. 158, 161-163, 165, 168, 169, 179 (shamela ids 181, 183-186, 188, 191, 192, 202)
- Removed or changed: 'her household blossomed', 'her flock fattened' (the pages have milk for the child, the camel's udder full and the donkey outpacing the caravan); 'pressed to keep the child an extra season' (the page has Amina saying Halimah had been eager to keep him); 'adored him'; 'council of Quraysh where no child had ever sat' (the page has a cushion in the shade of the Kaaba); 'guarded him for forty years' (no duration on the page read). Added Abd al-Muttalib's death at eight (some say ten).
- New label: Seerah report

### seerah / seerah-05 / chapter 1

- Read: Ibn Hisham vol. 1 p. 240 (id 263: Khadijah the first to believe; Ali, Zayd, Abu Bakr appear as section headings in the contents, in that order), p. 262 (id 285: three years hidden); Sahih al-Bukhari 4770 on sunnah.com (Safa, horsemen, Abu Lahab, Surah 111)
- Removed or changed: The meal for Banu Hashim and Ali's reply (Musnad Ahmad, number never verified, contested): removed and replaced with a sentence saying it was not checked. 'A woman, a youth, a freed slave, a merchant: the future of the ummah in miniature' (ages/status not on the pages read). 'Reported in Sahih al-Bukhari and Sahih Muslim' narrowed to Bukhari 4770, the one read.
- New label: Seerah report

### seerah / seerah-08 / chapter 1

- Read: Ibn Hisham vol. 1 pp. 350, 351, 352 (ids 373-375), 374-377 (ids 397-400)
- Removed or changed: 'until they surrendered Muhammad to be killed' and 'no sitting with them' (not on p. 350); 'for three years' and 'milk of a single she-camel' (not found); 'Khadijah's wealth drained away' and the historians counting the boycott among the causes of her death (not found); 'Muslims and non-Muslims among them alike' (not found); 'sickened by watching relatives starve' (not found); 'declared void by the very men who wrote it' (the page says it was torn, and its writer was Mansur ibn Ikrima, not those men); 'an empire's merchant aristocracy'. Added the editor's footnote on leaves.
- New label: Seerah report

### seerah / seerah-09 / chapter 1

- Read: Ibn Hisham vol. 1 pp. 321 (id 344), 333, 334, 335 (ids 356-358), 336, 337 (ids 359, 360)
- Removed or changed: 'the bishops, like professionals everywhere, asked about doctrine before character' (the page has the Negus asking what religion they had left their people for); 'the king and his priests wept until their beards were wet' (the text has the Negus's beard wet and the bishops wetting their scriptures); the quoted sentence 'go, for by Allah, I will never surrender you to them' as reported by Ahmad (number never verified; the Ibn Hisham text has the Negus telling the two envoys to go and refusing to surrender the Muslims); 'a king they had never met'; 'proof that truth recognizes truth across every border' (commentary, softened). The Musnad Ahmad citation was dropped from sources.
- New label: Seerah report

### seerah / seerah-15 / chapter 1

- Read: Ibn Hisham vol. 1 pp. 501, 502, 503, 504 (shamela ids 524-527) and p. 516 (id 539). The first Jewish clauses on p. 504 and the closing clauses on p. 503 were read; the clause 'Yathrib is sacred' is on p. 504
- Removed or changed: 'Within the first year' (no date on the page); 'one hand against any aggressor' (reworded to mutual support against an attacker, as the text has it); 'his own account is in the hadith literature' (replaced by the Ibn Ishaq account in Ibn Hisham); 'some clan leaders tested it from without, until the covenant's clauses were broken one by one and its sanctions came due one by one' (not read); 'For a time, Madinah lived the experiment' (not read); 'one city, many religions, one covenant' (commentary, reworded).
- New label: Seerah report

### seerah / seerah-21 / chapter 1

- Read: Ibn Hisham vol. 2 pp. 215, 216, 217, 218, 219, 220-225, 227, 228, 229, 231, 232, 233 (shamela ids 951-956, 957-962, 964, 966, 968-970); the account is Ibn Ishaq's
- Removed or changed: 'a side the armies could not cross — the lava fields and the palm groves' (the page read has only a place name behind the Muslims); 'advice of Salman the Persian' (now 'it is said', as Ibn Hisham words it); 'the believers dug through the cold nights' (not read); 'that is what the Persians do' attributed to the hypocrites at the edge (the page has the Quraysh horsemen calling it a stratagem the Arabs had not used; the hypocrite remark read is Mu'attib's, about Kisra and Caesar); 'Quraysh from the south, Ghatafan from the east' and 'chiefs of Banu Nadir' (the page names Jewish men of Banu al-Nadir and Banu Wa'il and the Quraysh and Ghatafan commanders); 'a bitter gale that blew for days' (the page has a cold wind on winter nights); 'freezing the besiegers' and 'without a battle being fought' (a duel and a crossing are narrated).
- New label: Seerah report

### seerah / seerah-23 / chapter 1

- Read: Ibn Hisham vol. 2 p. 606-607 (shamela ids 1343, 1344: the list of envoys and kings; p. 607 does not give the rulers' replies); Bukhari 2941 and 7 and 64 on sunnah.com
- Removed or changed: The quoted wording of the letter ('From Muhammad ... to Heraclius the Great of Rome') and 'you bear the sins of the peasants' (replaced with a paraphrase and the translator's gloss 'the tillers'); 'the Negus ... embraced Islam before he died' (not read); 'al-Muqawqis sent gifts and courtesy but not faith' (not read); 'Khaybar ... was taken in the same year' (not read; removed); 'after Hudaybiyyah ... last stage of the mission' (the hadith says during the truce; 'last stage of the mission' was not read); Heraclius 'did not convert' (not read; the hadith's end is not claimed). 'Questioned Abu Sufyan' kept, now cited to Bukhari 2941 (number checked).
- New label: Seerah report

### seerah / seerah-25 / chapter 1

- Read: Ibn Hisham vol. 2 pp. 437, 438, 442 (ids 1174, 1175, 1179), 478-480, 484-486 (ids 1215-1217, 1221-1223), 490 (id 1227), 537 (id 1274); Bukhari 4333 and 3231 on sunnah.com
- Removed or changed: 'a near-rout until the Prophet stood firm on his mule calling the fleeing ranks back' (the hadith has the Muslims retreating and the Prophet calling the Ansar; the mule is not in what was read); 'the spoils of Hunayn were the richest of the Prophet's life' (not read); 'the new Makkan elite' (the hadith says the Tulaqa'); 'they wept and said: yes, we are pleased' (the reply is not in Bukhari 4333); 'reported in Sahih al-Bukhari and Sahih Muslim' (narrowed to the one read); 'whose people had once turned him away' and 'the hope he voiced long before' (Bukhari 3231 is about the day Ibn Abd Yalil turned him away; the Arabic wording of 'descendants' replaced by the translation's wording); 'the siege was lifted' kept as 'the army departed', with the dream and the Prophet's words to Umar added from p. 484.
- New label: Seerah report

### seerah / seerah-26 / chapter 1

- Read: Ibn Hisham vol. 2 pp. 515, 516, 517 (shamela ids 1252-1254); Bukhari 4418 on sunnah.com
- Removed or changed: 'news came that the Byzantines were massing at the northern border' (Ibn Hisham p. 516 has only the order to prepare to fight the Romans); 'the orchards heavy and the harvest calling' kept as the ripe fruit and shade; 'by order of the Prophet' kept and cited; 'the entire city' (the hadith has the Muslims told not to speak to the three); 'his two companions' named from the hadith; 'Tabuk was the last expedition of the Prophet's life' (not in the pages read; removed); 'even its greatest men' (reworded); 'written into the Qur'an for all time' (reworded). 'even its greatest men' / 'a man who had fought alongside the Prophet' (not read; reworded to believers who stayed behind without excuse).
- New label: Seerah report

### seerah / seerah-28 / chapter 1

- Read: Ibn Hisham vol. 2 pp. 606, 642, 643, 649, 650, 651, 652, 653, 655 (shamela ids 1379-1392); Bukhari 3668 and 4437 on sunnah.com; birth on Monday: vol. 1 p. 158
- Removed or changed: 'The fever came in Safar of the eleventh year' (Ibn Ishaq: last nights of Safar or start of Rabi' al-Awwal; the year not read); 'sometimes joining the prayers seated' (only the Monday Subh scene was read); 'in the same breath: the prayer, or the Companion above'; 'may my father and mother be sacrificed for you; by Allah, Allah will never cause you to die twice' and 'kissed his forehead' (not found in what was read; Bukhari 3668 has a kiss and praise in life and death); 'the mosque of Madinah filled with weeping'; 'porch of Banu Sa'ida' (the hadith says shed); 'the room of the wife he loved most, among his family, on his own bed, at peace' (reworded to Aisha's house and her day); 'raised his eyes and said: rather, the Highest Companion' (Bukhari 4437 has him looking at the ceiling after waking and asking to be with the highest companion). Hadith numbers now given where read.
- New label: Seerah report

### seerah / seerah-29 / chapter 1

- Read: Sahih al-Bukhari 2739, 3092, 2068 and Sunan Ibn Majah 2697 on sunnah.com
- Removed or changed: 'a mended cloak, a couch of palm-fiber that left marks on his side, a handful of barley' (not read); 'his shield was still in pawn' (Bukhari 2068 says he bought grain on credit with his armour as pledge; whether it was still pawned at death was not read); 'He left no son to inherit his authority'; 'Within thirty years ... within a century ... over a billion' (history, not sourced); 'the tradition forbids his image ... no monument to Muhammad except the practice of his message'; 'I have only been sent to perfect noble character (Ahmad; number not verified)'. Last counsel kept with Ibn Majah 2697 (da'if per Darussalam). The chapter has no seerah book passage, so no Seerah label; the story returns to its original label.
- New label: none (chapter label removed)
