import assert from 'node:assert/strict';
import { after, before, describe, it } from 'node:test';
import { addChild, call, makeCtx, makeProfile, signUp, type Ctx } from './helpers.js';

describe('profiles, export and erasure', () => {
  let ctx: Ctx;
  before(async () => {
    ctx = await makeCtx();
  });
  after(async () => {
    await ctx.close();
  });

  it('creates and updates my profile, private by default', async () => {
    const s = await signUp(ctx);
    const r = await call(ctx, 'PUT', '/v1/me/profile', { token: s.token, body: { displayName: 'Amina K' } });
    assert.equal(r.status, 200);
    assert.equal(r.json.profile.visibility, 'private');
    assert.equal(r.json.profile.handle, null);
    const r2 = await call(ctx, 'PUT', '/v1/me/profile', {
      token: s.token,
      body: { displayName: 'Amina K', handle: 'amina_k', visibility: 'handle', bio: 'Tea and tafsir' },
    });
    assert.equal(r2.json.profile.id, r.json.profile.id, 'update, not a second profile');
    assert.equal(r2.json.profile.handle, 'amina_k');
    const me = await call(ctx, 'GET', '/v1/me', { token: s.token });
    assert.equal(me.json.profile.displayName, 'Amina K');
  });

  it('rejects reserved names, look-alikes, taken handles, links in bios', async () => {
    const a = await signUp(ctx);
    const b = await signUp(ctx);
    for (const name of ['Hadi', 'h4di', 'Imam Yusuf', 'Ar-Rayaan Team']) {
      const r = await call(ctx, 'PUT', '/v1/me/profile', { token: a.token, body: { displayName: name } });
      assert.equal(r.status, 422, name);
      assert.equal(r.json.error.code, 'display_name_invalid');
    }
    assert.equal(
      (await call(ctx, 'PUT', '/v1/me/profile', { token: a.token, body: { displayName: 'Ok Name', handle: 'the_admin' } })).json.error.code,
      'handle_invalid',
    );
    assert.equal(
      (await call(ctx, 'PUT', '/v1/me/profile', { token: a.token, body: { displayName: 'Ok Name', bio: 'visit www.spam.com' } })).json.error.code,
      'bio_invalid',
    );
    assert.equal(
      (await call(ctx, 'PUT', '/v1/me/profile', { token: a.token, body: { displayName: 'Ok Name', visibility: 'handle' } })).json.error.code,
      'handle_required',
    );
    await makeProfile(ctx, a, 'First One', 'taken_handle');
    const clash = await call(ctx, 'PUT', '/v1/me/profile', { token: b.token, body: { displayName: 'Second', handle: 'taken_handle' } });
    assert.equal(clash.status, 409);
    assert.equal(clash.json.error.code, 'handle_taken');
  });

  it('exports everything held about me, with no secrets', async () => {
    const s = await signUp(ctx);
    await makeProfile(ctx, s, 'Export Me');
    await addChild(ctx, s, 'Little One');
    const r = await call(ctx, 'GET', '/v1/me/export', { token: s.token });
    assert.equal(r.status, 200);
    const j = r.json;
    assert.equal(j.user.email, s.email);
    assert.equal(j.profiles.length, 2);
    assert.equal(j.parentalLinks.length, 1);
    assert.equal(j.consents.filter((c: { kind: string }) => c.kind === 'parent_consent').length, 1);
    const text = JSON.stringify(j);
    assert.ok(!text.includes(s.token));
    assert.ok(!text.includes('token_hash'));
    assert.ok(!text.includes('email_hash'));
  });

  it('erases an account: personal data goes, children go, sign-in stops, the address is free again', async () => {
    const s = await signUp(ctx);
    const friend = await signUp(ctx);
    const pid = await makeProfile(ctx, s, 'Erase Me', 'erase_me', 'community');
    const fid = await makeProfile(ctx, friend, 'Friend Of Me', 'friend_of_me', 'handle');
    const kid = await addChild(ctx, s, 'Kid');
    await call(ctx, 'POST', '/v1/friends/requests', { token: friend.token, body: { handle: 'erase_me' } });
    // Seed forum content so the content choice is exercised.
    const cat = (
      await ctx.db.query<{ id: string }>(`insert into forum_categories (slug, title) values ('erase-test', 'T') returning id`)
    ).rows[0]!.id;
    const thread = (
      await ctx.db.query<{ id: string }>(
        `insert into forum_threads (category_id, author_profile_id, title) values ($1, $2, 'A thread title') returning id`,
        [cat, pid],
      )
    ).rows[0]!.id;
    await ctx.db.query(`insert into forum_posts (thread_id, author_profile_id, body) values ($1, $2, 'hello')`, [thread, pid]);

    const bad = await call(ctx, 'DELETE', '/v1/me', { token: s.token, body: { confirm: 'yes' } });
    assert.equal(bad.status, 400);

    const del = await call(ctx, 'DELETE', '/v1/me', { token: s.token, body: { confirm: 'DELETE', content: 'remove' } });
    assert.equal(del.status, 204);

    assert.equal((await call(ctx, 'GET', '/v1/me', { token: s.token })).status, 401);
    const u = (await ctx.db.query<Record<string, unknown>>('select * from users where id = $1', [s.userId])).rows[0]!;
    assert.equal(u.email, null);
    assert.equal(u.email_hash, null);
    assert.equal(u.status, 'deleted');
    const p = (await ctx.db.query<Record<string, unknown>>('select * from profiles where id = $1', [pid])).rows[0]!;
    assert.equal(p.display_name, 'Deleted member');
    assert.equal(p.handle, null);
    assert.equal((await ctx.db.query('select 1 from profiles where id = $1', [kid])).rowCount, 0);
    assert.equal((await ctx.db.query('select 1 from sessions where user_id = $1', [s.userId])).rowCount, 0);
    assert.equal((await ctx.db.query('select 1 from friendships where profile_lo = $1 or profile_hi = $1', [pid])).rowCount, 0);
    assert.equal((await ctx.db.query(`select 1 from forum_posts where author_profile_id = $1 and status = 'removed' and body = '[removed]'`, [pid])).rowCount, 1);
    const audit = await ctx.db.query(`select meta from audit_log where action = 'account.erased' and actor_user_id = $1`, [s.userId]);
    assert.equal(audit.rowCount, 1);
    // The handle can be taken by someone else, and the friend sees nothing of the erased person.
    assert.equal((await call(ctx, 'GET', '/v1/friends', { token: friend.token })).json.incoming.length, 0);
    void fid;
    const again = await signUp(ctx, s.email);
    assert.notEqual(again.userId, s.userId);
  });

  it('keeps only the e-mail hash of a banned account that erases itself', async () => {
    const s = await signUp(ctx);
    await ctx.db.query(`update users set status = 'banned' where id = $1`, [s.userId]);
    // A banned account cannot call the API, so erase through the service directly.
    const { eraseAccount } = await import('../src/account.js');
    await ctx.db.tx((q) => eraseAccount(q, s.userId, ctx.clock.now(), 'keep_anonymous'));
    const u = (await ctx.db.query<Record<string, unknown>>('select * from users where id = $1', [s.userId])).rows[0]!;
    assert.equal(u.email, null);
    assert.notEqual(u.email_hash, null);
    assert.equal(u.status, 'banned');
    await call(ctx, 'POST', '/v1/auth/request-code', { body: { email: s.email } });
    const code = ctx.email.lastCodeFor(s.email)!;
    const v = await call(ctx, 'POST', '/v1/auth/verify-code', {
      body: { email: s.email, code, confirmAdult: true, termsVersion: (await import('../src/versions.js')).TERMS_VERSION, privacyVersion: (await import('../src/versions.js')).PRIVACY_VERSION },
    });
    assert.equal(v.status, 403, 'a banned address cannot start over');
  });
});
