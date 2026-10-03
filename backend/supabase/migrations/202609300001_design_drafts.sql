create table if not exists public.design_drafts (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid not null references auth.users(id) on delete cascade,
    title text not null,
    prompt text not null,
    device_preset text not null,
    design_json jsonb not null,
    status text not null default 'draft' check (status in ('draft', 'published', 'dismissed')),
    created_at timestamptz not null default now(),
    reviewed_at timestamptz
);

create index if not exists design_drafts_owner_status_created_idx
    on public.design_drafts (owner_id, status, created_at desc);

alter table public.design_drafts enable row level security;

create policy "Owner can read their design drafts"
    on public.design_drafts for select
    using (auth.uid() = owner_id);

create policy "Owner can update their design drafts"
    on public.design_drafts for update
    using (auth.uid() = owner_id)
    with check (auth.uid() = owner_id);

create policy "Owner can delete their design drafts"
    on public.design_drafts for delete
    using (auth.uid() = owner_id);
