import assert from 'node:assert/strict';
import { after, before, describe, it } from 'node:test';
import { MAX_CODE_ATTEMPTS } from '../src/auth.js';
import { ResendEmailSender } from '../src/email.js';
import { PRIVACY_VERSION, TERMS_VERSION } from '../src/versions.js';
import { call, makeCtx, signUp, uniqueEmail, type Ctx } from './helpers.js';

describe('auth', () => {
  let ctx: Ctx;
  before(async () => {
    ctx = await makeCtx();
  });
  after(async () => {
    await ctx.close();
  });

  const verifyBody = (email: string, code: string, extra: Record<string, unknown> = {}) => ({
    email,
    code,
    confirmAdult: true,
    termsVersion: TERMS_VERSION,
    privacyVersion: PRIVACY_VERSION,
    ...extra,
  });

  it('health endpoints work and set strict headers', async () => {
    const h = await call(ctx, 'GET', '/healthz');
    assert.equal(h.status, 200);
    assert.deepEqual(h.json, { status: 'ok' });
    assert.equal(h.headers['x-content-type-options'], 'nosniff');
    assert.equal(h.headers['cache-control'], 'no-store');
    const r = await call(ctx, 'GET', '/readyz');
    assert.equal(r.status, 200);
  });

  it('signs a new person up and in with an e-mailed code', async () => {
    const email = uniqueEmail('new');
    const s = await signUp(ctx, email);
    assert.match(s.token, /^ar_/);
    const me = await call(ctx, 'GET', '/v1/me', { token: s.token });
    assert.equal(me.status, 200);
    assert.equal(me.json.user.email, email);
    assert.equal(me.json.profile, null);

    // Signing in again does not create a second account.
    const again = await signUp(ctx, email);
    assert.equal(again.userId, s.userId);
    const rows = await ctx.db.query('select 1 from consents where user_id = $1', [s.userId]);
    assert.equal(rows.rowCount, 2); // terms + privacy, recorded once
  });

  it('answers request-code the same for unknown and known addresses', async () => {
    const known = await signUp(ctx);
    const a = await call(ctx, 'POST', '/v1/auth/request-code', { body: { email: known.email } });
    const b = await call(ctx, 'POST', '/v1/auth/request-code', { body: { email: uniqueEmail('ghost') } });
    assert.equal(a.status, 202);
    assert.equal(b.status, 202);
    assert.deepEqual(a.json, b.json);
  });

  it('stores only hashes: no token and no plain code column in the database', async () => {
    const s = await signUp(ctx);
    const sessions = JSON.stringify((await ctx.db.query('select * from sessions')).rows);
    assert.ok(!sessions.includes(s.token));
    const cols = await ctx.db.query<{ column_name: string }>(
      `select column_name from information_schema.columns where table_name = 'auth_codes'`,
    );
    const names = cols.rows.map((c) => c.column_name);
    assert.ok(names.includes('code_hash') && !names.includes('code'));
  });

  it('requires adult confirmation and the current texts to create an account', async () => {
    const email = uniqueEmail('adult');
    await call(ctx, 'POST', '/v1/auth/request-code', { body: { email } });
    const code = ctx.email.lastCodeFor(email)!;
    const noAdult = await call(ctx, 'POST', '/v1/auth/verify-code', {
      body: verifyBody(email, code, { confirmAdult: false }),
    });
    assert.equal(noAdult.status, 422);
    assert.equal(noAdult.json.error.code, 'adult_confirmation_required');
    const oldTerms = await call(ctx, 'POST', '/v1/auth/verify-code', {
      body: verifyBody(email, code, { termsVersion: 'old' }),
    });
    assert.equal(oldTerms.status, 422);
    assert.equal(oldTerms.json.error.code, 'consent_outdated');
    // The code survived those refusals and still works.
    const ok = await call(ctx, 'POST', '/v1/auth/verify-code', { body: verifyBody(email, code) });
    assert.equal(ok.status, 200);
    assert.equal(ok.json.isNewAccount, true);
  });

  it('rejects wrong codes and burns the code after too many attempts', async () => {
    const email = uniqueEmail('wrong');
    await call(ctx, 'POST', '/v1/auth/request-code', { body: { email } });
    const code = ctx.email.lastCodeFor(email)!;
    const wrong = code === '000000' ? '111111' : '000000';
    for (let i = 0; i < MAX_CODE_ATTEMPTS; i += 1) {
      const r = await call(ctx, 'POST', '/v1/auth/verify-code', { body: verifyBody(email, wrong) });
      assert.equal(r.status, 401);
    }
    const afterBurn = await call(ctx, 'POST', '/v1/auth/verify-code', { body: verifyBody(email, code) });
    assert.equal(afterBurn.status, 401);
  });

  it('expires codes and allows each only once', async () => {
    const email = uniqueEmail('expiry');
    await call(ctx, 'POST', '/v1/auth/request-code', { body: { email } });
    const code = ctx.email.lastCodeFor(email)!;
    ctx.clock.advanceMs(11 * 60_000);
    const late = await call(ctx, 'POST', '/v1/auth/verify-code', { body: verifyBody(email, code) });
    assert.equal(late.status, 401);

    const email2 = uniqueEmail('once');
    await call(ctx, 'POST', '/v1/auth/request-code', { body: { email: email2 } });
    const code2 = ctx.email.lastCodeFor(email2)!;
    const first = await call(ctx, 'POST', '/v1/auth/verify-code', { body: verifyBody(email2, code2) });
    assert.equal(first.status, 200);
    const second = await call(ctx, 'POST', '/v1/auth/verify-code', { body: verifyBody(email2, code2) });
    assert.equal(second.status, 401);
  });

  it('limits code requests per address and per network address', async () => {
    const email = uniqueEmail('flood');
    for (let i = 0; i < 5; i += 1) {
      const r = await call(ctx, 'POST', '/v1/auth/request-code', { body: { email }, ip: '10.9.9.9' });
      assert.equal(r.status, 202);
    }
    const sixth = await call(ctx, 'POST', '/v1/auth/request-code', { body: { email }, ip: '10.9.9.9' });
    assert.equal(sixth.status, 429);
    assert.equal(sixth.json.error.code, 'rate_limited');

    for (let i = 0; i < 4; i += 1) {
      await call(ctx, 'POST', '/v1/auth/request-code', { body: { email: uniqueEmail('ip') }, ip: '10.8.8.8' });
    }
    // 10 per hour per IP: five were used by the first loop? (different ip) - use a new one.
    let blocked = 0;
    for (let i = 0; i < 12; i += 1) {
      const r = await call(ctx, 'POST', '/v1/auth/request-code', { body: { email: uniqueEmail('ip2') }, ip: '10.7.7.7' });
      if (r.status === 429) {
        blocked += 1;
        assert.ok(Number(r.headers['retry-after']) > 0);
      }
    }
    assert.equal(blocked, 2);
  });

  it('rejects malformed input without echoing it', async () => {
    const r = await call(ctx, 'POST', '/v1/auth/request-code', { body: { email: 'not an email' } });
    assert.equal(r.status, 400);
    assert.equal(r.json.error.code, 'validation_failed');
    assert.ok(!JSON.stringify(r.json).includes('not an email'));
    const big = await call(ctx, 'POST', '/v1/auth/request-code', { body: { email: 'a@b.co', pad: 'x'.repeat(20_000) } });
    assert.equal(big.status, 413);
  });

  it('logs out, lists and revokes sessions', async () => {
    const s = await signUp(ctx);
    const second = await signUp(ctx, s.email);
    const list = await call(ctx, 'GET', '/v1/auth/sessions', { token: s.token });
    assert.equal(list.json.sessions.length, 2);
    assert.equal(list.json.sessions.filter((x: { current: boolean }) => x.current).length, 1);
    const other = list.json.sessions.find((x: { current: boolean }) => !x.current);
    const del = await call(ctx, 'DELETE', `/v1/auth/sessions/${other.id}`, { token: s.token });
    assert.equal(del.status, 204);
    assert.equal((await call(ctx, 'GET', '/v1/me', { token: second.token })).status, 401);
    assert.equal((await call(ctx, 'POST', '/v1/auth/logout', { token: s.token })).status, 204);
    assert.equal((await call(ctx, 'GET', '/v1/me', { token: s.token })).status, 401);
  });

  it('refuses missing, malformed and expired tokens', async () => {
    assert.equal((await call(ctx, 'GET', '/v1/me')).status, 401);
    assert.equal((await call(ctx, 'GET', '/v1/me', { token: 'ar_nonsense' })).status, 401);
    assert.equal((await call(ctx, 'GET', '/v1/me', { token: 'x'.repeat(300) })).status, 401);
    const s = await signUp(ctx);
    ctx.clock.advanceMs(31 * 86_400_000);
    assert.equal((await call(ctx, 'GET', '/v1/me', { token: s.token })).status, 401);
  });

  it('blocks suspended and banned accounts at sign-in and on every request', async () => {
    const s = await signUp(ctx);
    await ctx.db.query(`update users set status = 'suspended' where id = $1`, [s.userId]);
    const r = await call(ctx, 'GET', '/v1/me', { token: s.token });
    assert.equal(r.status, 403);
    assert.equal(r.json.error.code, 'account_restricted');
    await call(ctx, 'POST', '/v1/auth/request-code', { body: { email: s.email } });
    const code = ctx.email.lastCodeFor(s.email)!;
    const v = await call(ctx, 'POST', '/v1/auth/verify-code', { body: verifyBody(s.email, code) });
    assert.equal(v.status, 403);
  });

  it('returns 502 and leaves no code behind when the mail provider fails', async () => {
    const email = uniqueEmail('mailfail');
    ctx.email.failNext = true;
    const r = await call(ctx, 'POST', '/v1/auth/request-code', { body: { email } });
    assert.equal(r.status, 502);
    assert.equal(r.json.error.code, 'email_unavailable');
    const left = await ctx.db.query('select 1 from auth_codes where email_hash = $1', [
      (await import('../src/security.js')).emailHash(ctx.config.pepper, email),
    ]);
    assert.equal(left.rowCount, 0);
  });
});

describe('ResendEmailSender', () => {
  it('posts the message with the key and reports status only on failure', async () => {
    const seen: { url: string; init: RequestInit }[] = [];
    const ok = new ResendEmailSender('KEY', 'Ar-Rayaan <a@b.test>', (async (url: string, init: RequestInit) => {
      seen.push({ url, init });
      return new Response('{}', { status: 200 });
    }) as unknown as typeof fetch);
    await ok.sendSignInCode('who@example.test', '123456', 10);
    assert.equal(seen[0]!.url, 'https://api.resend.com/emails');
    assert.equal((seen[0]!.init.headers as Record<string, string>).authorization, 'Bearer KEY');
    const payload = JSON.parse(String(seen[0]!.init.body));
    assert.deepEqual(payload.to, ['who@example.test']);
    assert.match(payload.text, /123456/);
    assert.ok(!/https?:\/\//.test(payload.text), 'the message carries no links');

    const bad = new ResendEmailSender('KEY', 'x', (async () =>
      new Response('who@example.test is invalid', { status: 422 })) as unknown as typeof fetch);
    await assert.rejects(bad.sendSignInCode('who@example.test', '1', 10), (e: Error) => {
      assert.match(e.message, /422/);
      assert.ok(!e.message.includes('who@example.test'));
      return true;
    });
  });
});
