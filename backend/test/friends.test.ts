import assert from 'node:assert/strict';
import { after, before, describe, it } from 'node:test';
import { addChild, call, makeCtx, makeProfile, signUp, type Ctx, type Session } from './helpers.js';

describe('friends', () => {
  let ctx: Ctx;
  before(async () => {
    ctx = await makeCtx({ env: { SESSION_TTL_DAYS: '90' } });
  });
  after(async () => {
    await ctx.close();
  });

  let n = 0;
  const person = async (visibility: 'private' | 'handle' | 'community' = 'handle') => {
    const s = await signUp(ctx);
    n += 1;
    const handle = `friend_${n}_x`;
    const profileId = await makeProfile(ctx, s, `Person ${n}`, handle, visibility);
    return { s, handle, profileId };
  };
  const ask = (from: Session, handle: string) =>
    call(ctx, 'POST', '/v1/friends/requests', { token: from.token, body: { handle } });

  it('request by handle, accept, list, remove', async () => {
    const a = await person();
    const b = await person();
    const r = await ask(a.s, b.handle);
    assert.equal(r.status, 201);
    const bList = await call(ctx, 'GET', '/v1/friends', { token: b.s.token });
    assert.equal(bList.json.incoming.length, 1);
    assert.equal((await call(ctx, 'GET', '/v1/friends', { token: a.s.token })).json.outgoing.length, 1);
    // The requester cannot accept their own request.
    assert.equal((await call(ctx, 'POST', `/v1/friends/requests/${r.json.friendship.id}/accept`, { token: a.s.token })).status, 404);
    const acc = await call(ctx, 'POST', `/v1/friends/requests/${r.json.friendship.id}/accept`, { token: b.s.token });
    assert.equal(acc.json.friendship.status, 'accepted');
    const aList = await call(ctx, 'GET', '/v1/friends', { token: a.s.token });
    assert.equal(aList.json.friends.length, 1);
    assert.equal(aList.json.friends[0].profile.id, b.profileId);
    const notes = await ctx.db.query(`select kind from notifications where user_id = $1`, [a.s.userId]);
    assert.ok(notes.rows.some((x) => x.kind === 'friend_accepted'));
    assert.equal((await call(ctx, 'DELETE', `/v1/friends/${r.json.friendship.id}`, { token: a.s.token })).status, 204);
    assert.equal((await call(ctx, 'GET', '/v1/friends', { token: b.s.token })).json.friends.length, 0);
  });

  it('does not reveal private profiles: they cannot be found by handle', async () => {
    const a = await person();
    const hidden = await person('private');
    const missing = await ask(a.s, 'no_such_handle');
    const priv = await ask(a.s, hidden.handle);
    assert.equal(priv.status, 404);
    assert.deepEqual(priv.json, missing.json, 'same answer as a handle that does not exist');
  });

  it('needs a profile first, and refuses friending yourself', async () => {
    const bare = await signUp(ctx);
    const b = await person();
    assert.equal((await ask(bare, b.handle)).json.error.code, 'profile_required');
    assert.equal((await ask(b.s, b.handle)).json.error.code, 'cannot_friend_self');
  });

  it('declined requests cannot be repeated for 30 days; the other side may still ask', async () => {
    const a = await person();
    const b = await person();
    const r = await ask(a.s, b.handle);
    await call(ctx, 'POST', `/v1/friends/requests/${r.json.friendship.id}/decline`, { token: b.s.token });
    assert.equal((await ask(a.s, b.handle)).json.error.code, 'request_declined_recently');
    ctx.clock.advanceMs(31 * 86_400_000);
    assert.equal((await ask(a.s, b.handle)).status, 201);
  });

  it('rejects duplicate requests and existing friends', async () => {
    const a = await person();
    const b = await person();
    const r = await ask(a.s, b.handle);
    assert.equal((await ask(a.s, b.handle)).json.error.code, 'request_pending');
    await call(ctx, 'POST', `/v1/friends/requests/${r.json.friendship.id}/accept`, { token: b.s.token });
    assert.equal((await ask(b.s, a.handle)).json.error.code, 'already_friends');
  });

  it('blocking removes the friendship and hides each side from the other', async () => {
    const a = await person();
    const b = await person();
    const r = await ask(a.s, b.handle);
    await call(ctx, 'POST', `/v1/friends/requests/${r.json.friendship.id}/accept`, { token: b.s.token });
    const blk = await call(ctx, 'POST', '/v1/blocks', { token: b.s.token, body: { profileId: a.profileId } });
    assert.equal(blk.status, 204);
    assert.equal((await call(ctx, 'GET', '/v1/friends', { token: a.s.token })).json.friends.length, 0);
    assert.equal((await ask(a.s, b.handle)).status, 404, 'blocked person sees "not found"');
    assert.equal((await ask(b.s, a.handle)).status, 404);
    assert.equal((await call(ctx, 'GET', '/v1/blocks', { token: b.s.token })).json.blocks.length, 1);
    assert.equal((await call(ctx, 'DELETE', `/v1/blocks/${a.profileId}`, { token: b.s.token })).status, 204);
    assert.equal((await ask(a.s, b.handle)).status, 201);
  });

  it('rate-limits friend requests per person per day', async () => {
    const a = await person();
    const targets = [];
    for (let i = 0; i < 21; i += 1) targets.push(await person());
    let limited = 0;
    for (const t of targets) if ((await ask(a.s, t.handle)).status === 429) limited += 1;
    assert.equal(limited, 1);
  });

  it('children cannot use the handle route, and guardians see only their own child\'s list', async () => {
    const g = await signUp(ctx);
    await makeProfile(ctx, g, 'Parent One', 'parent_one', 'handle');
    const kid = await addChild(ctx, g, 'Kid');
    const other = await signUp(ctx);
    // There is no way to pass a child as the requester.
    const r = await call(ctx, 'POST', '/v1/friends/requests', { token: g.token, body: { handle: 'parent_one', asProfileId: kid } });
    assert.equal(r.status, 409, 'extra fields are ignored; the adult profile asked itself');
    assert.equal((await call(ctx, 'GET', `/v1/friends?profileId=${kid}`, { token: g.token })).status, 200);
    assert.equal((await call(ctx, 'GET', `/v1/friends?profileId=${kid}`, { token: other.token })).status, 404);
    // An adult cannot find a child: children have no handle at all.
    const asker = await person();
    const rows = await ctx.db.query(`select handle from profiles where id = $1`, [kid]);
    assert.equal(rows.rows[0]?.handle, null);
    assert.equal((await ask(asker.s, 'kid')).status, 404);
  });
});
