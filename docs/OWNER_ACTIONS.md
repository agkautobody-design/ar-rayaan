# Ar-Rayaan: things only the owner can do (checked 21 Oct 2026)

Each item says why it matters, the exact steps, and how to confirm it worked.

## 1. Protect the `main` branch (10 minutes)
Why: right now anyone with write access, or a bot, can push straight to `main`, and `main` deploys to the live site.
1. GitHub → agkautobody-design/ar-rayaan → Settings → Branches → Add branch protection rule.
2. Branch name pattern: `main`.
3. Tick: Require a pull request before merging; Require status checks to pass before merging, and add the checks `check` and `android-apk` (they appear after a PR has run); Do not allow force pushes; Do not allow deletions.
4. Save. Confirm: open any PR, the merge button waits for the checks.
Note: the Build & Deploy Web workflow force-replaces the `render` branch. Leave `render` unprotected.

## 2. Publish the Firestore rules (5 minutes). Majlis posting breaks live without this
Why: `firestore.rules` in the repo adds rate limits, reserved names and reports. They are NOT deployed automatically (there is no `firebase.json`).
1. Firebase console → your project → Firestore Database → Rules.
2. Replace the editor contents with the contents of `firestore.rules` from the repo (main branch). Click Publish.
3. Confirm: Rules tab shows today's publish time. The Majlis stays gated in the app until moderation exists, so no user-visible change is expected.

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
Saheeh International is bundled with no permission statement in the repo. Clear Quran is applied for but not granted (do not add it). Quran Foundation terms (updated 11 Oct 2026) forbid bundling their content. Options: (a) ask the rights holder for written permission, (b) switch the bundled English to Pickthall (1930, public domain) and fetch modern translations from the Quran Foundation API, (c) accept the risk. The code has a switch ready. Tell Claude which.

## 6. Legal review
A privacy lawyer should review the Terms, Privacy Policy and the children's section (`lib/features/legal/`, `lib/features/academy/domain/children_privacy.dart`). The contact address in both drafts is a placeholder: add a real one. Incorporating RHW Technologies before store launch is recommended (store accounts show your legal name).

## 7. Pick a licensed source for Quranic word meanings
The 300-word deck is hidden because no licence-checked source of meanings and roots is in place. The sources found carry GPL or unstated data terms. Pick one you are allowed to use; Claude wires it in.

## 8. Test on real devices (nothing native has been run on a phone yet)
Android and iPhone: adhan with the app closed and after a reboot; Android 12+ "Alarms and reminders" prompt and its fallback; Android 13+ notification permission; iOS permission and the 64-notification limit; compass calibration and declination; the Android debug APK from the PR Check artifact `ar-rayaan-debug-apk`.

## 9. Run the audio CORS test
The sandbox cannot reach the audio hosts. Run the DevTools snippet and curl commands in `docs/audio_cors.md` from a normal browser on https://ar-rayaan.onrender.com and send Claude the output.

## 10. One decision
Sakina's line "the founder who has stood where you are" was removed (it claimed a personal history). Keep it removed or restore it?
