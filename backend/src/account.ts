import { audit } from './context.js';
import { notify } from './notify.js';
import type { Queryable } from './db.js';

export type ContentChoice = 'keep_anonymous' | 'remove';

/**
 * Erases a person from the service. Everything personal goes now; the only
 * things that remain are:
 *  - the user row as an empty tombstone (id, role, timestamps);
 *  - the profile row as "Deleted member", so threads that others replied to
 *    still read (unless the person chose to remove their posts);
 *  - for an account banned at the time, the keyed e-mail hash, so the ban
 *    cannot be dodged by signing up again;
 *  - audit-log rows, which hold ids only.
 */
export async function eraseAccount(
  q: Queryable,
  userId: string,
  now: Date,
  content: ContentChoice,
): Promise<void> {
  const own = await q.query<{ id: string }>('select id from profiles where user_id = $1', [userId]);
  const ownIds = own.rows.map((r) => r.id);

  // Children managed by this account: removed entirely (cascades their
  // friendships, links and invites).
  await q.query('delete from profiles where managed_by = $1', [userId]);

  for (const pid of ownIds) {
    await q.query('delete from friendships where profile_lo = $1 or profile_hi = $1', [pid]);
    await q.query('delete from blocks where blocker_profile = $1 or blocked_profile = $1', [pid]);
    await q.query('delete from meetup_rsvps where profile_id = $1', [pid]);
    await q.query('delete from invite_redemptions where profile_id = $1', [pid]);
    await q.query('delete from user_hidden where profile_id = $1', [pid]);
    await q.query('delete from forum_reactions where profile_id = $1', [pid]);
    // Reports this person filed stay for the moderators, with no author.
    await q.query('update reports set reporter_profile_id = null where reporter_profile_id = $1', [pid]);
    // Future meet-ups this person organised are cancelled and their attendees told.
    const mine = await q.query<{ id: string }>(
      `select id from meetups where organiser_profile_id = $1 and status in ('published', 'pending_review') and starts_at > $2`,
      [pid, now],
    );
    for (const m of mine.rows) {
      await q.query(
        `update meetups set status = 'cancelled', cancel_reason = 'organiser_unavailable', cancelled_at = $2 where id = $1`,
        [m.id, now],
      );
      const att = await q.query<{ user_id: string }>(
        `select distinct p.user_id from meetup_rsvps r join profiles p on p.id = r.profile_id
          where r.meetup_id = $1 and r.status in ('going', 'waitlist') and p.kind = 'adult' and p.user_id is not null
            and p.user_id <> $2`,
        [m.id, userId],
      );
      for (const a of att.rows) await notify(q, a.user_id, 'meetup_cancelled', { meetupId: m.id, reason: 'organiser_unavailable' });
    }
    if (content === 'remove') {
      await q.query(
        `update forum_posts set status = 'removed', body = '[removed]', edited_at = $2
          where author_profile_id = $1`,
        [pid, now],
      );
      await q.query(
        `update forum_threads set status = 'removed' where author_profile_id = $1`,
        [pid],
      );
    }
    await q.query(
      `update profiles set display_name = 'Deleted member', handle = null, bio = null,
              avatar_key = null, visibility = 'private', erased_at = $2, updated_at = $2
        where id = $1`,
      [pid, now],
    );
  }

  await q.query('delete from invites where created_by_user = $1', [userId]);
  await q.query('delete from sessions where user_id = $1', [userId]);
  await q.query('delete from notifications where user_id = $1', [userId]);
  await q.query('delete from push_subscriptions where user_id = $1', [userId]);
  await q.query('delete from consents where user_id = $1', [userId]);
  await q.query('delete from credentials where user_id = $1', [userId]);
  await q.query('delete from appeals where user_id = $1', [userId]);
  await q.query('delete from parental_links where guardian_user_id = $1', [userId]);
  await q.query(
    `delete from auth_codes where email_hash = (select email_hash from users where id = $1)`,
    [userId],
  );

  const u = await q.query<{ status: string }>('select status from users where id = $1', [userId]);
  const wasBanned = u.rows[0]?.status === 'banned';
  // A banned account keeps its sanction and strikes (to stop ban evasion);
  // anyone else's moderation history goes with them.
  if (!wasBanned) {
    await q.query('delete from strikes where user_id = $1', [userId]);
    await q.query('delete from sanctions where user_id = $1', [userId]);
  }
  await q.query(
    `update users set email = null, firebase_uid = null,
            email_hash = case when $2 then email_hash else null end,
            status = case when $2 then status else 'deleted' end,
            role = case when $2 then role else 'member' end,
            deleted_at = $3, last_login_at = null, locale = null, adult_attested_at = null
      where id = $1`,
    [userId, wasBanned, now],
  );
  await audit(q, { actorUserId: userId, action: 'account.erased', meta: { content } });
}
