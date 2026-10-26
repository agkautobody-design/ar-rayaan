import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { audit, type Deps } from './context.js';
import { notFound, conflict, unauthorized, unprocessable } from './errors.js';
import { limit, requireAuth } from './guards.js';
import { MAX_CHILD_PROFILES_PER_GUARDIAN } from './policy/age.js';
import { validateChildNickname } from './policy/names.js';
import { mapProfile, PROFILE_COLUMNS, type ProfileRow } from './profiles.js';
import { parse, UUID_RE } from './validate.js';
import { PARENT_CONSENT_VERSION } from './versions.js';

const createBody = z.object({
  nickname: z.string().trim().min(1).max(60),
  // We store a band, never a date of birth.
  ageBand: z.enum(['under13', 'teen13to17']),
  consent: z.object({
    version: z.string().max(40),
    isParentOrGuardian: z.literal(true),
  }),
});

const patchBody = z.object({ nickname: z.string().trim().min(1).max(60) });

/**
 * Child and teen profiles. They have no login, no handle, no bio, are never
 * public and never searchable; the guardian's account manages them.
 */
export async function registerGuardianRoutes(app: FastifyInstance, deps: Deps): Promise<void> {
  const { db } = deps;
  const auth = requireAuth(deps);

  app.post(
    '/v1/guardian/children',
    { preHandler: [auth, limit(deps, { name: 'child_create', max: 20, windowSec: 3600, by: 'user' })] },
    async (request, reply) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      const body = parse(createBody, request.body);
      if (body.consent.version !== PARENT_CONSENT_VERSION) {
        throw unprocessable('consent_outdated', 'Please read and accept the current parent consent.');
      }
      const nick = body.nickname.trim();
      const problem = validateChildNickname(nick);
      if (problem) throw unprocessable('nickname_invalid', problem);

      const child = await db.tx(async (q) => {
        const count = await q.query<{ n: string }>(
          'select count(*)::text as n from profiles where managed_by = $1',
          [a.userId],
        );
        if (Number(count.rows[0]?.n ?? '0') >= MAX_CHILD_PROFILES_PER_GUARDIAN) {
          throw conflict('child_limit_reached', 'You have reached the number of child profiles allowed.');
        }
        const kind = body.ageBand === 'under13' ? 'child' : 'teen';
        const ins = await q.query<ProfileRow>(
          `insert into profiles (kind, managed_by, display_name, visibility)
           values ($1, $2, $3, 'private') returning ${PROFILE_COLUMNS}`,
          [kind, a.userId, nick],
        );
        const row = ins.rows[0];
        if (!row) throw new Error('child insert returned no row');
        await q.query(
          `insert into parental_links (guardian_user_id, ward_profile_id, status, consent_version)
           values ($1, $2, 'active', $3)`,
          [a.userId, row.id, PARENT_CONSENT_VERSION],
        );
        await q.query(
          `insert into consents (user_id, kind, version, subject_profile_id)
           values ($1, 'parent_consent', $2, $3)`,
          [a.userId, PARENT_CONSENT_VERSION, row.id],
        );
        await audit(q, {
          actorUserId: a.userId,
          actorRole: a.role,
          action: 'guardian.child_added',
          targetType: 'profile',
          targetId: row.id,
          meta: { kind },
        });
        return row;
      });
      void reply.code(201);
      return { child: mapProfile(child) };
    },
  );

  app.get('/v1/guardian/children', { preHandler: [auth] }, async (request) => {
    const a = request.auth;
    if (!a) throw unauthorized();
    const r = await db.query<ProfileRow>(
      `select ${PROFILE_COLUMNS} from profiles where managed_by = $1 order by created_at`,
      [a.userId],
    );
    return { children: r.rows.map(mapProfile) };
  });

  app.patch<{ Params: { id: string } }>(
    '/v1/guardian/children/:id',
    { preHandler: [auth] },
    async (request) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      if (!UUID_RE.test(request.params.id)) throw notFound();
      const body = parse(patchBody, request.body);
      const nick = body.nickname.trim();
      const problem = validateChildNickname(nick);
      if (problem) throw unprocessable('nickname_invalid', problem);
      const r = await db.query<ProfileRow>(
        `update profiles set display_name = $3, updated_at = $4
          where id = $1 and managed_by = $2 returning ${PROFILE_COLUMNS}`,
        [request.params.id, a.userId, nick, deps.now()],
      );
      const row = r.rows[0];
      if (!row) throw notFound();
      return { child: mapProfile(row) };
    },
  );

  app.delete<{ Params: { id: string } }>(
    '/v1/guardian/children/:id',
    { preHandler: [auth] },
    async (request, reply) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      if (!UUID_RE.test(request.params.id)) throw notFound();
      await db.tx(async (q) => {
        const r = await q.query('delete from profiles where id = $1 and managed_by = $2', [
          request.params.id,
          a.userId,
        ]);
        if (r.rowCount === 0) throw notFound();
        await audit(q, {
          actorUserId: a.userId,
          actorRole: a.role,
          action: 'guardian.child_removed',
          targetType: 'profile',
          targetId: request.params.id,
        });
      });
      void reply.code(204);
    },
  );
}
