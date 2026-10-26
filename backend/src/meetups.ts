import { randomUUID } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import {
  activeCredential, blockedEitherWaySql, fileAutoReport, hitLimit, requireMember, type Member,
} from './community.js';
import type { Deps } from './context.js';
import type { Queryable } from './db.js';
import { conflict, forbidden, notFound, unauthorized, unprocessable } from './errors.js';
import { isStaff, judge } from './forums.js';
import { limit, requireAuth } from './guards.js';
import { notify } from './notify.js';
import { toIso, actingProfile, ownAdultProfile } from './profiles.js';
import { parse, UUID_RE } from './validate.js';

/**
 * Meet-ups: public places only, adults only unless a verified organiser opens
 * a families event and a guardian RSVPs, never a private home.
 *
 *  - venue kinds are an allow-list (no "home" value, no private-address
 *    column); a cafe must be confirmed halal; coordinates are rounded to
 *    about 100 m; text that points at a home is refused by the content filter;
 *  - the organiser sets the audience (open, brothers, sisters, families); the
 *    app does not guess anyone's gender;
 *  - an organiser with a verified `organiser` credential publishes at once;
 *    everyone else waits for a moderator, and any later change to what people
 *    were shown sends the event back for review;
 *  - there are no direct messages: attendees see counts, the organiser sees
 *    adult names, nobody sees a child's name.
 */

const VENUE_KINDS = ['mosque', 'community_centre', 'library', 'cafe', 'park', 'school_hall', 'other_public'] as const;
const AUDIENCES = ['open', 'brothers', 'sisters', 'families'] as const;

export const MIN_LEAD_MS = 2 * 3_600_000;
export const MAX_HORIZON_DAYS = 180;
export const MAX_SERIES_HORIZON_DAYS = 365;
const MAX_UPCOMING_UNVERIFIED = 6;
const MAX_UPCOMING_VERIFIED = 24;

const fields = {
  title: z.string().trim().min(4).max(120),
  description: z.string().trim().max(2000),
  venueKind: z.enum(VENUE_KINDS),
  venueName: z.string().trim().min(2).max(120),
  venueAddress: z.string().trim().max(200).nullable().optional(),
  city: z.string().trim().min(2).max(80),
  region: z.string().trim().max(80).nullable().optional(),
  country: z.string().trim().length(2).transform((s) => s.toUpperCase()),
  lat: z.number().min(-90).max(90).nullable().optional(),
  lng: z.number().min(-180).max(180).nullable().optional(),
  startsAt: z.string().datetime(),
  endsAt: z.string().datetime().nullable().optional(),
  audience: z.enum(AUDIENCES),
  minorsPolicy: z.enum(['adults_only', 'guardian_rsvp']),
  capacity: z.number().int().min(2).max(500).nullable().optional(),
  accessibilityNotes: z.string().trim().max(300).nullable().optional(),
  halalConfirmed: z.boolean(),
};

const createBody = z.object({
  ...fields,
  description: fields.description.default(''),
  audience: fields.audience.default('open'),
  minorsPolicy: fields.minorsPolicy.default('adults_only'),
  halalConfirmed: fields.halalConfirmed.default(false),
  recurrence: z.enum(['weekly', 'biweekly', 'monthly']).optional(),
  occurrences: z.array(z.string().datetime()).max(11).default([]),
  acknowledgeOrganiserRules: z.literal(true),
});

const patchBody = z.object(fields).partial();

const idParam = z.object({ id: z.string().regex(/^[0-9a-f-]{36}$/) });
const listQuery = z.object({
  city: z.string().trim().max(80).optional(),
  country: z.string().trim().length(2).optional(),
  audience: z.enum(AUDIENCES).optional(),
  after: z.string().regex(/^[0-9T:.\-+Z]+~[0-9a-f-]{36}$/).optional(),
  limit: z.coerce.number().int().min(1).max(50).default(30),
});
const rsvpBody = z.object({
  acknowledge: z.literal(true),
  childProfileId: z.string().regex(/^[0-9a-f-]{36}$/).optional(),
});
const rsvpQuery = z.object({ childProfileId: z.string().regex(/^[0-9a-f-]{36}$/).optional() });
const cancelBody = z.object({
  reason: z.enum(['weather', 'venue_unavailable', 'low_attendance', 'organiser_unavailable', 'other']),
  scope: z.enum(['this', 'series']).default('this'),
});

interface MeetupRow {
  id: string;
  organiser_profile_id: string;
  organiser_name: string;
  organiser_user_id: string | null;
  organiser_verified: boolean;
  organiser_org: string | null;
  title: string;
  description: string;
  venue_kind: string;
  venue_name: string;
  venue_address: string | null;
  city: string;
  region: string | null;
  country: string;
  lat: string | null;
  lng: string | null;
  starts_at: Date;
  ends_at: Date | null;
  audience: string;
  minors_policy: string;
  capacity: number | null;
  accessibility_notes: string | null;
  status: string;
  halal_confirmed: boolean;
  recurrence: string;
  series_id: string | null;
  series_index: number;
  cancel_reason: string | null;
  going: number;
  waitlist: number;
  my_status: string | null;
}

/** Selected for a viewer ($1 = viewer profile id or null, $2 = now). */
const MEETUP_SELECT = `
  select m.id, m.organiser_profile_id, op.display_name as organiser_name, op.user_id as organiser_user_id,
         exists (select 1 from credentials c
                  where c.user_id = op.user_id and c.kind = 'organiser' and c.verified_at is not null
                    and c.revoked_at is null and (c.expires_at is null or c.expires_at > $2)) as organiser_verified,
         (select c.org_name from credentials c
           where c.user_id = op.user_id and c.kind = 'organiser' and c.verified_at is not null
             and c.revoked_at is null and (c.expires_at is null or c.expires_at > $2)
           order by c.verified_at desc limit 1) as organiser_org,
         m.title, m.description, m.venue_kind, m.venue_name, m.venue_address, m.city, m.region, m.country,
         m.lat::text as lat, m.lng::text as lng, m.starts_at, m.ends_at, m.audience, m.minors_policy,
         m.capacity, m.accessibility_notes, m.status, m.halal_confirmed, m.recurrence, m.series_id,
         m.series_index, m.cancel_reason,
         (select count(*) from meetup_rsvps r where r.meetup_id = m.id and r.status = 'going')::int as going,
         (select count(*) from meetup_rsvps r where r.meetup_id = m.id and r.status = 'waitlist')::int as waitlist,
         (select r.status from meetup_rsvps r where r.meetup_id = m.id and r.profile_id = $1) as my_status
    from meetups m join profiles op on op.id = m.organiser_profile_id`;

export function mapMeetup(m: MeetupRow, meProfileId: string | null) {
  const mine = meProfileId !== null && m.organiser_profile_id === meProfileId;
  return {
    id: m.id,
    title: m.title,
    description: m.description,
    venueKind: m.venue_kind,
    venueName: m.venue_name,
    venueAddress: m.venue_address,
    city: m.city,
    region: m.region,
    country: m.country,
    lat: m.lat === null ? null : Number(m.lat),
    lng: m.lng === null ? null : Number(m.lng),
    startsAt: toIso(m.starts_at),
    endsAt: m.ends_at ? toIso(m.ends_at) : null,
    audience: m.audience,
    minorsPolicy: m.minors_policy,
    capacity: m.capacity,
    spotsLeft: m.capacity === null ? null : Math.max(0, m.capacity - m.going),
    goingCount: m.going,
    waitlistCount: m.waitlist,
    accessibilityNotes: m.accessibility_notes,
    halalConfirmed: m.halal_confirmed,
    status: m.status,
    recurrence: m.recurrence,
    seriesId: m.series_id,
    cancelReason: m.cancel_reason,
    organiser: {
      profileId: m.organiser_profile_id,
      displayName: m.organiser_name,
      verified: m.organiser_verified,
      orgName: m.organiser_org,
    },
    mine,
    myRsvp: m.my_status,
  };
}

function round3(n: number): number {
  return Math.round(n * 1000) / 1000;
}

interface Fields {
  title: string; description: string; venueKind: (typeof VENUE_KINDS)[number]; venueName: string;
  venueAddress: string | null; city: string; region: string | null; country: string;
  lat: number | null; lng: number | null; startsAt: Date; endsAt: Date | null;
  audience: (typeof AUDIENCES)[number]; minorsPolicy: 'adults_only' | 'guardian_rsvp';
  capacity: number | null; accessibilityNotes: string | null; halalConfirmed: boolean;
}

/** The rules every meet-up (new or edited) must satisfy before it is stored. */
function checkRules(f: Fields, now: Date, organiserVerified: boolean): void {
  const lead = f.startsAt.getTime() - now.getTime();
  if (lead < MIN_LEAD_MS) throw unprocessable('too_soon', 'Meet-ups must be set at least two hours ahead.');
  if (lead > MAX_HORIZON_DAYS * 86_400_000) {
    throw unprocessable('too_far', `Meet-ups can be set up to ${MAX_HORIZON_DAYS} days ahead.`);
  }
  if (f.endsAt) {
    const len = f.endsAt.getTime() - f.startsAt.getTime();
    if (len <= 0) throw unprocessable('ends_before_start', 'The end must be after the start.');
    if (len > 12 * 3_600_000) throw unprocessable('too_long', 'A meet-up can last at most 12 hours.');
  }
  if ((f.lat === null) !== (f.lng === null)) {
    throw unprocessable('location_incomplete', 'Give both coordinates or neither.');
  }
  if (f.venueKind === 'cafe' && !f.halalConfirmed) {
    throw unprocessable('halal_required', 'A cafe is accepted only when you confirm it is halal.');
  }
  if (f.minorsPolicy === 'guardian_rsvp') {
    if (f.audience !== 'families') {
      throw unprocessable('minors_need_families', 'Children can only be included in a families meet-up.');
    }
    if (!organiserVerified) {
      throw unprocessable('minors_need_verified_organiser', 'Only a verified organiser can include children.');
    }
  }
}

function checkOccurrences(first: Date, rule: string | undefined, extra: Date[], now: Date): void {
  if (extra.length === 0) return;
  if (!rule) throw unprocessable('recurrence_required', 'Say how the meet-up repeats.');
  let prev = first;
  for (const d of extra) {
    const gapH = (d.getTime() - prev.getTime()) / 3_600_000;
    // An hour of slack lets the app keep the same local time across a clock change.
    const ok =
      rule === 'weekly' ? Math.abs(gapH - 168) <= 1.01
      : rule === 'biweekly' ? Math.abs(gapH - 336) <= 1.01
      : gapH >= 28 * 24 - 1.01 && gapH <= 31 * 24 + 1.01;
    if (!ok) throw unprocessable('recurrence_invalid', 'The repeat dates do not match the repeat rule.');
    if (d.getTime() - now.getTime() > MAX_SERIES_HORIZON_DAYS * 86_400_000) {
      throw unprocessable('too_far', 'A repeating meet-up can run for at most a year.');
    }
    prev = d;
  }
}

export async function registerMeetupRoutes(app: FastifyInstance, deps: Deps): Promise<void> {
  const { db } = deps;
  const auth = requireAuth(deps);

  async function viewer(userId: string): Promise<string | null> {
    const p = await ownAdultProfile(db, userId);
    return p && p.erased_at === null ? p.id : null;
  }

  async function organiserVerified(q: Queryable, userId: string): Promise<boolean> {
    return (await activeCredential(q, userId, 'organiser', deps.now())) !== undefined;
  }

  /** Loads one meet-up for a viewer, or 404 when they may not see it. */
  async function load(q: Queryable, id: string, userId: string, role: string): Promise<{ m: MeetupRow; me: string | null }> {
    if (!UUID_RE.test(id)) throw notFound();
    const me = await viewer(userId);
    const r = await q.query<MeetupRow>(`${MEETUP_SELECT} where m.id = $3`, [me, deps.now(), id]);
    const m = r.rows[0];
    if (!m) throw notFound();
    const isOrganiser = me !== null && m.organiser_profile_id === me;
    if (!isStaff(role) && !isOrganiser) {
      if (m.status === 'cancelled') {
        // visible to anyone who had signed up
        if (!m.my_status) throw notFound();
      } else if (m.status !== 'published') {
        throw notFound();
      }
      if (me) {
        const b = await q.query(`select ${blockedEitherWaySql('$1', '$2')} as b`, [me, m.organiser_profile_id]);
        if ((b.rows[0] as { b?: boolean } | undefined)?.b) throw notFound();
      }
    }
    return { m, me };
  }

  // ---------------------------------------------------------------- list
  app.get('/v1/meetups', { preHandler: [auth] }, async (request) => {
    const a = request.auth;
    if (!a) throw unauthorized();
    const q = parse(listQuery, request.query);
    const me = await viewer(a.userId);
    const now = deps.now();
    const [afterAt, afterId] = q.after ? q.after.split('~') : [null, null];
    const r = await db.query<MeetupRow>(
      `${MEETUP_SELECT}
        where m.status = 'published'
          and coalesce(m.ends_at, m.starts_at + interval '3 hours') > $2
          and ($4::text is null or lower(m.city) = lower($4::text))
          and ($5::text is null or m.country = upper($5::text))
          and ($6::text is null or m.audience = $6::text)
          and ($7::timestamptz is null or (m.starts_at, m.id) > ($7::timestamptz, $8::uuid))
          and not ${blockedEitherWaySql('$1', 'm.organiser_profile_id')}
          and not exists (select 1 from user_hidden h
                           where h.profile_id = $1 and h.target_type = 'meetup' and h.target_id = m.id)
        order by m.starts_at, m.id
        limit $3`,
      [me, now, q.limit + 1, q.city ?? null, q.country ?? null, q.audience ?? null, afterAt, afterId],
    );
    const rows = r.rows.slice(0, q.limit);
    const last = rows[rows.length - 1];
    return {
      meetups: rows.map((m) => mapMeetup(m, me)),
      hasMore: r.rows.length > q.limit,
      next: r.rows.length > q.limit && last ? `${toIso(last.starts_at)}~${last.id}` : null,
    };
  });

  app.get('/v1/meetups/mine', { preHandler: [auth] }, async (request) => {
    const a = request.auth;
    if (!a) throw unauthorized();
    const me = await viewer(a.userId);
    if (!me) return { meetups: [] };
    const r = await db.query<MeetupRow>(
      `${MEETUP_SELECT}
        where (m.organiser_profile_id = $1
               or exists (select 1 from meetup_rsvps r where r.meetup_id = m.id and r.profile_id = $1
                           and r.status in ('going', 'waitlist')))
          and coalesce(m.ends_at, m.starts_at + interval '3 hours') > $2::timestamptz - interval '30 days'
        order by m.starts_at, m.id limit 100`,
      [me, deps.now()],
    );
    return { meetups: r.rows.map((m) => mapMeetup(m, me)) };
  });

  /** The data a reminder screen needs; the hourly job also sends notifications. */
  app.get('/v1/meetups/reminders', { preHandler: [auth] }, async (request) => {
    const a = request.auth;
    if (!a) throw unauthorized();
    const me = await viewer(a.userId);
    if (!me) return { reminders: [] };
    const now = deps.now();
    const r = await db.query<{ id: string; title: string; starts_at: Date; venue_name: string; city: string }>(
      `select m.id, m.title, m.starts_at, m.venue_name, m.city
         from meetups m join meetup_rsvps r on r.meetup_id = m.id
        where r.profile_id = $1 and r.status = 'going' and m.status = 'published'
          and m.starts_at > $2 and m.starts_at < $2::timestamptz + interval '7 days'
        order by m.starts_at`,
      [me, now],
    );
    return {
      reminders: r.rows.map((m) => ({
        meetupId: m.id, title: m.title, startsAt: toIso(m.starts_at), venueName: m.venue_name, city: m.city,
        remindAt: [
          new Date(m.starts_at.getTime() - 24 * 3_600_000).toISOString(),
          new Date(m.starts_at.getTime() - 2 * 3_600_000).toISOString(),
        ],
      })),
    };
  });

  app.get<{ Params: { id: string } }>('/v1/meetups/:id', { preHandler: [auth] }, async (request) => {
    const a = request.auth;
    if (!a) throw unauthorized();
    const { id } = parse(idParam, request.params);
    const { m, me } = await load(db, id, a.userId, a.role);
    const out: Record<string, unknown> = { meetup: mapMeetup(m, me) };
    if (me !== null && m.organiser_profile_id === me) {
      // The organiser sees adult names. A child's name is never listed.
      const adults = await db.query<{ profile_id: string; name: string; status: string }>(
        `select r.profile_id, p.display_name as name, r.status
           from meetup_rsvps r join profiles p on p.id = r.profile_id
          where r.meetup_id = $1 and p.kind = 'adult' and r.status in ('going', 'waitlist')
          order by r.created_at`,
        [id],
      );
      const kids = await db.query<{ n: string }>(
        `select count(*)::text as n from meetup_rsvps r join profiles p on p.id = r.profile_id
          where r.meetup_id = $1 and p.kind <> 'adult' and r.status = 'going'`,
        [id],
      );
      out.attendees = {
        adults: adults.rows.map((x) => ({ profileId: x.profile_id, displayName: x.name, status: x.status })),
        childrenGoing: Number(kids.rows[0]?.n ?? '0'),
      };
    }
    return out;
  });

  // -------------------------------------------------------------- create
  app.post('/v1/meetups', { preHandler: [auth] }, async (request, reply) => {
    const a = request.auth;
    if (!a) throw unauthorized();
    const b = parse(createBody, request.body);
    const member = await requireMember(db, deps, a, { visible: true, rules: true, notMuted: true });
    hitLimit(deps, `meetup_attempt:${a.userId}`, 60, 3600);
    const now = deps.now();
    const verified = await activeCredential(db, a.userId, 'organiser', now);
    const f: Fields = {
      title: b.title, description: b.description, venueKind: b.venueKind, venueName: b.venueName,
      venueAddress: b.venueAddress?.trim() ? b.venueAddress.trim() : null, city: b.city,
      region: b.region?.trim() ? b.region.trim() : null, country: b.country,
      lat: b.lat === null || b.lat === undefined ? null : round3(b.lat),
      lng: b.lng === null || b.lng === undefined ? null : round3(b.lng),
      startsAt: new Date(b.startsAt), endsAt: b.endsAt ? new Date(b.endsAt) : null,
      audience: b.audience, minorsPolicy: b.minorsPolicy, capacity: b.capacity ?? null,
      accessibilityNotes: b.accessibilityNotes?.trim() ? b.accessibilityNotes.trim() : null,
      halalConfirmed: b.halalConfirmed,
    };
    checkRules(f, now, verified !== undefined);
    const extra = b.occurrences.map((s) => new Date(s));
    checkOccurrences(f.startsAt, b.recurrence, extra, now);

    const verdict = await judgeMeetup(deps, member, f);
    const status = verified && verdict.kind !== 'review' ? 'published' : 'pending_review';

    const upcoming = await db.query<{ n: string }>(
      `select count(*)::text as n from meetups
        where organiser_profile_id = $1 and status in ('published', 'pending_review') and starts_at > $2`,
      [member.profile.id, now],
    );
    const have = Number(upcoming.rows[0]?.n ?? '0');
    const cap = verified ? MAX_UPCOMING_VERIFIED : MAX_UPCOMING_UNVERIFIED;
    if (have + 1 + extra.length > cap) {
      throw conflict('too_many_meetups', 'You have reached the limit of upcoming meet-ups. Cancel one or wait.');
    }

    hitLimit(deps, `meetup_create:${a.userId}`, 5, 86_400);
    const seriesId = extra.length > 0 ? randomUUID() : null;
    const length = f.endsAt ? f.endsAt.getTime() - f.startsAt.getTime() : null;
    const ids = await db.tx(async (q) => {
      const out: string[] = [];
      const starts = [f.startsAt, ...extra];
      for (let i = 0; i < starts.length; i += 1) {
        const s = starts[i] as Date;
        const r = await q.query<{ id: string }>(
          `insert into meetups
             (organiser_profile_id, organiser_credential_id, title, description, venue_kind, venue_name,
              venue_address, city, region, country, lat, lng, starts_at, ends_at, audience, minors_policy,
              capacity, accessibility_notes, status, halal_confirmed, recurrence, series_id, series_index,
              created_at, published_at)
           values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25)
           returning id`,
          [
            member.profile.id, verified?.id ?? null, f.title, f.description, f.venueKind, f.venueName,
            f.venueAddress, f.city, f.region, f.country, f.lat, f.lng, s,
            length === null ? null : new Date(s.getTime() + length), f.audience, f.minorsPolicy, f.capacity,
            f.accessibilityNotes, status, f.halalConfirmed, b.recurrence ?? 'none', seriesId, i, now,
            status === 'published' ? now : null,
          ],
        );
        const id = r.rows[0]?.id ?? '';
        out.push(id);
        if (verdict.kind !== 'allow' && verdict.autoReport) {
          await fileAutoReport(q, { type: 'meetup', id }, verdict.autoReport);
        }
      }
      return out;
    });
    const r = await db.query<MeetupRow>(`${MEETUP_SELECT} where m.id = $3`, [member.profile.id, now, ids[0]]);
    const row = r.rows[0];
    if (!row) throw notFound();
    void reply.code(201);
    return { meetup: mapMeetup(row, member.profile.id), count: ids.length, pendingReview: status === 'pending_review' };
  });

  async function judgeMeetup(d: Deps, member: Member, f: Pick<Fields, 'title' | 'description' | 'venueName' | 'city' | 'accessibilityNotes' | 'venueAddress'>) {
    const main = await judge(d, member, [f.title, f.description, f.venueName, f.city, f.accessibilityNotes ?? ''], 'meetup');
    const addr = f.venueAddress ? await judge(d, member, [f.venueAddress], 'venue') : main;
    return main.kind === 'review' ? main : addr.kind === 'review' ? addr : main;
  }

  // --------------------------------------------------------------- edit
  app.patch<{ Params: { id: string } }>(
    '/v1/meetups/:id',
    { preHandler: [auth, limit(deps, { name: 'meetup_edit', max: 30, windowSec: 3600, by: 'user' })] },
    async (request) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      const { id } = parse(idParam, request.params);
      const patch = parse(patchBody, request.body);
      const member = await requireMember(db, deps, a, { visible: true, rules: true, notMuted: true });
      const now = deps.now();
      const { m } = await load(db, id, a.userId, 'member');
      if (m.organiser_profile_id !== member.profile.id) throw notFound();
      if (m.status === 'cancelled' || m.status === 'hidden') throw conflict('invalid_state', 'This meet-up can no longer be edited.');
      if (new Date(m.starts_at).getTime() <= now.getTime()) throw conflict('already_started', 'This meet-up has started.');
      const verified = await organiserVerified(db, a.userId);

      const f: Fields = {
        title: patch.title ?? m.title,
        description: patch.description ?? m.description,
        venueKind: (patch.venueKind ?? m.venue_kind) as Fields['venueKind'],
        venueName: patch.venueName ?? m.venue_name,
        venueAddress: patch.venueAddress === undefined ? m.venue_address : (patch.venueAddress?.trim() || null),
        city: patch.city ?? m.city,
        region: patch.region === undefined ? m.region : (patch.region?.trim() || null),
        country: patch.country ?? m.country,
        lat: patch.lat === undefined ? (m.lat === null ? null : Number(m.lat)) : (patch.lat === null ? null : round3(patch.lat)),
        lng: patch.lng === undefined ? (m.lng === null ? null : Number(m.lng)) : (patch.lng === null ? null : round3(patch.lng)),
        startsAt: patch.startsAt ? new Date(patch.startsAt) : new Date(m.starts_at),
        endsAt: patch.endsAt === undefined ? (m.ends_at ? new Date(m.ends_at) : null) : (patch.endsAt ? new Date(patch.endsAt) : null),
        audience: (patch.audience ?? m.audience) as Fields['audience'],
        minorsPolicy: (patch.minorsPolicy ?? m.minors_policy) as Fields['minorsPolicy'],
        capacity: patch.capacity === undefined ? m.capacity : (patch.capacity ?? null),
        accessibilityNotes: patch.accessibilityNotes === undefined ? m.accessibility_notes : (patch.accessibilityNotes?.trim() || null),
        halalConfirmed: patch.halalConfirmed ?? m.halal_confirmed,
      };
      checkRules(f, now, verified);

      const audienceChanged = f.audience !== m.audience || f.minorsPolicy !== m.minors_policy;
      if (audienceChanged && m.going + m.waitlist > 0) {
        throw conflict('audience_locked', 'People have already signed up, so who it is for cannot change. Cancel and create a new one.');
      }
      if (f.capacity !== null && f.capacity < m.going) {
        throw conflict('capacity_below_going', 'The capacity cannot be lower than the number already going.');
      }
      const verdict = await judgeMeetup(deps, member, f);

      const timeOrPlaceChanged =
        f.startsAt.getTime() !== new Date(m.starts_at).getTime() || f.venueName !== m.venue_name ||
        f.venueAddress !== m.venue_address || f.venueKind !== m.venue_kind || f.city !== m.city;
      const contentChanged =
        timeOrPlaceChanged || f.title !== m.title || f.description !== m.description || audienceChanged ||
        f.endsAt?.getTime() !== (m.ends_at ? new Date(m.ends_at).getTime() : undefined);
      let status = m.status;
      if (m.status === 'published' && contentChanged && (!verified || verdict.kind === 'review')) status = 'pending_review';

      await db.tx(async (q) => {
        await q.query(
          `update meetups set title=$2, description=$3, venue_kind=$4, venue_name=$5, venue_address=$6, city=$7,
                  region=$8, country=$9, lat=$10, lng=$11, starts_at=$12, ends_at=$13, audience=$14,
                  minors_policy=$15, capacity=$16, accessibility_notes=$17, halal_confirmed=$18, status=$19
            where id = $1`,
          [id, f.title, f.description, f.venueKind, f.venueName, f.venueAddress, f.city, f.region, f.country,
           f.lat, f.lng, f.startsAt, f.endsAt, f.audience, f.minorsPolicy, f.capacity, f.accessibilityNotes,
           f.halalConfirmed, status],
        );
        if (timeOrPlaceChanged) await notifyAttendees(q, id, 'meetup_updated', {});
        if (verdict.kind !== 'allow' && verdict.autoReport) await fileAutoReport(q, { type: 'meetup', id }, verdict.autoReport);
      });
      return { meetup: { id, status }, pendingReview: status === 'pending_review' };
    },
  );

  // ------------------------------------------------------------- cancel
  app.post<{ Params: { id: string } }>(
    '/v1/meetups/:id/cancel',
    { preHandler: [auth] },
    async (request, reply) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      const { id } = parse(idParam, request.params);
      const b = parse(cancelBody, request.body);
      const me = await viewer(a.userId);
      if (!me) throw forbidden('profile_required', 'Create your profile first.');
      const now = deps.now();
      await db.tx(async (q) => {
        const r = await q.query<{ organiser_profile_id: string; status: string; series_id: string | null; starts_at: Date }>(
          'select organiser_profile_id, status, series_id, starts_at from meetups where id = $1 for update',
          [id],
        );
        const m = r.rows[0];
        if (!m || m.organiser_profile_id !== me) throw notFound();
        if (!['published', 'pending_review'].includes(m.status)) throw conflict('invalid_state', 'This meet-up cannot be cancelled.');
        const targets = await q.query<{ id: string }>(
          b.scope === 'series' && m.series_id
            ? `select id from meetups where series_id = $1 and starts_at >= $2 and status in ('published', 'pending_review')`
            : `select id from meetups where id = $3`,
          b.scope === 'series' && m.series_id ? [m.series_id, m.starts_at] : [null, null, id],
        );
        for (const t of targets.rows) {
          await q.query(
            `update meetups set status = 'cancelled', cancel_reason = $2, cancelled_at = $3 where id = $1`,
            [t.id, b.reason, now],
          );
          await notifyAttendees(q, t.id, 'meetup_cancelled', { reason: b.reason });
        }
      });
      void reply.code(204);
    },
  );

  async function notifyAttendees(q: Queryable, meetupId: string, kind: string, extra: Record<string, unknown>): Promise<void> {
    const r = await q.query<{ user_id: string }>(
      `select distinct p.user_id from meetup_rsvps r join profiles p on p.id = r.profile_id
        where r.meetup_id = $1 and r.status in ('going', 'waitlist') and p.kind = 'adult' and p.user_id is not null`,
      [meetupId],
    );
    for (const u of r.rows) await notify(q, u.user_id, kind, { meetupId, ...extra });
  }

  // --------------------------------------------------------------- rsvp
  app.put<{ Params: { id: string } }>(
    '/v1/meetups/:id/rsvp',
    { preHandler: [auth, limit(deps, { name: 'rsvp', max: 40, windowSec: 3600, by: 'user' })] },
    async (request) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      const { id } = parse(idParam, request.params);
      const b = parse(rsvpBody, request.body);
      const member = await requireMember(db, deps, a, { visible: true, rules: true });
      const now = deps.now();
      return db.tx(async (q) => {
        const r = await q.query<{
          organiser_profile_id: string; status: string; starts_at: Date; capacity: number | null; minors_policy: string;
        }>(
          `select organiser_profile_id, status, starts_at, capacity, minors_policy from meetups where id = $1 for update`,
          [id],
        );
        const m = r.rows[0];
        if (!m || m.status !== 'published') throw notFound();
        const bl = await q.query<{ b: boolean }>(`select ${blockedEitherWaySql('$1', '$2')} as b`, [member.profile.id, m.organiser_profile_id]);
        if (bl.rows[0]?.b) throw notFound();
        if (new Date(m.starts_at).getTime() <= now.getTime()) throw conflict('already_started', 'This meet-up has started.');

        const child = b.childProfileId ? await actingProfile(q, a.userId, b.childProfileId) : null;
        if (child && child.kind === 'adult') throw unprocessable('not_a_child', 'That is not a child profile.');
        if (child && m.minors_policy !== 'guardian_rsvp') {
          throw conflict('adults_only', 'This meet-up is for adults only.');
        }

        const used = Number(
          (await q.query<{ n: string }>(`select count(*)::text as n from meetup_rsvps where meetup_id = $1 and status = 'going'`, [id])).rows[0]?.n ?? '0',
        );
        const existing = async (pid: string) =>
          (await q.query<{ status: string }>('select status from meetup_rsvps where meetup_id = $1 and profile_id = $2', [id, pid])).rows[0]?.status;
        const adultNow = await existing(member.profile.id);
        const childNow = child ? await existing(child.id) : undefined;

        // First come, first served. A waiting person keeps their place (their
        // row is not rewritten); a child can only go when their guardian goes.
        let free = m.capacity === null ? Number.POSITIVE_INFINITY : m.capacity - used;
        const isLive = (s: string | undefined) => s === 'going' || s === 'waitlist';
        let adultStatus: string;
        if (isLive(adultNow)) {
          adultStatus = adultNow as string;
        } else {
          adultStatus = free >= 1 ? 'going' : 'waitlist';
          if (adultStatus === 'going') free -= 1;
        }
        let childStatus: string | null = null;
        if (child) {
          if (isLive(childNow)) {
            childStatus = childNow as string;
          } else {
            childStatus = adultStatus === 'going' && free >= 1 ? 'going' : 'waitlist';
            if (childStatus === 'going') free -= 1;
          }
        }

        const upsert = async (pid: string, status: string, guardian: string | null) =>
          q.query(
            `insert into meetup_rsvps (meetup_id, profile_id, status, guardian_user_id, created_at, updated_at, acknowledged_at)
             values ($1, $2, $3, $4, $5, $5, $5)
             on conflict (meetup_id, profile_id) do update set status = excluded.status,
               guardian_user_id = excluded.guardian_user_id, updated_at = excluded.updated_at,
               acknowledged_at = excluded.acknowledged_at,
               reminded_24h_at = null, reminded_2h_at = null`,
            [id, pid, status, guardian, now],
          );
        if (!isLive(adultNow)) await upsert(member.profile.id, adultStatus, null);
        if (child && childStatus && !isLive(childNow)) await upsert(child.id, childStatus, a.userId);
        return { rsvp: { status: adultStatus, childStatus } };
      });
    },
  );

  app.delete<{ Params: { id: string }; Querystring: { childProfileId?: string } }>(
    '/v1/meetups/:id/rsvp',
    { preHandler: [auth] },
    async (request, reply) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      const { id } = parse(idParam, request.params);
      const { childProfileId } = parse(rsvpQuery, request.query);
      const me = await viewer(a.userId);
      if (!me) throw notFound();
      const now = deps.now();
      await db.tx(async (q) => {
        const exists = await q.query('select 1 from meetups where id = $1 for update', [id]);
        if (exists.rowCount === 0) throw notFound();
        if (childProfileId) {
          const child = await actingProfile(q, a.userId, childProfileId);
          await q.query(
            `update meetup_rsvps set status = 'cancelled', updated_at = $3 where meetup_id = $1 and profile_id = $2 and status <> 'cancelled'`,
            [id, child.id, now],
          );
        } else {
          const r = await q.query(
            `update meetup_rsvps set status = 'cancelled', updated_at = $3 where meetup_id = $1 and profile_id = $2 and status <> 'cancelled'`,
            [id, me, now],
          );
          if (r.rowCount === 0) throw notFound();
          // A guardian leaving takes their children off the list too.
          await q.query(
            `update meetup_rsvps set status = 'cancelled', updated_at = $3
              where meetup_id = $1 and guardian_user_id = $2 and status <> 'cancelled'`,
            [id, a.userId, now],
          );
        }
        await promoteWaitlist(q, id, now);
      });
      void reply.code(204);
    },
  );
}

/** Moves people off the waiting list, first come first served, when seats free up. */
export async function promoteWaitlist(q: Queryable, meetupId: string, now: Date): Promise<void> {
  const m = await q.query<{ capacity: number | null }>('select capacity from meetups where id = $1', [meetupId]);
  const capacity = m.rows[0]?.capacity;
  if (capacity === null || capacity === undefined) return;
  const used = Number(
    (await q.query<{ n: string }>(`select count(*)::text as n from meetup_rsvps where meetup_id = $1 and status = 'going'`, [meetupId])).rows[0]?.n ?? '0',
  );
  let free = capacity - used;
  if (free <= 0) return;
  const wl = await q.query<{ profile_id: string; kind: string; user_id: string | null; guardian_user_id: string | null }>(
    `select r.profile_id, p.kind, p.user_id, r.guardian_user_id
       from meetup_rsvps r join profiles p on p.id = r.profile_id
      where r.meetup_id = $1 and r.status = 'waitlist' order by r.updated_at, r.created_at, r.profile_id`,
    [meetupId],
  );
  const promoted = new Set<string>();
  const promote = async (profileId: string) => {
    await q.query(`update meetup_rsvps set status = 'going', updated_at = $3 where meetup_id = $1 and profile_id = $2`, [meetupId, profileId, now]);
    promoted.add(profileId);
  };
  for (const r of wl.rows.filter((x) => x.kind === 'adult')) {
    if (free <= 0) break;
    const kids = wl.rows.filter((x) => x.kind !== 'adult' && x.guardian_user_id === r.user_id);
    const need = 1 + kids.length;
    if (need > free) continue;
    await promote(r.profile_id);
    for (const k of kids) await promote(k.profile_id);
    free -= need;
    if (r.user_id) await notify(q, r.user_id, 'meetup_waitlist_promoted', { meetupId });
  }
  for (const k of wl.rows.filter((x) => x.kind !== 'adult' && !promoted.has(x.profile_id))) {
    if (free <= 0) break;
    const g = await q.query(
      `select 1 from meetup_rsvps r join profiles p on p.id = r.profile_id
        where r.meetup_id = $1 and p.user_id = $2 and r.status = 'going'`,
      [meetupId, k.guardian_user_id],
    );
    if (g.rowCount === 0) continue;
    await promote(k.profile_id);
    free -= 1;
  }
}
