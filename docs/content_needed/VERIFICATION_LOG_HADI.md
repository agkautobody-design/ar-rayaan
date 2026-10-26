# Verification log: Hadi local knowledge

Rule: Hadi's new local answers are EXTRACTIVE. They quote entries that
already ship in the app. No new religious content was written or sourced in
this change, so nothing new needed external verification.

| Source pack | Path | Used for | Checks |
| --- | --- | --- | --- |
| Huda guides (51) | assets/guides/guides.json | steps quoted verbatim with the guide's own `sources` and `madhhabNote` | checksum-gated pack, unchanged |
| Q&A bank (12) | assets/qa/qa_bank.json | answer quoted verbatim with its `s` source | checksum-gated, unchanged |
| Story packs | assets/stories/{prophets,companions,women,seerah,ghayb,signs,tales,dailyduas,newmuslim,modernhadith}.json | first chapter, cut at a sentence end (never rewritten), first three sources | an "unchecked" label is shown as "Unverified" before the text; reflections are labelled as reflections |

Left out on purpose: khutbahs (sermons), the Qur'an text and translation
(already used for printed passages, not as answers), Nawawi 40 (no per-hadith
titles to match on), the 99 Names game.

Test `test/hadi_local_knowledge_test.dart` checks that guide steps appear
verbatim in composed answers and that an unverified story says so first.

Topics that could not be answered from these packs are in
`docs/content_needed/hadi_gaps.md`.
