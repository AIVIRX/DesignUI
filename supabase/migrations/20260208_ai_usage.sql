-- AI usage tracking and limits
create table if not exists public.ai_usage (
  user_id uuid not null,
  day date not null,
  count integer not null default 0,
  last_request_at timestamptz,
  updated_at timestamptz not null default now(),
  primary key (user_id, day)
);

create index if not exists ai_usage_day_idx on public.ai_usage (day);
