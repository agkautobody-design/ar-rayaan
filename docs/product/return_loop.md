# Return loop: "days returned" and quiet completion moments

Status: built, owner-approved (Oct 2026). Both parts are small and can be
switched off in code.

## The decision

The app used to say "no streaks, no totals" (habits_providers.dart,
prayer_log.dart). The owner has narrowly approved two things:

1. An optional, gentle "days returned" count.
2. A quiet card at three natural finishing moments.

Everything else about the old rule still stands: no points, no confetti, no
share button, no leaderboard, no push nag, no loss or guilt message.

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
