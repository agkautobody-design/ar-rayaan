import type { FastifyReply, FastifyRequest, preHandlerAsyncHookHandler } from 'fastify';
import type { Deps } from './context.js';
import { forbidden, tooMany, unauthorized } from './errors.js';
import { hashToken, SESSION_TOKEN_PREFIX } from './security.js';

/** Requires a valid bearer token; fills request.auth. */
export function requireAuth(deps: Deps): preHandlerAsyncHookHandler {
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
    if (row.status !== 'active') {
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
