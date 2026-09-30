#!/usr/bin/env python3
"""从网站数据生成 WoW Handbook 插件的数据文件 WowHandbook/Data/*.lua。

- Zones.lua：区域与城市（uiMapID、等级范围、阵营、中英文名）
- Dungeons.lua：副本与团队副本（等级、入口坐标、首领与掉落物品 ID、相关任务 ID）
- Quests.lua：副本任务与任务链上的任务（等级、阵营、接交任务 NPC 与坐标、前置与后续）
- Spells.lua：各职业可学技能与每个等级的学习等级（中英文名、图标）；术士恶魔技能标出所属恶魔，
  并按客户端物品表里的魔典（Grimoire of X (Rank N)）标出每个等级靠魔典学习还是恶魔自带
- MapOverlays.lua：大地图各区域的探索贴图（WorldMapOverlay / WorldMapOverlayTile），供“显示完整地图”
  补画尚未探索的区域
- Graveyards.lua：各区域地图上灵魂医者的位置（网站 graveyards.json，来自 QuestieDB 刷新点），
  游戏不提供墓地列表时，大地图用它显示灵魂医者
- Professions.lua：12 个专业（中英文名、图标、技能线 ID）与各专业训练师（网站 profession-trainers.json：
  QuestieDB Forever 版训练师与坐标，加游戏内实测坐标与新训练师；阵营、可教到的等级、地图与坐标）
- ClassTrainers.lua：各职业训练师（网站 class-trainers.json：QuestieDB Forever 版加游戏内实测坐标与新训练师；
  猎人另有宠物训练师 kind = "pet"，法师另有传送门训练师 kind = "portal"；阵营、地图与坐标）
- GatheringNodes.lua：草药与矿点（网站 gathering-nodes.json，来自 QuestieDB Forever 版刷新点）：每种采集点
  采到的物品与所需技能；各区域地图上的位置，同一处可能刷出的几种合并为一个点

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
import subprocess
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


def write_lua(name: str, table_name: str, value, notice: str | None = None) -> None:
    """数据文件只写“自动生成”和必要的许可署名。"""
    text = (
        "-- 自动生成的数据文件，请勿手工编辑。\n"
        + (f"-- {notice}\n" if notice else "")
        + "local ADDON_NAME, ns = ...\n"
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


# 两个来源的坐标相差在这个范围内（0–100 的地图百分比）才视为同一地点、同一坐标系
PLACE_TOLERANCE = 2.0

# 网站与参照坐标矛盾、无法确定地图的地点，导出结束时报告数量
place_conflicts: list[dict] = []


def _same_spot(a, b) -> bool:
    return bool(a and b and None not in a[:2] and None not in b[:2]
                and abs(a[0] - b[0]) <= PLACE_TOLERANCE and abs(a[1] - b[1]) <= PLACE_TOLERANCE)


def place(source: dict | None, zone_by_name: dict, zh_source: dict | None, reference: dict | None = None) -> dict | None:
    """接任务地点。地图与坐标作为一个整体从同一来源选取，不把一个来源的地图和另一个来源的坐标拼在一起：
    · 网站有坐标：参照只给地图、或参照坐标与之一致时，用参照的 uiMapID（按地点名推断地图对“Sentinel Tower”
      这类名称会失败，主城地点还会被推到外面的区域）；参照坐标与网站矛盾时说明两者不是同一处，改用按地点名
      推断的地图，推断不出时不给坐标，并记进 place_conflicts；
    · 网站没有坐标：整组使用参照的地图与坐标，参照缺地图时不给坐标。
    发布到插件的数据不带来源标记。"""
    if not source:
        return None
    reference = reference or {}
    site_coords = source.get("coordinates")
    ref_coords = reference.get("coordinates")
    ref_map = reference.get("uiMapId")
    map_id, coords = None, None
    if site_coords:
        if ref_map and (not ref_coords or _same_spot(site_coords, ref_coords)):
            map_id, coords = ref_map, site_coords
        else:
            map_id = resolve_map(source.get("location"), zone_by_name)
            coords = site_coords if map_id else None
            if not map_id and ref_map:
                place_conflicts.append({"id": source.get("id"), "site": site_coords,
                                        "reference": {"map": ref_map, "coordinates": ref_coords}})
    elif ref_coords and ref_map:
        map_id, coords = ref_map, ref_coords
    else:
        map_id = resolve_map(source.get("location"), zone_by_name)
    coords = coords or [None, None]
    return {
        "kind": source.get("kind"),
        "id": source.get("id"),
        "name": {"enUS": source.get("name"), "zhCN": (zh_source or {}).get("name")},
        "map": map_id,
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


def build_rewards(rewards: dict | None, zh_rewards: dict | None, reference: dict | None = None) -> dict | None:
    """任务奖励。网站没有经验、金钱时用参照值；参照独有的奖励物品放进 extraItems（插件显示为“其他可能的奖励”）。"""
    if not rewards:
        return None
    reference = reference or {}
    zh_reps = (zh_rewards or {}).get("reputation") or []
    result = {
        "xp": rewards.get("experience") or reference.get("experience") or None,
        "money": money_copper(rewards.get("money")) or reference.get("money"),
        "items": [{"id": i["id"], "count": i.get("count") or 1} for i in rewards.get("items") or [] if i.get("id")],
        "choices": [{"id": i["id"], "count": i.get("count") or 1} for i in rewards.get("choiceItems") or [] if i.get("id")],
        "reputation": [
            {"name": {"enUS": r.get("name"), "zhCN": (zh_reps[index] if index < len(zh_reps) else {}).get("name")},
             "value": r.get("value")}
            for index, r in enumerate(rewards.get("reputation") or [])
        ],
        "extraItems": [{"id": i} for i in reference.get("rewardItemIds") or []]
                          + [{"id": i, "followUp": True} for i in reference.get("followUpRewardItemIds") or []],
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


def merge_ids(*groups) -> list:
    result = []
    for group in groups:
        for value in group or []:
            if value not in result:
                result.append(value)
    return result


def build_quests(dungeon_quests: list, zh_quests: dict, chains: dict, zh_steps: dict, zone_by_name: dict,
                 reference_quests: list | None = None) -> dict:
    quests = {}
    references = {int(q["id"]): q for q in reference_quests or []}
    for quest in dungeon_quests:
        qid = int(quest["id"])
        zh = zh_quests.get(qid, {})
        chain = chains["chains"].get(str(qid), {})
        reference = quest.get("reference") or {}
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
            "sectionSlugs": quest.get("sectionSlugs") or None,
            "relatedExternal": quest.get("relatedExternal") or None,
            "newInForeverChain": chain.get("newInForever") or None,
            "classRestriction": (quest.get("classRestriction") or "").upper() or None,
            "start": place(start, zone_by_name, zh_start, reference.get("start")),
            "inside": (not quest.get("pickupBefore") and starts_inside(start, quest.get("instances") or [quest.get("instance")])) or None,
            "finish": place(finish, zone_by_name, zh_finish),
            "before": merge_ids(flatten(chain.get("before")), [p["id"] for p in quest.get("prerequisites", [])], reference.get("prerequisites")),
            "after": flatten(chain.get("after")),
            "summary": {"enUS": quest.get("summary"), "zhCN": zh.get("summary")} if quest.get("summary") else None,
            "objectives": {"enUS": quest.get("objectives"), "zhCN": zh.get("objectives")} if quest.get("objectives") else None,
            "rewards": build_rewards(quest.get("rewards"), zh.get("rewards"), reference),
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
            "min": step.get("minimumLevel") or references.get(qid, {}).get("minimumLevel"),
            "summary": {"enUS": step.get("note"), "zhCN": zh_step.get("note")} if step.get("note") else None,
            "faction": FACTION_CODES.get(step.get("faction") or ""),
            "start": place(start, zone_by_name, zh_start),
            "before": merge_ids(flatten(chain.get("before")), references.get(qid, {}).get("prerequisites")),
            "after": flatten(chain.get("after")),
            "chainOnly": True,
        }
    # 网站未单独发布的参照任务：导出为 extra（不计入推荐与可接数量），名称优先运行时向客户端获取
    for ref in reference_quests or []:
        qid = int(ref["id"])
        if qid in quests:
            continue
        giver = ref.get("giver") or {}
        coords = giver.get("coordinates") or [None, None]
        rewards = ref.get("rewards") or {}
        entry = {
            "name": {"enUS": ref.get("name")} if ref.get("name") else None,
            "level": ref.get("level"),
            "min": ref.get("minimumLevel"),
            "faction": FACTION_CODES.get(ref.get("faction") or ""),
            "start": {
                "kind": "item" if ref.get("startItem") else "npc",
                "id": ref.get("startItem") or giver.get("npcId"),
                "name": {"enUS": giver.get("name")} if giver.get("name") else None,
                "map": giver.get("uiMapId"), "x": coords[0], "y": coords[1],
            } if giver.get("name") or giver.get("uiMapId") or ref.get("startItem") else None,
            "inside": ref.get("inside") or None,
            "before": ref.get("prerequisites") or [],
            "after": [],
            "rewards": {k: v for k, v in {
                "xp": rewards.get("experience"), "money": rewards.get("money"),
                "extraItems": [{"id": i} for i in rewards.get("itemIds") or []],
            }.items() if v} or None,
            "extra": True,
        }
        if ref.get("role") == "dungeon":
            entry["instances"] = ref.get("instanceSlugs") or []
            entry["sectionSlugs"] = ref.get("sectionSlugs") or None
        else:
            entry["chainOnly"] = True
        quests[qid] = entry
    # Preserve the confirmed follow-up relationship of curated Forever chains.
    for owner, chain in chains.get("chains", {}).items():
        if chain.get("newInForever"):
            for qid in flatten(chain.get("after")):
                if qid in quests:
                    quests[qid]["before"] = merge_ids(quests[qid].get("before"), [int(owner)])
                    quests[qid]["newInForeverChain"] = True
    # 参照前置补进来后，给前置任务补上 after
    for qid, quest in quests.items():
        for before in quest.get("before") or []:
            target = quests.get(before)
            if target is not None and qid not in (target.get("after") or []):
                target["after"] = (target.get("after") or []) + [qid]
    return quests


# 入口在主城里的副本只对本阵营显示：无限版的组队查找器不会直接传送进副本（用户 2026-09-27 确认），
# 另一阵营的玩家实际进不去。
FACTION_ONLY_DUNGEONS = {"hall-of-thanes": "alliance", "ragefire-chasm": "horde"}

# 网站首领顺序来自客户端 DungeonEncounter 的 OrderIndex，个别副本与实际路线不符；这里按实际路线覆盖
# （键是副本 slug，有分区时为 "副本-分区"）。列出的首领按此顺序排在前面，没列出的保持原顺序跟在后面。
# 死亡矿井：重拳先生在绿皮船长之前；曲奇是可选首领，多在范克里夫之后顺路击杀
BOSS_ORDER = {
    "deadmines": ["Rhahk'Zor", "Sneed", "Gilnid", "Mr. Smite", "Captain Greenskin", "Edwin VanCleef", "Cookie"],
}


def ordered_bosses(slug: str, names: list) -> list:
    order = BOSS_ORDER.get(slug)
    if not order:
        return names
    return [name for name in order if name in names] + [name for name in names if name not in order]


def build_dungeons(zones: list, zh_names: dict, boss_loot: dict, quests: dict, zone_slug_to_map: dict,
                   drop_details: dict | None = None, boss_details: dict | None = None) -> list:
    dungeons = []
    drop_details = drop_details or {}
    boss_details = boss_details or {}
    for entry in zones:
        if entry["kind"] not in ("dungeon", "raid"):
            continue
        slug = entry["slug"]
        loot_entry = boss_loot.get(slug, {})
        entrance = entry.get("entrance") or {}
        sections = entry.get("sections") or []
        for section in sections or [None]:
            section_slug = section["slug"] if section else None
            section_loot = (loot_entry.get("sections") or {}).get(section_slug, {}) if section else loot_entry
            loot = section_loot.get("bosses") or {}
            details = (drop_details.get(slug) or {}).get(section_slug or "_root") or {}
            facts = (boss_details.get(slug) or {}).get(section_slug or "_root") or {}
            boss_names = ordered_bosses(f"{slug}-{section_slug}" if section else slug,
                                        list((section or entry).get("bosses") or []))
            # 网站首领列表之外、只来自掉落表的行（稀有精英、物品、杂兵等）标 lootOnly：保留掉落，但不计入首领数和进度
            site_bosses = set(boss_names)
            boss_names += [name for name in loot if name not in boss_names]
            boss_names += [row["name"] for row in section_loot.get("extra") or [] if row["name"] not in boss_names]
            loot = dict(loot, **{row["name"]: row["items"] for row in section_loot.get("extra") or [] if row["name"] not in loot})
            level_min = (section or entry).get("levelMin")
            level_max = (section or entry).get("levelMax")
            levels = [level_min, level_max] if level_min is not None and level_max is not None else (section or entry).get("levels")
            dungeons.append({
                "slug": f"{slug}-{section_slug}" if section else slug,
                "sectionSlug": section_slug,
                "parentSlug": slug if section else None,
                "siteSlug": slug,
                "kind": entry["kind"],
                "instanceID": entry.get("mapId"),
                "uiMapID": entry.get("uiMapId"),
                "levels": levels,
                "levelMin": level_min if level_min is not None else (levels or [None])[0],
                "levelMax": level_max if level_max is not None else (levels or [None, None])[-1],
                "dataPending": entry.get("dataPending") or None,
                "faction": FACTION_ONLY_DUNGEONS.get(slug) or entry.get("faction"),
                "name": {"enUS": (section or entry)["name"],
                         "zhCN": (section or entry).get("nameZh") or zh_names.get((section or entry)["name"])},
                "entrance": {
                    "map": zone_slug_to_map.get(entrance.get("zone")),
                    "x": entrance.get("x"),
                    "y": entrance.get("y"),
                } if entrance.get("zone") else None,
                "bosses": [
                    {"name": {"enUS": name, "zhCN": zh_names.get(name)},
                     "level": (facts.get(name) or {}).get("level"),
                     "npcID": (facts.get(name) or {}).get("npcId"),
                     "displayID": (facts.get(name) or {}).get("displayId"),
                     "lootOnly": True if site_bosses and name not in site_bosses else None,
                     "items": [
                         item if isinstance(item, dict) else {
                             "id": item,
                             "rate": ((details.get(name) or {}).get(str(item)) or {}).get("rate"),
                             "newInForever": ((details.get(name) or {}).get(str(item)) or {}).get("newInForever"),
                         }
                         for item in loot.get(name, [])
                     ]}
                    for name in boss_names
                ],
                "quests": sorted(qid for qid, quest in quests.items()
                                 if (section_slug in (quest.get("sectionSlugs") or []) if section
                                     else slug in (quest.get("instances") or []))),
            })
        if sections:
            unassigned = sorted(qid for qid, quest in quests.items()
                                if slug in (quest.get("instances") or [])
                                and "unassigned" in (quest.get("sectionSlugs") or []))
            if unassigned:
                dungeons.append({
                    "slug": slug,
                    "siteSlug": slug,
                    "aggregateOnly": True,
                    "kind": entry["kind"],
                    "levels": entry.get("levels"),
                    "levelMin": entry.get("levelMin"),
                    "levelMax": entry.get("levelMax"),
                    "name": {"enUS": entry["name"], "zhCN": zh_names.get(entry["name"])},
                    "bosses": [],
                    "quests": unassigned,
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


# 客户端 ChrClasses 的职业位（SkillLineAbility.ClassMask）
CLASS_BITS = {"warrior": 1, "paladin": 2, "hunter": 4, "rogue": 8, "priest": 16, "shaman": 64,
              "mage": 128, "warlock": 256, "druid": 1024}


def load_spell_ids(site: Path) -> dict:
    """技能 ID：{(职业, 英文技能名, 等级文字): [(学习等级, 技能ID), …]}。

    网站技能书只有名称与等级，没有 ID；插件要在运行时向客户端取未学技能的鼠标提示，需要 ID。
    来源是网站仓库本地的客户端表导出（SkillLineAbility 限定为可学习的职业技能，SpellName、Spell 的等级文字、
    SpellLevels 的学习等级）；表不存在时返回空表，导出照常进行，只是没有 ID。"""
    table = latest_db2(site, "SkillLineAbility")
    if not table:
        return {}
    folder = table.parent
    names = {r["ID"]: r["Name_lang"] for r in read_csv(folder / "SpellName.csv")}
    subtexts = {r["ID"]: r.get("NameSubtext_lang") or "" for r in read_csv(folder / "Spell.csv")}
    levels = {}
    if (folder / "SpellLevels.csv").exists():
        for r in read_csv(folder / "SpellLevels.csv"):
            levels[r["SpellID"]] = int(r.get("SpellLevel") or r.get("BaseLevel") or 0)
    # 术士恶魔的技能在各自的技能线（“Pet - Imp”等）上，职业位为 0；键里的职业写作 "pet:恶魔英文名"
    pet_lines = {}
    if (folder / "SkillLine.csv").exists():
        for r in read_csv(folder / "SkillLine.csv"):
            match = re.match(r"^Pet - (.+)$", r.get("DisplayName_lang") or "")
            if match:
                pet_lines[r["ID"]] = "pet:" + match.group(1)
    result: dict = {}
    for r in read_csv(table):
        spell_id, mask = r["Spell"], int(r.get("ClassMask") or 0)
        name = names.get(spell_id)
        if not name:
            continue
        owners = [class_slug for class_slug, bit in CLASS_BITS.items() if mask & bit]
        if r.get("SkillLine") in pet_lines:
            owners.append(pet_lines[r["SkillLine"]])
        for owner in owners:
            key = (owner, name, subtexts.get(spell_id, ""))
            result.setdefault(key, []).append((levels.get(spell_id, 0), int(spell_id)))
    return result


def pick_spell_id(spell_ids: dict, class_slug: str, name: str, rank: str, level: int) -> int | None:
    """同名同等级有多个候选时，取学习等级与网站一致的；仍不唯一则取 ID 最小的。"""
    candidates = spell_ids.get((class_slug, name, rank)) or []
    exact = sorted(spell_id for spell_level, spell_id in candidates if spell_level == level)
    if exact:
        return exact[0]
    return min((spell_id for _, spell_id in candidates), default=None)


def rank_number(rank: str) -> int:
    match = re.search(r"\d+", rank or "")
    return int(match.group()) if match else 0


def build_spells(spellbook: dict, zh_spellbook: dict, grimoires: dict | None = None,
                 spell_ids: dict | None = None) -> dict:
    grimoires = grimoires or {}
    spell_ids = spell_ids or {}
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
                    owner = "pet:" + tab["name"] if is_pet else class_slug
                    spell_id = pick_spell_id(spell_ids, owner, spell["name"], row["rank"], row["level"])
                    if spell_id:
                        row["id"] = spell_id
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


def build_graveyards(graveyards: dict) -> dict:
    """{uiMapID: {{x, y}, ...}}，坐标 0–100"""
    return {int(map_id): [[x, y] for x, y in points] for map_id, points in sorted(graveyards.get("maps", {}).items(),
                                                                                key=lambda kv: int(kv[0]))}


def apply_deadmines_site_sync(site: Path, document: dict, zh_quests: dict) -> None:
    """Read the website's curated overlay, including its class/external classification."""
    module = site / "src/data/deadminesQuestSync.ts"
    if not module.exists():
        return
    result = subprocess.run([
        "node", "--input-type=module", "-e",
        "const m = await import(process.argv[1]); console.log(JSON.stringify({"
        "en:m.additionalDeadminesQuests('en'),zh:m.additionalDeadminesQuests('zh'),"
        "minimumLevels:m.deadminesMinimumLevelOverrides,pickupBefore:[...m.deadminesPickupBeforeIds],main:[...m.deadminesMainQuestIds],excluded:[...m.excludedDeadminesQuestIds]}));",
        module.resolve().as_uri(),
    ], check=True, capture_output=True, text=True)
    overlay = json.loads(result.stdout)
    excluded = set(overlay["excluded"])
    promoted = {q["id"] for q in overlay["en"]}
    document["quests"] = [q for q in document["quests"] if q["id"] not in excluded | promoted]
    for quest in overlay["en"]:
        quest["relatedExternal"] = quest["id"] not in overlay["main"]
        document["quests"].append(quest)
    for quest in document["quests"]:
        if str(quest["id"]) in overlay["minimumLevels"]:
            quest["minimumLevel"] = overlay["minimumLevels"][str(quest["id"])]
        if quest["id"] in overlay["pickupBefore"]:
            quest["pickupBefore"] = True
    zh_quests.update({q["id"]: q for q in overlay["zh"]})
    document["referenceQuests"] = [q for q in document.get("referenceQuests", [])
                                    if q["id"] not in excluded | promoted]


# 专业训练师可教到的等级：网站按训练师头衔判断；插件界面按这个顺序排列
TRAINER_RANKS = ("apprentice", "journeyman", "expert", "artisan", "specialization")
def load_skill_lines(site: Path) -> dict:
    """{专业英文名: [技能线 ID…]}：客户端 SkillLine 表里专业与副专业（分类 11、9）的主技能线和其下的子技能线。
    Forever 用正式服的分层技能线（采矿 186，其下 2946），插件按这些 ID 识别玩家学了哪个专业。"""
    table = latest_db2(site, "SkillLine")
    if not table:
        return {}
    rows = [r for r in read_csv(table) if r.get("CategoryID") in ("9", "11")]
    names = {r["ID"]: r["DisplayName_lang"] for r in rows if r.get("ParentSkillLineID") in ("0", "")}
    lines = {name: [int(skill_id)] for skill_id, name in names.items()}
    for row in rows:
        parent = row.get("ParentSkillLineID")
        if parent in names:
            lines[names[parent]].append(int(row["ID"]))
    return lines


def build_professions(professions: dict, zh_professions: dict, trainers: dict, skill_lines: dict | None = None) -> list:
    """专业列表（主专业在前，按网站顺序）与各专业训练师。没有坐标的训练师保留地图，x / y 为空。"""
    zh = {p["slug"]: p["name"] for p in zh_professions.get("professions", [])}
    skill_lines = skill_lines or {}
    out = []
    for profession in professions.get("professions", []):
        slug = profession["slug"]
        rows = [{
            "id": row["id"],
            "name": {"enUS": row["name"], "zhCN": row.get("nameZh")},
            "faction": row.get("faction"),
            "rank": row.get("rank") if row.get("rank") in TRAINER_RANKS else None,
            "map": row.get("map"),
            "x": row.get("x"),
            "y": row.get("y"),
        } for row in (trainers.get("professions") or {}).get(slug, [])]
        out.append({
            "slug": slug,
            "kind": profession.get("kind"),
            "name": {"enUS": profession["name"], "zhCN": zh.get(slug)},
            "icon": icon_name(profession.get("icon")),
            "skillLines": skill_lines.get(profession["name"]),
            "trainers": rows,
        })
    return out


def build_class_trainers(trainers: dict) -> dict:
    """{[职业] = {{id, name = {enUS, zhCN}, faction, kind, map, x, y}}}，职业为小写的职业标识（mage 等）。"""
    return {class_name: [{
        "id": row["id"],
        "name": {"enUS": row["name"], "zhCN": row.get("nameZh")},
        "faction": row.get("faction"),
        "kind": row.get("kind"),
        "map": row.get("map"),
        "x": row.get("x"),
        "y": row.get("y"),
    } for row in rows] for class_name, rows in (trainers.get("classes") or {}).items()}


def build_gathering(gathering: dict) -> dict:
    """{nodes = {{kind, item, skill, rare, objects}}, maps = {[uiMapID] = {herb = {{x, y, 种类序号…}}, ore = {…}}}}。
    种类序号是 nodes 里的位置（从 1 开始）；rare 标出偶尔替换普通矿刷出的稀有变种（银、金、真银、黑铁）；
    objects 是这种采集点的物件 ID（插件据此认出玩家采了什么）；
    物品名称、图标运行时向客户端取。"""
    return {
        "nodes": [{"kind": n["kind"], "item": n["item"], "skill": n["skill"], "rare": True if n.get("rare") else None,
                   "objects": n.get("objects")}
                  for n in gathering.get("nodes", [])],
        "maps": {int(map_id): kinds for map_id, kinds in (gathering.get("maps") or {}).items()},
    }


def export(site: Path) -> dict:
    generated = site / "src" / "data" / "generated"
    zones = load(generated / "zones.json")["maps"]
    zh_names = load(generated / "zh" / "zone-names.json")["names"]
    dungeon_quests_data = load(generated / "dungeon-quests.json")
    zh_quests = {int(q["id"]): q for q in load(generated / "zh" / "dungeon-quests.json")["quests"]}
    apply_deadmines_site_sync(site, dungeon_quests_data, zh_quests)
    dungeon_quests = dungeon_quests_data["quests"]
    chains = load(generated / "quest-chains.json")
    zh_chains = load(generated / "zh" / "quest-chains.json")
    boss_loot_data = load(generated / "boss-loot.json")
    boss_loot = boss_loot_data["instances"]

    zone_table, zone_by_name = build_zones(zones, zh_names)
    zone_slug_to_map = {entry["slug"]: entry.get("uiMapId") for entry in zones if entry.get("uiMapId")}
    quests = build_quests(dungeon_quests, zh_quests, chains, zh_chains.get("steps", {}), zone_by_name,
                          dungeon_quests_data.get("referenceQuests"))
    dungeons = build_dungeons(zones, zh_names, boss_loot, quests, zone_slug_to_map,
                              boss_loot_data.get("dropDetails"), boss_loot_data.get("bossDetails"))
    spells = build_spells(load(generated / "spellbook.json"), load(generated / "zh" / "spellbook.json"),
                          load_grimoires(site), load_spell_ids(site))
    return {"zones": zone_table, "dungeons": dungeons, "quests": quests, "spells": spells,
            "mapOverlays": load_map_overlays(site),
            "graveyards": build_graveyards(load(generated / "graveyards.json")) if (generated / "graveyards.json").exists() else {},
            "classTrainers": build_class_trainers(load(generated / "class-trainers.json"))
            if (generated / "class-trainers.json").exists() else {},
            "gathering": build_gathering(load(generated / "gathering-nodes.json"))
            if (generated / "gathering-nodes.json").exists() else {"nodes": [], "maps": {}},
            "professions": build_professions(load(generated / "professions.json"),
                                             load(generated / "zh" / "professions.json"),
                                             load(generated / "profession-trainers.json")
                                             if (generated / "profession-trainers.json").exists() else {},
                                             load_skill_lines(site)),
            "build": load(generated / "zones.json").get("build")}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--site", type=Path, default=DEFAULT_SITE)
    args = parser.parse_args()
    data = export(args.site)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    write_lua("Zones.lua", "zones", data["zones"])
    write_lua("Dungeons.lua", "dungeons", data["dungeons"])
    write_lua("Quests.lua", "quests", data["quests"])
    write_lua("Spells.lua", "spells", data["spells"])
    write_lua("MapOverlays.lua", "mapOverlays", data["mapOverlays"])
    # 灵魂医者刷新点来自 GPL-3.0 的 Questie，按许可保留署名
    write_lua("Graveyards.lua", "graveyards", data["graveyards"],
              "Spirit healer locations from Questie (https://github.com/Questie/Questie), GPL-3.0.")
    # 训练师名单与坐标主要来自 Questie 项目的 QuestieDB（GPL-3.0），按许可保留署名
    write_lua("Professions.lua", "professions", data["professions"],
              "Profession trainer locations from QuestieDB (https://github.com/Questie/QuestieDB), "
              "the Questie project, GPL-3.0, with positions checked in WoW: Forever.")
    # 职业训练师位置来自 Questie 项目的 QuestieDB（GPL-3.0），按许可保留署名
    write_lua("ClassTrainers.lua", "classTrainers", data["classTrainers"],
              "Class trainer locations from QuestieDB (https://github.com/Questie/QuestieDB), "
              "the Questie project, GPL-3.0, with positions checked in WoW: Forever.")
    # 采集点刷新位置来自 Questie 项目的 QuestieDB（GPL-3.0），按许可保留署名
    write_lua("GatheringNodes.lua", "gathering", data["gathering"],
              "Herb and mining node locations from QuestieDB (https://github.com/Questie/QuestieDB), "
              "the Questie project, GPL-3.0.")
    print(f"区域 {len(data['zones'])}，副本 {len(data['dungeons'])}，任务 {len(data['quests'])}，"
          f"职业 {len(data['spells'])}（技能 {sum(len(v) for v in data['spells'].values())}），"
          f"地图探索贴图 {len(data['mapOverlays'])} 张地图，灵魂医者 {sum(len(v) for v in data['graveyards'].values())} 个，"
          f"专业 {len(data['professions'])}（训练师 {sum(len(p['trainers']) for p in data['professions'])}），"
          f"职业训练师 {sum(len(v) for v in data['classTrainers'].values())} 个，"
          f"采集点 {sum(len(v) for m in data['gathering']['maps'].values() for v in m.values())} 处")
    if place_conflicts:
        ids = ", ".join(str(item["id"]) for item in place_conflicts[:10])
        print(f"注意：{len(place_conflicts)} 个地点网站坐标与参照不一致且按地点名推断不出地图，未导出坐标（{ids}…）")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
