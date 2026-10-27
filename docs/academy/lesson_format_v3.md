# Academy v3 lesson format

Lessons live in `assets/academy/lessons_v3/<course>.json` (one file per course, so parallel authors never conflict) and REPLACE the manifest lesson with the same id. A lesson not found there plays exactly as before. Files are found through the asset manifest; no list to edit. Phrase files live in `assets/academy/phrases/<author>.json`.

## Rules
- Arabic is never typed into a lesson. A step names a phrase (`shahada.full`), an ayah (`q:1:2`, range `q:1:1-4`) or one word (`q:1:2#3`, `shahada.tawhid#0`). The Arabic comes from `assets/quran/quran.json` or from `assets/academy/phrases/*.json`.
- Every phrase has `sources`, `status` (`verified`|`unverified`; unverified phrases cannot be shown) and `needsScholarReview`. Rebuild/verify with `python3 tool/academy_phrases.py build|verify` (needs network).
- A `hear it` button appears only for ayat (real recitation audio). Hadith phrases show a note that no recording exists.
- Labels: `[Established]` needs a `source`; `[Interpretive]`; `[Reflection]`. Madhab differences use `contrast` rows.
- No points, streaks, coins, badges (validator fails on those words). Gates never trap: after 2 misses the answer is shown, and the item returns once at the end of the check.
- Every wrong option has `reteach` text and `back` (an EARLIER step id). `lookback: "<lessonId>#<itemId>"` reuses an earlier lesson's item (no `back`).
- Citations must pass `tool/hadith_check.py` (add verdicts to `tool/hadith_verdicts/<yours>.json`; Sunan citations need the grader named within 140 characters) and `tool/quran_ref_check.py`.
- Review: a completed lesson is queued in the existing FSRS queue; a review asks 4 of the lesson's check items (`review: false` excludes one).

## File
```json
{"schema": 3, "course": "the-path", "lessons": [{"id": "path.u0.l1", "title": "...", "minutes": 15, "intro": "...", "steps": [ ... ]}]}
```
8 to 15 steps, 8+ check items, at least one gating step (check/arrange/match) and one `recap`.

## Step kinds (all have `id`, `kind`, optional `label`, `source`, `review`)
| kind | fields |
|---|---|
| `teach`, `why`, `story` | `title`, `body` (string or list), `bullets`, `quran` (ayah ref shown with Arabic) |
| `say` | `refs` (phrases/ayat), `title`, `note`, `words` (for ayat: `{"q:1:2": [{"tr","en"}, ...]}`, one per Arabic word) |
| `listen` | `ref` (ayah/range, real audio), `repeats` 1-5, `title`, `note` |
| `howto` | `steps: [{text, count, detail}]`, `intro`, `mistakes` |
| `contrast` | `rows: [{name, text}]`, `intro`, `agree`, `closing` (label defaults `[Interpretive]`) |
| `arrange` | `prompt`, `items` in CORRECT order `[{text, why, back}]`, `explain` (gates) |
| `match` | `prompt`, `pairs: [{left, right, why, back}]`, a face is `{text}`, `{ref}` or `{word}` (gates) |
| `check` | `items` (gates). Item: `id`, `q`, `type` mcq/fill/scenario, `options` (`text`/`word`/`ref`; wrong ones carry `reteach`, `back`), `answer`, `explain`, `scenario`, `fill: {ref, blank, show: arabic|translit}`, `review` |
| `recap` | `canDo` (3+), `next` |
| `doit` | `title`, `body`, `route` (`/prayer` `/qibla` `/quran` `/quran/<1-114>` `/hadi` `/calendar` `/adhkar` `/academy/hifz`), `button` |

Code: `lib/features/academy/domain/v3/` (pure Dart), screens in `presentation/lesson_v3_screen.dart` and `presentation/v3/`. Tests: `test/academy_v3_test.dart`.

## Needs scholar review
Every phrase in `assets/academy/phrases/foundation.json` (all `verified`: Arabic found letter for letter in the cited hadith; the rest is the author's wording):
- `shahada.tawhid`: Arabic copied from Muslim 403 (fawazahmed0/hadith-api, ara-muslim); transliteration, meaning and word glosses are the author's own.
- `shahada.risala`: Arabic copied from Muslim 403 (fawazahmed0/hadith-api, ara-muslim); transliteration, meaning and word glosses are the author's own.
- `takbir`: Arabic copied from Muslim 379 (fawazahmed0/hadith-api, ara-muslim); transliteration, meaning and word glosses are the author's own.
- `ruku.tasbih`: Arabic copied from Muslim 772 (fawazahmed0/hadith-api, ara-muslim); transliteration, meaning and word glosses are the author's own.
- `rise.sami`: Arabic copied from Bukhari 689 (fawazahmed0/hadith-api, ara-bukhari); transliteration, meaning and word glosses are the author's own.
- `rise.rabbana`: Arabic copied from Bukhari 689 (fawazahmed0/hadith-api, ara-bukhari); transliteration, meaning and word glosses are the author's own.
- `sujud.tasbih`: Arabic copied from Muslim 772 (fawazahmed0/hadith-api, ara-muslim); transliteration, meaning and word glosses are the author's own.
- `between.rabbighfir`: Arabic copied from Abu Dawud 874 (graded by al-Albani; fawazahmed0/hadith-api, ara-abudawud); transliteration, meaning and word glosses are the author's own.
- `tashahhud.1`: Arabic copied from Bukhari 831 (fawazahmed0/hadith-api, ara-bukhari); transliteration, meaning and word glosses are the author's own.
- `tashahhud.2`: Arabic copied from Bukhari 831 (fawazahmed0/hadith-api, ara-bukhari); transliteration, meaning and word glosses are the author's own.
- `tashahhud.3`: Arabic copied from Bukhari 831 (fawazahmed0/hadith-api, ara-bukhari); transliteration, meaning and word glosses are the author's own.
- `tashahhud.4`: Arabic copied from Bukhari 831 (fawazahmed0/hadith-api, ara-bukhari); transliteration, meaning and word glosses are the author's own.
- `salawat.1`: Arabic copied from Bukhari 3370 (fawazahmed0/hadith-api, ara-bukhari); transliteration, meaning and word glosses are the author's own.
- `salawat.2`: Arabic copied from Bukhari 3370 (fawazahmed0/hadith-api, ara-bukhari); transliteration, meaning and word glosses are the author's own.
- `salam`: Arabic copied from Abu Dawud 996 (graded by al-Albani; fawazahmed0/hadith-api, ara-abudawud); transliteration, meaning and word glosses are the author's own.
- `amin`: Arabic copied from Bukhari 780 (fawazahmed0/hadith-api, ara-bukhari); transliteration, meaning and word glosses are the author's own.
- `wudu.bismillah`: Arabic copied from Nasa'i 78 (graded by al-Albani; fawazahmed0/hadith-api, ara-nasai); transliteration, meaning and word glosses are the author's own.
- `wudu.dua.1`: Arabic copied from Muslim 234.02 (fawazahmed0/hadith-api, ara-muslim); transliteration, meaning and word glosses are the author's own.
- `wudu.dua.2`: Arabic copied from Muslim 234.02 (fawazahmed0/hadith-api, ara-muslim); transliteration, meaning and word glosses are the author's own.
- `dhikr.1`: Arabic copied from Abu Dawud 832 (graded by al-Albani; fawazahmed0/hadith-api, ara-abudawud); transliteration, meaning and word glosses are the author's own.
- `dhikr.2`: Arabic copied from Abu Dawud 832 (graded by al-Albani; fawazahmed0/hadith-api, ara-abudawud); transliteration, meaning and word glosses are the author's own.
- `dhikr.3`: Arabic copied from Abu Dawud 832 (graded by al-Albani; fawazahmed0/hadith-api, ara-abudawud); transliteration, meaning and word glosses are the author's own.
- `dhikr.4`: Arabic copied from Abu Dawud 832 (graded by al-Albani; fawazahmed0/hadith-api, ara-abudawud); transliteration, meaning and word glosses are the author's own.
- `dhikr.5`: Arabic copied from Abu Dawud 832 (graded by al-Albani; fawazahmed0/hadith-api, ara-abudawud); transliteration, meaning and word glosses are the author's own.

Lesson steps flagged by the author:
- `path.u0.l1/half1`: Explanation of the meaning of la ilaha illa Allah (the word ilah). Standard, but worded by the app author.
- `path.u0.l1/half2`: Explanation of what believing in the Messenger means (trust, obey, avoid, worship as taught). Standard, but worded by the app author.
- `path.u0.l1/howto`: Practical guidance on how a person enters Islam: no witness or ceremony required (general scholarly view); ghusl required or recommended (schools differ).
- `path.u1.l1/steps`: The limits of the face, wiping the ears, and the “to the elbows/ankles includes the elbows/ankles” wording follow the common teaching of the schools. Please confirm.
- `path.u1.l1/madhab`: Each row states the commonly taught position of each school on a wudu question. Needs a scholar to confirm the wording of every row.
- `path.u1.l1/breaks`: List of what breaks wudu and the statement that doubt does not break it. Standard, but worded by the app author.
- `path.u2.l1/times`: The rak’ah counts are the consensus of all four schools. Bukhari 350 shows prayer was first two rak’ahs, then increased for the resident. Please confirm the wording.
- `path.u2.l1/before`: Practical preparations for prayer. Please confirm that nothing here is out of line with the four schools.
- `path.u2.l1/flow`: The counts of 3 for bowing and prostration are the usual sunnah. The sitting between the two prostrations and the short surah after Al-Fatihah follow common teaching. Please confirm.
- `path.u2.l1/madhab`: Each row states the commonly taught position of each school. Needs a scholar to confirm the wording of every row.
- `path.u3.l1/madhab`: Each row states the commonly taught position of each school on Al-Fatihah in prayer. Needs a scholar to confirm each row.

Every `contrast` step (madhab rows) and every explanation written by the app author; the app already shows "Scholar review needed".

## Illustration needs (none used yet; silhouette figures, no faces)
Wudu: each of the 9 steps (hands, mouth, nose, face, arms, head and ears, feet). Salah: standing with hands raised, hands folded (3 school variants), bowing, standing up, prostration (seven parts touching), sitting between, tashahhud sitting, salam turning head. Qibla/prayer-mat setup.

## Needs scholar review: Aqeedah, Understanding the Qur’an, Da’wah (courses aqid, und, daw)
Files: `assets/academy/lessons_v3/aqid.json` (10 lessons), `und.json` (9), `daw.json` (11); phrases in `assets/academy/phrases/aqid-und-daw.json` (built and re-verified by `python3 tool/academy_phrases_aqid_und_daw.py build|verify`; Arabic is cut by word position from the cited hadith, never typed). Hadith verdicts: `tool/hadith_verdicts/aqid_und_daw.json`.

Phrases (every one has `needsScholarReview: true`; transliteration, meaning and word glosses are the author’s own):
- `aqid.mercy`: Bukhari 7404; Muslim 2751 (the same teaching in another wording)
- `aqid.names99.1`: Bukhari 2736; Muslim 2677 (the same teaching in another wording)
- `aqid.names99.2`: Bukhari 2736
- `aqid.prophets.1`: Bukhari 3443; Muslim 2365 (the same teaching in another wording)
- `aqid.prophets.2`: Bukhari 3443; Muslim 2365 (the same teaching in another wording)
- `aqid.iman.1`: Muslim 8 (the hadith of Jibril)
- `aqid.iman.2`: Muslim 8 (the hadith of Jibril)
- `aqid.ihsan.1`: Muslim 8 (the hadith of Jibril); Bukhari 50 (the same teaching in another wording)
- `aqid.ihsan.2`: Muslim 8 (the hadith of Jibril); Bukhari 50 (the same teaching in another wording)
- `aqid.zulm.1`: Muslim 2577
- `aqid.zulm.2`: Muslim 2577
- `daw.convey`: Bukhari 3461
- `daw.ease.1`: Bukhari 69
- `daw.ease.2`: Bukhari 69
- `daw.gentle.1`: Muslim 2594
- `daw.gentle.2`: Muslim 2594
- `daw.nasiha`: Muslim 55
- `daw.believer.1`: Muslim 2999
- `daw.believer.2`: Muslim 2999
- `daw.believer.3`: Muslim 2999
- `daw.dua.daws`: Bukhari 2937; Muslim 2524 (the same prayer in another wording)
- `und.best`: Bukhari 5027
- `und.beautify`: Abu Dawud 1468 (graded sahih by al-Albani)
- `und.consistent`: Bukhari 6464
- `und.proof`: Muslim 223
- `und.taawwudh`: Bukhari 3282

Lesson steps flagged by the author (the explanation is the app author’s wording, or the point needs a scholar):
- `aqid.u1.l1/mercy`: The meaning of 55:1-4 is summarised from Tafsir Ibn Kathir (English text in the spa5k tafsir archive). Please confirm the wording.
- `aqid.u1.l1/ikhlasmeaning`: Explanation of Ahad, As-Samad and kufuwan from Tafsir Ibn Kathir (including the report from Ibn Abbas). Please confirm.
- `aqid.u1.l1/loved`: The last sentence (what “a third of the Qur’an” means) is the common explanation, worded by the app author. Please confirm.
- `aqid.u1.l1/method`: A practical method for learning aqeedah, worded by the app author. Please confirm that nothing here goes against any of the Sunni schools of creed (Athari, Ashari, Maturidi).
- `aqid.u1.l2/p1`: Plain-words summary of the first two of the ten statements in Tafsir Ibn Kathir. Please confirm.
- `aqid.u1.l2/p4`: The explanation of Kursi (report from Ibn Abbas that it is the footstool) is from Tafsir Ibn Kathir. Scholars of different schools of creed explain such descriptions differently. Please confirm the wording.
- `aqid.u1.l3/twice`: The statement that every surah except At-Tawbah opens with the basmala is a standard fact about the Qur’anic text; please confirm.
- `aqid.u1.l3/difference`: Summary of the difference between Ar-Rahman and Ar-Raheem from Tafsir Ibn Kathir (Abu Ali al-Farisi, al-Azrami). The last “simple way to remember” sentence is the app author’s. Scholars hold other views too. Please confirm.
- `aqid.u1.l4/meaning`: (1) The range of explanations of ahsaaha, (2) the statement that al-Nawawi says the hadith does not limit Allah’s names to ninety-nine, and (3) the statement that scholars’ lists differ, are standard but worded by the app author and not checked against the original commentaries. Please confirm.
- `aqid.u1.l4/learn`: “Scholars say we call Allah only by names He or His Messenger gave Him” is the common position (the names are taken from revelation). Please confirm.
- `aqid.u2.l1/chain`: The order Adam, Nuh, Ibrahim, Musa, Isa, Muhammad is the commonly taught order. Musa is placed by the order of the books (the Torah before the Gospel); please confirm the wording.
- `aqid.u2.l1/answer`: A practical approach worded by the app author. The belief that earlier books were changed is the common Sunni teaching; please confirm the phrasing.
- `aqid.u2.l2/schools`: A short beginner summary of Ashari, Maturidi and Athari positions on qadar, worded by the app author. Please check each row.
- `aqid.u2.l3/count`: The count of twenty-five named prophets is the common teaching, and scholars differ on a few names such as Dhul-Kifl. The app does not use the often-repeated figure of 124,000 prophets, because the hadith that gives it is not sound. Please confirm the wording.
- `aqid.u2.l3/ibrahim`: That Ibrahim was arguing with his people (not truly doubting) is the explanation many scholars give, supported by 6:83. Please confirm it fits the Sunni tafsir tradition as worded.
- `aqid.u2.l3/safe`: Practical guidance worded by the app author. The rule about not showing images is the app’s policy. Please confirm.
- `aqid.u3.l1/start`: The grouping into general and special “withness” is a common way scholars explain these ayat. Please confirm the wording and that it does not go beyond Ibn Kathir.
- `aqid.u3.l1/closer`: Ibn Kathir reads the nearness in 50:16 as the angels; others read it as knowledge. Please confirm the wording and that the dispute is stated fairly.
- `aqid.u3.l1/schools`: Short beginner summary of the Athari and Ashari/Maturidi positions on the “with you” ayat and istiwa. Please check each row, and add the Maturidi view if it should be a separate row.
- `aqid.u3.l1/close`: A practical note worded by the app author. The safety sentence is deliberate. Please keep it or reword it.
- `aqid.u3.l2/amend`: A practical sequence based on Bukhari 2449 and the general teaching on repentance, worded by the app author. The last step, charity on their behalf, should be confirmed by a scholar.
- `und.u1.l1/start`: The link between the word Qur’an and the root of iqra is the common linguistic explanation; some scholars give other derivations. Please confirm the wording.
- `und.u1.l2/views`: A short beginner summary of the purposes of the two steps. Please confirm the wording; the topic of the ahruf is deliberately left out.
- `und.u1.l3/easy`: The second and third sentence give an explanation of 54:17 in the app author’s words. Please confirm.
- `und.u1.l3/schools`: This row-by-row summary of the four schools on reciting in a language other than Arabic in prayer is from general knowledge, not a quoted source. It needs a scholar to confirm each row, especially the Hanafi row.
- `und.u2.l1/start`: The distinction between the Qur’an and a translation of its meanings is the common scholarly position. Please confirm the wording.
- `und.u2.l1/muttaqin`: Examples of how translators render muttaqeen are given without naming translators. Please confirm they are fair examples.
- `und.u2.l1/read`: Practical guidance worded by the app author. Please confirm.
- `und.u2.l2/carefully`: The last sentence is an explanation by the app author. Please confirm.
- `und.u2.l2/slow`: Practical guidance worded by the app author. Please confirm.
- `und.u2.l3/who`: Summarised from Ibn Kathir (English text in the spa5k tafsir archive). Please confirm that this represents his words fairly.
- `und.u2.l3/manners`: The connection between the ayah and manners is the position of many scholars, but the ayah itself is understood by others as not being about wudu. Please confirm the wording.
- `und.u2.l3/schools`: The positions of the four schools, the Zahiri view and the modern views on screens are from general knowledge, not from a quoted source. They need a scholar to confirm, row by row.
- `und.u2.l3/begin`: Practical manners worded by the app author. The third and fifth steps are common manners but have no specific text here.
- `und.u3.l1/abdullah`: The advice on the speed of finishing is given as a hadith report. How scholars apply it (for example in Ramadan) varies; please confirm the wording.
- `und.u3.l1/why`: The conclusion drawn from the hadith is the app author’s explanation. Please confirm.
- `und.u3.l2/start`: The last sentence (what scholars take healing to include) is a general summary. Please confirm.
- `und.u3.l2/medicine`: The second paragraph is the app author’s practical advice. The safety sentence is deliberate. Please keep it or reword it.
- `und.u3.l2/use`: Practical guidance worded by the app author. Please confirm.
- `und.u3.l3/forms`: Summarised from Ibn Kathir (English text in the spa5k tafsir archive). Please confirm that it is fair.
- `daw.u1.l1/quran`: The older lesson text said Mus’ab was sent with “the shahada”; Bukhari 3925 says he taught the Qur’an. The text now follows the hadith.
- `daw.u1.l1/begin`: Practical guidance worded by the app author. Please confirm.
- `daw.u1.l2/three`: The explanation of the three terms is a common summary. Please confirm the wording.
- `daw.u1.l2/answers`: The reports are verbatim from the corpus. The explanation that the answers suit the person or time is a common scholarly reading but not in the hadith text; please confirm.
- `daw.u1.l3/details`: The link of the day of Aqaba to Ta’if and the stoning story are seerah reports that this app has not verified against a hadith collection. The lesson says so. Please confirm the wording.
- `daw.u1.l3/mock`: Practical guidance worded by the app author. Please confirm.
- `daw.u1.l4/heraclius`: The al-Amin title is a seerah report that has not been verified against a hadith collection. The lesson says so. Please confirm.
- `daw.u1.l4/say_do`: The second sentence is the app author’s explanation. Please confirm.
- `daw.u2.l1/limits`: Guidance worded by the app author on how to speak about hardship. Please confirm that it is consistent with the Sunni teaching.
- `daw.u2.l1/sit`: Practical guidance worded by the app author. The last step is deliberate. Please confirm.
- `daw.u2.l2/limits`: The first paragraph is a general summary of how ease works within obligations. Please confirm that it is stated correctly.
- `daw.u2.l2/describe`: Practical guidance worded by the app author. Please confirm.
- `daw.u2.l3/challenge`: The description of the challenge as a ladder and its audience is a common summary. Please confirm the wording.
- `daw.u2.l3/rebuke`: The argument from self-correction is a commonly made argument, not a ruling. Please confirm that it is stated fairly.
- `daw.u2.l3/jubayr`: The last sentence is the biographers’ report that Jubayr later became Muslim; it is well known but not in this hadith. Please confirm.
- `daw.u2.l3/talk`: Practical guidance worded by the app author. Please confirm.
- `daw.u2.l4/repent`: The last sentence about fear being a sign of life is the app author’s reflection. Please confirm.
- `daw.u2.l4/amr`: The second paragraph is a general summary that sincere repentance is the way for a Muslim. Please confirm.
- `daw.u2.l4/respond`: Practical guidance worded by the app author, including the conditions of repentance as commonly taught. Please confirm. The last step is deliberate.
- `daw.u3.l1/calm`: Practical guidance worded by the app author. Please confirm.
- `daw.u3.l2/say_dont_know`: Practical guidance worded by the app author. Please confirm.
- `daw.u3.l2/unsure`: Practical guidance worded by the app author. Please confirm.

Every `contrast` step in these courses (creed schools on qadar and on “with you”; the four schools on reciting in another language in prayer and on touching the mushaf) is from general knowledge and needs a scholar to confirm each row.

Not verified against a hadith collection, so not used as proof: the title al-Amin; the link of the day of Aqaba (Bukhari 3231) to Ta’if and the stoning story; the habit of reciting Ayat al-Kursi after each prayer (its source is outside the six books); the count of 25 named prophets (counts differ); the 124,000 prophets figure is deliberately NOT used (its hadith is weak).

## Illustration and audio needs (aqid, und, daw)
- Illustrations: none are used. Silhouette-only figures (no faces) would help: the cave of Hira scene (und.u1.l1), the cave of Thawr scene (aqid.u3.l1), the mushaf held with care (und.u2.l3), a person talking with another person (daw.u1.l1, daw.u1.l2).
- Audio: only ayat have recordings. Hadith phrases (for example `aqid.iman`, `daw.believer`, `und.beautify`) show a note that no recording exists yet; a recording of each would help.
- App gaps (owned by others): there is no `doit` route for the Names deck, the stories or the hadith pages, so those lessons point to the Qur’an reader.

## Family, Youth, Transactions courses (needs scholar review)

Phrases (Arabic copied from the cited hadith in fawazahmed0/hadith-api; transliteration, meaning and glosses are the author's own; all marked for scholar review):
- `fam.nikah.barak`: Tirmidhi 1091 (graded sahih by al-Albani)
- `fam.child.refuge`: Bukhari 3371 (the Prophet said this over his grandsons Hasan and Husayn)
- `fam.hamd`: Bukhari 6224 (the words)
- `fam.sneeze.reply`: Bukhari 6224
- `fam.sneeze.back`: Bukhari 6224
- `fam.eat.bismillah`: Abu Dawud 3767 (graded sahih by al-Albani)
- `fam.eat.forgot`: Abu Dawud 3767 (graded sahih by al-Albani)
- `yth.love.1`: Abu Dawud 5125 (graded hasan by al-Albani)
- `yth.love.2`: Abu Dawud 5125 (graded hasan by al-Albani)
- `trx.halal.1`: Tirmidhi 3563 (graded hasan by al-Albani and Darussalam)
- `trx.halal.2`: Tirmidhi 3563 (graded hasan by al-Albani and Darussalam)
- `trx.halal`: Tirmidhi 3563 (graded hasan by al-Albani and Darussalam)
- `trx.worry.1`: Bukhari 6369
- `trx.worry.2`: Bukhari 6369
- `trx.worry.3`: Bukhari 6369
- `trx.worry.4`: Bukhari 6369
- `trx.worry`: Bukhari 6369
- `trx.repay.1`: Nasa'i 4683 (graded sahih by al-Albani; hasan by Zubair Ali Zai)
- `trx.repay.2`: Nasa'i 4683 (graded sahih by al-Albani; hasan by Zubair Ali Zai)
- `trx.repay`: Nasa'i 4683 (graded sahih by al-Albani; hasan by Zubair Ali Zai)
- `trx.barakah.early`: Tirmidhi 1212 (graded sahih by al-Albani)

Lesson steps flagged by the author:
- `fam.u1.l1/ruling`: The ruling on marriage by situation and the wording per school (Hanafi/Hanbali sunnah, Maliki recommended for most, Shafi’i permissible/recommended for the one who wants it). Written from general knowledge of the fiqh manuals, not checked against a primary text here. Needs a scholar.
- `fam.u1.l1/contract`: Every row of this table (wali, witnesses, minimum mahr per school) is written from general fiqh knowledge and has not been checked against the manuals. Needs a scholar to confirm each school’s wording.
- `fam.u1.l2/owed`: The plain-words paraphrase of "do not keep away from her except inside the house" (do not send her away or leave) is the app author’s reading. Please confirm the wording.
- `fam.u1.l2/force`: This step mentions Qur’an 4:34 without giving a ruling and says no scholar permits injuring or shaming a spouse. Needs a scholar to confirm the wording and balance.
- `fam.u1.l3/garments`: The explanation of the garment image (closeness, covering, protection) is the app author’s summary of standard commentary. Please confirm.
- `fam.u1.l3/talk`: The use of the three-nights report for spouses is the app author’s application of its spirit. Needs a scholar to confirm the wording.
- `fam.u1.l3/trouble`: The statement that divorce is allowed but serious with rules that differ by school is general. Please confirm.
- `fam.u2.l2/beat`: This step explains the word for striking in the 7/10-year hadith. It says classical scholars limit it to a light, non-harmful tap and that many modern scholars prefer no hitting. Needs a scholar to confirm the wording and attributions.
- `fam.u2.l2/plan`: The plan by age and the statement that all four schools agree prayer becomes obligatory at puberty are general teaching, not checked against the manuals. Please confirm.
- `fam.u3.l1/duty`: Please confirm the summary of the schools’ views on a wife’s legal duty to do housework (Hanafi, Shafi’i, Hanbali, Maliki) and the wording of the practical note.
- `fam.u3.l3/limit`: Please confirm that the framing of forgiveness versus safety in cases of abuse is acceptable and add a referral line if the app has one.
- `fam.u3.l3/greet`: The hadith is about brothers in Islam. The application to spouses and family members is an extension; please confirm the wording.
- `yth.u1.l1/two`: The two-kinds-of-honour framing is a teaching summary, not a classical quotation. Please confirm the wording.
- `yth.u1.l2/names`: The explanation that the names show knowledge as the basis of the human role is a common tafsir summary; please confirm the attribution.
- `yth.u1.l2/answer`: The reading of Allah’s answer as a hopeful reply is a common reflection, not a specific tafsir citation. Please confirm.
- `yth.u2.l1/distract`: The application of 63:9 to phones is a reflection; the ayah itself names wealth and children. Please confirm.
- `yth.u2.l3/exceptions`: Please confirm the summary of exceptions (doctor, proposal, witness) and that the details differ by school.
- `yth.u3.l2/check`: Please confirm that the last step, trusting that Allah replaces what is left for His sake, does not need a source; it is stated as a reflection.
- `trx.u1.l1/consent`: The three-question summary of a valid deal is a teaching aid. Please confirm that it is acceptable as stated.
- `trx.u1.l1/forms`: The list of unjust forms is a teaching summary. Please confirm.
- `trx.u1.l2/tawakkul`: The three-way comparison is a teaching summary based on the hadith of the bird. Please confirm.
- `trx.u1.l3/notof`: The explanation that not of us is a strong warning and not a declaration of leaving Islam is the common scholarly reading. Please confirm.
- `trx.u1.l3/size`: Applying 83:1-3 to workers and students is a common application; please confirm.
- `trx.u2.l1/double`: The note that scholars do not take doubled and multiplied as a limit on the prohibition is the common reading; please confirm.
- `trx.u2.l1/kinds`: Please confirm the definitions of nasi’a and fadl and the one-line summary of each school’s reason (illa) for the six items.
- `trx.u2.l2/classic`: Please confirm the statement about the OIC Fiqh Academy and the Muslim World League Fiqh Council, and the minority view.
- `trx.u2.l2/cases`: Please confirm each case summary, especially the advice about interest on savings and about late penalties.
- `trx.u2.l3/war`: Please confirm the explanation of the war ayah and that repentance is in the same ayah.
- `trx.u2.l3/home`: Please confirm the summary of positions on mortgages and the reference to the European Council for Fatwa and Research.
- `trx.u3.l1/nisab`: Please confirm the gram values (595 g silver, 85 g gold) and the statement that the gold nisab is derived from other reports.
- `trx.u3.l1/which`: Please confirm the summary of the schools on which nisab applies to cash, and the cautious-choice suggestion.
- `trx.u3.l1/year`: The year condition is stated on the authority of the schools and the Companions; I did not verify the individual reports. Please confirm, and confirm the debt-subtraction step.
- `trx.u3.l1/calc`: Please confirm what counts as zakatable for personal items and the debt rules.

Not verified by the author: the one-year (hawl) condition for zakat is stated on the authority of the schools; the individual reports were not checked. The gram values of the nisab (about 595 g silver, 85 g gold) are scholarly conventions. The legacy screens family_school_screen.dart, youth_school_screen.dart and transactions_school_screen.dart still carry the old titles and claims (half the deen, best generation, average of five, riba economy, burnout cure) and were not changed.

Audio needs: no recordings exist for hadith phrases (fam.*, yth.*, trx.*); the lessons show a no-recording note. Ayat have recitation audio. Illustration needs: none used.
