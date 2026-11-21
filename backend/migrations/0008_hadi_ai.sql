-- 0008_hadi_ai: the per-person daily count behind Hadi's live-AI route.
-- Counts only: no question, no answer and no memory is ever stored here.

create table hadi_ai_usage (
  user_id uuid not null references users (id) on delete cascade,
  day     date not null,
  count   integer not null default 0,
  primary key (user_id, day)
);
