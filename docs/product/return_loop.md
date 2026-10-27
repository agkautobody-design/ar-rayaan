# Return loop: My log (private totals) and quiet completion moments

Status: built. Owner ruling on streaks, RESOLVED (Oct 2026), in his words:

> not streaks but users can track, the app can track it for them, congratulate new users or people lacking, but no shaming for not being every day user or someone that doesn't log it in.

This replaces the earlier "streaks and days returned" design (a run of
consecutive days with one grace day a week). That design is gone from the code.

## Rules that stand

- NO STREAKS, on any act (worship or study): no consecutive-day counts, no
  reset-to-zero or loss mechanics, no "don't break the chain" framing, no
  streak badge or share card.
- Tracking is private and on-device. Counts are plain totals for a period
  (this week, this month, all time). They never reset because a day was
  missed, and the screen never shows a run length.
- Encouragement, never shame. Banned everywhere: "you missed", "you failed",
  "you broke", red or negative styling for gaps, loss counters, comparing to
  others, leaderboards on worship, push notifications that scold. A gap is
  neutral empty space.
- Copy for religious acts does not imply points or reward-for-worship. No
  points, coins, ads or ratings on religious acts (standing rule).

## My log

- Screen `/my-log` (Menu, Settings "Open my log", Home card). Code in
  `lib/features/tracking/`.
- Tracks: Everything, Qur'an reading, Dhikr and tasbeeh, Prayers, Fasting,
  Lessons. For each: This week (Monday to today), This month, All time, the
  last day logged, and a month calendar of the days logged (filled = logged,
  empty = nothing, no other state).
- Sources: Qur'an, dhikr/tasbeeh and lesson days are recorded by the switch
  ("Keep a private log", Settings under "Coming back", OFF by default) into
  `ar.tracking.days` (dates only, about ten years, this device only). Prayers
  are read from the prayer log (`ar.prayer.log.v1`; "prayed" and "late" count,
  "not prayed" and "excused" add nothing and are not shown). Fasting is read
  from the fasting log. Lessons also include the Academy activity days
  (finishing a lesson or answering a review, which is how Hifz revision in the
  Review Queue is logged).
- Prayers show a count of prayers ("You have prayed 12 times this week"); the
  other tracks count days.
- `ReturnAct` has no prayer value: a prayer cannot be recorded by the switch.
- Switching off erases the days the switch saved. Prayer and fasting logs stay.
- Days saved by the earlier release under `ar.streaks.days` are read once and
  moved to `ar.tracking.days`, so nobody loses what they logged.

## Encouragement (`lib/features/tracking/domain/encouragement.dart`)

- Nothing logged: "Nothing is logged yet. Start whenever you like, there is no
  rush."
- First log: "Your first one is logged. Welcome, and thank you for being here."
- First week of use: "Your first week with the log. Glad you are here."
- Back after a gap of 7 days or more: "Welcome back, glad you're here."
- No log for 3 days or more (and not new): an optional "A small step today?"
  with "Not now". It is dismissible and stays away for the rest of that day.
  It is shown inside the app only; there is no push notification for it.
- Nothing special to say: nothing is said.

## Journey ring

Progress ring on My Journey, from totals only (adhkar counted today 45,
surah opened 10, reflection 15, lesson 15, memorised ayat 15). No weight
depends on a run. An empty ring reads as "start whenever you like".

## Quiet completion card

- Shown after: finishing an adhkar set, a surah read to its end, and the first
  lesson. Text: "Done. May it be accepted." Plain words, not a ruling.
- When the person is new or has just come back, one warm line is added (the
  lines above). Never a count.
- Once per set or surah per day; the first lesson once ever.
- No Share button on the adhkar or Qur'an cards.

## Sharing

PENDING OWNER DECISION. Only study milestones are shared (a finished lesson or
course; a Hifz section if one is added). Worship acts, counts and gaps are
never offered for sharing. Every share still goes through the preview sheet.

## How to turn it off in code

- Whole log and its Settings switch: `kReturnLoopEnabled = false` in
  `lib/features/habits/application/return_loop.dart`.
- Quiet cards: `kQuietDoneEnabled = false` in `quiet_done.dart`.
- To default the log ON, change the `?? false` in
  `ReturnLoopEnabledController.build`.
