import assert from 'node:assert/strict';
import { after, before, describe, it } from 'node:test';
import { sqlState, CHECK_VIOLATION } from '../src/db.js';
import {
  addChild, breathe, call, categoryId, giveCredential, makeCtx, makeMember, makeProfile, seasoned, setRole,
  signUp, type Ctx, type Member,
} from './helpers.js';

describe('forums', () => {
  let ctx: Ctx;
  before(async () => {
    ctx = await makeCtx();
  });
  after(async () => {
    await ctx.close();
  });

  const start = (m: Member, slug: string, title: string, body: string) =>
    call(ctx, 'POST', `/v1/forum/categories/${slug}/threads`, { token: m.token, body: { title, body } });
  const reply = (m: Member, threadId: string, body: string, replyTo?: string) =>
    call(ctx, 'POST', `/v1/forum/threads/${threadId}/posts`, { token: m.token, body: { body, ...(replyTo ? { replyTo } : {}) } });
  const open = (m: Member, id: string) => call(ctx, 'GET', `/v1/forum/threads/${id}`, { token: m.token });
  const list = (m: Member, slug: string) => call(ctx, 'GET', `/v1/forum/categories/${slug}/threads`, { token: m.token });
  const seasonedMember = async (name?: string) => {
    const m = await makeMember(ctx, name);
    await seasoned(ctx, m);
    return m;
  };

  it('needs a profile visible in the community and accepted rules before anyone can write', async () => {
    const s = await signUp(ctx);
    assert.equal((await start(s as Member, 'welcome', 'Hello there', 'Salam everyone')).json.error.code, 'profile_required');
    await makeProfile(ctx, s, 'Quiet One', null, 'private');
    assert.equal((await start(s as Member, 'welcome', 'Hello there', 'Salam everyone')).json.error.code, 'community_visibility_required');
    await makeProfile(ctx, s, 'Quiet One', null, 'community');
    assert.equal((await start(s as Member, 'welcome', 'Hello there', 'Salam everyone')).json.error.code, 'rules_not_accepted');
    const rules = await call(ctx, 'GET', '/v1/community/rules', { token: s.token });
    assert.equal(rules.json.accepted, false);
    assert.equal((await call(ctx, 'POST', '/v1/community/rules/accept', { token: s.token, body: { version: 'old' } })).status, 422);
    assert.equal((await call(ctx, 'POST', '/v1/community/rules/accept', { token: s.token, body: { version: '2026-10-draft-1' } })).status, 204);
    assert.equal((await call(ctx, 'GET', '/v1/community/rules', { token: s.token })).json.accepted, true);
    assert.equal((await start(s as Member, 'welcome', 'Hello there', 'Salam everyone')).status, 201);
  });

  it('lists the seeded categories with the rules that apply to the caller', async () => {
    const m = await makeMember(ctx);
    const r = await call(ctx, 'GET', '/v1/forum/categories', { token: m.token });
    assert.equal(r.status, 200);
    const by = Object.fromEntries(r.json.categories.map((c: any) => [c.slug, c]));
    assert.deepEqual(Object.keys(by).sort(), ['announcements', 'ask-scholar', 'daily-life', 'learning', 'sensitive', 'welcome', 'wellbeing']);
    assert.equal(by['ask-scholar'].canStart, true);
    assert.equal(by['ask-scholar'].canReply, false, 'members cannot answer in Ask a scholar');
    assert.equal(by['ask-scholar'].strictModeration, true);
    assert.equal(by.sensitive.strictModeration, true);
    assert.equal(by.announcements.canStart, false);
    assert.equal(by.welcome.canReply, true);
    assert.equal(r.json.rulesVersion, '2026-10-draft-1');
  });

  it('starts a thread, replies, labels every post as community opinion, and notifies the author', async () => {
    const a = await seasonedMember('Amina A');
    const b = await seasonedMember('Bilal B');
    const t = await start(a, 'learning', 'Tips for makharij', 'Which resources helped you?');
    assert.equal(t.status, 201);
    assert.equal(t.json.pendingReview, false);
    const id = t.json.thread.id;
    breathe(ctx);
    const r1 = await reply(b, id, 'Slow repetition with a teacher helped me.');
    assert.equal(r1.status, 201);
    assert.equal(r1.json.post.label, 'community_opinion');
    const view = await open(a, id);
    assert.equal(view.json.posts.length, 2);
    assert.ok(view.json.posts.every((p: any) => p.label === 'community_opinion'));
    assert.equal(view.json.posts[0].mine, true);
    const notes = await ctx.db.query(`select kind, payload from notifications where user_id = $1`, [a.userId]);
    assert.ok(notes.rows.some((n) => n.kind === 'forum_reply'));
    breathe(ctx);
    await reply(a, id, 'Thank you!', r1.json.post.id);
    const after = await ctx.db.query(`select count(*)::int as n from notifications where user_id = $1 and kind = 'forum_reply'`, [a.userId]);
    assert.equal(after.rows[0]!.n, 1, 'no notification for replying to yourself');
    const l = await list(b, 'learning');
    assert.equal(l.json.threads[0].postCount, 3);
  });

  it('ignores any label the client tries to send', async () => {
    const a = await seasonedMember();
    const r = await call(ctx, 'POST', '/v1/forum/categories/welcome/threads', {
      token: a.token,
      body: { title: 'Sneaky label', body: 'hello', label: 'scholar_answer' },
    });
    assert.equal(r.status, 201);
    const view = await open(a, r.json.thread.id);
    assert.equal(view.json.posts[0].label, 'community_opinion');
  });

  it('keeps Ask a scholar separate: members ask, only a verified scholar answers, labelled', async () => {
    const asker = await seasonedMember('Asker');
    const other = await seasonedMember('Other');
    const scholar = await seasonedMember('Aisha Teacher');
    const mod = await seasonedMember('Zaid Reviewer');
    await setRole(ctx, mod.userId, 'moderator');
    const q = await start(asker, 'ask-scholar', 'A question about prayer', 'How do I make up a missed prayer?');
    assert.equal(q.status, 201);
    assert.equal(q.json.pendingReview, true, 'every question is read first');
    const id = q.json.thread.id;
    // Hidden from others until approved; the asker sees it.
    assert.equal((await list(other, 'ask-scholar')).json.threads.length, 0);
    assert.equal((await list(asker, 'ask-scholar')).json.threads.length, 1);
    assert.equal((await open(other, id)).status, 404);
    // A moderator approves it.
    assert.equal((await call(ctx, 'POST', `/v1/mod/review/thread/${id}/approve`, { token: mod.token })).status, 204);
    assert.equal((await list(other, 'ask-scholar')).json.threads.length, 1);
    // A community member may not answer, even a well-meaning one.
    breathe(ctx);
    const denied = await reply(other, id, 'I think you should pray it at once.');
    assert.equal(denied.status, 403);
    assert.equal(denied.json.error.code, 'scholars_only');
    // The asker cannot answer their own question either.
    assert.equal((await reply(asker, id, 'I found it')).status, 403);
    // A scholar without a verified credential cannot.
    assert.equal((await reply(scholar, id, 'An answer')).status, 403);
    await giveCredential(ctx, scholar.userId, 'scholar', 'Example Institute');
    breathe(ctx);
    const ok = await reply(scholar, id, 'The scholar answers here, with sources named by the scholar.');
    assert.equal(ok.status, 201);
    assert.equal(ok.json.post.label, 'scholar_answer');
    assert.equal(ok.json.pendingReview, false, 'a verified scholar answer is not held');
    const view = await open(other, id);
    const answer = view.json.posts.find((p: any) => p.label === 'scholar_answer');
    assert.ok(answer);
    assert.equal(answer.scholarOrg, 'Example Institute');
    assert.equal(view.json.thread.answered, true);
    assert.equal(view.json.posts[0].label, 'question');
  });

  it('a revoked scholar credential stops scholar answers', async () => {
    const asker = await seasonedMember();
    const scholar = await seasonedMember('Former Teacher');
    const mod = await seasonedMember('Reviewer Two');
    await setRole(ctx, mod.userId, 'moderator');
    const cred = await giveCredential(ctx, scholar.userId, 'scholar');
    const q = await start(asker, 'ask-scholar', 'Another question', 'Is this the right place?');
    await call(ctx, 'POST', `/v1/mod/review/thread/${q.json.thread.id}/approve`, { token: mod.token });
    await ctx.db.query('update credentials set revoked_at = $2 where id = $1', [cred, ctx.clock.now()]);
    breathe(ctx);
    assert.equal((await reply(scholar, q.json.thread.id, 'answer')).status, 403);
  });

  it('holds every post in Sensitive topics for review', async () => {
    const a = await seasonedMember();
    const t = await start(a, 'sensitive', 'Respectful discussion', 'Let us discuss differences with adab.');
    assert.equal(t.json.pendingReview, true);
    assert.equal((await list(await seasonedMember(), 'sensitive')).json.threads.length, 0);
  });

  it('staff-only announcements: members cannot start or reply', async () => {
    const m = await seasonedMember();
    const mod = await seasonedMember();
    await setRole(ctx, mod.userId, 'moderator');
    assert.equal((await start(m, 'announcements', 'News today', 'Something new')).status, 403);
    const t = await start(mod, 'announcements', 'News today', 'Something new');
    assert.equal(t.status, 201);
    assert.equal(t.json.pendingReview, false);
    breathe(ctx);
    assert.equal((await reply(m, t.json.thread.id, 'nice')).status, 403);
  });

  it('refuses contact details, homes, photos and bad links with a kind message (422)', async () => {
    const a = await seasonedMember();
    for (const [body, reason] of [
      ['call me on 416 555 0199 anytime', 'contact_details'],
      ['add me on whatsapp', 'off_platform_contact'],
      ['come to my house after isha', 'private_address'],
      ['look at this ![photo](x)', 'no_images'],
      ['visit https://bit.ly/abc', 'link_blocked'],
    ]) {
      breathe(ctx);
      const r = await start(a, 'welcome', 'A title here', body as string);
      assert.equal(r.status, 422, body);
      assert.equal(r.json.error.code, 'content_blocked');
      assert.equal(r.json.error.reason, reason);
    }
  });

  it('new accounts cannot post links; takfir and rulings are held, not blocked, and reported', async () => {
    const fresh = await makeMember(ctx);
    const blocked = await start(fresh, 'welcome', 'My introduction', 'see https://example.org');
    assert.equal(blocked.json.error.reason, 'links_new_account');
    const a = await seasonedMember();
    breathe(ctx);
    const held = await start(a, 'daily-life', 'Strong words', 'You are a kafir for saying that');
    assert.equal(held.status, 201);
    assert.equal(held.json.pendingReview, true);
    const rep = await ctx.db.query(`select reason, auto, priority from reports where target_id = $1`, [held.json.postId]);
    assert.equal(rep.rows[0]!.reason, 'sectarian');
    assert.equal(rep.rows[0]!.auto, true);
  });

  it('possible risk to life is allowed, shows help, and goes to the top of the queue', async () => {
    const a = await seasonedMember();
    const r = await start(a, 'wellbeing', 'I am not okay', 'I feel I want to die. Please help.');
    assert.equal(r.status, 201);
    assert.equal(r.json.pendingReview, false);
    assert.equal(r.json.showHelp, true);
    const rep = await ctx.db.query(`select priority from reports where target_id = $1`, [r.json.postId]);
    assert.ok((rep.rows[0] as { priority: number }).priority >= 80);
  });

  it('one gentle reaction: counted privately, never on your own post, never changes order', async () => {
    const a = await seasonedMember();
    const b = await seasonedMember();
    const c = await seasonedMember();
    const t = await start(a, 'learning', 'Order check', 'First post of the thread');
    const id = t.json.thread.id;
    breathe(ctx);
    const p1 = await reply(b, id, 'Second post, written first');
    breathe(ctx);
    ctx.clock.advanceMs(1000);
    const p2 = await reply(c, id, 'Third post, loved by everyone');
    for (const m of [a, b]) {
      assert.equal((await call(ctx, 'PUT', `/v1/forum/posts/${p2.json.post.id}/helpful`, { token: m.token })).status, 204);
    }
    assert.equal((await call(ctx, 'PUT', `/v1/forum/posts/${p2.json.post.id}/helpful`, { token: c.token })).status, 409, 'not your own');
    const asC = await open(c, id);
    const asA = await open(a, id);
    const postC = asC.json.posts.find((p: any) => p.id === p2.json.post.id);
    const postA = asA.json.posts.find((p: any) => p.id === p2.json.post.id);
    assert.equal(postC.helpfulCount, 2, 'the author sees encouragement');
    assert.equal(postA.helpfulCount, null, 'other readers see no score');
    assert.equal(postA.helpfulByMe, true);
    // Chronological, not by reactions.
    assert.deepEqual(asA.json.posts.map((p: any) => p.id).slice(1), [p1.json.post.id, p2.json.post.id]);
    // No notifications for reactions.
    const n = await ctx.db.query(`select count(*)::int as n from notifications where user_id = $1 and kind like '%helpful%'`, [c.userId]);
    assert.equal(n.rows[0]!.n, 0);
    assert.equal((await call(ctx, 'DELETE', `/v1/forum/posts/${p2.json.post.id}/helpful`, { token: a.token })).status, 204);
    assert.equal((await open(c, id)).json.posts.find((p: any) => p.id === p2.json.post.id).helpfulCount, 1);
  });

  it('threads are ordered by activity, not by popularity, and pinned ones come first', async () => {
    const a = await seasonedMember();
    const t1 = await start(a, 'daily-life', 'Older thread here', 'one');
    breathe(ctx);
    const t2 = await start(a, 'daily-life', 'Newer thread here', 'two');
    const l = await list(a, 'daily-life');
    const ids = l.json.threads.map((t: any) => t.id);
    assert.ok(ids.indexOf(t2.json.thread.id) < ids.indexOf(t1.json.thread.id));
    await ctx.db.query('update forum_threads set pinned = true where id = $1', [t1.json.thread.id]);
    const l2 = await list(a, 'daily-life');
    assert.equal(l2.json.threads[0].id, t1.json.thread.id);
  });

  it('lets authors edit for 15 minutes; reviewed categories re-review an edited post', async () => {
    const a = await seasonedMember();
    const t = await start(a, 'learning', 'Edit me please', 'Original words');
    const pid = t.json.postId;
    const e1 = await call(ctx, 'PATCH', `/v1/forum/posts/${pid}`, { token: a.token, body: { body: 'Better words' } });
    assert.equal(e1.status, 200);
    assert.equal(e1.json.pendingReview, false);
    ctx.clock.advanceMs(16 * 60_000);
    const e2 = await call(ctx, 'PATCH', `/v1/forum/posts/${pid}`, { token: a.token, body: { body: 'Too late' } });
    assert.equal(e2.json.error.code, 'edit_window_closed');
    // In a strict category an approved post becomes pending again on edit.
    const mod = await seasonedMember();
    await setRole(ctx, mod.userId, 'moderator');
    breathe(ctx);
    const s = await start(a, 'sensitive', 'A careful topic', 'Careful words');
    await call(ctx, 'POST', `/v1/mod/review/thread/${s.json.thread.id}/approve`, { token: mod.token });
    const e3 = await call(ctx, 'PATCH', `/v1/forum/posts/${s.json.postId}`, { token: a.token, body: { body: 'Different words now' } });
    assert.equal(e3.json.pendingReview, true);
    const viewByOther = await open(mod, s.json.thread.id);
    assert.ok(viewByOther.json.posts.some((p: any) => p.status === 'pending_review'));
  });

  it('removing the opening post removes the thread', async () => {
    const a = await seasonedMember();
    const b = await seasonedMember();
    const t = await start(a, 'welcome', 'Gone soon', 'bye');
    assert.equal((await call(ctx, 'DELETE', `/v1/forum/posts/${t.json.postId}`, { token: b.token })).status, 404);
    assert.equal((await call(ctx, 'DELETE', `/v1/forum/posts/${t.json.postId}`, { token: a.token })).status, 204);
    assert.equal((await open(b, t.json.thread.id)).status, 404);
  });

  it('refuses a duplicate post and enforces new-account and burst limits', async () => {
    const a = await seasonedMember();
    const t = await start(a, 'welcome', 'Duplicate check', 'same body');
    breathe(ctx);
    const dup = await reply(a, t.json.thread.id, 'same body');
    assert.equal(dup.json.error.code, 'duplicate_post');

    const fresh = await makeMember(ctx);
    assert.equal((await start(fresh, 'welcome', 'First thread', 'one')).status, 201);
    breathe(ctx);
    assert.equal((await start(fresh, 'welcome', 'Second thread', 'two')).status, 201);
    breathe(ctx);
    const third = await start(fresh, 'welcome', 'Third thread', 'three');
    assert.equal(third.status, 429, 'new accounts start at most two threads a day');

    const burst = await seasonedMember();
    const bt = await start(burst, 'welcome', 'Burst thread', 'x');
    const rs = [];
    for (let i = 0; i < 4; i += 1) rs.push((await reply(burst, bt.json.thread.id, `reply number ${i}`)).status);
    assert.deepEqual(rs, [201, 201, 429, 429]);
  });

  it('a locked thread takes no replies', async () => {
    const a = await seasonedMember();
    const t = await start(a, 'welcome', 'Lock me soon', 'x');
    await ctx.db.query(`update forum_threads set status = 'locked' where id = $1`, [t.json.thread.id]);
    breathe(ctx);
    assert.equal((await reply(a, t.json.thread.id, 'still here')).json.error.code, 'thread_locked');
  });

  it('blocking hides a person from your lists and threads, both ways', async () => {
    const a = await seasonedMember();
    const b = await seasonedMember();
    const tb = await start(b, 'welcome', 'By Bilal', 'hello from b');
    breathe(ctx);
    const ta = await start(a, 'welcome', 'By Amina', 'hello from a');
    breathe(ctx);
    const rb = await reply(b, ta.json.thread.id, 'a reply from b');
    assert.equal((await call(ctx, 'POST', '/v1/blocks', { token: a.token, body: { profileId: b.profileId } })).status, 204);
    const la = await list(a, 'welcome');
    assert.ok(!la.json.threads.some((t: any) => t.id === tb.json.thread.id));
    assert.equal((await open(a, tb.json.thread.id)).status, 404);
    const lb = await list(b, 'welcome');
    assert.ok(!lb.json.threads.some((t: any) => t.id === ta.json.thread.id), 'hidden the other way too');
    const view = await open(a, ta.json.thread.id);
    const placeholder = view.json.posts.find((p: any) => p.id === rb.json.post.id);
    assert.equal(placeholder.status, 'hidden_by_you');
    assert.equal(placeholder.body, '');
    breathe(ctx);
    assert.equal((await reply(b, ta.json.thread.id, 'more')).status, 404);
  });

  it('hiding a thread or post for yourself does not remove it for others', async () => {
    const a = await seasonedMember();
    const b = await seasonedMember();
    const t = await start(a, 'welcome', 'Hide me', 'hidden content');
    assert.equal((await call(ctx, 'POST', '/v1/hidden', { token: b.token, body: { targetType: 'thread', targetId: t.json.thread.id } })).status, 204);
    assert.ok(!(await list(b, 'welcome')).json.threads.some((x: any) => x.id === t.json.thread.id));
    assert.ok((await list(a, 'welcome')).json.threads.some((x: any) => x.id === t.json.thread.id));
    assert.equal((await call(ctx, 'DELETE', `/v1/hidden/thread/${t.json.thread.id}`, { token: b.token })).status, 204);
    assert.ok((await list(b, 'welcome')).json.threads.some((x: any) => x.id === t.json.thread.id));
  });

  it('children never reach the forums: no route takes a child, and the database refuses a child row', async () => {
    const parent = await seasonedMember('Parent');
    const childId = await addChild(ctx, parent, 'Little One');
    const cat = await categoryId(ctx, 'welcome');
    await assert.rejects(
      ctx.db.query(`insert into forum_threads (category_id, author_profile_id, title) values ($1, $2, 'A child thread')`, [cat, childId]),
      (e: unknown) => sqlState(e) === CHECK_VIOLATION,
    );
    const t = await start(parent, 'welcome', 'Parent thread', 'x');
    await assert.rejects(
      ctx.db.query(`insert into forum_posts (thread_id, author_profile_id, body) values ($1, $2, 'hi')`, [t.json.thread.id, childId]),
      (e: unknown) => sqlState(e) === CHECK_VIOLATION,
    );
    await assert.rejects(
      ctx.db.query(`insert into forum_reactions (post_id, profile_id, kind) values ($1, $2, 'helpful')`, [t.json.postId, childId]),
      (e: unknown) => sqlState(e) === CHECK_VIOLATION,
    );
    // A request that names a child profile is simply ignored: the caller acts as themselves.
    const r = await call(ctx, 'POST', '/v1/forum/categories/welcome/threads', {
      token: parent.token,
      body: { title: 'Named a child', body: 'different text', profileId: childId },
    });
    const view = await open(parent, r.json.thread.id);
    assert.equal(view.json.posts[0].authorProfileId, parent.profileId);
  });

  it('there are no direct messages in phase 2', async () => {
    const m = await makeMember(ctx);
    for (const url of ['/v1/messages', '/v1/dm', '/v1/conversations', '/v1/chat']) {
      assert.equal((await call(ctx, 'POST', url, { token: m.token, body: {} })).status, 404);
    }
  });
});
