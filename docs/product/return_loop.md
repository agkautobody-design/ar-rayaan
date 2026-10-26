# Return loop: "days returned" and quiet completion moments

Status: built, owner-approved (Oct 2026). Both parts are small and can be
switched off in code. Streaks and sharing (below, "Streaks and sharing") were
added on top, also owner-approved.

## The decision

The app used to say "no streaks, no totals" (habits_providers.dart,
prayer_log.dart). The owner has narrowly approved two things:

1. An optional, gentle "days returned" count.
2. A quiet card at three natural finishing moments.

Everything else about the old rule still stands: no points, no confetti, no
leaderboard, no push nag, no loss or guilt message. (The old "no share
button" rule was lifted by the owner: see "Streaks and sharing".)

## 1. Days returned (opt in)

- Settings, "COMING BACK", switch "Show days I came back". OFF by default.
- Counts only Qur'an reading (tapping an ayah, or reaching the end of a
  surah), adhkar (a tap on a counter) and lessons (finishing one). The enum
  `ReturnAct` has exactly those three values: a prayer or any other
  obligation cannot be recorded, by construction.
- One grace day per calendar week (Monday to Sunday) is built in: one missed
  day does not end the run. Two missed days in a row, or a second missed day
  in the same week, quietly start a fresh run. Nothing is said about it.
- Wording is positive only: "You came back N days." Shown from 2 days, in
  Settings under the switch and on the completion card. Never when it is 0
  or 1.
- Local only: SharedPreferences keys `ar.return.enabled` and
  `ar.return.days` (dates only, last 400 days). Not synced, not sent anywhere.
- Switching it off deletes the stored days (silent reset).
- Code: `lib/features/habits/application/return_loop.dart`, beside
  habits_providers.dart. Maths is the pure `ReturnLoop.daysReturned`.

## 2. Quiet completion card

- Shown after: finishing an adhkar set, a surah read to its end (the end of
  the surah stays on screen for 4 seconds), and the first lesson (a line
  added to the existing lesson-complete sheet).
- Text: "Done. May it be accepted." Plain words, not a ruling, no du'a text.
  No du'a is shown; any du'a would have to come from the adhkar data with its
  source, and none is used here.
- Once per set or surah per day; the first lesson once ever. Not tied to the
  switch above (the count line appears on it only when opted in).
- Respects Elder Mode (larger text, 64dp button), large text (scrolls, no
  fixed heights) and RTL (directional padding, centred text).
- Code: `lib/features/habits/presentation/quiet_done.dart`.

## How to turn it off in code

- Whole return loop (count and Settings switch): in `return_loop.dart` set
  `const bool kReturnLoopEnabled = false;`. The switch disappears, nothing is
  recorded, no count shows.
- Quiet cards: in `quiet_done.dart` set `const bool kQuietDoneEnabled = false;`.

## Owner notes

- Changing the card wording: edit `kQuietDoneText` (test
  test/return_loop_test.dart pins it, update both).
- A user who wants to stop the count does it in Settings; nothing else needs
  clearing.
- Not built, on purpose: reminders, history view, goals, badges.

## Streaks and sharing (owner-approved, Oct 2026)

Streaks (screen `/streaks`, card on Home, code in `lib/features/streaks/`):

- One switch, the same as before ("Keep my streaks" in Settings and on the
  Streaks screen). OFF by default; Home shows a quiet invitation with "Turn on"
  and "Not now". To default it ON, change the `?? false` in
  `ReturnLoopEnabledController.build`.
- Four streaks: Qur'an reading, dhikr and tasbeeh (adhkar taps and tasbeeh
  taps), prayers logged, and days returned (any of Qur'an, dhikr, lessons).
- Qur'an, dhikr and lessons are stored in `ar.streaks.days` (dates only,
  last 400 days, this device only). Prayers are NOT stored again: the streak
  is read from the prayer log the person already keeps. A day counts when at
  least one prayer is marked prayed (on time or late). A day with only
  "excused" marks is skipped: it never counts against anyone and never uses
  the grace day.
- Same grace rule as above (one forgiven day per Monday to Sunday week); the
  maths is `StreakMath.run` (pure; a test checks it agrees with
  `ReturnLoop.daysReturned` when nothing is excused).
- The Streaks screen has a month calendar (done = filled, grace day = ring,
  excused = dash), and the month's count. No "lost" or "broken" wording
  anywhere (a test scans the sources).
- Switching off erases the stored days. The prayer log is left alone.
- `ReturnAct` still has no prayer value; the prayers streak is read-only.

Sharing (`lib/features/share/`):

- Every share goes through a preview sheet (`showSharePreview`) that shows
  the exact text. Nothing is posted automatically. Where the browser has the
  Web Share API the button says Share; elsewhere it says "Copy to share" and
  copies with a "Copied" message.
- Entry points: an ayah (its actions sheet; Arabic, translation, reference and
  the Tanzil / Saheeh International credit), a dhikr or dua (only ones that
  carry their source), a story chapter and a hadith (existing share buttons now
  preview first), a milestone ("I completed ..." on the completion card after
  an adhkar set or a surah, and on the lesson-complete sheet), a "came back N
  days" line for Qur'an, dhikr or days returned, and an invitation to
  https://ar-rayaan.onrender.com (Verse Cards screen).
- Prayer streaks are never offered for sharing. Notes, the prayer log and
  reading history are never part of any shared text.
- Text only. An image card needs a canvas-to-file share path that is not in
  the app yet (no new dependencies); not built.
