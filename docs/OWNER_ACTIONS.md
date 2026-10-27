# Ar-Rayaan: things only the owner can do (updated 22 Oct 2026)

Each item says why it matters, the exact steps, and how to confirm it worked.

## 1. Protect the `main` branch (10 minutes)
Why: right now anyone with write access, or a bot, can push straight to `main`, and `main` deploys to the live site.
1. GitHub → agkautobody-design/ar-rayaan → Settings → Branches → Add branch protection rule.
2. Branch name pattern: `main`.
3. Tick: Require a pull request before merging; Require status checks to pass before merging, and add the checks `check` and `android-apk` (they appear after a PR has run); Do not allow force pushes; Do not allow deletions.
4. Save. Confirm: open any PR, the merge button waits for the checks.
Note: the Build & Deploy Web workflow force-replaces the `render` branch. Leave `render` unprotected.
Why this matters more than it looks: the app downloads updated stories, guides, games and so on straight from `main` (raw.githubusercontent.com) the moment they are pushed, before any test has run. The code now limits the damage (feature switches such as `system/module_registry.json` can no longer be changed remotely; a downloaded pack must keep the shape of the shipped one and match the manifest's SHA-256), but the TEXT of a pack is still whatever is on `main`. Branch protection is the control that puts a review and the tests between a change and every user. After protecting it: make the content bots open pull requests instead of pushing, and rotate the token or SSH key they use (the git log shows several bot identities that pushed to `main` directly).

## 2. Publish the Firestore rules (5 minutes). Majlis posting breaks live without this
Why: `firestore.rules` in the repo adds rate limits, reserved names, reports, and (since 22 Oct) locks down the online game rooms and bounds the Majlis reads. They are NOT deployed automatically (there is no `firebase.json`).
Order matters: let this change deploy to the live site FIRST (merge, wait for the green deploy), THEN publish the rules. The new rules need the new app: the old app writes game moves and Majlis queries in a way the new rules refuse.
1. Firebase console → your project → Firestore Database → Rules.
2. Replace the editor contents with the contents of `firestore.rules` from the repo (main branch). Click Publish.
3. Confirm: Rules tab shows today's publish time. The Majlis stays gated in the app until moderation exists, so no user-visible change is expected there.
What changed in the rules, so you know what to test:
- Online games (`game_rooms`), privacy update: a table now holds only anonymous sign-in ids (`host: {uid}`, `guest: {uid}`), never a display name; `expireAt` may be at most 12 hours ahead (the app uses 6); reads and writes are refused once `expireAt` has passed; either player can delete the table (the app deletes it on leave). The old app wrote names, so publish only after the new app is live.
- Online games (`game_rooms`): rooms can be read by code but not listed; the joiner can no longer rewrite moves, turn or result; a table is created with an exact set of fields; only one new numbered move per write; a finished or left table is closed.
- Majlis: threads and posts only under the `courtyard` room; reads must carry a limit (the app sends 50 threads / 200 posts); display names are limited to ASCII letters and digits, space, `. _ ' -`, and Arabic/Urdu letters (so a Cyrillic "а" or an accented letter can not slip past the reserved-name check), and digits that imitate letters ("h4di") are folded before the reserved-name check.
Quick test after publishing: open the live site on two devices, Games → Ludo → "Play a friend online", create a table on one, join with the code on the other, and play a few moves.
Not tested by CI: there is no Firestore emulator in the repo, so the rules were reviewed by reading and by static tests of the file (`test/firestore_rules_hardening_test.dart`), not executed. If you want them executed, say so and I will add the emulator suite.

## 2b. Turn on automatic deletion of old game tables (3 minutes)
Why: tables are never deleted by the app, so the `game_rooms` collection would only grow.
1. Firebase console → Firestore Database → "Time to live" (TTL) → Create policy.
2. Collection group: `game_rooms`. Timestamp field: `expireAt`. Create.
3. Confirm: the policy shows as Serving. Every table now carries `expireAt` (6 hours after creation; the rules cap it at 12). The in-app privacy text says tables are deleted when someone leaves and expire on their own, so this policy is what makes that sentence true for tables abandoned without leaving.

## 2c. Chess and Ludo art: done (26 Oct 2026)
The approved chess pieces, five marble and wood boards with their highlight tiles, and the Ludo board, pawns and dice are in the app (see `docs/product/games_art_pipeline.md`). Nothing is awaited. Optional: if you ever re-export at a higher resolution (boards 2048 x 2048, tiles 256 x 256), send the files; the grey board's "last move" tile (the delivered one was opaque) is drawn in code as a soft silver-gold tint, and Royal marble has no tiles, so it uses a gold glow. Check on a real phone: pieces centred on squares, pawn numbers readable on Ludo, the dice picture.

## 3. Request a Sunnah.com API key (10 minutes)
Why: web-page checks of hadith are rate-limited (HTTP 429). A key lets the checker verify reliably.
1. Open https://github.com/sunnah-com/api/issues/new?template=request-for-api-access.md and put your name in the title, as the template asks. Other questions: https://sunnah.com/contact.
2. When the key arrives, send it to Claude in chat. It goes into the checker only (never into the app or the repo; it will live as a GitHub Actions secret).

## 4. Name the reviewers (the biggest trust item)
Until a person is named, every page says "Not yet scholar-reviewed". That is the honest state. Needed:
- A named scholar for hadith, stories, prophets, rulings and the "Disputed in the sources" items. A woman scholar for the Women's school.
- A clinician for Sakina (safety plan, crisis wording).
- Native speakers for non-English crisis phrases.
What they review is listed in `docs/story_audit.md` (278 chapters) and the layers files under `assets/stories/layers/`. Open questions waiting for a scholar: which son was sacrificed; Ibrahim's heaven (Bukhari 349 vs 3207); the Musa/Khidr identity; the forbidden tree; whether Dhul-Kifl was a prophet; who Dhul-Qarnayn was; istiwa; how long the Fire lasts; the Mahdi and Isa's prayer leader; zihar; the ruling on neglecting prayer; the Abu Talib link to Ali.
When someone agrees to be named, tell Claude; the label changes only then.

## 5. Decide the English translation licence
Saheeh International is bundled with no permission statement in the repo. The Clear Quran is now the app's default English translation by design, but its text is not in the repo: supply the file and the publisher's written authorisation as described in docs/content_needed/CLEAR_QURAN_PACK.md and run one import command. Quran Foundation terms (updated 11 Oct 2026) forbid bundling their content. Options: (a) ask the rights holder for written permission, (b) switch the bundled English to Pickthall (1930, public domain) and fetch modern translations from the Quran Foundation API, (c) accept the risk. The code has a switch ready. Tell Claude which.

## 6. Legal review
A privacy lawyer should review the Terms, Privacy Policy and the children's section (`lib/features/legal/`, `lib/features/academy/domain/children_privacy.dart`). The contact address in both drafts is NOT set: the Terms and the Privacy Policy say "Contact address: not published yet" and the draft banner says a lawyer review and the address are pending. No real address exists anywhere in the repo, so none was invented. Decide the address (for example a mailbox on rhwktech.com), tell Claude, and it replaces `kLegalContactPending` in `lib/features/legal/presentation/legal_screens.dart` and the banner wording. Do this before any store release; stores require a reachable privacy contact. Incorporating RHW Technologies before store launch is recommended (store accounts show your legal name).

## 7. Pick a licensed source for Quranic word meanings
The 300-word deck is hidden because no licence-checked source of meanings and roots is in place. The sources found carry GPL or unstated data terms. Pick one you are allowed to use; Claude wires it in.

## 8. Test on real devices (nothing native has been run on a phone yet)
Android and iPhone: adhan with the app closed and after a reboot; Android 12+ "Alarms and reminders" prompt and its fallback; Android 13+ notification permission; iOS permission and the 64-notification limit; compass calibration and declination; the Android debug APK from the PR Check artifact `ar-rayaan-debug-apk`.

## 9. Run the audio CORS test
The sandbox cannot reach the audio hosts. Run the DevTools snippet and curl commands in `docs/audio_cors.md` from a normal browser on https://ar-rayaan.onrender.com and send Claude the output.

## 10. One decision
Sakina's line "the founder who has stood where you are" was removed (it claimed a personal history). Keep it removed or restore it?

## 11. Turn on Firebase App Check (needs your reCAPTCHA key; about 20 minutes)
Why: the Firebase web key is public by design, and anonymous sign-in is the only gate on Majlis, game rooms and Hadi reports. A script can create unlimited anonymous accounts and flood them. App Check makes Firebase accept requests only from the real app.
This could not be done in code alone: it needs a key only you can create, a new dependency (`firebase_app_check`, which also changes `pubspec.lock`), and a switch in the console. Steps:
1. Google Cloud console → reCAPTCHA Enterprise (or reCAPTCHA v3 in the Firebase App Check page) → create a site key for ar-rayaan.onrender.com.
2. Firebase console → App Check → register the web app with that key. Do NOT enforce yet.
3. Send the site key to Claude (it is public, not a secret). Claude adds `firebase_app_check`, activates it at startup, and opens a pull request.
4. After that is live and the App Check metrics show verified requests, return to App Check and turn on Enforce for Cloud Firestore and Authentication.
Also worth doing at the same time: Firebase console → Authentication → Settings → authorized domains (only your site), and Google Cloud console → Credentials → restrict the browser key to your site's referrers.

## 12. Delete a user's data on the server (needs the Firebase console; 10 minutes)
Why: Firestore does not delete sub-collections when a document is deleted. The app now deletes everything it knows it wrote (the account, each child's exams, lessons and mastery) when someone deletes their account, but the app cannot list sub-collections, so anything a future version adds could be missed. The Majlis forbids deleting posts, so a person's posts and display name stay after they delete their account (the Delete Account screen says so).
1. Firebase console → Extensions → install "Delete User Data" (firebase/delete-user-data).
2. Paths: `users/{UID}`, `families/{UID}` (recursive delete: on).
3. Confirm by deleting a test account and checking Firestore.
Decision for you: do you want people to be able to delete their own Majlis posts? That needs a rule change and a Delete button; it is a prerequisite the Majlis gate text already names.

## 13. Give Claude a YouTube API key so the catalogue can play in the app (10 minutes)
Why: the 202 catalogue tracks only have YouTube search links. The in-app player needs real video IDs, and a wrong ID plays the wrong video. A tool proposes IDs with the channel name; you or Claude check each is the artist's official channel before it is approved.
1. Google Cloud console → create a project → APIs & Services → enable "YouTube Data API v3".
2. Credentials → Create credentials → API key → restrict it to "YouTube Data API v3" only.
3. GitHub → the ar-rayaan repository → Settings → Secrets and variables → Actions → New repository secret named `YOUTUBE_API_KEY`.
4. Tell Claude. Each run searches about 80 tracks (the free daily quota is 10,000 units, 100 per search), so the whole catalogue takes three runs on three days. Proposals land on the branch `data/player-source-candidates`; nothing reaches the app until an ID is approved into `assets/academy/player_sources.json`.

## 14. Limits on "add to my YouTube / Spotify playlist" and "identify a song" (information, no action yet)
- Spotify: apps in development mode serve 5 allow-listed users; lifting that needs a registered business with about 250,000 monthly users. So Ar-Rayaan opens the track in Spotify, where the person taps +. It cannot write to a Spotify playlist for them.
- YouTube: writing to a person's playlist is possible with Google sign-in, but each add costs 50 quota units (about 200 adds a day on the default quota) and needs Google's app verification. Not built.
- Shazam (ShazamKit): Android and iOS only, no web. It needs an Apple Developer account ($99 a year) and an Apple token that must be renewed at least every three months. Not built. An Android-only version is possible later if you want it.

## 15. Have the new Arabic, Bangla and Urdu labels checked by native speakers
Why: the first-run language chooser now translates the tab names, Home titles and the first questions. Every word is a machine-style draft. The list and instructions are in `docs/content_needed/translation_review.md`. Send it to one native speaker per language and pass back the corrections. Until then the Language screen says they are first drafts.

## 16. Make the daily content job run the content check before it commits (5 minutes, in the job's own settings)
Why: the daily story job has twice pushed a broken entry straight to `main` (`mh-community-27` on 23 Oct: object `sources`, no audit row, a duplicate story; `mh-gratitude-28` on 27 Oct: the same faults). The job is not defined in this repository (there is no scheduled workflow here; its commits are authored by `agent <agent@example.com>`), so the repo cannot change what it does. The repo now (a) fails every pull request and every push to `main` that carries a broken story, with the entry named, and (b) holds the checker the job must call.
Where it must go: in whatever runs the daily job (its prompt, script or scheduler), add this as a required step after it edits `assets/stories/modernhadith.json` and BEFORE `git commit`:
```
python3 tool/check_daily_content.py
```
If it exits non-zero (it prints the story id and the reason), the job must drop the new entry (`git checkout -- assets/stories assets/content_version.json`) and stop; it must not edit the checker or the audit file to make it pass. Better still, make the job open a pull request instead of pushing (item 1), so the PR check runs the same gate.
Confirm: the next daily run either adds a story that passes the check, or adds nothing.

## 17. Parent PIN and child mode: what to know, and what you must decide
What changed: the parent check is now a 4 to 6 digit PIN, chosen by the first grown-up who reaches a gate on a device (salted hash, kept on the device only; five wrong tries lock it for five minutes; it stays open for two minutes). A parent can turn on child mode (from Kids Corner or the Family Wing): the app then shows only Kids Corner, the Arabic letters and the stories school, until the PIN is entered.
Caveats to accept or change: (a) a child who reaches a gate before any parent has set a PIN can set one; so set the PIN first on a shared device. (b) Clearing the browser's site data removes the PIN (there is no recovery by e-mail, because nothing about children leaves the device). (c) The Games door is left out of child mode because the game data is owned elsewhere and has not been reviewed for children. (d) The privacy text still needs a lawyer's review for COPPA/PIPEDA wording.

## 18. Contact address (still open)
The Terms and Privacy screens say the contact address is "not published yet". Give Claude one real address (or a form link) to put there; none was invented.

## 19. Left as it was, by decision or ownership
Streaks on worship: RESOLVED (Oct 2026), see section 20. The 30-day New Muslim content. Qur'an reader details (the "first time only" banner when the text is already saved, ayah numbers in button names, duplicate bookmark controls), Hadi's offline wording, the lesson result announcement and the Academy streak row label: those code areas belong to other work. Tab order out of step with the screen-reader tree is a Flutter web engine behaviour, not something the app can fix.

## 20. Streaks: RESOLVED (owner ruling, Oct 2026)
Owner's words: "not streaks but users can track, the app can track it for them, congratulate new users or people lacking, but no shaming for not being every day user or someone that doesn't log it in."
What was done: there are no streaks anywhere in the app, for worship or study. The old Streaks screen, the Home streaks card, the "days returned" run, the grace day, the "came back N days" share line and the Sakina "Day N" line are gone. In their place: My log (Menu, Settings, Home card), a private on-device log with plain totals (this week, this month, all time), the last day logged, and a calendar of the days logged; "you have prayed X times this week". Counts never reset because a day was empty; an empty day is neutral empty space. New people are congratulated (first log, first week), people who come back after a week or more are welcomed ("Welcome back, glad you're here"), and people logging rarely get a dismissible "A small step today?". No scolding, no loss counters, no push notifications, no points, no leaderboards. Details: docs/product/return_loop.md.
Still open for you: (a) sharing. You have not ruled on sharing of worship acts. Until you do, only study milestones can be shared (a finished lesson or course); sharing from adhkar and Qur'an reading was removed, and no counts or gaps are offered for sharing. (b) The private log is still opt-in (off until switched on), as before. Say if you want it on by default.
