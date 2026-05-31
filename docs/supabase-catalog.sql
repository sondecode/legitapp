-- LegitApp catalog schema.
-- Run this in Supabase SQL editor. The macOS app reads public.legitapp_catalog
-- through PostgREST using LegitAppSupabaseURL and LegitAppSupabaseAnonKey.

create table if not exists public.legitapp_banners (
    id text primary key default 'default',
    enabled boolean not null default false,
    sidebar_banner boolean not null default false,
    image_url text not null default '',
    link_url text not null default '',
    fixed_height double precision,
    updated_at timestamptz not null default now(),
    constraint legitapp_banners_singleton check (id = 'default')
);

create table if not exists public.legitapp_categories (
    id text primary key,
    sf_symbol text not null,
    sort_order integer not null default 0,
    enabled boolean not null default true,
    updated_at timestamptz not null default now()
);

create table if not exists public.legitapp_category_casks (
    category_id text not null references public.legitapp_categories(id) on delete cascade,
    cask_id text not null,
    sort_order integer not null default 0,
    primary key (category_id, cask_id)
);

create table if not exists public.legitapp_category_app_metadata (
    category_id text not null references public.legitapp_categories(id) on delete cascade,
    app_id text not null,
    vi_description text not null,
    primary key (category_id, app_id)
);

create table if not exists public.legitapp_website_only_apps (
    category_id text not null references public.legitapp_categories(id) on delete cascade,
    app_id text not null,
    name text not null,
    vi_description text not null,
    homepage text not null,
    sort_order integer not null default 0,
    primary key (category_id, app_id)
);

alter table public.legitapp_banners enable row level security;
alter table public.legitapp_categories enable row level security;
alter table public.legitapp_category_casks enable row level security;
alter table public.legitapp_category_app_metadata enable row level security;
alter table public.legitapp_website_only_apps enable row level security;

grant select on public.legitapp_banners to anon;
grant select on public.legitapp_categories to anon;
grant select on public.legitapp_category_casks to anon;
grant select on public.legitapp_category_app_metadata to anon;
grant select on public.legitapp_website_only_apps to anon;

drop policy if exists "Allow anonymous catalog reads" on public.legitapp_banners;
drop policy if exists "Allow anonymous catalog reads" on public.legitapp_categories;
drop policy if exists "Allow anonymous catalog reads" on public.legitapp_category_casks;
drop policy if exists "Allow anonymous catalog reads" on public.legitapp_category_app_metadata;
drop policy if exists "Allow anonymous catalog reads" on public.legitapp_website_only_apps;

create policy "Allow anonymous catalog reads"
    on public.legitapp_banners
    for select
    to anon
    using (true);

create policy "Allow anonymous catalog reads"
    on public.legitapp_categories
    for select
    to anon
    using (enabled);

create policy "Allow anonymous catalog reads"
    on public.legitapp_category_casks
    for select
    to anon
    using (
        exists (
            select 1
            from public.legitapp_categories c
            where c.id = category_id
                and c.enabled
        )
    );

create policy "Allow anonymous catalog reads"
    on public.legitapp_category_app_metadata
    for select
    to anon
    using (
        exists (
            select 1
            from public.legitapp_categories c
            where c.id = category_id
                and c.enabled
        )
    );

create policy "Allow anonymous catalog reads"
    on public.legitapp_website_only_apps
    for select
    to anon
    using (
        exists (
            select 1
            from public.legitapp_categories c
            where c.id = category_id
                and c.enabled
        )
    );

create or replace view public.legitapp_catalog as
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
) as data;

alter view public.legitapp_catalog set (security_invoker = true);
grant select on public.legitapp_catalog to anon;

-- Minimal seed example. Add or update rows here, or import from categories.json
-- with your own admin script/service-role process.
insert into public.legitapp_banners (
    id,
    enabled,
    sidebar_banner,
    image_url,
    link_url,
    fixed_height
) values (
    'default',
    false,
    true,
    'https://i.ebayimg.com/images/g/RzYAAOSwTFZlNkr9/s-l1200.jpg',
    'https://legitpass.vn',
    160
) on conflict (id) do update set
    enabled = excluded.enabled,
    sidebar_banner = excluded.sidebar_banner,
    image_url = excluded.image_url,
    link_url = excluded.link_url,
    fixed_height = excluded.fixed_height,
    updated_at = now();
