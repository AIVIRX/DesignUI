create table if not exists public.ai_generation_outcomes (
    generation_id uuid primary key references public.ai_generations(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    final_screen jsonb,
    latest_event text not null check (latest_event in ('applied', 'edited', 'regenerated', 'kept', 'undone', 'exported')),
    edit_count integer not null default 0 check (edit_count >= 0),
    elapsed_ms integer check (elapsed_ms is null or elapsed_ms >= 0),
    time_to_first_edit_ms integer check (time_to_first_edit_ms is null or time_to_first_edit_ms >= 0),
    structural_change_score double precision check (structural_change_score is null or structural_change_score between 0 and 1),
    outcome_score double precision not null default 0 check (outcome_score between 0 and 1),
    learning_consent boolean not null default false,
    eligible_for_learning boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists ai_generation_outcomes_user_updated_idx
    on public.ai_generation_outcomes (user_id, updated_at desc);

create index if not exists ai_generation_outcomes_learning_candidates_idx
    on public.ai_generation_outcomes (outcome_score desc, updated_at desc)
    where learning_consent = true and eligible_for_learning = true;

alter table public.ai_generation_outcomes enable row level security;

create policy "Users can read their AI generation outcomes"
    on public.ai_generation_outcomes for select
    using (auth.uid() = user_id);

comment on table public.ai_generation_outcomes is
    'Private generation outcomes. Rows are never eligible for shared retrieval without explicit consent and a separate quality review.';
