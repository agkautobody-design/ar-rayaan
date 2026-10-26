import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { audit, type Deps } from './context.js';
import { sqlState, UNIQUE_VIOLATION } from './db.js';
import { ApiError, forbidden, notFound, tooMany, unauthorized, unprocessable } from './errors.js';
import { FirebaseVerifier, TokenRejected } from './firebaseVerifier.js';
import { limit, requireAuth } from './guards.js';
import {
  codeHash,
  emailHash,
  hashToken,
  newSessionToken,
  newSignInCode,
  normaliseEmail,
  safeEqualHex,
} from './security.js';
import { parse, UUID_RE } from './validate.js';
import { PRIVACY_VERSION, TERMS_VERSION } from './versions.js';

export const CODE_TTL_MINUTES = 10;
export const MAX_CODE_ATTEMPTS = 5;
export const MAX_CODES_PER_EMAIL_PER_HOUR = 5;

const emailSchema = z
  .string()
  .max(254)
  .regex(/^[^\s@]+@[^\s@]+\.[^\s@]+$/);

const requestBody = z.object({ email: emailSchema });

const verifyBody = z.object({
  email: emailSchema,
  code: z.string().regex(/^\d{6}$/),
  deviceLabel: z.string().trim().min(1).max(60).optional(),
  // Needed only the first time (account creation).
  confirmAdult: z.boolean().optional(),
  termsVersion: z.string().max(40).optional(),
  privacyVersion: z.string().max(40).optional(),
});

const firebaseBody = z.object({
  idToken: z.string().min(20).max(4096),
  deviceLabel: z.string().trim().min(1).max(60).optional(),
  confirmAdult: z.boolean().optional(),
  termsVersion: z.string().max(40).optional(),
  privacyVersion: z.string().max(40).optional(),
});

interface UserRow {
  id: string;
  role: 'member' | 'moderator' | 'admin';
  status: string;
}

export async function registerAuthRoutes(app: FastifyInstance, deps: Deps): Promise<void> {
  const { db, config } = deps;

  interface SignInBody {
    confirmAdult?: boolean | undefined;
    termsVersion?: string | undefined;
    privacyVersion?: string | undefined;
    deviceLabel?: string | undefined;
  }

  /**
   * Shared end of every sign-in route: find or create the account, enforce
   * the adult confirmation and consent versions for NEW accounts, refuse
   * restricted accounts, and open a session. [consume] runs inside the same
   * transaction (marks the e-mail code used); [refund] runs when a new
   * account is refused so the person can retry with the same code.
   */
  async function finishSignIn(o: {
    normalised: string;
    eh: string;
    firebaseUid: string | undefined;
    body: SignInBody;
    consume?: (q: import('./db.js').Queryable) => Promise<void>;
    refund?: () => Promise<void>;
  }) {
    const now = deps.now();
    const found = await db.query<UserRow & { firebase_uid: string | null }>(
      o.firebaseUid
        ? 'select id, role, status, firebase_uid from users where firebase_uid = $1 or email_hash = $2 order by (firebase_uid = $1) desc nulls last limit 1'
        : 'select id, role, status, firebase_uid from users where email_hash = $2 and $1::text is null',
      [o.firebaseUid ?? null, o.eh],
    );
    let user: UserRow | undefined = found.rows[0];

    if (!user) {
      // First sign-in = account creation. Adults only, with agreed texts.
      if (o.body.confirmAdult !== true) {
        await o.refund?.();
        throw unprocessable(
          'adult_confirmation_required',
          'Accounts are for people aged 18 or over. Children use a child profile inside a parent’s account.',
        );
      }
      if (o.body.termsVersion !== TERMS_VERSION || o.body.privacyVersion !== PRIVACY_VERSION) {
        await o.refund?.();
        throw unprocessable('consent_outdated', 'Please read and accept the current Terms and Privacy Policy.');
      }
    } else if (user.status === 'banned' || user.status === 'suspended') {
      throw forbidden('account_restricted', 'This account cannot be used right now.');
    }

    const token = newSessionToken();
    const expiresAt = new Date(now.getTime() + config.sessionTtlDays * 86_400_000);
    let created = false;
    try {
      user = await db.tx(async (q) => {
        await o.consume?.(q);
        let u = user;
        if (!u) {
          const ins = await q.query<UserRow>(
            `insert into users (email, email_hash, firebase_uid, adult_attested_at, last_login_at)
             values ($1, $2, $3, $4, $4) returning id, role, status`,
            [o.normalised, o.eh, o.firebaseUid ?? null, now],
          );
          u = ins.rows[0];
          if (!u) throw new Error('user insert returned no row');
          created = true;
          await q.query(
            `insert into consents (user_id, kind, version) values ($1, 'terms', $2), ($1, 'privacy', $3)`,
            [u.id, TERMS_VERSION, PRIVACY_VERSION],
          );
          await audit(q, { actorUserId: u.id, actorRole: u.role, action: 'account.created' });
        } else {
          // Link a Firebase identity to an account first made with an e-mail code.
          await q.query(
            'update users set last_login_at = $1, firebase_uid = coalesce(firebase_uid, $3) where id = $2',
            [now, u.id, o.firebaseUid ?? null],
          );
        }
        await q.query(
          `insert into sessions (user_id, token_hash, device_label, created_at, last_seen_at, expires_at)
           values ($1, $2, $3, $4, $4, $5)`,
          [u.id, hashToken(token), o.body.deviceLabel ?? null, now, expiresAt],
        );
        return u;
      });
    } catch (err) {
      if (sqlState(err) === UNIQUE_VIOLATION) {
        throw unauthorized('That sign-in is not valid. Please try again.');
      }
      throw err;
    }
    if (!user) throw new Error('no user after sign-in');
    return {
      token,
      expiresAt: expiresAt.toISOString(),
      isNewAccount: created,
      user: { id: user.id, role: user.role },
    };
  }

  if (config.authMode !== 'firebase') {
  app.post(
    '/v1/auth/request-code',
    { preHandler: [limit(deps, { name: 'auth_request', max: 10, windowSec: 3600, by: 'ip' })] },
    async (request, reply) => {
      const { email } = parse(requestBody, request.body);
      const normalised = normaliseEmail(email);
      const eh = emailHash(config.pepper, normalised);
      const now = deps.now();

      const recent = await db.query<{ n: string }>(
        'select count(*)::text as n from auth_codes where email_hash = $1 and created_at > $2',
        [eh, new Date(now.getTime() - 3_600_000)],
      );
      if (Number(recent.rows[0]?.n ?? '0') >= MAX_CODES_PER_EMAIL_PER_HOUR) throw tooMany(600);

      const code = newSignInCode();
      const ins = await db.query<{ id: string }>(
        `insert into auth_codes (email_hash, code_hash, created_at, expires_at, requester_hash)
         values ($1, $2, $3, $4, $5) returning id`,
        [
          eh,
          codeHash(config.pepper, normalised, code),
          now,
          new Date(now.getTime() + CODE_TTL_MINUTES * 60_000),
          emailHash(config.pepper, `ip:${request.ip}`),
        ],
      );
      try {
        await deps.email.sendSignInCode(normalised, code, CODE_TTL_MINUTES);
      } catch (err) {
        await db.query('delete from auth_codes where id = $1', [ins.rows[0]?.id]);
        request.log.error({ err: String(err) }, 'sign-in e-mail failed');
        throw new ApiError(502, 'email_unavailable', 'We could not send the code. Please try again.');
      }
      // Same answer whether or not an account exists.
      void reply.code(202);
      return { ok: true, expiresInSec: CODE_TTL_MINUTES * 60 };
    },
  );

  app.post(
    '/v1/auth/verify-code',
    { preHandler: [limit(deps, { name: 'auth_verify', max: 30, windowSec: 3600, by: 'ip' })] },
    async (request) => {
      const body = parse(verifyBody, request.body);
      const normalised = normaliseEmail(body.email);
      const eh = emailHash(config.pepper, normalised);
      const now = deps.now();

      const open = await db.query<{ id: string; code_hash: string }>(
        `select id, code_hash from auth_codes
          where email_hash = $1 and consumed_at is null and expires_at > $2
          order by created_at desc limit 1`,
        [eh, now],
      );
      const row = open.rows[0];
      if (!row) throw unauthorized('That code is not valid. Ask for a new one.');

      const bumped = await db.query<{ attempts: number }>(
        'update auth_codes set attempts = attempts + 1 where id = $1 returning attempts',
        [row.id],
      );
      const attempts = bumped.rows[0]?.attempts ?? MAX_CODE_ATTEMPTS + 1;
      if (attempts > MAX_CODE_ATTEMPTS) {
        await db.query('update auth_codes set consumed_at = $1 where id = $2', [now, row.id]);
        throw unauthorized('That code is not valid. Ask for a new one.');
      }
      const good = safeEqualHex(row.code_hash, codeHash(config.pepper, normalised, body.code));
      if (!good) throw unauthorized('That code is not valid. Ask for a new one.');

      return finishSignIn({
        normalised,
        eh,
        firebaseUid: undefined,
        body,
        refund: async () => {
          await db.query('update auth_codes set attempts = attempts - 1 where id = $1', [row.id]);
        },
        consume: async (q) => {
          const used = await q.query(
            'update auth_codes set consumed_at = $1 where id = $2 and consumed_at is null',
            [now, row.id],
          );
          if (used.rowCount !== 1) throw unauthorized('That code is not valid. Ask for a new one.');
        },
      });
    },
  );
  }

  if (config.authMode !== 'email_code') {
    const verifier =
      deps.firebase ??
      new FirebaseVerifier(config.firebaseProjectId ?? '', deps.now);
    app.post(
      '/v1/auth/firebase',
      { preHandler: [limit(deps, { name: 'auth_firebase', max: 60, windowSec: 3600, by: 'ip' })] },
      async (request) => {
        const body = parse(firebaseBody, request.body);
        let identity;
        try {
          identity = await verifier.verify(body.idToken);
        } catch (err) {
          if (err instanceof TokenRejected) throw unauthorized('Please sign in again.');
          throw err;
        }
        if (!identity.emailVerified) {
          throw unprocessable('email_not_verified', 'Please verify your e-mail address first.');
        }
        const normalised = normaliseEmail(identity.email);
        return finishSignIn({
          normalised,
          eh: emailHash(config.pepper, normalised),
          firebaseUid: identity.uid,
          body,
        });
      },
    );
  }

  app.post('/v1/auth/logout', { preHandler: [requireAuth(deps)] }, async (request, reply) => {
    const auth = request.auth;
    if (!auth) throw unauthorized();
    await db.query('update sessions set revoked_at = $1 where id = $2', [deps.now(), auth.sessionId]);
    void reply.code(204);
  });

  app.get('/v1/auth/sessions', { preHandler: [requireAuth(deps)] }, async (request) => {
    const auth = request.auth;
    if (!auth) throw unauthorized();
    const r = await db.query<{
      id: string;
      device_label: string | null;
      created_at: Date;
      last_seen_at: Date;
      expires_at: Date;
    }>(
      `select id, device_label, created_at, last_seen_at, expires_at from sessions
        where user_id = $1 and revoked_at is null and expires_at > $2
        order by last_seen_at desc`,
      [auth.userId, deps.now()],
    );
    return {
      sessions: r.rows.map((s) => ({
        id: s.id,
        deviceLabel: s.device_label,
        createdAt: new Date(s.created_at).toISOString(),
        lastSeenAt: new Date(s.last_seen_at).toISOString(),
        expiresAt: new Date(s.expires_at).toISOString(),
        current: s.id === auth.sessionId,
      })),
    };
  });

  app.delete<{ Params: { id: string } }>(
    '/v1/auth/sessions/:id',
    { preHandler: [requireAuth(deps)] },
    async (request, reply) => {
      const auth = request.auth;
      if (!auth) throw unauthorized();
      if (!UUID_RE.test(request.params.id)) throw notFound();
      const r = await db.query(
        `update sessions set revoked_at = $1
          where id = $2 and user_id = $3 and revoked_at is null`,
        [deps.now(), request.params.id, auth.userId],
      );
      if (r.rowCount === 0) throw notFound();
      void reply.code(204);
    },
  );
}
