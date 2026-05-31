#!/usr/bin/env python3
"""Generate Supabase catalog seed SQL from LegitApp categories.json."""

from __future__ import annotations

import json
import sys
from pathlib import Path


def sql(value: object) -> str:
    if value is None:
        return "null"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return str(value)
    return "'" + str(value).replace("'", "''") + "'"


def main() -> int:
    source = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("LegitApp/Resources/categories.json")
    payload = json.loads(source.read_text(encoding="utf-8"))

    banner = payload.get("banner") or {}
    categories = payload.get("categories", payload if isinstance(payload, list) else [])

    print("-- Generated from", source)
    print("begin;")
    print("delete from public.legitapp_website_only_apps;")
    print("delete from public.legitapp_category_app_metadata;")
    print("delete from public.legitapp_category_casks;")
    print("delete from public.legitapp_categories;")
    print()

    print(
        "insert into public.legitapp_banners "
        "(id, enabled, sidebar_banner, image_url, link_url, fixed_height) values "
        f"('default', {sql(banner.get('enabled', False))}, "
        f"{sql(banner.get('sidebar_banner', False))}, "
        f"{sql(banner.get('imageUrl', ''))}, "
        f"{sql(banner.get('linkUrl', ''))}, "
        f"{sql(banner.get('fixedHeight'))}) "
        "on conflict (id) do update set "
        "enabled = excluded.enabled, "
        "sidebar_banner = excluded.sidebar_banner, "
        "image_url = excluded.image_url, "
        "link_url = excluded.link_url, "
        "fixed_height = excluded.fixed_height, "
        "updated_at = now();"
    )
    print()

    for category_order, category in enumerate(categories):
        category_id = category["id"]
        print(
            "insert into public.legitapp_categories "
            "(id, sf_symbol, sort_order, enabled) values "
            f"({sql(category_id)}, {sql(category['sfSymbol'])}, {category_order}, true) "
            "on conflict (id) do update set "
            "sf_symbol = excluded.sf_symbol, "
            "sort_order = excluded.sort_order, "
            "enabled = excluded.enabled, "
            "updated_at = now();"
        )

        for cask_order, cask_id in enumerate(category.get("casks", [])):
            print(
                "insert into public.legitapp_category_casks "
                "(category_id, cask_id, sort_order) values "
                f"({sql(category_id)}, {sql(cask_id)}, {cask_order}) "
                "on conflict (category_id, cask_id) do update set "
                "sort_order = excluded.sort_order;"
            )

        for app in category.get("apps", []):
            print(
                "insert into public.legitapp_category_app_metadata "
                "(category_id, app_id, vi_description) values "
                f"({sql(category_id)}, {sql(app['id'])}, {sql(app['viDescription'])}) "
                "on conflict (category_id, app_id) do update set "
                "vi_description = excluded.vi_description;"
            )

        for app_order, app in enumerate(category.get("websiteOnlyApps", [])):
            print(
                "insert into public.legitapp_website_only_apps "
                "(category_id, app_id, name, vi_description, homepage, sort_order) values "
                f"({sql(category_id)}, {sql(app['id'])}, {sql(app['name'])}, "
                f"{sql(app['viDescription'])}, {sql(app['homepage'])}, {app_order}) "
                "on conflict (category_id, app_id) do update set "
                "name = excluded.name, "
                "vi_description = excluded.vi_description, "
                "homepage = excluded.homepage, "
                "sort_order = excluded.sort_order;"
            )

        print()

    print("commit;")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
