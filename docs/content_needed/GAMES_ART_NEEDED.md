# Games art: what is his exact art, what is patched, what is a fallback

Written 26 Oct 2026. The Games screens now use art cropped from the owner's final dark-gold "mosque at sunset" designs. This file lists every art slot, how good it is, and the clean file to export for each one that is not his exact art.

## How it works

* Files live in `assets/games/art/`, named after the slot (`hubHeader.webp`, `cornerOrnament.png` ...). `assets/games/art/manifest.json` records, for each slot, the source screenshot and the crop box.
* `tool/crop_game_art.py` rebuilds all of it from the screenshots: `python3 tool/crop_game_art.py --src <folder with the screenshots>`.
* In the app, `GamesArt` (`lib/features/games/ui/games_art.dart`) looks at which files are bundled. A slot with no file draws the old code-drawn look, so a missing file never breaks a screen.
* **To replace a slot:** export the new file with the same name and extension, put it in `assets/games/art/`, and rebuild. Keep the file under about 150 KB. The whole folder is capped at 4 MB by `test/audit/asset_audit_test.dart`.
* **To fill a fallback slot:** drop the file in with the name below; the app picks it up where that slot is used.
* Never exported or cropped: human photos or faces (avatars stay initials), anything showing a prophet. The Family tile shows dark silhouettes from behind, no faces.

## Totals

| | Slots |
|---|---|
| Exact (a plain crop of his screenshot, nothing removed) | 23 |
| Patched (text or buttons painted out, or cut out of a dark background) | 3 |
| Fallback (no usable crop, drawn in code) | 11 |

## Slots that have a file (exact and patched)

"Exact" slots are his art at the pixel size of the screenshot. They are sharp at the sizes shown on a phone and soft if enlarged, so a 2x export is welcome but not needed.

| Slot | Kind | Size now | Cropped from | Used for |
|---|---|---|---|---|
| `hubHeader` | patched | 941x430 | All Games Collection | Hub header (`ArchHeader`); tagline sits in the dark sky |
| `skylineBand` | exact | 941x222 | Qur’an Knowledge waiting room | Slim header strip on setup, history and the community page |
| `categoryIslamic` | exact | 238x126 | Games landing, six category cards | Hub section heading: Islamic |
| `categoryBoard` | exact | 231x126 | Games landing, six category cards | Hub section heading: Strategy (board games) |
| `categoryWords` | exact | 239x126 | Games landing, six category cards | Hub section heading: Words and puzzles |
| `categoryPuzzles` | exact | 238x122 | Games landing, six category cards | Not shown yet (no puzzle games on main) |
| `categoryFamily` | exact | 231x124 | Games landing, six category cards | Hub section heading: Family |
| `categoryMore` | exact | 237x124 | Games landing, six category cards | Not shown yet (no "More games" section) |
| `gameQuranKnowledge` | exact | 306x172 | Game Setup, Qur’an Knowledge | Qur’an Knowledge tile, history row |
| `heroQuranKnowledge` | exact | 798x347 | Qur’an Knowledge details | Qur’an Knowledge page banner |
| `gameStories` | exact | 240x110 | Islamic Games list | Stories Trivia tile |
| `gameNames99` | exact | 240x110 | Islamic Games list | The 99 Names tile |
| `gameLineage` | exact | 240x110 | Islamic Games list | Lineage Challenge tile |
| `gameHijrah` | exact | 240x110 | Islamic Games list | Hijrah Journey tile |
| `gameHadith` | exact | 240x110 | Islamic Games list | Not shown yet (no Hadith game) |
| `gameHifz` | exact | 230x144 | Game History | Hifz practice tile |
| `gameChess` | exact | 230x144 | Game History | Shatranj tile and history row |
| `gameLudo` | exact | 230x144 | Game History | Ludo tile and history row |
| `gameMemory` | exact | 230x144 | Game History | Names Memory tile |
| `gameArabicWords` | exact | 230x144 | Game History | Not shown yet (Arabic Words is licence-blocked) |
| `gameSeerahChallenge` | exact | 230x144 | Game History | Not shown yet (no Seerah game) |
| `gamePuzzlePath` | exact | 210x124 | All Games Collection | Not shown yet (no puzzle game) |
| `gameLogicTiles` | exact | 265x115 | All Games Collection | Not shown yet (no logic game) |
| `resultTrophy` | exact | 783x355 | Game Complete (trophy) | Top of every result (quiz and memory) |
| `cornerOrnament` | patched | 93x90 (transparent) | Astronomy Explorer (ornate panel) | Panel corners on details, setup, results, community |
| `goldDivider` | patched | 530x20 (transparent) | Qur’an Knowledge waiting room | Rule under the result and above the hub buttons |

## Patched slots: the clean file to export

These three look right but are not clean. Replace them with a clean export when you can.

| Slot | File name | Size to export | Transparent | What is wrong now, and what the file must be |
|---|---|---|---|---|
| `hubHeader` | `hubHeader.webp` | 1200 x 550 | no | The title, tagline, clock, battery, back and search buttons were painted out with an automatic fill. The sky behind the old title is a smooth dark smear, and the two round buttons leave a soft orange glow on the pillars. Export the arch, lanterns, flowers and skyline with no text, no status bar and no buttons. Leave the dark sky inside the arch empty; the app puts its own tagline there. |
| `cornerOrnament` | `cornerOrnament.png` | 256 x 256 | **yes** | Cut out of a dark panel by turning colour into transparency, so the lines are slightly rough and only look right on a dark panel. Export the top-left Islamic pattern corner alone, gold on transparent. The app mirrors it for the other three corners. |
| `goldDivider` | `goldDivider.png` | 1060 x 40 | **yes** | Same cut-out method. Export the thin gold rule with the small diamond in the middle, gold on transparent. |

## Fallback slots: drawn in code until a file exists

| Slot | File name | Size to export | Transparent | Why there is no crop, and what to export |
|---|---|---|---|---|
| `backdropFull` | `backdropFull.webp` | 1170 x 2532 | no | Every designed screen has its title, cards or buttons baked in, so no full-screen backdrop could be cut out. Export the lantern-and-arch backdrop with no UI: sunset skyline in the top 40 percent, fading to near-black navy so panels stay readable. Not placed on a screen yet; it will be used behind setup, waiting and result pages. |
| `bottomNavFrame` | `bottomNavFrame.png` | 1080 x 240 | **yes** | The gold nav pill exists in the designs only with icons and labels in it. Export the empty frame (gold outline, glow, the raised centre tab shape) with no icons or text. The shared bottom nav is outside the Games section, so this is not wired up. |
| `historyEmpty` | `historyEmpty.webp` | 600 x 400 | no | The designs show no empty Game History. Export a quiet lantern-and-closed-book scene, no text. Shown when no game has been played yet. |
| `settingsHeader` | `settingsHeader.webp` | 941 x 222 | no | There is no Games settings screen on main yet, so nothing uses it. When one is built it uses `skylineBand`; export this only if you want a different strip. |
| `seerahTimelineBoard` | `seerahTimelineBoard.webp` | 1080 x 1600 | no | Card-list background of Seerah Timeline. Text-free; no faces, no figures. Until it exists the screen draws a plain panel on the chosen card theme. |
| `prophetsOrderBoard` | `prophetsOrderBoard.webp` | 1080 x 1600 | no | Same, for Prophets in Order. No images of any prophet. |
| `wuduStepsBoard` | `wuduStepsBoard.webp` | 1080 x 1600 | no | Steps background of the Wudu screen. No people. |
| `salahStepsBoard` | `salahStepsBoard.webp` | 1080 x 1600 | no | Steps background of the Salah screen. No people. |
| `wordSearchGrid` | `wordSearchGrid.webp` | 1080 x 1080 | no | Grid background of Word Search, no letters. |
| `scrambleTile` | `scrambleTile.webp` | 1080 x 900 | no | Letter-tile background of Word Scramble, no letters. |
| `hajjMap` | `hajjMap.webp` | 1080 x 1400 | no | Schematic map for the hidden Hajj Map game (Makkah, Mina, Arafat, Muzdalifah, Jamarat; no photos). Not used until that game is unhidden. |

## Where the art is applied

| Screen | Art |
|---|---|
| Games hub (`/games`) | `hubHeader` arch, one `category*` picture per section, one `game*` picture per tile and Continue row, `goldDivider` above the buttons |
| Category lists | There is no separate category page on main; the hub's filter chips show the same sections with their `category*` picture |
| Game page (`/games/g/:id`) | `heroQuranKnowledge` (Qur’an Knowledge) or the game's own picture, `cornerOrnament` on each panel |
| Setup | `skylineBand` strip, `cornerOrnament` on each group |
| Results | `resultTrophy`, `goldDivider`, `cornerOrnament` on the played-together panel |
| History | `skylineBand` strip, `game*` picture on each row |
| Community stub | `skylineBand` strip, `cornerOrnament` |
| Games settings | No design; the screen is drawn in code on the shared theme |
| Learning games (Seerah Timeline, Prophets in Order, Wudu and Salah steps, Word Search, Word Scramble) | the board slots above, with a plain themed panel as fallback; Seerah Challenge, Hadith Knowledge and Arabic Words use their `game*` pictures |
| Chess and Ludo | Final art from `tool/process_game_art.py`; see the section below. Lineage, Ayah and Hijrah screens are not touched here. |

## Content notes for the owner

* `gameNames99` shows the gold Allah calligraphy medallion from his 99 Names tile. If he does not want the Name on a tappable game tile, swap that one slot.
* `gameStories` and `gameLineage` use his Prophets and Islamic History tiles; none shows a figure. `gameMemory` is his Islamic Memory card art, used for Names Memory.
* The designs also show star ratings, "Online" dots and points. None of that was brought in; the app's no-ratings, no-points rules still apply.

## Chess and Ludo art (final, 26 Oct 2026)

Nothing is awaited. All of it comes from the owner-approved files through `tool/process_game_art.py` (`docs/product/games_art_pipeline.md`).

| Item | Files | Status |
|---|---|---|
| Chess pieces (12) | `assets/games/chess/pieces/{w,b}{p,n,b,r,q,k}.webp`, 512 x 512 | final |
| Chess boards: Royal marble (default), Green marble, Blue marble, Grey, Classic wood | `assets/games/chess/boards/chess_board_<theme>.webp`, 1254 x 1254 | final |
| Highlight tiles | `chess_board_<theme>_highlight_{selected,legal_move,last_move}.png`, 256 x 256, for green, blue, classic and (selected, legal move) grey | final |
| Royal marble tiles | none: gold glow drawn in code | optional export |
| Grey last-move tile | none: the delivered one was opaque and fringed; a soft silver-gold tint is drawn in code | optional export (256 x 256, translucent) |
| Ludo board, pawns, dice 1 to 6, rolling die | `assets/games/ludo/` | final |

Optional only: higher-resolution re-exports (boards 2048 x 2048). Boards are shipped at 1254 px, enough for a phone at 3x.
