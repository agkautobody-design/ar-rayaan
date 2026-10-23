# Verification log: Arabic for the 99 Names, transliteration for duas and adhkar

Round 4 (branch `feat/r4-content-names-duas`). Rule followed: no Arabic or transliteration was written from memory. Each string below was fetched from a named page, compared with the app's existing text by a letter-for-letter check (vowel marks, tatweel, bracketed notes and hamza/alef forms ignored), and left out when the sources disagreed or the check failed. Pages were read through a page-fetch tool that summarises, so long passages were read in short segments.

## 1. The 99 Names of Allah: Arabic (`assets/games/names99.json`, key `arabic`)

Sources (six lists, four of them fully vowelled: 1, 2, 4, 5; lists 3 and 6 give consonants only; plus the Qur'an text):

1. Wikipedia, Names of God in Islam: https://en.wikipedia.org/wiki/Names_of_God_in_Islam
2. 99namesofallah.name: https://99namesofallah.name/
3. WikiIslam, 99 Names of Allah: https://wikiislam.net/wiki/99_Names_of_Allah
4. Islamic Relief Canada: https://old.islamicreliefcanada.org/?p=36617
5. Edarabia: https://www.edarabia.com/99-names-allah-english-arabic-meaning-definition/
6. Sunni Online: https://sunnionline.us/english/2010/04/24/227/amp/
7. Qur'an text for the Names that are ayat words (for example 59:23): https://api.quran.com/api/v4/verses/by_key/59:23?fields=text_uthmani, and the app's own Tanzil data
8. The hadith of the Names, Jami at-Tirmidhi 3507: https://sunnah.com/tirmidhi:3507 (the list of Names differs by narration; the app's own order and numbering of `names99.json` was kept, only `arabic` was added)

Method: the consonants of each Name were compared across the lists, the vowelled form was taken from the vowelled lists where they agree, and Names that occur in the Qur'an were checked against the Tanzil text. The row order and the app's transliteration and meaning were not changed.

Disagreements and how they were settled:
- Name 3: the WikiIslam list was the outlier on the consonants; the other lists agree, so their reading was used.
- Names 80, 88 and 91: one list had a vowel-mark typo each; the vowelling shared by the other lists was used.
- Name 89: the lists print a pausal form; it is kept as the lists print it.
- Allah, ar-Rahman and ar-Rahim carry the standard Qur'anic spelling with the dagger alif.

Result: 99 of 99 rows now have `arabic`, 99 distinct, Arabic characters only (test: `W1.5` in `test/audit/data_audit_test.dart` and `test/names_duas_arabic_test.dart`). Left out: none.

## 2. Transliteration

Scheme and source. The Latin line for each dua and dhikr was taken from the transliteration printed with the same dua on sunnah.com's Hisn al-Muslim (https://sunnah.com/hisn:N, N shown beside each item). For Qur'anic passages the transliteration already approved in this app (`assets/quran/transliteration.json`, Tanzil text) was used instead. A transliteration was attached only when the app's Arabic equals that source's Arabic letter for letter (or is exactly a stated run of its lines). The source of each line is stored beside it in the JSON field `tlSource` and shown under the line in the app.

Two edits made to the source transliteration, both visible in `tlSource` or here:
- Any Hisn line that printed "hātha" (Hisn 77) is written "hādha", as the same entry spells it elsewhere.
- Hisn 122 in the Du'a School: one apostrophe typed for the letter ayn in "'Aẓīm" is written as ayn, matching the other lines.
- Hisn 79 (Sayyid al-Istighfar): "laka" is added before "bidhanbī" to match the Arabic of Sahih al-Bukhari 6306 (see 3).

### 2a. Adhkar (`assets/adhkar/adhkar.json`), 29 of 52 items
Attached (set number, source Hisn page / Qur'an): morning 2: Qur’an transliteration already approved in this app; morning 3: Hisn al-Muslim 77; morning 4: Hisn al-Muslim 78; morning 5: Hisn al-Muslim 79; morning 6: Hisn al-Muslim 80; morning 7: Hisn al-Muslim 81; morning 9: Hisn al-Muslim 83; morning 10: Hisn al-Muslim 84; morning 11: Hisn al-Muslim 85; morning 12: Hisn al-Muslim 86; morning 17: Hisn al-Muslim 91; morning 19: Hisn al-Muslim 92; morning 20: Hisn al-Muslim 94; morning 21: Hisn al-Muslim 73; morning 22: Hisn al-Muslim 96; morning 24: Hisn al-Muslim 98; evening 2: Qur’an transliteration already approved in this app; evening 5: Hisn al-Muslim 79; evening 9: Hisn al-Muslim 83; evening 10: Hisn al-Muslim 84; evening 11: Hisn al-Muslim 85; evening 12: Hisn al-Muslim 86; evening 17: Hisn al-Muslim 91; evening 22: Hisn al-Muslim 96; evening 23: Hisn al-Muslim 97; evening 24: Hisn al-Muslim 98; after-prayer 1: Hisn al-Muslim 66; after-prayer 2: Hisn al-Muslim 67; after-prayer 3: Hisn al-Muslim 68.

Left out (23): morning 1, morning 8, morning 13, morning 14, morning 15, morning 16, morning 18, evening 1, evening 3, evening 4, evening 6, evening 7, evening 8, evening 13, evening 14, evening 15, evening 16, evening 18, after-prayer 4, after-prayer 5, after-prayer 6, after-prayer 7, after-prayer 8.
Reasons: the app's Arabic differs from the source (extra instruction text such as "after every prayer", an added word, or a longer or shorter version); the source transliteration is garbled; or no matching Hisn entry was found.

### 2b. Daily Duas (`assets/stories/dailyduas.json`), 30 of 42 duas
Attached: dua-waking: Hisn al-Muslim 1; dua-sleep: Qur’an transliteration already approved in this app; dua-sleep2: Qur’an transliteration already approved in this app; dua-travel: Hisn al-Muslim 207; dua-anxiety: Hisn al-Muslim 121; dua-distress: Hisn al-Muslim 122; dua-debt: Hisn al-Muslim 136; dua-loss: Hisn al-Muslim 154; dua-istikhara: Hisn al-Muslim 74; dua-fasting: Hisn al-Muslim 176; dua-rain: Hisn al-Muslim 172; dua-mosque: Hisn al-Muslim 20; dua-after-salah: Hisn al-Muslim 66; dua-istikhlas: Hisn al-Muslim 79; dua-rabbana-atina: Hisn al-Muslim 235; dua-exit-home: Hisn al-Muslim 16; dua-enter-mosque2: Hisn al-Muslim 20; dua-rain2: Hisn al-Muslim 170; dua-debt2: Hisn al-Muslim 136; dua-hawqala: Hisn al-Muslim 260; dua-seeing-afflicted: Hisn al-Muslim 194; dua-istikhara-full: Hisn al-Muslim 74; dua-iftar-full: Hisn al-Muslim 176; dua-travel-full: Hisn al-Muslim 207; dua-sajdah: Hisn al-Muslim 41; dua-between-sajdah: Hisn al-Muslim 48; dua-visit-sick: Hisn al-Muslim 147; dua-morning-master: Hisn al-Muslim 97; dua-evening-shield: Hisn al-Muslim 105; dua-children-shield: Hisn al-Muslim 146.

Left out (12): dua-home-in, dua-eat-before, dua-eat-after, dua-illness, dua-parents, dua-children, dua-rizq, dua-family2, dua-forgiveness-night, dua-suhoor, dua-witr-qunut, dua-takbir-days.
Reasons: not found in Hisn al-Muslim with matching Arabic; transliteration in the source had typos (witr qunut, Hisn 116, also carries a bracketed optional phrase); or the Arabic itself could not be checked (dua-rizq).

### 2c. Du'a School (`lib/features/academy/presentation/dua_school_screen.dart`)
Attached to 8 of 14 lessons: Sayyid al-Istighfar (both lessons, Hisn 79 lines 1-2), Three Quls (first ayah of each, Qur'an 112:1, 113:1, 114:1), Leaving the home (Hisn 16), Entering the mosque (Hisn 20 line 6), After the prayer (Hisn 66), Boarding transport (Hisn 207 lines 2-3), In distress (Hisn 122 lines 1-4).
Left out: Ayat al-Kursi lesson (excerpt, the approved line is for the whole ayah), Before sleeping, Before eating, After eating, Entering the home, Hasbunallahu wa ni'mal wakil (part of an ayah).

## 3. Dua entries that showed their Arabic only in part ("...")
Each now carries the full Arabic and no longer matches `arabicIsElided`.
- dua-istikhara-full (Istikhara): Sahih al-Bukhari 1166, https://sunnah.com/bukhari:1166 (vowelled text read in segments), cross-checked letter for letter with Hisn 74. Bukhari 7390 (https://sunnah.com/bukhari:7390) was also read. The earlier cited number Bukhari 6382 did not load, and Bukhari 1162 is a different hadith, so neither is relied on. The short form dua-istikhara no longer repeats the elided text (`dua` set to null) and gets its transliteration from Hisn 74 lines 7-14.
- dua-istikhlas (Sayyid al-Istighfar): Hisn 79 (https://sunnah.com/hisn:79) with Sahih al-Bukhari 6306 (https://sunnah.com/bukhari:6306); the Arabic with "wa abu'u laka bidhanbi" was confirmed on https://islamtics.com/sayyidul-istighfar-dua/ and https://ihadis.com/en/blogs/dua-dhikr/sayyidul-istighfar-dua.
- dua-witr-qunut: Hisn 116 (https://sunnah.com/hisn:116), cross-read with https://sunnah.com/nasai:1745 and https://sunnah.com/abudawud:1425. The optional bracketed phrase "wa la ya'izzu man 'adayt" is not in the app's text and was not added. Hisn 116 prints "innahu la yadhillu" without the conjunction; that reading is followed. No transliteration attached (the Hisn line has typos).
- dua-sleep (Ayat al-Kursi) and dua-sleep2 (the three Quls): the Arabic was filled in from the app's own Tanzil data (`assets/quran/quran.json`, 2:255 and 112 to 114), and a test asserts equality with that data. Transliteration from the approved Qur'an file.

## 4. Not done / needs owner or scholar content
- Every item listed as left out in 2a to 2c.
- dua-rizq: the Arabic itself was not found in a source; not changed, no transliteration.
- A scholar read-through of the Latin spelling scheme: Hisn al-Muslim uses one scheme (ʿ shown as a backtick), the Qur'an file another (aa/oo/ee). The two are shown as is; unifying them is a style decision for the owner.
