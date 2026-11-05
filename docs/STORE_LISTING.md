# Ar-Rayaan — store listing draft (Google Play & Apple App Store)

Everything the stores ask for, drafted and ready to paste. What still needs
the owner is marked **[OWNER]**. Last updated: 2026-11-06.

## Names and ids

| Field | Value |
|---|---|
| App name | Ar-Rayaan: Calm & Care |
| Short name (iOS subtitle, 30 chars) | Faith, family & calm |
| Package / bundle id | com.arrayaan.app (already in the Android config) |
| Version at listing | 0.8.0+8 (pubspec.yaml) |

## Short description (Google Play, 80 chars)

Prayer times, Qur'an, hadith, masjid & halal finder — calm care for Muslim families.

## Full description

Ar-Rayaan is a calm, private companion for Muslim family life.

- Prayer times with your saved place, qibla and a gentle daily rhythm
- Qur'an with reading support, forty hadith, dhikr and du'a
- Masajid & halal food near you on a night map, with community-added
  places — anyone signed in can add a missing masjid, halal shop or
  community event, and the community keeps them honest
- Stories of the prophets and companions, read together as a family
- Hadi and Sakina, the in-app guides, for everyday questions and hard days
- Family wing: children's profiles, academy lessons, parent-teacher chat
- Games the family can play together, online or on one device

Privacy first: no ads, no trackers sold, nothing you write leaves your
device unless you choose to share it. Free, made with love for the ummah.

## Category & tags

- Google Play: Lifestyle (second: Education)
- Apple: Lifestyle (second: Reference)
- Keywords: prayer times, quran, hadith, mosque finder, halal food, muslim
  family, dhikr, qibla, islamic calendar, zakat

## Content rating (both stores)

- No violence, no gambling, no user-to-user stranger contact by default.
- Community submissions (places, events, forum) exist → both stores ask
  about user-generated content. Answer: yes, UGC; moderated (report button,
  auto-hide after community flags, founder takedown, block list).
- Expected rating: Everyone / 4+.

## Data safety (Google Play) / App privacy (Apple)

- Account (optional): email — for sign-in only. **[OWNER: confirm the
  privacy policy URL below covers this]**
- Feedback form: optional email, message, and — only if the user switches
  it on — recent error notes (error types and messages, no user data).
- Location: approximate, only when the user taps "use my location" for
  prayer times or the masjid finder; sent to OpenStreetMap for search.
- Family wing: children's nicknames and learning progress, visible only to
  the family's parents and invited teachers.
- No data sold, no ads, no third-party analytics beyond Firebase
  (analytics/crashlytics) — **[OWNER: decide whether to keep Firebase
  Analytics on; if yes, declare it]**.

## Links

- Privacy policy: https://ar-rayaan.onrender.com/#/legal/privacy
- Terms: https://ar-rayaan.onrender.com/#/legal/terms
- Support/contact: **[OWNER: the contact address — see OWNER_ACTIONS #18]**

## Screenshots to capture on launch day (5–8, phone)

1. Home / Today screen
2. Prayer times
3. Qur'an reader
4. Masajid map with the three tabs (Masajid / Halal Food / Events)
5. A story open (family reading)
6. Hadi answering a question
7. Family wing / academy
8. Share Ar-Rayaan QR card

## Still needed from the owner before submission

1. Google Play Console account ($25 one-time) and an Android signing key
   (let Google manage it — choose "Play App Signing").
2. Apple Developer account ($99/year) and a Mac or CI runner for the iOS
   build (the repo already builds an unsigned iOS artifact in CI).
3. The contact/support address (OWNER_ACTIONS #18).
4. A paid hosting tier for the API/site so the store review never hits a
   cold-start spinner.
5. Publish the Firestore rules and the founder document (OWNER_ACTIONS #24)
   — community submissions and moderation depend on them.
