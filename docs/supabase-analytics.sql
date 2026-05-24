-- LegitApp Supabase analytics schema.
-- Run this in the Supabase SQL editor, then fill LegitAppSupabaseURL and
-- LegitAppSupabaseAnonKey in LegitApp-Info.plist.

create extension if not exists pgcrypto;

create table if not exists public.legitapp_events (
    id uuid primary key default gen_random_uuid(),
    created_at timestamptz not null default now(),
    event_name text not null check (
        event_name in (
            'app_open',
            'dmg_download_click',
            'cask_install_success',
            'cask_uninstall_success',
            'cask_update_success',
            'cask_reinstall_success'
        )
    ),
    anonymous_user_id uuid not null,
    app_version text,
    os_version text,
    cask_id text,
    cask_name text,
    cask_tap text,
    install_method text,
    source text not null default 'macos_app'
);

create index if not exists legitapp_events_created_at_idx
    on public.legitapp_events (created_at desc);

create index if not exists legitapp_events_event_name_idx
    on public.legitapp_events (event_name);

create index if not exists legitapp_events_cask_id_idx
    on public.legitapp_events (cask_id)
    where cask_id is not null;

alter table public.legitapp_events enable row level security;

revoke all on public.legitapp_events from anon;
grant insert on public.legitapp_events to anon;

drop policy if exists "Allow anonymous analytics inserts" on public.legitapp_events;

create policy "Allow anonymous analytics inserts"
    on public.legitapp_events
    for insert
    to anon
    with check (true);

create or replace view public.legitapp_event_counts as
select
    event_name,
    count(*) as event_count
from public.legitapp_events
group by event_name;

alter view public.legitapp_event_counts set (security_invoker = true);

create or replace view public.legitapp_download_clicks as
select
    date_trunc('day', created_at)::date as download_date,
    count(*) as download_clicks,
    count(distinct anonymous_user_id) as unique_downloaders
from public.legitapp_events
where event_name = 'dmg_download_click'
group by download_date
order by download_date desc;

alter view public.legitapp_download_clicks set (security_invoker = true);

create or replace view public.legitapp_daily_active_users as
select
    date_trunc('day', created_at)::date as active_date,
    count(distinct anonymous_user_id) as active_users
from public.legitapp_events
where event_name = 'app_open'
group by active_date
order by active_date desc;

alter view public.legitapp_daily_active_users set (security_invoker = true);

create or replace view public.legitapp_monthly_active_users as
select
    date_trunc('month', created_at)::date as active_month,
    count(distinct anonymous_user_id) as active_users
from public.legitapp_events
where event_name = 'app_open'
group by active_month
order by active_month desc;

alter view public.legitapp_monthly_active_users set (security_invoker = true);

create or replace view public.legitapp_top_installed_casks as
select
    cask_id,
    max(cask_name) as cask_name,
    count(*) as install_count
from public.legitapp_events
where event_name = 'cask_install_success'
    and cask_id is not null
group by cask_id
order by install_count desc;

alter view public.legitapp_top_installed_casks set (security_invoker = true);

create or replace view public.legitapp_uninstall_counts as
select
    cask_id,
    max(cask_name) as cask_name,
    count(*) as uninstall_count
from public.legitapp_events
where event_name = 'cask_uninstall_success'
    and cask_id is not null
group by cask_id
order by uninstall_count desc;

alter view public.legitapp_uninstall_counts set (security_invoker = true);
