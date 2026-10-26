import { activeSanction, notifyAdmins, recountThread, type ContentType } from './community.js';
import { audit, type Role } from './context.js';
import type { Queryable } from './db.js';
import { notify } from './notify.js';
import { STRIKE_LADDER, STRIKE_LIFETIME_DAYS } from './policy/moderation.js';

/**
 * The moving parts of moderation, shared by the report route (which can hide
 * something automatically) and the moderator routes. Every change goes through
 * [recordAction], so every action has a reason the affected person can read
 * and a line in the append-only audit log (ids only).
 */

export type ModAction =
  | 'hide' | 'restore' | 'remove' | 'lock_thread' | 'unlock_thread' | 'warn'
  | 'mute' | 'suspend' | 'ban' | 'unban' | 'verify_credential' | 'revoke_credential';

export interface ActionInput {
  /** null = the system (automatic hide, strike ladder). */
  moderatorUserId: string | null;
  moderatorRole?: Role | null;
  targetUserId: string | null;
  targetType?: string | undefined;
  targetId?: string | undefined;
  action: ModAction;
  reason: string;
  reportId?: string | null | undefined;
  expiresAt?: Date | null | undefined;
  now: Date;
}

export async function recordAction(q: Queryable, a: ActionInput): Promise<string> {
  const r = await q.query<{ id: string }>(
    `insert into moderation_actions
       (moderator_user_id, target_user_id, target_type, target_id, action, reason, report_id, expires_at, created_at)
     values ($1, $2, $3, $4, $5, $6, $7, $8, $9) returning id`,
    [
      a.moderatorUserId, a.targetUserId, a.targetType ?? null, a.targetId ?? null, a.action, a.reason,
      a.reportId ?? null, a.expiresAt ?? null, a.now,
    ],
  );
  const id = r.rows[0]?.id ?? '';
  await audit(q, {
    actorUserId: a.moderatorUserId,
    actorRole: a.moderatorRole ?? (a.moderatorUserId === null ? null : 'moderator'),
    action: `mod.${a.action}`,
    ...(a.targetType ? { targetType: a.targetType } : {}),
    ...(a.targetId ? { targetId: a.targetId } : {}),
    meta: { actionId: id, targetUser: a.targetUserId, reportId: a.reportId ?? null, system: a.moderatorUserId === null },
  });
  return id;
}

const TABLE: Record<ContentType, string> = { post: 'forum_posts', thread: 'forum_threads', meetup: 'meetups' };

/** What "visible again" means for each kind of content. */
export const LIVE_STATUS: Record<ContentType, string> = { post: 'visible', thread: 'open', meetup: 'published' };
/** Statuses a hide can start from. */
const HIDEABLE: Record<ContentType, string[]> = {
  post: ['visible'],
  thread: ['open', 'locked'],
  meetup: ['published'],
};

export async function setStatus(
  q: Queryable,
  type: ContentType,
  id: string,
  status: string,
  now: Date,
): Promise<void> {
  if (type === 'meetup') {
    await q.query(
      `update meetups set status = $2, published_at = case when $2 = 'published' then coalesce(published_at, $3) else published_at end where id = $1`,
      [id, status, now],
    );
  } else {
    await q.query(`update ${TABLE[type]} set status = $2 where id = $1`, [id, status]);
  }
  if (type === 'thread') await recountThread(q, id);
  if (type === 'post') {
    const t = await q.query<{ thread_id: string }>('select thread_id from forum_posts where id = $1', [id]);
    const tid = t.rows[0]?.thread_id;
    if (tid) await recountThread(q, tid);
  }
}

/** Hides live content. Returns true when it changed. */
export async function hideContent(q: Queryable, type: ContentType, id: string, now: Date): Promise<boolean> {
  const r = await q.query<{ status: string }>(`select status from ${TABLE[type]} where id = $1 for update`, [id]);
  const st = r.rows[0]?.status;
  if (!st || !HIDEABLE[type].includes(st)) return false;
  await setStatus(q, type, id, 'hidden', now);
  return true;
}

export async function activePoints(q: Queryable, userId: string, now: Date): Promise<number> {
  const r = await q.query<{ n: string }>(
    'select coalesce(sum(points), 0)::text as n from strikes where user_id = $1 and expires_at > $2',
    [userId, now],
  );
  return Number(r.rows[0]?.n ?? '0');
}

export async function addSanction(
  q: Queryable,
  s: {
    userId: string;
    kind: 'mute' | 'suspend' | 'ban';
    endsAt: Date | null;
    actionId: string;
    now: Date;
  },
): Promise<void> {
  await q.query(
    `insert into sanctions (user_id, kind, starts_at, ends_at, action_id) values ($1, $2, $3, $4, $5)`,
    [s.userId, s.kind, s.now, s.endsAt, s.actionId],
  );
  if (s.kind === 'suspend') {
    await q.query(`update users set status = 'suspended' where id = $1 and status = 'active'`, [s.userId]);
  } else if (s.kind === 'ban') {
    await q.query(`update users set status = 'banned' where id = $1 and status in ('active', 'suspended')`, [s.userId]);
  }
}

/** Ends every live sanction of [kinds] and reactivates the account if nothing else holds it. */
export async function liftSanctions(
  q: Queryable,
  userId: string,
  kinds: ReadonlyArray<'mute' | 'suspend' | 'ban'>,
  now: Date,
  onlyAction?: string,
): Promise<void> {
  await q.query(
    `update sanctions set lifted_at = $3
      where user_id = $1 and kind = any($2::text[]) and lifted_at is null
        and ($4::uuid is null or action_id = $4::uuid)`,
    [userId, [...kinds], now, onlyAction ?? null],
  );
  const still = await activeSanction(q, userId, ['suspend', 'ban'], now);
  if (!still) {
    await q.query(`update users set status = 'active' where id = $1 and status in ('suspended', 'banned')`, [userId]);
  }
}

/**
 * Adds strike points and takes the automatic step when a threshold is crossed:
 * a mute, then a suspension, then an indefinite suspension that waits for an
 * admin. Staff are never sanctioned automatically.
 */
export async function applyStrike(
  q: Queryable,
  userId: string,
  points: number,
  actionId: string,
  now: Date,
): Promise<void> {
  if (points <= 0) return;
  const before = await activePoints(q, userId, now);
  await q.query(
    `insert into strikes (user_id, action_id, points, created_at, expires_at) values ($1, $2, $3, $4, $5)`,
    [userId, actionId, points, now, new Date(now.getTime() + STRIKE_LIFETIME_DAYS * 86_400_000)],
  );
  const after = before + points;
  const crossed = STRIKE_LADDER.filter((s) => before < s.points && s.points <= after).pop();
  if (!crossed) return;
  const u = await q.query<{ role: string; status: string }>('select role, status from users where id = $1', [userId]);
  const user = u.rows[0];
  if (!user || user.role !== 'member' || user.status === 'deleted' || user.status === 'banned') return;
  if (crossed.sanction === 'mute') {
    if (await activeSanction(q, userId, ['mute', 'suspend', 'ban'], now)) return;
  } else if (crossed.days === null) {
    // The last step waits for an admin: skip only if one already is waiting.
    const waiting = await q.query(
      `select 1 from sanctions where user_id = $1 and kind in ('suspend', 'ban') and lifted_at is null
          and ends_at is null limit 1`,
      [userId],
    );
    if (waiting.rowCount > 0) return;
  } else if (await activeSanction(q, userId, ['suspend', 'ban'], now)) {
    return;
  }
  const endsAt = crossed.days === null ? null : new Date(now.getTime() + crossed.days * 86_400_000);
  const reason = `Automatic step after reaching ${crossed.points} strike points. ${
    crossed.days === null ? 'An admin will review your case.' : `It lasts ${crossed.days} days.`
  } You can appeal.`;
  const id = await recordAction(q, {
    moderatorUserId: null,
    targetUserId: userId,
    action: crossed.sanction,
    reason,
    expiresAt: endsAt,
    now,
  });
  await addSanction(q, { userId, kind: crossed.sanction, endsAt, actionId: id, now });
  await notify(q, userId, 'moderation_action', { actionId: id, action: crossed.sanction });
  if (crossed.days === null) await notifyAdmins(q, 'strike_review', { userId });
}

/** Tells a person that something they wrote was acted on. Ids and codes only. */
export async function notifyActionTarget(
  q: Queryable,
  userId: string | null,
  actionId: string,
  action: ModAction,
  targetType?: string,
  targetId?: string,
): Promise<void> {
  if (!userId) return;
  await notify(q, userId, 'moderation_action', {
    actionId,
    action,
    ...(targetType ? { targetType } : {}),
    ...(targetId ? { targetId } : {}),
  });
}
