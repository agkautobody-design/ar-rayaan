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

Every `contrast` step (madhab rows) and every explanation written by the app author; the app already shows "Not yet scholar-reviewed".

## Illustration needs (none used yet; silhouette figures, no faces)
Wudu: each of the 9 steps (hands, mouth, nose, face, arms, head and ears, feet). Salah: standing with hands raised, hands folded (3 school variants), bowing, standing up, prostration (seven parts touching), sitting between, tashahhud sitting, salam turning head. Qibla/prayer-mat setup.
