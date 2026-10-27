# Support, conversation and knowledge packs: format

Status: draft 1 (27 Oct 2026). Data only. The Dart code that loads these files is written separately; this document is the contract between the two.

Files:

| File | What |
| --- | --- |
| `assets/support/packs/<pack>.json` | one pack per file (this document) |
| `assets/support/helplines.json` | verified help lines (separate format, see "Help lines" below) |
| `tool/support/pack_schema.json` | JSON Schema (draft 2020-12). The enums in it are the single source of truth |
| `tool/support/validate_packs.py` | the validator CI runs (`python3 tool/support/validate_packs.py`) |
| `tool/support/test_validate_packs.py` | self-test of the validator (`... validate_packs.py --self-test`) |

Everything here is **draft content**. Nothing is `shippable` until a named reviewer is recorded (see "Review and status"). The app must treat any snippet whose `status` is not `shippable` as internal-build-only (feature flag), and must never show a snippet whose pack is past `reviewBy`.

## 1. Three kinds of pack

| `packKind` | For | Snippet `kind` values | Notes |
| --- | --- | --- | --- |
| `support` | Hadi support module: addiction, abuse, distress, grief, family, students, check-in | `orient reflect ask explain plan-step safety islamic family referral checkin affirm summary` | Motivational-interviewing style. 25 to 60 snippets per pack. |
| `conversation` | Everyday talk for Hadi (adults) and Wasia (age bands 5-8, 9-12, 13-17) | `converse` (with a `move`) | At least 6 variants per move and age band, 2 or more tones. Rotation rules in section 5. |
| `knowledge` | Answers from built-in knowledge: app help, Islam basics, how-tos, misconceptions, etiquette, lesson facts | `fact howto misconception etiquette app-help lesson-fact faq` | Cross-references existing assets (`crossRef`) rather than copying them. |

## 2. File layout

```json
{
  "schema": 1,
  "pack": "alcohol",
  "packKind": "support",
  "topic": "alcohol",
  "description": "Short human description.",
  "audience": "hadi",
  "ageBands": ["adult"],
  "version": "0.1.0",
  "createdOn": "2026-10-27",
  "reviewBy": "2027-04-27",
  "languages": ["en"],
  "rotation": {"strategy": "seeded-no-repeat", "defaultMinGapTurns": 6},
  "snippets": [ ]
}
```

* `pack` equals the file name without `.json` and is `[a-z][a-z0-9_]*`.
* `rotation` exists only in conversation packs.
* `languages` lists every language used by any snippet. English is always present. `ar`, `ur`, `bn` appear only in the safety, medical_emergency, referral and checkin material (section 6).
* `reviewBy`: after this date the whole pack is withdrawn by the app (the same idea as the 9-month `help_resources_test`). The validator fails on an expired pack, so a stale pack cannot be merged.
* Files whose name starts with `_` are ignored by the validator and must not be bundled.

### Snippet

```json
{
  "id": "alcohol.reflect.004",
  "kind": "reflect",
  "subtopic": "evening-drinking",
  "stage": ["reflect", "explore"],
  "text": {"en": "It sounds like evenings are the hardest part."},
  "ageBand": ["adult"],
  "tags": ["craving", "evening"],
  "triggers": ["every night", "after work"],
  "doNotSay": ["Do not add a ruling to the first reply."],
  "sources": [],
  "evidenceLevel": "N",
  "risk": "low",
  "askPermission": false,
  "neverParaphrase": false,
  "needsScholarReview": false,
  "needsClinicianReview": true,
  "needsNativeClinicianReview": false,
  "reviewedBy": null,
  "reviewedOn": null,
  "status": "draft"
}
```

| Field | Required | Meaning |
| --- | --- | --- |
| `id` | yes | `<pack>.<code>.<nnn>`, unique in the pack. Stable forever: reports, user memory and rotation refer to it. Never reuse an id. |
| `kind` | yes | See section 1 and section 3. |
| `subtopic` | no | Finer topic, e.g. `opioids`, `benzodiazepines`, `cannabis`. Lower-case, hyphens. |
| `audience` | no | Overrides the pack's audience (`hadi`, `wasia`, `both`). |
| `stage` | yes | Conversation states in which the snippet may be used: `open checkin listen reflect explore plan close crisis handoff question any`. |
| `text` | yes | `{ "en": "..." }`, plus `ar`, `ur`, `bn` only where allowed (section 6). Plain text, no markup, no emoji, no numbers, no links. `{slot}` placeholders from the slot list. |
| `ageBand` | yes | Array of `adult`, `5-8`, `9-12`, `13-17`, `all`. |
| `tone` | conversation | `warm brief formal playful calm`. Optional elsewhere. |
| `move` | conversation | Which conversational move this is (section 5). |
| `variantGroup` | conversation | Interchangeable snippets share a group. The app never shows the same text twice inside `minGapTurns` of the group. |
| `minGapTurns` | no | Overrides the pack default. |
| `slots` | if used | Declares every `{slot}` used: `name word topic time_of_day days_away lesson letter total_days app_screen number`. The app fills them or drops the snippet. |
| `tags` | yes | Retrieval tags (lower-case). |
| `triggers` | yes | Lower-case words or short phrases that make the snippet a candidate. Hints only, never shown. May be empty. |
| `doNotSay` | yes | Authoring and review notes (what must not be said around it). Never shown. May be empty. |
| `sources` | yes | See section 4. May be empty only for `evidenceLevel` `N` or `X`. |
| `crossRef` | no | `[{asset, id}]` pointing at existing content (section 7). |
| `evidenceLevel` | yes | `A` guideline, regulator or systematic review. `B` peer-reviewed study or reputable service guidance. `C` expert consensus or practice material (needs a clinician). `D` tradition or scholarly opinion (Islamic frame). `X` unreviewed, cannot ship. `N` no factual claim, pure wording. |
| `risk` | yes | `low medium high`. High always needs a clinician. |
| `askPermission` | no | The app must ask before showing (information the person did not request). |
| `neverParaphrase` | no | Fixed text. Show exactly as written. Never rewrite with a model. All `safety`, `referral` and `medical_emergency` snippets are fixed. |
| `disputed`, `schoolsNamed` | no | A disputed position must say "scholars differ" in the text and name the schools. |
| `needsScholarReview` | yes | True for any Qur'an, hadith or fiqh source, any `islamic` snippet and any religious knowledge. |
| `needsClinicianReview` | yes | True for any clinical, guideline, study or background source, for kinds `safety plan-step referral`, for high risk, and for every child age band. |
| `needsSafeguardingReview` | no | Required true for child age bands and for the abuse topics. |
| `needsNativeClinicianReview` | yes | True exactly when a translation is present. |
| `reviewedBy` | yes | `null` until reviewed; then `{name, role, madhhab?}`. |
| `reviewedOn` | yes | `null` until reviewed; then `YYYY-MM-DD`. Both null or both set. |
| `status` | yes | `draft clinician_approved scholar_approved shippable`. Anything other than `draft` needs a reviewer. |

## 3. Kinds in the support packs

| kind | Use |
| --- | --- |
| `orient` | Opening, scope and honesty lines: what Hadi is, what it is not, what it can do here. |
| `reflect` | Simple and complex reflections of feeling or meaning. Hedged. At most 8 words are copied from the user. |
| `ask` | One open question, or a permission-ask ("Would it be all right if I shared something that helps some people?"). |
| `affirm` | Affirmation of effort and strengths, never flattery. |
| `summary` | Summary frames filled from confirmed items. |
| `explain` | Plain information (psychoeducation, how a service works). Always `askPermission: true` unless requested. |
| `plan-step` | One small step. Never a programme, dose, taper or "safe amount". |
| `safety` | Fixed safety text (emergency first, do-not-stop-suddenly cards). `neverParaphrase: true`. |
| `referral` | Who to turn to and what to say in one sentence. Help-line numbers are never typed into text: the app joins the snippet with `helplines.json` by country and scope. |
| `family` | Wording for relatives and friends. |
| `islamic` | A faith frame. Text is the app's own plain wording. The verse or hadith is **not** quoted in `text`; it is a structured source and the app renders it (see section 4). |
| `checkin` | The gentle check-in lines (3 tones, age bands). |

## 4. Sources and evidence

Each source object:

```json
{"type": "clinical", "title": "NIAAA Rethinking Drinking", "url": "https://rethinkingdrinking.niaaa.nih.gov/thinking-about-change/cut-down-or-quit",
 "section": "RES_H1 2.1", "retrievedOn": "2026-10-27"}
{"type": "quran", "ref": "39:53", "section": "RES_H2 2.1"}
{"type": "hadith", "ref": "bukhari:7507", "grade": "Sahih", "grader": "two Sahihs", "section": "RES_H2 2.3"}
{"type": "hadith", "ref": "tirmidhi:2038", "grade": "Sahih", "grader": "al-Albani", "section": "RES_H2 2.5"}
{"type": "fiqh", "title": "Dar al-Ifta al-Misriyyah fatwa 21455", "level": "institution", "schools": ["hanafi", "shafii"], "section": "RES_H2 3.4", "url": "https://..."}
```

Types: `quran hadith clinical guideline study fiqh institution background app asset authored`.

Rules (the validator enforces them):

* **Medical statements** trace to RES_H1 with the source URL and the section. A claim that rests only on RES_H1's "background" tag uses type `background`, evidence `C`, and a clinician must confirm it.
* **Islamic statements** trace to RES_H2. A hadith source names `book:number` (`bukhari muslim abudawud tirmidhi nasai ibnmajah`), must have an `ok` verdict in `tool/hadith_verdicts/*.json` with a non-weak grade, and records `grade` and `grader` (Sahihayn: grader `two Sahihs`). The hadith the research brief lists under "Do not use" (RES_H2 section 8) and the disputed-grade ones are rejected by the validator. A Qur'an source `s:a[-b]` must exist in `assets/quran/quran.json`; `4:34` is never allowed in a pack.
* **Nothing is quoted in `text`.** Text carries no citation ("Bukhari 123", "(2:255)" fail). The app renders the ayah (Arabic and Saheeh International) from `quran.json` by ref, and for a hadith shows the snippet's own plain-words meaning plus "Bukhari 7507, Sahih" assembled from the source object. No Arabic is typed by hand anywhere in these files.
* **Disputed positions** are written as "scholars differ" with the schools named, never as one ruling.
* **No invented numbers.** No statistic in a support snippet. A figure (for example a zakat rate) may appear only in a non-clinical knowledge snippet with a fiqh or asset source.
* Verdict files for what the packs cite live in `tool/hadith_verdicts/support.json`.

## 5. Conversation packs

A conversation snippet has `kind: "converse"`, a `move`, a `tone`, a `variantGroup`, and optionally `minGapTurns`.

Moves (full list in the schema): greetings by time of day (`greet_morning greet_afternoon greet_evening greet_night`), `greet_first_time`, return after a gap (`greet_return_short greet_return_long`, with `{days_away}` allowed), `small_talk rapport how_are_you_reply how_are_you_ask gratitude_receive gratitude_give humour clarify follow_up tell_me_more transition summarise handle_confusion handle_disagreement handle_frustration handle_youre_wrong apologise dont_know scholar_handoff boundary_clinician boundary_fatwa boundary_only_friend boundary_ai encourage celebrate goodbye`; and for Wasia `praise_specific wrong_answer_patience explain_level_1 explain_level_2 explain_level_3 quiz_offer quiz_next quiz_right quiz_wrong ask_me_anything story_prompt break_offer silly_fun bedtime calm_down bored cant_do_it hate_this curiosity_islam grownup_handoff lesson_start lesson_end`.

Rules:

* **At least 6 variants per move and age band**, at least 2 different tones, and no two variants of a move open with the same three words (validator).
* **Rotation (the app must implement):** seeded per session. Keep a history of shown snippet ids per `variantGroup`. Candidate set = variants for (move, age band, tone preference) minus any id shown within the last `minGapTurns` turns of that group (default from `rotation.defaultMinGapTurns`). If the candidate set is empty, widen to other tones, then to the least recently shown. Never show the identical text twice in a row, in any case. Tone preference comes from the user's tone dials (brief, warm, formal), defaulting to `warm`.
* **Humour** is gentle and never used while a crisis latch, a safety card, or any distress cue is active, and never about a person, a faith practice, or a struggle.
* **Boundary moves** (`boundary_clinician boundary_fatwa boundary_only_friend boundary_ai`) are fixed wording variants that say the honest thing in different words; they are not optional when the matching cue occurs.
* A conversation snippet is never a source of facts. Facts come from knowledge packs.

## 6. Languages

* English first. Other languages only for `safety`, `referral`, `checkin` snippets and the `medical_emergency` pack.
* Every translated snippet sets `needsNativeClinicianReview: true`. They were not produced by a native clinician and must not be released in a language until one signs.
* Arabic-script text appears only in `text.ar` and `text.ur`, Bengali only in `text.bn`. `text.en` has no non-Latin script. No Qur'an or hadith Arabic is typed by hand; religious text appears only through the structured `quran`/`hadith` sources the app renders from the verified corpus.
* Numbers in translated safety text are never typed: the line "call your emergency number" is joined by the app with the user's country entry in `helplines.json`.

## 7. Cross-references to existing content

Knowledge snippets point to existing assets instead of copying them, and add only what is missing:

```json
"crossRef": [{"asset": "assets/qa/qa_bank.json", "id": "wudu-steps"}]
```

The validator checks the file exists. The code agent resolves `id` against the asset's own id scheme (`qa_bank.json` ids, HadiCore entry ids, guide ids, story ids, academy lesson ids). When a snippet only adds a pointer, its `text` is a one-line bridge ("There is a short guide in the app on this"), and the app opens the referenced item.

## 8. Retrieval needs (for the code agent)

The packs assume this retrieval, offline, no embeddings:

1. **Filter** by `audience` (hadi/wasia), `ageBand` (the child's parent-set band; fall back to `9-12` when unknown; adult for Hadi), `stage`, `languages`, `status` (internal build: any; release: `shippable` only), `reviewBy` not passed.
2. **Candidates** = snippets whose `triggers` or `tags` overlap the cues from the detector (topic, emotion, intent) or, for knowledge, the tokenised question (reuse the `LocalKnowledge` tokenised index over `triggers`, `tags`, and `text.en`).
3. **Score** = overlap of triggers and tags, times a recency penalty (a snippet shown this session is penalised; a conversation `variantGroup` obeys `minGapTurns`), times tone preference.
4. **Return** at most two snippets for a support turn (about 300 tokens) and honour `askPermission` (ask first) and `neverParaphrase` (show verbatim). `safety`, `referral` and `medical_emergency` are T0: no model is involved, ever.
5. **Joins**: `referral` and `safety` snippets are joined with `helplines.json` (country from the existing country setting, scope from the snippet's tags). Numbers are never typed in snippet text.
6. **Slots**: fill `{name}` etc. or drop the snippet; never show a raw `{...}`.
7. **Provenance affordance**: "How I know this" lists `sources` (title, grade), the review status and `version`.
8. **Cost**: the conversation and knowledge packs exist so that common turns are answered with no model call. A model may be used only to rephrase a non-fixed snippet inside the schema-constrained path described in the design brief; it may not add facts.
9. **Pubspec**: declare `assets/support/` and `assets/support/packs/` (Flutter asset directories are not recursive).
10. **Child rules** are enforced in data (no `haram`/`sin`/`hell` wording, no "tell your parents" as the only route, 60 words maximum, short sentences) and must also be enforced in code (no model, no persistence, no parent dashboard).

## 9. Help lines (`assets/support/helplines.json`)

File: `assets/support/helplines.json`, built by `tool/support/build_helplines.py` and checked by `tool/support/validate_helplines.py` (which also cross-checks the app's `HelpResources`).

Top level: `schema`, `verifiedOn`, `about`, `scopes`, `helplines` (display set) and `toVerify` (never shown).

Each row: `id`, `country` (ISO code or `INT`), `service`, `number`, `text` (SMS/keyword), `url`, `hours` (null if the source did not state it), `scope` (suicide, addiction, domestic-abuse, child, sexual-violence, general, emergency, smoking, gambling, elder, eating, poison, muslim), `language`, `audience` (adult, child, adult-concerned, child-or-adult-concerned, adult-or-concerned), `verifiedOn`, `source` (operator or official page), `status` (`verified` or `unverified`), `notes`.

Rules: only rows read on an operator or official page on `verifiedOn` are in `helplines`; anything unconfirmed is `unverified` and sits in `toVerify` with the reason. Child lines (`audience` child) are kept apart from adult lines. The app joins a `referral` or `safety` snippet with the user's country and the snippet's scope; numbers are never typed in snippet text. Where a country has no verified crisis line the app falls back to the `INT` directories.

## 10. Review and status

* `draft` -> `clinician_approved` -> `scholar_approved` (if religious) -> `shippable`. High-risk items need both where relevant. Child material needs a safeguarding lead.
* Every snippet is registered in the review register (`tool/scholar_review/build_register.py` -> `docs/SCHOLAR_REVIEW_REGISTER.md`, `register.json`), under the label "Scholar review needed" or the clinician equivalent.
* Reviewer names are recorded in the snippet (`reviewedBy`, `reviewedOn`), never invented.

## 11. Running the checks

```
python3 tool/support/validate_packs.py            # all packs
python3 tool/support/validate_packs.py --self-test
python3 tool/hadith_check.py check                # also scans assets/support (CI)
python3 tool/quran_ref_check.py                   # also scans assets/support (CI)
```

The repo-wide hadith and Qur'an gates scan every JSON file under `assets/`, so they apply to these packs too. For that reason a graded-book hadith source object is written on one line with `grade` and `grader` straight after `ref`.
