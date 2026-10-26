-- 0004_moderation: verified credentials, reports, actions, strikes, sanctions,
-- appeals, keyword and link filters.

-- Scholars, meet-up organisers and trusted moderators are verified by a human
-- admin. A credential can expire or be revoked.
create table credentials (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references users (id) on delete cascade,
  kind           text not null check (kind in ('scholar', 'organiser', 'trusted_moderator')),
  org_name       text,
  evidence_note  text,
  verified_by    uuid references users (id) on delete set null,
  verified_at    timestamptz,
  expires_at     timestamptz,
  revoked_at     timestamptz,
  created_at     timestamptz not null default now()
);
create index credentials_user_idx on credentials (user_id, kind);

create table reports (
  id                    uuid primary key default gen_random_uuid(),
  reporter_profile_id   uuid references profiles (id) on delete set null,
  target_type           text not null
                          check (target_type in ('post', 'thread', 'profile', 'meetup', 'room')),
  target_id             uuid not null,
  reason                text not null
                          check (reason in ('abuse', 'harassment', 'hate', 'sectarian',
                                            'religious_misinformation', 'sexual',
                                            'child_safety', 'spam', 'privacy', 'scam', 'other')),
  details               text check (details is null or char_length(details) <= 1000),
  status                text not null default 'open'
                          check (status in ('open', 'triaged', 'actioned', 'dismissed')),
  -- child_safety reports are created with a high priority and jump the queue.
  priority              integer not null default 0,
  created_at            timestamptz not null default now(),
  handled_by            uuid references users (id) on delete set null,
  handled_at            timestamptz,
  resolution            text
);
create index reports_queue_idx on reports (status, priority desc, created_at);
create index reports_target_idx on reports (target_type, target_id);

create table moderation_actions (
  id                 uuid primary key default gen_random_uuid(),
  moderator_user_id  uuid references users (id) on delete set null,
  target_user_id     uuid references users (id) on delete set null,
  target_type        text,
  target_id          uuid,
  action             text not null
                       check (action in ('hide', 'restore', 'remove', 'lock_thread',
                                         'unlock_thread', 'warn', 'mute', 'suspend', 'ban',
                                         'unban', 'verify_credential', 'revoke_credential')),
  -- Every action carries a reason the affected person can read.
  reason             text not null,
  report_id          uuid references reports (id) on delete set null,
  expires_at         timestamptz,
  created_at         timestamptz not null default now()
);
create index moderation_actions_target_idx on moderation_actions (target_user_id, created_at desc);

create table strikes (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references users (id) on delete cascade,
  action_id   uuid references moderation_actions (id) on delete set null,
  points      integer not null check (points between 1 and 10),
  created_at  timestamptz not null default now(),
  expires_at  timestamptz not null
);
create index strikes_user_idx on strikes (user_id, expires_at);

create table sanctions (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references users (id) on delete cascade,
  kind       text not null check (kind in ('mute', 'suspend', 'ban')),
  starts_at  timestamptz not null default now(),
  -- null = until lifted by a human.
  ends_at    timestamptz,
  action_id  uuid references moderation_actions (id) on delete set null,
  lifted_at  timestamptz
);
create index sanctions_user_idx on sanctions (user_id);

create table appeals (
  id          uuid primary key default gen_random_uuid(),
  action_id   uuid not null references moderation_actions (id) on delete cascade,
  user_id     uuid not null references users (id) on delete cascade,
  statement   text not null check (char_length(statement) between 1 and 2000),
  status      text not null default 'open'
                check (status in ('open', 'upheld', 'reduced', 'denied')),
  decided_by  uuid references users (id) on delete set null,
  decided_at  timestamptz,
  created_at  timestamptz not null default now(),
  -- One appeal per action. A different moderator decides (checked in the API).
  unique (action_id, user_id)
);

create table content_filters (
  id          uuid primary key default gen_random_uuid(),
  -- block_word: refused outright. review_word: post goes to the review queue.
  -- block_link: link domains refused. allow_domain: link domains allowed
  -- (links are refused for new accounts unless the domain is on this list).
  kind        text not null check (kind in ('block_word', 'review_word', 'block_link', 'allow_domain')),
  pattern     text not null check (char_length(pattern) between 1 and 200),
  note        text,
  active      boolean not null default true,
  created_by  uuid references users (id) on delete set null,
  created_at  timestamptz not null default now()
);
