-- Tracks all AI prompts sent through the StudioAI edge function.
-- Run this in Supabase SQL editor before/with deploying the function update.

create table if not exists public.ai_prompts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  prompt text not null,
  prompt_length integer not null default 0,
  selected_component_type text,
  has_selection boolean not null default false,
  generation_mode text not null default 'selection_or_standard',
  daily_count_at_request integer not null default 0,
  daily_limit integer not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists ai_prompts_user_created_idx
  on public.ai_prompts (user_id, created_at desc);

create index if not exists ai_prompts_created_idx
  on public.ai_prompts (created_at desc);

alter table public.ai_prompts enable row level security;

drop policy if exists "Users can read own ai prompts" on public.ai_prompts;
create policy "Users can read own ai prompts"
  on public.ai_prompts
  for select
  using (auth.uid() = user_id);

