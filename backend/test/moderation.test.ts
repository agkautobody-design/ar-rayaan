import assert from 'node:assert/strict';
import { after, before, describe, it } from 'node:test';
import { sqlState, CHECK_VIOLATION } from '../src/db.js';
import { runCommunityJobs, runCommunityRetention } from '../src/jobs/community.js';
import {
  breathe, call, makeCtx, makeMember, seasoned, setRole, type Ctx, type Member,
} from './helpers.js';

describe('reports, moderation, strikes, appeals, credentials', () => {
  let ctx: Ctx;
  before(async () => {
    ctx = await makeCtx({ env: { SESSION_TTL_DAYS: '90' } });
  });
  after(async () => {
    await ctx.close();
  });

  const person = async (name: string, role?: 'moderator' | 'admin') => {
    const m = await makeMember(ctx, name.replace(/\b(mod|admin|moderator|scholar|staff)\b/gi, 'Aide'));
    await seasoned(ctx, m);
    if (role) await setRole(ctx, m.userId, role);
    return m;
  };
  const post = async (m: Member, text: string, slug = 'welcome') => {
    breathe(ctx);
    const r = await call(ctx, 'POST', `/v1/forum/categories/${slug}/threads`, {
      token: m.token,
      body: { title: `Thread ${text}`.slice(0, 100), body: text },
    });
    assert.equal(r.status, 201, JSON.stringify(r.json));
    return { threadId: r.json.thread.id as string, postId: r.json.postId as string };
  };
  const report = (m: Member, targetType: string, targetId: string, reason = 'abuse') =>
    call(ctx, 'POST', '/v1/reports', { token: m.token, body: { targetType, targetId, reason } });
  const act = (m: Member, body: Record<string, unknown>) =>
    call(ctx, 'POST', '/v1/mod/actions', { token: m.token, body });
  const status = async (table: string, id: string) =>
    ((await ctx.db.query(`select status from ${table} where id = $1`, [id])).rows[0] as { status: string }).status;

  it('records a report once, never reveals the reporter, and hides at three independent reports', async () => {
    const author = await person('Aaliyah Author');
    const [r1, r2, r3] = [await person('Reporter One'), await person('Reporter Two'), await person('Reporter Three')];
    const mod = await person('Reviewer Mod', 'moderator');
    const p = await post(author, 'A post that people will report');
    assert.equal((await report(author, 'post', p.postId)).json.error.code, 'own_content');
    assert.equal((await report(r1, 'post', '00000000-0000-4000-8000-000000000000')).status, 404);
    const first = await report(r1, 'post', p.postId);
    assert.equal(first.status, 201);
    assert.equal(first.json.hidden, false);
    const again = await report(r1, 'post', p.postId);
    assert.equal(again.status, 200);
    assert.equal(again.json.duplicate, true);
    assert.equal((await report(r2, 'post', p.postId, 'harassment')).json.hidden, false);
    const third = await report(r3, 'post', p.postId, 'hate');
    assert.equal(third.json.hidden, true);
    assert.equal(await status('forum_posts', p.postId), 'hidden');

    const q = await call(ctx, 'GET', '/v1/mod/queue', { token: mod.token });
    const item = q.json.reports.find((x: any) => x.targetId === p.postId);
    assert.equal(item.reportCount, 3);
    assert.deepEqual(item.reasons, ['abuse', 'harassment', 'hate']);
    const raw = JSON.stringify(q.json);
    for (const m of [r1, r2, r3]) assert.ok(!raw.includes(m.profileId), 'reporter ids never appear in the queue');

    // The author is told, with a reason, and can see it in their moderation page.
    const mine = await call(ctx, 'GET', '/v1/me/moderation', { token: author.token });
    const hidden = mine.json.actions.find((a: any) => a.action === 'hide');
    assert.match(hidden.reason, /reviewed by a person/);
    assert.equal(hidden.appealable, true);
    assert.equal((await ctx.db.query(`select 1 from notifications where user_id = $1 and kind = 'moderation_action'`, [author.userId])).rowCount, 1);
    // Other readers see a placeholder, not the words.
    const view = await call(ctx, 'GET', `/v1/forum/threads/${p.threadId}`, { token: r1.token });
    assert.equal(view.json.posts[0].status, 'hidden');
    assert.equal(view.json.posts[0].body, '');
  });

  it('a moderator dismissing the reports restores a post that only an automatic hide had hidden', async () => {
    const author = await person('Dina Author');
    const rs = [await person('Rep A'), await person('Rep B'), await person('Rep C')];
    const mod = await person('Judge Mod', 'moderator');
    const p = await post(author, 'Unfairly reported post');
    for (const r of rs) await report(r, 'post', p.postId, 'spam');
    assert.equal(await status('forum_posts', p.postId), 'hidden');
    const d = await call(ctx, 'POST', '/v1/mod/queue/dismiss', { token: mod.token, body: { targetType: 'post', targetId: p.postId, note: 'fine' } });
    assert.equal(d.status, 204);
    assert.equal(await status('forum_posts', p.postId), 'visible');
    const q = await call(ctx, 'GET', '/v1/mod/queue', { token: mod.token });
    assert.ok(!q.json.reports.some((x: any) => x.targetId === p.postId));
  });

  it('one child-safety report hides at once, notifies every admin and tops the queue', async () => {
    const author = await person('Faris Author');
    const rep = await person('Careful Reporter');
    const mod = await person('Queue Mod', 'moderator');
    const admin = await person('Chief Admin', 'admin');
    const spam = await post(author, 'Some post that is merely spam');
    await report(rep, 'post', spam.postId, 'spam');
    const bad = await post(author, 'Another post that worries someone');
    const r = await report(rep, 'post', bad.postId, 'child_safety');
    assert.equal(r.json.hidden, true);
    assert.equal(await status('forum_posts', bad.postId), 'hidden');
    const notes = await ctx.db.query(`select payload from notifications where user_id = $1 and kind = 'report_child_safety'`, [admin.userId]);
    assert.equal(notes.rowCount, 1);
    const q = await call(ctx, 'GET', '/v1/mod/queue', { token: mod.token });
    assert.equal(q.json.reports[0].targetId, bad.postId);
    assert.equal(q.json.reports[0].priority, 100);
    const idxSpam = q.json.reports.findIndex((x: any) => x.targetId === spam.postId);
    assert.ok(idxSpam > 0, 'spam ranks below child safety');
  });

  it('only staff can use the console, and staff limits are enforced', async () => {
    const member = await person('Plain Member');
    const mod = await person('Limited Mod', 'moderator');
    const admin = await person('Boss Admin', 'admin');
    const target = await person('Target Person');
    assert.equal((await call(ctx, 'GET', '/v1/mod/queue', { token: member.token })).status, 403);
    assert.equal((await call(ctx, 'GET', '/v1/admin/audit', { token: mod.token })).status, 403);
    assert.equal((await act(member, { action: 'warn', userId: target.userId, reason: 'nope' })).status, 403);
    assert.equal((await act(mod, { action: 'ban', userId: target.userId, reason: 'too harsh for me' })).status, 403);
    assert.equal((await act(mod, { action: 'suspend', userId: target.userId, reason: 'too harsh', durationDays: 3 })).status, 403);
    assert.equal((await act(mod, { action: 'mute', userId: target.userId, reason: 'too long', durationDays: 30 })).status, 403);
    assert.equal((await act(mod, { action: 'warn', userId: admin.userId, reason: 'cannot touch an admin' })).status, 403);
    assert.equal((await act(mod, { action: 'warn', userId: mod.userId, reason: 'myself' })).status, 409);
    assert.equal((await act(mod, { action: 'warn', userId: target.userId, reason: 'a' })).status, 400, 'a reason is required');
  });

  it('strike points climb a ladder: mute, suspension, then an admin decides (never an automatic ban)', async () => {
    const mod = await person('Strike Mod', 'moderator');
    const admin = await person('Strike Admin', 'admin');
    const u = await person('Erring Member');
    const warn = () => act(mod, { action: 'warn', userId: u.userId, reason: 'Please keep to the rules of kindness.' });
    assert.equal((await warn()).status, 201);
    assert.equal((await warn()).status, 201);
    // Third point: automatic 7-day mute.
    assert.equal((await warn()).status, 201);
    const m1 = await call(ctx, 'GET', '/v1/me/moderation', { token: u.token });
    assert.equal(m1.json.strikePoints, 3);
    assert.equal(m1.json.sanctions[0].kind, 'mute');
    breathe(ctx);
    const muted = await call(ctx, 'POST', '/v1/forum/categories/welcome/threads', { token: u.token, body: { title: 'Trying to post', body: 'hello' } });
    assert.equal(muted.status, 403);
    assert.equal(muted.json.error.code, 'muted');
    // Reading and reporting still work while muted.
    assert.equal((await call(ctx, 'GET', '/v1/forum/categories', { token: u.token })).status, 200);
    // Points 4..6: automatic suspension.
    for (let i = 0; i < 3; i += 1) await warn();
    assert.equal((await call(ctx, 'GET', '/v1/forum/categories', { token: u.token })).status, 403);
    const restricted = await call(ctx, 'GET', '/v1/me/moderation', { token: u.token });
    assert.equal(restricted.status, 200, 'a suspended person can still read their notice');
    assert.equal(restricted.json.accountStatus, 'suspended');
    assert.equal((await call(ctx, 'GET', '/v1/notifications', { token: u.token })).status, 200);
    // Points to 10: indefinite suspension and every admin is told; not a ban.
    for (let i = 0; i < 4; i += 1) await warn();
    const row = (await ctx.db.query(`select status from users where id = $1`, [u.userId])).rows[0] as { status: string };
    assert.equal(row.status, 'suspended');
    const open = await ctx.db.query(`select 1 from sanctions where user_id = $1 and kind = 'suspend' and ends_at is null and lifted_at is null`, [u.userId]);
    assert.equal(open.rowCount, 1);
    assert.equal((await ctx.db.query(`select 1 from notifications where user_id = $1 and kind = 'strike_review'`, [admin.userId])).rowCount, 1);
  });

  it('a timed suspension lifts itself when it ends', async () => {
    const admin = await person('Timer Admin', 'admin');
    const u = await person('Suspended Soon');
    assert.equal((await act(admin, { action: 'suspend', userId: u.userId, reason: 'Cooling off period.', durationDays: 2 })).status, 201);
    assert.equal((await call(ctx, 'GET', '/v1/forum/categories', { token: u.token })).status, 403);
    ctx.clock.advanceMs(3 * 86_400_000);
    assert.equal((await call(ctx, 'GET', '/v1/forum/categories', { token: u.token })).status, 200);
    // The job does the same for people who never come back.
    const v = await person('Suspended Away');
    await act(admin, { action: 'suspend', userId: v.userId, reason: 'Cooling off period.', durationDays: 1 });
    ctx.clock.advanceMs(2 * 86_400_000);
    const done = await runCommunityJobs(ctx.db, ctx.clock.now());
    assert.ok(done.suspensionsLifted >= 1);
    assert.equal(((await ctx.db.query(`select status from users where id = $1`, [v.userId])).rows[0] as { status: string }).status, 'active');
  });

  it('ban and unban are admin-only; a banned person can still see why and appeal', async () => {
    const admin = await person('Ban Admin', 'admin');
    const other = await person('Second Admin', 'admin');
    const u = await person('Banned Member');
    const b = await act(admin, { action: 'ban', userId: u.userId, reason: 'Repeated serious harm to others.' });
    assert.equal(b.status, 201);
    assert.equal((await call(ctx, 'GET', '/v1/forum/categories', { token: u.token })).status, 403);
    const mine = await call(ctx, 'GET', '/v1/me/moderation', { token: u.token });
    const ban = mine.json.actions.find((a: any) => a.action === 'ban');
    assert.match(ban.reason, /serious harm/);
    const ap = await call(ctx, 'POST', '/v1/appeals', { token: u.token, body: { actionId: ban.id, statement: 'I am sorry and I would like another chance.' } });
    assert.equal(ap.status, 201);
    const mod = await person('Plain Mod', 'moderator');
    const list = await call(ctx, 'GET', '/v1/mod/appeals', { token: mod.token });
    const appeal = list.json.appeals.find((x: any) => x.id === ap.json.appeal.id);
    assert.equal(appeal.action.action, 'ban');
    assert.equal((await call(ctx, 'POST', `/v1/mod/appeals/${appeal.id}/decide`, { token: mod.token, body: { decision: 'upheld', note: 'A moderator may not decide a ban' } })).status, 403);
    // The admin who banned cannot decide their own ban; a different admin can.
    assert.equal((await call(ctx, 'POST', `/v1/mod/appeals/${appeal.id}/decide`, { token: admin.token, body: { decision: 'denied', note: 'I banned them' } })).json.error.code, 'different_moderator_required');
    const done = await call(ctx, 'POST', `/v1/mod/appeals/${appeal.id}/decide`, { token: other.token, body: { decision: 'upheld', note: 'On reflection the ban was too strong.' } });
    assert.equal(done.status, 204);
    assert.equal((await call(ctx, 'GET', '/v1/forum/categories', { token: u.token })).status, 200, 'the ban was lifted');
    const note = await ctx.db.query(`select payload from notifications where user_id = $1 and kind = 'appeal_decided'`, [u.userId]);
    assert.equal((note.rows[0] as { payload: { decision: string } }).payload.decision, 'upheld');
  });

  it('removal with a reason and strikes, then a successful appeal restores the post and the points', async () => {
    const mod = await person('Remove Mod', 'moderator');
    const mod2 = await person('Appeal Mod', 'moderator');
    const a = await person('Appealing Author');
    const p = await post(a, 'This post was removed by mistake');
    const rm = await act(mod, { action: 'remove', targetType: 'post', targetId: p.postId, reason: 'Looked like a personal ruling.' });
    assert.equal(rm.status, 201);
    assert.equal(await status('forum_posts', p.postId), 'removed');
    const mine = await call(ctx, 'GET', '/v1/me/moderation', { token: a.token });
    assert.equal(mine.json.strikePoints, 2);
    const action = mine.json.actions.find((x: any) => x.action === 'remove');
    assert.equal(action.reason, 'Looked like a personal ruling.');
    const ap = await call(ctx, 'POST', '/v1/appeals', { token: a.token, body: { actionId: action.id, statement: 'It was a question, not a ruling.' } });
    assert.equal(ap.status, 201);
    assert.equal((await call(ctx, 'POST', '/v1/appeals', { token: a.token, body: { actionId: action.id, statement: 'Again' } })).json.error.code, 'already_appealed');
    assert.equal((await call(ctx, 'POST', `/v1/mod/appeals/${ap.json.appeal.id}/decide`, { token: mod.token, body: { decision: 'upheld', note: 'I removed it myself' } })).json.error.code, 'different_moderator_required');
    assert.equal((await call(ctx, 'POST', `/v1/mod/appeals/${ap.json.appeal.id}/decide`, { token: mod2.token, body: { decision: 'upheld', note: 'Agreed, it was a question.' } })).status, 204);
    assert.equal(await status('forum_posts', p.postId), 'visible');
    assert.equal((await call(ctx, 'GET', '/v1/me/moderation', { token: a.token })).json.strikePoints, 0);
    // A different person's action cannot be appealed.
    const x = await person('Someone Else');
    assert.equal((await call(ctx, 'POST', '/v1/appeals', { token: x.token, body: { actionId: action.id, statement: 'Not mine' } })).status, 404);
  });

  it('appeals close after 30 days', async () => {
    const mod = await person('Late Mod', 'moderator');
    const a = await person('Late Author');
    await act(mod, { action: 'warn', userId: a.userId, reason: 'Please be gentler.' });
    const id = ((await call(ctx, 'GET', '/v1/me/moderation', { token: a.token })).json.actions[0]).id;
    ctx.clock.advanceMs(31 * 86_400_000);
    assert.equal((await call(ctx, 'POST', '/v1/appeals', { token: a.token, body: { actionId: id, statement: 'late' } })).json.error.code, 'appeal_window_closed');
  });

  it('review: approve and reject held posts; not your own; the rejection has a reason', async () => {
    const mod = await person('Review Mod', 'moderator');
    const other = await person('Other Mod', 'moderator');
    const a = await person('Held Author');
    const t = await post(a, 'You are a kafir and a deviant', 'daily-life');
    const q = await call(ctx, 'GET', '/v1/mod/queue', { token: mod.token });
    assert.ok(q.json.pending.some((x: any) => x.id === t.threadId && x.type === 'thread'));
    // Own content cannot be approved by its author-moderator.
    const own = await post(mod, 'A staff post that needs another moderator', 'sensitive');
    assert.equal((await call(ctx, 'POST', `/v1/mod/review/thread/${own.threadId}/approve`, { token: mod.token })).json.error.code, 'own_content');
    assert.equal((await call(ctx, 'POST', `/v1/mod/review/thread/${own.threadId}/approve`, { token: other.token })).status, 204);
    const rej = await call(ctx, 'POST', `/v1/mod/review/thread/${t.threadId}/reject`, { token: mod.token, body: { reason: 'Calling someone a kafir is not allowed here.', strikePoints: 1 } });
    assert.equal(rej.status, 204);
    assert.equal(await status('forum_threads', t.threadId), 'removed');
    const mine = await call(ctx, 'GET', '/v1/me/moderation', { token: a.token });
    assert.match(mine.json.actions[0].reason, /kafir/);
    assert.equal(mine.json.strikePoints, 1);
    assert.equal((await call(ctx, 'POST', `/v1/mod/review/thread/${t.threadId}/reject`, { token: mod.token, body: { reason: 'again' } })).status, 404);
  });

  it('credentials: apply, a human admin verifies, revokes; a trusted moderator gets the role', async () => {
    const admin = await person('Cred Admin', 'admin');
    const u = await person('Applicant Person');
    const apply = await call(ctx, 'POST', '/v1/credentials', { token: u.token, body: { kind: 'organiser', orgName: 'Al-Noor Mosque', evidenceNote: 'Committee member; call the office on the public number.' } });
    assert.equal(apply.status, 201);
    assert.equal((await call(ctx, 'POST', '/v1/credentials', { token: u.token, body: { kind: 'organiser', orgName: 'Again', evidenceNote: 'again' } })).json.error.code, 'credential_exists');
    const mine = await call(ctx, 'GET', '/v1/me/credentials', { token: u.token });
    assert.equal(mine.json.credentials[0].state, 'pending');
    const pending = await call(ctx, 'GET', '/v1/mod/credentials', { token: admin.token });
    assert.ok(pending.json.credentials.some((c: any) => c.id === apply.json.credential.id && c.evidenceNote));
    assert.equal((await call(ctx, 'POST', `/v1/mod/credentials/${apply.json.credential.id}/verify`, { token: u.token, body: {} })).status, 403);
    assert.equal((await call(ctx, 'POST', `/v1/mod/credentials/${apply.json.credential.id}/verify`, { token: admin.token, body: { expiresInDays: 30 } })).status, 204);
    assert.equal((await call(ctx, 'GET', '/v1/me/credentials', { token: u.token })).json.credentials[0].state, 'verified');
    assert.equal((await call(ctx, 'POST', `/v1/mod/credentials/${apply.json.credential.id}/revoke`, { token: admin.token, body: { reason: 'The mosque did not confirm.' } })).status, 204);
    assert.equal((await call(ctx, 'GET', '/v1/me/credentials', { token: u.token })).json.credentials[0].state, 'revoked');
    // Trusted moderator
    const t = await call(ctx, 'POST', '/v1/credentials', { token: u.token, body: { kind: 'trusted_moderator', orgName: 'Volunteer', evidenceNote: 'Volunteer for the community.' } });
    await call(ctx, 'POST', `/v1/mod/credentials/${t.json.credential.id}/verify`, { token: admin.token, body: {} });
    assert.equal((await call(ctx, 'GET', '/v1/mod/queue', { token: u.token })).status, 200);
    await call(ctx, 'POST', `/v1/mod/credentials/${t.json.credential.id}/revoke`, { token: admin.token, body: { reason: 'Ended.' } });
    assert.equal((await call(ctx, 'GET', '/v1/mod/queue', { token: u.token })).status, 403);
    // An admin cannot verify their own application.
    const own = await call(ctx, 'POST', '/v1/credentials', { token: admin.token, body: { kind: 'scholar', orgName: 'Self', evidenceNote: 'Myself.' } });
    assert.equal((await call(ctx, 'POST', `/v1/mod/credentials/${own.json.credential.id}/verify`, { token: admin.token, body: {} })).json.error.code, 'own_content');
  });

  it('admins manage filters (plain text) and every action lands in an append-only audit log of ids only', async () => {
    const admin = await person('Filter Admin', 'admin');
    const mod = await person('Filter Mod', 'moderator');
    const a = await person('Filter Subject');
    assert.equal((await call(ctx, 'POST', '/v1/admin/filters', { token: mod.token, body: { kind: 'block_word', pattern: 'x' } })).status, 403);
    assert.equal((await call(ctx, 'POST', '/v1/admin/filters', { token: admin.token, body: { kind: 'allow_domain', pattern: 'not a domain' } })).status, 422);
    const add = await call(ctx, 'POST', '/v1/admin/filters', { token: admin.token, body: { kind: 'block_word', pattern: 'blorptastic' } });
    assert.equal(add.status, 201);
    breathe(ctx);
    const blocked = await call(ctx, 'POST', '/v1/forum/categories/welcome/threads', { token: a.token, body: { title: 'A blorptastic day', body: 'hello' } });
    assert.equal(blocked.json.error.reason, 'blocked_word');
    await call(ctx, 'POST', '/v1/admin/filters', { token: admin.token, body: { kind: 'allow_domain', pattern: 'example.org' } });
    breathe(ctx);
    const linked = await call(ctx, 'POST', '/v1/forum/categories/welcome/threads', { token: a.token, body: { title: 'A useful link', body: 'see https://example.org/guide' } });
    assert.equal(linked.status, 201);
    assert.equal(linked.json.pendingReview, false);
    assert.equal((await call(ctx, 'DELETE', `/v1/admin/filters/${add.json.filter.id}`, { token: admin.token })).status, 204);
    breathe(ctx);
    assert.equal((await call(ctx, 'POST', '/v1/forum/categories/welcome/threads', { token: a.token, body: { title: 'A blorptastic day', body: 'hello again' } })).status, 201);

    await act(mod, { action: 'warn', userId: a.userId, reason: 'A gentle word.' });
    const log = await call(ctx, 'GET', '/v1/admin/audit?action=mod.', { token: admin.token });
    assert.ok(log.json.entries.some((e: any) => e.action === 'mod.warn' && e.targetType === null));
    const raw = JSON.stringify((await call(ctx, 'GET', '/v1/admin/audit', { token: admin.token })).json);
    assert.ok(!raw.includes(a.email) && !raw.includes('Filter Subject'), 'the audit log holds ids only');
    await assert.rejects(ctx.db.query(`update audit_log set action = 'x'`), (e: unknown) => sqlState(e) === CHECK_VIOLATION);
    await assert.rejects(ctx.db.query(`delete from audit_log`), (e: unknown) => sqlState(e) === CHECK_VIOLATION);
  });

  it('exports everything held, and erasing removes posts, reports, strikes and credentials', async () => {
    const mod = await person('Export Mod', 'moderator');
    const a = await person('Leaving Member');
    const b = await person('Staying Member');
    const p = await post(a, 'A post by someone leaving');
    await report(a, 'post', (await post(b, 'A post that a leaver reports')).postId, 'spam');
    await act(mod, { action: 'warn', userId: a.userId, reason: 'A gentle word.' });
    const ex = await call(ctx, 'GET', '/v1/me/export', { token: a.token });
    assert.equal(ex.status, 200);
    assert.equal(ex.json.forumPosts.length >= 1, true);
    assert.equal(ex.json.reportsFiled.length, 1);
    assert.equal(ex.json.moderation.strikes.length, 1);
    assert.equal(ex.json.moderation.actionsAboutMe.length, 1);
    const del = await call(ctx, 'DELETE', '/v1/me', { token: a.token, body: { confirm: 'DELETE', content: 'remove' } });
    assert.equal(del.status, 204);
    assert.equal(await status('forum_posts', p.postId), 'removed');
    assert.equal((await ctx.db.query(`select body from forum_posts where id = $1`, [p.postId])).rows[0]!.body, '[removed]');
    assert.equal((await ctx.db.query(`select 1 from strikes where user_id = $1`, [a.userId])).rowCount, 0);
    assert.equal((await ctx.db.query(`select 1 from reports where reporter_profile_id = $1`, [a.profileId])).rowCount, 0);
    const name = (await ctx.db.query(`select display_name from profiles where id = $1`, [a.profileId])).rows[0] as { display_name: string };
    assert.equal(name.display_name, 'Deleted member');
  });

  it('wipes the words of long-removed posts but keeps them while an appeal is open', async () => {
    const mod = await person('Retention Mod', 'moderator');
    const a = await person('Retention Author');
    const p1 = await post(a, 'Removed long ago and never appealed');
    const p2 = await post(a, 'Removed long ago but under appeal');
    await act(mod, { action: 'remove', targetType: 'post', targetId: p1.postId, reason: 'Against the rules.' });
    await act(mod, { action: 'remove', targetType: 'post', targetId: p2.postId, reason: 'Against the rules.' });
    const acts = (await call(ctx, 'GET', '/v1/me/moderation', { token: a.token })).json.actions;
    const second = acts.find((x: any) => x.reason && true && x.targetType === 'post');
    const ap = await ctx.db.query(`select id from moderation_actions where target_id = $1 and action = 'remove'`, [p2.postId]);
    await call(ctx, 'POST', '/v1/appeals', { token: a.token, body: { actionId: (ap.rows[0] as { id: string }).id, statement: 'Please look again.' } });
    void second;
    ctx.clock.advanceMs(61 * 86_400_000);
    const r = await runCommunityRetention(ctx.db, ctx.clock.now());
    assert.ok(r.removedBodies >= 1);
    assert.equal((await ctx.db.query(`select body from forum_posts where id = $1`, [p1.postId])).rows[0]!.body, '[removed]');
    assert.notEqual((await ctx.db.query(`select body from forum_posts where id = $1`, [p2.postId])).rows[0]!.body, '[removed]');
  });
});
