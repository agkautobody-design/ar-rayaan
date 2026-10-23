# Needs owner/scholar content: how to pray tahajjud

> INTEGRATED (owner-approved, verified): the app now has the Huda guide `huda-tahajjud`, and Hadi links it. The numbers in the draft below were corrected where wrong (the "witr last" line is Bukhari 998, not 990). See VERIFICATION_LOG.md for every citation checked and everything dropped. Still not scholar-reviewed (OWNER_ACTIONS item 4).

Status: NOT in the app. Hadi says plainly, in the chat, that it has no verified tahajjud steps and points to the Witr and night guide (`huda-witr`) and Prayer Times. Nothing below may be shipped until a scholar has approved it and every reference has been checked against the collection.

## Why
Testers q07, q22, q23 asked "how do I pray tahajjud / how many rak'ahs". The Prayer Times Tahajjud card opens the Witr guide, which covers witr, not the steps of tahajjud.

## Proposed draft (for approval; wording is the owner's to change)
A short Huda guide, "Tahajjud — The Night Prayer", in the same shape as the other guides (steps, sources, madhhabNote):

1. What it is: prayer in the night after sleeping, the last third of the night being the best time. Sources to verify: Qur'an 17:79, 73:1-4, 32:16, 51:17-18; Sahih al-Bukhari 1145 and Sahih Muslim 758 (Allah descends in the last third of the night).
2. Number of rak'ahs: offered in pairs. The narrations about the Prophet's night prayer (for example Aisha's report, Sahih al-Bukhari 1147) and the schools' views on the count need a scholar to state. Do not state a fixed number without that.
3. Beginning with two short rak'ahs: a hadith reported in Sahih Muslim (about 767-768). Verify the number.
4. Ending with witr: "make the witr your last prayer at night" (Sahih al-Bukhari 990, already used in the Witr guide).
5. Virtue: the best prayer after the obligatory is the night prayer (Sahih Muslim 1163). Verify.

## Owner decisions needed
- Who reviews it (a named scholar, per the app's own review-status policy).
- Whether it is a new guide or a section of `huda-witr`.
- All hadith numbers above were written from memory of the collections and MUST be checked before use.

When approved: add the guide to `assets/guides/guides.json`, add `huda-tahajjud` to `kHadiGuideNames` in `hadi_controller.dart`, and change `HadiExplain.tahajjudReply` to link it.
