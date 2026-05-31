 -- LegitApp Supabase caching via Materialized Views + pg_cron.
-- Run this AFTER supabase-analytics.sql and supabase-security.sql.
--
-- Why not Redis?
--   • Analytics writes are very infrequent (max 1/day per user for app_open,
--     60 s cooldown for cask events) — no need for a write buffer.
--   • The only read bottleneck is the admin panel's aggregate views.
--   • Materialized views solve that with zero extra infrastructure and cost.
--
-- Strategy:
--   1. Replace live views with MATERIALIZED views (pre-computed snapshots).
--   2. Refresh them every 15 minutes via pg_cron (CONCURRENTLY = no read lock).
--   3. Grant the service role (used by the admin Next.js panel) SELECT on them.
--   4. Keep the original live views for any real-time use case.

-- =========================================================
-- Enable pg_cron extension (required for scheduled refresh)
-- =========================================================

create extension if not exists pg_cron;

-- =========================================================
-- 1. Materialized views
--    Each replaces a heavy aggregate query with a cached snapshot.
--    Reads hit the pre-computed table; only the refresh touches the base table.
-- =========================================================

-- Event totals (dashboard stats cards)
create materialized view if not exists public.legitapp_mv_event_counts as
select
    event_name,
    count(*) as event_count
from public.legitapp_events
group by event_name
with data;

-- Daily active users (line chart)
create materialized view if not exists public.legitapp_mv_daily_active_users as
select
    date_trunc('day', created_at)::date as active_date,
    count(distinct anonymous_user_id) as active_users
from public.legitapp_events
where event_name = 'app_open'
group by active_date
order by active_date desc
with data;

-- Monthly active users
create materialized view if not exists public.legitapp_mv_monthly_active_users as
select
    date_trunc('month', created_at)::date as active_month,
    count(distinct anonymous_user_id) as active_users
from public.legitapp_events
where event_name = 'app_open'
group by active_month
order by active_month desc
with data;

-- Download clicks (line chart)
create materialized view if not exists public.legitapp_mv_download_clicks as
select
    date_trunc('day', created_at)::date as download_date,
    count(*) as download_clicks,
    count(distinct anonymous_user_id) as unique_downloaders
from public.legitapp_events
where event_name = 'dmg_download_click'
group by download_date
order by download_date desc
with data;

-- Top installed casks
create materialized view if not exists public.legitapp_mv_top_installed_casks as
select
    cask_id,
    max(cask_name) as cask_name,
    count(*) as install_count
from public.legitapp_events
where event_name = 'cask_install_success'
    and cask_id is not null
group by cask_id
order by install_count desc
with data;

-- Uninstall counts
create materialized view if not exists public.legitapp_mv_uninstall_counts as
select
    cask_id,
    max(cask_name) as cask_name,
    count(*) as uninstall_count
from public.legitapp_events
where event_name = 'cask_uninstall_success'
    and cask_id is not null
group by cask_id
order by uninstall_count desc
with data;

-- =========================================================
-- 2. Unique indexes required for CONCURRENTLY refresh
--    CONCURRENTLY allows reads while the view refreshes (no lock).
-- =========================================================

create unique index if not exists legitapp_mv_event_counts_pk
    on public.legitapp_mv_event_counts (event_name);

create unique index if not exists legitapp_mv_dau_pk
    on public.legitapp_mv_daily_active_users (active_date);

create unique index if not exists legitapp_mv_mau_pk
    on public.legitapp_mv_monthly_active_users (active_month);

create unique index if not exists legitapp_mv_downloads_pk
    on public.legitapp_mv_download_clicks (download_date);

create unique index if not exists legitapp_mv_top_casks_pk
    on public.legitapp_mv_top_installed_casks (cask_id);

create unique index if not exists legitapp_mv_uninstall_pk
    on public.legitapp_mv_uninstall_counts (cask_id);

-- =========================================================
-- 3. Permissions — service role reads materialized views
--    (anon has no SELECT; admin panel uses service role key)
-- =========================================================

grant select on public.legitapp_mv_event_counts         to service_role;
grant select on public.legitapp_mv_daily_active_users   to service_role;
grant select on public.legitapp_mv_monthly_active_users to service_role;
grant select on public.legitapp_mv_download_clicks      to service_role;
grant select on public.legitapp_mv_top_installed_casks  to service_role;
grant select on public.legitapp_mv_uninstall_counts     to service_role;

-- =========================================================
-- 4. pg_cron scheduled refresh — every 15 minutes
--    CONCURRENTLY: no read lock, existing data stays visible.
--    Schedule uses standard cron syntax.
-- =========================================================

-- Remove old jobs if re-running this script
select cron.unschedule(jobname)
from cron.job
where jobname like 'refresh_legitapp_mv_%';

select cron.schedule(
    'refresh_legitapp_mv_event_counts',
    '*/15 * * * *',
    $$refresh materialized view concurrently public.legitapp_mv_event_counts$$
);

select cron.schedule(
    'refresh_legitapp_mv_dau',
    '*/15 * * * *',
    $$refresh materialized view concurrently public.legitapp_mv_daily_active_users$$
);

select cron.schedule(
    'refresh_legitapp_mv_mau',
    '*/15 * * * *',
    $$refresh materialized view concurrently public.legitapp_mv_monthly_active_users$$
);

select cron.schedule(
    'refresh_legitapp_mv_downloads',
    '*/15 * * * *',
    $$refresh materialized view concurrently public.legitapp_mv_download_clicks$$
);

select cron.schedule(
    'refresh_legitapp_mv_top_casks',
    '*/15 * * * *',
    $$refresh materialized view concurrently public.legitapp_mv_top_installed_casks$$
);

select cron.schedule(
    'refresh_legitapp_mv_uninstalls',
    '*/15 * * * *',
    $$refresh materialized view concurrently public.legitapp_mv_uninstall_counts$$
);

-- =========================================================
-- Verify scheduled jobs
-- =========================================================
-- select jobname, schedule, active from cron.job where jobname like 'refresh_legitapp_mv_%';

-- =========================================================
-- 5. Catalog caching (categories + banner)
--    WHY THIS MATTERS MORE THAN ANALYTICS VIEWS:
--    • legitapp_catalog is queried by EVERY user on every app open (anon role).
--    • The live view runs nested jsonb_agg + 4 correlated subqueries across 5 tables.
--    • Analytics views are only read by the admin panel (low traffic, service role).
--
--    REFRESH STRATEGY: trigger-based (not pg_cron).
--    Categories change only when an admin saves — could be once a week.
--    A trigger fires immediately on any change to the 4 catalog tables,
--    so users always see fresh data within milliseconds of an admin save.
-- =========================================================

-- 5a. Materialized view — pre-computes the full catalog JSON.
--     Same query as the live legitapp_catalog view.
create materialized view if not exists public.legitapp_mv_catalog as
select jsonb_build_object(
    'banner',
    (
        select jsonb_build_object(
            'enabled', b.enabled,
            'sidebar_banner', b.sidebar_banner,
            'imageUrl', b.image_url,
            'linkUrl', b.link_url,
            'fixedHeight', b.fixed_height
        )
        from public.legitapp_banners b
        where b.id = 'default'
        limit 1
    ),
    'categories',
    coalesce(
        (
            select jsonb_agg(
                jsonb_build_object(
                    'id', c.id,
                    'sfSymbol', c.sf_symbol,
                    'casks', coalesce(
                        (
                            select jsonb_agg(cc.cask_id order by cc.sort_order, cc.cask_id)
                            from public.legitapp_category_casks cc
                            where cc.category_id = c.id
                        ),
                        '[]'::jsonb
                    ),
                    'apps', coalesce(
                        (
                            select jsonb_agg(
                                jsonb_build_object(
                                    'id', m.app_id,
                                    'viDescription', m.vi_description
                                )
                                order by m.app_id
                            )
                            from public.legitapp_category_app_metadata m
                            where m.category_id = c.id
                        ),
                        '[]'::jsonb
                    ),
                    'websiteOnlyApps', coalesce(
                        (
                            select jsonb_agg(
                                jsonb_build_object(
                                    'id', w.app_id,
                                    'name', w.name,
                                    'viDescription', w.vi_description,
                                    'homepage', w.homepage
                                )
                                order by w.sort_order, w.app_id
                            )
                            from public.legitapp_website_only_apps w
                            where w.category_id = c.id
                        ),
                        '[]'::jsonb
                    )
                )
                order by c.sort_order, c.id
            )
            from public.legitapp_categories c
            where c.enabled
        ),
        '[]'::jsonb
    )
) as data
with data;

-- 5b. Unique index — required for CONCURRENTLY refresh.
--     The view returns exactly one row, so we index on the ctid workaround:
--     use a generated serial or a constant. Simplest: index on (data->>'banner')
--     is not unique-safe. Use a dummy unique column instead.
--     Postgres requires a unique index for CONCURRENTLY; since there is only
--     one row we add a surrogate key via a boolean column trick.
create unique index if not exists legitapp_mv_catalog_pk
    on public.legitapp_mv_catalog ((true));

-- 5c. Grant SELECT to anon — macOS app reads this with the anon key.
grant select on public.legitapp_mv_catalog to anon;

-- 5d. Point the existing legitapp_catalog view at the materialized view.
--     The macOS app already queries "legitapp_catalog" — no Swift code change needed.
--     Reads now hit the pre-computed row (single index scan) instead of running
--     the full jsonb_agg query.
create or replace view public.legitapp_catalog as
select data from public.legitapp_mv_catalog;

alter view public.legitapp_catalog set (security_invoker = true);

-- Re-grant (view was replaced above)
grant select on public.legitapp_catalog to anon;

-- 5e. Trigger function — refreshes the materialized view whenever catalog tables change.
--     SECURITY DEFINER runs as the owner (superuser) who has REFRESH privilege.
--     Not CONCURRENTLY here because the view has only one row — refresh is instant.
create or replace function public.refresh_catalog_mv()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    refresh materialized view public.legitapp_mv_catalog;
    return null;
end;
$$;

-- 5f. Attach trigger to all four catalog tables.
--     AFTER INSERT OR UPDATE OR DELETE, statement-level (FOR EACH STATEMENT)
--     so bulk admin saves fire the refresh once, not N times per row.

drop trigger if exists trg_refresh_catalog_mv on public.legitapp_categories;
create trigger trg_refresh_catalog_mv
    after insert or update or delete
    on public.legitapp_categories
    for each statement execute function public.refresh_catalog_mv();

drop trigger if exists trg_refresh_catalog_mv on public.legitapp_category_casks;
create trigger trg_refresh_catalog_mv
    after insert or update or delete
    on public.legitapp_category_casks
    for each statement execute function public.refresh_catalog_mv();

drop trigger if exists trg_refresh_catalog_mv on public.legitapp_category_app_metadata;
create trigger trg_refresh_catalog_mv
    after insert or update or delete
    on public.legitapp_category_app_metadata
    for each statement execute function public.refresh_catalog_mv();

drop trigger if exists trg_refresh_catalog_mv on public.legitapp_banners;
create trigger trg_refresh_catalog_mv
    after insert or update or delete
    on public.legitapp_banners
    for each statement execute function public.refresh_catalog_mv();

-- =========================================================
-- Verify catalog materialized view
-- =========================================================
-- select length(data::text) as json_bytes from public.legitapp_mv_catalog;
