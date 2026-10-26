-- 0007_community_phase2: forum rules per category, seeded categories, report
-- de-duplication, personal "hide", meet-up recurrence/reminders, and database
-- guards that keep minors out of forums and meet-ups even if a route has a bug.
--
-- DRAFT: category names, rules text and limits are proposals for the owner and
-- a scholar to review (docs/product/community_rules_draft.md).

-- ---------------------------------------------------------------- categories
alter table forum_categories drop constraint forum_categories_kind_check;
alter table forum_categories add constraint forum_categories_kind_check
  check (kind in ('general', 'learning', 'ask_scholar', 'sensitive',
                  'family', 'announcements', 'wellbeing'));

-- who_can_post = who may START a thread; who_can_reply = who may answer.
-- "Ask a scholar" lets members ask but only a verified scholar answer, so a
-- community opinion can never sit next to (or pose as) a scholar's answer.
alter table forum_categories add column who_can_reply text not null default 'member'
  check (who_can_reply in ('member', 'verified', 'scholar', 'moderator'));
alter table forum_categories add column rules_note text not null default '';

insert into forum_categories
  (slug, title, description, kind, who_can_post, who_can_reply, strict_moderation, sort_order, rules_note)
values
  ('welcome', 'Welcome and introductions',
   'Say salam and introduce yourself. Be kind to people who are new.',
   'general', 'member', 'member', false, 10,
   'Introductions only. Do not share contact details or where you live.'),
  ('learning', 'Learning together',
   'Study questions and tips about the Qur''an, Arabic and tajweed, shared as fellow learners.',
   'learning', 'member', 'member', false, 20,
   'Replies here are community opinion, not rulings. Questions that need a ruling belong in Ask a scholar.'),
  ('daily-life', 'Daily life and family',
   'Everyday life, family, work and community, with adab.',
   'family', 'member', 'member', false, 30,
   'No private information about other people. No photos.'),
  ('ask-scholar', 'Ask a scholar',
   'Ask a question. Only verified scholars answer here, and their answers are labelled.',
   'ask_scholar', 'member', 'scholar', true, 40,
   'Every question is read by a moderator before it appears. Community members do not answer here.'),
  ('wellbeing', 'Wellbeing and support',
   'Gentle support for the heart and mind. Support, not diagnosis.',
   'wellbeing', 'member', 'member', false, 50,
   'If you are in danger, contact local emergency services or a crisis line now.'),
  ('announcements', 'Announcements',
   'News from the Ar-Rayaan team.',
   'announcements', 'moderator', 'moderator', false, 60,
   'Staff only.'),
  ('sensitive', 'Sensitive topics',
   'Differences between schools of thought and other delicate subjects, discussed with respect. Every post is reviewed before it appears.',
   'sensitive', 'member', 'member', true, 70,
   'No takfir (declaring others out of the faith), no fatwa-giving, no insults. Posts that break this are removed.');

-- ------------------------------------------------------------------- posts
alter table forum_posts add column credential_id uuid references credentials (id) on delete set null;
create index forum_posts_author_idx on forum_posts (author_profile_id);
create index forum_posts_review_idx on forum_posts (status) where status = 'pending_review';

-- One gentle reaction. The older kinds stay allowed so nothing already stored breaks.
alter table forum_reactions drop constraint forum_reactions_kind_check;
alter table forum_reactions add constraint forum_reactions_kind_check
  check (kind in ('helpful', 'benefit', 'dua', 'thanks'));

-- ----------------------------------------------------------------- reports
alter table reports add column auto boolean not null default false;
-- A person can have one live report per target; reporting twice is a no-op.
create unique index reports_one_open_per_reporter
  on reports (reporter_profile_id, target_type, target_id)
  where status in ('open', 'triaged') and reporter_profile_id is not null;

alter table appeals add column decision_note text;
create index appeals_status_idx on appeals (status, created_at);

-- Content a person has hidden for themselves (not a report).
create table user_hidden (
  profile_id  uuid not null references profiles (id) on delete cascade,
  target_type text not null check (target_type in ('post', 'thread', 'meetup')),
  target_id   uuid not null,
  created_at  timestamptz not null default now(),
  primary key (profile_id, target_type, target_id)
);

-- ----------------------------------------------------------------- meet-ups
alter table meetups add column recurrence text not null default 'none'
  check (recurrence in ('none', 'weekly', 'biweekly', 'monthly'));
-- Occurrences of a recurring meet-up are separate rows (own capacity and
-- RSVPs) that share a series id.
alter table meetups add column series_id uuid;
alter table meetups add column series_index integer not null default 0;
-- A cafe is accepted only when the organiser confirms it is halal.
alter table meetups add column halal_confirmed boolean not null default false;
alter table meetups add column cancel_reason text;
alter table meetups add column cancelled_at timestamptz;
create index meetups_series_idx on meetups (series_id) where series_id is not null;
create index meetups_organiser_idx on meetups (organiser_profile_id);
create index meetups_review_idx on meetups (status) where status = 'pending_review';

alter table meetup_rsvps add column reminded_24h_at timestamptz;
alter table meetup_rsvps add column reminded_2h_at timestamptz;
alter table meetup_rsvps add column acknowledged_at timestamptz;
create index meetup_rsvps_profile_idx on meetup_rsvps (profile_id);

-- ------------------------------------------------- defence in depth (minors)
-- The API already refuses these; the database refuses them too, so a bug in a
-- route cannot put a child in a forum or on a meet-up alone.
create function require_adult_profile() returns trigger
language plpgsql as $$
declare
  k text;
begin
  select kind into k from profiles where id = (to_jsonb(new) ->> TG_ARGV[0])::uuid;
  if k is distinct from 'adult' then
    raise exception 'only adult profiles can use %', TG_TABLE_NAME using errcode = '23514';
  end if;
  return new;
end;
$$;

create trigger forum_threads_adult_only before insert on forum_threads
  for each row execute function require_adult_profile('author_profile_id');
create trigger forum_posts_adult_only before insert on forum_posts
  for each row execute function require_adult_profile('author_profile_id');
create trigger forum_reactions_adult_only before insert on forum_reactions
  for each row execute function require_adult_profile('profile_id');
create trigger meetups_adult_organiser before insert on meetups
  for each row execute function require_adult_profile('organiser_profile_id');

-- A minor can hold an RSVP only when their own guardian is named on it and the
-- meet-up allows guardian RSVPs.
create function meetup_rsvp_guard() returns trigger
language plpgsql as $$
declare
  k text;
  owner uuid;
  policy text;
begin
  select kind, managed_by into k, owner from profiles where id = new.profile_id;
  if k = 'adult' then
    return new;
  end if;
  select minors_policy into policy from meetups where id = new.meetup_id;
  if policy is distinct from 'guardian_rsvp' then
    raise exception 'this meet-up is for adults only' using errcode = '23514';
  end if;
  if new.guardian_user_id is null or new.guardian_user_id is distinct from owner then
    raise exception 'a guardian must RSVP for a minor' using errcode = '23514';
  end if;
  return new;
end;
$$;

create trigger meetup_rsvps_guard before insert or update on meetup_rsvps
  for each row execute function meetup_rsvp_guard();
