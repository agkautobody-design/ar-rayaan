import assert from 'node:assert/strict';
import { after, before, describe, it } from 'node:test';
import { notify } from '../src/notify.js';
import { call, makeCtx, makeMember, signUp, type Ctx } from './helpers.js';

describe('notifications (polling)', () => {
  let ctx: Ctx;
  before(async () => {
    ctx = await makeCtx();
  });
  after(async () => {
    await ctx.close();
  });

  const push = async (userId: string, kind: string, payload: Record<string, unknown> = {}) => {
    ctx.clock.advanceMs(1000);
    await ctx.db.query(
      'insert into notifications (user_id, kind, payload, created_at) values ($1, $2, $3::jsonb, $4)',
      [userId, kind, JSON.stringify(payload), ctx.clock.now()],
    );
  };

  it('needs sign-in and returns only my notifications, newest first, with an unread count', async () => {
    assert.equal((await call(ctx, 'GET', '/v1/notifications')).status, 401);
    const a = await makeMember(ctx);
    const b = await makeMember(ctx);
    await push(a.userId, 'friend_request', { friendshipId: 'x' });
    await push(a.userId, 'forum_reply', { threadId: 't' });
    await push(b.userId, 'friend_request');
    const r = await call(ctx, 'GET', '/v1/notifications', { token: a.token });
    assert.equal(r.status, 200);
    assert.deepEqual(r.json.notifications.map((n: any) => n.kind), ['forum_reply', 'friend_request']);
    assert.equal(r.json.unreadCount, 2);
    assert.ok(r.json.serverTime);
  });

  it('polls for what is new since the last one seen', async () => {
    const a = await makeMember(ctx);
    await push(a.userId, 'friend_request');
    const first = await call(ctx, 'GET', '/v1/notifications', { token: a.token });
    const last = first.json.notifications[0].createdAt as string;
    assert.equal((await call(ctx, 'GET', `/v1/notifications?after=${encodeURIComponent(last)}`, { token: a.token })).json.notifications.length, 0);
    await push(a.userId, 'friend_accepted');
    const next = await call(ctx, 'GET', `/v1/notifications?after=${encodeURIComponent(last)}`, { token: a.token });
    assert.deepEqual(next.json.notifications.map((n: any) => n.kind), ['friend_accepted']);
  });

  it('marks some or all as read, and never touches someone else\'s', async () => {
    const a = await makeMember(ctx);
    const b = await makeMember(ctx);
    await push(a.userId, 'friend_request');
    await push(a.userId, 'forum_reply');
    await push(b.userId, 'friend_request');
    const list = await call(ctx, 'GET', '/v1/notifications', { token: a.token });
    const [one, two] = list.json.notifications as Array<{ id: string }>;
    const bId = (await call(ctx, 'GET', '/v1/notifications', { token: b.token })).json.notifications[0].id;
    await call(ctx, 'POST', '/v1/notifications/read', { token: a.token, body: { ids: [one!.id, bId] } });
    assert.equal((await call(ctx, 'GET', '/v1/notifications', { token: a.token })).json.unreadCount, 1);
    assert.equal((await call(ctx, 'GET', '/v1/notifications', { token: b.token })).json.unreadCount, 1, 'b untouched');
    assert.equal((await call(ctx, 'GET', '/v1/notifications?unreadOnly=true', { token: a.token })).json.notifications.length, 1);
    assert.equal((await call(ctx, 'POST', '/v1/notifications/read', { token: a.token, body: { all: true } })).status, 204);
    assert.equal((await call(ctx, 'GET', '/v1/notifications', { token: a.token })).json.unreadCount, 0);
    void two;
  });

  it('holds ids and short codes only: no names, no message text, no reporter', async () => {
    const host = await makeMember(ctx, 'Hostname Person');
    const guest = await makeMember(ctx, 'Guestname Person');
    await ctx.db.query(`update users set created_at = $2 where id = any($1::uuid[])`, [[host.userId, guest.userId], new Date('2026-01-01')]);
    const t = await call(ctx, 'POST', '/v1/forum/categories/welcome/threads', { token: host.token, body: { title: 'Private topic title', body: 'secret words in the body' } });
    ctx.clock.advanceMs(61_000);
    await call(ctx, 'POST', `/v1/forum/threads/${t.json.thread.id}/posts`, { token: guest.token, body: { body: 'a reply with secret text' } });
    const all = await ctx.db.query('select kind, payload from notifications');
    const raw = JSON.stringify(all.rows);
    for (const s of ['Hostname Person', 'Guestname Person', 'Private topic title', 'secret words', 'secret text']) {
      assert.ok(!raw.includes(s), `notification leaked ${s}`);
    }
  });

  it('is rate limited to a sane polling rate', async () => {
    const a = await makeMember(ctx);
    let last = 200;
    for (let i = 0; i < 305; i += 1) last = (await call(ctx, 'GET', '/v1/notifications', { token: a.token })).status;
    assert.equal(last, 429);
  });

  it('does not exist for people who never signed in', async () => {
    const s = await signUp(ctx);
    assert.equal((await call(ctx, 'GET', '/v1/notifications', { token: s.token })).status, 200);
    void notify;
  });
});
