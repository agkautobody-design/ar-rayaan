-- 0002_social: friend graph, blocks, invites.

create table invites (
  id                  uuid primary key default gen_random_uuid(),
  -- Keyed hash of the code. The code is shown once, when created.
  code_hash           text not null unique,
  kind                text not null check (kind in ('friend', 'room', 'meetup', 'family')),
  -- The profile the invite speaks for. For an invite a guardian issues for a
  -- child this is the child's profile; created_by_user is still the guardian.
  created_by_profile  uuid not null references profiles (id) on delete cascade,
  created_by_user     uuid not null references users (id) on delete cascade,
  -- What the invite opens: a meet-up id (kind 'meetup') or the six-letter code
  -- of a Firestore game table (kind 'room'; tables live in Firestore, see the
  -- plan, section 2). Null for friend invites.
  target_ref          text,
  max_uses            integer not null default 1 check (max_uses between 1 and 50),
  uses                integer not null default 0 check (uses >= 0),
  expires_at          timestamptz not null,
  revoked_at          timestamptz,
  created_at          timestamptz not null default now(),
  constraint invites_uses_within_max check (uses <= max_uses)
);
create index invites_creator_idx on invites (created_by_user);

create table invite_redemptions (
  invite_id    uuid not null references invites (id) on delete cascade,
  profile_id   uuid not null references profiles (id) on delete cascade,
  redeemed_at  timestamptz not null default now(),
  primary key (invite_id, profile_id)
);

-- One row per pair. profile_lo < profile_hi so a pair cannot be stored twice.
create table friendships (
  id                uuid primary key default gen_random_uuid(),
  profile_lo        uuid not null references profiles (id) on delete cascade,
  profile_hi        uuid not null references profiles (id) on delete cascade,
  requested_by      uuid not null references profiles (id) on delete cascade,
  status            text not null default 'pending'
                      check (status in ('pending', 'accepted', 'declined', 'removed')),
  via               text not null check (via in ('handle', 'invite')),
  invite_id         uuid references invites (id) on delete set null,
  -- A guardian's approval for a minor on each side. Set when the guardian
  -- creates or redeems the invite for the child.
  guardian_lo_user  uuid references users (id) on delete set null,
  guardian_lo_at    timestamptz,
  guardian_hi_user  uuid references users (id) on delete set null,
  guardian_hi_at    timestamptz,
  created_at        timestamptz not null default now(),
  responded_at      timestamptz,
  constraint friendships_ordered check (profile_lo < profile_hi),
  constraint friendships_requester_is_member check (requested_by in (profile_lo, profile_hi)),
  unique (profile_lo, profile_hi)
);
create index friendships_hi_idx on friendships (profile_hi);

-- Defence in depth for the child-safety rules (the API enforces them first):
--   * a minor profile can only be friends with another minor profile;
--   * an accepted friendship needs a guardian approval for every minor side.
create function friendships_guard() returns trigger
language plpgsql as $$
declare
  kind_lo text;
  kind_hi text;
begin
  select kind into kind_lo from profiles where id = new.profile_lo;
  select kind into kind_hi from profiles where id = new.profile_hi;
  if (kind_lo = 'adult') <> (kind_hi = 'adult') then
    raise exception 'minor_adult_friendship_forbidden' using errcode = '23514';
  end if;
  if new.status = 'accepted' then
    if kind_lo <> 'adult' and new.guardian_lo_at is null then
      raise exception 'guardian_approval_required' using errcode = '23514';
    end if;
    if kind_hi <> 'adult' and new.guardian_hi_at is null then
      raise exception 'guardian_approval_required' using errcode = '23514';
    end if;
  end if;
  return new;
end;
$$;

create trigger friendships_guard_trg
  before insert or update on friendships
  for each row execute function friendships_guard();

create table blocks (
  blocker_profile  uuid not null references profiles (id) on delete cascade,
  blocked_profile  uuid not null references profiles (id) on delete cascade,
  created_at       timestamptz not null default now(),
  primary key (blocker_profile, blocked_profile),
  constraint blocks_not_self check (blocker_profile <> blocked_profile)
);
