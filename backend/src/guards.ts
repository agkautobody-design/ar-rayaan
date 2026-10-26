import type { FastifyReply, FastifyRequest, preHandlerAsyncHookHandler } from 'fastify';
import type { Deps } from './context.js';
import type { Queryable } from './db.js';
import { forbidden, tooMany, unauthorized } from './errors.js';
import { hashToken, SESSION_TOKEN_PREFIX } from './security.js';

/**
 * Lifts a suspension that had an end time which has now passed and that no
 * other sanction keeps in force. A suspension set by hand (no sanction row)
 * stays until a person lifts it. Returns true when the account is active again.
 */
export async function liftExpiredSuspension(q: Queryable, userId: string, now: Date): Promise<boolean> {
  const s = await q.query<{ active: string; ended: string }>(
    `select count(*) filter (where lifted_at is null and starts_at <= $2
                               and (ends_at is null or ends_at > $2))::text as active,
            count(*) filter (where kind = 'suspend' and lifted_at is null
                               and ends_at is not null and ends_at <= $2)::text as ended
       from sanctions where user_id = $1 and kind in ('suspend', 'ban')`,
    [userId, now],
  );
  if (Number(s.rows[0]?.active ?? '0') !== 0 || Number(s.rows[0]?.ended ?? '0') === 0) return false;
  await q.query(`update users set status = 'active' where id = $1 and status = 'suspended'`, [userId]);
  return true;
}

/**
 * Requires a valid bearer token; fills request.auth. A suspended or banned
 * account is refused unless [allowRestricted] is set (only the routes a
 * restricted person needs: see their notice and appeal). A suspension whose
 * time has run out is lifted here, on the first request after it ends.
 */
export function requireAuth(
  deps: Deps,
  opts: { allowRestricted?: boolean } = {},
): preHandlerAsyncHookHandler {
  return async (request: FastifyRequest) => {
    const header = request.headers.authorization;
    if (typeof header !== 'string' || !header.startsWith('Bearer ')) throw unauthorized();
    const token = header.slice(7).trim();
    if (!token.startsWith(SESSION_TOKEN_PREFIX) || token.length > 200) throw unauthorized();

    const now = deps.now();
    const r = await deps.db.query<{
      session_id: string;
      user_id: string;
      role: 'member' | 'moderator' | 'admin';
      status: string;
      last_seen_at: Date;
    }>(
      `select s.id as session_id, u.id as user_id, u.role, u.status, s.last_seen_at
         from sessions s join users u on u.id = s.user_id
        where s.token_hash = $1 and s.revoked_at is null and s.expires_at > $2`,
      [hashToken(token), now],
    );
    const row = r.rows[0];
    if (!row) throw unauthorized();
    if (row.status === 'suspended' && (await liftExpiredSuspension(deps.db, row.user_id, now))) {
      row.status = 'active';
    }
    if (row.status !== 'active' && !(opts.allowRestricted && (row.status === 'suspended' || row.status === 'banned'))) {
      throw forbidden('account_restricted', 'This account cannot be used right now.');
    }
    // Touch at most once an hour: cheap, and enough to list "last used".
    if (now.getTime() - new Date(row.last_seen_at).getTime() > 3_600_000) {
      await deps.db.query('update sessions set last_seen_at = $1 where id = $2', [
        now,
        row.session_id,
      ]);
    }
    request.auth = { userId: row.user_id, role: row.role, sessionId: row.session_id };
  };
}

export function requireRole(...roles: Array<'moderator' | 'admin'>): preHandlerAsyncHookHandler {
  return async (request: FastifyRequest) => {
    const role = request.auth?.role;
    if (!role || !(roles as string[]).includes(role)) {
      throw forbidden('forbidden', 'You cannot do that.');
    }
  };
}

export interface LimitSpec {
  /** Short stable name, part of the key. */
  name: string;
  max: number;
  windowSec: number;
  by: 'ip' | 'user';
}

/** Per-route limit. Throws 429 (with Retry-After) when exceeded. */
export function limit(deps: Deps, spec: LimitSpec): preHandlerAsyncHookHandler {
  return async (request: FastifyRequest, reply: FastifyReply) => {
    const who = spec.by === 'user' ? (request.auth?.userId ?? request.ip) : request.ip;
    const r = deps.limiter.hit(`${spec.name}:${spec.by}:${who}`, spec.max, spec.windowSec * 1000);
    if (!r.allowed) {
      void reply.header('retry-after', String(r.retryAfterSec));
      throw tooMany(r.retryAfterSec);
    }
  };
}
