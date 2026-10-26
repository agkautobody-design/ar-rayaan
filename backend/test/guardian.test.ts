import assert from 'node:assert/strict';
import { after, before, describe, it } from 'node:test';
import { MAX_CHILD_PROFILES_PER_GUARDIAN } from '../src/policy/age.js';
import { PARENT_CONSENT_VERSION } from '../src/versions.js';
import { addChild, call, makeCtx, signUp, type Ctx } from './helpers.js';

describe('guardian: child and teen profiles', () => {
  let ctx: Ctx;
  before(async () => {
    ctx = await makeCtx();
  });
  after(async () => {
    await ctx.close();
  });

  const body = (extra: Record<string, unknown> = {}) => ({
    nickname: 'Little Yusuf',
    ageBand: 'under13',
    consent: { version: PARENT_CONSENT_VERSION, isParentOrGuardian: true },
    ...extra,
  });

  it('adds a child with recorded parent consent; the child is private and has no login', async () => {
    const g = await signUp(ctx);
    const r = await call(ctx, 'POST', '/v1/guardian/children', { token: g.token, body: body() });
    assert.equal(r.status, 201);
    const c = r.json.child;
    assert.equal(c.kind, 'child');
    assert.equal(c.visibility, 'private');
    assert.equal(c.handle, null);
    assert.equal(c.bio, null);
    const row = (await ctx.db.query<Record<string, unknown>>('select * from profiles where id = $1', [c.id])).rows[0]!;
    assert.equal(row.user_id, null);
    assert.equal(row.managed_by, g.userId);
    const link = await ctx.db.query(`select 1 from parental_links where ward_profile_id = $1 and status = 'active'`, [c.id]);
    assert.equal(link.rowCount, 1);
    const consent = await ctx.db.query(
      `select version from consents where user_id = $1 and kind = 'parent_consent' and subject_profile_id = $2`,
      [g.userId, c.id],
    );
    assert.equal(consent.rows[0]?.version, PARENT_CONSENT_VERSION);
    const teen = await call(ctx, 'POST', '/v1/guardian/children', { token: g.token, body: body({ ageBand: 'teen13to17', nickname: 'Big Sis' }) });
    assert.equal(teen.json.child.kind, 'teen');
  });

  it('refuses without the parent confirmation, with an old consent, or a reserved nickname', async () => {
    const g = await signUp(ctx);
    const noConfirm = await call(ctx, 'POST', '/v1/guardian/children', {
      token: g.token,
      body: body({ consent: { version: PARENT_CONSENT_VERSION, isParentOrGuardian: false } }),
    });
    assert.equal(noConfirm.status, 400);
    const old = await call(ctx, 'POST', '/v1/guardian/children', {
      token: g.token,
      body: body({ consent: { version: 'v0', isParentOrGuardian: true } }),
    });
    assert.equal(old.json.error.code, 'consent_outdated');
    const reserved = await call(ctx, 'POST', '/v1/guardian/children', { token: g.token, body: body({ nickname: 'Hadi' }) });
    assert.equal(reserved.json.error.code, 'nickname_invalid');
    const noAge = await call(ctx, 'POST', '/v1/guardian/children', { token: g.token, body: body({ ageBand: 'adult' }) });
    assert.equal(noAge.status, 400, 'an adult band cannot be made through this route');
    assert.equal((await call(ctx, 'POST', '/v1/guardian/children', { body: body() })).status, 401);
  });

  it('caps the number of children per account', async () => {
    const g = await signUp(ctx);
    for (let i = 0; i < MAX_CHILD_PROFILES_PER_GUARDIAN; i += 1) await addChild(ctx, g, `Kid ${String.fromCharCode(65 + i)}`);
    const r = await call(ctx, 'POST', '/v1/guardian/children', { token: g.token, body: body() });
    assert.equal(r.status, 409);
    assert.equal(r.json.error.code, 'child_limit_reached');
  });

  it('lets only the guardian see, rename and delete a child', async () => {
    const g = await signUp(ctx);
    const other = await signUp(ctx);
    const id = await addChild(ctx, g, 'Mine');
    assert.equal((await call(ctx, 'GET', '/v1/guardian/children', { token: other.token })).json.children.length, 0);
    assert.equal((await call(ctx, 'PATCH', `/v1/guardian/children/${id}`, { token: other.token, body: { nickname: 'Stolen' } })).status, 404);
    assert.equal((await call(ctx, 'DELETE', `/v1/guardian/children/${id}`, { token: other.token })).status, 404);
    const ok = await call(ctx, 'PATCH', `/v1/guardian/children/${id}`, { token: g.token, body: { nickname: 'Renamed' } });
    assert.equal(ok.json.child.displayName, 'Renamed');
    assert.equal((await call(ctx, 'DELETE', `/v1/guardian/children/${id}`, { token: g.token })).status, 204);
    assert.equal((await call(ctx, 'GET', '/v1/guardian/children', { token: g.token })).json.children.length, 0);
    assert.equal((await call(ctx, 'DELETE', `/v1/guardian/children/not-a-uuid`, { token: g.token })).status, 404);
  });

  it('writes audit entries that hold ids only', async () => {
    const g = await signUp(ctx);
    const id = await addChild(ctx, g, 'Audited Kid');
    const rows = await ctx.db.query<{ meta: unknown; target_id: string }>(
      `select meta, target_id from audit_log where action = 'guardian.child_added' and actor_user_id = $1`,
      [g.userId],
    );
    assert.equal(rows.rows[0]?.target_id, id);
    assert.ok(!JSON.stringify(rows.rows).includes('Audited Kid'));
  });
});
