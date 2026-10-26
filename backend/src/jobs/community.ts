import type { Db } from '../db.js';
import { liftExpiredSuspension } from '../guards.js';
import { notify } from '../notify.js';

/**
 * Scheduled community work. Idempotent: running it twice sends nothing twice.
 * Runs every ten minutes inside the service (one instance) and from tests.
 */
export interface CommunityJobResult {
  reminders: number;
  suspensionsLifted: number;
}

const HOUR = 3_600_000;
const DAY = 86_400_000;

/** A reminder 24 hours before and again 2 hours before, once each. */
export async function sendMeetupReminders(db: Db, now: Date): Promise<number> {
  const due = await db.query<{
    meetup_id: string;
    profile_id: string;
    user_id: string;
    starts_at: Date;
    r24: Date | null;
    r2: Date | null;
  }>(
    `select r.meetup_id, r.profile_id, p.user_id, m.starts_at, r.reminded_24h_at as r24, r.reminded_2h_at as r2
       from meetup_rsvps r
       join meetups m on m.id = r.meetup_id
       join profiles p on p.id = r.profile_id
      where r.status = 'going' and p.kind = 'adult' and p.user_id is not null
        and m.status = 'published' and m.starts_at > $1 and m.starts_at <= $2`,
    [now, new Date(now.getTime() + 24 * HOUR)],
  );
  let sent = 0;
  for (const d of due.rows) {
    const remaining = new Date(d.starts_at).getTime() - now.getTime();
    const window = remaining <= 2 * HOUR ? '2h' : '24h';
    if (window === '2h' ? d.r2 !== null : d.r24 !== null) continue;
    const ok = await db.tx(async (q) => {
      const u = await q.query(
        window === '2h'
          ? `update meetup_rsvps set reminded_2h_at = $3, reminded_24h_at = coalesce(reminded_24h_at, $3)
              where meetup_id = $1 and profile_id = $2 and reminded_2h_at is null and status = 'going'`
          : `update meetup_rsvps set reminded_24h_at = $3
              where meetup_id = $1 and profile_id = $2 and reminded_24h_at is null and status = 'going'`,
        [d.meetup_id, d.profile_id, now],
      );
      if (u.rowCount === 0) return false;
      await notify(q, d.user_id, 'meetup_reminder', { meetupId: d.meetup_id, window });
      return true;
    });
    if (ok) sent += 1;
  }
  return sent;
}

/** Puts back accounts whose timed suspension has ended. */
export async function liftEndedSuspensions(db: Db, now: Date): Promise<number> {
  const r = await db.query<{ user_id: string }>(
    `select distinct s.user_id from sanctions s join users u on u.id = s.user_id
      where s.kind = 'suspend' and s.lifted_at is null and s.ends_at is not null and s.ends_at <= $1
        and u.status = 'suspended'`,
    [now],
  );
  let n = 0;
  for (const u of r.rows) if (await liftExpiredSuspension(db, u.user_id, now)) n += 1;
  return n;
}

export async function runCommunityJobs(db: Db, now: Date): Promise<CommunityJobResult> {
  return {
    reminders: await sendMeetupReminders(db, now),
    suspensionsLifted: await liftEndedSuspensions(db, now),
  };
}

export interface CommunityRetentionResult {
  removedBodies: number;
  strikes: number;
  sanctions: number;
  meetups: number;
  reports: number;
}

/** Keeps moderation data only as long as it is needed (plan, section 9). */
export async function runCommunityRetention(db: Db, now: Date): Promise<CommunityRetentionResult> {
  const ago = (days: number) => new Date(now.getTime() - days * DAY);
  const n = async (sql: string, p: unknown[]) => (await db.query(sql, p)).rowCount;
  return {
    // The words of a post a moderator removed are wiped 60 days after the
    // removal unless an appeal about it is still open.
    removedBodies: await n(
      `update forum_posts fp set body = '[removed]'
        where fp.status = 'removed' and fp.body not in ('[removed]', '[removed by author]')
          and exists (select 1 from moderation_actions m
                       where m.target_type = 'post' and m.target_id = fp.id and m.action = 'remove' and m.created_at < $1)
          and not exists (select 1 from appeals ap join moderation_actions m on m.id = ap.action_id
                           where m.target_type = 'post' and m.target_id = fp.id and ap.status = 'open')`,
      [ago(60)],
    ),
    strikes: await n('delete from strikes where expires_at < $1', [ago(180)]),
    sanctions: await n(
      `delete from sanctions where kind <> 'ban' and coalesce(lifted_at, ends_at) is not null and coalesce(lifted_at, ends_at) < $1`,
      [ago(180)],
    ),
    // Meet-ups end; their sign-up lists go 90 days later.
    meetups: await n(
      `delete from meetups m where coalesce(m.ends_at, m.starts_at) < $1
          and not exists (select 1 from reports r where r.target_type = 'meetup' and r.target_id = m.id and r.status in ('open', 'triaged'))`,
      [ago(90)],
    ),
    reports: await n(`delete from reports where status in ('actioned', 'dismissed') and handled_at < $1`, [ago(365)]),
  };
}
