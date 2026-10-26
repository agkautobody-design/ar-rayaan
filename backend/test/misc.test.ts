import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { after, before, describe, it } from 'node:test';
import { runRetention } from '../src/jobs/retention.js';
import { addChild, call, makeCtx, makeProfile, signUp, uniqueEmail, type Ctx } from './helpers.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

describe('OpenAPI file matches the routes', () => {
  it('documents every route and nothing else', async () => {
    const ctx = await makeCtx({ env: { AUTH_MODE: 'both', FIREBASE_PROJECT_ID: 'p' } });
    const yaml = await readFile(path.join(root, 'openapi.yaml'), 'utf8');
    const documented = new Set<string>();
    let current = '';
    let inPaths = false;
    for (const line of yaml.split('\n')) {
      if (/^paths:/.test(line)) inPaths = true;
      else if (/^\S/.test(line)) inPaths = false;
      if (!inPaths) continue;
      const p = /^  (\/\S*):\s*$/.exec(line);
      if (p) current = p[1]!;
      const m = /^    (get|post|put|patch|delete):\s*$/.exec(line);
      if (m && current) documented.add(`${m[1]!.toUpperCase()} ${current}`);
    }
    const registered = new Set(
      ctx.app.routeTable
        .filter((r) => r.method !== 'HEAD' && r.method !== 'OPTIONS')
        .map((r) => `${r.method} ${r.url.replace(/:([A-Za-z]+)/g, '{$1}')}`),
    );
    assert.deepEqual([...registered].filter((r) => !documented.has(r)), [], 'routes missing from openapi.yaml');
    assert.deepEqual([...documented].filter((r) => !registered.has(r)), [], 'openapi.yaml documents routes that do not exist');
    await ctx.close();
  });
});

describe('logs hold no personal data', () => {
  let ctx: Ctx;
  before(async () => {
    ctx = await makeCtx();
  });
  after(async () => {
    await ctx.close();
  });

  it('never contains e-mail, code, token, address, names, handles or bodies', async () => {
    const email = uniqueEmail('logcheck');
    const s = await signUp(ctx, email, '203.0.113.77');
    const code = ctx.email.lastCodeFor(email)!;
    await makeProfile(ctx, s, 'Secretive Sam', 'secret_sam', 'handle');
    await addChild(ctx, s, 'Hidden Kid');
    await call(ctx, 'GET', '/v1/me', { token: s.token, ip: '203.0.113.77' });
    await call(ctx, 'POST', '/v1/friends/requests', { token: s.token, body: { handle: 'someone_else' } });
    await call(ctx, 'POST', '/v1/auth/request-code', { body: { email: 'not valid' } });
    ctx.email.failNext = true;
    await call(ctx, 'POST', '/v1/auth/request-code', { body: { email: 'mailfail@example.test' } });
    const all = ctx.logs.join('');
    assert.ok(ctx.logs.length > 5, 'requests are logged');
    for (const secret of [email, 'mailfail@example.test', s.token, '203.0.113.77', 'Secretive Sam', 'secret_sam', 'Hidden Kid', 'someone_else', 'Bearer']) {
      assert.ok(!all.includes(secret), `log leaked ${secret}`);
    }
    assert.ok(!new RegExp(`"code":"?${code}`).test(all));
    const lines = ctx.logs.map((l) => JSON.parse(l) as Record<string, unknown>);
    const req = lines.find((l) => l.msg === 'request' && l.route === '/v1/me');
    assert.ok(req, 'one structured line per request');
    assert.equal(req.method, 'GET');
    assert.equal(req.status, 200);
    assert.match(String(req.actor), /^[0-9a-f]{12}$/);
  });

  it('answers unexpected errors with a plain 500 and no detail', async () => {
    const s = await signUp(ctx);
    await ctx.db.query('alter table consents rename to consents_gone');
    try {
      const r = await call(ctx, 'GET', '/v1/me/export', { token: s.token });
      assert.equal(r.status, 500);
      assert.deepEqual(Object.keys(r.json.error).sort(), ['code', 'message']);
      assert.ok(!JSON.stringify(r.json).includes('consents'));
    } finally {
      await ctx.db.query('alter table consents_gone rename to consents');
    }
  });
});

describe('CORS', () => {
  it('echoes only configured origins', async () => {
    const ctx = await makeCtx({ env: { CORS_ORIGINS: 'https://app.example.test' } });
    const ok = await ctx.app.inject({ method: 'OPTIONS', url: '/v1/me', headers: { origin: 'https://app.example.test' } });
    assert.equal(ok.statusCode, 204);
    assert.equal(ok.headers['access-control-allow-origin'], 'https://app.example.test');
    const no = await ctx.app.inject({ method: 'GET', url: '/healthz', headers: { origin: 'https://evil.example.test' } });
    assert.equal(no.headers['access-control-allow-origin'], undefined);
    await ctx.close();
  });
});

describe('retention', () => {
  it('deletes only what has outlived its window', async () => {
    const ctx = await makeCtx();
    const now = ctx.clock.now();
    const old = new Date(now.getTime() - 40 * 86_400_000);
    await ctx.db.query(`insert into auth_codes (email_hash, code_hash, created_at, expires_at) values ('a','b',$1,$1), ('c','d',$2,$2)`, [old, now]);
    const s = await signUp(ctx);
    await ctx.db.query(`insert into notifications (user_id, kind, created_at) values ($1,'old',$2), ($1,'new',$3)`, [s.userId, new Date(now.getTime() - 100 * 86_400_000), now]);
    const r = await runRetention(ctx.db, now);
    assert.ok(r.authCodes >= 1 && r.notifications === 1);
    const left = await ctx.db.query(`select kind from notifications where user_id = $1`, [s.userId]);
    assert.ok(left.rows.some((x) => x.kind === 'new') && !left.rows.some((x) => x.kind === 'old'));
    await ctx.close();
  });
});
