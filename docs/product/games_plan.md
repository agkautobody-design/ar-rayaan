# Games section and Wasia Academy: strategy and build plan

Status: PLAN ONLY. No app code is changed by this document. Written 26 Oct 2026 against `main` at a6f408d.
Author: research pass for the owner. Everything below that says "owner decides" needs an answer before the build starts.

Sources used: the whole repo (lib, assets, tests, firestore.rules, docs), and the owner's design images (about 150 screens in four batches: Maze/Geometry/Logic generic games, Islamic game landing pages, Chess/Ludo flows, and the final dark-gold "mosque at sunset" set).

---

## 0. The short version

1. The app already has more than the designs assume. It has seven working games, a Firestore "online hall" that lets two people play Ludo or Shatranj by six-letter code, a Family Wing with parent gate and children's privacy text, a lesson player with typed step kinds, a spaced-review queue, and a navy/gold theme that is already 90% of the new look. The plan is to connect and re-skin, not rebuild.
2. One game engine, one content registry. A learning game is a `GameDef` plus a `ContentSet`. The Games hub lists every `GameDef`; a Wasia lesson gets a new step kind `game` that points at the same `GameDef` and a fixed `ContentSet`. Same code, same content, two doors.
3. Keep the locked five-tab nav (Home, Faith, Family, Hadi, You). It is also what the newest Home design shows. Games is reached from a Home tile, Explore, Kids and Wasia, not from a sixth tab.
4. Multiplayer in three honest phases: (1) solo and pass-and-play on one device, (2) invite-code rooms (already half built) plus a "your games" list kept on the device, (3) live presence, push, friends. Phases 1 and 2 need no new backend. Phase 3 does, and should wait for parental controls and moderation.
5. Content safety is the real gate. Several designed screens contain religious claims, verses or points for worship that the app's own rules forbid. Section 6 lists each.

---

## 1. What exists today (repo audit)

### 1.1 Games (`lib/features/games`, `assets/games`)

| Game | Route | Code | Modes today | Data | Notes |
|---|---|---|---|---|---|
| Games list | `/games` | `games_screens.dart` `GamesScreen` | 7 plain cards | none | Outside the nav shell, `ScreenHeader(close: true)`. No filters, no history. |
| Ludo "the second crown" | `/games/ludo` | `ludo_screen.dart`, `data/ludo_rules.dart` | vs Hadi (heuristic AI), two players on one device, online by code | pure rules in `LudoRules` | 2 players only. Source comment: "four-player boards and ... in v2". Dice is rolled on the mover's device and sent with the move. |
| Shatranj (chess) | `/games/shatranj` | `shatranj_screen.dart`, `chess_pieces.dart` | vs Hadi engine (alpha-beta), two players on one device, online by code | in-file engine | Engine now complete (`lib/features/games/chess/`): castling, en passant, chosen promotion, mate/stalemate, threefold, fifty-move, insufficient material; undo/redo, three levels, hint, draw offer, resign, optional clock, move list, captured pieces, settings. Board art cut from the owner's design (`docs/product/chess_assets.md`). Online tables are moves only. |
| Daily Trivia | `/games/trivia` | `games_screens.dart` `TriviaScreen` | solo | `assets/games/trivia.json`, 40 questions (Prophets 8, Women 7, Seerah 5, Companions 5, Qur'an 5, Al-Ghayb 5, General 5) loaded by `ContentSync` | Options are shuffled per question. Each question has a `why` line. |
| The 99 Names | `/games/names99` | same file | flashcards | `assets/games/names99.json` (99 names, Arabic, meaning, ref) | Arabic added in round 4, verified in `docs/content_needed/VERIFICATION_LOG_NAMES_DUAS.md`. |
| Lineage Challenge | `/games/lineage` | `games_extra.dart`, `data/lineage_rounds.dart` | solo | `assets/family/tree.json` | Round logic is pure and tested (`test/games/lineage_rounds_test.dart`). |
| Ayah Completion | `/games/ayah` | `games_extra.dart` | solo | whole bundled Qur'an (`assets/quran/quran.json`, 114 surahs) | One word veiled, pick it. Text comes from the bundled Tanzil file, never typed in code. |
| Hijrah Journey | `/games/hijrah` | `games_extra.dart` `HijrahMapScreen` | solo, station by station | in file | Static story map. |
| Online hall | bottom sheet | `data/game_rooms_service.dart`, `presentation/online_lobby.dart`, `data/room_moves.dart` | create/join a room by six-letter code, moves synced by Firestore | collection `game_rooms` | Anonymous Firebase auth. Rooms are readable by code, never listable. 24 h `expireAt` (TTL policy still an owner action, `docs/OWNER_ACTIONS.md` item 2b). Rules in `firestore.rules` allow only `ludo` and `shatranj`. Honest offline errors already exist (`OnlineLobby.describe`). |

Tests that pin this: `test/games/online_lobby_test.dart`, `room_moves_test.dart`, `lineage_rounds_test.dart`, `firestore_rules_hardening_test.dart`, `journey_hifz_kids_test.dart`.

Not in the repo (checked with grep): memory/match, word search, jigsaw, sudoku, maze, 2048, checkers, reversi, four in a row, quiz setup/results screens, game history, saved game state, scores, leaderboards, chat, friend list, presence, push notifications.

### 1.2 Learning code (Wasia Academy, Journey, Hifz, Kids, Stories)

- **Naming.** In code, "Al-Wasia Academy" is the structured-learning wing (`lib/features/academy`, route `/academy`, gate `/academy/gate`, titled "Wasia Academy"). "Wasia" is also the in-lesson teacher voice (`wasia_controller.dart`). Hadi is the guide/assistant (`lib/features/hadi`). The owner's naming (Ar-Rayaan the gate, Al-Hadi the guide, Al-Wasia the vast knowledge) matches.
- **Lesson model** (`academy/domain/academy_models.dart`): Course > Unit > Lesson > Step. `AcademyStepKind` is `text, action, embed, check, try_, demo`. An `action` step opens an app route; a `check` step points at an assessment id. This is the hook for a `game` step.
- **Courses** (`course_manifest.dart`, 2,171 lines): the-path, letters, recitation, quranic-arabic, arabic-language, aqeedah, character, family, youth, womens, transactions, endoflife, dawah, health, understanding, hifz, plus screens for seerah, history, stories, hadith, dua, dhikr, hisn, hajj-umrah pack, ramadan mode, Q and A bank.
- **Checks and review.** `assessment_engine.dart` (mastery, not curves; nothing timed; wrong answers reteach), `recall_check.dart` (auto-generated fill-the-word question from the lesson's own sentence, with an exclusion list `kRecallExcludedLessons` for lessons the audit flagged), `letter_drills.dart`, `review_questions.dart`, `fsrs.dart` and `spaced_repetition.dart` (review queue). Three near-identical question shapes already exist: `TriviaQ`, `AssessmentItem`, `ReviewQuestion` (plus `LetterDrill`). They should become one.
- **Hifz.** Hifz Planner (`/academy/hifz`), and a "Hide text / test me" mode inside the Qur'an reader (`surah_reader_screen.dart`, `hideable_arabic.dart`). That is the existing Hifz test.
- **Kids.** `/kids` (`kids_corner_screen.dart`): three doors, Arabic letters, Games, Stories school. Games is already a child door. Family Wing (`academy_family.dart`, `family_service.dart`, `widgets/parent_gate.dart`, `domain/children_privacy.dart`): child profiles are first name only, on the device only; the privacy text promises no cloud copy, no advertising, no analytics.
- **Stories / Seerah.** `assets/stories/*.json` (seerah 31 collections, prophets 24, companions 26, women 17, ghayb 50 ...). Seerah School (`seerah_school_screen.dart`) lists chapters that open the stories. Every Seerah chapter has an audit row in `docs/story_audit.md` and a label policy (`story_labels_test.dart`).
- **Journey** (`/journey`, in the Home branch of the nav shell): "My Journey" progress ring and saved stories. It is a progress page, not a game.
- **Streaks.** `docs/product/return_loop.md`: owner-approved gentle "days returned" (opt-in, one grace day a week, three acts only: Qur'an, adhkar, lessons; no points, no confetti, no leaderboard).

### 1.3 Shell, nav, theme

- **Bottom nav** (`app_bottom_nav.dart`, `router.dart` StatefulShellRoute): Home, Faith, Family, Hadi, You. Documented as "Locked". Elder Mode redirects the Home tab to `/home/elder`. Routes `noor` and `journey` live in the Home branch, so there is precedent for putting a page inside a branch to keep the nav visible.
- **Games, Kids, Academy routes are outside the shell** (full screen with `ScreenHeader` back/close). `parentRouteOf` sends `/games/*` back to `/games`, `/academy/*` to `/academy`.
- **Titles.** Every route needs an entry in `lib/app/core/route_titles.dart` (`crawl_web_test`).
- **Theme** (`app_colors.dart`, `app_typography.dart`, `theme/widgets/*`): gold `#D4AF37`, goldLight `#E8C96A`, goldDark `#9C7C1E`, sand `#EAD6B4`, deepBlue `#0B1B2A`, navy `#101C2E`, night `#05090F`; Playfair Display (headings), Inter (body), Amiri (Arabic); `GlassCard` (1px gold border, radius 20, optional blur), `GoldButton` (champagne gradient pill), `ScenicBackground` (home golden-hour mosque garden `bg_home.jpg`, community lanterns, pattern), `ScreenHeader`, `AskHadiPill`. A `theme_a11y_test` pins text contrast.
- **Assets today:** 15 MB total; images 5.6 MB; fonts 3 MB; audio 2.3 MB; Qur'an 2.2 MB.

### 1.4 Things that do NOT exist and the designs assume

User accounts, friend lists, a "family" of other devices, online/offline presence, invitations that arrive on another phone, push notifications ("Your turn"), server-side game history, scores shared between users, chat, ratings ("4.8"), tournaments, coins, weekly challenges with rewards, a server-authoritative dice, any moderation.

---

## 2. Catalogue of the designs (every screen and flow)

Four batches. Where two versions of one screen exist the latest is marked (final).

### 2.1 Final batch (dark gold, mosque-at-sunset; the owner's chosen theme)

| # | Screen | What it shows | Maps to today |
|---|---|---|---|
| F1 | Home with Games entry | Hādi search bar, "Today's Verse", 3x2 tile grid (Qur'an, Prayer Times, Hādi, Family, Community, Games highlighted), "Continue Playing" row (Qur'an Knowledge 12/30, Chess vs Omar "Your turn"), banner "Build Your Knowledge Through Play / Explore Games". Nav Home, Faith, Family, Hādi, You. | `HomeScreen` exists with a Quick Access strip that already names Games. Needs tile + Continue row + saved-game state. |
| F2 | Games Hub (variants A/B/C/D) | Arched header, filter chips All/Islamic/Strategy/Family (or Trivia/Words/Board/Family/Learning), "Continue Playing" with progress bars, sections Islamic / Strategy / Family and Community, "Popular Games" with star ratings 4.8/4.7/4.6/4.5 | `GamesScreen` (flat list of 7). No chips, no continue, no ratings. |
| F3 | Games landing with 6 big category cards | Islamic Games, Board Games, Word Games, Puzzles and Mind, Family and Group, More Games; "Popular Games" row | none |
| F4 | Islamic Games (two versions: list with thumbnails; 2-column cards with Trivia/Learning/Words/Board tags) | Qur'an Knowledge / Qur'an Trivia, Seerah Challenge / Seerah Quest, Hadith Knowledge / Hadith Match, Prophets and Messengers / Prophets Timeline, Islamic History, Salah and Wudu, 99 Names, Arabic Vocabulary / Arabic Words | Trivia, 99 Names, Lineage (prophets), Ayah, Hijrah exist. Seerah, Hadith, Salah/Wudu, Arabic words are new. |
| F5 | All Games Collection | 2-column grid: Qur'an Quiz, Seerah Challenge, Chess, Ludo, Memory, Arabic Words, Puzzle Path, Logic Tiles | registry view |
| F6 | Qur'an Knowledge details | topics covered, play formats (solo, family, friends), 5 to 30 questions, multiple choice, hints, all levels, Play Now, Invite Family | new |
| F7 | Game Setup, Qur'an Knowledge | 5 steps: play mode (Solo, Family, Friends), players 1 to 4, questions 5/10/15/20/30, difficulty Easy/Standard/Challenge, hints toggle, Continue | new |
| F8 | Invite Players (Family/Friends/Recent tabs) | contact list with Online/Offline dots, checkboxes, search, Send Invitations | no equivalent (needs accounts) |
| F9 | Waiting Room | players 4/4, Host crown, Joined/Waiting, "Game Code: AR2387" with copy button, Start Game, Cancel | `OnlineLobby` has the code part only |
| F10 | Your Turn | "Games waiting for your move" (Qur'an Knowledge 12/20, Chess, Ludo 3/4), "Waiting for Others" (Arabic Words 5/10, Seerah Challenge family game 8/15) | new; needs remembered rooms and (for push) FCM |
| F11 | Game History | filters All/Islamic/Completed/Ongoing; per game last played, questions, levels, score 80/100 or "Level 2/10" | new local store |
| F12 | Ludo flow (10 screens: details, setup, invite, waiting, in-game 4 players, results, history, Hadi help, settings) | 4 players, "Tap to Roll", Chat button in some variants | Ludo exists with 2 players |
| F13 | Chess flow (setup with game type Standard/Timed/Casual, board theme, play as, time control 5/10/15/30, allow hints; in-game with clocks, Undo, Draw, Resign, Settings; "You Won", View Analysis; Learn Chess with Hadi: How to Play, Strategies, Puzzles, Tactics, Video Lessons; Chess settings; Tournaments) | engine exists; clocks, undo, draw, resign, analysis, lessons, tournaments do not |
| F14 | Ask Hadi (in-game help) | Explain the rules, Give me a hint, What's the best move, Tell me more about this game, Share a strategy tip | Hadi screen exists; game help does not |
| F15 | Game Settings | Sound, Vibration, Board Theme (4), Show Move Hints, Enable Animations, Confirm Moves, Reset to Default | new (sound infrastructure `sfx_provider.dart` exists) |
| F16 | Quiz in-game / results | question 3 of 10, hint, 50/50, next; "Quiz Completed" 80/100 with a ranked list of 4 players | new |

### 2.2 Earlier Islamic and learning screens (second/third batches)

Islamic Games landing pages (Qur'an Challenge, Islamic Trivia, Hadith Quiz with levels, Seerah Journey, Arabic Words, Word Search, Islamic Memory, Islamic Puzzles, Family Games, Ramadan Challenges, Masjid Explorer, Muslim World Explorer); Qur'an Challenge modes (Surah Quiz, Ayah Order, Verse Challenge, Surah Order, Word Match, Recitation Challenge with "listen, recite, get feedback", Ayah Puzzle, Time Challenge); Hadith Quiz question types (multiple choice, type the missing word, Al-Hadi hint panel, Correct, Skipped, waiting for players, Explanation and Source, Report this question, results, continue saved quiz); Family Quiz (Team Noor 320 vs Team Sabr 250, "Ask Hadi"), Team Setup (players, team/individual, age range, game type); Seerah Journey chapter "A Turning Point in Makkah" with "How do you respond?" choices and "Read Source Context"; Chapter Complete ("Hijrah to Madinah", 250 points, "Why this sequence matters"); Arabic Words Matching and Spelling Challenge (audio, "Use Hint -50 pts"); Islamic Memory (Kaaba pair with "Match Found" explanation); Islamic Jigsaw; Ramadan Challenges "Good Deeds Checklist" (points per deed, 7 day streak, 320 total points); Seerah Journey with 12 chapters and locked/completed lessons; Salah Steps result (6 of 7); Hajj Map Challenge result (Makkah, Mina, Arafat, Muzdalifah, Jamarat); Wudu Complete (7/7); Islamic History quiz answer review with a "Verified Source" box.

### 2.3 Generic game screens (first batch)

Maze Escape (several variants), Geometry Builder (Islamic star pattern), Logic Grid, Riddle Challenge, Quiz Challenge (general), Geography Explorer, World Flags, Jigsaw (easy/medium/hard, 24 pieces), Memory Match, grids of 10-game overview screens (Word Search, Hangman, Number Sequence, Math Challenge, True or False, Spot the Difference, Color Pattern, Shape Builder, Tetris-style, Memory Numbers, Tower Builder, Colour Sort, Pattern Sequence, Word Scramble, Crossword, Picture Puzzle, 2048, Logic Puzzle, Number Puzzle, Picture Quiz), Astronomy Explorer, Healthy Habits, Art and Pattern Studio, Good Manners Choice, Nature Cycle, Story Sequence Builder, Math Quest, Animal Habitat Match, Inventions and Discoveries, Mystery Clue Hunt, Music and Sound Recognition, Tangram, Logic Deduction (Muslim scholars grid), Sliding Tile, Checkers (with Qur'an 2:153 banner), Four in a Row, Reversi, Sudoku.

### 2.4 Cross-cutting observations about the designs

- **Five different bottom navs** appear (see section 4.1) and **two header styles** (a compact "Ar-Rayaan / The Gate" logo and the newer calligraphy "AR-RAYAAN, Your gateway to Allah" logo).
- **Fake social proof:** "Popular Games" with star ratings (4.8 and so on) and "Online" dots on named people. There is no data behind either.
- **Currencies:** "Hint (5 points)", "Use Hint -50 pts", "coins" on one variant, "Points Earned +50 bonus", "Rewards", "Tournaments", "earn rewards".
- **Free text between people:** a "Chat" button on the Ludo board and a 200-character message on every invite.
- **Timers** on religious quizzes (00:30 per question).
- **Religious claims in sample content**, listed in section 6.4.

---

## 3. Game-by-game table

Legend. Verify = Islamic-content verification need: None (no religious claim), Source (claims come from bundled, already-audited text; needs the citation shown), Scholar (new religious wording; owner must have it reviewed before release). Modes: S solo, P pass-and-play on one device, A async by code, L live. Effort: S under 1 week, M 1 to 2 weeks, L 2 to 4 weeks, XL over 4 weeks (one engineer, including tests). Where: G Games only, W Wasia only, B both. Priority: P0 now, P1 next, P2 later, P3 only if the owner insists.

| Game | Learning value | Verify | Modes | Effort | Where | Pri | Notes |
|---|---|---|---|---|---|---|---|
| Daily Trivia (exists) | Medium: stories, Qur'an facts | Source (`why` lines carry refs) | S | S (re-skin, move to engine) | B | P0 | Only 40 questions; Qur'an category has 5. |
| 99 Names flashcards (exists) | High | Source (verified log) | S | S | B | P0 | Good Wasia step ("meet 3 names"). Add matching mode later. |
| Lineage Challenge (exists) | Medium | Source (tree.json) | S | S | B | P0 | Rename in hub as "Prophets' Family Tree". |
| Ayah Completion (exists) | High: reading the real text | None beyond bundled Tanzil text | S, P | S | B | P0 | Pool is the whole Qur'an. Strong base for "Qur'an Knowledge". |
| Hijrah Journey (exists) | Medium | Source (check against story audit) | S | S | B | P1 | Becomes a Seerah "Timeline" game with the order game engine. |
| Ludo (exists, 2 players) | Low (social, turn-taking, counting) | None, but see dice note (6.6) | S vs Hadi, P, A | S to keep; L for 4 players | G | P0 keep, P1 4-player | LudoRules already holds an array of players. |
| Chess / Shatranj (exists) | High (strategy) | None; dice not involved | S vs Hadi, P, A | M for clocks/undo/resign; L for Learn Chess lessons | G (lessons also B) | P0 keep, P1 undo/resign/clock | "Learn Chess with Hadi" is lesson content, not Islamic content. |
| Qur'an Knowledge (new quiz mode set) | High | Source for verbatim question types; Scholar for any meaning/tafsir question | S, P, A | M for engine + 3 question types | B | P0 | Engine first with: ayah completion, surah name/number/ayah count (from `kSurahIndex`), "which surah contains this ayah". Revelation place only where unanimous; skip disputed. |
| Seerah Challenge / Journey | High | Source (stories already audited) + Scholar for new "How do you respond?" scenarios | S, P | M (order/timeline from existing chapters), L (scenarios) | B (Seerah School step) | P1 | The "respond with patience" scenario cards are new religious guidance: Scholar. |
| Hadith Knowledge / Match | High | Source for text from `nawawi40.json`; Scholar for questions | S, P | M | B (Hadith School) | P1 | Blank-the-word from the bundled text is allowed; "complete the hadith" must show book and number. Never score a grade claim. |
| Prophets and Messengers timeline | Medium | Scholar (order and dates are disputed in places; only use what the story files assert) | S | M | B | P2 | Use lineage + stories, no dates. |
| Salah and Wudu steps (order game) | Very high (practical) | Source (`huda-wudu`, `huda-prayer` already carry citations) | S, P | M | B (Huda lessons) | P1 | Order the steps exactly as the guide gives them. Result screen text must come from the guide, not new wording. |
| Hajj map challenge | Medium | Source (hajj pack, `huda-hajj-intro`, `huda-tawaf`, `huda-arafat`) | S | L (map art) | B (Hajj pack) | P2 | Needs map art. Verse 22:27 on the result must be checked against the Tanzil text. |
| Islamic History quiz | Medium | Scholar for new question bank (dates CE/AH) | S | M | G (Wasia History School later) | P2 | The Hijrah 622 CE example is fine; the bank is new content. |
| Arabic letters game | High (kids) | None: the 28 letters curriculum is audited | S | M | B (Letters school drill) | P0 | Reuse `letter_drills.dart`. |
| Arabic Words (match, spell, scramble) | High | Blocked: 300-word deck is hidden pending a licence (OWNER_ACTIONS item 7) | S, A | M after licence | B | P2 (blocked) | Audio for pronunciation: only if a licensed recording exists; TTS Arabic quality is not reliable for teaching. |
| Islamic Memory (match pairs) | Medium (recall) | Source (pairs from Names/letters/Kaaba facts) | S, P | S to M | B | P0 | Cards can be text/pattern with no art; art is a later upgrade. |
| Word Search / Crossword (Islamic terms) | Medium | Source (glossary exists, `glossary.dart`) | S | M | B | P2 | Use only glossary terms already in the app. |
| Jigsaw / Islamic Puzzles | Low | None (images only) | S | M + art | G | P2 | Needs licensed or owner-made images. |
| Geometry Builder (Islamic star patterns), Tangram | Medium (geometry) | None | S | L | G | P2 | Culturally on-theme; good second wave. |
| Sudoku, 2048, Sliding Tile, Maze, Logic Grid, Reversi, Checkers, Four in a Row | Low to medium (logic) | None | S, P | S each (pure Dart) | G | P2 | Cheap, no religious risk. Do not decorate with Qur'an verses (6.4). |
| Number/Math games, Pattern Sequence, Color Pattern, Shape Builder | Medium (kids) | None | S | S each | G (kids door) | P3 | |
| Riddles, Quiz Challenge (general), Geography/Flags, Astronomy, Animals, Inventions, Healthy Habits, Good Manners | Low to medium | Healthy Habits and Good Manners are values content: Scholar | S | M each (content authoring) | G | P3 | Non-religious banks still need an editor; flags need image assets. |
| Hangman, Tetris-style | n/a | None | S | S | none | Skip or rename | Hangman imagery is a poor fit for a children's Islamic app; "Tetris" is a trademark (a block-drop game must not use that name or its exact pieces). |
| Music and Sound Recognition | n/a | Owner decision | - | - | none | Drop or restrict | Instrument "music" quizzes conflict with positions many users hold; keep nasheed (voice) content separate. Owner decides. |
| Ramadan Challenges "Good Deeds Checklist with points" | n/a | Policy conflict | - | - | none | Do not build as designed | Points for worship acts break the owner's own rule (6.2). A points-free "Ramadan games" row is fine; the existing Ramadan Mode screen already covers the season. |
| Tournaments, weekly challenges with rewards | n/a | Policy conflict | - | - | none | Do not build | See 6.3. |

---

## 4. Recommended information architecture

### 4.1 One bottom nav

The designs show five versions:

| Version | Tabs |
|---|---|
| A (setup, details, waiting, history screens, final batch) | Home, Learn, Games, Family, More |
| B (the newest Home, Islamic Games, Games Hub variants) | Home, Faith, Family, Hādi, You |
| C (Chess/Ludo page set) | Home, Learn, Games, Family, Profile |
| D (generic game screens) | Home, Games, Progress, Profile |
| E (one Games landing) | Home, Faith, Family, Games, You |

**Recommendation: keep the current locked nav, Home, Faith, Family, Hādi, You. It equals version B, which is also the newest Home screen the owner designed.** Reasons: it is already built and tested (`family_tab_test`, Elder Mode redirect); Hādi is the product's core and the design shows it as a tab on Home; adding a Games tab means dropping Faith, Family or Hādi, or growing to six tabs, which fails at 2x text scale (each tab needs about 56 px width plus a 12 px label).

Where Games lives then:

1. Home tile "Games" (already in the Home design) and the "Continue Playing" row.
2. Explore list (already there).
3. Kids Corner door (already there).
4. Inside Wasia Academy (new, section 4.3).
5. Search destinations (already there, extend keywords).

To keep the nav visible on the Games hub (the designs show it everywhere), move `/games` into the Home branch of the shell, exactly as `/noor` and `/journey` are. Individual game screens stay full-screen outside the shell with a back arrow (a board game needs the whole screen; a bottom nav under a Ludo board invites mis-taps). Owner decision D3.

The current nav shell needs no code change in phase 1. "Learn" and "More" tabs from other versions are not built; Academy stays reached from Home, Explore and Menu (and Faith). If the owner later insists on a Learn tab, it replaces nothing: it would need a sixth tab, which this plan advises against.

### 4.2 Games hub structure

Route tree (all need `route_titles.dart` entries; only new routes listed):

```
/games                      Hub (chips: All, Islamic, Strategy, Family, Mind, Words)
/games/history              Game History (local)
/games/yourturn             Your Turn (phase 2)
/games/g/:id                Game details (rules, modes, "How to play", Play, Invite by code)
/games/g/:id/setup          Setup (mode, players, questions, difficulty, hints)
/games/g/:id/play          In-game (engine host)
/games/g/:id/results        Results
/games/settings             Sound, vibration, board theme, hints, animations, confirm moves
```

Existing `/games/ludo`, `/games/shatranj`, `/games/trivia`, `/games/names99`, `/games/lineage`, `/games/ayah`, `/games/hijrah` stay and are aliased in the registry so no deep link, search destination or test breaks. Hub sections are generated from the registry, so adding a game is one registry entry.

Do not show a game card for anything not built. The hub shows only live `GameDef`s; "coming soon" cards are allowed only in a single clearly labelled "Coming later" strip (the app already has an honest-labels rule, `content_policy_screen.dart`).

Drop from the hub: star ratings, "Popular Games" as a popularity claim. Use "Start here" (editorial) and "Continue" (the person's own).

### 4.3 Where Wasia Academy lives and how Games relates

Wasia Academy stays at `/academy`, reached from Home, Explore, Menu, Kids. It is not a nav tab. In the Academy:

- **Lesson step kind `game`.** Add `AcademyStepKind.game` with `gameId` and `contentSetId`. The lesson player opens the game in "lesson mode": fixed question set, hints allowed, no timer, no ranking, no coins. On finish it returns a result to the step, the step completes if the score passes the lesson's threshold (reuse `AssessmentEngine` rule: mastery, wrong answers reteach).
- **Course page and Academy home** get a small "Practise with a game" row for each course that has at least one game step.
- **Review Queue.** A game question that belongs to a lesson's `ContentSet` can feed `ReviewQuestion` (they already have the same shape), so a missed ayah or letter returns in spaced review. No new scheduler.
- **Games hub** shows the same learning games with a small "Wasia lesson" tag and a "Open the lesson" link. One game, two doors.
- **Which games belong where.**
  - Wasia and Games (both): Qur'an Knowledge, Ayah Completion, 99 Names, Letters, Arabic Words, Seerah, Hadith, Salah/Wudu order, Hajj map, Memory (with lesson-linked card sets), Lineage.
  - Games only: Ludo, Chess (except Learn Chess lessons, which are also a Wasia course), Sudoku, 2048, Maze, Jigsaw, Geometry, Tangram, other pure-logic games.
  - Wasia only: nothing at first. Lessons without a game keep the current `check` step.
- **Family Wing.** The active child (`active_child_banner.dart`) is the profile that game results attach to in "Play as a Family (same device)". All stored on the device (the privacy text stays true).

### 4.4 One engine, one registry (so a game is a lesson step AND a Games entry)

Proposed layout (new folder `lib/features/games/engine/`, pure Dart where possible so it can be tested with the plain Dart SDK, as the repo already does for rules):

```dart
class GameDef {
  final String id;             // 'qk', 'ludo', 'memory' ...
  final String titleKey, blurbKey;
  final GameCategory category; // islamic, strategy, family, mind, words
  final Set<PlayMode> modes;   // solo, passAndPlay, asyncRoom, live
  final int minPlayers, maxPlayers;
  final AgeBand ages;          // all, 5plus, 8plus ...
  final String route;          // existing or new
  final bool learning;         // true => may appear as a Wasia step
  final List<String> contentSetIds;
  final VerifyLevel verify;    // none, source, scholar (blocks release until cleared)
  final String? artKey;        // asset key, falls back to code-drawn art
}

class ContentSet {
  final String id, titleKey;
  final List<Question> questions;   // ONE model replacing TriviaQ/AssessmentItem/ReviewQuestion
  final List<Citation> citations;   // per question: book, number, or surah:ayah; shown after answering
  final String? lessonRef;          // 'path.u2.l1' when it belongs to a Wasia lesson
}
```

- `Question` = prompt, options, answerIndex, `why`, `citation`, optional hint text (static, from the data, never an AI call), optional glyph.
- Engines: `QuizEngine` (multiple choice and fill-the-word), `OrderEngine` (sequence ordering: wudu steps, seerah timeline, surah order), `PairsEngine` (memory, matching), `BoardEngine` (ludo, chess, later checkers/reversi/four in a row sharing a turn/move/undo contract), `GridEngine` (sudoku, 2048, sliding, maze).
- `GameSession` = engine state + players + mode + seed; serialisable to JSON so the same object is (a) saved locally for "Continue", (b) a `game_rooms` move payload in phase 2, (c) a lesson step result.
- Content packs: new JSON under `assets/games/` or downloadable via `ContentSync` (the app already downloads content packs, checksum-gated; follow `docs/OWNER_ACTIONS.md` item 1 about branch protection before adding any bot-updated pack). Do not touch the catalogue or `kCatalogSha256`; if a new pack is added to the manifest it must follow the existing pack-shape tests.
- Registry is a Dart const list (like `kKidsDoors`, `kAcademyCourses`) so it cannot be changed remotely and tests can assert: every route has a title, every `GameDef` with `verify != none` has a verification log entry, every Wasia `game` step points to a real `GameDef` and `ContentSet`.

---

## 5. Multiplayer reality check

### 5.1 What the app really has

Correction to the working assumption "no backend": there IS a minimal one. `GameRoomsService` creates a Firestore document `game_rooms/{code}` with host, guest, turn, a `moves` map, 24 h `expireAt`; rules allow create, get by code, a guarded update, no listing; auth is Firebase Anonymous. Two phones can play Ludo or Shatranj by sharing a six-letter code today, once the owner publishes the Firestore rules and turns on the TTL policy (OWNER_ACTIONS 2 and 2b). It is gated on the Firebase switches and degrades honestly.

What it does not have: identity beyond an anonymous uid, friends, presence, invitations that arrive, push, history, server-side validation (dice and moves are trusted from the mover), anti-cheat, moderation, reporting, more than 2 players, any game other than `ludo` and `shatranj` in the rules allow-list.

### 5.2 What each designed screen needs

| Design | Needs | Phase |
|---|---|---|
| Solo, "Play vs Computer", "Play as a Family (same device)" | nothing | 1 |
| Game Setup (mode, players, questions, difficulty, hints) | nothing | 1 |
| Waiting Room with Game Code and copy | existing room code; add share sheet and QR (`qr_flutter` is already a dependency) | 2 |
| Invite Players (Family/Friends/Recent, search, Online dots) | accounts, friend graph, presence | 3 (and only with parental controls) |
| "Send Invitations" | replace with "Share invite link/code/QR" through the OS share sheet | 2 |
| Your Turn / Waiting for Others | the device remembers the room codes it has joined; poll or listen each (`get` by code is allowed; `list` is not and must stay so); no server list needed | 2 |
| "It's your turn" notification | push (FCM) plus a server that watches rooms; not in dependencies today | 3 |
| 3 or 4 player rooms | rules currently allow one guest; schema change (`players` array), rule update, Ludo 4-player board | 2 (Ludo 4 is L effort) |
| Online presence dots, Recent players | presence service, privacy decisions | 3, probably never for children |
| Chat | moderation, reporting, child safety | Not built. See 5.4 |
| Server-side dice, anti-cheat | Cloud Function or equivalent (the code comments already say so) | 3 |
| Game history synced across devices | account | 3 |

### 5.3 Phases

**Phase 1: solo and pass-and-play (no backend, works offline).** All content games, Ludo and Chess vs Hadi or the same device, Family Wing profiles as player names, local history and "Continue" (SharedPreferences, last 50 sessions, device only). Zero cost.

**Phase 2: invite-code rooms (reuses what exists).** Extend `game_rooms` rules: allow-list adds the new game ids; add `players` (max 4) and `version`; keep no-list, TTL, name validation. Share via link/QR. Your Turn screen from locally remembered codes. Each remembered room costs one document read per refresh (cache and refresh only when the screen is open). Cost, order of magnitude (verify against current Firebase pricing before launch): a 40-move two-player game is about 40 writes and 80 to 120 listener reads. The Firebase free tier (roughly 50k reads and 20k writes a day at the time of writing) covers a few hundred games a day; past that cost is cents per thousand games. The real costs are operational: rules publication, TTL, abuse monitoring.

**Phase 3: live and social.** Only after: a decision on accounts; a parental-consent design (verifiable consent for under-13s is a legal topic for the lawyer in OWNER_ACTIONS item 6); push; server-authoritative dice and move validation; moderation. Not before.

### 5.4 Children's privacy and safety rules for multiplayer

- **No chat for any child profile, ever.** For adults, phase 2 offers a fixed list of quick phrases (for example "Good game", "Your turn", "Well played") and no free text. The 200-character invite message and the Ludo "Chat" button from the designs are dropped.
- **No friend discovery, no search by name, no public lobbies, no matchmaking with strangers.** Rooms are private codes. A child can only join with a code a parent has been shown (parent gate, as the Family Wing already does).
- **Names:** first name or nickname the parent chose (existing rule, max 30 chars), passed through the existing `validName` rule; never the real family name, never a photo (the designs show cartoon and photo avatars: use code-drawn initials or a small fixed set of drawn avatars).
- **No presence ("Online" dots), no "last seen", no location.**
- **Under-13 profiles: online play is off by default**; a parent turns it on per child, behind the parent gate.
- **Data:** room documents hold uid, display name, moves, nothing else; 24 h TTL; no analytics; update `children_privacy.dart` and bump `kChildrenPrivacyVersion` in the same commit as the first online-for-children feature (the file says to do that).
- **Reporting:** a "Report this player" button writes to a new `game_reports` collection the owner reviews (mirrors `hadi_report_service.dart`). Needs an owner decision on who reads the reports.
- **Moderation reality:** with no named moderator, do not ship anything that carries user-written text between users.

---

## 6. Content-safety rules (for games)

### 6.1 Verification

1. Every Qur'an, hadith and seerah question or answer must come from a bundled, already-audited source (Tanzil text; `nawawi40.json`; `huda` guides; the audited story chapters; `kSurahIndex`) or from a new `docs/content_needed/*.md` file the owner approves. The app never invents rulings, hadith, duas or translations; an AI model never writes quiz content shipped to users.
2. Each question carries a citation (book and number, or surah:ayah, or story id and chapter) that is shown after the answer ("Verified Source" box as in the design, but only when it is true: the box says what was actually checked and the label policy from `content_policy_screen.dart`, "Not yet scholar-reviewed", still applies until a named reviewer exists).
3. Questions generated from lesson text follow `recall_check.dart`: no questions on sentences that quote, cite, name a hadith book, or contain Arabic; the `kRecallExcludedLessons` list is honoured.
4. Hadith questions never assert a grade without the grader's name (existing policy). A question whose answer depends on a graded report is not allowed until graded.
5. A `GameDef` with `verify: scholar` cannot be reachable from the hub in a release build until its log row says cleared (a test enforces this).
6. A "Report this question" link (designed) writes to the existing report path, not to a server nobody reads.

### 6.2 No points for religious acts; no worship gamification

- No score, coin, point, badge or rank is awarded for prayer, fasting, Qur'an reading, charity or any act of worship. The "Good Deeds Checklist (+50 points, 7 day streak, 320 total points)" screen is NOT to be built as designed. Worship tracking stays as it is (private, no points; `return_loop.md`).
- Scores belong only to game performance (answers right, moves, time in a board game). A learning-game score is shown as "8 of 10", never as a measure of faith, and never compared between children.
- Streaks: only the owner-approved "days returned". Games do not add streak counters, daily-challenge streaks, "don't lose your streak" messaging, or loss language.

### 6.3 No gambling-like or manipulative mechanics

- No loot boxes, mystery rewards, spin wheels, random rewards, paid retries, or real-money anything.
- **Hints are not currency.** The designs show "Hint (5 points)", "-50 pts", and "coins". Replace with a fixed number of free hints per game (the designs' "3/3" model). Hints can never be bought, earned by playing more, or traded. No coin balance anywhere.
- No ads, no third-party SDKs in games, no analytics, no tracking, no ratings or reviews, no "popular" counters.
- No dark patterns: no countdown pressure on children, no fake urgency ("only 2 hours left"), no guilt copy ("you lost"; the Chess history design shows red "You lost" and X marks: use neutral wording), no auto-renewing paywall inside a game, no pushing to invite contacts, no leaderboard of children.
- Timers: religious and learning quizzes have no timer (matches the Academy charter: "nothing is timed"). Timers allowed in board games (chess clock, optional) and in the memory game as an optional best-time stat.
- Rank lists in a family game are shown as "played together" with equal weight for children; trophy icons only in adult or solo contexts. Owner decision D6.

### 6.4 Specific items in the designs that need a decision or a change

| Where | Issue | Action |
|---|---|---|
| Qur'an quiz sample question "Which Surah is known as the Heart of the Qur'an? Yaseen" | The saying is a hadith report about Ya-Sin that many hadith scholars grade weak. A question that teaches it as fact conflicts with the app's grading rule. | Do not ship this question. Use verifiable surah facts (names, order, ayah counts, verbatim completion). If the owner wants it, it needs a graded citation and wording like "a report states ..." and scholar review. |
| Checkers screen carries a Qur'an 2:153 banner | A verse used as decoration on a board game; a verse quoted must be the verbatim Tanzil text with reference and fit its meaning. | No Qur'an verses on non-religious games. Verses appear only where the game is about that verse. |
| Wudu results "Hadi reflection with Qur'an 2:222" | 2:222 is a verse mainly about menstruation and repentance/purity; attaching it to a wudu result is a meaning claim. | Wudu result text must come from `huda-wudu` and its sources (for wudu the guide cites 5:6). Any added reflection needs Scholar. |
| Hajj map result with Qur'an 22:27 | Plausible (call to Hajj) but must be shown verbatim from the bundled text with number. | Show only if the string comes from `quran.json`. |
| Seerah "How do you respond? Respond with patience / Seek guidance / Protect the message" | Teaches what the Prophet's example implies in a situation: new religious guidance, with "correct" answers. | Scholar content. Until cleared, the Seerah game is order/timeline/fact only, built from the audited chapters. |
| Salah Steps "6 of 7" and per-step feedback, Hadi note | Feedback text must not add rulings. | Feedback = the guide's own step text plus its citation. |
| "Learn with Translations" | Uses a translation. | Bundled English is Saheeh International (licence unresolved, OWNER_ACTIONS 5; Clear Quran preferred but not in the repo). Do not add a second translation to games until the owner decides. |
| Recitation Challenge "listen, recite, get feedback" | Speech recognition of Qur'an recitation is accuracy-sensitive, needs microphone permission and a recogniser; wrong feedback on tajweed is a religious-content risk and child voice data is a privacy risk (the privacy text says no voice). | Do not build. |
| Arabic Words with pronunciation audio | Needs licensed recordings; device TTS is poor for Arabic. | Wait for audio source. |
| Music and Sound Recognition | See table row. | Owner decision. |
| Ramadan Challenges with points and streak | 6.2. | Do not build as designed. |
| Ratings, popularity numbers | No data, would be invented. | Remove. |
| Time pressure in Hadith/Qur'an quizzes | Conflicts with the Academy charter. | No timer. |
| Avatars with photos and cartoon faces of named users | Child privacy, depiction questions for some users. | Initials or abstract drawn avatars. |

### 6.5 Existing-content gating

Anything flagged in `docs/story_audit.md`, `docs/content_needed/*` as awaiting a scholar stays out of games. The "Disputed in the sources" items (OWNER_ACTIONS item 4) are never question material.

### 6.6 Note for the owner: dice and board games

This is a request for your decision, not a ruling from me. Chess and games with dice are discussed by Muslim scholars with different conclusions, in particular about dice games (nard/backgammon style) and about games that involve stakes or distract from prayer. I have not tried to decide it. What the plan does regardless: no stakes of any kind, no real or virtual money, no gambling framing; a short "play in moderation, prayer times come first" reminder is possible and is optional; the Ludo dice is a plain random roll with no betting element. Suggested step: ask your reviewer scholar (OWNER_ACTIONS 4) a precise question: "Is a no-stakes Ludo and Chess acceptable inside an Islamic app for adults and children?" and record the answer. If the answer is no for either game, remove it from the hub; the registry makes that a one-line change. Decision D2.

---

## 7. Theme specification: dark-gold "mosque at sunset"

### 7.1 What the design uses (sampled from the final-batch images)

| Token | Value (sampled / nearest existing) |
|---|---|
| Page background | near-black navy `#000410` to `#00090D` (existing `night #05090F`, use it) |
| Panel fill | `#010F16` at about 85% over art; glass look (existing glass fill `0x1AFFFFFF`) |
| Gold CTA gradient (Play Now, Continue, Start Game) | top `#FFD367`, middle `#E2A63F`, bottom `#CE8D2C` (existing `goldGradient` is `#EED488, #D4AF37, #B08A24`: close, slightly paler; add `playGradient` with the sampled stops) |
| Gold border (panels, chips, tiles) | 1 to 1.5 px, gold at 70 to 100% with soft outer glow (existing glass card border is gold at low alpha; add a "bright" variant) |
| Title text | champagne `#FFF6C8` with a subtle gold gradient (existing `GoldText`) |
| Body text | sand `#EAD6B4` and white-ish (existing `textPrimary`, `textMuted`) |
| Selected chip / segmented control | solid gold gradient with dark navy label |
| Unselected chip | transparent navy with gold 1 px border, gold or cream label |
| Success | muted green fill with green check (Waiting Room "Joined"): `#2E7D5B`-ish on dark; keep contrast >= 4.5:1 |
| Presence dot | green, grey (not used: no presence in the app) |
| Card radius | 20 to 24 (existing 20) |
| Header | an arch ("ogee"/pointed-arch) outline in gold framing a skyline banner, back button left in a gold ring, search or bookmark right in a gold ring, lantern frames at the edges, crescent and star above the title |
| Skyline art | mosque silhouette at sunset with palms, water reflection, lanterns, pink flowers |
| Bottom nav | rounded capsule with gold hairline, active tab as a lifted gold-glow pill, outline icons in gold |
| Typography | serif display for titles (the designs look like Playfair/Cormorant; the app ships Playfair Display, keep it), humanist sans for body (Inter), Amiri for Arabic |
| Icons | thin-line gold outline in a circular gold ring (list rows), solid gold for tile icons |
| Pattern | faint eight-pointed star lattice behind panels (existing `bg_pattern.jpg`) |

Finding: this is the existing "Locked" system plus art. Home already uses a golden-hour mosque garden (`bg_home.jpg`), community lanterns, a pattern background, `GlassCard`, `GoldButton`, gold-ring `ScreenHeader` buttons. The new design adds: the arch header, brighter gold, lantern frames, larger tile cards with art, and chips.

### 7.2 How to implement it in Flutter without bundling the mockups

Never copy the design images into `assets/` (each is about 2.5 MB, 150 of them is 380 MB; they are screenshots with text and fake avatars). Rebuild with code and a small set of purpose-made assets.

Layers, each with a code-drawn fallback so every screen works the day it is wired:

1. **`GamesTheme` tokens** (new file `lib/app/theme/games_theme.dart`): `playGradient`, `goldBorderBright`, `panelFill`, `chipSelected`, `chipIdle`, radii, spacing, text styles built on `AppText`. All colours via `AppColors` constants so `theme_a11y_test` can pin contrast.
2. **`ArchHeader` widget** (new, `theme/widgets/arch_header.dart`): a `CustomPainter` that draws a pointed arch (two quadratic/cubic curves meeting at a point), gold stroke with glow (`MaskFilter.blur`), crescent-and-star above the title, back and trailing slots (must use `IconButton` with `tooltip:`; `icon_button_labels_test`). Fallback body: a vertical gradient from deep navy to a warm amber horizon band plus a programmatically drawn skyline (domes and minarets as simple paths) and a few "star" dots. With art present, it paints the image behind the arch clip. This is one widget, reused by every game screen.
3. **`SkylineBackground`** (variant of `ScenicBackground`): reuses `assets/images/bg_home.jpg` (already shipped, 1 MB) or the pattern, with the existing night gradient overlay; no new asset needed for phase 1.
4. **`GameTile` and `GameRow`** (new): card with art on one side and gradient scrim. Fallback art = gradient plus a large gold line icon (the designs' category icons: dome, dice, A-B tiles, puzzle, people, controller are all in `Icons`/drawn as paths). `GlassCard(blur: false)` inside lists (the card comment says blur on long lists is costly).
5. **Chips, segmented control, stat strip, progress bar, pill nav**: small stateless widgets on tokens. Nav stays `AppBottomNav`.
6. **Pattern fill** for locked/empty states: the lattice from `bg_pattern.jpg`, or a `CustomPainter` eight-point star tile.
7. **Gold glow** for selected items via `BoxShadow` (cheap) not repeated `BackdropFilter`.

Fonts: no change (Playfair, Inter, Amiri already bundled).

### 7.3 Art assets the owner or designer must supply (all optional for phase 1)

Format: WebP or JPEG, 1x and 2x not needed (Flutter scales), sRGB, no baked-in text, no real people, no faces. Dimensions are for the largest use; budget in section 9.

| # | Asset | Use | Size | Budget |
|---|---|---|---|---|
| 1 | Games header skyline (mosque at sunset, palms, lanterns frame, no text) | `ArchHeader`, hub | 1080x640 | <= 150 KB |
| 2 | Two header variants (night, dawn) | optional themes | 1080x640 | <= 150 KB each |
| 3 | Category tile art: Islamic, Board, Words, Puzzles, Family, More | hub | 600x400 | <= 35 KB each |
| 4 | Game art: Qur'an Knowledge (open mushaf on stand), Seerah (caravan, dunes), Hadith (books), Prophets path, Islamic History (old city), Salah/Wudu (silhouette at prayer, water), Names (calligraphy medallion), Arabic Words (letter tiles), Memory (card backs and 8 face images), Chess board, Ludo board, Jigsaw scene, Logic tiles | tiles and details | 600x400 | <= 35 KB each (about 14 images, 0.5 MB) |
| 5 | Memory card faces: Kaaba, lantern, crescent, mosque dome, mushaf, date palm, desert dune, oasis | memory | 256x256 | <= 12 KB each |
| 6 | Ludo token and dice art (or keep code-drawn, already gem-gradient painted) | Ludo | vector | code |
| 7 | Chess piece sets: keep the existing hand-drawn set; extra "Arabic style" set only if wanted | chess | vector | code |
| 8 | Hajj map (Makkah, Mina, Arafat, Muzdalifah, Jamarat), schematic, no photos | Hajj map | 1080x1080 | <= 120 KB |
| 9 | Avatar set: 8 to 12 abstract/illustrated avatars, no photo realism, mixed, optional | profiles | 128x128 | <= 6 KB each |
| 10 | Lantern frame corner pieces, arch ornament (SVG or PNG with alpha) | header edges | 400x600 | <= 30 KB each |
| 11 | Trophy / "complete" illustration (adult and solo only) | results | 512x512 | <= 40 KB |

Everything must be owned or licensed for commercial use; keep a source line per file in `docs/` (the repo has an asset audit test; `asset_audit_test.dart` fails if a referenced path does not exist, so reference art only when the file is committed, and always keep the code fallback via `errorBuilder`, as `ScenicBackground` does).

### 7.4 Contrast and legibility

Gold on navy passes AA. Gold text on the amber sunset area does not: the designs put white or champagne titles over a bright sky. Always put a dark scrim (>= 55% navy) under header text, or keep text on the navy panel below the art. Keep the `textFaint` floor (70% sand) and the 12 px minimum (an existing audit test enforces no font under 12 px).

---

## 8. Accessibility

- **Elder Mode.** Games hub in Elder Mode: three large cards (Qur'an Knowledge, 99 Names, Memory) plus "All games", no filters, no carousel, no timers, no "continue" strip beyond one card, bigger hit targets (>= 56 px). Chess/Ludo allowed but behind "More games". Elder home (`/home/elder`) keeps its three doors; Back from games goes to the Elder home (the header already handles that).
- **Large text to 2x.** All chip rows are `Wrap`, not `Row`; stat strips wrap to two lines; quiz option buttons grow in height; `WholeWordText` (exists) for labels; boards scale with `LayoutBuilder` and never rely on text inside cells. Add each new screen to `large_text_layout_test.dart` and `widget_audit_test` (they already sweep screens).
- **Min 12 px**, 48 px touch targets, gold focus ring (`FocusRing` exists), keyboard navigation for web (arrow keys on boards, Enter to select, Esc back; `keyboard_back.dart` exists).
- **Tooltips.** Every `IconButton`/FAB gets `tooltip:` (CI test).
- **Screen reader.** Board games expose a semantic description of the current position and announce each move ("Red token moved 4 squares"; "Knight to f3"); quiz questions are real text, not images; results are announced. Do not use colour alone: Ludo colour teams also get a symbol or number; chess uses piece shapes (already vector); correct/wrong answers use icon plus text plus colour.
- **Reduced motion.** Honour `MediaQuery.disableAnimations`; the "Enable Animations" setting in the design maps to it.
- **RTL.** Arabic content (letters, ayah) is RTL; the shell chrome follows the locale; boards and dice are never mirrored; ordering games with Arabic words flow right to left. The app has `app_locale.dart` for languages; test one RTL pass on each new screen with Arabic text.
- **Sound.** Optional, off for Elder Mode? Default per existing `sfx_provider`; haptics via `HapticFeedback` (no new dependency), with the Vibration toggle.
- **Dyslexia/colour-blind**: the gold-on-navy palette is safe; avoid green/red as the only correct/wrong signal.

---

## 9. Asset and size budget, performance, offline, privacy

**Size.** Current assets 15 MB. Proposed games additions: art about 2 to 3 MB total (section 7.3), question packs about 200 to 400 KB of JSON (1,500 questions at about 250 bytes). Budget: games add at most 4 MB to the bundle; anything bigger (Hajj map, jigsaw scenes, audio) ships as a downloadable pack through `ContentSync` (matches the owner's wish that every content type can be downloaded to the device). The PR check already reports web bundle size; do not let `main.dart.js` grow more than about 150 KB gzip from the game engines.

**Performance.**
- Boards drawn with `CustomPainter`; `RepaintBoundary` around boards and the dice.
- Hub lists use `ListView.builder`/`SliverGrid`; `GlassCard(blur: false)` in lists; at most one `BackdropFilter` per screen (the nav already uses one).
- Precache only the hub header; lazy-load tile art with `errorBuilder` fallback.
- Chess AI and any search: depth-capped and time-sliced (`await Future<void>.delayed(Duration.zero)` between iterations) since web has no isolates for this engine; easy/medium/hard = depth 2/3/4 with a node budget so a low-end phone never freezes.
- No per-frame allocations in painters; images decoded at display size (`cacheWidth`).
- Keep `unawaited_futures` clean; cancel timers and listeners in `dispose` (online rooms already use streams: unsubscribe).

**Offline.**
- Phase 1 games fully offline: bundled data or downloaded packs. The "Needs internet" view (`needs_internet_view.dart`) only for online rooms and pack downloads.
- Saved sessions and history in SharedPreferences (key prefix `ar.games.`), capped (last 50 results, 1 saved session per game), cleared by an existing "delete my data" path, and by switching profiles in Family Wing.
- Online rooms: honest status ("Waiting for the other player", "You seem to be offline"), moves queued only by Firestore's own cache; never claim "connected" without a server round trip (existing `netTimeout` approach).

**Analytics-free.** No analytics SDK, no event logging, no crash reporter receiving child data (matches `kChildrenPrivacyBody`). "Popular", ratings and play counts are not computed. Local history is the only record and never leaves the device in phase 1.

---

## 10. Phased build plan

### 10.1 Screens that can be WIRED NOW with existing data and logic

(Phase 1 deliverable. "Wire" = build the screen in the new theme and connect it to code or data already in the repo, no new religious content, no backend.)

| # | Design screen | Wired to | Notes |
|---|---|---|---|
| 1 | Games Hub (chips All/Islamic/Strategy/Family; sections) | registry of the 7 existing games | Only real games. No ratings. "Continue" only after step 8. |
| 2 | Islamic Games list | Trivia, Ayah, 99 Names, Lineage, Hijrah | Seerah/Hadith/Salah cards appear only when built. |
| 3 | All Games Collection grid | same registry | |
| 4 | Home "Games" tile and banner "Build Your Knowledge Through Play" | `AppRoutes.games`, `home_screen.dart` tiles | Touches the Home screen: coordinate with the Home owner, tiny diff. |
| 5 | Game Details (Ludo, Chess, Qur'an Knowledge, Trivia, 99 Names) | `GameDef` + static rules text | "How to play" static text (non-religious, authored). |
| 6 | Game Setup (mode Solo / Family same device, players, questions 5 to 30, difficulty, hints toggle) | quiz setup over Trivia and Ayah Completion; chess difficulty = engine depth; Ludo = existing 3 modes | Questions count capped by pool size. Qur'an Knowledge = Ayah Completion + surah facts from `kSurahIndex` (hundreds of verified items); trivia pool is only 40, so do not offer 30 questions on trivia. |
| 7 | In-game quiz screen (progress bar, options, hint, next, skip) | Trivia / Ayah data with `why` shown after answer | Remove timer, remove "points" on hints; hints = fixed 3 free per game, hint text from data. 50/50 is fine (removes two wrong options). |
| 8 | Results screen (score "8 of 10", per-player list for pass-and-play, Play Again, Back to Games) | local session | Neutral wording; no rank trophies for children. |
| 9 | Game History (filters All/Islamic/Completed/Ongoing) and "Continue Playing" | new local store `ar.games.history`; Trivia/Ayah sessions resumable | Needs a small saved-session store (the only new logic). |
| 10 | Game Settings (sound, vibration, hints, animations, confirm moves, board theme) | `sfx_provider`, `HapticFeedback`, existing chess board colours | Board themes: the Shatranj board has a gold look; add 2 colourways in code. |
| 11 | Chess in-game, Ludo in-game | existing screens, re-skinned header | Undo/Draw/Resign/clock are NOT wired now (need engine work, phase 1b). |
| 12 | Waiting Room (code, copy, share, QR) | `GameRoomsService` + `OnlineLobby` + `qr_flutter` | Show the code and "Share"; players list only 2 slots. Needs the Firebase switches on. |
| 13 | Ask Hadi (in-game help) | "Explain the rules" = static rules; "Tell me about this game" = static; Islamic questions deep-link to `AppRoutes.hadiAsk(...)` | No AI call from inside a game. "Best move" and "Give me a hint" for chess = the engine's own suggestion (existing `_search`), not Hadi AI. |
| 14 | Memory game (Islamic Memory) | letters (28) and 99 Names pairs, text cards with pattern backs | Requires the new `PairsEngine` (small). Kaaba/lantern face art later. |
| 15 | Wasia: lesson "Practise" step | existing `check`/`action` steps routed to `/games/...` | Interim: an `action` step that opens `/games/ayah` etc., before the real `game` step kind exists. |
| 16 | Kids Corner door | existing | Add "Games for children" filter once age bands exist. |

### 10.2 Numbered phases

**Phase 0: decisions and foundations (1 to 2 weeks).**
1. Owner answers D1 to D10 (section 12).
2. Add `games_theme.dart`, `ArchHeader`, `GameTile`, chips (code-drawn fallbacks). Visual test via `theme_demo_screen.dart` (dev route exists).
3. Add the registry and the unified `Question` model; adapt `TriviaQ`, Ayah rounds, Lineage rounds to emit it (pure Dart, unit-tested with the repo's plain Dart SDK trick). Keep all current routes and titles.
4. Route titles, search destinations (keywords: quiz, memory, trivia, chess, ludo, games), registry tests.

**Phase 1: Games section, solo and pass-and-play (3 to 5 weeks).**
5. Wire items 1 to 11, 13, 14 of 10.1.
6. Local history and resume store; Game Settings.
7. Qur'an Knowledge with three verified question types (ayah completion, surah by number/name, surah ayah count); Trivia rename to "Stories Trivia" so the two are not confused.
8. Chess: castling and en passant, undo, resign, optional clock, difficulty levels. Ludo: keep two players, add an optional on-device 4-player mode (S to M, `LudoRules` already takes any number of players; the board painter is the work).
9. Memory (PairsEngine).
10. Pass-and-play with Family Wing profiles (names from the active child only after the parent gate).

**Phase 2: Wasia integration (2 to 3 weeks, can run alongside late Phase 1).**
11. `AcademyStepKind.game` plus `gameId`/`contentSetId` on `AcademyStep`; lesson player embeds the engine in lesson mode; manifest tests extended (every game step references a real game and set).
12. Content sets tied to lessons: Letters drills (existing), Salah/Wudu ordering from `huda-wudu`/`huda-prayer` steps, Ayah and surah sets for Qur'an lessons, Names sets.
13. Review Queue hook: wrong answers enter FSRS as `ReviewQuestion`s.
14. "Practise with a game" row on course pages and Academy home; Games hub "Wasia lesson" tag.

**Phase 3: invite-code rooms (3 to 4 weeks, needs the owner to publish Firestore rules and TTL first).**
15. Rules and schema: allow new game ids, `players` up to 4, versioning, keep no-list; update `firestore_rules_hardening_test`.
16. Share invite (OS share sheet, QR), Waiting Room for up to 4 with Host/Joined/Waiting states.
17. Your Turn list from locally remembered room codes; refresh on open.
18. Async quiz rooms (everyone answers on their own device within 24 h): needs a result-merge rule; start with 2 players.
19. Quick-phrase reactions only, report button, parental switch "Allow online games" per child.
20. Update `children_privacy.dart` text and version in the same commit; lawyer review (OWNER_ACTIONS 6).

**Phase 4: content-gated games (when the owner supplies content or licences).**
21. Seerah timeline/order from audited chapters; "How do you respond?" scenarios only with scholar-approved text in `docs/content_needed/`.
22. Hadith match from `nawawi40.json` with citations.
23. Arabic Words after the word-list licence (OWNER_ACTIONS 7) and audio source.
24. Hajj map game with map art; Prophets timeline; Islamic History bank.
25. Learn Chess lessons (non-religious, needs authoring) as a Wasia course.

**Phase 5: live and social (not scheduled).**
26. Accounts, push, presence, friends, server-authoritative dice. Only with parental-consent design and moderation. Needs its own plan.

### 10.3 Screens the owner should design next (missing)

Prioritised; each is needed before the matching phase can finish.

1. **Quiz question screens per type** (the designs show only multiple choice): fill-the-word (tap to place), true/false, order the items (drag with up/down buttons for accessibility), match pairs (two columns), image/map pick, "which surah" with Arabic. Include correct, wrong, skipped, and "Verified Source" states.
2. **Wasia lesson-with-game screen**: how a game appears inside a lesson (intro card, in-lesson header with lesson title and step count, result back to the lesson, "try again" and "continue the lesson").
3. **Seerah/Prophets chapter flows**: chapter list with locked/completed, chapter page, timeline-order game, source panel; no "respond" scenarios until the content exists.
4. **Wudu/Salah ordering game**: the ordering interaction, per-step feedback state, result, "open the guide" link.
5. **Arabic word games** (match, spell, scramble) with RTL layout and the "audio unavailable" state.
6. **Hajj map** challenge (map, tap-the-place, result).
7. **Parent controls for games**: per-child switches (online play, time limit, which game categories), parent gate entry, game time summary on the Family Wing, "Allow online games" explanation.
8. **Empty, error and offline states**: no games played yet, no internet for rooms, room full/expired/not found, pack not downloaded, content unavailable, session could not be saved.
9. **Elder Mode variants**: Games hub (three cards), quiz question (large type, no timer), results.
10. **Large-text (2x) variants** of hub, setup and quiz.
11. **Tablet and landscape**: hub grid at wide widths, boards beside the control panel, web at desktop width (the app is Flutter web).
12. **Four-player Ludo** states (turn indicator, captured, waiting for rejoin) and the "pass the phone" interstitial for pass-and-play ("Hand the phone to Aisha").
13. **Chess extras**: undo/draw/resign confirmations, clock states, game-over reasons (checkmate, stalemate, resignation, timeout), promotion picker.
14. **Share/invite sheet** (link, QR, copy code), with the "no stranger" wording.
15. **"Continue" cards and Game History detail** (what a finished game shows, delete history).
16. **Report this question / player** flow.
17. **Game rules / How to play** pages (one template).
18. **Consistent header**: pick one of the two logo header styles; define the compact (scrolled) header variant.
19. **Settings variants** (per game) beyond the one common page.

---

## 11. Risks and what to watch

- **Scope creep from 150 designed screens.** The registry plus five engines covers about 90% of them; the rest is content. Ship the engine and 6 to 8 games, not 40.
- **Content, not code, is the bottleneck.** Religious question banks need a reviewer (OWNER_ACTIONS 4); until then the Islamic games are limited to verbatim text and audited facts.
- **Translation licence.** Games that show an English meaning inherit the open decision on Saheeh International vs Clear Quran (OWNER_ACTIONS 5; `docs/content_needed/CLEAR_QURAN_PACK.md`). Use Arabic-only and transliteration/name meanings in phase 1 where possible.
- **Online rules not published.** Online play and everything in phase 3 depend on OWNER_ACTIONS 2 and 2b.
- **CI is the compiler** (no Flutter SDK locally): each phase is a series of small PRs; pure-Dart engines first so they can be checked with the standalone Dart SDK.
- **Held PRs** (#63, #65, #66, #67) are untouched by this plan; check for overlap with games, theme or nav before Phase 0 begins.

---

## 12. Decisions the owner must make

| ID | Decision | Recommended answer |
|---|---|---|
| D1 | Which nav is final? | Keep Home, Faith, Family, Hadi, You. Games via Home tile. |
| D2 | Are no-stakes Ludo (dice) and Chess acceptable? Ask your reviewer scholar. | Ask; the plan works either way. |
| D3 | Should `/games` sit inside the nav shell (nav visible on the hub)? | Yes for the hub; games full-screen. |
| D4 | Games for children: online play for under-13s off by default, no chat anywhere for children, quick phrases only for adults. | Approve. |
| D5 | Drop points/coins/ratings/rewards/tournaments; fixed free hints; no timers on religious quizzes; Ramadan "good deeds with points" not built. | Approve. |
| D6 | Show ranks and trophies between family members, or "played together" for children? | Trophies only in solo/adult contexts. |
| D7 | Scope of phase 1 Qur'an Knowledge: verbatim and surah facts only until a scholar clears more? Retire the "Heart of the Qur'an = Yaseen" sample question. | Yes. |
| D8 | Who is the scholar reviewer and by when (blocks Seerah scenarios, Hadith bank, Islamic History bank)? | Name one. |
| D9 | Publish the Firestore rules and TTL (OWNER_ACTIONS 2, 2b) so online rooms can be tested. | Do before phase 3. |
| D10 | Art: who produces the assets in 7.3 and by when? Music/sound recognition game: keep or drop? | Phase 1 ships with the code-drawn fallback; drop music quiz. |
| D11 | Header style: compact "Ar-Rayaan The Gate" or the calligraphy "Your gateway to Allah" version? | Pick one; use it everywhere. |
| D12 | Do you want accounts and friends at all (phase 5)? | Not before the app has a moderator and a lawyer-reviewed consent flow. |
