import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { contentOwner, recountThread, type ContentType } from './community.js';
import { audit, type Deps } from './context.js';
import type { Queryable } from './db.js';
import { conflict, forbidden, notFound, unauthorized, unprocessable } from './errors.js';
import { notifyThreadAuthor } from './forums.js';
import { limit, requireAuth, requireRole } from './guards.js';
import {
  addSanction, applyStrike, liftSanctions, notifyActionTarget, recordAction, setStatus, LIVE_STATUS,
  type ModAction,
} from './modcore.js';
import { notify } from './notify.js';
import { validateFilterPattern } from './policy/content.js';
import {
  APPEAL_WINDOW_DAYS, DEFAULT_STRIKES, MAX_MUTE_DAYS_ADMIN, MAX_MUTE_DAYS_MODERATOR, MAX_STRIKE_ADMIN,
  MAX_STRIKE_MODERATOR, MAX_SUSPEND_DAYS, STRIKE_LADDER,
} from './policy/moderation.js';
import { ownAdultProfile, toIso } from './profiles.js';
import { parse, UUID_RE } from './validate.js';

/**
 * The moderator console API: queue, actions with reasons, review of held
 * content, strikes, appeals, credentials, filters and the audit log. Every
 * change writes a moderation action (a reason the person can read) and an
 * audit line (ids only). See docs/product/moderation_handbook.md.
 */

const uuid = z.string().regex(/^[0-9a-f-]{36}$/);
const reason = z.string().trim().min(3).max(500);

const actionBody = z.object({
  action: z.enum(['hide', 'restore', 'remove', 'lock_thread', 'unlock_thread', 'warn', 'mute', 'suspend', 'ban', 'unban']),
  targetType: z.enum(['post', 'thread', 'meetup']).optional(),
  targetId: uuid.optional(),
  userId: uuid.optional(),
  reason,
  reportId: uuid.optional(),
  strikePoints: z.number().int().min(0).max(10).optional(),
  durationDays: z.number().int().min(1).max(MAX_SUSPEND_DAYS).optional(),
  indefinite: z.boolean().optional(),
});

const dismissBody = z.object({
  targetType: z.enum(['post', 'thread', 'meetup', 'profile', 'room']),
  targetId: uuid,
  note: z.string().trim().max(500).optional(),
});

const rejectBody = z.object({ reason, strikePoints: z.number().int().min(0).max(10).optional() });
const appealBody = z.object({ actionId: uuid, statement: z.string().trim().min(1).max(2000) });
const decideBody = z.object({
  decision: z.enum(['upheld', 'reduced', 'denied']),
  note: z.string().trim().min(3).max(1000),
});
const credentialBody = z.object({
  kind: z.enum(['scholar', 'organiser', 'trusted_moderator']),
  orgName: z.string().trim().min(2).max(120),
  evidenceNote: z.string().trim().min(3).max(1000),
});
const verifyBody = z.object({
  expiresInDays: z.number().int().min(1).max(730).default(365),
  note: z.string().trim().max(500).optional(),
});
const revokeBody = z.object({ reason });
const filterBody = z.object({
  kind: z.enum(['block_word', 'review_word', 'block_link', 'allow_domain']),
  pattern: z.string().trim().min(1).max(200),
  note: z.string().trim().max(200).optional(),
});
const listLimit = z.object({ limit: z.coerce.number().int().min(1).max(200).default(50) });
const auditQuery = z.object({
  limit: z.coerce.number().int().min(1).max(200).default(100),
  before: z.string().regex(/^\d{1,18}$/).optional(),
  action: z.string().max(60).optional(),
});

interface Preview {
  type: string;
  status: string | null;
  title?: string | null;
  body?: string | null;
  authorName?: string | null;
  authorProfileId?: string | null;
  category?: string | null;
  threadId?: string | null;
}

/** A short, moderator-only view of what was reported or is waiting. */
async function describeTarget(q: Queryable, type: string, id: string): Promise<Preview | null> {
  if (type === 'post') {
    const r = await q.query<{ status: string; body: string; name: string; pid: string; title: string; tid: string; slug: string }>(
      `select fp.status, fp.body, pr.display_name as name, pr.id as pid, t.title, t.id as tid, c.slug
         from forum_posts fp join profiles pr on pr.id = fp.author_profile_id
         join forum_threads t on t.id = fp.thread_id join forum_categories c on c.id = t.category_id
        where fp.id = $1`,
      [id],
    );
    const p = r.rows[0];
    return p ? { type, status: p.status, title: p.title, body: p.body.slice(0, 600), authorName: p.name, authorProfileId: p.pid, category: p.slug, threadId: p.tid } : null;
  }
  if (type === 'thread') {
    const r = await q.query<{ status: string; title: string; name: string; pid: string; slug: string; body: string | null }>(
      `select t.status, t.title, pr.display_name as name, pr.id as pid, c.slug,
              (select f.body from forum_posts f where f.thread_id = t.id order by f.created_at, f.id limit 1) as body
         from forum_threads t join profiles pr on pr.id = t.author_profile_id
         join forum_categories c on c.id = t.category_id where t.id = $1`,
      [id],
    );
    const t = r.rows[0];
    return t ? { type, status: t.status, title: t.title, body: t.body?.slice(0, 600) ?? null, authorName: t.name, authorProfileId: t.pid, category: t.slug } : null;
  }
  if (type === 'meetup') {
    const r = await q.query<{ status: string; title: string; description: string; venue_name: string; venue_kind: string; city: string; name: string; pid: string }>(
      `select m.status, m.title, m.description, m.venue_name, m.venue_kind, m.city, pr.display_name as name, pr.id as pid
         from meetups m join profiles pr on pr.id = m.organiser_profile_id where m.id = $1`,
      [id],
    );
    const m = r.rows[0];
    return m ? { type, status: m.status, title: m.title, body: `${m.venue_kind}: ${m.venue_name}, ${m.city}. ${m.description}`.slice(0, 600), authorName: m.name, authorProfileId: m.pid } : null;
  }
  if (type === 'profile') {
    const r = await q.query<{ display_name: string; bio: string | null; handle: string | null }>(
      'select display_name, bio, handle from profiles where id = $1',
      [id],
    );
    const p = r.rows[0];
    return p ? { type, status: null, title: p.display_name, body: p.bio, authorName: p.display_name, authorProfileId: id } : null;
  }
  return null;
}

function roleCap(role: string, moderator: number, admin: number): number {
  return role === 'admin' ? admin : moderator;
}

export async function registerModerationRoutes(app: FastifyInstance, deps: Deps): Promise<void> {
  const { db } = deps;
  const auth = requireAuth(deps);
  const restrictedOk = requireAuth(deps, { allowRestricted: true });
  const staff = requireRole('moderator', 'admin');
  const adminOnly = requireRole('admin');

  // ---------------------------------------------------------------- queue
  app.get('/v1/mod/queue', { preHandler: [auth, staff] }, async (request) => {
    const { limit: lim } = parse(listLimit, request.query);
    const groups = await db.query<{
      target_type: string; target_id: string; priority: number; report_count: number;
      reasons: string[]; first_at: Date; auto_count: number;
    }>(
      `select target_type, target_id, max(priority)::int as priority, count(*)::int as report_count,
              array_agg(distinct reason) as reasons, min(created_at) as first_at,
              (count(*) filter (where auto))::int as auto_count
         from reports where status in ('open', 'triaged')
        group by target_type, target_id
        order by max(priority) desc, min(created_at) asc
        limit $1`,
      [lim],
    );
    const reports = [];
    for (const g of groups.rows) {
      reports.push({
        targetType: g.target_type,
        targetId: g.target_id,
        priority: g.priority,
        reportCount: g.report_count,
        autoFlagged: g.auto_count > 0,
        reasons: [...g.reasons].sort(),
        firstReportedAt: toIso(g.first_at),
        target: await describeTarget(db, g.target_type, g.target_id),
      });
    }
    const pending: Array<Record<string, unknown>> = [];
    const threads = await db.query<{ id: string; created_at: Date }>(
      `select id, created_at from forum_threads where status = 'pending_review' order by created_at limit $1`,
      [lim],
    );
    for (const t of threads.rows) {
      pending.push({ type: 'thread', id: t.id, createdAt: toIso(t.created_at), target: await describeTarget(db, 'thread', t.id) });
    }
    const posts = await db.query<{ id: string; created_at: Date }>(
      `select fp.id, fp.created_at from forum_posts fp join forum_threads t on t.id = fp.thread_id
        where fp.status = 'pending_review' and t.status <> 'pending_review' order by fp.created_at limit $1`,
      [lim],
    );
    for (const p of posts.rows) {
      pending.push({ type: 'post', id: p.id, createdAt: toIso(p.created_at), target: await describeTarget(db, 'post', p.id) });
    }
    const meetups = await db.query<{ id: string; created_at: Date }>(
      `select id, created_at from meetups where status = 'pending_review' order by created_at limit $1`,
      [lim],
    );
    for (const m of meetups.rows) {
      pending.push({ type: 'meetup', id: m.id, createdAt: toIso(m.created_at), target: await describeTarget(db, 'meetup', m.id) });
    }
    pending.sort((x, y) => String(x.createdAt).localeCompare(String(y.createdAt)));
    return { reports, pending };
  });

  // -------------------------------------------------------------- actions
  app.post(
    '/v1/mod/actions',
    { preHandler: [auth, staff, limit(deps, { name: 'mod_action', max: 300, windowSec: 3600, by: 'user' })] },
    async (request, reply) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      const b = parse(actionBody, request.body);
      const now = deps.now();
      const isAdmin = a.role === 'admin';
      const id = await db.tx(async (q) => {
        const contentActions: ModAction[] = ['hide', 'restore', 'remove', 'lock_thread', 'unlock_thread'];
        let targetUser: string | null = b.userId ?? null;
        let owner: Awaited<ReturnType<typeof contentOwner>>;
        if (b.targetType && b.targetId) {
          owner = await contentOwner(q, b.targetType, b.targetId, true);
          if (!owner) throw notFound();
          targetUser = owner.authorUserId;
        } else if (contentActions.includes(b.action)) {
          throw unprocessable('target_required', 'Say which post, thread or meet-up.');
        }
        if (targetUser === null) throw unprocessable('target_required', 'Say which person.');
        if (targetUser === a.userId) throw conflict('own_content', 'Another moderator must act on your own content or account.');
        const tu = await q.query<{ role: string; status: string }>('select role, status from users where id = $1', [targetUser]);
        const targetRole = tu.rows[0]?.role ?? 'member';
        if (!tu.rows[0]) throw notFound();
        if (targetRole !== 'member' && !isAdmin) throw forbidden('forbidden', 'Only an admin can act on staff.');

        const cap = roleCap(a.role, MAX_STRIKE_MODERATOR, MAX_STRIKE_ADMIN);
        const strikes = Math.min(b.strikePoints ?? DEFAULT_STRIKES[b.action] ?? 0, cap);
        let endsAt: Date | null = null;
        let sanction: 'mute' | 'suspend' | 'ban' | null = null;

        switch (b.action) {
          case 'hide':
          case 'remove':
          case 'restore':
          case 'lock_thread':
          case 'unlock_thread': {
            if (!owner || !b.targetType) throw unprocessable('target_required', 'Say which post, thread or meet-up.');
            const type: ContentType = b.targetType;
            if ((b.action === 'lock_thread' || b.action === 'unlock_thread') && type !== 'thread') {
              throw unprocessable('wrong_target', 'Only a thread can be locked.');
            }
            const st = owner.status;
            if (b.action === 'hide' && !['visible', 'open', 'locked', 'published'].includes(st)) throw conflict('invalid_state', 'That is not showing.');
            if (b.action === 'remove' && st === 'removed') throw conflict('invalid_state', 'Already removed.');
            if (b.action === 'restore' && !['hidden', 'removed'].includes(st)) throw conflict('invalid_state', 'That is not hidden.');
            if (b.action === 'lock_thread' && st !== 'open') throw conflict('invalid_state', 'Only an open thread can be locked.');
            if (b.action === 'unlock_thread' && st !== 'locked') throw conflict('invalid_state', 'That thread is not locked.');
            const next =
              b.action === 'hide' ? 'hidden'
              : b.action === 'remove' ? 'removed'
              : b.action === 'lock_thread' ? 'locked'
              : LIVE_STATUS[type];
            await setStatus(q, type, owner.id, next, now);
            break;
          }
          case 'warn':
            break;
          case 'mute': {
            const days = b.durationDays ?? 7;
            if (days > roleCap(a.role, MAX_MUTE_DAYS_MODERATOR, MAX_MUTE_DAYS_ADMIN)) {
              throw forbidden('forbidden', 'That is longer than you can set.');
            }
            endsAt = new Date(now.getTime() + days * 86_400_000);
            sanction = 'mute';
            break;
          }
          case 'suspend':
            if (!isAdmin) throw forbidden('forbidden', 'Only an admin can suspend an account.');
            if (!b.indefinite && !b.durationDays) throw unprocessable('duration_required', 'Say for how many days, or indefinite.');
            endsAt = b.indefinite ? null : new Date(now.getTime() + (b.durationDays ?? 1) * 86_400_000);
            sanction = 'suspend';
            break;
          case 'ban':
            if (!isAdmin) throw forbidden('forbidden', 'Only an admin can ban an account.');
            sanction = 'ban';
            break;
          case 'unban': {
            if (!isAdmin) throw forbidden('forbidden', 'Only an admin can lift a ban.');
            break;
          }
        }

        const actionId = await recordAction(q, {
          moderatorUserId: a.userId,
          moderatorRole: a.role,
          targetUserId: targetUser,
          targetType: b.targetType,
          targetId: b.targetId,
          action: b.action,
          reason: b.reason,
          reportId: b.reportId ?? null,
          expiresAt: endsAt,
          now,
        });
        if (b.action === 'unban') {
          await liftSanctions(q, targetUser, ['mute', 'suspend', 'ban'], now);
        }
        if (sanction) await addSanction(q, { userId: targetUser, kind: sanction, endsAt, actionId, now });
        if (strikes > 0 && ['warn', 'remove', 'hide', 'mute', 'suspend', 'ban'].includes(b.action)) {
          await applyStrike(q, targetUser, strikes, actionId, now);
        }
        // Reports on this target are settled by the action.
        if (b.targetType && b.targetId && ['hide', 'remove', 'restore'].includes(b.action)) {
          await q.query(
            `update reports set status = $3, handled_by = $4, handled_at = $5, resolution = $6
              where target_type = $1 and target_id = $2 and status in ('open', 'triaged')`,
            [b.targetType, b.targetId, b.action === 'restore' ? 'dismissed' : 'actioned', a.userId, now, b.action],
          );
        }
        if (b.action !== 'restore' && b.action !== 'unban') {
          await notifyActionTarget(q, targetUser, actionId, b.action, b.targetType, b.targetId);
        }
        return actionId;
      });
      void reply.code(201);
      return { action: { id } };
    },
  );

  app.post(
    '/v1/mod/queue/dismiss',
    { preHandler: [auth, staff] },
    async (request, reply) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      const b = parse(dismissBody, request.body);
      const now = deps.now();
      await db.tx(async (q) => {
        const r = await q.query(
          `update reports set status = 'dismissed', handled_by = $3, handled_at = $4, resolution = $5
            where target_type = $1 and target_id = $2 and status in ('open', 'triaged')`,
          [b.targetType, b.targetId, a.userId, now, b.note ?? 'dismissed'],
        );
        if (r.rowCount === 0) throw notFound();
        // If the only thing that hid it was an automatic hide from these
        // reports, and a person found them unfounded, put it back.
        if (b.targetType === 'post' || b.targetType === 'thread' || b.targetType === 'meetup') {
          const type: ContentType = b.targetType;
          const o = await contentOwner(q, type, b.targetId, true);
          if (o && o.status === 'hidden') {
            const last = await q.query<{ moderator_user_id: string | null; action: string }>(
              `select moderator_user_id, action from moderation_actions
                where target_type = $1 and target_id = $2 order by created_at desc, id desc limit 1`,
              [type, b.targetId],
            );
            const l = last.rows[0];
            if (l && l.moderator_user_id === null && l.action === 'hide') {
              await setStatus(q, type, b.targetId, LIVE_STATUS[type], now);
              await recordAction(q, {
                moderatorUserId: a.userId, moderatorRole: a.role, targetUserId: o.authorUserId,
                targetType: type, targetId: b.targetId, action: 'restore',
                reason: 'Reports were reviewed and dismissed.', now,
              });
            }
          }
        }
        await audit(q, { actorUserId: a.userId, actorRole: a.role, action: 'mod.dismiss', targetType: b.targetType, targetId: b.targetId });
      });
      void reply.code(204);
    },
  );

  // --------------------------------------------------------------- review
  const review = (approve: boolean) =>
    async (
      request: { auth?: { userId: string; role: 'member' | 'moderator' | 'admin' }; params: { type: string; id: string }; body?: unknown },
      reply: { code: (n: number) => unknown },
    ) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      const { type, id } = request.params;
      if (!['thread', 'post', 'meetup'].includes(type) || !UUID_RE.test(id)) throw notFound();
      const ct = type as ContentType;
      const body = approve ? { reason: 'Approved after review.', strikePoints: 0 } : parse(rejectBody, request.body);
      const now = deps.now();
      await db.tx(async (q) => {
        const o = await contentOwner(q, ct, id, true);
        if (!o || o.status !== 'pending_review') throw notFound();
        if (o.authorUserId === a.userId) throw conflict('own_content', 'Another moderator must review your own content.');
        if (approve) {
          if (ct === 'thread') {
            await q.query(`update forum_threads set status = 'open' where id = $1`, [id]);
            await q.query(`update forum_posts set status = 'visible' where thread_id = $1 and status = 'pending_review'`, [id]);
            await recountThread(q, id);
          } else if (ct === 'post') {
            await q.query(`update forum_posts set status = 'visible' where id = $1`, [id]);
            const p = await q.query<{ thread_id: string; pid: string; author: string }>(
              `select fp.thread_id, fp.id as pid, t.author_profile_id as author
                 from forum_posts fp join forum_threads t on t.id = fp.thread_id where fp.id = $1`,
              [id],
            );
            const pr = p.rows[0];
            if (pr) {
              await recountThread(q, pr.thread_id);
              await notifyThreadAuthor(q, pr.thread_id, pr.author, o.authorProfileId, pr.pid);
            }
          } else {
            await q.query(
              `update meetups set status = 'published', published_at = coalesce(published_at, $2), reviewed_by = $3 where id = $1`,
              [id, now, a.userId],
            );
          }
          const actionId = await recordAction(q, {
            moderatorUserId: a.userId, moderatorRole: a.role, targetUserId: o.authorUserId,
            targetType: ct, targetId: id, action: 'restore', reason: body.reason, now,
          });
          if (o.authorUserId) await notify(q, o.authorUserId, ct === 'meetup' ? 'meetup_approved' : 'post_approved', { targetType: ct, targetId: id, actionId });
        } else {
          const cap = roleCap(a.role, MAX_STRIKE_MODERATOR, MAX_STRIKE_ADMIN);
          const pts = Math.min(body.strikePoints ?? 0, cap);
          if (ct === 'thread') {
            await q.query(`update forum_threads set status = 'removed' where id = $1`, [id]);
            await q.query(`update forum_posts set status = 'removed' where thread_id = $1 and status = 'pending_review'`, [id]);
          } else if (ct === 'post') {
            await q.query(`update forum_posts set status = 'removed' where id = $1`, [id]);
            const t = await q.query<{ thread_id: string }>('select thread_id from forum_posts where id = $1', [id]);
            if (t.rows[0]) await recountThread(q, t.rows[0].thread_id);
          } else {
            await q.query(`update meetups set status = 'hidden', reviewed_by = $2 where id = $1`, [id, a.userId]);
          }
          const actionId = await recordAction(q, {
            moderatorUserId: a.userId, moderatorRole: a.role, targetUserId: o.authorUserId,
            targetType: ct, targetId: id, action: 'remove', reason: body.reason, now,
          });
          if (pts > 0 && o.authorUserId) await applyStrike(q, o.authorUserId, pts, actionId, now);
          await notifyActionTarget(q, o.authorUserId, actionId, 'remove', ct, id);
        }
        await q.query(
          `update reports set status = 'actioned', handled_by = $3, handled_at = $4, resolution = $5
            where target_type = $1 and target_id = $2 and status in ('open', 'triaged')`,
          [ct, id, a.userId, now, approve ? 'approved' : 'rejected'],
        );
      });
      void reply.code(204);
    };
  app.post<{ Params: { type: string; id: string } }>('/v1/mod/review/:type/:id/approve', { preHandler: [auth, staff] }, review(true));
  app.post<{ Params: { type: string; id: string } }>('/v1/mod/review/:type/:id/reject', { preHandler: [auth, staff] }, review(false));

  // -------------------------------------------------------------- appeals
  app.get('/v1/me/moderation', { preHandler: [restrictedOk] }, async (request) => {
    const a = request.auth;
    if (!a) throw unauthorized();
    const now = deps.now();
    const actions = await db.query<{
      id: string; action: string; reason: string; target_type: string | null; created_at: Date;
      expires_at: Date | null; appeal_id: string | null; appeal_status: string | null; appeal_note: string | null;
    }>(
      `select m.id, m.action, m.reason, m.target_type, m.created_at, m.expires_at,
              ap.id as appeal_id, ap.status as appeal_status, ap.decision_note as appeal_note
         from moderation_actions m left join appeals ap on ap.action_id = m.id and ap.user_id = $1
        where m.target_user_id = $1 and m.action not in ('restore', 'unban', 'unlock_thread', 'verify_credential', 'revoke_credential')
        order by m.created_at desc, m.id limit 50`,
      [a.userId],
    );
    const pts = await db.query<{ n: string }>(
      'select coalesce(sum(points), 0)::text as n from strikes where user_id = $1 and expires_at > $2',
      [a.userId, now],
    );
    const sanctions = await db.query<{ kind: string; ends_at: Date | null }>(
      `select kind, ends_at from sanctions where user_id = $1 and lifted_at is null
          and (ends_at is null or ends_at > $2) order by starts_at desc`,
      [a.userId, now],
    );
    const accountStatus = await db.query<{ status: string }>('select status from users where id = $1', [a.userId]);
    return {
      accountStatus: accountStatus.rows[0]?.status ?? 'active',
      strikePoints: Number(pts.rows[0]?.n ?? '0'),
      ladder: STRIKE_LADDER.map((s) => ({ points: s.points, step: s.sanction, days: s.days })),
      sanctions: sanctions.rows.map((s) => ({ kind: s.kind, endsAt: s.ends_at ? toIso(s.ends_at) : null })),
      actions: actions.rows.map((m) => ({
        id: m.id,
        action: m.action,
        reason: m.reason,
        targetType: m.target_type,
        createdAt: toIso(m.created_at),
        appealable:
          m.appeal_id === null && now.getTime() - new Date(m.created_at).getTime() <= APPEAL_WINDOW_DAYS * 86_400_000,
        appeal: m.appeal_id ? { id: m.appeal_id, status: m.appeal_status, note: m.appeal_note } : null,
      })),
    };
  });

  app.post(
    '/v1/appeals',
    { preHandler: [restrictedOk, limit(deps, { name: 'appeal', max: 5, windowSec: 86_400, by: 'user' })] },
    async (request, reply) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      const b = parse(appealBody, request.body);
      const now = deps.now();
      const out = await db.tx(async (q) => {
        const r = await q.query<{ id: string; action: string; created_at: Date }>(
          `select id, action, created_at from moderation_actions where id = $1 and target_user_id = $2`,
          [b.actionId, a.userId],
        );
        const m = r.rows[0];
        if (!m || ['restore', 'unban', 'unlock_thread', 'verify_credential', 'revoke_credential'].includes(m.action)) throw notFound();
        if (now.getTime() - new Date(m.created_at).getTime() > APPEAL_WINDOW_DAYS * 86_400_000) {
          throw conflict('appeal_window_closed', `Appeals must be made within ${APPEAL_WINDOW_DAYS} days.`);
        }
        const ex = await q.query('select 1 from appeals where action_id = $1 and user_id = $2', [m.id, a.userId]);
        if (ex.rowCount > 0) throw conflict('already_appealed', 'You have already appealed this.');
        const ins = await q.query<{ id: string }>(
          `insert into appeals (action_id, user_id, statement, created_at) values ($1, $2, $3, $4) returning id`,
          [m.id, a.userId, b.statement, now],
        );
        await audit(q, { actorUserId: a.userId, action: 'appeal.created', targetType: 'moderation_action', targetId: m.id });
        return ins.rows[0]?.id ?? '';
      });
      void reply.code(201);
      return { appeal: { id: out, status: 'open' } };
    },
  );

  app.get('/v1/mod/appeals', { preHandler: [auth, staff] }, async (request) => {
    const { limit: lim } = parse(listLimit, request.query);
    const r = await db.query<{
      id: string; action_id: string; statement: string; created_at: Date; action: string; reason: string;
      target_type: string | null; target_id: string | null; moderator_user_id: string | null; display_name: string | null;
    }>(
      `select ap.id, ap.action_id, ap.statement, ap.created_at, m.action, m.reason, m.target_type, m.target_id,
              m.moderator_user_id, p.display_name
         from appeals ap join moderation_actions m on m.id = ap.action_id
         left join profiles p on p.user_id = ap.user_id and p.kind = 'adult'
        where ap.status = 'open' order by ap.created_at limit $1`,
      [lim],
    );
    const out = [];
    for (const x of r.rows) {
      out.push({
        id: x.id,
        statement: x.statement,
        createdAt: toIso(x.created_at),
        appellantName: x.display_name,
        action: { id: x.action_id, action: x.action, reason: x.reason, targetType: x.target_type, targetId: x.target_id, bySystem: x.moderator_user_id === null },
        target: x.target_type && x.target_id ? await describeTarget(db, x.target_type, x.target_id) : null,
      });
    }
    return { appeals: out };
  });

  app.post<{ Params: { id: string } }>(
    '/v1/mod/appeals/:id/decide',
    { preHandler: [auth, staff] },
    async (request, reply) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      if (!UUID_RE.test(request.params.id)) throw notFound();
      const b = parse(decideBody, request.body);
      const now = deps.now();
      await db.tx(async (q) => {
        const r = await q.query<{
          id: string; user_id: string; action_id: string; action: string; moderator_user_id: string | null;
          target_type: ContentType | null; target_id: string | null;
        }>(
          `select ap.id, ap.user_id, ap.action_id, m.action, m.moderator_user_id, m.target_type, m.target_id
             from appeals ap join moderation_actions m on m.id = ap.action_id
            where ap.id = $1 and ap.status = 'open' for update of ap`,
          [request.params.id],
        );
        const ap = r.rows[0];
        if (!ap) throw notFound();
        // A different person decides: not the moderator who acted, not the appellant.
        if (ap.moderator_user_id === a.userId || ap.user_id === a.userId) {
          throw conflict('different_moderator_required', 'A different moderator must decide this appeal.');
        }
        if (['suspend', 'ban'].includes(ap.action) && a.role !== 'admin') {
          throw forbidden('forbidden', 'Only an admin decides appeals about suspensions and bans.');
        }
        await q.query(
          `update appeals set status = $2, decided_by = $3, decided_at = $4, decision_note = $5 where id = $1`,
          [ap.id, b.decision, a.userId, now, b.note],
        );
        if (b.decision !== 'denied') {
          await liftSanctions(q, ap.user_id, ['mute', 'suspend', 'ban'], now, ap.action_id);
          await q.query('delete from strikes where action_id = $1', [ap.action_id]);
        }
        if (b.decision === 'upheld' && ap.target_type && ap.target_id && ['hide', 'remove'].includes(ap.action)) {
          const o = await contentOwner(q, ap.target_type, ap.target_id, true);
          if (o && ['hidden', 'removed'].includes(o.status)) {
            await setStatus(q, ap.target_type, ap.target_id, LIVE_STATUS[ap.target_type], now);
          }
        }
        if (b.decision === 'upheld' && ap.action === 'lock_thread' && ap.target_id) {
          await q.query(`update forum_threads set status = 'open' where id = $1 and status = 'locked'`, [ap.target_id]);
        }
        await audit(q, {
          actorUserId: a.userId, actorRole: a.role, action: 'appeal.decided',
          targetType: 'appeal', targetId: ap.id, meta: { decision: b.decision, actionId: ap.action_id },
        });
        await notify(q, ap.user_id, 'appeal_decided', { appealId: ap.id, decision: b.decision });
      });
      void reply.code(204);
    },
  );

  // ---------------------------------------------------------- credentials
  const CRED_STATE = `case when c.revoked_at is not null then 'revoked'
                           when c.verified_at is null then 'pending'
                           when c.expires_at is not null and c.expires_at <= $1 then 'expired'
                           else 'verified' end`;

  app.get('/v1/me/credentials', { preHandler: [auth] }, async (request) => {
    const a = request.auth;
    if (!a) throw unauthorized();
    const r = await db.query<{ id: string; kind: string; org_name: string | null; state: string; verified_at: Date | null; expires_at: Date | null; created_at: Date }>(
      `select c.id, c.kind, c.org_name, ${CRED_STATE} as state, c.verified_at, c.expires_at, c.created_at
         from credentials c where c.user_id = $2 order by c.created_at desc`,
      [deps.now(), a.userId],
    );
    return {
      credentials: r.rows.map((c) => ({
        id: c.id, kind: c.kind, orgName: c.org_name, state: c.state,
        verifiedAt: c.verified_at ? toIso(c.verified_at) : null,
        expiresAt: c.expires_at ? toIso(c.expires_at) : null,
        createdAt: toIso(c.created_at),
      })),
    };
  });

  app.post(
    '/v1/credentials',
    { preHandler: [auth, limit(deps, { name: 'credential_apply', max: 5, windowSec: 86_400, by: 'user' })] },
    async (request, reply) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      const b = parse(credentialBody, request.body);
      if (!(await ownAdultProfile(db, a.userId))) throw forbidden('profile_required', 'Create your profile first.');
      const now = deps.now();
      const id = await db.tx(async (q) => {
        const ex = await q.query(
          `select 1 from credentials c where c.user_id = $2 and c.kind = $3
              and (${CRED_STATE}) in ('pending', 'verified') limit 1`,
          [now, a.userId, b.kind],
        );
        if (ex.rowCount > 0) throw conflict('credential_exists', 'You already have this, or an application is waiting.');
        const ins = await q.query<{ id: string }>(
          `insert into credentials (user_id, kind, org_name, evidence_note, created_at) values ($1, $2, $3, $4, $5) returning id`,
          [a.userId, b.kind, b.orgName, b.evidenceNote, now],
        );
        await audit(q, { actorUserId: a.userId, action: 'credential.applied', targetType: 'credential', targetId: ins.rows[0]?.id, meta: { kind: b.kind } });
        return ins.rows[0]?.id ?? '';
      });
      void reply.code(201);
      return { credential: { id, kind: b.kind, state: 'pending' } };
    },
  );

  app.get('/v1/mod/credentials', { preHandler: [auth, staff] }, async (request) => {
    const { limit: lim } = parse(listLimit, request.query);
    const r = await db.query<{
      id: string; kind: string; org_name: string | null; evidence_note: string | null; state: string; created_at: Date; name: string | null; user_id: string;
    }>(
      `select c.id, c.kind, c.org_name, c.evidence_note, ${CRED_STATE} as state, c.created_at, c.user_id, p.display_name as name
         from credentials c left join profiles p on p.user_id = c.user_id and p.kind = 'adult'
        where c.verified_at is null and c.revoked_at is null
        order by c.created_at limit $2`,
      [deps.now(), lim],
    );
    return {
      credentials: r.rows.map((c) => ({
        id: c.id, kind: c.kind, orgName: c.org_name, evidenceNote: c.evidence_note, state: c.state,
        applicantName: c.name, createdAt: toIso(c.created_at),
      })),
    };
  });

  app.post<{ Params: { id: string } }>(
    '/v1/mod/credentials/:id/verify',
    { preHandler: [auth, adminOnly] },
    async (request, reply) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      if (!UUID_RE.test(request.params.id)) throw notFound();
      const b = parse(verifyBody, request.body);
      const now = deps.now();
      await db.tx(async (q) => {
        const r = await q.query<{ user_id: string; kind: string }>(
          `select user_id, kind from credentials where id = $1 and verified_at is null and revoked_at is null for update`,
          [request.params.id],
        );
        const c = r.rows[0];
        if (!c) throw notFound();
        if (c.user_id === a.userId) throw conflict('own_content', 'Another admin must verify your own application.');
        await q.query(`update credentials set verified_at = $2, verified_by = $3, expires_at = $4 where id = $1`, [
          request.params.id, now, a.userId, new Date(now.getTime() + b.expiresInDays * 86_400_000),
        ]);
        if (c.kind === 'trusted_moderator') {
          await q.query(`update users set role = 'moderator' where id = $1 and role = 'member'`, [c.user_id]);
        }
        const actionId = await recordAction(q, {
          moderatorUserId: a.userId, moderatorRole: a.role, targetUserId: c.user_id, targetType: 'credential',
          targetId: request.params.id, action: 'verify_credential', reason: b.note?.trim() || `Verified as ${c.kind}.`, now,
        });
        await notify(q, c.user_id, 'credential_verified', { credentialId: request.params.id, kind: c.kind, actionId });
      });
      void reply.code(204);
    },
  );

  app.post<{ Params: { id: string } }>(
    '/v1/mod/credentials/:id/revoke',
    { preHandler: [auth, adminOnly] },
    async (request, reply) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      if (!UUID_RE.test(request.params.id)) throw notFound();
      const b = parse(revokeBody, request.body);
      const now = deps.now();
      await db.tx(async (q) => {
        const r = await q.query<{ user_id: string; kind: string }>(
          `select user_id, kind from credentials where id = $1 and revoked_at is null for update`,
          [request.params.id],
        );
        const c = r.rows[0];
        if (!c) throw notFound();
        await q.query(`update credentials set revoked_at = $2 where id = $1`, [request.params.id, now]);
        if (c.kind === 'trusted_moderator') {
          await q.query(`update users set role = 'member' where id = $1 and role = 'moderator'`, [c.user_id]);
        }
        const actionId = await recordAction(q, {
          moderatorUserId: a.userId, moderatorRole: a.role, targetUserId: c.user_id, targetType: 'credential',
          targetId: request.params.id, action: 'revoke_credential', reason: b.reason, now,
        });
        await notify(q, c.user_id, 'credential_revoked', { credentialId: request.params.id, kind: c.kind, actionId });
      });
      void reply.code(204);
    },
  );

  // ----------------------------------------------------- filters and audit
  app.get('/v1/admin/filters', { preHandler: [auth, adminOnly] }, async () => {
    const r = await db.query<{ id: string; kind: string; pattern: string; note: string | null; active: boolean; created_at: Date }>(
      'select id, kind, pattern, note, active, created_at from content_filters order by created_at desc limit 500',
    );
    return {
      filters: r.rows.map((f) => ({ id: f.id, kind: f.kind, pattern: f.pattern, note: f.note, active: f.active, createdAt: toIso(f.created_at) })),
    };
  });

  app.post('/v1/admin/filters', { preHandler: [auth, adminOnly] }, async (request, reply) => {
    const a = request.auth;
    if (!a) throw unauthorized();
    const b = parse(filterBody, request.body);
    const problem = validateFilterPattern(b.kind, b.pattern);
    if (problem) throw unprocessable('pattern_invalid', problem);
    const id = await db.tx(async (q) => {
      const r = await q.query<{ id: string }>(
        `insert into content_filters (kind, pattern, note, created_by, created_at) values ($1, $2, $3, $4, $5) returning id`,
        [b.kind, b.pattern, b.note ?? null, a.userId, deps.now()],
      );
      await audit(q, { actorUserId: a.userId, actorRole: a.role, action: 'filter.added', targetType: 'content_filter', targetId: r.rows[0]?.id, meta: { kind: b.kind } });
      return r.rows[0]?.id ?? '';
    });
    void reply.code(201);
    return { filter: { id } };
  });

  app.delete<{ Params: { id: string } }>('/v1/admin/filters/:id', { preHandler: [auth, adminOnly] }, async (request, reply) => {
    const a = request.auth;
    if (!a) throw unauthorized();
    if (!UUID_RE.test(request.params.id)) throw notFound();
    await db.tx(async (q) => {
      const r = await q.query(`update content_filters set active = false where id = $1 and active`, [request.params.id]);
      if (r.rowCount === 0) throw notFound();
      await audit(q, { actorUserId: a.userId, actorRole: a.role, action: 'filter.removed', targetType: 'content_filter', targetId: request.params.id });
    });
    void reply.code(204);
  });

  app.get('/v1/admin/audit', { preHandler: [auth, adminOnly] }, async (request) => {
    const q = parse(auditQuery, request.query);
    const r = await db.query<{
      id: string; at: Date; actor_user_id: string | null; actor_role: string | null; action: string;
      target_type: string | null; target_id: string | null; meta: Record<string, unknown>;
    }>(
      `select id::text as id, at, actor_user_id, actor_role, action, target_type, target_id, meta
         from audit_log
        where ($1::bigint is null or id < $1::bigint) and ($2::text is null or action like $2::text || '%')
        order by id desc limit $3`,
      [q.before ?? null, q.action ?? null, q.limit],
    );
    return {
      entries: r.rows.map((e) => ({
        id: e.id, at: toIso(e.at), actorUserId: e.actor_user_id, actorRole: e.actor_role,
        action: e.action, targetType: e.target_type, targetId: e.target_id, meta: e.meta,
      })),
    };
  });
}
