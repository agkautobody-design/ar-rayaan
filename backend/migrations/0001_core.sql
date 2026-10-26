-- 0001_core: accounts, sessions, one-time email codes, profiles, guardian links,
-- consent records, audit log.
--
-- Conventions for every migration in this directory:
--   * plain SQL that runs on PostgreSQL 16 (Render) and on PGlite (tests);
--   * text + CHECK constraints instead of enum types (cheaper to change);
--   * ids are uuid (gen_random_uuid, built in since PostgreSQL 13);
--   * all times are timestamptz;
--   * never edit a migration after it has been applied anywhere: add a new one.

create table users (
  id                 uuid primary key default gen_random_uuid(),
  -- The address is kept only so a sign-in code can be sent. Null after erasure.
  email              text,
  -- HMAC-SHA256(PEPPER, normalised email), hex. Used for lookups and logs so
  -- the plain address never has to leave this table.
  email_hash         text unique,
  -- Firebase Authentication uid, when the person signed in through the app's
  -- existing Firebase identity (the production path). Null for e-mail-code
  -- accounts. Cleared on erasure.
  firebase_uid       text unique,
  role               text not null default 'member'
                       check (role in ('member', 'moderator', 'admin')),
  status             text not null default 'active'
                       check (status in ('active', 'suspended', 'banned', 'deleted')),
  -- Self-registered accounts are adults only (phase 1). We store that the
  -- person confirmed it and when, never a date of birth.
  adult_attested_at  timestamptz,
  locale             text,
  created_at         timestamptz not null default now(),
  last_login_at      timestamptz,
  deleted_at         timestamptz,
  -- A deleted account has no address and no hash. A banned account that was
  -- erased keeps only the keyed hash, so the ban cannot be dodged by re-joining
  -- (see the plan, section 9).
  constraint users_hash_present check (status = 'deleted' or email_hash is not null)
);

create table sessions (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references users (id) on delete cascade,
  -- SHA-256 of the bearer token. The token itself is never stored.
  token_hash    text not null unique,
  device_label  text,
  created_at    timestamptz not null default now(),
  last_seen_at  timestamptz not null default now(),
  expires_at    timestamptz not null,
  revoked_at    timestamptz
);
create index sessions_user_idx on sessions (user_id);

-- One-time sign-in codes. Only a keyed hash of the code is stored.
create table auth_codes (
  id              uuid primary key default gen_random_uuid(),
  email_hash      text not null,
  code_hash       text not null,
  attempts        integer not null default 0,
  created_at      timestamptz not null default now(),
  expires_at      timestamptz not null,
  consumed_at     timestamptz,
  -- Keyed hash of the requester's network address, for abuse analysis only.
  -- Purged with the row (retention job).
  requester_hash  text
);
create index auth_codes_email_idx on auth_codes (email_hash, created_at desc);

-- A profile is what other people see (or, for a child, what a parent manages).
-- Phase 1: 'adult' profiles belong to a login (user_id); 'teen' and 'child'
-- profiles have NO login: they are managed by a guardian's account
-- (managed_by). A later migration may relax the owner rule for teens.
create table profiles (
  id            uuid primary key default gen_random_uuid(),
  kind          text not null check (kind in ('adult', 'teen', 'child')),
  user_id       uuid unique references users (id) on delete cascade,
  managed_by    uuid references users (id) on delete cascade,
  display_name  text not null,
  handle        text,
  bio           text,
  -- private: reachable only through an invite. handle: findable by exact
  -- handle. community: display name may appear on forum posts and meet-ups.
  visibility    text not null default 'private'
                  check (visibility in ('private', 'handle', 'community')),
  avatar_key    text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  erased_at     timestamptz,
  constraint profiles_one_owner check ((user_id is not null) <> (managed_by is not null)),
  constraint profiles_adult_has_login check (kind <> 'adult' or user_id is not null),
  constraint profiles_minor_is_managed check (kind = 'adult' or managed_by is not null),
  -- A minor profile is never public, never has a handle or a bio.
  constraint profiles_minor_is_private
    check (kind = 'adult' or (visibility = 'private' and handle is null and bio is null)),
  constraint profiles_handle_shape check (handle is null or handle ~ '^[a-z0-9_]{3,20}$')
);
create unique index profiles_handle_key on profiles (handle) where handle is not null;
create index profiles_managed_by_idx on profiles (managed_by) where managed_by is not null;

create table parental_links (
  id                uuid primary key default gen_random_uuid(),
  guardian_user_id  uuid not null references users (id) on delete cascade,
  ward_profile_id   uuid not null references profiles (id) on delete cascade,
  status            text not null default 'active'
                      check (status in ('pending', 'active', 'revoked')),
  -- Version of the parent-consent text the guardian agreed to.
  consent_version   text not null,
  consented_at      timestamptz not null default now(),
  revoked_at        timestamptz,
  unique (guardian_user_id, ward_profile_id)
);
create index parental_links_ward_idx on parental_links (ward_profile_id);

create table consents (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid not null references users (id) on delete cascade,
  kind                text not null
                        check (kind in ('terms', 'privacy', 'community_rules',
                                        'parent_consent', 'ai_assist')),
  version             text not null,
  -- For parent_consent: the child profile the consent is about.
  subject_profile_id  uuid references profiles (id) on delete set null,
  given_at            timestamptz not null default now(),
  withdrawn_at        timestamptz
);
create index consents_user_idx on consents (user_id);

-- Append-only record of security-relevant events. Holds ids and codes, never
-- names, e-mail addresses or message text.
create table audit_log (
  id             bigint generated always as identity primary key,
  at             timestamptz not null default now(),
  actor_user_id  uuid,
  actor_role     text,
  action         text not null,
  target_type    text,
  target_id      text,
  meta           jsonb not null default '{}'::jsonb
);
create index audit_log_at_idx on audit_log (at);
create index audit_log_actor_idx on audit_log (actor_user_id);

create function audit_log_is_append_only() returns trigger
language plpgsql as $$
begin
  raise exception 'audit_log is append-only' using errcode = '23514';
end;
$$;

create trigger audit_log_no_update
  before update or delete on audit_log
  for each row execute function audit_log_is_append_only();
