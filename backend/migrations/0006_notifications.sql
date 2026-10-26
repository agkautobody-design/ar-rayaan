-- 0006_notifications: in-app notifications and (later) web-push subscriptions.
-- A notification payload holds ids and a short code, never names or message
-- text; the client renders the words.

create table notifications (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references users (id) on delete cascade,
  kind        text not null,
  payload     jsonb not null default '{}'::jsonb,
  read_at     timestamptz,
  created_at  timestamptz not null default now()
);
create index notifications_user_idx on notifications (user_id, created_at desc);

-- Reserved for the web-push phase. Empty until then.
create table push_subscriptions (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references users (id) on delete cascade,
  endpoint    text not null unique,
  p256dh      text not null,
  auth_secret text not null,
  created_at  timestamptz not null default now()
);
