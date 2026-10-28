# Fix pass C: accessibility, offline, kids/parent UI, navigation, languages

Nothing here was run on a device. CI (analyze, tests, web build) is the only check.

## Fixed
- Offline: network-first service worker (`web/ar_sw.js`) plus custom `flutter_bootstrap.js`; the app reopens offline once opened online. Honest wording in Settings, Downloads, Qur'an and Hadi help. "Try again" now re-fetches Qur'an text and transliteration, and retries on its own when the device comes back online. Offline banner is a live region in the semantics tree. Home Qur'an tile updates after the text is saved.
- Accessibility: Settings is a plain scroll view so Tab reaches every section; switch rows are one Tab stop; focus rings on 48 InkWells (Academy track chips, Path rows, Prayer Times buttons and others) and on elevated/filled buttons; Academy splash takes Enter/Space (and an early Enter); lesson checks (choose, arrange, match) move focus, announce results in live regions, and matched pairs are labelled in words; 30 dialogs and the main sheets are named; 60 text inputs are labelled.
- Child mode: Games (offline, no chat) and a short surah set (`kChildSurahs`) and duas open inside locked child mode. Stories school shows seven gentle stories with no adult theme text. Free-text Ask Hadi is hidden in child mode and on duas. Dua page: "WHAT IT MEANS" label, "Say it together" replaces the story question. Old "answer a question" wording replaced with PIN wording.
- Elder Mode gains Qibla, Learning and Games doors; "three doors" copy replaced in four languages.
- Wasia: Alif no longer asks about a letter before it; "three times" no longer repeats on every letter and step.
- Games result: encouraging line (also at 0).
- Sources: Aladhan row reworded; no "Founder-approved" in user text.
- Privacy: new "Google services at start-up" section (Firebase starts at launch when the build is connected).
- Journey: adhkar row says "all sets ... repetitions" (Home's tile counts the morning set only).
- Lesson to lesson uses replace, so Back no longer needs 8+ presses.
- Review register: four new items (child surahs, child stories, Firebase wording, Arabic/Bangla/Urdu elder line needing native-speaker review).

## Not fixed
- Privacy contact address: no published address exists in the repo and none was invented. Owner action (docs/OWNER_ACTIONS.md item 6).
- Back after Privacy Policy lands on Our Sources (browser-history behaviour; the safe fix is untestable without a device).
- Adult exam result saved without a Family Wing detour.
- Full Arabic/Urdu/Bangla UI coverage, RTL punctuation and "PM 6:15" order.
- Music ruling sources, Hifz planner done-ticks, reader "last read" keeping the ayah.
- Journey ring "15% each" wording.
- PIN session timeout cue and making child mode default-suggested after "Teaching my children".
- Six dialogs have no simple literal title and are unlabelled (downloads_screen, notes/tools_screens, ayah_actions_sheet, add_to_playlist_sheet, academy_family, shatranj_screen). v1 `lesson_player` checks did not get the focus/live-region treatment.
- Each new build clears the `ar-content-v1` cache once.
- The Qur'an reader in child mode was not audited for links out (other surahs redirect to Kids Corner).
