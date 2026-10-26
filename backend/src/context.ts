import type { Config } from './config.js';
import type { Db, Queryable } from './db.js';
import type { EmailSender } from './email.js';
import type { FirebaseVerifier } from './firebaseVerifier.js';
import type { RateLimiter } from './rateLimit.js';

export interface Deps {
  config: Config;
  db: Db;
  email: EmailSender;
  limiter: RateLimiter;
  /** Overridable in tests; built from config when authMode needs it. */
  firebase?: FirebaseVerifier;
  now: () => Date;
}

export type Role = 'member' | 'moderator' | 'admin';

export interface AuthInfo {
  userId: string;
  role: Role;
  sessionId: string;
}

declare module 'fastify' {
  interface FastifyRequest {
    auth?: AuthInfo;
  }
}

export interface AuditEntry {
  actorUserId: string | null;
  actorRole?: Role | null;
  action: string;
  targetType?: string;
  targetId?: string;
  /** Ids and codes only. Never names, addresses or message text. */
  meta?: Record<string, unknown>;
}

export async function audit(q: Queryable, e: AuditEntry): Promise<void> {
  await q.query(
    `insert into audit_log (actor_user_id, actor_role, action, target_type, target_id, meta)
     values ($1, $2, $3, $4, $5, $6::jsonb)`,
    [
      e.actorUserId,
      e.actorRole ?? null,
      e.action,
      e.targetType ?? null,
      e.targetId ?? null,
      JSON.stringify(e.meta ?? {}),
    ],
  );
}
