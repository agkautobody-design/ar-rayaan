import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { eraseAccount } from './account.js';
import type { Deps } from './context.js';
import { sqlState, UNIQUE_VIOLATION } from './db.js';
import { conflict, notFound, unauthorized, unprocessable } from './errors.js';
import { limit, requireAuth } from './guards.js';
import { validateDisplayName, validateHandle } from './policy/names.js';
import { mapProfile, ownAdultProfile, PROFILE_COLUMNS, toIso, type ProfileRow } from './profiles.js';
import { parse } from './validate.js';

const LINK_RE = /(https?:\/\/|www\.|\b[a-z0-9-]+\.(com|net|org|io|me|co|app|ly|link)\b)/i;

const profileBody = z.object({
  displayName: z.string().trim().min(1).max(60),
  handle: z.string().max(40).nullable().optional(),
  bio: z.string().max(160).nullable().optional(),
  visibility: z.enum(['private', 'handle', 'community']).optional(),
});

const deleteBody = z.object({
  confirm: z.literal('DELETE'),
  content: z.enum(['keep_anonymous', 'remove']).default('keep_anonymous'),
});

export async function registerMeRoutes(app: FastifyInstance, deps: Deps): Promise<void> {
  const { db } = deps;
  const auth = requireAuth(deps);

  app.get('/v1/me', { preHandler: [auth] }, async (request) => {
    const a = request.auth;
    if (!a) throw unauthorized();
    const u = await db.query<{
      id: string;
      email: string | null;
      role: string;
      status: string;
      created_at: Date;
    }>('select id, email, role, status, created_at from users where id = $1', [a.userId]);
    const user = u.rows[0];
    if (!user) throw unauthorized();
    const profile = await ownAdultProfile(db, a.userId);
    const kids = await db.query<ProfileRow>(
      `select ${PROFILE_COLUMNS} from profiles where managed_by = $1 order by created_at`,
      [a.userId],
    );
    return {
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        status: user.status,
        createdAt: toIso(user.created_at),
      },
      profile: profile ? mapProfile(profile) : null,
      children: kids.rows.map(mapProfile),
    };
  });

  app.put(
    '/v1/me/profile',
    { preHandler: [auth, limit(deps, { name: 'profile_write', max: 30, windowSec: 3600, by: 'user' })] },
    async (request) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      const body = parse(profileBody, request.body);
      const name = body.displayName.trim();
      const nameProblem = validateDisplayName(name);
      if (nameProblem) throw unprocessable('display_name_invalid', nameProblem);
      const handle = body.handle ?? null;
      if (handle !== null) {
        const p = validateHandle(handle);
        if (p) throw unprocessable('handle_invalid', p);
      }
      const bio = body.bio?.trim() ? body.bio.trim() : null;
      if (bio !== null && LINK_RE.test(bio)) {
        throw unprocessable('bio_invalid', 'Please leave links out of your bio.');
      }
      const visibility = body.visibility ?? 'private';
      if (visibility === 'handle' && handle === null) {
        throw unprocessable('handle_required', 'Choose a handle to be found by it.');
      }
      const now = deps.now();
      try {
        const existing = await ownAdultProfile(db, a.userId);
        const r = existing
          ? await db.query<ProfileRow>(
              `update profiles set display_name = $2, handle = $3, bio = $4, visibility = $5, updated_at = $6
                where id = $1 returning ${PROFILE_COLUMNS}`,
              [existing.id, name, handle, bio, visibility, now],
            )
          : await db.query<ProfileRow>(
              `insert into profiles (kind, user_id, display_name, handle, bio, visibility)
               values ('adult', $1, $2, $3, $4, $5) returning ${PROFILE_COLUMNS}`,
              [a.userId, name, handle, bio, visibility],
            );
        const row = r.rows[0];
        if (!row) throw notFound();
        return { profile: mapProfile(row) };
      } catch (err) {
        if (sqlState(err) === UNIQUE_VIOLATION) {
          throw conflict('handle_taken', 'That handle is already taken.');
        }
        throw err;
      }
    },
  );

  app.delete(
    '/v1/me',
    { preHandler: [auth, limit(deps, { name: 'account_delete', max: 5, windowSec: 3600, by: 'user' })] },
    async (request, reply) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      const body = parse(deleteBody, request.body);
      await db.tx((q) => eraseAccount(q, a.userId, deps.now(), body.content));
      void reply.code(204);
    },
  );

  app.get(
    '/v1/me/export',
    { preHandler: [auth, limit(deps, { name: 'export', max: 5, windowSec: 3600, by: 'user' })] },
    async (request) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      const id = a.userId;
      const one = async (sql: string) => (await db.query(sql, [id])).rows;
      const profileIds = (
        await db.query<{ id: string }>(
          'select id from profiles where user_id = $1 or managed_by = $1',
          [id],
        )
      ).rows.map((r) => r.id);
      const byProfile = async (sql: string) => (await db.query(sql, [profileIds])).rows;
      return {
        exportedAt: deps.now().toISOString(),
        user: (await one(
          'select id, email, role, status, created_at, last_login_at from users where id = $1',
        ))[0],
        profiles: await one(
          `select ${PROFILE_COLUMNS} from profiles where user_id = $1 or managed_by = $1 order by created_at`,
        ),
        parentalLinks: await one(
          'select id, ward_profile_id, status, consent_version, consented_at, revoked_at from parental_links where guardian_user_id = $1',
        ),
        consents: await one(
          'select kind, version, subject_profile_id, given_at, withdrawn_at from consents where user_id = $1',
        ),
        sessions: await one(
          'select id, device_label, created_at, last_seen_at, expires_at, revoked_at from sessions where user_id = $1',
        ),
        invitesCreated: await one(
          'select id, kind, created_by_profile, max_uses, uses, expires_at, revoked_at, created_at from invites where created_by_user = $1',
        ),
        friendships: await byProfile(
          `select id, profile_lo, profile_hi, requested_by, status, via, created_at, responded_at
             from friendships where profile_lo = any($1::uuid[]) or profile_hi = any($1::uuid[])`,
        ),
        blocks: await byProfile(
          'select blocker_profile, blocked_profile, created_at from blocks where blocker_profile = any($1::uuid[])',
        ),
        forumPosts: await byProfile(
          'select id, thread_id, body, label, status, created_at from forum_posts where author_profile_id = any($1::uuid[])',
        ),
        meetupRsvps: await byProfile(
          'select meetup_id, profile_id, status, created_at from meetup_rsvps where profile_id = any($1::uuid[])',
        ),
        notifications: await one(
          'select kind, payload, read_at, created_at from notifications where user_id = $1',
        ),
      };
    },
  );
}
