# Games: what is built, what is hidden, and exactly what content is needed

Branch `feat/learning-games`, 26 Oct 2026. Rule followed: a learning game is built only from content already in the app, and every question or round shows its source and an explanation. Where the app lacks verified content, the game is registered as `hidden: true` in `lib/features/games/engine/learning_games.dart` (no hub card, no page, `gameById` returns null) and its need is listed here. `test/games/learning_games_test.dart` fails if a hidden game is missing from this file.

## Built from content already in the repo

| Game | Fed from | How each answer is sourced |
|---|---|---|
| Seerah Challenge (`seerah`) | `assets/games/seerah_quiz.json` (51 questions) | each question names a story of `assets/stories/seerah.json` and an "evidence" phrase that must appear word for word in that story's text or source line (test). The source shown is the story's own source lines |
| Seerah Timeline (`seerah-timeline`) | `assets/games/order_rounds.json`, 12 events | the order the Seerah School tells its stories in (story numbers must rise; test). Each event shows a sentence copied from its story. No dates are asserted beyond the story's own words |
| Prophets in Order (`prophets-order`) | `order_rounds.json` + `assets/family/tree.json` | only orders the tree states: Adam first (tree text: first man and first prophet), Muhammad last (Seal of the Prophets, Qur'an 33:40 as the tree cites it), or an Established ancestor of the other (test checks every pair, and that no pair can be read the other way). No dates, no images of prophets |
| Hadith Knowledge (`hadith`) | `assets/hadith/nawawi40.json` | hadith text, number, the collection an-Nawawi names, and the grade WITH its grader via `HadithGrade` (the existing guard). A report with no named grader (Forty no. 19) is not asked. "Which collection" never offers a collection the right answer also names |
| Wudu and Salah Steps (`salah-wudu`) | `huda-wudu` and `huda-prayer` in `assets/guides/guides.json` | the guide's steps in the guide's own order, with the guide's sources. Madhhab: the guide follows no single school and the app holds no verified text for any one school's details; the round says so and shows the guide's own `madhhabNote` when it has one |
| Arabic Words (`arabic-words`) | `assets/games/names99.json` (Arabic checked per `VERIFICATION_LOG_NAMES_DUAS.md`), `assets/academy/letters_curriculum.json` | Name <-> Arabic matching and letter <-> name matching. The meaning of a Name is shown after the answer but never asked, because several Names have close meanings and a question must have one right answer |
| Word Search / Word Scramble (`wordsearch`, `scramble`) | the Huda glossary (`kGuideGlossary`, neutral literal glosses, no rulings) | each word comes with its gloss. No Name of Allah is hidden or scrambled (test) |

Not used on purpose: `assets/academy/word_pack.json` (meanings have no licensed source, see `word_deck_gate_test.dart`), the 99 Names as scrambled or hidden words, any picture of a prophet, any timer, any point or coin tied to worship, any rating.

## Hidden games and the content each needs

### 1. Islamic History (`islamic-history`)
Needs a list of at least 30 events after the Seerah (for example the caliphates, the first Muslim dynasties, scholars) where each row has: the event in one plain sentence; the date in AH and in CE, each with a named source (work and page, or a stable URL actually opened); two or three clearly wrong alternatives; and a named scholar's sign-off. The app has no such list: the Seerah stories give years only for a few events.

### 2. Seerah: How Would You Respond? (`seerah-scenarios`)
The design asks what the right response is in a situation of the Seerah. That is new religious guidance. Needs, from a named scholar: each situation, the response taught by the Prophet's example with its hadith or Qur'an reference, and why the other choices are not. Until then the Seerah is covered by Seerah Challenge and Seerah Timeline.

### 3. Arabic Spelling (`arabic-spelling`)
Needs a word list with: the vowelled Arabic word, its transliteration, its English meaning, and for each meaning a named source with a licence that allows use in the app (OWNER_ACTIONS item 7 is the same blocker for the 300-word deck). If the design's pronunciation audio is wanted: a licensed recording per word (device speech is not reliable for Arabic). Arabic letters and the 99 Names are already covered by Arabic Words.

### 4. Hajj Map (`hajj-map`)
Needs (a) the schematic map art (Makkah, Mina, Arafat, Muzdalifah, Jamarat; no photos), and (b) a named scholar's check of the order of the rites as the guides (`huda-ihram`, `huda-tawaf`, `huda-arafat`, `huda-arafat-day`, `huda-ihram-rites`, `huda-hajj-overview`) give them, because the rites differ by day and by type of Hajj. A Qur'an verse on the result screen (the design shows 22:27) must be copied from `assets/quran/quran.json`.

## Content that would grow the games that are built

- Seerah Challenge: more questions follow the same pattern. Add a row to `seerah_quiz.json` with a story id and an `evidence` phrase copied from that story. Stories flagged "source not checked" in `docs/story_audit.md` are still labelled, not removed.
- Prophets in Order: the tree gives few unambiguous orders. A scholar-approved order of the prophets (with the source for each pair) would allow rounds beyond Adam, Muhammad ﷺ, and the fathers and sons of the tree.
- Hadith Knowledge: only the Forty are bundled. Riyad as-Salihin (or any other collection) needs a sourced, graded, bundled text first. Topics for each of the Forty (a "which hadith teaches this" round) need an approved title per hadith.
- Arabic Words: a list of Names whose meanings are close (for example Al-Qadir and Al-Muqtadir) approved by a scholar would let meaning questions be asked safely. Word-level meanings for dua words need a sourced list.
- Wudu and Salah Steps: more guides can be added (ghusl, tayammum, the Hajj rites) once the owner decides which have a clear single order.

## Art to export from the designs (all optional)

The designs are not in the repo, so nothing was cropped. Each game draws the same theme in code. When you export a clean file with this name, put it in `assets/games/art/` (or run `python3 tool/games_art_crop.py <design.png> <slot> --box L T R B`, which crops, resizes to at most 1080 px wide and writes the `.webp`). No text, no buttons, no avatars, no faces; at most 150 KB each.

| File (in `assets/games/art/`) | Used by | What to export |
|---|---|---|
| `seerah_timeline_board.webp` | Seerah Timeline | the card-list background of the timeline screen |
| `prophets_order_board.webp` | Prophets in Order | the same, for the prophets screen |
| `wudu_steps_board.webp` | Wudu steps | the steps background of the Wudu screen |
| `salah_steps_board.webp` | Salah steps | the steps background of the Salah screen |
| `wordsearch_grid.webp` | Word Search | the grid background |
| `scramble_tile.webp` | Word Scramble | the letter-tile background |
| `hajj_map.webp` | Hajj Map (hidden) | the schematic map |

Memory cards (Names Memory) were not changed in this branch.
