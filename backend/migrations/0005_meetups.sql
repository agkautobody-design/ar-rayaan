-- 0005_meetups: public-venue meet-ups and RSVPs.
-- There is deliberately no column for a private address: venue_kind has no
-- 'home' value, locations are rounded to about 100 m, and a meet-up cannot be
-- published until it has been reviewed (or the organiser holds a verified
-- organiser credential).

create table meetups (
  id                     uuid primary key default gen_random_uuid(),
  organiser_profile_id   uuid not null references profiles (id) on delete restrict,
  organiser_credential_id uuid references credentials (id) on delete set null,
  title                  text not null check (char_length(title) between 4 and 120),
  description            text not null default '' check (char_length(description) <= 2000),
  venue_kind             text not null
                           check (venue_kind in ('mosque', 'community_centre', 'library',
                                                 'cafe', 'park', 'school_hall', 'other_public')),
  venue_name             text not null check (char_length(venue_name) between 2 and 120),
  venue_address          text check (venue_address is null or char_length(venue_address) <= 200),
  city                   text not null,
  region                 text,
  country                text not null check (char_length(country) = 2),
  -- Rounded to 3 decimals (about 100 m). Never an exact doorstep.
  lat                    numeric(6, 3),
  lng                    numeric(6, 3),
  starts_at              timestamptz not null,
  ends_at                timestamptz,
  audience               text not null default 'open'
                           check (audience in ('open', 'brothers', 'sisters', 'families')),
  -- adults_only: no one under 18. guardian_rsvp: a minor can attend only when
  -- a guardian RSVPs for them and attends.
  minors_policy          text not null default 'adults_only'
                           check (minors_policy in ('adults_only', 'guardian_rsvp')),
  capacity               integer check (capacity is null or capacity between 2 and 500),
  accessibility_notes    text check (accessibility_notes is null or char_length(accessibility_notes) <= 300),
  status                 text not null default 'draft'
                           check (status in ('draft', 'pending_review', 'published',
                                             'cancelled', 'hidden')),
  reviewed_by            uuid references users (id) on delete set null,
  created_at             timestamptz not null default now(),
  published_at           timestamptz,
  constraint meetups_ends_after_start check (ends_at is null or ends_at > starts_at)
);
create index meetups_listing_idx on meetups (status, starts_at);

create table meetup_rsvps (
  meetup_id         uuid not null references meetups (id) on delete cascade,
  profile_id        uuid not null references profiles (id) on delete cascade,
  status            text not null default 'going'
                      check (status in ('going', 'waitlist', 'cancelled')),
  -- Set when the attendee is a minor: the guardian who RSVPs and attends.
  guardian_user_id  uuid references users (id) on delete set null,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  primary key (meetup_id, profile_id)
);
