import assert from 'node:assert/strict';
import { cp, mkdtemp, readFile, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { after, before, describe, it } from 'node:test';
import type { Db } from '../src/db.js';
import { sqlState } from '../src/db.js';
import { MIGRATIONS_DIR, migrate } from '../src/migrate.js';
import { openTestDb } from './helpers.js';

const EXPECTED_TABLES = [
  'users', 'sessions', 'auth_codes', 'profiles', 'parental_links', 'consents', 'audit_log',
  'invites', 'invite_redemptions', 'friendships', 'blocks',
  'forum_categories', 'forum_threads', 'forum_posts', 'forum_reactions',
  'credentials', 'reports', 'moderation_actions', 'strikes', 'sanctions', 'appeals', 'content_filters',
  'meetups', 'meetup_rsvps', 'notifications', 'push_subscriptions', 'user_hidden', 'schema_migrations',
];

describe('migrations and schema', () => {
  let db: Db;
  before(async () => {
    db = await openTestDb();
  });
  after(async () => {
    await db.close();
  });

  const user = async (email: string) =>
    (
      await db.query<{ id: string }>(
        `insert into users (email, email_hash) values ($1, $1) returning id`,
        [email],
      )
    ).rows[0]!.id;
  const profile = async (kind: 'adult' | 'child' | 'teen', ownerId: string, name: string) =>
    (
      await db.query<{ id: string }>(
        kind === 'adult'
          ? `insert into profiles (kind, user_id, display_name) values ('adult', $1, $2) returning id`
          : `insert into profiles (kind, managed_by, display_name) values ($2, $1, $3) returning id`,
        kind === 'adult' ? [ownerId, name] : [ownerId, kind, name],
      )
    ).rows[0]!.id;

  it('creates every table in the plan', async () => {
    const r = await db.query<{ table_name: string }>(
      `select table_name from information_schema.tables where table_schema = 'public'`,
    );
    const have = new Set(r.rows.map((x) => x.table_name));
    for (const t of EXPECTED_TABLES) assert.ok(have.has(t), `missing table ${t}`);
  });

  it('is idempotent and detects an edited migration', async () => {
    const again = await migrate(db);
    assert.equal(again.applied.length, 0);
    assert.ok(again.skipped.length >= 7);

    const tmp = await mkdtemp(path.join(os.tmpdir(), 'mig-'));
    await cp(MIGRATIONS_DIR, tmp, { recursive: true });
    const f = path.join(tmp, '0001_core.sql');
    await writeFile(f, `${await readFile(f, 'utf8')}\n-- tampered\n`);
    await assert.rejects(migrate(db, tmp), /checksum mismatch/);
  });

  it('keeps the audit log append-only', async () => {
    await db.query(`insert into audit_log (action) values ('test.event')`);
    await assert.rejects(db.query(`update audit_log set action = 'x'`), /append-only/);
    await assert.rejects(db.query(`delete from audit_log`), /append-only/);
  });

  it('refuses a minor profile that has a handle, a bio, or a public setting', async () => {
    const g = await user('g1@example.test');
    for (const extra of ["handle = 'kid_one'", "bio = 'hi'", "visibility = 'handle'"]) {
      const id = await profile('child', g, 'Kid');
      await assert.rejects(
        db.query(`update profiles set ${extra} where id = $1`, [id]),
        (e) => sqlState(e) === '23514',
        extra,
      );
    }
  });

  it('requires an owner on every profile', async () => {
    await assert.rejects(
      db.query(`insert into profiles (kind, display_name) values ('adult', 'Nobody')`),
      (e) => sqlState(e) === '23514',
    );
    await assert.rejects(
      db.query(`insert into profiles (kind, display_name, managed_by) values ('adult', 'X', null)`),
      (e) => sqlState(e) === '23514',
    );
  });

  it('forbids an adult-minor friendship at the database level', async () => {
    const g = await user('g2@example.test');
    const adult = await profile('adult', g, 'Adult One');
    const kid = await profile('child', g, 'Kid Two');
    const [lo, hi] = adult < kid ? [adult, kid] : [kid, adult];
    await assert.rejects(
      db.query(
        `insert into friendships (profile_lo, profile_hi, requested_by, status, via) values ($1,$2,$1,'pending','invite')`,
        [lo, hi],
      ),
      /minor_adult_friendship_forbidden/,
    );
  });

  it('forbids an accepted minor friendship without guardian approval on both sides', async () => {
    const g1 = await user('g3@example.test');
    const g2 = await user('g4@example.test');
    const a = await profile('child', g1, 'Kid A');
    const b = await profile('child', g2, 'Kid B');
    const [lo, hi] = a < b ? [a, b] : [b, a];
    await assert.rejects(
      db.query(
        `insert into friendships (profile_lo, profile_hi, requested_by, status, via) values ($1,$2,$1,'accepted','invite')`,
        [lo, hi],
      ),
      /guardian_approval_required/,
    );
    await assert.rejects(
      db.query(
        `insert into friendships (profile_lo, profile_hi, requested_by, status, via, guardian_lo_at)
         values ($1,$2,$1,'accepted','invite', now())`,
        [lo, hi],
      ),
      /guardian_approval_required/,
    );
    await db.query(
      `insert into friendships (profile_lo, profile_hi, requested_by, status, via, guardian_lo_at, guardian_hi_at)
       values ($1,$2,$1,'accepted','invite', now(), now())`,
      [lo, hi],
    );
  });

  it('stores a pair once and keeps the pair ordered', async () => {
    const g = await user('g5@example.test');
    const g2 = await user('g6@example.test');
    const a = await profile('adult', g, 'Adult A');
    const b = await profile('adult', g2, 'Adult B');
    const [lo, hi] = a < b ? [a, b] : [b, a];
    await assert.rejects(
      db.query(`insert into friendships (profile_lo, profile_hi, requested_by, via) values ($1,$2,$1,'handle')`, [hi, lo]),
      (e) => sqlState(e) === '23514',
    );
    await db.query(`insert into friendships (profile_lo, profile_hi, requested_by, via) values ($1,$2,$1,'handle')`, [lo, hi]);
    await assert.rejects(
      db.query(`insert into friendships (profile_lo, profile_hi, requested_by, via) values ($1,$2,$1,'handle')`, [lo, hi]),
      (e) => sqlState(e) === '23505',
    );
  });

  it('has no way to store a private address for a meet-up', async () => {
    const g = await user('g8@example.test');
    const p = await profile('adult', g, 'Organiser');
    await assert.rejects(
      db.query(
        `insert into meetups (organiser_profile_id, title, venue_kind, venue_name, city, country, starts_at)
         values ($1, 'Tea together', 'home', 'My house', 'Toronto', 'CA', now() + interval '3 day')`,
        [p],
      ),
      (e) => sqlState(e) === '23514',
    );
    const cols = await db.query<{ column_name: string }>(
      `select column_name from information_schema.columns where table_name = 'meetups'`,
    );
    assert.ok(!cols.rows.some((c) => /home|private/.test(c.column_name)));
  });
});
