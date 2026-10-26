import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import type { Deps } from './context.js';
import type { Queryable } from './db.js';
import { conflict, forbidden, notFound, unauthorized } from './errors.js';
import { limit, requireAuth } from './guards.js';
import { notify } from './notify.js';
import {
  capabilities,
  MAX_FRIENDS_ADULT,
  MAX_FRIENDS_MINOR,
  type ProfileKind,
} from './policy/age.js';
import { actingProfile, toIso, type ProfileRow } from './profiles.js';
import { parse, UUID_RE } from './validate.js';

export const DECLINE_COOLDOWN_DAYS = 30;

export function orderedPair(a: string, b: string): [string, string] {
  return a < b ? [a, b] : [b, a];
}

export function friendCap(kind: ProfileKind): number {
  return kind === 'adult' ? MAX_FRIENDS_ADULT : MAX_FRIENDS_MINOR;
}

export async function acceptedFriendCount(q: Queryable, profileId: string): Promise<number> {
  const r = await q.query<{ n: string }>(
    `select count(*)::text as n from friendships
      where status = 'accepted' and (profile_lo = $1 or profile_hi = $1)`,
    [profileId],
  );
  return Number(r.rows[0]?.n ?? '0');
}

export async function isBlockedEitherWay(q: Queryable, a: string, b: string): Promise<boolean> {
  const r = await q.query(
    `select 1 from blocks
      where (blocker_profile = $1 and blocked_profile = $2)
         or (blocker_profile = $2 and blocked_profile = $1) limit 1`,
    [a, b],
  );
  return r.rowCount > 0;
}

const requestBody = z.object({ handle: z.string().trim().toLowerCase().regex(/^[a-z0-9_]{3,20}$/) });
const blockBody = z.object({
  profileId: z.string().regex(/^[0-9a-f-]{36}$/),
  asProfileId: z.string().regex(/^[0-9a-f-]{36}$/).optional(),
});
const listQuery = z.object({ profileId: z.string().regex(/^[0-9a-f-]{36}$/).optional() });

interface FriendRow {
  id: string;
  status: 'pending' | 'accepted';
  requested_by: string;
  created_at: Date;
  responded_at: Date | null;
  other_id: string;
  other_name: string;
  other_kind: ProfileKind;
}

export async function registerFriendRoutes(app: FastifyInstance, deps: Deps): Promise<void> {
  const { db } = deps;
  const auth = requireAuth(deps);

  app.get('/v1/friends', { preHandler: [auth] }, async (request) => {
    const a = request.auth;
    if (!a) throw unauthorized();
    const { profileId } = parse(listQuery, request.query);
    const me = await actingProfile(db, a.userId, profileId);
    const r = await db.query<FriendRow>(
      `select f.id, f.status, f.requested_by, f.created_at, f.responded_at,
              p.id as other_id, p.display_name as other_name, p.kind as other_kind
         from friendships f
         join profiles p on p.id = case when f.profile_lo = $1 then f.profile_hi else f.profile_lo end
        where (f.profile_lo = $1 or f.profile_hi = $1)
          and f.status in ('pending', 'accepted') and p.erased_at is null
        order by f.created_at desc`,
      [me.id],
    );
    const shape = (f: FriendRow) => ({
      friendshipId: f.id,
      since: toIso(f.responded_at ?? f.created_at),
      profile: { id: f.other_id, displayName: f.other_name, kind: f.other_kind },
    });
    return {
      profileId: me.id,
      friends: r.rows.filter((f) => f.status === 'accepted').map(shape),
      incoming: r.rows
        .filter((f) => f.status === 'pending' && f.requested_by !== me.id)
        .map(shape),
      outgoing: r.rows
        .filter((f) => f.status === 'pending' && f.requested_by === me.id)
        .map(shape),
    };
  });

  app.post(
    '/v1/friends/requests',
    { preHandler: [auth, limit(deps, { name: 'friend_request', max: 20, windowSec: 86_400, by: 'user' })] },
    async (request, reply) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      const { handle } = parse(requestBody, request.body);
      const out = await db.tx(async (q) => {
        const me = await actingProfile(q, a.userId);
        if (!capabilities(me.kind).friendRequestsByHandle) {
          throw forbidden('not_allowed', 'This profile cannot send friend requests.');
        }
        const t = await q.query<ProfileRow & { owner_status: string }>(
          `select p.id, p.kind, p.user_id, p.managed_by, p.display_name, p.handle, p.bio,
                  p.visibility, p.created_at, p.erased_at, u.status as owner_status
             from profiles p join users u on u.id = p.user_id
            where p.handle = $1 and p.kind = 'adult' and p.visibility in ('handle', 'community')
              and p.erased_at is null`,
          [handle],
        );
        const target = t.rows[0];
        if (!target || target.owner_status !== 'active' || target.user_id === null) throw notFound();
        if (target.id === me.id) throw conflict('cannot_friend_self', 'That is your own handle.');
        if (await isBlockedEitherWay(q, me.id, target.id)) throw notFound();
        if ((await acceptedFriendCount(q, me.id)) >= friendCap(me.kind)) {
          throw conflict('friend_limit_reached', 'You have reached the friend limit.');
        }
        const [lo, hi] = orderedPair(me.id, target.id);
        const ex = await q.query<{ id: string; status: string; requested_by: string; responded_at: Date | null }>(
          'select id, status, requested_by, responded_at from friendships where profile_lo = $1 and profile_hi = $2',
          [lo, hi],
        );
        const old = ex.rows[0];
        let id: string;
        if (old) {
          if (old.status === 'accepted') throw conflict('already_friends', 'You are already friends.');
          if (old.status === 'pending') {
            throw conflict('request_pending', 'A request is already waiting.');
          }
          if (
            old.status === 'declined' &&
            old.requested_by === me.id &&
            old.responded_at &&
            deps.now().getTime() - new Date(old.responded_at).getTime() <
              DECLINE_COOLDOWN_DAYS * 86_400_000
          ) {
            throw conflict('request_declined_recently', 'Please wait before asking again.');
          }
          await q.query(
            `update friendships set status = 'pending', requested_by = $2, via = 'handle',
                    invite_id = null, created_at = $3, responded_at = null,
                    guardian_lo_user = null, guardian_lo_at = null,
                    guardian_hi_user = null, guardian_hi_at = null
              where id = $1`,
            [old.id, me.id, deps.now()],
          );
          id = old.id;
        } else {
          const ins = await q.query<{ id: string }>(
            `insert into friendships (profile_lo, profile_hi, requested_by, status, via)
             values ($1, $2, $3, 'pending', 'handle') returning id`,
            [lo, hi, me.id],
          );
          id = ins.rows[0]?.id ?? '';
        }
        await notify(q, target.user_id, 'friend_request', { friendshipId: id });
        return id;
      });
      void reply.code(201);
      return { friendship: { id: out, status: 'pending' } };
    },
  );

  const respond = (verb: 'accept' | 'decline') =>
    async (request: { auth?: { userId: string }; params: { id: string } }) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      if (!UUID_RE.test(request.params.id)) throw notFound();
      return db.tx(async (q) => {
        const me = await actingProfile(q, a.userId);
        const r = await q.query<{ id: string; profile_lo: string; profile_hi: string; requested_by: string }>(
          `select id, profile_lo, profile_hi, requested_by from friendships
            where id = $1 and status = 'pending' and (profile_lo = $2 or profile_hi = $2)
              and requested_by <> $2 for update`,
          [request.params.id, me.id],
        );
        const f = r.rows[0];
        if (!f) throw notFound();
        if (verb === 'accept') {
          if ((await acceptedFriendCount(q, me.id)) >= friendCap(me.kind)) {
            throw conflict('friend_limit_reached', 'You have reached the friend limit.');
          }
          await q.query(
            `update friendships set status = 'accepted', responded_at = $2 where id = $1`,
            [f.id, deps.now()],
          );
          const who = await q.query<{ user_id: string | null }>(
            'select user_id from profiles where id = $1',
            [f.requested_by],
          );
          const uid = who.rows[0]?.user_id;
          if (uid) await notify(q, uid, 'friend_accepted', { friendshipId: f.id });
        } else {
          await q.query(
            `update friendships set status = 'declined', responded_at = $2 where id = $1`,
            [f.id, deps.now()],
          );
        }
        return { friendship: { id: f.id, status: verb === 'accept' ? 'accepted' : 'declined' } };
      });
    };

  app.post<{ Params: { id: string } }>(
    '/v1/friends/requests/:id/accept',
    { preHandler: [auth] },
    respond('accept'),
  );
  app.post<{ Params: { id: string } }>(
    '/v1/friends/requests/:id/decline',
    { preHandler: [auth] },
    respond('decline'),
  );

  app.delete<{ Params: { id: string }; Querystring: { profileId?: string } }>(
    '/v1/friends/:id',
    { preHandler: [auth] },
    async (request, reply) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      if (!UUID_RE.test(request.params.id)) throw notFound();
      const { profileId } = parse(listQuery, request.query);
      const me = await actingProfile(db, a.userId, profileId);
      const r = await db.query(
        `update friendships set status = 'removed', responded_at = $3
          where id = $1 and status in ('accepted', 'pending') and (profile_lo = $2 or profile_hi = $2)`,
        [request.params.id, me.id, deps.now()],
      );
      if (r.rowCount === 0) throw notFound();
      void reply.code(204);
    },
  );

  app.get('/v1/blocks', { preHandler: [auth] }, async (request) => {
    const a = request.auth;
    if (!a) throw unauthorized();
    const { profileId } = parse(listQuery, request.query);
    const me = await actingProfile(db, a.userId, profileId);
    const r = await db.query<{ id: string; display_name: string; created_at: Date }>(
      `select p.id, p.display_name, b.created_at from blocks b join profiles p on p.id = b.blocked_profile
        where b.blocker_profile = $1 order by b.created_at desc`,
      [me.id],
    );
    return {
      blocks: r.rows.map((b) => ({ profileId: b.id, displayName: b.display_name, createdAt: toIso(b.created_at) })),
    };
  });

  app.post(
    '/v1/blocks',
    { preHandler: [auth, limit(deps, { name: 'block', max: 60, windowSec: 3600, by: 'user' })] },
    async (request, reply) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      const body = parse(blockBody, request.body);
      await db.tx(async (q) => {
        const me = await actingProfile(q, a.userId, body.asProfileId);
        if (!UUID_RE.test(body.profileId)) throw notFound();
        if (body.profileId === me.id) throw conflict('cannot_block_self', 'You cannot block yourself.');
        const exists = await q.query('select 1 from profiles where id = $1', [body.profileId]);
        if (exists.rowCount === 0) throw notFound();
        await q.query(
          `insert into blocks (blocker_profile, blocked_profile) values ($1, $2)
           on conflict do nothing`,
          [me.id, body.profileId],
        );
        const [lo, hi] = orderedPair(me.id, body.profileId);
        await q.query(
          `update friendships set status = 'removed', responded_at = $3
            where profile_lo = $1 and profile_hi = $2 and status in ('accepted', 'pending')`,
          [lo, hi, deps.now()],
        );
      });
      void reply.code(204);
    },
  );

  app.delete<{ Params: { profileId: string }; Querystring: { profileId?: string } }>(
    '/v1/blocks/:profileId',
    { preHandler: [auth] },
    async (request, reply) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      if (!UUID_RE.test(request.params.profileId)) throw notFound();
      // Query string `profileId` names the acting profile (a managed child).
      const { profileId } = parse(listQuery, request.query);
      const me = await actingProfile(db, a.userId, profileId);
      await db.query('delete from blocks where blocker_profile = $1 and blocked_profile = $2', [
        me.id,
        request.params.profileId,
      ]);
      void reply.code(204);
    },
  );
}
