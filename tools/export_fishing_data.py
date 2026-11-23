#!/usr/bin/env python3
"""从网站数据生成专业工作台钓鱼视角的数据 WowHandbook/Data/Fishing.lua。

来源是网站 src/data/generated/fishing-zones.json（网站 scripts/generate-fishing-zones.py 生成：经典旧世钓鱼掉落表
按每次上钩换算的几率，Forever 的名称）。每个钓鱼地区：
  slug、map（uiMapID，按网站 zones.json 换算）、level（水域钓鱼等级，可钓技能 max(1, level)、不脱钩 level + 95）；
  waters 水域：main 为该地区的主水域（没有更细归属的子区域都算它），areas 为属于这片水域的子区域名
  （按语言 enUS / zhCN，只用来和客户端 GetSubZoneText 对上，显示时也用它），level，
  catch 渔获 { 物品 ID, 每次上钩的几率 %, 标记, 最少, 最多 }，标记 "" 普通、"quest" 有任务时才有、
  "winter" / "summer" 季节；
  schools 鱼群（与该地区出现的鱼群名对应，名称按语言）与它们的 yields（同 catch 格式）。
kinds：物品 ID -> 类别（fish / treasure / potion / other / junk）。物品名称、图标、品质运行时向客户端取。

只读网站仓库。用法（仓库根目录）：
    python3 tools/export_fishing_data.py [--site /path/to/WowHandbook] [--json /path/to/fishing-zones.json]
网站的工作副本不在含钓鱼数据的分支时，可用 --json 指向导出的 fishing-zones.json。
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
OUTPUT = REPO_ROOT / "WowHandbook" / "Data" / "Fishing.lua"

sys.path.insert(0, str(REPO_ROOT / "tools"))
from export_site_data import DEFAULT_SITE, load, lua_value  # noqa: E402

KINDS = ("fish", "treasure", "potion", "other", "junk")


def catch_row(row: list) -> list:
    item, pct, flag, low, high = row
    return [int(item), float(pct), flag or "", int(low), int(high)]


def build(data: dict, slug_to_map: dict) -> dict:
    zones = []
    used = set()
    for zone in data.get("zones", []):
        ui_map = slug_to_map.get(zone["slug"])
        if not ui_map:
            raise ValueError(f"fishing zone without uiMapId: {zone['slug']}")
        waters = []
        for water in zone.get("waters", []):
            rows = [catch_row(r) for r in water.get("catch", [])]
            used.update(r[0] for r in rows)
            waters.append({
                "main": bool(water.get("main")),
                "level": water.get("level"),
                "areas": {"enUS": list(water.get("areas") or []), "zhCN": list(water.get("areasZh") or [])},
                "catch": rows,
            })
        schools = []
        for school in zone.get("schools", []):
            rows = [catch_row(r) for r in school.get("yields", [])]
            used.update(r[0] for r in rows)
            schools.append({"name": {"enUS": school["name"], "zhCN": school.get("nameZh") or school["name"]},
                            "yields": rows})
        zones.append({"slug": zone["slug"], "map": ui_map, "level": zone.get("level"),
                      "waters": waters, "schools": schools})
    kinds = {}
    for key, entry in (data.get("items") or {}).items():
        item = int(key)
        kind = entry[3] if len(entry) > 3 and entry[3] in KINDS else "other"
        if item in used:
            kinds[item] = kind
    return {"build": data.get("build"), "zones": zones, "kinds": dict(sorted(kinds.items()))}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--site", type=Path, default=DEFAULT_SITE)
    parser.add_argument("--json", type=Path, default=None, help="fishing-zones.json（默认取网站仓库里的）")
    args = parser.parse_args()
    generated = args.site / "src" / "data" / "generated"
    source = args.json or generated / "fishing-zones.json"
    zones = load(generated / "zones.json")["maps"]
    slug_to_map = {entry["slug"]: entry["uiMapId"] for entry in zones if entry.get("uiMapId")}
    data = build(load(source), slug_to_map)
    OUTPUT.write_text(
        "-- 自动生成的数据文件，请勿手工编辑（tools/export_fishing_data.py）。\n"
        "local ADDON_NAME, ns = ...\n"
        "ns.Data = ns.Data or {}\n"
        f"ns.Data.fishing = {lua_value(data)}\n", encoding="utf-8")
    print(f"Fishing.lua：{len(data['zones'])} 个地区，渔获 {len(data['kinds'])} 种")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
