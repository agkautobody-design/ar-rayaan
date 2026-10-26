import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { contentOwner, notifyAdmins, type ContentType } from './community.js';
import type { Deps } from './context.js';
import { conflict, notFound, unauthorized, forbidden } from './errors.js';
import { limit, requireAuth } from './guards.js';
import { hideContent, notifyActionTarget, recordAction } from './modcore.js';
import { AUTO_HIDE_REPORTERS, REPORT_PRIORITY, REPORT_REASONS } from './policy/moderation.js';
import { ownAdultProfile } from './profiles.js';
import { parse, UUID_RE } from './validate.js';

/**
 * Reports and personal "hide". Hide first, judge second: enough independent
 * reports (or one child-safety report) hide the content until a person reads
 * it. The reporter is never revealed to the person reported, or in the API at
 * all: the moderator queue shows reasons and counts only.
 */

const reportBody = z.object({
  targetType: z.enum(['post', 'thread', 'profile', 'meetup']),
  targetId: z.string().regex(/^[0-9a-f-]{36}$/),
  reason: z.enum(REPORT_REASONS),
  details: z.string().trim().max(1000).optional(),
});

const hideBody = z.object({
  targetType: z.enum(['post', 'thread', 'meetup']),
  targetId: z.string().regex(/^[0-9a-f-]{36}$/),
});

export async function registerReportRoutes(app: FastifyInstance, deps: Deps): Promise<void> {
  const { db } = deps;
  const auth = requireAuth(deps);

  app.post(
    '/v1/reports',
    { preHandler: [auth, limit(deps, { name: 'report', max: 20, windowSec: 86_400, by: 'user' })] },
    async (request, reply) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      const body = parse(reportBody, request.body);
      const me = await ownAdultProfile(db, a.userId);
      if (!me || me.erased_at !== null) throw forbidden('profile_required', 'Create your profile first.');
      const now = deps.now();
      const out = await db.tx(async (q) => {
        // Resolve the target and its owner. Anything that does not exist, or
        // cannot be seen by anyone, is "not found".
        let ownerUser: string | null = null;
        let ownerProfile: string;
        if (body.targetType === 'profile') {
          const p = await q.query<{ id: string; user_id: string | null; kind: string; erased_at: Date | null }>(
            'select id, user_id, kind, erased_at from profiles where id = $1',
            [body.targetId],
          );
          const t = p.rows[0];
          if (!t || t.erased_at !== null || t.kind !== 'adult') throw notFound();
          ownerProfile = t.id;
          ownerUser = t.user_id;
        } else {
          const t = await contentOwner(q, body.targetType, body.targetId);
          if (!t || t.status === 'removed') throw notFound();
          ownerProfile = t.authorProfileId;
          ownerUser = t.authorUserId;
        }
        if (ownerProfile === me.id) throw conflict('own_content', 'You cannot report your own content.');

        const priority = REPORT_PRIORITY[body.reason];
        const ins = await q.query<{ id: string }>(
          `insert into reports (reporter_profile_id, target_type, target_id, reason, details, priority, created_at)
           values ($1, $2, $3, $4, $5, $6, $7)
           on conflict (reporter_profile_id, target_type, target_id)
             where status in ('open', 'triaged') and reporter_profile_id is not null
           do nothing returning id`,
          [me.id, body.targetType, body.targetId, body.reason, body.details ?? null, priority, now],
        );
        const reportId = ins.rows[0]?.id;
        if (!reportId) return { duplicate: true, hidden: false, id: null as string | null };

        let hidden = false;
        if (body.targetType !== 'profile') {
          const distinct = await q.query<{ n: string }>(
            `select count(distinct reporter_profile_id)::text as n from reports
              where target_type = $1 and target_id = $2 and status in ('open', 'triaged')
                and reporter_profile_id is not null`,
            [body.targetType, body.targetId],
          );
          const n = Number(distinct.rows[0]?.n ?? '0');
          if (body.reason === 'child_safety' || n >= AUTO_HIDE_REPORTERS) {
            const type: ContentType = body.targetType;
            hidden = await hideContent(q, type, body.targetId, now);
            if (hidden) {
              const actionId = await recordAction(q, {
                moderatorUserId: null,
                targetUserId: ownerUser,
                targetType: type,
                targetId: body.targetId,
                action: 'hide',
                reason: 'Hidden automatically while reports are reviewed by a person.',
                reportId,
                now,
              });
              await notifyActionTarget(q, ownerUser, actionId, 'hide', type, body.targetId);
            }
          }
        }
        if (body.reason === 'child_safety') {
          await notifyAdmins(q, 'report_child_safety', { reportId, targetType: body.targetType, targetId: body.targetId });
        }
        return { duplicate: false, hidden, id: reportId };
      });
      void reply.code(out.duplicate ? 200 : 201);
      return { report: { id: out.id, status: 'received' }, duplicate: out.duplicate, hidden: out.hidden };
    },
  );

  // ------------------------------------------------------ personal hide
  app.post(
    '/v1/hidden',
    { preHandler: [auth, limit(deps, { name: 'hide', max: 200, windowSec: 3600, by: 'user' })] },
    async (request, reply) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      const body = parse(hideBody, request.body);
      const me = await ownAdultProfile(db, a.userId);
      if (!me) throw forbidden('profile_required', 'Create your profile first.');
      const t = await contentOwner(db, body.targetType, body.targetId);
      if (!t) throw notFound();
      await db.query(
        `insert into user_hidden (profile_id, target_type, target_id, created_at) values ($1, $2, $3, $4)
         on conflict do nothing`,
        [me.id, body.targetType, body.targetId, deps.now()],
      );
      void reply.code(204);
    },
  );

  app.delete<{ Params: { targetType: string; targetId: string } }>(
    '/v1/hidden/:targetType/:targetId',
    { preHandler: [auth] },
    async (request, reply) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      const { targetType, targetId } = request.params;
      if (!['post', 'thread', 'meetup'].includes(targetType) || !UUID_RE.test(targetId)) throw notFound();
      const me = await ownAdultProfile(db, a.userId);
      if (!me) throw notFound();
      await db.query('delete from user_hidden where profile_id = $1 and target_type = $2 and target_id = $3', [
        me.id,
        targetType,
        targetId,
      ]);
      void reply.code(204);
    },
  );
}
