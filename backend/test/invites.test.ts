import assert from 'node:assert/strict';
import { after, before, describe, it } from 'node:test';
import { MAX_ACTIVE_INVITES, MAX_FAILED_CODE_LOOKUPS_PER_HOUR } from '../src/invites.js';
import { addChild, call, makeCtx, makeProfile, signUp, type Ctx, type Session } from './helpers.js';

describe('invites', () => {
  let ctx: Ctx;
  before(async () => {
    ctx = await makeCtx();
  });
  after(async () => {
    await ctx.close();
  });

  let n = 0;
  const adult = async () => {
    const s = await signUp(ctx);
    n += 1;
    const profileId = await makeProfile(ctx, s, `Adult ${n}`);
    return { s, profileId };
  };
  const invite = async (s: Session, body: Record<string, unknown> = {}) => {
    const r = await call(ctx, 'POST', '/v1/invites', { token: s.token, body });
    assert.equal(r.status, 201, JSON.stringify(r.json));
    return r.json.invite as { id: string; code: string; link: string; expiresAt: string };
  };
  const redeem = (s: Session, code: string, asProfileId?: string) =>
    call(ctx, 'POST', '/v1/invites/redeem', { token: s.token, body: { code, ...(asProfileId ? { asProfileId } : {}) } });

  it('two adults become friends with an invite code, and the code is not stored', async () => {
    const a = await adult();
    const b = await adult();
    const inv = await invite(a.s);
    assert.match(inv.code, /^[2-9A-Z]{5}-[2-9A-Z]{5}$/);
    assert.ok(inv.link.endsWith(`/#/join/${inv.code}`));
    const dump = JSON.stringify((await ctx.db.query('select * from invites')).rows);
    assert.ok(!dump.includes(inv.code.replace('-', '')));

    const pv = await call(ctx, 'POST', '/v1/invites/preview', { token: b.s.token, body: { code: inv.code.toLowerCase() } });
    assert.equal(pv.status, 200);
    assert.equal(pv.json.invite.inviterDisplayName.startsWith('Adult'), true);
    assert.equal(pv.json.invite.familyInvite, false);

    const r = await redeem(b.s, inv.code);
    assert.equal(r.status, 200);
    assert.equal(r.json.friendship.status, 'accepted');
    assert.equal((await call(ctx, 'GET', '/v1/friends', { token: a.s.token })).json.friends.length, 1);
    // Single use.
    const c = await adult();
    assert.equal((await redeem(c.s, inv.code)).status, 404);
  });

  it('refuses your own invite, a repeat, expired, revoked and unknown codes - all with the same answer', async () => {
    const a = await adult();
    const b = await adult();
    const own = await invite(a.s);
    assert.equal((await redeem(a.s, own.code)).json.error.code, 'own_invite');

    const multi = await invite(a.s, { maxUses: 3 });
    assert.equal((await redeem(b.s, multi.code)).status, 200);
    assert.equal((await redeem(b.s, multi.code)).json.error.code, 'already_redeemed');

    const c = await adult();
    const revoked = await invite(a.s);
    assert.equal((await call(ctx, 'DELETE', `/v1/invites/${revoked.id}`, { token: a.s.token })).status, 204);
    const revokedAnswer = await redeem(c.s, revoked.code);

    const short = await invite(a.s, { ttlHours: 1 });
    ctx.clock.advanceMs(2 * 3_600_000);
    const expiredAnswer = await redeem(c.s, short.code);
    const unknownAnswer = await redeem(c.s, 'ABCDE-FGHJK');
    for (const r of [revokedAnswer, expiredAnswer, unknownAnswer]) {
      assert.equal(r.status, 404);
      assert.deepEqual(r.json, unknownAnswer.json);
    }
  });

  it('locks out someone who keeps guessing codes', async () => {
    const a = await adult();
    for (let i = 0; i < MAX_FAILED_CODE_LOOKUPS_PER_HOUR; i += 1) {
      const r = await redeem(a.s, `GUESS${i}-ABCDE`.slice(0, 11).replace(/[01IOLU]/g, 'X'));
      assert.equal(r.status, 404);
    }
    assert.equal((await redeem(a.s, 'ABCDE-FGHJK')).status, 429);
    assert.equal((await call(ctx, 'POST', '/v1/invites/preview', { token: a.s.token, body: { code: 'ABCDE-FGHJK' } })).status, 429);
  });

  it('caps active invites', async () => {
    const a = await adult();
    for (let i = 0; i < MAX_ACTIVE_INVITES; i += 1) await invite(a.s, { ttlHours: 24 });
    const over = await call(ctx, 'POST', '/v1/invites', { token: a.s.token, body: {} });
    assert.equal(over.status, 409);
    assert.equal(over.json.error.code, 'invite_limit_reached');
  });

  it('lists my invites without codes', async () => {
    const a = await adult();
    await invite(a.s);
    const l = await call(ctx, 'GET', '/v1/invites', { token: a.s.token });
    assert.equal(l.json.invites.length, 1);
    assert.equal(l.json.invites[0].active, true);
    assert.ok(!('code' in l.json.invites[0]));
  });

  describe('children', () => {
    it('two guardians connect their children; both approvals are recorded', async () => {
      const g1 = await signUp(ctx);
      const g2 = await signUp(ctx);
      const k1 = await addChild(ctx, g1, 'Yusuf');
      const k2 = await addChild(ctx, g2, 'Maryam');
      const inv = await invite(g1, { asProfileId: k1, maxUses: 5 });
      const meta = await ctx.db.query('select max_uses from invites where id = $1', [inv.id]);
      assert.equal(meta.rows[0]?.max_uses, 1, "a child's invite works once");

      const pv = await call(ctx, 'POST', '/v1/invites/preview', { token: g2.token, body: { code: inv.code } });
      assert.equal(pv.json.invite.familyInvite, true);
      assert.equal(pv.json.invite.inviterDisplayName, null, "a child's name is not shown before redeeming");

      const r = await redeem(g2, inv.code, k2);
      assert.equal(r.status, 200);
      const f = (await ctx.db.query<Record<string, unknown>>('select * from friendships where id = $1', [r.json.friendship.id])).rows[0]!;
      assert.equal(f.status, 'accepted');
      assert.ok(f.guardian_lo_at && f.guardian_hi_at, 'a guardian approved each side');
      const approvers = new Set([f.guardian_lo_user, f.guardian_hi_user]);
      assert.deepEqual(approvers, new Set([g1.userId, g2.userId]));

      assert.equal((await call(ctx, 'GET', `/v1/friends?profileId=${k2}`, { token: g2.token })).json.friends.length, 1);
      assert.equal((await call(ctx, 'GET', `/v1/friends?profileId=${k1}`, { token: g2.token })).status, 404);
    });

    it('siblings under one guardian can be connected', async () => {
      const g = await signUp(ctx);
      const k1 = await addChild(ctx, g, 'Sib One');
      const k2 = await addChild(ctx, g, 'Sib Two');
      const inv = await invite(g, { asProfileId: k1 });
      assert.equal((await redeem(g, inv.code, k2)).status, 200);
      const inv2 = await invite(g, { asProfileId: k1 });
      assert.equal((await redeem(g, inv2.code, k1)).json.error.code, 'own_invite');
    });

    it('an adult can never be connected to a child, in either direction', async () => {
      const g = await signUp(ctx);
      const kid = await addChild(ctx, g, 'Protected');
      const stranger = await adult();
      const childInv = await invite(g, { asProfileId: kid });
      const asAdult = await redeem(stranger.s, childInv.code);
      assert.equal(asAdult.status, 403);
      assert.equal(asAdult.json.error.code, 'not_allowed');
      assert.ok(!JSON.stringify(asAdult.json).includes('Protected'));

      // An adult's invite redeemed on behalf of a child.
      const g2 = await signUp(ctx);
      const kid2 = await addChild(ctx, g2, 'Other Kid');
      const adultInv = await invite(stranger.s);
      assert.equal((await redeem(g2, adultInv.code, kid2)).status, 403);
      // And nothing was created.
      const rows = await ctx.db.query(`select 1 from friendships where profile_lo = $1 or profile_hi = $1 or profile_lo = $2 or profile_hi = $2`, [kid, kid2]);
      assert.equal(rows.rowCount, 0);
    });

    it("a stranger cannot act as someone else's child", async () => {
      const g = await signUp(ctx);
      const kid = await addChild(ctx, g, 'Mine Only');
      const other = await adult();
      const inv = await invite(other.s);
      assert.equal((await redeem(g, inv.code, kid)).status, 403);
      const g2 = await signUp(ctx);
      assert.equal((await call(ctx, 'POST', '/v1/invites', { token: g2.token, body: { asProfileId: kid } })).status, 404);
    });
  });
});
