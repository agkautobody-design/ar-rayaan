import type { AuthInfo, Deps } from './context.js';
import type { Queryable } from './db.js';
import { conflict, forbidden, tooMany } from './errors.js';
import { notify } from './notify.js';
import type { AutoReport, DbFilter } from './policy/content.js';
import { NEW_ACCOUNT_DAYS, NEW_ACCOUNT_MIN_APPROVED_POSTS } from './policy/moderation.js';
import { ownAdultProfile, type ProfileRow } from './profiles.js';
import { COMMUNITY_RULES_VERSION } from './versions.js';

/**
 * Shared checks for forums, meet-ups and moderation. Everything a person must
 * satisfy before they can write in the community lives here so the routes read
 * the same way and a rule is changed in one place.
 */

export interface Member {
  userId: string;
  role: AuthInfo['role'];
  profile: ProfileRow;
  newAccount: boolean;
}

export async function loadFilters(q: Queryable): Promise<DbFilter[]> {
  const r = await q.query<{ kind: DbFilter['kind']; pattern: string }>(
    'select kind, pattern from content_filters where active',
  );
  return r.rows;
}

export interface ActiveSanction {
  kind: 'mute' | 'suspend' | 'ban';
  ends_at: Date | null;
}

export async function activeSanction(
  q: Queryable,
  userId: string,
  kinds: ReadonlyArray<'mute' | 'suspend' | 'ban'>,
  now: Date,
): Promise<ActiveSanction | undefined> {
  const r = await q.query<ActiveSanction>(
    `select kind, ends_at from sanctions
      where user_id = $1 and kind = any($2::text[]) and lifted_at is null
        and starts_at <= $3 and (ends_at is null or ends_at > $3)
      order by ends_at desc nulls first limit 1`,
    [userId, [...kinds], now],
  );
  return r.rows[0];
}

export async function hasAcceptedRules(q: Queryable, userId: string): Promise<boolean> {
  const r = await q.query(
    `select 1 from consents
      where user_id = $1 and kind = 'community_rules' and version = $2 and withdrawn_at is null
      limit 1`,
    [userId, COMMUNITY_RULES_VERSION],
  );
  return r.rowCount > 0;
}

export interface CredentialRow {
  id: string;
  kind: 'scholar' | 'organiser' | 'trusted_moderator';
  org_name: string | null;
}

/** A credential a human admin verified and that is neither revoked nor expired. */
export async function activeCredential(
  q: Queryable,
  userId: string,
  kind: CredentialRow['kind'],
  now: Date,
): Promise<CredentialRow | undefined> {
  const r = await q.query<CredentialRow>(
    `select id, kind, org_name from credentials
      where user_id = $1 and kind = $2 and verified_at is not null and revoked_at is null
        and (expires_at is null or expires_at > $3)
      order by verified_at desc limit 1`,
    [userId, kind, now],
  );
  return r.rows[0];
}

export async function isNewAccount(
  q: Queryable,
  userId: string,
  profileId: string,
  now: Date,
): Promise<boolean> {
  const u = await q.query<{ created_at: Date }>('select created_at from users where id = $1', [userId]);
  const created = u.rows[0]?.created_at;
  if (!created) return true;
  if (now.getTime() - new Date(created).getTime() < NEW_ACCOUNT_DAYS * 86_400_000) return true;
  const p = await q.query<{ n: string }>(
    `select count(*)::text as n from forum_posts where author_profile_id = $1 and status = 'visible'`,
    [profileId],
  );
  return Number(p.rows[0]?.n ?? '0') < NEW_ACCOUNT_MIN_APPROVED_POSTS;
}

export interface MemberChecks {
  /** The profile must be set to appear in the community (its name is shown). */
  visible?: boolean;
  /** The member must have accepted the current community rules. */
  rules?: boolean;
  /** A muted member cannot write. */
  notMuted?: boolean;
}

/**
 * The caller as a community participant: an adult with a profile, and (for
 * writing) a community-visible profile, accepted rules, and no active mute.
 * Minors never get here: they have no login, and the database also refuses
 * their rows.
 */
export async function requireMember(
  q: Queryable,
  deps: Deps,
  auth: AuthInfo,
  checks: MemberChecks = {},
): Promise<Member> {
  const profile = await ownAdultProfile(q, auth.userId);
  if (!profile || profile.erased_at !== null) {
    throw forbidden('profile_required', 'Create your profile first.');
  }
  if (checks.visible && profile.visibility !== 'community') {
    throw forbidden(
      'community_visibility_required',
      'To take part, choose “Visible in the community” in your profile. Your display name will be shown.',
    );
  }
  if (checks.rules && !(await hasAcceptedRules(q, auth.userId))) {
    throw forbidden('rules_not_accepted', 'Please read and accept the community rules first.');
  }
  const now = deps.now();
  if (checks.notMuted) {
    const m = await activeSanction(q, auth.userId, ['mute'], now);
    if (m) {
      throw forbidden(
        'muted',
        m.ends_at
          ? `You cannot post until ${new Date(m.ends_at).toISOString().slice(0, 10)}.`
          : 'You cannot post right now.',
      );
    }
  }
  return {
    userId: auth.userId,
    role: auth.role,
    profile,
    newAccount: await isNewAccount(q, auth.userId, profile.id, now),
  };
}

/** SQL: true when either profile has blocked the other. */
export function blockedEitherWaySql(meParam: string, otherExpr: string): string {
  return `exists (select 1 from blocks bl
            where (bl.blocker_profile = ${meParam} and bl.blocked_profile = ${otherExpr})
               or (bl.blocked_profile = ${meParam} and bl.blocker_profile = ${otherExpr}))`;
}

/** Files a system report, once per target and reason while one is still open. */
export async function fileAutoReport(
  q: Queryable,
  target: { type: 'post' | 'thread' | 'profile' | 'meetup'; id: string },
  rep: AutoReport,
): Promise<void> {
  const dup = await q.query(
    `select 1 from reports where target_type = $1 and target_id = $2 and reason = $3
        and auto and status in ('open', 'triaged') limit 1`,
    [target.type, target.id, rep.reason],
  );
  if (dup.rowCount > 0) return;
  await q.query(
    `insert into reports (reporter_profile_id, target_type, target_id, reason, details, priority, auto)
     values (null, $1, $2, $3, $4, $5, true)`,
    [target.type, target.id, rep.reason, rep.details, rep.priority],
  );
}

export async function notifyAdmins(
  q: Queryable,
  kind: string,
  payload: Record<string, unknown>,
): Promise<void> {
  const r = await q.query<{ id: string }>(
    `select id from users where role = 'admin' and status = 'active'`,
  );
  for (const a of r.rows) await notify(q, a.id, kind, payload);
}

export type ContentType = 'post' | 'thread' | 'meetup';

export interface ContentOwner {
  type: ContentType;
  id: string;
  status: string;
  authorProfileId: string;
  authorUserId: string | null;
}

/** Who wrote [type]/[id], and what state it is in. Undefined when it does not exist. */
export async function contentOwner(
  q: Queryable,
  type: ContentType,
  id: string,
  lock = false,
): Promise<ContentOwner | undefined> {
  const table = type === 'post' ? 'forum_posts' : type === 'thread' ? 'forum_threads' : 'meetups';
  const col = type === 'meetup' ? 'organiser_profile_id' : 'author_profile_id';
  const r = await q.query<{ status: string; pid: string; uid: string | null }>(
    `select c.status, c.${col} as pid, p.user_id as uid
       from ${table} c join profiles p on p.id = c.${col}
      where c.id = $1 ${lock ? `for update of c` : ''}`,
    [id],
  );
  const row = r.rows[0];
  if (!row) return undefined;
  return { type, id, status: row.status, authorProfileId: row.pid, authorUserId: row.uid };
}

/** Recomputes a thread's visible post count and last-post time. */
export async function recountThread(q: Queryable, threadId: string): Promise<void> {
  await q.query(
    `update forum_threads t set
        post_count = (select count(*) from forum_posts p where p.thread_id = t.id and p.status = 'visible'),
        last_post_at = coalesce(
          (select max(p.created_at) from forum_posts p where p.thread_id = t.id and p.status = 'visible'),
          t.created_at)
      where t.id = $1`,
    [threadId],
  );
}

export function assertNotSelf(a: string | null, b: string, message = 'You cannot do that to your own content.'): void {
  if (a !== null && a === b) throw conflict('own_content', message);
}

/** Counts one hit against [key]; throws 429 when the window is used up. */
export function hitLimit(deps: Deps, key: string, max: number, windowSec: number): void {
  const r = deps.limiter.hit(key, max, windowSec * 1000);
  if (!r.allowed) throw tooMany(r.retryAfterSec);
}

export type Standing = 'member' | 'verified' | 'scholar' | 'moderator';

/** Whether [m] meets the standing a category asks for. */
export async function meetsStanding(
  q: Queryable,
  m: Pick<Member, 'userId' | 'role'>,
  required: Standing,
  now: Date,
): Promise<boolean> {
  if (required === 'member') return true;
  const staff = m.role === 'moderator' || m.role === 'admin';
  if (required === 'moderator') return staff;
  if (staff && required === 'verified') return true;
  if (required === 'scholar') return (await activeCredential(q, m.userId, 'scholar', now)) !== undefined;
  for (const k of ['scholar', 'organiser', 'trusted_moderator'] as const) {
    if (await activeCredential(q, m.userId, k, now)) return true;
  }
  return false;
}
