# Verification log: Tahajjud, What Is Islam, Four Schools guides

Checked 23 Oct 2026. The three guides (`huda-tahajjud`, `huda-what-is-islam`, `huda-madhhab-overview` in `assets/guides/guides.json`) are labelled "not yet scholar-reviewed" in their Sources card. Nothing here replaces the named-scholar review in OWNER_ACTIONS item 4.

Method: Qur'an references were read in the app's own bundled text (`assets/quran/quran.json`, Saheeh International) and quotations are word for word (CI: `test/hadith/quran_refs_test.dart`). Hadith were opened on sunnah.com (narrator, chapter heading, content read). Verdicts are recorded in `tool/hadith_verdicts/r4guides.json` (CI: `test/hadith/hadith_citations_test.dart`). Other sources were opened as web pages; the page named is the page read.

## Tahajjud guide

| Citation | Source checked | Result |
|---|---|---|
| Qur'an 17:79 | bundled text (verb `fa-tahajjad` is in the Arabic) | verified, quoted |
| Qur'an 32:16 | bundled text | verified, quoted |
| Qur'an 51:17-18 | bundled text | verified, quoted |
| Qur'an 73:2 (quoted), 73:3-4 (paraphrased) | bundled text | verified |
| Sahih al-Bukhari 1145 | https://sunnah.com/bukhari:1145 | Abu Hurayrah, Allah descends in the last third of the night and calls; chapter "Offering Salat and invoking Allah in the last hours of the night" |
| Sahih Muslim 758 | https://sunnah.com/muslim:758 | Abu Hurayrah, same subject (page shows 758a); no grade shown |
| Sahih al-Bukhari 990 | https://sunnah.com/bukhari:990 | Ibn Umar, night prayer two by two, one rak'ah if dawn is feared. It does NOT say "make witr your last prayer" (the draft and the old Witr guide used it for that) |
| Sahih Muslim 767 | https://sunnah.com/muslim:767 | Aisha, began night prayer with two short rak'ahs |
| Sahih Muslim 768 | https://sunnah.com/muslim:768 | Abu Hurayrah, begin night prayer with two short rak'ahs |
| Sahih al-Bukhari 1147 | https://sunnah.com/bukhari:1147 | Aisha to Abu Salama: not beyond eleven in Ramadan or other months, four, four, three |
| Sahih al-Bukhari 998 | https://sunnah.com/bukhari:998 | Ibn Umar, "Make witr as your last prayer at night"; chapter "Witr as the last Salat". This is the right number for the line the draft gave as 990 |
| Sahih Muslim 1163 | https://sunnah.com/muslim:1163 | Abu Hurayrah, best prayer after the obligatory is the night prayer (page shows 1163a) |

Dropped or not stated (no source read):
- "Prayer after sleeping" as the definition of tahajjud (no lexicon or fiqh text opened; the guide says it does not state whether sleep must come first).
- "The last third is the best time" (the hadith reports the descent and the call, not a ranking).
- Any fixed rak'ah number as a rule, and any school's view on the count. Aisha's eleven is given only as her report.
- Draft item "Muslim about 767-768" is verified as 767 and 768 exactly; no other number was kept.

## What Is Islam guide

| Citation | Source checked | Result |
|---|---|---|
| Qur'an 3:19, 3:83, 3:84, 3:85, 33:40 | bundled text (Arabic shows `aslama` in 3:83 and `muslimun` in 3:84) | verified, quoted |
| Sahih al-Bukhari 8 | https://sunnah.com/bukhari:8 | Ibn Umar, Islam rests on five: testimony, prayer, zakat, Hajj, fasting Ramadan |
| Sahih Muslim 8 | https://sunnah.com/muslim:8 | Umar, hadith of Jibril: Islam, iman, ihsan (page shows 8a) |
| "Islam means surrender" | https://www.britannica.com/topic/Islam | page says the name Islam means "surrender" |

Dropped or not stated:
- The Arabic root of the word (the Britannica page does not discuss it; no lexicon was opened). The guide points only to the Qur'an's own use of the word in 3:83-84.
- The one-line definition from the draft is kept only as "put together from the sources in this guide (not a scholar's definition)"; each clause maps to 3:84, 3:19, 33:40 and Bukhari 8.

## Four Schools guide

| Citation | Source checked | Result |
|---|---|---|
| Sahih al-Bukhari 740 | https://sunnah.com/bukhari:740 | Sahl ibn Sa'd, people told to put the right hand on the left forearm in prayer |
| Hanafi below the navel; Shafi'i above the navel (Dorar adds: below the chest) | https://dorar.net/en/feqhia/76 and https://fiqh.islamonline.net/en/the-position-of-hands-in-prayer/ | both pages agree |
| Maliki hands at the sides (some Maliki scholars); Ahmad: both below and above the navel | islamonline page (commentary by Sheikh Ahmad Kutty; the page's top summary is machine generated and was not used) | attributed to that source in the guide; Dorar gives "choice is broad" for Ahmad |
| Prayer valid either way; Tirmidhi and Ibn al-Mundhir on the Companions | islamonline page, Sheikh Ahmad Kutty | attributed to him in the guide |
| "A school of thought within Islamic jurisprudence" | https://en.wikipedia.org/wiki/Madhhab | labelled a general reference, not a fiqh text |

Dropped or not stated:
- Any position table beyond this one example. Dorar and the islamonline page give no per-school hadith evidence (Dorar's footnotes are not in the text), and the Maliki and Hanbali placements differ between the two pages, so neither is stated as the school's position.
- Qunut and the opening supplication by school: not re-stated. The qunut differences already sit in the Witr guide, were not opened in a source for this task, and remain unverified.
- Founders and death years of the four imams (the Wikipedia page read does not give them; none was opened elsewhere).
- Evidence each school cites, and the book each position is taken from: needs the named scholar.

## Existing content changed because of what was found

- Witr guide (`huda-witr`): "make the witr your last prayer at night" was cited as Bukhari 990; the verified number is 998. The clause "never abandoned the witr, neither traveling nor resident" was also cited to 990, which does not say it. It now reads "reported as something the Prophet did not abandon" with no number (the policy: an unverifiable citation loses its number), here and in the Rawatib guide (`huda-nawafil`). If the owner or a scholar supplies a source, the number can return.
- Still unverified and untouched: the qunut positions by school in the Witr guide, and the school positions in other guides' madhhab notes.
