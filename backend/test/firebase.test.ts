import assert from 'node:assert/strict';
import { createSign, generateKeyPairSync } from 'node:crypto';
import { after, before, describe, it } from 'node:test';
import { FirebaseVerifier, JWKS_URL, TokenRejected } from '../src/firebaseVerifier.js';
import { PRIVACY_VERSION, TERMS_VERSION } from '../src/versions.js';
import { call, makeCtx, signUp, uniqueEmail, type Ctx } from './helpers.js';

const PROJECT = 'ar-rayaan-test';
const KID = 'kid-1';

const { privateKey, publicKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
const other = generateKeyPairSync('rsa', { modulusLength: 2048 });
const jwk = { ...(publicKey.export({ format: 'jwk' }) as object), kid: KID, alg: 'RS256', use: 'sig' };

function b64(o: unknown): string {
  return Buffer.from(JSON.stringify(o)).toString('base64url');
}

function makeToken(
  nowSec: number,
  over: Record<string, unknown> = {},
  key = privateKey,
  header: Record<string, unknown> = {},
): string {
  const h = b64({ alg: 'RS256', kid: KID, typ: 'JWT', ...header });
  const p = b64({
    iss: `https://securetoken.google.com/${PROJECT}`,
    aud: PROJECT,
    sub: 'fb-uid-1',
    iat: nowSec - 10,
    exp: nowSec + 3000,
    email: 'person@example.test',
    email_verified: true,
    firebase: { sign_in_provider: 'password' },
    ...over,
  });
  const sig = createSign('RSA-SHA256').update(`${h}.${p}`).sign(key).toString('base64url');
  return `${h}.${p}.${sig}`;
}

describe('Firebase ID-token verification', () => {
  const now = new Date('2026-11-01T12:00:00Z');
  const nowSec = Math.floor(now.getTime() / 1000);
  let fetches = 0;
  const verifier = () =>
    new FirebaseVerifier(PROJECT, () => now, async (url) => {
      assert.equal(url, JWKS_URL);
      fetches += 1;
      return new Response(JSON.stringify({ keys: [jwk] }), {
        status: 200,
        headers: { 'cache-control': 'public, max-age=3600' },
      });
    });
  const reason = async (t: string) => {
    try {
      await verifier().verify(t);
      return 'accepted';
    } catch (e) {
      assert.ok(e instanceof TokenRejected);
      return e.reason;
    }
  };

  it('accepts a good token and caches the keys', async () => {
    const v = verifier();
    const id = await v.verify(makeToken(nowSec));
    assert.deepEqual(id, { uid: 'fb-uid-1', email: 'person@example.test', emailVerified: true });
    const before = fetches;
    await v.verify(makeToken(nowSec));
    assert.equal(fetches, before, 'second verify used the cached keys');
  });

  it('rejects every kind of bad token', async () => {
    assert.equal(await reason(makeToken(nowSec, { aud: 'other' })), 'bad_audience');
    assert.equal(await reason(makeToken(nowSec, { iss: 'https://securetoken.google.com/other' })), 'bad_issuer');
    assert.equal(await reason(makeToken(nowSec, { exp: nowSec - 600 })), 'expired');
    assert.equal(await reason(makeToken(nowSec, { iat: nowSec + 600 })), 'issued_in_future');
    assert.equal(await reason(makeToken(nowSec, { sub: '' })), 'bad_subject');
    assert.equal(await reason(makeToken(nowSec, { firebase: { sign_in_provider: 'anonymous' } })), 'anonymous');
    assert.equal(await reason(makeToken(nowSec, { email: undefined })), 'no_email');
    assert.equal(await reason(makeToken(nowSec, {}, other.privateKey)), 'bad_signature');
    assert.equal(await reason(makeToken(nowSec, {}, privateKey, { alg: 'none' })), 'bad_alg');
    assert.equal(await reason(makeToken(nowSec, {}, privateKey, { kid: 'unknown' })), 'unknown_key');
    assert.equal(await reason('a.b'), 'malformed');
    assert.equal(await reason('x'.repeat(5000)), 'malformed');
  });
});

describe('POST /v1/auth/firebase', () => {
  let ctx: Ctx;
  let nowSec: number;
  before(async () => {
    const clock = new Date('2026-11-01T12:00:00Z');
    nowSec = Math.floor(clock.getTime() / 1000);
    const verifier = new FirebaseVerifier(PROJECT, () => clock, async () =>
      new Response(JSON.stringify({ keys: [jwk] }), { status: 200 }));
    ctx = await makeCtx({ env: { AUTH_MODE: 'both', FIREBASE_PROJECT_ID: PROJECT }, firebase: verifier });
  });
  after(async () => {
    await ctx.close();
  });

  const body = (idToken: string, extra: Record<string, unknown> = {}) => ({
    idToken,
    confirmAdult: true,
    termsVersion: TERMS_VERSION,
    privacyVersion: PRIVACY_VERSION,
    ...extra,
  });

  it('creates an account from a Firebase identity, then signs the same person in again', async () => {
    const email = uniqueEmail('fb');
    const tok = makeToken(nowSec, { sub: 'fb-new', email });
    const noAdult = await call(ctx, 'POST', '/v1/auth/firebase', { body: body(tok, { confirmAdult: false }) });
    assert.equal(noAdult.status, 422);
    const first = await call(ctx, 'POST', '/v1/auth/firebase', { body: body(tok) });
    assert.equal(first.status, 200);
    assert.equal(first.json.isNewAccount, true);
    const me = await call(ctx, 'GET', '/v1/me', { token: first.json.token });
    assert.equal(me.json.user.email, email);
    const again = await call(ctx, 'POST', '/v1/auth/firebase', { body: { idToken: tok } });
    assert.equal(again.status, 200);
    assert.equal(again.json.isNewAccount, false);
    assert.equal(again.json.user.id, first.json.user.id);
  });

  it('refuses anonymous, unverified and forged tokens', async () => {
    const anon = makeToken(nowSec, { firebase: { sign_in_provider: 'anonymous' } });
    assert.equal((await call(ctx, 'POST', '/v1/auth/firebase', { body: body(anon) })).status, 401);
    const unverified = makeToken(nowSec, { email_verified: false, sub: 'fb-unv', email: uniqueEmail('unv') });
    const r = await call(ctx, 'POST', '/v1/auth/firebase', { body: body(unverified) });
    assert.equal(r.status, 422);
    assert.equal(r.json.error.code, 'email_not_verified');
    const forged = makeToken(nowSec, {}, other.privateKey);
    assert.equal((await call(ctx, 'POST', '/v1/auth/firebase', { body: body(forged) })).status, 401);
  });

  it('links a Firebase identity to an account first made with an e-mail code', async () => {
    const s = await signUp(ctx);
    const tok = makeToken(nowSec, { sub: 'fb-link', email: s.email });
    const r = await call(ctx, 'POST', '/v1/auth/firebase', { body: { idToken: tok } });
    assert.equal(r.status, 200);
    assert.equal(r.json.user.id, s.userId);
  });

  it('does not let a suspended account in through Firebase', async () => {
    const email = uniqueEmail('fbsus');
    const tok = makeToken(nowSec, { sub: 'fb-sus', email });
    const r = await call(ctx, 'POST', '/v1/auth/firebase', { body: body(tok) });
    await ctx.db.query(`update users set status = 'suspended' where id = $1`, [r.json.user.id]);
    assert.equal((await call(ctx, 'POST', '/v1/auth/firebase', { body: { idToken: tok } })).status, 403);
  });

  it('removes the e-mail-code routes in firebase-only mode, and the firebase route in email-only mode', async () => {
    const fbOnly = await makeCtx({ env: { AUTH_MODE: 'firebase', FIREBASE_PROJECT_ID: PROJECT } });
    assert.equal((await call(fbOnly, 'POST', '/v1/auth/request-code', { body: { email: 'a@b.test' } })).status, 404);
    await fbOnly.close();
    const emailOnly = await makeCtx();
    assert.equal((await call(emailOnly, 'POST', '/v1/auth/firebase', { body: { idToken: 'x'.repeat(30) } })).status, 404);
    await emailOnly.close();
  });
});
