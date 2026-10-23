# Dua transliteration: content needed

Status (round 4): PARTLY DONE. The owner approved adding transliteration where it can be verified. 30 of 42 duas, 29 of 52 counted adhkar and 8 of 14 Du'a School lessons now have a `tl` line with its source (`tlSource`) shown in the app; the Daily Duas reader and the Du'a School now display it. Items without a verified source were left out and are listed in `VERIFICATION_LOG_NAMES_DUAS.md`; the tables below stay as the list of what exists. The elided Arabic of dua-istikhlas, dua-istikhara-full, dua-witr-qunut, dua-sleep and dua-sleep2 is now complete.

First-time users who cannot read Arabic (p05, q07) asked for a Latin-letter line under each dua so they can say it. The app's dua data has Arabic and an English meaning only. There is no transliteration field anywhere in the dua data, so the app shows none, and none has been written by the developer (religious-content rule).

## What is needed

- One transliteration line per Arabic text below, in an established standard scheme, approved by the owner or a scholar, with the source it was taken from.
- Delivered as a JSON field (`tl`) next to `arabic`, per dua and per dhikr. The counted sets on Dhikr & Du'a (section 2) already show a `tl` field when it exists. The Daily Duas reader (section 1) and the Du'a School (section 3) do not read it yet: that small change is made when the content arrives.
- The Qur'an reader already has an approved transliteration for Al-Fatihah, Ayat al-Kursi (2:255), Surah 103 and Surahs 105-114 (`assets/quran/transliteration.json`). Duas that are exactly one of those passages could reuse it once the owner confirms the mapping.

## 1. Daily Duas pack (`assets/stories/dailyduas.json`): 42 duas, none has transliteration

| id | title |
|---|---|
| dua-waking | On Waking |
| dua-sleep | Before Sleep (1) — Ayat al-Kursi |
| dua-sleep2 | Before Sleep (2) — The Three Quls |
| dua-home-in | Entering the Home |
| dua-eat-before | Before Eating |
| dua-eat-after | After Eating |
| dua-travel | The Journey |
| dua-anxiety | The Heart's Unrest |
| dua-distress | The Dua of Distress |
| dua-debt | The Debtor's Dua |
| dua-illness | For the Sick |
| dua-loss | When Struck by Loss |
| dua-istikhara | Istikhara's Heart |
| dua-parents | For Parents |
| dua-children | For the Children |
| dua-fasting | Breaking the Fast |
| dua-rain | When It Rains |
| dua-mosque | Entering the Mosque |
| dua-after-salah | After the Prayer |
| dua-istikhlas | Sayyid al-Istighfar — the Master of Seeking Forgiveness |
| dua-rabbana-atina | The Sum of all Duas |
| dua-exit-home | Leaving for Work or Study |
| dua-enter-mosque2 | Entering the Mosque (full form) |
| dua-rain2 | Asking for Rain |
| dua-debt2 | For Relief of Debt |
| dua-rizq | Asking Provision |
| dua-family2 | For the Whole Household |
| dua-hawqala | The Hawqala — the Treasure of Paradise |
| dua-seeing-afflicted | Seeing Someone Afflicted |
| dua-forgiveness-night | The Night Prayer's Door |
| dua-istikhara-full | Istikhara — Asking Allah to Choose |
| dua-suhoor | At Suhoor — the Fast Begins |
| dua-iftar-full | Breaking the Fast — Complete |
| dua-travel-full | The Full Journey Dua |
| dua-sajdah | Inside the Prostration |
| dua-between-sajdah | Between the Two Prostrations |
| dua-witr-qunut | The Witr Qunut |
| dua-visit-sick | Visiting the Sick |
| dua-morning-master | The Morning Shield (Complete) |
| dua-evening-shield | The Evening Shield |
| dua-children-shield | Over Your Children |
| dua-takbir-days | The Ten Days' Takbir |

## 2. Hisn al-Muslim counted sets (`assets/adhkar/adhkar.json`): none has transliteration

- Morning Adhkar (`morning`): 23 items, numbered 1 to 24
- Evening Adhkar (`evening`): 21 items, numbered 1 to 24
- After Prayer (`after-prayer`): 8 items, numbered 1 to 8

## 3. Du'a School lessons (`lib/features/academy/presentation/dua_school_screen.dart`): 14 lessons, none has transliteration

- Ayat al-Kursi — after Fajr, protection
- Sayyid al-Istighfar — the master of seeking forgiveness
- Before sleeping
- Before eating
- The Three Quls — the evening shield
- Leaving the home — the morning departure
- After eating — the thanked meal
- Entering the home — the threshold greeting
- Entering the mosque — asking the doors of mercy
- After the prayer — the closing words
- Boarding any transport — the borrowed ride
- In distress — the dua of the afflicted
- Hasbunallahu wa ni'mal wakil — the sufficiency clause
- The master of forgiveness — morning anchor

