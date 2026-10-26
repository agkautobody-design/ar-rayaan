-- 0003_forums: categories, threads, posts, reactions.
-- Posts always carry a label so a community opinion can never be mistaken for
-- scholarly guidance. Nothing here is ever fed to Hadi as religious guidance.

create table forum_categories (
  id                 uuid primary key default gen_random_uuid(),
  slug               text not null unique check (slug ~ '^[a-z0-9-]{2,40}$'),
  title              text not null,
  description        text not null default '',
  kind               text not null default 'general'
                       check (kind in ('general', 'learning', 'ask_scholar', 'sensitive',
                                       'family', 'announcements')),
  -- Minimum standing needed to start a thread / answer.
  who_can_post       text not null default 'member'
                       check (who_can_post in ('member', 'verified', 'scholar', 'moderator')),
  -- New posts wait in the review queue until a moderator approves them.
  strict_moderation  boolean not null default false,
  adults_only        boolean not null default true,
  sort_order         integer not null default 0,
  archived           boolean not null default false,
  created_at         timestamptz not null default now()
);

create table forum_threads (
  id                 uuid primary key default gen_random_uuid(),
  category_id        uuid not null references forum_categories (id) on delete restrict,
  author_profile_id  uuid not null references profiles (id) on delete restrict,
  title              text not null check (char_length(title) between 4 and 140),
  status             text not null default 'open'
                       check (status in ('open', 'locked', 'hidden', 'removed', 'pending_review')),
  pinned             boolean not null default false,
  post_count         integer not null default 0,
  created_at         timestamptz not null default now(),
  last_post_at       timestamptz not null default now()
);
create index forum_threads_cat_idx on forum_threads (category_id, last_post_at desc);

create table forum_posts (
  id                 uuid primary key default gen_random_uuid(),
  thread_id          uuid not null references forum_threads (id) on delete cascade,
  author_profile_id  uuid not null references profiles (id) on delete restrict,
  reply_to           uuid references forum_posts (id) on delete set null,
  body               text not null check (char_length(body) between 1 and 4000),
  -- community_opinion is the default and is shown with that label.
  -- scholar_answer is only accepted from a verified scholar credential.
  label              text not null default 'community_opinion'
                       check (label in ('community_opinion', 'scholar_answer',
                                        'question', 'announcement')),
  status             text not null default 'visible'
                       check (status in ('visible', 'hidden', 'removed', 'pending_review')),
  edited_at          timestamptz,
  created_at         timestamptz not null default now()
);
create index forum_posts_thread_idx on forum_posts (thread_id, created_at);

-- No downvotes. Three gentle reactions only.
create table forum_reactions (
  post_id     uuid not null references forum_posts (id) on delete cascade,
  profile_id  uuid not null references profiles (id) on delete cascade,
  kind        text not null check (kind in ('benefit', 'dua', 'thanks')),
  created_at  timestamptz not null default now(),
  primary key (post_id, profile_id, kind)
);
