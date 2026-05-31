-- LegitApp Supabase security & performance migration.
-- Run this AFTER supabase-analytics.sql.
-- All statements are idempotent — safe to re-run.

-- =========================================================
-- 1. Input validation: field-length constraints
--    Prevents oversized payloads and junk data injection.
-- =========================================================

do $$ begin
    if not exists (
        select 1 from information_schema.check_constraints
        where constraint_name = 'legitapp_events_source_values'
    ) then
        alter table public.legitapp_events
            add constraint legitapp_events_source_values
                check (source in ('macos_app', 'website'));
    end if;
end $$;

do $$ begin
    if not exists (
        select 1 from information_schema.check_constraints
        where constraint_name = 'legitapp_events_app_version_length'
    ) then
        alter table public.legitapp_events
            add constraint legitapp_events_app_version_length
                check (app_version is null or char_length(app_version) <= 30);
    end if;
end $$;

do $$ begin
    if not exists (
        select 1 from information_schema.check_constraints
        where constraint_name = 'legitapp_events_os_version_length'
    ) then
        alter table public.legitapp_events
            add constraint legitapp_events_os_version_length
                check (os_version is null or char_length(os_version) <= 100);
    end if;
end $$;

do $$ begin
    if not exists (
        select 1 from information_schema.check_constraints
        where constraint_name = 'legitapp_events_cask_id_length'
    ) then
        alter table public.legitapp_events
            add constraint legitapp_events_cask_id_length
                check (cask_id is null or char_length(cask_id) <= 100);
    end if;
end $$;

do $$ begin
    if not exists (
        select 1 from information_schema.check_constraints
        where constraint_name = 'legitapp_events_cask_name_length'
    ) then
        alter table public.legitapp_events
            add constraint legitapp_events_cask_name_length
                check (cask_name is null or char_length(cask_name) <= 200);
    end if;
end $$;

do $$ begin
    if not exists (
        select 1 from information_schema.check_constraints
        where constraint_name = 'legitapp_events_cask_tap_length'
    ) then
        alter table public.legitapp_events
            add constraint legitapp_events_cask_tap_length
                check (cask_tap is null or char_length(cask_tap) <= 200);
    end if;
end $$;

do $$ begin
    if not exists (
        select 1 from information_schema.check_constraints
        where constraint_name = 'legitapp_events_install_method_length'
    ) then
        alter table public.legitapp_events
            add constraint legitapp_events_install_method_length
                check (install_method is null or char_length(install_method) <= 50);
    end if;
end $$;

-- =========================================================
-- 2. Performance: composite indexes for analytics views
--
--    legitapp_daily_active_users  → (event_name, created_at, anonymous_user_id)
--    legitapp_top_installed_casks → (event_name, cask_id)
--    Rate-limit function          → (anonymous_user_id, created_at)
-- =========================================================

-- Covers time-bucketed aggregations in DAU / download_clicks / MAU views
create index if not exists legitapp_events_eventname_created_idx
    on public.legitapp_events (event_name, created_at desc)
    include (anonymous_user_id);

-- Covers top-installed / uninstall aggregations
create index if not exists legitapp_events_eventname_cask_idx
    on public.legitapp_events (event_name, cask_id)
    where cask_id is not null;

-- Used by the rate-limit function to count recent rows per user
create index if not exists legitapp_events_user_created_idx
    on public.legitapp_events (anonymous_user_id, created_at desc);

-- =========================================================
-- 3. Anti-spam: server-side rate limit
--    Max 30 inserts per anonymous_user_id per hour.
--    SECURITY DEFINER so anon (INSERT-only) can count its own rows.
-- =========================================================

create or replace function public.legitapp_check_rate_limit(uid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select count(*) < 30
    from public.legitapp_events
    where anonymous_user_id = uid
      and created_at > now() - interval '1 hour';
$$;

-- Restrict execution to anon role only (not public)
revoke execute on function public.legitapp_check_rate_limit(uuid) from public;
grant  execute on function public.legitapp_check_rate_limit(uuid) to anon;

-- Replace permissive insert policy with rate-limited one
drop policy if exists "Allow anonymous analytics inserts" on public.legitapp_events;

create policy "Allow anonymous analytics inserts"
    on public.legitapp_events
    for insert
    to anon
    with check (
        legitapp_check_rate_limit(anonymous_user_id)
    );
