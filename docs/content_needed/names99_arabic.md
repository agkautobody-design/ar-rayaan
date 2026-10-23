# The 99 Names: Arabic script and pronunciation

Status (round 4): DONE for the Arabic script. All 99 rows in `assets/games/names99.json` now have `arabic`, verified against several lists; sources and the disagreements are in `VERIFICATION_LOG_NAMES_DUAS.md`. Still open: approval of the English meanings and optional audio. The text below is the original request.

Finding (round 3, r12): the 99 Names screen shows only the transliteration and a short English meaning. There is no Arabic script anywhere in the app's data for these names (`assets/games/names99.json` has `n`, `name`, `meaning`, `ref` only; a search of `assets/` and `lib/` found no Arabic for them).

Not written into the app, because the Arabic text of each Name and its pronunciation are religious content that needs an approved source.

What is needed from the owner:
- One agreed list of the 99 Names in Arabic (with full vowel marks), numbered to match `names99.json` (n = 1..99). Name the list used (for example the narration in Jami at-Tirmidhi 3507 and the scholar whose enumeration the app follows), because enumerations differ slightly between scholars.
- Approval of the English meaning on each row (the current rows are unchanged).
- Optional: audio of each Name from a reciter the owner approves.

Shape to add once approved: a new key `arabic` per row in `assets/games/names99.json`, then bump its entry in `assets/content_version.json` and run `python3 tool/gen_content_manifest.py`. The list view and the card already exist; show `arabic` above the transliteration when present.

Meanwhile (done in this change): the screen has an "All 99" list with number, transliteration, meaning and a labelled Qur'an reference, and a tap on any row opens that Name.
