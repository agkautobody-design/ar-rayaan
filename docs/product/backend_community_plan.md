# Ar-Rayaan community backend: research and plan

Status: PROPOSAL for the owner's approval. Phase 0 (this branch) builds a
tested skeleton that is switched OFF everywhere. Nothing is deployed, nothing
is created on Render or Firebase, no secret is in the repository.

Not legal advice. Every legal statement below is a research note for a
lawyer to confirm (section 8).

## 0. Decision in one page

1. The app is NOT backend-less. It already uses Firebase: Authentication
   (email/password, Google, Apple, and anonymous sign-in for game tables),
   Firestore game tables ("Play a friend online" in Ludo and Shatranj, a
   six-letter code, hardened rules, 24-hour expiry) and a Firestore forum
   (the Majlis "Courtyard", closed by the module registry). Section 1 has the
   evidence. A second login system or a second game-room system would be
   redundant, so this plan reuses both.
2. Decision: HYBRID.
   - Keep Firebase Authentication as the one identity. The new service accepts
     the app's Firebase ID token and turns it into its own session
     (`POST /v1/auth/firebase`). No new login screen is needed in production.
   - Keep the Firestore game tables as they are for now. They work, they have
     realtime and offline behaviour built in, and they carry no personal data
     beyond a display name.
   - Add ONE small server (Node/TypeScript, PostgreSQL, on Render) only for
     what Firestore rules cannot enforce safely: guardian links for children,
     the friend graph, invite codes, forums with a review queue, meet-ups,
     reports, bans, appeals, an audit log, erasure and export, scheduled
     clean-up. Section 2 compares the options with evidence.
3. Stack: Node 22 + TypeScript + Fastify 5 + PostgreSQL 16 (Render web
   service + Render Postgres). About US$13 a month to start, US$44 a month
   when it needs room to grow (section 3).
4. Child safety is enforced twice: in the API, and again inside the database
   (triggers and CHECK constraints), so a bug in one layer cannot link an
   adult to a child. Children are profiles inside a parent's account: no
   login, no handle, no public profile, no forum, no meet-up, no messages,
   not findable.
5. Everything is opt-in and OFF. The Flutter flag `COMMUNITY_BACKEND` defaults
   to `off`; the privacy text is NOT changed in this PR because no data is
   sent anywhere yet. The exact wording to publish with the first deployment
   is in section 9.

## 1. What exists today (evidence)

| Area | Where | What it does today |
| --- | --- | --- |
| Accounts | `lib/features/auth/` | `AuthRepository` with a local fake and a Firebase implementation (email+password, Google, Apple). `main.dart` picks Firebase only when `FIREBASE_*` dart-defines are present. |
| Profile | `lib/features/profile/` | Local-only `UserProfile` (uid, name, email). |
| Family wing | `lib/features/academy/application/family_service.dart`, `children_privacy.dart` | Children are local-only; cloud sync is OFF; even with consent a child's name never goes to the cloud. Privacy text version 3. |
| Online games | `lib/features/games/data/game_rooms_service.dart`, `online_lobby.dart`, `firestore.rules` (`game_rooms`) | Anonymous Firebase sign-in, a 6-character code, create/join/move, 24-hour `expireAt`. The display name is the Majlis name (default "Guest of the Courtyard"). There is no parent gate in front of it. |
| Forum | `lib/features/majlis/`, `firestore.rules` (`majlis_*`) | Public Firestore forum, no moderation queue, gated by `assets/system/module_registry.json` (`majlis`: gated). Name rules in `majlis_policy.dart`. |
| Community tab | `lib/features/community/` | Static: masjid finder and Friday times. No friends, no invites. |
| Sharing | `lib/features/share/` | Verse cards, handouts, QR of the app URL. No friend invites. |
| Legal | `lib/features/legal/legal_screens.dart` | Terms and Privacy drafts. Privacy says "What stays on your device" and names Firebase Auth and Firestore for the Majlis. The contact address is still "not published yet". |
| Owner actions | `docs/OWNER_ACTIONS.md` items 2 and 2b | Publish `firestore.rules`; turn on the Firestore TTL policy for `game_rooms.expireAt`. |
| CI | `.github/workflows/pr-check.yml`, `build-web.yml` | Flutter analyze/test/build; Android APK; deploy to the `render` branch. No Firestore emulator; rules are covered by static tests (`test/firestore_rules_hardening_test.dart`). |

Two findings that matter for this plan:

- Online game tables work without a parent gate and put a display name in a
  Firestore document. That conflicts with the family wing's promise (a
  child's name never leaves the device) if a child can reach "Play a friend
  online". Fix in phase 2: a parent gate in front of online play for any
  active child profile, and a neutral table name for children.
- The Majlis is open and unmoderated by design of its Firestore rules. It must
  stay closed until the moderation model in section 10 exists. The new forum
  tables replace it; the Majlis is retired when they go live.

## 2. Firebase or a separate server? The comparison

Question from the coordinator: extend Firebase (Auth + Firestore + Cloud
Functions + App Check), or add a separate server only for what Firebase does
badly?

| Criterion | Firebase only (Firestore + rules + Cloud Functions) | Hybrid (chosen): Firebase Auth + Firestore games + one small server |
| --- | --- | --- |
| Reuse of what exists | Maximum | Auth and game tables reused unchanged |
| Child-safety enforcement | Rules run server-side and cannot be bypassed, but they judge one request at a time. "Guardian A and guardian B both approved, neither profile is an adult, both are under their friend cap, nobody blocked anybody, the code was unused" spans several documents. Rules allow only a handful of `get()` lookups per request, cannot count, and cannot run a multi-document transaction with checks; the usual answer is a Cloud Function, which makes it a server anyway. | Constraints live in SQL: foreign keys, CHECK, unique pairs, triggers, transactions. A buggy client or a buggy route still cannot store an adult-child friendship (the trigger refuses it; tested). |
| Moderation | Queue, strikes, appeals, keyword filters, audit log all need queries Firestore does not do well (ordering by priority, joins, aggregates) | Plain SQL |
| Erasure / export | One user's data is spread over many collections; cascading deletes need a Function | One transaction; export is a few queries |
| Cost | Spark is free but Cloud Functions need the Blaze (billing) plan; Firestore is billed per read, and chat-like or feed-like screens multiply reads. Exact prices: check the Firebase pricing page, not verified here. | Render prices are fixed per month (verified, section 3) |
| Data residency / PIPEDA | Firestore offers North American locations including Canada (Montreal, Toronto) at project creation. NOT verified here; confirm in the Firebase console. A real advantage. | Render has no Canadian region (nearest: Ohio, Virginia). NOT verified here; confirm. Not a legal bar by itself; PIPEDA requires openness about processing abroad (section 9). The data is portable Postgres, so it can move to a Canadian host later. |
| Offline | Firestore SDK has offline cache and queued writes | Server data needs an app-side cache; fine for friends/invites/forums; games keep Firestore's offline behaviour |
| CI testability | Firestore emulator needs Java and a `firebase-tools` download. GitHub runners have Java, so it can run in CI; I could NOT run it here (downloads blocked). Today rules are only tested statically. | Verified here: 80 tests pass on in-memory Postgres (PGlite) and on real PostgreSQL 16; CI runs both |
| Lock-in | High (rules language, Functions runtime) | Low (Postgres, Docker, plain Node) |
| Ops burden | Lowest | One extra service to watch; Render handles TLS, deploys, backups on paid Postgres |

Where Firebase wins (and is kept): identity, realtime two-player tables,
offline cache. Where it loses: relational safety rules, moderation, erasure.

Verdict: do not rebuild what works (Auth, game tables); do not stretch rules
and Functions into a relational moderation system. If the owner prefers zero
new infrastructure, the fallback is "Firebase only with Cloud Functions", and
the SQL migrations in `backend/migrations/` are the specification of the
data and constraints those Functions would have to enforce. It costs more
build time and cannot enforce the adult/child separation as strongly.

Changes to Firebase-side files in this PR: none. `firestore.rules` is not
touched (the owner has not yet published the last change, OWNER_ACTIONS
item 2; changing it again now would add risk with no benefit).

## 3. Stack choice and cost

Compared for a one-person-owner project that must stay testable in CI.

| | Dart `shelf` | Node + TypeScript + Fastify (chosen) | Other (Go, Python/FastAPI, Supabase) |
| --- | --- | --- | --- |
| Shares language with the app | Yes (models could be shared) | No | No |
| Ecosystem for Postgres, rate limiting, OpenAPI, test tooling | Thin | Rich and mainstream | Rich |
| Tests in this environment | The Dart SDK here has no package manager access, so a shelf server could not be built or tested here at all | Built and tested here, twice (in-memory and real Postgres) | Go or Python would work here too |
| Runs on Render | Docker only | Native or Docker | Native or Docker |
| Hiring / future help | Rare | Common | Common |
| Fit with Firebase ID tokens | Verify RS256 yourself | Same, with `node:crypto` (done, tested) | Same |

Fastify was chosen over Express for built-in schema validation hooks, JSON
logging (pino) and speed; Zod does the input validation. Supabase was
considered (Postgres plus auth plus row-level security) but it would be a
second identity system next to Firebase and puts the safety rules in policies
rather than code that can be unit-tested in CI. Dart shelf is attractive for
sharing models but the app and server do not share enough code to pay for
the weaker tooling.

Dependencies: `fastify`, `pg`, `pino`, `zod` at runtime. Dev: `typescript`,
`tsx`, `@electric-sql/pglite`, type packages. `npm audit` is clean at the
time of writing; CI runs the production audit.

### Render cost (verified from https://render.com/pricing in this session)

| Item | Start | Room to grow |
| --- | --- | --- |
| Web service | US$7 / month (under 1 CPU, 512 MB) | US$25 (1 CPU, 2 GB) |
| PostgreSQL | US$6 / month (256 MB; 1 GB storage included) | US$19 (1 GB RAM) or US$40 (2 GB) |
| Extra storage | US$0.30 per GB per month | |
| Total | about US$13 / month | about US$44 / month |

The Render workspace plan (Hobby US$0, Pro US$25) is separate from compute;
whether the owner's existing workspace needs Pro is not known. The blueprint
uses plan names `starter` and `basic-256mb`; confirm the exact names in the
dashboard when applying it (not verified).
Email: Resend or similar has a free tier for low volume (not verified here);
with `AUTH_MODE=firebase` the server sends no email at all.

## 4. Authentication design

- Production path (`AUTH_MODE=firebase`): the app signs in with Firebase as it
  does today, then calls `POST /v1/auth/firebase` with the ID token. The server
  verifies it without the Admin SDK: RS256 signature against Google's
  published keys (cached by `max-age`), `iss` = `https://securetoken.google.com/<project>`,
  `aud` = project, `exp`, `iat`, non-empty `sub`. It REFUSES anonymous Firebase
  users (the game tables' identity) and unverified emails. The result is an
  opaque session token (`ar_...`), 256 bits, stored only as a SHA-256 hash,
  30-day sliding expiry, revocable per device (`/v1/auth/sessions`).
- Pluggable second path (`AUTH_MODE=email_code` or `both`): passwordless
  email code (6 digits, 10 minutes, 5 attempts, single use, HMAC-hashed with a
  server secret, never logged). The sender is an interface: `ResendEmailSender`
  (written to Resend's documented endpoint, NOT exercised against the live
  service), `ConsoleEmailSender` (development only, refused in production),
  `MemoryEmailSender` (tests). Adding Postmark/SES/SMTP is one class.
  Use case: Android/iOS builds without Firebase, development, or leaving
  Firebase later.
- New accounts must confirm they are 18 or over and accept the current Terms
  and Privacy versions (recorded in `consents`). No date of birth is stored.
  A person under 18 never creates an account: a parent creates a child or
  teen profile (section 8).
- Suspended and banned accounts are refused at sign-in and on every request.
- No secrets in the repository. Owner-supplied values: section 19.

## 5. Data model

Migrations are plain SQL in `backend/migrations/` (six files, checksum-checked,
applied in order, each in a transaction). The schema is the contract:

| Group | Tables | Notes |
| --- | --- | --- |
| Accounts | `users`, `sessions`, `auth_codes`, `consents` | email kept only to send a code; `email_hash` is a keyed hash; `firebase_uid` links the Firebase identity |
| People | `profiles`, `parental_links` | `kind` = adult / teen / child. Minors have no login (`managed_by` a guardian), no handle, no bio, always private (CHECK constraints). |
| Friend graph | `friendships`, `blocks`, `invites`, `invite_redemptions` | one row per pair (ordered ids); guardian approval stamps per minor side; a trigger refuses adult-minor pairs and accepted minor pairs without both stamps |
| Forums | `forum_categories`, `forum_threads`, `forum_posts`, `forum_reactions` | every post has a label (`community_opinion` by default, `scholar_answer` only from a verified scholar); reactions are benefit / dua / thanks, no downvotes |
| Moderation | `credentials`, `reports`, `moderation_actions`, `strikes`, `sanctions`, `appeals`, `content_filters` | child-safety reports get high priority; every action carries a reason; one appeal per action |
| Meet-ups | `meetups`, `meetup_rsvps` | public venue kinds only, no private-address column, rounded coordinates |
| Notifications | `notifications`, `push_subscriptions` | payload is ids and a short code only; push reserved for later |
| Audit | `audit_log` | append-only (trigger refuses update and delete); ids only, no names or emails |

Game rooms, players and moves are NOT in this schema: they stay in Firestore
(section 2). Invites already support `kind='room'` with a `target_ref` for the
six-letter code, for the phase that adds friends-only tables.

## 6. API outline

Implemented now (see `backend/openapi.yaml`; a test fails if a route and the
file disagree):

- System: `GET /healthz` (no database), `GET /readyz`.
- Auth: `POST /v1/auth/firebase`, `POST /v1/auth/request-code`,
  `POST /v1/auth/verify-code`, `POST /v1/auth/logout`, `GET /v1/auth/sessions`,
  `DELETE /v1/auth/sessions/{id}`.
- Me: `GET /v1/me`, `PUT /v1/me/profile`, `DELETE /v1/me` (erase),
  `GET /v1/me/export`.
- Guardian: `POST|GET /v1/guardian/children`, `PATCH|DELETE /v1/guardian/children/{id}`.
- Friends: `GET /v1/friends`, `POST /v1/friends/requests`,
  `POST /v1/friends/requests/{id}/accept|decline`, `DELETE /v1/friends/{id}`,
  `GET|POST /v1/blocks`, `DELETE /v1/blocks/{profileId}`.
- Invites: `POST|GET /v1/invites`, `DELETE /v1/invites/{id}`,
  `POST /v1/invites/preview`, `POST /v1/invites/redeem`.

Planned (schema exists, routes do not): forums (`/v1/forums/...`), reports
(`/v1/reports`), moderator queue (`/v1/mod/...`), meet-ups (`/v1/meetups/...`),
notifications (`/v1/notifications`), appeals, credentials.

Realtime: start with polling (30 s while a screen is open, backing off when
hidden; a few hundred users cost almost nothing). Add Server-Sent Events for
notifications later; WebSocket only if a feature truly needs it. Games keep
Firestore's realtime listeners.

## 7. Rate limits and anti-abuse

Implemented and tested: per-IP and per-user fixed windows (sign-in codes
10/hour/IP and 5/hour/address; code checks 30/hour/IP; friend requests
20/day; invites 30/hour and 20 active; invite lookups lock out after 10 misses
in an hour; profile writes, account deletion, export, child creation each
capped), 16 KB request bodies, strict input validation that never echoes
values, identical answers for "does not exist" and "not allowed" where
existence would leak (private profiles, bad invite codes, blocked people),
decline cooldown of 30 days, friend caps (200 adults, 30 minors).
The limiter is in memory: correct for one instance. Move counters to
Postgres if the service is ever scaled to several instances.
Planned: new-account posting limits, link and keyword filters, App Check on
the Firebase side, CAPTCHA only if abuse appears (it adds friction and
tracking).

## 8. Child safety and legal (research notes for a lawyer)

Frameworks considered, all principles rather than a claim of compliance:

- PIPEDA (Canada; the owner is in Ontario). Ontario has no general
  private-sector privacy statute, so PIPEDA is the baseline for commercial
  activity. The Privacy Commissioner's 2017 review of children's educational
  apps (summary: https://www.hunton.com/privacy-and-information-security-law/canadian-privacy-commissioner-issues-report-childrens-educational-apps)
  says: under 13 needs parent or guardian consent; for older minors adapt the
  consent to their maturity. The design follows that: under-13 only as a
  child profile under a parent who consents and can delete.
- COPPA (US). The FTC's amended rule was published 22 April 2025, effective
  23 June 2025, compliance by 22 April 2026 (https://www.jonesday.com/en/insights/2025/05/ftc-finalizes-amendments-to-coppa--rule).
  It adds a written retention policy, a written security programme, and
  separate consent for sharing with third parties. Relevant if US children
  can use the app. The design collects almost nothing about a child
  (a nickname) and shares nothing.
- GDPR Article 8 and the UK Age-Appropriate Design Code. The Code has 15
  standards (https://ico.org.uk/media/for-organisations/uk-gdpr-guidance-and-resources/childrens-information/childrens-code-guidance-and-resources/age-appropriate-design-a-code-of-practice-for-online-services-2-1.pdf):
  best interests, DPIA, age-appropriate application, transparency, detrimental
  use of data, policies and community standards, default settings, data
  minimisation, data sharing, geolocation, parental controls, profiling, nudge
  techniques, connected toys, online tools. The design maps to them: high
  privacy by default, no profiling, no geolocation for children, no nudges or
  streak pressure on children (also the owner's streak decision is pending),
  guardian controls, minimal data.
- Also for the lawyer: Quebec's Law 25 if Quebec residents use the service;
  Canada's anti-spam law (CASL) for any non-transactional email (none planned);
  Ontario's duty to report a child who may need protection (Child, Youth and
  Family Services Act) and the federal duty of internet service providers to
  report child sexual exploitation material, which affects what a moderator
  does on a child-safety report; PIPEDA breach reporting. Recommend a
  Data Protection Impact Assessment (DPIA) before launch.

### Rules built into the skeleton

1. Accounts are for people 18 and over (attested, no date of birth stored).
2. Under 13 exists only as a `child` profile inside a parent's account, after
   a recorded parent consent (version, time, which child). 13 to 17 is a
   `teen` profile managed the same way in phase 1. A later phase may give
   teens their own login under a parental link.
3. A minor profile has no handle, no bio, is always private, cannot be found,
   cannot post in forums, cannot organise or RSVP to a meet-up alone, and
   has no direct messages. (DB constraints, tested.)
4. No profile has direct messages in phase 1. Friends exist to play together.
5. Friendships never cross the adult/minor line. Two children connect only
   through an invite one guardian made and the other guardian redeemed; each
   guardian's action is stored as the approval for their child (`guardian_*_at`).
   An adult who holds a child's code is refused and learns nothing, not even
   the child's name. A child's invite works once.
6. A child's name is shown only to a guardian who redeems the code, and to
   that guardian's own screens. Strangers see "a family invite".
7. Data minimisation: a child profile is a nickname, a kind, a creation time.
   No age, photo, voice, contact, location. Parents can delete a child at any
   time; the account can be erased and exported (section 9).
8. Deleting a parent deletes their children.

### Open decisions for the owner and lawyer

- Whether 13 to 17 should get their own login (more autonomy, more risk).
- Whether an adult relative may ever be a child's friend (currently never).
- Retention of the keyed email hash for banned accounts that erase
  themselves (currently kept, to stop ban evasion; needs a legal basis).
- Parental consent method strength (currently a recorded declaration inside a
  signed-in adult account; COPPA's list of verifiable methods is longer).

## 9. Privacy-first design and the text to publish

- No advertising, no ad tracking, no analytics SDK, no selling or sharing of
  data. The server logs one JSON line per request: route pattern, status,
  timing and a keyed 12-character account tag. Never emails, IP addresses,
  names, handles, request bodies, codes or tokens (a test asserts this).
- Emails and invite codes are stored as keyed hashes where a hash is enough.
  The email itself is kept only so a code can be sent; with `AUTH_MODE=firebase`
  it is the verified address Firebase already holds.
- Erasure: `DELETE /v1/me` removes personal data in one transaction (children,
  friendships, invites, sessions, consents, notifications), turns the profile
  into "Deleted member", and offers to remove or anonymise forum posts.
  Export: `GET /v1/me/export` returns everything held.
- Retention job (hourly, in-process): sign-in codes 1 day, expired sessions
  7 days, expired invites 30 days, notifications 90 days (14 once read).
- Residency: Render's nearest regions are in the US; Firestore may offer
  Canadian locations. PIPEDA does not forbid processing abroad but expects
  openness. Disclose it in the privacy text; if the lawyer wants Canadian
  storage, move the Postgres to a Canadian host (it is plain PostgreSQL).
- Every server feature is opt-in: nothing is sent until the person creates a
  community account. The app works fully without it, as today.

Privacy text to publish WITH the first deployment (not added now, because
today nothing is sent; draft for the lawyer):

> **Community account (optional).** If you choose to join the community
> features, we keep your sign-in email, a display name you choose, and an
> optional handle on our server, hosted by Render in the United States. We
> use them to let you add friends, accept invitations and take part in
> forums and meet-ups. Your profile is private unless you choose otherwise.
> We do not sell data, show advertising, or track you across other sites. You
> can export or erase your account at any time in the app; erasing removes
> your personal data and your children's profiles. Server logs do not contain
> your email, address, name or messages.
>
> **Children.** A parent or guardian can add a child as a profile inside the
> parent's account. We store only the nickname the parent chooses. A child
> has no login, cannot be found by anyone, cannot post or be messaged, and
> can be connected only to other children whose parents approved the link.
> Online game tables currently use Google's Firebase service (see "Your
> account"); we will put a parent check in front of them for children.

Also update `children_privacy.dart` (its bullet "All of it stays on this
device... not sent to our servers") in the same commit that turns the backend
on for any family feature; its version number must be bumped.

## 10. Moderation model

Tables exist; routes arrive in phase 3.

- Report: any member can report a post, thread, profile, meet-up. Reasons:
  abuse, harassment, hate, sectarian, religious misinformation, sexual,
  child safety, spam, privacy, scam, other. Child-safety reports have the top
  priority and notify every admin.
- Hide first, judge second: a report threshold hides content pending review
  (the reporter is never revealed). Moderators see a queue ordered by priority
  then age (the Reddit "modqueue" idea).
- Actions (always with a reason the person can read): hide, restore, remove,
  lock thread, warn, mute, suspend, ban, verify or revoke a credential.
- Strikes expire; points trigger automatic sanctions (for example 3 points
  mute for 7 days, 6 suspend, 10 ban). The numbers are for the owner to set.
- Appeals: one per action, decided by a different moderator.
- Trusted moderators: volunteers with a `trusted_moderator` credential, a
  written code of conduct and an audit trail; admin-only for bans.
- Filters: block-word (refused), review-word (goes to the queue), link rules
  (new accounts cannot post links unless the domain is allowed) from
  `content_filters`. Discord's AutoMod works the same way: it acts before the
  post appears and alerts moderators (https://discord.com/community/automating-moderation-community-support).
- AI assist later: classify toxicity or likely religious misinformation to
  RANK the queue only. A person decides. No child content is ever sent to an
  AI service (matches the family wing's promise).
- Slow mode and temporary member limits (Facebook Groups has both:
  https://techcrunch.com/2021/06/16/facebook-rolls-out-new-tools-for-group-admins-including-automated-moderation-aids/).
- Strict categories (sensitive topics, ask-a-scholar) hold every new post for
  review.

## 11. Forum rules: proposed defaults for the owner to decide

Categories (proposal): Welcome and introductions; Learning together
(Qur'an, Arabic, tajweed); Daily life and family; Ask a scholar; Wellbeing
and support; Announcements (staff only); Sensitive topics (strict).

1. Adab first: speak kindly, assume good faith, say salam, no mocking.
2. No takfir, no declaring other Muslims out of the faith, no fatwa wars.
3. No personal rulings. A post is a community opinion unless it comes from a
   verified scholar in "Ask a scholar".
4. Sectarian and madhhab differences are discussed only in the Sensitive
   category, where every post is reviewed before it appears.
5. No party politics or calls for violence (proposed default; the owner
   decides whether any political discussion is allowed).
6. No sharing private information about other people; no screenshots of
   private chats; no personal contact details or private addresses.
7. No spam, advertising, fundraising or links to unknown sites by new
   accounts.
8. Support, not diagnosis: wellbeing posts show the help-resources banner the
   app already has; moderators escalate anyone at risk.
9. Adults only. Children never post.

Labelling: every post shows its label. "Community opinion" is the default and
is visibly not guidance. "Scholar answer" appears only for a verified scholar
credential with a named reviewer. Hadi never reads forum content and never
treats it as religious guidance: forum data is in the server database only,
and no Hadi code path loads it (a test should assert this when the forum
screens land). Who the named scholars are is the owner's decision
(OWNER_ACTIONS item 4).

## 12. Meet-up safety

- Public venues only: mosque, community centre, library, cafe, park, school
  hall, other public. The schema has no "home" value and no private-address
  field; locations are rounded to about 100 m.
- Organiser verification: a meet-up is published only after review, or
  immediately if the organiser holds a verified `organiser` credential
  (a mosque or community body confirmed by an admin). Admin checks a mosque
  by contacting it through its public channel.
- Audience set by the organiser: open, brothers only, sisters only, families.
  Gender-separated and family-only options are the organiser's setting, not a
  guess by the app.
- Minors: adults only by default. If the organiser allows it, a minor can be
  listed only when a guardian RSVPs and attends (`guardian_user_id`).
- Reporting on every meet-up page; reports during or after an event go to the
  queue (Meetup does the same: https://help.meetup.com/hc/en-us/articles/39257846459789-Reporting-a-Meetup-group-or-event).
- Disclaimers shown before RSVP: the app does not vouch for attendees;
  meet in public; tell someone; leave if uncomfortable; the organiser is
  responsible for the event.
- Lawyer: liability wording, event-insurance guidance for organisers.

## 13. Friend invites

- Contact-free by default: no address-book upload, no phone number, no
  location search.
- Ways to connect: invite link (`.../#/join/CODE`, share through any app),
  a QR of that link (the app already has `qr_flutter`), the 10-character code
  read aloud (no 0/O/1/I/L/U), or an exact handle for adults who chose to be
  findable. Same pattern as the owner's earlier "people-finding" decisions
  for the calling app.
- Codes are random (about 49 bits), stored hashed, shown once, expire
  (default 72 hours, at most 30 days), can be revoked, are rate-limited
  against guessing, and a child's code works once.

## 14. Notifications

In-app list first (table `notifications`; ids and a short code only, the app
writes the words). Web push later (`push_subscriptions` is reserved and empty)
and only after an explicit opt-in. No marketing notifications. No streak
pressure notifications to children.

## 15. Offline-first

The app must keep working with the backend off or unreachable, as now. The
client foundation does this by construction: with the flag off every call
fails fast with a friendly error and does nothing else; community screens
(later) show cached lists and queue nothing risky. Game tables keep Firestore's
offline behaviour. Account creation, invites and moderation require a
connection and say so.

## 16. Cost and scale phases

| Phase | Users | Setup | About / month (USD) |
| --- | --- | --- | --- |
| 1 Beta | up to 1,000 | Starter web + Postgres 256 MB | 13 |
| 2 Growing | 1,000 to 20,000 | Standard web + Postgres 1 GB | 44 |
| 3 Busy | 20,000+ | 2 web instances (move rate limits to Postgres), Postgres 2 to 4 GB, read cache | 100 to 150 |

Postgres at this scale is small: friends, invites and posts are kilobytes.

## 17. Phased build plan and who does what

| Phase | Deliverable | Claude | Owner |
| --- | --- | --- | --- |
| 0 (this PR) | Plan, backend skeleton, Flutter foundation, CI | done | approve the plan, decide section 11 and 12 defaults |
| 1 | Deploy: apply the blueprint, set variables, run migrations; first sign-in from the app behind the flag; account, profile, family and invite screens; privacy text and parent consent text; DPIA | build screens and tests | Render workspace and plan, Firebase project id, domain, lawyer review |
| 2 | Friends UI and QR; parent gate and neutral names in front of online games; friends-only tables (invite `kind=room`); Firestore emulator rules tests in CI | build | publish `firestore.rules` (item 2), TTL (2b) |
| 3 | Forums with reports, review queue, strikes, appeals, filters; retire the Majlis; moderator console (web page) | build | name the moderators and scholars; approve rules |
| 4 | Meet-ups with organiser verification | build | verify first organisers; liability wording |
| 5 | Notifications (SSE, then web push), AI-assisted ranking of the queue, teen logins if wanted | build | decisions |

Each phase ships behind its own flag and stays off until the owner turns it
on. The existing CI jobs are untouched.

## 18. How other apps do it (research)

Fetched and read in this session:

- Meetup: published Community Guidelines (moderation and safety, organiser
  standards, reporting) and a Trust and Safety team that reviews reports and
  does not share outcomes with the reporter.
  https://help.meetup.com/hc/en-us/sections/360000683791-Community-Guidelines ,
  https://help.meetup.com/hc/en-us/articles/39257846459789-Reporting-a-Meetup-group-or-event
  Lesson: organiser standards plus a visible report button on every event.
- Discord: AutoMod filters messages before they post, custom word lists,
  wildcard matching, alerts moderators, and leaves context-dependent calls
  to humans. https://discord.com/community/automating-moderation-community-support
  Lesson: automate the obvious, keep a person for judgment.
- Facebook Groups: Admin Assist (rules on account age, past violations,
  promotional content), conflict alerts, slow mode, temporary per-member
  limits, member summary, appeals to the platform.
  https://techcrunch.com/2021/06/16/facebook-rolls-out-new-tools-for-group-admins-including-automated-moderation-aids/
  Lesson: cheap, rule-based limits for new or flagged members.
- Muzz (Muslim marriage app): manual moderation of profiles, selfie
  verification (since 2016), a chaperone feature. https://en.wikipedia.org/wiki/Muzz_(dating_app)
  Lesson: identity verification and an optional guardian view build trust
  with families. Relevant to meet-up organiser verification.
- Quran.com / QuranReflect: guests read freely, signed-in users post;
  the product page does not describe moderation rules.
  https://quran.com/product-updates/quranreflect-a-new-social-experience-for-quran-reflections
  Lesson: read-only access for guests lowers the stakes; the actual
  moderation policy must be read on the site itself (not done).
- Reddit moderators: research on how modqueues are used.
  https://arxiv.org/html/2509.07314v1 (appeared in search; not read in full).

Named in the brief but NOT researched in depth (no source read): Muslim Pro's
community features, Salaam and Salams safety features. Do this before copying
anything from them.

## 19. What the owner must provide or approve

1. Approve the hybrid decision (section 2) or ask for Firebase only.
2. Render: confirm the workspace and plan, approve about US$13 a month to
   start, then apply `backend/render.yaml` (Blueprint file path
   `backend/render.yaml`). Nothing has been created.
3. The Firebase project id (the one the app already uses) for
   `FIREBASE_PROJECT_ID`.
4. The web origin(s) for `CORS_ORIGINS` (currently https://ar-rayaan.onrender.com;
   add the custom domain when chosen) and a domain name for the API (for
   example api.rhwktech.com) if wanted.
5. If email-code sign-in is wanted: an email provider account and key
   (`RESEND_API_KEY`), and a sending address on a domain the owner controls
   (`EMAIL_FROM`) with its DNS records. Not needed with Firebase sign-in.
6. Moderators (names or a call for volunteers), the scholars for "Ask a
   scholar", and who handles a child-safety report within 24 hours.
7. Forum rules (section 11) and meet-up rules (section 12): approve or edit.
8. Legal review: Terms, Privacy, parent consent text, the section 8 open
   decisions, the privacy contact address, and whether to incorporate RHW
   Technologies before launch (OWNER_ACTIONS item 6).
9. GitHub: add `Backend CI` as a required check once it has run on a PR.
10. Secrets are set only in the Render dashboard, never in the repository:
    `PEPPER` (Render can generate it; never change it after accounts exist),
    `FIREBASE_PROJECT_ID`, `CORS_ORIGINS`, `PUBLIC_APP_URL`, and the email
    values if used.

## 20. What was and was not verified

Verified here: backend type-check and build; 80 backend tests on in-memory
PostgreSQL and on a real PostgreSQL 16; migrations apply twice on a clean
database; the server starts, answers `/healthz` and `/readyz`, refuses an
incomplete production configuration; no personal data in logs; the OpenAPI
file matches the routes; Firebase ID-token checks with a locally generated key
pair; Flutter client files analysed with the real Dart analyzer (with small
stubs for packages that cannot be downloaded) and their tests run with a
minimal stand-in for `flutter_test`.

Not verified: the real `flutter analyze` and `flutter test` (CI is the
compiler); the Docker build (no Docker daemon here; CI builds it); the
Render blueprint (not applied; plan names to confirm); Resend delivery; a
live Firebase ID token against Google's real keys; the Firestore emulator;
Render's and Firebase's regions and Firebase prices; every legal point.
