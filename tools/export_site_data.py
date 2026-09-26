#!/usr/bin/env python3
"""从网站数据生成 WoW Handbook 插件的数据文件 WowHandbook/Data/*.lua。

- Zones.lua：区域与城市（uiMapID、等级范围、阵营、中英文名）
- Dungeons.lua：副本与团队副本（等级、入口坐标、首领与掉落物品 ID、相关任务 ID）
- Quests.lua：副本任务与任务链上的任务（等级、阵营、接交任务 NPC 与坐标、前置与后续）
- Spells.lua：各职业可学技能与每个等级的学习等级（中英文名、图标）；术士恶魔技能标出所属恶魔，
  并按客户端物品表里的魔典（Grimoire of X (Rank N)）标出每个等级靠魔典学习还是恶魔自带
- MapOverlays.lua：大地图各区域的探索贴图（WorldMapOverlay / WorldMapOverlayTile），供“显示完整地图”
  补画尚未探索的区域

只读网站仓库，不写网站仓库。插件只带客户端给不了的内容：ID、关系、坐标、等级；
名称以网站数据为兜底，界面优先用客户端运行时名称。
用法（仓库根目录）：python3 tools/export_site_data.py [--site /path/to/WowHandbook]
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
# 网站仓库默认与插件仓库放在同一上级目录的 Websites/WowHandbook；可用 --site 或环境变量 WOWHANDBOOK_SITE 指定
DEFAULT_SITE = Path(os.environ.get("WOWHANDBOOK_SITE") or Path(__file__).resolve().parents[2] / "Websites" / "WowHandbook")
OUTPUT_DIR = REPO_ROOT / "WowHandbook" / "Data"

FACTION_CODES = {"alliance": "A", "horde": "H"}


def load(path: Path):
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


# ---------------------------------------------------------------------------
# Lua 序列化
# ---------------------------------------------------------------------------

def lua_value(value, indent: int = 0) -> str:
    pad = "    " * indent
    inner = "    " * (indent + 1)
    if value is None:
        return "nil"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return repr(round(value, 2)) if isinstance(value, float) else str(value)
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, list):
        if not value:
            return "{}"
        if all(isinstance(v, (int, float, str)) for v in value) and len(value) <= 12:
            return "{ " + ", ".join(lua_value(v) for v in value) + " }"
        return "{\n" + "".join(f"{inner}{lua_value(v, indent + 1)},\n" for v in value) + pad + "}"
    if isinstance(value, dict):
        items = [(k, v) for k, v in value.items() if v is not None and v != [] and v != {}]
        if not items:
            return "{}"
        parts = []
        for key, item in items:
            if isinstance(key, int):
                lua_key = f"[{key}]"
            elif key.isidentifier():
                lua_key = key
            else:
                lua_key = f"[{json.dumps(key, ensure_ascii=False)}]"
            parts.append(f"{inner}{lua_key} = {lua_value(item, indent + 1)},\n")
        return "{\n" + "".join(parts) + pad + "}"
    raise TypeError(f"unsupported value: {value!r}")


def write_lua(name: str, source: str, table_name: str, value) -> None:
    text = (
        "-- 自动生成，请勿手工编辑。生成脚本：tools/export_site_data.py\n"
        f"-- 来源：{source}\n"
        "local ADDON_NAME, ns = ...\n"
        "ns.Data = ns.Data or {}\n"
        f"ns.Data.{table_name} = {lua_value(value)}\n"
    )
    (OUTPUT_DIR / name).write_text(text, encoding="utf-8")


# ---------------------------------------------------------------------------
# 数据整理
# ---------------------------------------------------------------------------

def build_zones(zones: list, zh_names: dict) -> tuple[dict, dict]:
    """返回 (按 uiMapID 的区域表, 英文名 -> uiMapID)"""
    by_map, by_name = {}, {}
    for entry in zones:
        ui_map = entry.get("uiMapId")
        if not ui_map or entry["kind"] not in ("zone", "city", "continent"):
            continue
        levels = entry.get("levels")
        by_map[ui_map] = {
            "slug": entry["slug"],
            "kind": entry["kind"],
            "levels": levels,
            "faction": entry.get("faction"),
            "name": {"enUS": entry["name"], "zhCN": zh_names.get(entry["name"])},
        }
        by_name[entry["name"]] = ui_map
    return by_map, by_name


def resolve_map(location: str | None, zone_by_name: dict) -> int | None:
    """地点名 -> uiMapID：先整名，再取“子区域, 区域”的区域部分，最后不区分大小写。副本内地点返回 None。"""
    if not location:
        return None
    candidates = [location]
    if "," in location:
        candidates.append(location.rsplit(",", 1)[1].strip())
    lowered = {name.lower(): ui_map for name, ui_map in zone_by_name.items()}
    for candidate in candidates:
        if candidate in zone_by_name:
            return zone_by_name[candidate]
        if candidate.lower() in lowered:
            return lowered[candidate.lower()]
    return None


def place(source: dict | None, zone_by_name: dict, zh_source: dict | None) -> dict | None:
    if not source:
        return None
    coords = source.get("coordinates") or [None, None]
    return {
        "kind": source.get("kind"),
        "id": source.get("id"),
        "name": {"enUS": source.get("name"), "zhCN": (zh_source or {}).get("name")},
        "map": resolve_map(source.get("location"), zone_by_name),
        "x": coords[0],
        "y": coords[1],
    }


def money_copper(value) -> int | None:
    """网站的金钱写法（"1g 5s 20c"、"35s"）或数字 -> 铜"""
    if isinstance(value, (int, float)):
        return int(value)
    if not value:
        return None
    total = 0
    for amount, unit in re.findall(r"(\d+)\s*([gsc])", str(value)):
        total += int(amount) * {"g": 10000, "s": 100, "c": 1}[unit]
    return total or None


def build_rewards(rewards: dict | None, zh_rewards: dict | None) -> dict | None:
    if not rewards:
        return None
    zh_reps = (zh_rewards or {}).get("reputation") or []
    result = {
        "xp": rewards.get("experience") or None,
        "money": money_copper(rewards.get("money")),
        "items": [{"id": i["id"], "count": i.get("count") or 1} for i in rewards.get("items") or [] if i.get("id")],
        "choices": [{"id": i["id"], "count": i.get("count") or 1} for i in rewards.get("choiceItems") or [] if i.get("id")],
        "reputation": [
            {"name": {"enUS": r.get("name"), "zhCN": (zh_reps[index] if index < len(zh_reps) else {}).get("name")},
             "value": r.get("value")}
            for index, r in enumerate(rewards.get("reputation") or [])
        ],
    }
    return {k: v for k, v in result.items() if v} or None


def _plain_place(name: str) -> str:
    name = name.strip().lower()
    return name[4:] if name.startswith("the ") else name


def starts_inside(source: dict | None, instances: list) -> bool:
    """任务是否在副本里接：由副本掉落的物品开始，或接任务的 NPC / 物体位于副本内。

    网站的地点写法：副本内的 NPC 地点以副本名开头（“Blackrock Depths — Shadowforge City”、
    上下层黑石塔写作“Blackrock Spire”），少数只有内部地图编号（“map 48”）。
    “Blackrock Mountain — …”等副本外的区域不算。
    """
    if not source:
        return False
    if source.get("kind") == "item":
        return True
    location = (source.get("location") or "").strip()
    if not location:
        return False
    if re.fullmatch(r"map \d+", location):
        return True
    head = _plain_place(re.split(r" — |,", location)[0])
    return any(head and _plain_place(name).endswith(head) for name in instances if name)


def flatten(groups: list) -> list:
    return [quest_id for group in groups or [] for quest_id in group]


def build_quests(dungeon_quests: list, zh_quests: dict, chains: dict, zh_steps: dict, zone_by_name: dict) -> dict:
    quests = {}
    for quest in dungeon_quests:
        qid = int(quest["id"])
        zh = zh_quests.get(qid, {})
        chain = chains["chains"].get(str(qid), {})
        start = (quest.get("startSources") or [None])[0]
        finish = (quest.get("endSources") or [None])[0]
        zh_start = (zh.get("startSources") or [None])[0]
        zh_finish = (zh.get("endSources") or [None])[0]
        quests[qid] = {
            "name": {"enUS": quest["name"], "zhCN": zh.get("name")},
            "level": quest.get("level"),
            "min": quest.get("minimumLevel"),
            "faction": FACTION_CODES.get(quest.get("faction") or ""),
            "instances": quest.get("instanceSlugs") or ([quest["instanceSlug"]] if quest.get("instanceSlug") else []),
            "start": place(start, zone_by_name, zh_start),
            "inside": starts_inside(start, quest.get("instances") or [quest.get("instance")]) or None,
            "finish": place(finish, zone_by_name, zh_finish),
            "before": flatten(chain.get("before")),
            "after": flatten(chain.get("after")),
            "summary": {"enUS": quest.get("summary"), "zhCN": zh.get("summary")} if quest.get("summary") else None,
            "objectives": {"enUS": quest.get("objectives"), "zhCN": zh.get("objectives")} if quest.get("objectives") else None,
            "rewards": build_rewards(quest.get("rewards"), zh.get("rewards")),
        }
    # 任务链上不属于副本任务的前后置任务：只带名称、等级、阵营与接任务地点
    for key, step in chains.get("steps", {}).items():
        qid = int(key)
        if qid in quests:
            continue
        chain = chains["chains"].get(key, {})
        zh_step = zh_steps.get(key, {})
        start = (step.get("startSources") or [None])[0]
        zh_start = (zh_step.get("startSources") or [None])[0]
        quests[qid] = {
            "name": {"enUS": step.get("name"), "zhCN": zh_step.get("name")},
            "level": step.get("level"),
            "faction": FACTION_CODES.get(step.get("faction") or ""),
            "start": place(start, zone_by_name, zh_start),
            "before": flatten(chain.get("before")),
            "after": flatten(chain.get("after")),
            "chainOnly": True,
        }
    return quests


def build_dungeons(zones: list, zh_names: dict, boss_loot: dict, quests: dict, zone_slug_to_map: dict) -> list:
    dungeons = []
    for entry in zones:
        if entry["kind"] not in ("dungeon", "raid"):
            continue
        slug = entry["slug"]
        loot = boss_loot.get(slug, {}).get("bosses", {})
        boss_names = list(entry.get("bosses") or [])
        boss_names += [name for name in loot if name not in boss_names]
        entrance = entry.get("entrance") or {}
        dungeons.append({
            "slug": slug,
            "kind": entry["kind"],
            "instanceID": entry.get("mapId"),
            "uiMapID": entry.get("uiMapId"),
            "levels": entry.get("levels"),
            "faction": entry.get("faction"),
            "name": {"enUS": entry["name"], "zhCN": zh_names.get(entry["name"])},
            "entrance": {
                "map": zone_slug_to_map.get(entrance.get("zone")),
                "x": entrance.get("x"),
                "y": entrance.get("y"),
            } if entrance.get("zone") else None,
            "bosses": [
                {"name": {"enUS": name, "zhCN": zh_names.get(name)}, "items": loot.get(name, [])}
                for name in boss_names
            ],
            "quests": sorted(qid for qid, quest in quests.items() if slug in (quest.get("instances") or [])),
        })
    dungeons.sort(key=lambda d: ((d["levels"] or [99, 99])[0], (d["levels"] or [99, 99])[1], d["slug"]))
    return dungeons


def icon_name(path: str | None) -> str | None:
    if not path:
        return None
    return path.rsplit("/", 1)[-1].rsplit(".", 1)[0]


def latest_db2(site: Path, table: str) -> Path | None:
    """网站仓库本地客户端表导出里最新 1.60.* 构建中的某张表；不存在返回 None。"""
    root = site / "assets" / "research" / "db2"
    builds = sorted(
        (p for p in root.glob("1.60.*") if (p / f"{table}.csv").exists()),
        key=lambda p: [int(part) for part in p.name.split(".")],
    ) if root.exists() else []
    return builds[-1] / f"{table}.csv" if builds else None


def read_csv(path: Path) -> list:
    with path.open(encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def build_map_overlays(map_art: list, overlays: list, tiles: list) -> dict:
    """{uiMapID: [[宽, 高, 左偏移, 上偏移, 贴图文件ID...], ...]}；贴图按行优先排列（第 0 层）。"""
    art_to_maps: dict = {}
    for row in map_art:
        if int(row.get("PhaseID") or 0) == 0:
            art_to_maps.setdefault(int(row["UiMapArtID"]), []).append(int(row["UiMapID"]))
    files: dict = {}
    for row in tiles:
        if int(row.get("LayerIndex") or 0) == 0:
            files.setdefault(int(row["WorldMapOverlayID"]), []).append(
                (int(row["RowIndex"]), int(row["ColIndex"]), int(row["FileDataID"])))
    result: dict = {}
    for row in sorted(overlays, key=lambda r: int(r["ID"])):
        overlay_id = int(row["ID"])
        if int(row.get("PlayerConditionID") or 0) or overlay_id not in files:
            continue
        entry = [int(row["TextureWidth"]), int(row["TextureHeight"]), int(row["OffsetX"]), int(row["OffsetY"])]
        entry += [file_id for _, _, file_id in sorted(files[overlay_id])]
        for ui_map in art_to_maps.get(int(row["UiMapArtID"]), []):
            result.setdefault(ui_map, []).append(entry)
    return result


def load_map_overlays(site: Path) -> dict:
    paths = [latest_db2(site, name) for name in ("UiMapXMapArt", "WorldMapOverlay", "WorldMapOverlayTile")]
    if not all(paths):
        return {}
    return build_map_overlays(*(read_csv(path) for path in paths))


def load_grimoires(site: Path) -> dict:
    """从网站仓库本地的客户端表导出（assets/research/db2/<最新构建>/ItemSparse.csv）读取魔典：
    {技能英文名: {等级数字: {"item": 物品ID, "price": 买价（铜）, "level": 需求等级}}}，无等级的技能等级记为 0。
    该目录是网站仓库的本地研究素材，不存在时返回空表（导出照常进行，只是没有魔典信息）。"""
    root = site / "assets" / "research" / "db2"
    builds = sorted(
        (p for p in root.glob("1.60.*") if (p / "ItemSparse.csv").exists()),
        key=lambda p: [int(part) for part in p.name.split(".")],
    ) if root.exists() else []
    if not builds:
        return {}
    grimoires: dict = {}
    with (builds[-1] / "ItemSparse.csv").open(encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            match = re.match(r"^Grimoire of (.+?)(?: \(Rank (\d+)\))?$", row.get("Display_lang") or "")
            if match:
                grimoires.setdefault(match.group(1), {})[int(match.group(2) or 0)] = {
                    "item": int(row["ID"]),
                    "price": int(row.get("BuyPrice") or 0),
                    "level": int(row.get("RequiredLevel") or 0),
                }
    return grimoires


def rank_number(rank: str) -> int:
    match = re.search(r"\d+", rank or "")
    return int(match.group()) if match else 0


def build_spells(spellbook: dict, zh_spellbook: dict, grimoires: dict | None = None) -> dict:
    grimoires = grimoires or {}
    classes = {}
    for class_slug, data in spellbook["classes"].items():
        zh_tabs = zh_spellbook["classes"].get(class_slug, {}).get("tabs", [])
        spells = []
        for tab_index, tab in enumerate(data["tabs"]):
            zh_tab = zh_tabs[tab_index] if tab_index < len(zh_tabs) else {"name": None, "spells": []}
            for spell_index, spell in enumerate(tab["spells"]):
                zh_spell = zh_tab["spells"][spell_index] if spell_index < len(zh_tab["spells"]) else {}
                ranks = spell.get("ranks") or [{"rank": spell.get("rank", ""), "level": spell.get("level")}]
                is_pet = bool(tab.get("pet"))
                books = grimoires.get(spell["name"], {}) if is_pet else {}
                rank_rows = []
                for r in ranks:
                    if not r.get("level"):
                        continue
                    row = {"rank": r.get("rank") or "", "level": r.get("level")}
                    if is_pet:
                        book = books.get(rank_number(row["rank"]))
                        if book:
                            row["book"] = book["item"]
                            row["price"] = book["price"] or None
                        elif grimoires:
                            row["innate"] = True  # 商人不卖这一级的魔典：召唤恶魔时自带
                    rank_rows.append(row)
                spells.append({
                    "name": {"enUS": spell["name"], "zhCN": zh_spell.get("name")},
                    "tab": {"enUS": tab["name"], "zhCN": zh_tab.get("name")},
                    "pet": {"enUS": tab["name"], "zhCN": zh_tab.get("name")} if is_pet else None,
                    "icon": icon_name(spell.get("icon")),
                    "races": spell.get("races"),
                    "ranks": rank_rows,
                })
        classes[class_slug] = spells
    return classes


def export(site: Path) -> dict:
    generated = site / "src" / "data" / "generated"
    zones = load(generated / "zones.json")["maps"]
    zh_names = load(generated / "zh" / "zone-names.json")["names"]
    dungeon_quests = load(generated / "dungeon-quests.json")["quests"]
    zh_quests = {int(q["id"]): q for q in load(generated / "zh" / "dungeon-quests.json")["quests"]}
    chains = load(generated / "quest-chains.json")
    zh_chains = load(generated / "zh" / "quest-chains.json")
    boss_loot = load(generated / "boss-loot.json")["instances"]

    zone_table, zone_by_name = build_zones(zones, zh_names)
    zone_slug_to_map = {entry["slug"]: entry.get("uiMapId") for entry in zones if entry.get("uiMapId")}
    quests = build_quests(dungeon_quests, zh_quests, chains, zh_chains.get("steps", {}), zone_by_name)
    dungeons = build_dungeons(zones, zh_names, boss_loot, quests, zone_slug_to_map)
    spells = build_spells(load(generated / "spellbook.json"), load(generated / "zh" / "spellbook.json"),
                          load_grimoires(site))
    return {"zones": zone_table, "dungeons": dungeons, "quests": quests, "spells": spells,
            "mapOverlays": load_map_overlays(site),
            "build": load(generated / "zones.json").get("build")}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--site", type=Path, default=DEFAULT_SITE)
    args = parser.parse_args()
    data = export(args.site)
    source = f"wowhandbook src/data/generated（客户端 {data['build']}）"
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    write_lua("Zones.lua", source, "zones", data["zones"])
    write_lua("Dungeons.lua", source, "dungeons", data["dungeons"])
    write_lua("Quests.lua", source, "quests", data["quests"])
    write_lua("Spells.lua", source, "spells", data["spells"])
    write_lua("MapOverlays.lua", "客户端表 UiMapXMapArt / WorldMapOverlay / WorldMapOverlayTile", "mapOverlays",
              data["mapOverlays"])
    print(f"区域 {len(data['zones'])}，副本 {len(data['dungeons'])}，任务 {len(data['quests'])}，"
          f"职业 {len(data['spells'])}（技能 {sum(len(v) for v in data['spells'].values())}），"
          f"地图探索贴图 {len(data['mapOverlays'])} 张地图")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
