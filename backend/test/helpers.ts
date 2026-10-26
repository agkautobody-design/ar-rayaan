import { Writable } from 'node:stream';
import type { FastifyInstance } from 'fastify';
import { buildApp } from '../src/app.js';
import { loadConfig, type Config } from '../src/config.js';
import { PgDb, type Db } from '../src/db.js';
import type { FirebaseVerifier } from '../src/firebaseVerifier.js';
import { MemoryEmailSender } from '../src/email.js';
import { createLogger } from '../src/logging.js';
import { migrate } from '../src/migrate.js';
import { RateLimiter } from '../src/rateLimit.js';
import { PARENT_CONSENT_VERSION, PRIVACY_VERSION, TERMS_VERSION } from '../src/versions.js';

/**
 * By default the suite runs against in-memory PostgreSQL (PGlite): no server,
 * no setup. CI also runs it against a real PostgreSQL 16 by setting
 * TEST_DATABASE_URL, so both are exercised.
 */
export async function openTestDb(): Promise<Db> {
  const url = process.env.TEST_DATABASE_URL;
  let db: Db;
  if (url) {
    db = new PgDb(url, 4);
    await db.exec('drop schema if exists public cascade; create schema public;');
  } else {
    const { PgliteDb } = await import('../src/dev/pglite.js');
    db = await PgliteDb.create();
  }
  await migrate(db);
  return db;
}

export interface Clock {
  now: () => Date;
  advanceMs: (ms: number) => void;
}

export function makeClock(start = new Date('2026-11-01T12:00:00Z')): Clock {
  let t = start.getTime();
  return { now: () => new Date(t), advanceMs: (ms) => void (t += ms) };
}

export interface Ctx {
  app: FastifyInstance;
  db: Db;
  email: MemoryEmailSender;
  clock: Clock;
  config: Config;
  logs: string[];
  limiter: RateLimiter;
  close: () => Promise<void>;
}

export async function makeCtx(
  opts: { db?: Db; env?: Record<string, string>; firebase?: FirebaseVerifier } = {},
): Promise<Ctx> {
  const db = opts.db ?? (await openTestDb());
  const config = loadConfig({ NODE_ENV: 'test', LOG_LEVEL: 'info', ...opts.env });
  const logs: string[] = [];
  const stream = new Writable({
    write(chunk: Buffer, _enc, cb) {
      logs.push(chunk.toString());
      cb();
    },
  });
  const email = new MemoryEmailSender();
  const clock = makeClock();
  const limiter = new RateLimiter(() => clock.now().getTime());
  const app = await buildApp({
    deps: { config, db, email, limiter, now: clock.now, ...(opts.firebase ? { firebase: opts.firebase } : {}) },
    logger: createLogger(config, stream),
  });
  await app.ready();
  return {
    app,
    db,
    email,
    clock,
    config,
    logs,
    limiter,
    close: async () => {
      await app.close();
      if (!opts.db) await db.close();
    },
  };
}

export interface Session {
  token: string;
  userId: string;
  email: string;
}

type Method = 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';

export async function call(
  ctx: Ctx,
  method: Method,
  url: string,
  opts: { token?: string; body?: unknown; ip?: string } = {},
): Promise<{ status: number; json: any; headers: Record<string, unknown> }> {
  const res = await ctx.app.inject({
    method,
    url,
    headers: {
      ...(opts.token ? { authorization: `Bearer ${opts.token}` } : {}),
      ...(opts.body !== undefined ? { 'content-type': 'application/json' } : {}),
    },
    payload: opts.body === undefined ? undefined : JSON.stringify(opts.body),
    remoteAddress: opts.ip ?? nextIp(),
  });
  let json: any = null;
  try {
    json = res.body ? JSON.parse(res.body) : null;
  } catch {
    json = res.body;
  }
  return { status: res.statusCode, json, headers: res.headers };
}

let ipCounter = 0;
/** A fresh address per call, so per-IP limits only bite in tests that ask for them. */
function nextIp(): string {
  ipCounter += 1;
  return `172.${(ipCounter >> 16) & 255}.${(ipCounter >> 8) & 255}.${ipCounter & 255}`;
}

let counter = 0;
export const uniqueEmail = (prefix = 'user'): string => `${prefix}${++counter}@example.test`;

/** Full sign-up: request a code, read it from the outbox, verify. */
export async function signUp(ctx: Ctx, email = uniqueEmail(), ip?: string): Promise<Session> {
  const r1 = await call(ctx, 'POST', '/v1/auth/request-code', { body: { email }, ip });
  if (r1.status !== 202) throw new Error(`request-code ${r1.status}`);
  const code = ctx.email.lastCodeFor(email.toLowerCase());
  if (!code) throw new Error('no code sent');
  const r2 = await call(ctx, 'POST', '/v1/auth/verify-code', {
    body: {
      email,
      code,
      confirmAdult: true,
      termsVersion: TERMS_VERSION,
      privacyVersion: PRIVACY_VERSION,
    },
    ip,
  });
  if (r2.status !== 200) throw new Error(`verify-code ${r2.status} ${JSON.stringify(r2.json)}`);
  return { token: r2.json.token as string, userId: r2.json.user.id as string, email };
}

export async function makeProfile(
  ctx: Ctx,
  s: Session,
  displayName: string,
  handle: string | null = null,
  visibility: 'private' | 'handle' | 'community' = 'private',
): Promise<string> {
  const r = await call(ctx, 'PUT', '/v1/me/profile', {
    token: s.token,
    body: { displayName, handle, visibility },
  });
  if (r.status !== 200) throw new Error(`profile ${r.status} ${JSON.stringify(r.json)}`);
  return r.json.profile.id as string;
}

export async function addChild(
  ctx: Ctx,
  s: Session,
  nickname: string,
  ageBand: 'under13' | 'teen13to17' = 'under13',
): Promise<string> {
  const r = await call(ctx, 'POST', '/v1/guardian/children', {
    token: s.token,
    body: {
      nickname,
      ageBand,
      consent: { version: PARENT_CONSENT_VERSION, isParentOrGuardian: true },
    },
  });
  if (r.status !== 201) throw new Error(`child ${r.status} ${JSON.stringify(r.json)}`);
  return r.json.child.id as string;
}
