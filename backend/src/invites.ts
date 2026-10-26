import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { audit, type Deps } from './context.js';
import { CHECK_VIOLATION, sqlState, type Queryable } from './db.js';
import { conflict, forbidden, notFound, tooMany, unauthorized } from './errors.js';
import {
  acceptedFriendCount,
  friendCap,
  isBlockedEitherWay,
  orderedPair,
} from './friends.js';
import { limit, requireAuth } from './guards.js';
import { notify } from './notify.js';
import { isMinor, mayBeFriends, type ProfileKind } from './policy/age.js';
import { actingProfile, toIso } from './profiles.js';
import {
  inviteCodeHash,
  newInviteCode,
  normaliseInviteCode,
} from './security.js';
import { parse, UUID_RE } from './validate.js';

export const MAX_ACTIVE_INVITES = 20;
export const MAX_FAILED_CODE_LOOKUPS_PER_HOUR = 10;

const uuid = z.string().regex(/^[0-9a-f-]{36}$/);

const createBody = z.object({
  kind: z.literal('friend').default('friend'),
  asProfileId: uuid.optional(),
  maxUses: z.number().int().min(1).max(10).default(1),
  ttlHours: z.number().int().min(1).max(720).default(72),
});
const codeBody = z.object({ code: z.string().min(4).max(32), asProfileId: uuid.optional() });

interface InviteRow {
  id: string;
  kind: string;
  created_by_profile: string;
  created_by_user: string;
  max_uses: number;
  uses: number;
  expires_at: Date;
  revoked_at: Date | null;
  created_at: Date;
  creator_kind: ProfileKind;
  creator_name: string;
  creator_erased: Date | null;
}

export async function registerInviteRoutes(app: FastifyInstance, deps: Deps): Promise<void> {
  const { db, config } = deps;
  const auth = requireAuth(deps);

  /** Guessing codes is the attack; every miss counts against the person. */
  const failKey = (userId: string) => `invite_fail:user:${userId}`;
  const guardGuessing = (userId: string): void => {
    if (deps.limiter.isExhausted(failKey(userId), MAX_FAILED_CODE_LOOKUPS_PER_HOUR)) {
      throw tooMany(600);
    }
  };
  const miss = (userId: string): never => {
    deps.limiter.hit(failKey(userId), MAX_FAILED_CODE_LOOKUPS_PER_HOUR, 3_600_000);
    throw notFound('That invite is not valid any more.');
  };

  async function findInvite(
    q: Queryable,
    raw: string,
    userId: string,
    lock: boolean,
  ): Promise<InviteRow> {
    const code = normaliseInviteCode(raw);
    if (!code) return miss(userId);
    const r = await q.query<InviteRow>(
      `select i.id, i.kind, i.created_by_profile, i.created_by_user, i.max_uses, i.uses,
              i.expires_at, i.revoked_at, i.created_at,
              p.kind as creator_kind, p.display_name as creator_name, p.erased_at as creator_erased
         from invites i join profiles p on p.id = i.created_by_profile
        where i.code_hash = $1 ${lock ? 'for update of i' : ''}`,
      [inviteCodeHash(config.pepper, code)],
    );
    const inv = r.rows[0];
    if (
      !inv ||
      inv.revoked_at !== null ||
      inv.creator_erased !== null ||
      new Date(inv.expires_at).getTime() <= deps.now().getTime() ||
      inv.uses >= inv.max_uses
    ) {
      return miss(userId);
    }
    return inv;
  }

  app.post(
    '/v1/invites',
    { preHandler: [auth, limit(deps, { name: 'invite_create', max: 30, windowSec: 3600, by: 'user' })] },
    async (request, reply) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      const body = parse(createBody, request.body);
      const result = await db.tx(async (q) => {
        const me = await actingProfile(q, a.userId, body.asProfileId);
        const active = await q.query<{ n: string }>(
          `select count(*)::text as n from invites
            where created_by_user = $1 and revoked_at is null and expires_at > $2 and uses < max_uses`,
          [a.userId, deps.now()],
        );
        if (Number(active.rows[0]?.n ?? '0') >= MAX_ACTIVE_INVITES) {
          throw conflict('invite_limit_reached', 'Please revoke an old invite first.');
        }
        // A child's invite works once: a guardian hands it to one other family.
        const maxUses = isMinor(me.kind) ? 1 : body.maxUses;
        const code = newInviteCode();
        const expiresAt = new Date(deps.now().getTime() + body.ttlHours * 3_600_000);
        const ins = await q.query<{ id: string }>(
          `insert into invites (code_hash, kind, created_by_profile, created_by_user, max_uses, expires_at)
           values ($1, 'friend', $2, $3, $4, $5) returning id`,
          [inviteCodeHash(config.pepper, code.replace('-', '')), me.id, a.userId, maxUses, expiresAt],
        );
        const id = ins.rows[0]?.id ?? '';
        await audit(q, {
          actorUserId: a.userId,
          actorRole: a.role,
          action: 'invite.created',
          targetType: 'invite',
          targetId: id,
          meta: { forMinor: isMinor(me.kind) },
        });
        return { id, code, expiresAt, maxUses };
      });
      void reply.code(201);
      return {
        invite: {
          id: result.id,
          kind: 'friend',
          // Shown once. Only a keyed hash is stored.
          code: result.code,
          link: `${config.publicAppUrl}/#/join/${result.code}`,
          maxUses: result.maxUses,
          expiresAt: result.expiresAt.toISOString(),
        },
      };
    },
  );

  app.get('/v1/invites', { preHandler: [auth] }, async (request) => {
    const a = request.auth;
    if (!a) throw unauthorized();
    const r = await db.query<{
      id: string;
      created_by_profile: string;
      max_uses: number;
      uses: number;
      expires_at: Date;
      revoked_at: Date | null;
      created_at: Date;
    }>(
      `select id, created_by_profile, max_uses, uses, expires_at, revoked_at, created_at
         from invites where created_by_user = $1 order by created_at desc limit 100`,
      [a.userId],
    );
    const now = deps.now().getTime();
    return {
      invites: r.rows.map((i) => ({
        id: i.id,
        profileId: i.created_by_profile,
        maxUses: i.max_uses,
        uses: i.uses,
        expiresAt: toIso(i.expires_at),
        createdAt: toIso(i.created_at),
        active: i.revoked_at === null && new Date(i.expires_at).getTime() > now && i.uses < i.max_uses,
      })),
    };
  });

  app.delete<{ Params: { id: string } }>('/v1/invites/:id', { preHandler: [auth] }, async (request, reply) => {
    const a = request.auth;
    if (!a) throw unauthorized();
    if (!UUID_RE.test(request.params.id)) throw notFound();
    const r = await db.query(
      `update invites set revoked_at = $3 where id = $1 and created_by_user = $2 and revoked_at is null`,
      [request.params.id, a.userId, deps.now()],
    );
    if (r.rowCount === 0) throw notFound();
    void reply.code(204);
  });

  app.post(
    '/v1/invites/preview',
    { preHandler: [auth, limit(deps, { name: 'invite_preview', max: 30, windowSec: 3600, by: 'user' })] },
    async (request) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      const { code } = parse(codeBody, request.body);
      guardGuessing(a.userId);
      const inv = await findInvite(db, code, a.userId, false);
      const family = isMinor(inv.creator_kind);
      return {
        invite: {
          kind: inv.kind,
          // A child's name is never shown to a stranger holding a code.
          familyInvite: family,
          inviterDisplayName: family ? null : inv.creator_name,
          expiresAt: toIso(inv.expires_at),
        },
      };
    },
  );

  app.post(
    '/v1/invites/redeem',
    { preHandler: [auth, limit(deps, { name: 'invite_redeem', max: 30, windowSec: 3600, by: 'user' })] },
    async (request) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      const body = parse(codeBody, request.body);
      guardGuessing(a.userId);
      try {
        return await db.tx(async (q) => {
          const inv = await findInvite(q, body.code, a.userId, true);
          const me = await actingProfile(q, a.userId, body.asProfileId);
          if (!mayBeFriends(me.kind, inv.creator_kind)) {
            throw forbidden('not_allowed', 'This invite cannot be used for that profile.');
          }
          if (me.id === inv.created_by_profile) {
            throw conflict('own_invite', 'That is your own invite.');
          }
          // Two adults must be two people. Two children of one guardian are fine.
          if (!isMinor(me.kind) && inv.created_by_user === a.userId) {
            throw conflict('own_invite', 'That is your own invite.');
          }
          if (await isBlockedEitherWay(q, me.id, inv.created_by_profile)) {
            throw notFound('That invite is not valid any more.');
          }
          const done = await q.query(
            'select 1 from invite_redemptions where invite_id = $1 and profile_id = $2',
            [inv.id, me.id],
          );
          if (done.rowCount > 0) throw conflict('already_redeemed', 'You already used this invite.');

          const [lo, hi] = orderedPair(me.id, inv.created_by_profile);
          const ex = await q.query<{ id: string; status: string }>(
            'select id, status from friendships where profile_lo = $1 and profile_hi = $2',
            [lo, hi],
          );
          if (ex.rows[0]?.status === 'accepted') {
            throw conflict('already_friends', 'You are already friends.');
          }
          if (
            (await acceptedFriendCount(q, me.id)) >= friendCap(me.kind) ||
            (await acceptedFriendCount(q, inv.created_by_profile)) >= friendCap(inv.creator_kind)
          ) {
            throw conflict('friend_limit_reached', 'A friend limit has been reached.');
          }

          // Each minor side carries the approval of the guardian who acted:
          // the one who made the invite, and the one who is using it.
          const now = deps.now();
          const creatorIsLo = inv.created_by_profile === lo;
          const loMinor = creatorIsLo ? isMinor(inv.creator_kind) : isMinor(me.kind);
          const hiMinor = creatorIsLo ? isMinor(me.kind) : isMinor(inv.creator_kind);
          const loUser = creatorIsLo ? inv.created_by_user : a.userId;
          const hiUser = creatorIsLo ? a.userId : inv.created_by_user;
          const loAt = creatorIsLo ? inv.created_at : now;
          const hiAt = creatorIsLo ? now : inv.created_at;

          const up = await q.query<{ id: string }>(
            `insert into friendships
               (profile_lo, profile_hi, requested_by, status, via, invite_id,
                guardian_lo_user, guardian_lo_at, guardian_hi_user, guardian_hi_at, responded_at)
             values ($1, $2, $3, 'accepted', 'invite', $4, $5, $6, $7, $8, $9)
             on conflict (profile_lo, profile_hi) do update set
               status = 'accepted', requested_by = excluded.requested_by, via = 'invite',
               invite_id = excluded.invite_id, guardian_lo_user = excluded.guardian_lo_user,
               guardian_lo_at = excluded.guardian_lo_at, guardian_hi_user = excluded.guardian_hi_user,
               guardian_hi_at = excluded.guardian_hi_at, responded_at = excluded.responded_at
             returning id`,
            [
              lo,
              hi,
              inv.created_by_profile,
              inv.id,
              loMinor ? loUser : null,
              loMinor ? loAt : null,
              hiMinor ? hiUser : null,
              hiMinor ? hiAt : null,
              now,
            ],
          );
          const friendshipId = up.rows[0]?.id ?? '';
          await q.query('insert into invite_redemptions (invite_id, profile_id) values ($1, $2)', [
            inv.id,
            me.id,
          ]);
          await q.query('update invites set uses = uses + 1 where id = $1', [inv.id]);
          await notify(q, inv.created_by_user, 'friend_accepted', { friendshipId });
          await audit(q, {
            actorUserId: a.userId,
            actorRole: a.role,
            action: 'invite.redeemed',
            targetType: 'friendship',
            targetId: friendshipId,
            meta: { minor: isMinor(me.kind) || isMinor(inv.creator_kind) },
          });
          return {
            friendship: { id: friendshipId, status: 'accepted' },
            friend: {
              id: inv.created_by_profile,
              displayName: inv.creator_name,
              kind: inv.creator_kind,
            },
          };
        });
      } catch (err) {
        if (sqlState(err) === CHECK_VIOLATION) {
          throw forbidden('not_allowed', 'This invite cannot be used for that profile.');
        }
        throw err;
      }
    },
  );
}
