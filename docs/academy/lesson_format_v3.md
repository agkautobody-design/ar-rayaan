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
| `doit` | `title`, `body`, `route` (`/prayer` `/qibla` `/quran` `/quran/<1-114>` `/hadi` `/calendar` `/adhkar`), `button` |

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

Every `contrast` step (madhab rows) and every explanation written by the app author; the app already shows "Not yet scholar-reviewed".

## Illustration needs (none used yet; silhouette figures, no faces)
Wudu: each of the 9 steps (hands, mouth, nose, face, arms, head and ears, feet). Salah: standing with hands raised, hands folded (3 school variants), bowing, standing up, prostration (seven parts touching), sitting between, tashahhud sitting, salam turning head. Qibla/prayer-mat setup.

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
