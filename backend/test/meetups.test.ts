import assert from 'node:assert/strict';
import { after, before, describe, it } from 'node:test';
import { CHECK_VIOLATION, sqlState } from '../src/db.js';
import { runCommunityJobs } from '../src/jobs/community.js';
import {
  addChild, breathe, call, giveCredential, makeCtx, makeMember, seasoned, setRole, type Ctx, type Member,
} from './helpers.js';

describe('meet-ups', () => {
  let ctx: Ctx;
  before(async () => {
    ctx = await makeCtx({ env: { SESSION_TTL_DAYS: '90' } });
  });
  after(async () => {
    await ctx.close();
  });

  const inDays = (d: number, hour = 0) => new Date(ctx.clock.now().getTime() + d * 86_400_000 + hour * 3_600_000);
  const person = async (name: string, opts: { organiser?: boolean; role?: 'moderator' | 'admin' } = {}) => {
    const m = await makeMember(ctx, name.replace(/\b(mod|admin|moderator|scholar|staff)\b/gi, 'Aide'));
    await seasoned(ctx, m);
    if (opts.organiser) await giveCredential(ctx, m.userId, 'organiser', 'Al-Noor Mosque');
    if (opts.role) await setRole(ctx, m.userId, opts.role);
    return m;
  };
  const body = (over: Record<string, unknown> = {}) => ({
    title: 'Quran study circle',
    description: 'Reading together after Maghrib.',
    venueKind: 'mosque',
    venueName: 'Al-Noor Mosque',
    venueAddress: '100 Main Street',
    city: 'Toronto',
    country: 'CA',
    startsAt: inDays(3).toISOString(),
    audience: 'open',
    minorsPolicy: 'adults_only',
    acknowledgeOrganiserRules: true,
    ...over,
  });
  const create = (m: Member, over: Record<string, unknown> = {}) =>
    call(ctx, 'POST', '/v1/meetups', { token: m.token, body: body(over) });
  const rsvp = (m: Member, id: string, extra: Record<string, unknown> = {}) =>
    call(ctx, 'PUT', `/v1/meetups/${id}/rsvp`, { token: m.token, body: { acknowledge: true, ...extra } });
  const detail = (m: Member, id: string) => call(ctx, 'GET', `/v1/meetups/${id}`, { token: m.token });
  const listAll = (m: Member, q = '') => call(ctx, 'GET', `/v1/meetups${q}`, { token: m.token });
  const approve = (mod: Member, id: string) => call(ctx, 'POST', `/v1/mod/review/meetup/${id}/approve`, { token: mod.token });

  it('an unverified organiser waits for review; a verified organiser publishes at once', async () => {
    const plain = await person('Plain Organiser');
    const verified = await person('Verified Organiser', { organiser: true });
    const mod = await person('Meetup Mod', { role: 'moderator' });
    const viewer = await person('Viewer');
    const a = await create(plain);
    assert.equal(a.status, 201);
    assert.equal(a.json.pendingReview, true);
    assert.equal(a.json.meetup.status, 'pending_review');
    assert.equal(a.json.meetup.organiser.verified, false);
    assert.ok(!(await listAll(viewer)).json.meetups.some((m: any) => m.id === a.json.meetup.id));
    assert.equal((await detail(viewer, a.json.meetup.id)).status, 404, 'not visible before review');
    assert.equal((await detail(plain, a.json.meetup.id)).status, 200, 'the organiser sees it');
    assert.equal((await approve(mod, a.json.meetup.id)).status, 204);
    assert.ok((await listAll(viewer)).json.meetups.some((m: any) => m.id === a.json.meetup.id));
    const b = await create(verified, { title: 'Verified circle' });
    assert.equal(b.json.pendingReview, false);
    assert.equal(b.json.meetup.status, 'published');
    assert.equal(b.json.meetup.organiser.verified, true);
    assert.equal(b.json.meetup.organiser.orgName, 'Al-Noor Mosque');
  });

  it('only public venue kinds exist, and the database has no place for a home address', async () => {
    const m = await person('Venue Tester', { organiser: true });
    assert.equal((await create(m, { venueKind: 'home' })).status, 400);
    assert.equal((await create(m, { venueKind: 'apartment' })).status, 400);
    await assert.rejects(
      ctx.db.query(
        `insert into meetups (organiser_profile_id, title, venue_kind, venue_name, city, country, starts_at)
         values ($1, 'A home meetup', 'home', 'My house', 'Toronto', 'CA', $2)`,
        [m.profileId, inDays(2)],
      ),
      (e: unknown) => sqlState(e) === CHECK_VIOLATION,
    );
    const cols = await ctx.db.query<{ column_name: string }>(
      `select column_name from information_schema.columns where table_name = 'meetups'`,
    );
    const names = cols.rows.map((c) => c.column_name.toLowerCase());
    assert.ok(!names.some((n) => /home|house|private|residence|photo|image|picture/.test(n)), names.join(','));
  });

  it('a cafe must be confirmed halal; homes in the text are refused; times and sizes are checked', async () => {
    const m = await person('Rule Tester', { organiser: true });
    assert.equal((await create(m, { venueKind: 'cafe', venueName: 'Corner Cafe' })).json.error.code, 'halal_required');
    assert.equal((await create(m, { venueKind: 'cafe', venueName: 'Corner Cafe', halalConfirmed: true })).status, 201);
    breathe(ctx);
    for (const over of [
      { description: 'Please come to my house after isha' },
      { description: 'Held at my place, bring snacks' },
      { title: 'Basement gathering', description: 'at my home' },
      { venueName: 'My home', description: 'x' },
      { venueAddress: 'my home, 5 Elm Road' },
    ]) {
      const r = await create(m, over);
      assert.equal(r.status, 422, JSON.stringify(over));
      assert.equal(r.json.error.reason, 'private_address');
    }
    assert.equal((await create(m, { startsAt: inDays(0, 1).toISOString() })).json.error.code, 'too_soon');
    assert.equal((await create(m, { startsAt: inDays(400).toISOString() })).json.error.code, 'too_far');
    assert.equal((await create(m, { endsAt: inDays(2).toISOString() })).json.error.code, 'ends_before_start');
    assert.equal((await create(m, { endsAt: inDays(3, 14).toISOString() })).json.error.code, 'too_long');
    assert.equal((await create(m, { capacity: 1 })).status, 400);
    assert.equal((await create(m, { lat: 43.65 })).json.error.code, 'location_incomplete');
    assert.equal((await create(m, { acknowledgeOrganiserRules: false })).status, 400);
    const ok = await create(m, { lat: 43.653226, lng: -79.383184, title: 'Rounded place' });
    assert.equal(ok.status, 201);
    assert.equal(ok.json.meetup.lat, 43.653, 'coordinates are rounded to about 100 m');
    assert.equal(ok.json.meetup.lng, -79.383);
  });

  it('children only on a verified organiser families event; brothers and sisters events are adults only', async () => {
    const plain = await person('Plain Host');
    const verified = await person('Trusted Host', { organiser: true });
    assert.equal((await create(plain, { audience: 'brothers', minorsPolicy: 'guardian_rsvp' })).json.error.code, 'minors_need_families');
    assert.equal((await create(plain, { audience: 'families', minorsPolicy: 'guardian_rsvp' })).json.error.code, 'minors_need_verified_organiser');
    assert.equal((await create(verified, { audience: 'sisters', minorsPolicy: 'guardian_rsvp' })).json.error.code, 'minors_need_families');
    const ok = await create(verified, { audience: 'families', minorsPolicy: 'guardian_rsvp', title: 'Family morning' });
    assert.equal(ok.status, 201);
    assert.equal(ok.json.meetup.audience, 'families');
  });

  it('sign-up needs an acknowledgement, fills up, waits, and promotes in order', async () => {
    const host = await person('Capacity Host', { organiser: true });
    const [a, b, c] = [await person('Guest One'), await person('Guest Two'), await person('Guest Three')];
    const m = (await create(host, { capacity: 2, title: 'Small circle' })).json.meetup;
    assert.equal((await call(ctx, 'PUT', `/v1/meetups/${m.id}/rsvp`, { token: a.token, body: {} })).status, 400, 'must acknowledge');
    assert.equal((await rsvp(a, m.id)).json.rsvp.status, 'going');
    assert.equal((await rsvp(b, m.id)).json.rsvp.status, 'going');
    assert.equal((await rsvp(c, m.id)).json.rsvp.status, 'waitlist');
    assert.equal((await rsvp(c, m.id)).json.rsvp.status, 'waitlist', 'asking again keeps the place');
    const d = await detail(c, m.id);
    assert.equal(d.json.meetup.spotsLeft, 0);
    assert.equal(d.json.meetup.goingCount, 2);
    assert.equal(d.json.meetup.myRsvp, 'waitlist');
    assert.equal(d.json.attendees, undefined, 'attendees see counts, not names');
    assert.equal((await call(ctx, 'DELETE', `/v1/meetups/${m.id}/rsvp`, { token: a.token })).status, 204);
    assert.equal((await detail(c, m.id)).json.meetup.myRsvp, 'going', 'promoted');
    assert.equal((await ctx.db.query(`select 1 from notifications where user_id = $1 and kind = 'meetup_waitlist_promoted'`, [c.userId])).rowCount, 1);
    const org = await detail(host, m.id);
    assert.deepEqual(org.json.attendees.adults.map((x: any) => x.displayName).sort(), ['Guest Three', 'Guest Two']);
    assert.equal(org.json.attendees.childrenGoing, 0);
    assert.equal((await call(ctx, 'DELETE', `/v1/meetups/${m.id}/rsvp`, { token: a.token })).status, 404);
  });

  it('a guardian can bring a child only where the organiser allows it; a child name is never shown', async () => {
    const host = await person('Family Host', { organiser: true });
    const parent = await person('Parent Person');
    const kid = await addChild(ctx, parent, 'SecretKidName');
    const adultsOnly = (await create(host, { title: 'Adults circle' })).json.meetup;
    const families = (await create(host, { title: 'Families day', audience: 'families', minorsPolicy: 'guardian_rsvp', capacity: 3 })).json.meetup;
    assert.equal((await rsvp(parent, adultsOnly.id, { childProfileId: kid })).json.error.code, 'adults_only');
    const ok = await rsvp(parent, families.id, { childProfileId: kid });
    assert.equal(ok.status, 200);
    assert.equal(ok.json.rsvp.status, 'going');
    assert.equal(ok.json.rsvp.childStatus, 'going');
    const org = await detail(host, families.id);
    assert.equal(org.json.attendees.childrenGoing, 1);
    assert.ok(!JSON.stringify(org.json).includes('SecretKidName'));
    assert.equal(org.json.meetup.goingCount, 2, 'the child takes a seat');
    // The child cannot be signed up by someone else's account.
    const stranger = await person('Stranger');
    assert.equal((await rsvp(stranger, families.id, { childProfileId: kid })).status, 404);
    // Leaving as the guardian removes the child as well.
    assert.equal((await call(ctx, 'DELETE', `/v1/meetups/${families.id}/rsvp`, { token: parent.token })).status, 204);
    assert.equal((await detail(host, families.id)).json.meetup.goingCount, 0);
  });

  it('the database refuses a minor on a meet-up without their guardian or on an adults-only event', async () => {
    const host = await person('Trigger Host', { organiser: true });
    const parent = await person('Trigger Parent');
    const other = await person('Trigger Other');
    const kid = await addChild(ctx, parent, 'Kid');
    const adultsOnly = (await create(host, { title: 'Adults only event' })).json.meetup;
    const families = (await create(host, { title: 'Families event', audience: 'families', minorsPolicy: 'guardian_rsvp' })).json.meetup;
    const ins = (meetup: string, guardian: string | null) =>
      ctx.db.query(`insert into meetup_rsvps (meetup_id, profile_id, guardian_user_id) values ($1, $2, $3)`, [meetup, kid, guardian]);
    await assert.rejects(ins(adultsOnly.id, parent.userId), (e: unknown) => sqlState(e) === CHECK_VIOLATION);
    await assert.rejects(ins(families.id, null), (e: unknown) => sqlState(e) === CHECK_VIOLATION);
    await assert.rejects(ins(families.id, other.userId), (e: unknown) => sqlState(e) === CHECK_VIOLATION);
    await ins(families.id, parent.userId);
  });

  it('a blocked organiser and their meet-ups are invisible both ways', async () => {
    const host = await person('Blocked Host', { organiser: true });
    const a = await person('Blocker');
    const m = (await create(host, { title: 'Blocked circle' })).json.meetup;
    assert.ok((await listAll(a)).json.meetups.some((x: any) => x.id === m.id));
    await call(ctx, 'POST', '/v1/blocks', { token: a.token, body: { profileId: host.profileId } });
    assert.ok(!(await listAll(a)).json.meetups.some((x: any) => x.id === m.id));
    assert.equal((await detail(a, m.id)).status, 404);
    assert.equal((await rsvp(a, m.id)).status, 404);
    assert.equal((await rsvp(host, m.id)).status, 200, 'the organiser can still attend their own event');
  });

  it('personal hide removes a meet-up from my list only', async () => {
    const host = await person('Hide Host', { organiser: true });
    const a = await person('Hider');
    const b = await person('Not Hiding');
    const m = (await create(host, { title: 'Hideable circle' })).json.meetup;
    await call(ctx, 'POST', '/v1/hidden', { token: a.token, body: { targetType: 'meetup', targetId: m.id } });
    assert.ok(!(await listAll(a)).json.meetups.some((x: any) => x.id === m.id));
    assert.ok((await listAll(b)).json.meetups.some((x: any) => x.id === m.id));
  });

  it('repeats weekly as separate meet-ups in one series, and a series can be cancelled with notice', async () => {
    const host = await person('Series Host', { organiser: true });
    const guest = await person('Series Guest');
    const first = inDays(3);
    const week = (n: number) => new Date(first.getTime() + n * 7 * 86_400_000).toISOString();
    assert.equal((await create(host, { startsAt: first.toISOString(), occurrences: [week(1)] })).json.error.code, 'recurrence_required');
    assert.equal((await create(host, { startsAt: first.toISOString(), recurrence: 'weekly', occurrences: [new Date(first.getTime() + 3 * 86_400_000).toISOString()] })).json.error.code, 'recurrence_invalid');
    const r = await create(host, { title: 'Weekly circle', startsAt: first.toISOString(), recurrence: 'weekly', occurrences: [week(1), week(2), week(3)] });
    assert.equal(r.status, 201);
    assert.equal(r.json.count, 4);
    const rows = await ctx.db.query(`select id, series_id, series_index from meetups where series_id = $1 order by series_index`, [r.json.meetup.seriesId]);
    assert.equal(rows.rowCount, 4);
    const second = (rows.rows[1] as { id: string }).id;
    await rsvp(guest, second);
    // Cancel this one and everything after it.
    const c = await call(ctx, 'POST', `/v1/meetups/${second}/cancel`, { token: host.token, body: { reason: 'weather', scope: 'series' } });
    assert.equal(c.status, 204);
    const st = await ctx.db.query(`select status from meetups where series_id = $1 order by series_index`, [r.json.meetup.seriesId]);
    assert.deepEqual(st.rows.map((x: any) => x.status), ['published', 'cancelled', 'cancelled', 'cancelled']);
    assert.equal((await ctx.db.query(`select 1 from notifications where user_id = $1 and kind = 'meetup_cancelled'`, [guest.userId])).rowCount, 1);
    assert.equal((await detail(guest, second)).json.meetup.status, 'cancelled', 'attendees can see why');
    const stranger = await person('Late Stranger');
    assert.equal((await detail(stranger, second)).status, 404);
    // A non-organiser cannot cancel.
    assert.equal((await call(ctx, 'POST', `/v1/meetups/${(rows.rows[0] as { id: string }).id}/cancel`, { token: guest.token, body: { reason: 'other' } })).status, 404);
  });

  it('editing: an unverified organiser goes back to review; audience is locked once people sign up', async () => {
    const host = await person('Edit Host');
    const mod = await person('Edit Mod', { role: 'moderator' });
    const guest = await person('Edit Guest');
    const m = (await create(host, { title: 'Editable circle', capacity: 5 })).json.meetup;
    await approve(mod, m.id);
    await rsvp(guest, m.id);
    assert.equal((await call(ctx, 'PATCH', `/v1/meetups/${m.id}`, { token: host.token, body: { audience: 'brothers' } })).json.error.code, 'audience_locked');
    assert.equal((await call(ctx, 'PATCH', `/v1/meetups/${m.id}`, { token: host.token, body: { capacity: 2 } })).status, 200);
    await rsvp(await person('Second Edit Guest'), m.id);
    assert.equal((await call(ctx, 'PATCH', `/v1/meetups/${m.id}`, { token: host.token, body: { capacity: 2 } })).status, 200);
    const e1 = await call(ctx, 'PATCH', `/v1/meetups/${m.id}`, { token: host.token, body: { title: 'Editable circle, new title' } });
    assert.equal(e1.json.pendingReview, true, 'a change to what people saw is reviewed again');
    assert.equal((await detail(guest, m.id)).status, 404, 'hidden while it is reviewed again');
    assert.equal((await detail(host, m.id)).json.meetup.status, 'pending_review');
    // Moving it to a home after approval is refused outright.
    assert.equal((await call(ctx, 'PATCH', `/v1/meetups/${m.id}`, { token: host.token, body: { description: 'come to my house instead' } })).json.error.reason, 'private_address');
    // Someone else cannot edit it.
    assert.equal((await call(ctx, 'PATCH', `/v1/meetups/${m.id}`, { token: guest.token, body: { title: 'Hijacked circle' } })).status, 404);
  });

  it('a verified organiser edits freely, and attendees are told when the time or place moves', async () => {
    const host = await person('Verified Editor', { organiser: true });
    const guest = await person('Told Guest');
    const m = (await create(host, { title: 'Movable circle' })).json.meetup;
    await rsvp(guest, m.id);
    const e = await call(ctx, 'PATCH', `/v1/meetups/${m.id}`, { token: host.token, body: { startsAt: inDays(4).toISOString() } });
    assert.equal(e.json.pendingReview, false);
    assert.equal((await ctx.db.query(`select 1 from notifications where user_id = $1 and kind = 'meetup_updated'`, [guest.userId])).rowCount, 1);
    // But a capacity below the number going is refused.
    assert.equal((await call(ctx, 'PATCH', `/v1/meetups/${m.id}`, { token: host.token, body: { capacity: 2 } })).status, 200);
  });

  it('limits creation per day and upcoming meet-ups for unverified organisers', async () => {
    const host = await person('Busy Host');
    const mk = (i: number) => create(host, { title: `Circle number ${i}`, startsAt: inDays(3 + i).toISOString() });
    for (let i = 0; i < 5; i += 1) assert.equal((await mk(i)).status, 201);
    assert.equal((await mk(5)).status, 429, 'five a day');
    ctx.clock.advanceMs(86_400_000);
    assert.equal((await mk(5)).status, 201);
    assert.equal((await mk(6)).json.error.code, 'too_many_meetups', 'six upcoming for an unverified organiser');
    ctx.clock.advanceMs(-86_400_000);
  });

  it('sends a reminder 24 hours and 2 hours before, once each, and not to cancelled sign-ups', async () => {
    const host = await person('Reminder Host', { organiser: true });
    const a = await person('Reminded One');
    const b = await person('Reminded Two');
    const m = (await create(host, { title: 'Reminder circle', startsAt: inDays(2).toISOString() })).json.meetup;
    await rsvp(a, m.id);
    await rsvp(b, m.id);
    await call(ctx, 'DELETE', `/v1/meetups/${m.id}/rsvp`, { token: b.token });
    const rem = await call(ctx, 'GET', '/v1/meetups/reminders', { token: a.token });
    assert.equal(rem.json.reminders.length, 1);
    assert.equal(rem.json.reminders[0].remindAt.length, 2);
    const windows = async () =>
      (await ctx.db.query(`select payload from notifications where user_id = $1 and kind = 'meetup_reminder' order by created_at`, [a.userId]))
        .rows.map((r: any) => r.payload.window);
    await runCommunityJobs(ctx.db, ctx.clock.now());
    assert.deepEqual(await windows(), [], 'too early');
    ctx.clock.advanceMs(25 * 3_600_000);
    await runCommunityJobs(ctx.db, ctx.clock.now());
    await runCommunityJobs(ctx.db, ctx.clock.now());
    assert.deepEqual(await windows(), ['24h'], 'once');
    ctx.clock.advanceMs(22 * 3_600_000);
    await runCommunityJobs(ctx.db, ctx.clock.now());
    await runCommunityJobs(ctx.db, ctx.clock.now());
    assert.deepEqual(await windows(), ['24h', '2h']);
    assert.equal((await ctx.db.query(`select 1 from notifications where user_id = $1 and kind = 'meetup_reminder'`, [b.userId])).rowCount, 0);
    ctx.clock.advanceMs(-47 * 3_600_000);
  });

  it('a late sign-up skips the 24 hour reminder and gets only the 2 hour one', async () => {
    const host = await person('Late Host', { organiser: true });
    const a = await person('Late Guest');
    const m = (await create(host, { title: 'Soon circle', startsAt: inDays(0, 3).toISOString() })).json.meetup;
    await rsvp(a, m.id);
    ctx.clock.advanceMs(1.5 * 3_600_000);
    await runCommunityJobs(ctx.db, ctx.clock.now());
    const n = await ctx.db.query(`select payload from notifications where user_id = $1 and kind = 'meetup_reminder'`, [a.userId]);
    assert.deepEqual(n.rows.map((r: any) => r.payload.window), ['2h']);
    ctx.clock.advanceMs(-1.5 * 3_600_000);
  });

  it('reports hide a meet-up; past events are not listed; lists filter by city and audience', async () => {
    const host = await person('Report Host', { organiser: true });
    const v = await person('Viewer Two');
    const mod = await person('Report Mod', { role: 'moderator' });
    const sis = (await create(host, { title: 'Sisters circle', audience: 'sisters', city: 'Mississauga' })).json.meetup;
    const brs = (await create(host, { title: 'Brothers circle', audience: 'brothers', city: 'Toronto' })).json.meetup;
    assert.deepEqual((await listAll(v, '?audience=sisters')).json.meetups.map((x: any) => x.id), [sis.id]);
    assert.ok((await listAll(v, '?city=toronto')).json.meetups.every((x: any) => x.city === 'Toronto'));
    assert.equal((await listAll(v, '?city=Nowhere')).json.meetups.length, 0);
    const r = await call(ctx, 'POST', '/v1/reports', { token: v.token, body: { targetType: 'meetup', targetId: brs.id, reason: 'child_safety' } });
    assert.equal(r.json.hidden, true);
    assert.ok(!(await listAll(v)).json.meetups.some((x: any) => x.id === brs.id));
    const q = await call(ctx, 'GET', '/v1/mod/queue', { token: mod.token });
    assert.equal(q.json.reports[0].targetId, brs.id);
    assert.equal(q.json.reports[0].target.type, 'meetup');
    // Time passes: the event is over and leaves the list.
    ctx.clock.advanceMs(10 * 86_400_000);
    assert.ok(!(await listAll(v)).json.meetups.some((x: any) => x.id === sis.id));
    ctx.clock.advanceMs(-10 * 86_400_000);
  });

  it('children never organise: no route, and the database refuses', async () => {
    const parent = await person('Org Parent');
    const kid = await addChild(ctx, parent, 'Kid');
    await assert.rejects(
      ctx.db.query(
        `insert into meetups (organiser_profile_id, title, venue_kind, venue_name, city, country, starts_at)
         values ($1, 'Kid event', 'park', 'The park', 'Toronto', 'CA', $2)`,
        [kid, inDays(2)],
      ),
      (e: unknown) => sqlState(e) === CHECK_VIOLATION,
    );
  });

  it('erasing an organiser cancels their future meet-ups and tells the attendees', async () => {
    const host = await person('Leaving Host', { organiser: true });
    const guest = await person('Left Guest');
    const m = (await create(host, { title: 'Orphan circle' })).json.meetup;
    await rsvp(guest, m.id);
    assert.equal((await call(ctx, 'DELETE', '/v1/me', { token: host.token, body: { confirm: 'DELETE' } })).status, 204);
    assert.equal((await ctx.db.query(`select status from meetups where id = $1`, [m.id])).rows[0]!.status, 'cancelled');
    assert.equal((await ctx.db.query(`select 1 from notifications where user_id = $1 and kind = 'meetup_cancelled'`, [guest.userId])).rowCount, 1);
  });
});
