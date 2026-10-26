# Moderation handbook (DRAFT)

**DRAFT for owner and scholar review.** Numbers below are the code defaults in
`backend/src/policy/moderation.ts`; the owner decides the final values.

## Roles
`member`, `moderator`, `admin` (column `users.role`). Credentials (separate
table): `scholar`, `organiser`, `trusted_moderator`, granted only by a person
through `/v1/mod/credentials`. Bootstrap the first admin in SQL:
`update users set role='admin' where email='...';`

## Principles
- Hide first, review second: three independent reports, or any child-safety
  report, hide content until a person looks.
- Every action has a written reason the member can read, and an audit-log line
  (ids only, append-only).
- Staff are never auto-sanctioned. Appeals are decided by a different moderator.

## Queue (`GET /v1/mod/queue`)
Child-safety first, then priority, then age. For each item choose: dismiss,
approve (held posts/meet-ups), or an action (`POST /v1/mod/actions`: hide,
restore, remove, lock_thread, warn, mute, suspend, ban).

## Strikes
Points expire after 90 days. 3 points: 7-day mute. 6 points: 7-day
suspension. Next step: indefinite suspension waiting for an admin to decide
(no automatic permanent ban). Owner decides whether the last step is a ban.

## Child safety
Anything involving a child: remove, preserve the audit record, escalate to the
named safeguarding contact within 24 hours (owner must name this person) and
to the authorities where the law requires.

## Appeals
Members see actions at `/v1/me/moderation` and appeal within 30 days
(`POST /v1/appeals`), even when suspended. Decide at
`/v1/mod/appeals/{id}/decide`: upheld, reduced, denied. Owner must publish a
contact for people who cannot sign in.

## Verification
- Organiser: check the venue by its public contact (the mosque or centre),
  never by what the organiser says. Record the org name; set an expiry.
- Scholar: verify identity and standing with the scholar reviewer.
Revoke with `/v1/mod/credentials/{id}/revoke`.

## Filters
`/v1/admin/filters` manages keyword/link rules at runtime. Built-in takfir,
fatwa and sectarian lists need scholar review. Link allow-list is empty until
the owner names domains.

## Data
Members can export (`GET /v1/me/export`) and delete (`DELETE /v1/me`).
Deleted accounts' posts are anonymised or removed as the member chose.

## Majlis retirement
The older Firestore Majlis stays closed and gated. This server is the single
live forum. Owner decides when to delete the Majlis code and rules.
