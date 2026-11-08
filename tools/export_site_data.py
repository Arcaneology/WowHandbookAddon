#!/usr/bin/env python3
"""从网站数据生成 WoW Handbook 插件的数据文件 WowHandbook/Data/*.lua。

- Zones.lua：区域与城市（uiMapID、等级范围、阵营、中英文名）
- Dungeons.lua：副本与团队副本（等级、入口坐标、首领与掉落物品 ID、相关任务 ID）
- Quests.lua：副本任务与任务链上的任务（等级、阵营、接交任务 NPC 与坐标、前置与后续）
- Spells.lua：各职业可学技能与每个等级的学习等级（中英文名、图标）；术士恶魔技能标出所属恶魔，
  并按客户端物品表里的魔典（Grimoire of X (Rank N)）标出每个等级靠魔典学习还是恶魔自带
- MapOverlays.lua：大地图各区域的探索贴图（WorldMapOverlay / WorldMapOverlayTile），供“显示完整地图”
  补画尚未探索的区域
- Graveyards.lua：各区域地图上灵魂医者的位置与阵营限制（网站 graveyards.json：QuestieDB 刷新点、区域与墓地的
  关联，加游戏内实测位置），游戏不提供墓地列表时，大地图用它显示灵魂医者
- GraveyardAreas.lua：复活区域的分界线（每张地图、每个阵营按码做最近墓地分区），大地图上显示死在哪里会到哪个灵魂医者
- Professions.lua：12 个专业（中英文名、图标、技能线 ID）与各专业训练师（网站 profession-trainers.json：
  QuestieDB Forever 版训练师与坐标，加游戏内实测坐标与新训练师；阵营、可教到的等级、地图与坐标）
- ClassTrainers.lua：各职业训练师（网站 class-trainers.json：QuestieDB Forever 版加游戏内实测坐标与新训练师；
  猎人另有宠物训练师 kind = "pet"，法师另有传送门训练师 kind = "portal"；阵营、地图与坐标）
- Transmogrifiers.lua：幻化师（用户 2026-10-07 提供的位置，写在本脚本的 TRANSMOGRIFIERS；阵营、地图与坐标）
- TalentPlans.lua：网站推荐的天赋方案（src/data/builds.ts 与 buildCopy.ts，经 tools/dump_talent_plans.mjs 用网站自己的
  replayPlan 逐级重放）：每个方案从 10 级起每一级的分享码、洗天赋的等级、定位、方案名与一句话用途（中英）
- BisGear.lua：网站 BiS 页的装备推荐（src/data/classLeveling.ts 的 classBands，经 tools/dump_bis_gear.mjs 调用）：
  各职业各天赋 1–60 级逐级的首选装备变化、网站 10 级一段的备选与 60 级 PvP 组（物品 ID、获取途径），两个阵营合在一个列表里
- HunterPets.lua：稀有宠物追踪（网站 hunter-pets.json 与 src/data/hunterPetCopy.ts，后者经 tools/dump_hunter_pet_copy.mjs
  读取）：家族（名称、图标、专属技能 ID、定位）、稀有与精英稀有的可驯服野兽加上网站的重点宠物（家族、等级、稀有、
  无限版新增、攻击间隔、自带技能等级、重点宠物的看点 / 驯服提示 / 标签、地图位置，每张图最多 BEAST_SPOTS_PER_MAP 处；
  副本里的只记副本 slug）。
  家族修正、食谱、技能等级与普通野兽只放网站（用户 2026-11-08）；不带网站内部的证据字段
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


# 首领 NPC ID 的覆盖（键是网站副本 slug）。网站 bossDetails 里这几个新副本的 npcId 是参照数据带来的连号占位值
# （18401 起，两个副本互相重复），领主大厅的 Magmatus 则写成了怒焰裂谷塔拉加曼的 ID。这里按 Forever Guide 1.26.1
# 的首领表改成客户端里的生物 ID；值为 None 表示没有可靠 ID，导出时不带 npcID，副本进度改按名字匹配。
# 网站 bossDetails 修正后删掉对应条目。
BOSS_NPC_IDS = {
    "hall-of-thanes": {"Magmatus": 261316},
    "excavation-site-wetlands": {"Saltspine": 260322, "Shadetooth": 260325, "Highland Horror": 260808,
                                 "Relic Guardian": 260326},
    "city-of-dalaran": {"Arcane Anomaly": 245999, "Fel Ancient": 246003, "Unstable Sentinel": 246017,
                        "Shade of the Archmage": 246020, "Lyn the Ignored": 247032,
                        "Atrexis the Grave Knight": 247126,
                        "Mana Devourer": None, "Mana Elemental": None, "Mana Wraith": None},
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
            npc_ids = BOSS_NPC_IDS.get(slug) or {}
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
                     "npcID": npc_ids[name] if name in npc_ids else (facts.get(name) or {}).get("npcId"),
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


SPIRIT_HEALER_NPC = 6491
# 实测点与已有点相差在这个范围内（地图坐标，0–100）算同一个灵魂医者，用实测坐标替换
GRAVEYARD_SAME_SPOT = 5.0
# 同一个灵魂医者交互几次会记下几个略有出入的坐标：相差在这个范围内的合并成一个
GRAVEYARD_CLUSTER = 1.0


def load_collected_spirit_healers(site: Path) -> dict:
    """游戏内与灵魂医者对话时记下的位置：{uiMapID: [[x, y], ...]}。

    来源是网站仓库本地素材目录里最新一份游戏内实测存档（assets/addon-collector/latest_*.lua，只读取、
    不属于公开内容）；只取灵魂医者这一个 NPC 的交互坐标。文件不存在时返回空表，导出照常进行。"""
    folder = site / "assets" / "addon-collector"
    files = sorted(folder.glob("latest_*.lua")) if folder.exists() else []
    if not files:
        return {}
    text = files[-1].read_text(encoding="utf-8")
    start = re.search(r"^\[%d\] = \{$" % SPIRIT_HEALER_NPC, text, re.M)
    if not start:
        return {}
    following = re.search(r"^\[\d+\] = \{$", text[start.end():], re.M)
    block = text[start.end():start.end() + following.start()] if following else text[start.end():]
    positions = re.search(r'^\["positions"\] = \{\n(.*?)^\},?$', block, re.M | re.S)
    result: dict = {}
    for map_id, x, y, count in re.findall(r'\["(\d+):([\d.]+):([\d.]+)"\] = (\d+)', positions.group(1) if positions else ""):
        result.setdefault(int(map_id), []).append((float(x), float(y), int(count)))
    merged: dict = {}
    for map_id, points in result.items():
        clusters: list = []
        # 次数多的在前：同一处的几个坐标取记录次数最多的那个
        for x, y, _ in sorted(points, key=lambda p: (-p[2], p[0], p[1])):
            if not any(abs(x - cx) <= GRAVEYARD_CLUSTER and abs(y - cy) <= GRAVEYARD_CLUSTER for cx, cy in clusters):
                clusters.append((x, y))
        merged[map_id] = [[x, y] for x, y in sorted(clusters)]
    return merged


def build_graveyards(graveyards: dict, collected: dict | None = None) -> dict:
    """{uiMapID: {{x, y[, 阵营]}, ...}}，坐标 0–100；阵营 "A" / "H" 表示只有该阵营会被送到这里，两边都用的不写。

    网站每个点是 [x, y] 或 [x, y, 阵营]（"" 为两边都用）。collected 是游戏内实测的灵魂医者位置
    （{uiMapID: [[x, y], ...]}）：与已有点相差 GRAVEYARD_SAME_SPOT 以内的用实测坐标替换（阵营不变），
    其余作为新点加入（无限版新地图、挪过位置的墓地；阵营未知，按两边都用）。"""
    result = {int(map_id): [[p[0], p[1], p[2] if len(p) > 2 else ""] for p in points]
              for map_id, points in graveyards.get("maps", {}).items()}
    for map_id, points in (collected or {}).items():
        existing = result.setdefault(int(map_id), [])
        for x, y in points:
            near = [p for p in existing if abs(p[0] - x) <= GRAVEYARD_SAME_SPOT and abs(p[1] - y) <= GRAVEYARD_SAME_SPOT]
            if near:
                closest = min(near, key=lambda p: abs(p[0] - x) + abs(p[1] - y))
                closest[0], closest[1] = x, y
            else:
                existing.append([x, y, ""])
    return {map_id: [p if p[2] else p[:2] for p in points] for map_id, points in sorted(result.items())}


# 复活区域：服务器把死者送到“这片区域关联的、本阵营能用的墓地里最近的一个”。每张地图、每个阵营
# 按码（不是地图百分比，两个方向比例不同）做最近点分区，导出分区之间的分界线。
GRAVEYARD_SITE_SAME = 1.0     # 码：两个墓地相距这么近算同一个
GRAVEYARD_EDGE_EPS = 0.01     # 码：几何计算的容差


def _clip_half_plane(polygon: list, a: float, b: float, c: float) -> list:
    """保留多边形里 a*x + b*y <= c 的部分（Sutherland–Hodgman）。"""
    out = []
    count = len(polygon)
    for i in range(count):
        px, py = polygon[i]
        qx, qy = polygon[(i + 1) % count]
        p_in = a * px + b * py <= c + GRAVEYARD_EDGE_EPS
        q_in = a * qx + b * qy <= c + GRAVEYARD_EDGE_EPS
        if p_in:
            out.append((px, py))
        if p_in != q_in:
            denom = a * (qx - px) + b * (qy - py)
            if abs(denom) > 1e-12:
                t = (c - a * px - b * py) / denom
                out.append((px + (qx - px) * t, py + (qy - py) * t))
    return out


def graveyard_cells(sites: list, width: float, height: float) -> list:
    """每个墓地（码）在 width × height 地图矩形里“离它最近”的那块凸多边形；墓地可以在矩形外。"""
    cells = []
    for i, (sx, sy) in enumerate(sites):
        cell = [(0.0, 0.0), (width, 0.0), (width, height), (0.0, height)]
        for j, (tx, ty) in enumerate(sites):
            if i == j or not cell:
                continue
            # |p - s|² <= |p - t|²  ⇔  2(t - s)·p <= |t|² - |s|²
            cell = _clip_half_plane(cell, 2 * (tx - sx), 2 * (ty - sy), tx * tx + ty * ty - sx * sx - sy * sy)
        cells.append(cell)
    return cells


def graveyard_borders(sites: list, width: float, height: float) -> list:
    """分区之间的分界线 [(x1, y1, x2, y2), ...]（码），去掉地图边框上的边，相邻两块共用的边只留一条。"""
    unique = []
    for x, y in sites:
        if not any(abs(x - ux) <= GRAVEYARD_SITE_SAME and abs(y - uy) <= GRAVEYARD_SITE_SAME for ux, uy in unique):
            unique.append((x, y))
    if len(unique) < 2:
        return []
    eps = max(width, height) * 1e-4

    def on_frame(px, py, qx, qy):
        return any(abs(a - edge) <= eps and abs(b - edge) <= eps
                   for a, b, edge in ((px, qx, 0.0), (px, qx, width), (py, qy, 0.0), (py, qy, height)))

    seen, borders = set(), []
    for cell in graveyard_cells(unique, width, height):
        for i in range(len(cell)):
            px, py = cell[i]
            qx, qy = cell[(i + 1) % len(cell)]
            if (px - qx) ** 2 + (py - qy) ** 2 <= eps * eps or on_frame(px, py, qx, qy):
                continue
            key = tuple(sorted(((round(px / eps), round(py / eps)), (round(qx / eps), round(qy / eps)))))
            if key in seen:
                continue
            seen.add(key)
            borders.append((px, py, qx, qy))
    return borders


def build_graveyard_areas(graveyards: dict, spots: dict) -> dict:
    """{uiMapID: {A = 分界线, H = 分界线} 或 {both = 分界线}}；每条分界线 {x1, y1, x2, y2}，坐标 0–100。

    墓地是这张图上的灵魂医者（spots，即 build_graveyards 的结果，含实测点）加网站 extra 里关联到这片区域、
    但这里没有灵魂医者刷新点的墓地（相邻地图上、或只有服务器关联）。网站 linked 里的地图按关联数据
    区分阵营；地图只有一个可用墓地时没有分界线，不导出。"""
    sizes = graveyards.get("size", {})
    extra = graveyards.get("extra", {})
    result = {}
    for map_id in sorted(set(spots) | {int(m) for m in extra}):
        size = sizes.get(str(map_id))
        if not size:
            continue
        width, height = size
        points = [(p[0], p[1], p[2] if len(p) > 2 else "") for p in spots.get(map_id, [])]
        points += [(p[0], p[1], p[2]) for p in extra.get(str(map_id), [])]
        lines = {}
        for faction in ("A", "H"):
            sites = [(x / 100 * width, y / 100 * height) for x, y, f in points if f in ("", faction)]
            lines[faction] = [[round(px / width * 100, 1), round(py / height * 100, 1),
                               round(qx / width * 100, 1), round(qy / height * 100, 1)]
                              for px, py, qx, qy in graveyard_borders(sites, width, height)]
        if lines["A"] == lines["H"]:
            if lines["A"]:
                result[map_id] = {"both": lines["A"]}
        elif lines["A"] or lines["H"]:
            result[map_id] = {key: value for key, value in lines.items() if value}
    return result


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


# 无限版新训练师的阵营：来源数据只能从“对玩家友好”推断，推不出阵营；这里按游戏内确认的结果补上。
# 只在来源没有阵营时生效，来源有了阵营就以来源为准。
# 泽弗拉斯岛（天裔初始地区，地图 2521）：用户 2026-10-01 确认采到的训练师都是联盟方的。
TRAINER_FACTION_OVERRIDES = {npc_id: "A" for npc_id in (
    # 职业训练师
    251373, 251374, 251376, 251379, 251389, 251964, 254081, 254082, 254084, 254086, 254087, 254088,
    # 专业训练师
    251913, 251991, 251993, 257019, 257020, 257021, 257022, 257024,
)}


def trainer_faction(row: dict) -> str | None:
    return row.get("faction") or TRAINER_FACTION_OVERRIDES.get(row.get("id"))


# 新种族出生岛（泽弗拉斯岛）的地图：这里的训练师头衔不写等级（“Alchemist”“Tailor”），
# 但出生地的训练师就是最低一档（用户 2026-10-01 确认），按同专业其他训练师的最低一档补上
STARTER_ISLAND_MAPS = {2521}


def starter_trainer_rank(rows: list) -> str | None:
    """出生岛上没写等级的训练师该补的等级：这个专业其他训练师里最低的一档。

    只在这个专业的训练师大多带等级时才补（制造类专业：出生地都是 journeyman）；采集类专业的训练师头衔
    本来就基本不带等级，其他出生地的同类训练师也没有等级，保持不写。"""
    ranked = [row["rank"] for row in rows if row.get("rank") in TRAINER_RANKS and row.get("map") not in STARTER_ISLAND_MAPS]
    others = [row for row in rows if row.get("map") not in STARTER_ISLAND_MAPS]
    if not ranked or len(ranked) * 2 <= len(others):
        return None
    return min(ranked, key=TRAINER_RANKS.index)


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
            "faction": trainer_faction(row),
            "rank": row.get("rank") if row.get("rank") in TRAINER_RANKS else None,
            "map": row.get("map"),
            "x": row.get("x"),
            "y": row.get("y"),
        } for row in (trainers.get("professions") or {}).get(slug, [])]
        starter_rank = starter_trainer_rank(rows)
        for row in rows:
            if row["rank"] is None and row["map"] in STARTER_ISLAND_MAPS:
                row["rank"] = starter_rank
        out.append({
            "slug": slug,
            "kind": profession.get("kind"),
            "name": {"enUS": profession["name"], "zhCN": zh.get(slug)},
            "icon": icon_name(profession.get("icon")),
            "skillLines": skill_lines.get(profession["name"]),
            "trainers": rows,
        })
    return out


# 网站数据里漏掉、用户在游戏里实测补上的职业训练师（采集插件记录的交互坐标）：职业标识 -> 训练师；
# 网站数据里已有同一个 NPC 就以网站为准（网站补全后这里可以删）
CLASS_TRAINER_EXTRAS = {
    "warlock": [
        # 棘齿城的术士训练师（采集于 2026-10-10，中立，两个阵营都能学）
        {"id": 6251, "name": "Strahad Farsan", "nameZh": "斯坦哈德·法尔杉", "faction": "AH", "map": 1413, "x": 62.6, "y": 35.5},
    ],
}


def build_class_trainers(trainers: dict) -> dict:
    """{[职业] = {{id, name = {enUS, zhCN}, faction, kind, map, x, y}}}，职业为小写的职业标识（mage 等）。"""
    classes = {name: list(rows) for name, rows in (trainers.get("classes") or {}).items()}
    for class_name, extras in CLASS_TRAINER_EXTRAS.items():
        known = {row["id"] for row in classes.get(class_name, [])}
        classes.setdefault(class_name, []).extend(row for row in extras if row["id"] not in known)
    return {class_name: [{
        "id": row["id"],
        "name": {"enUS": row["name"], "zhCN": row.get("nameZh")},
        "faction": trainer_faction(row),
        "kind": row.get("kind"),
        "map": row.get("map"),
        "x": row.get("x"),
        "y": row.get("y"),
    } for row in rows] for class_name, rows in classes.items()}


# 幻化师：用户 2026-10-07 提供的位置（地图 ID 与 /way 坐标）；名字取游戏内英文名，中文名待采集
TRANSMOGRIFIERS = [
    {"name": "Fyrenz Vishonar", "faction": "A", "map": 1453, "x": 48.0, "y": 84.6},
    {"name": "Mon'ye", "faction": "H", "map": 1454, "x": 46.2, "y": 53.6},
    {"name": "Spellweaver Thaldris", "faction": "A", "map": 1416, "x": 17.8, "y": 60.6},
]


def build_transmogrifiers(rows: list) -> list:
    """[{name = {enUS, zhCN}, faction, map, x, y}]：同一地图内按坐标排序，输出稳定。"""
    return [{
        "name": {"enUS": row["name"], "zhCN": row.get("nameZh")},
        "faction": row.get("faction"),
        "map": row["map"],
        "x": row["x"],
        "y": row["y"],
    } for row in sorted(rows, key=lambda r: (r["map"], r["x"], r["y"]))]


BEAST_SPOTS_PER_MAP = 6
BEAST_RANKS = {"rare": "rare", "rare-elite": "rareelite", "elite": "elite", "boss": "boss"}


NORMAL_PET_ATTACK = 2.0  # 秒：没有攻速被动的野兽的攻击间隔


def load_hunter_pet_copy(site: Path) -> dict:
    """调用 node 运行 tools/dump_hunter_pet_copy.mjs，读网站宠物专栏的文案；网站没有文案源码时返回空表。"""
    if not (site / "src" / "data" / "hunterPetCopy.ts").exists():
        return {}
    script = REPO_ROOT / "tools" / "dump_hunter_pet_copy.mjs"
    result = subprocess.run(["node", str(script), str(site)], check=True, capture_output=True, text=True)
    return json.loads(result.stdout)


def build_hunter_pets(pets: dict, copy: dict | None = None) -> dict:
    """{families = {{slug, name, icon, signature, role}}, beasts = {[NPC ID] = {family, levels, rank, new, featured,
    attack, teaches = {{技能 ID, 等级}}, name, why, tip, tags, spots = {{uiMapID, x, y}}, instances}}}。
    插件只做稀有宠物追踪：只带稀有、精英稀有与网站重点宠物，以及每只的特点——攻击间隔（只在不是普通的 2 秒时带）、
    自带的宠物技能等级、家族专属技能（技能 ID，名字运行时向客户端取）；重点宠物另带网站的看点、驯服提示与标签。
    野兽名客户端没有按 ID 查询的接口，带中英两份。"""
    if not pets:
        return {"families": [], "beasts": {}}
    copy = copy or {}
    featured_copy = copy.get("featured") or {}
    family_copy = copy.get("families") or {}
    zone_maps = {slug: meta.get("uiMapId") for slug, meta in (pets.get("zones") or {}).items()}
    ability_ranks = {a["slug"]: [r["spellId"] for r in a.get("ranks", [])] for a in pets.get("abilities", [])}
    featured = set(pets.get("featured") or [])
    beasts = {}
    for b in pets.get("beasts", []):
        rank = BEAST_RANKS.get(b.get("rank"))
        if rank not in ("rare", "rareelite") and b["id"] not in featured:
            continue
        spots = []
        for slug in b.get("zones") or []:
            map_id = zone_maps.get(slug)
            if not map_id:
                continue
            for x, y in (b.get("spawns") or {}).get(slug, [])[:BEAST_SPOTS_PER_MAP]:
                spots.append([map_id, x, y])
        teaches = []
        for slug, level in b.get("teaches") or []:
            ranks = ability_ranks.get(slug) or []
            if 1 <= level <= len(ranks):
                teaches.append([ranks[level - 1], level])
        attack = b.get("attack")
        extra = featured_copy.get(str(b["id"])) or {}
        lo = b.get("minLevel")
        beasts[int(b["id"])] = {
            "family": b.get("family"),
            "levels": [lo, b.get("maxLevel") or lo] if lo else None,
            "rank": rank,
            "new": True if b.get("new") else None,
            "featured": True if b["id"] in featured else None,
            "attack": attack if attack and attack != NORMAL_PET_ATTACK else None,
            "teaches": teaches or None,
            "name": {"enUS": b["name"], "zhCN": b.get("zh")},
            "why": extra.get("why"),
            "tip": extra.get("tip"),
            "tags": extra.get("tags") or None,
            "spots": spots or None,
            "instances": b.get("instances") or None,
        }
    used = {b["family"] for b in beasts.values()}
    families = []
    for f in pets.get("families", []):
        if f["slug"] not in used:
            continue
        signature = (ability_ranks.get(f.get("signature")) or [None])[0]
        families.append({"slug": f["slug"], "name": {"enUS": f["name"], "zhCN": f.get("zh")}, "icon": f.get("icon"),
                         "signature": signature, "role": (family_copy.get(f["slug"]) or {}).get("role")})
    return {"families": families, "beasts": beasts}


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


def build_transport(source: dict) -> dict:
    """公共交通：枢纽（飞艇塔、码头）与航线。源数据在 tools/data/transport.json。
    航线 stops 是按顺序的停靠点：两站为双向往返；三站以上且 loop 为真是单向环线（最后一站回到第一站）。"""
    hubs = {}
    for hub in source["hubs"]:
        hubs[hub["id"]] = {key: hub[key] for key in ("kind", "area", "map", "x", "y", "berths", "taxiNodes", "name") if key in hub}
    for hub_id, hub in hubs.items():
        for target, spot in (hub.get("berths") or {}).items():
            if target not in hubs or "x" not in spot or "y" not in spot:
                raise SystemExit(f"枢纽 {hub_id} 的泊位 {target} 不是已有枢纽，或缺坐标")
    routes = []
    for route in source["routes"]:
        stops = route["stops"]
        if len(stops) < 2 or any(stop not in hubs for stop in stops):
            raise SystemExit(f"航线 {route['id']} 的停靠点不全在枢纽表里")
        if route.get("loop") and len(stops) < 3:
            raise SystemExit(f"航线 {route['id']} 是环线，至少要三个停靠点")
        routes.append({key: route[key] for key in ("id", "kind", "stops", "loop", "faction") if key in route})
    return {"hubs": hubs, "routes": routes}


# 路口箭头方向：L 左、R 右、O 上（北）、U 下（南），两两组合；换成逆时针角度（度），箭头贴图朝右为 0
PATH_ANGLES = {"R": 0, "RO": 45, "O": 90, "LO": 135, "L": 180, "LU": 225, "U": 270, "RU": 315}
PATH_KINDS = ("path", "entrance", "exit")


def build_zone_paths(source: dict) -> dict:
    """区域路口：{ 地图: [ { x, y, to, to2, kind, angle } ] }，源数据在 tools/data/zone-paths.json。"""
    maps: dict[int, list] = {}
    for entry in source["paths"]:
        if entry["dir"] not in PATH_ANGLES or entry["kind"] not in PATH_KINDS:
            raise SystemExit(f"区域路口 {entry} 的方向或类型不认识")
        if not (0 <= entry["x"] <= 100 and 0 <= entry["y"] <= 100):
            raise SystemExit(f"区域路口 {entry} 的坐标不在 0–100 内")
        spot = {"x": entry["x"], "y": entry["y"], "to": entry["to"], "to2": entry.get("to2"),
                "kind": entry["kind"], "angle": PATH_ANGLES[entry["dir"]]}
        maps.setdefault(entry["map"], []).append({key: value for key, value in spot.items() if value is not None})
    return maps


def build_talents(talents: dict, zh_talents: dict) -> dict:
    """天赋树：{职业: {name, trees: [{name, icon, talents: [{name, icon, max, row, col, req, cost, ranks}]}]}}。

    网站天赋数据取自客户端天赋表，没有技能 ID，游戏里也查不到其他职业、尚未学到的各级天赋说明，
    所以名字与每一级的说明随数据带上中英两份（中文为客户端简体中文表的原文）。
    req 是同一棵树里前置天赋的序号，网站从 0 起，这里改为 Lua 的从 1 起；天赋顺序与网站一致，
    这样模拟器生成的分享码能在网站天赋模拟器里打开。"""
    classes = {}
    for class_slug, data in talents["classes"].items():
        zh_trees = zh_talents["classes"].get(class_slug, {}).get("trees", [])
        trees = []
        for tree_index, tree in enumerate(data["trees"]):
            zh_tree = zh_trees[tree_index] if tree_index < len(zh_trees) else {}
            zh_list = zh_tree.get("talents", [])
            rows = []
            for index, talent in enumerate(tree["talents"]):
                zh = zh_list[index] if index < len(zh_list) else {}
                zh_ranks = zh.get("ranks") or []
                if len(talent["ranks"]) != talent["max"]:
                    raise ValueError(f"{class_slug} {talent['name']}: {len(talent['ranks'])} rank texts for max {talent['max']}")
                rows.append({
                    "name": {"enUS": talent["name"], "zhCN": zh.get("name")},
                    "icon": icon_name(talent.get("icon")),
                    "max": talent["max"],
                    "row": talent["row"],
                    "col": talent["col"],
                    "req": talent["req"] + 1 if talent.get("req") is not None else None,
                    "cost": {"enUS": talent["cost"], "zhCN": zh.get("cost")} if talent.get("cost") else None,
                    "ranks": {
                        "enUS": [rank["text"] for rank in talent["ranks"]],
                        "zhCN": [rank["text"] for rank in zh_ranks] if len(zh_ranks) == talent["max"] else None,
                    },
                })
            trees.append({
                "name": {"enUS": tree["name"], "zhCN": zh_tree.get("name")},
                "icon": icon_name(tree.get("icon")),
                "talents": rows,
            })
        # 职业名只带英文作兜底：界面上用客户端的职业名
        classes[class_slug] = {"name": {"enUS": data["name"]}, "trees": trees}
    return classes


PLAN_ROLES = {"damage", "tank", "healer"}


def load_talent_plans(site: Path) -> dict:
    """调用 node 运行 tools/dump_talent_plans.mjs，读网站的推荐天赋方案；网站没有方案源码时返回空表。"""
    if not (site / "src" / "data" / "builds.ts").exists():
        return {}
    script = REPO_ROOT / "tools" / "dump_talent_plans.mjs"
    result = subprocess.run(["node", str(script), str(site)], check=True, capture_output=True, text=True)
    return json.loads(result.stdout)


def build_plan_orders(plan: dict, sizes: list) -> list:
    """各阶段的加点顺序：[{respecAt（洗天赋的等级，最终方案为 nil）, steps: [树 * 100 + 天赋序号, …]}]，序号从 1 起。"""
    orders = []
    for phase in plan.get("orders") or []:
        for step in phase["steps"]:
            tree, index = divmod(step, 100)
            if not (1 <= tree <= len(sizes) and 1 <= index <= sizes[tree - 1]):
                raise ValueError(f"{plan['id']}: step {step} is not a talent")
        orders.append({"respecAt": phase.get("respecAt"), "steps": phase["steps"]})
    if not orders or orders[-1]["respecAt"] is not None:
        raise ValueError(f"{plan['id']}: the last order must be the final plan")
    return orders


def build_talent_plans(raw: dict, talents: dict) -> dict:
    """推荐天赋方案：{职业: {default, plans: [{id, role, first, last, respecs, codes, name, use}]}}。

    codes[n] 是第 first + n - 1 级（Lua 从 1 起）的分享码，与插件天赋模拟器、网站模拟器的分享码一致；
    respecs 是洗天赋的等级（这一级把点数全部重置后按新方案重新分配）；orders 是各阶段的加点顺序，
    供游戏天赋窗口上标“第几级点这个天赋”。只导出插件有天赋树的职业。"""
    classes = {}
    for class_slug, entry in (raw.get("classes") or {}).items():
        trees = (talents.get(class_slug) or {}).get("trees")
        if not trees:
            continue
        sizes = [len(tree["talents"]) for tree in trees]
        plans = []
        for plan in entry["plans"]:
            codes = plan["codes"]
            if plan["role"] not in PLAN_ROLES:
                raise ValueError(f"{plan['id']}: unknown role {plan['role']}")
            if not codes or len(codes) != plan["levels"][1] - 9:
                raise ValueError(f"{plan['id']}: {len(codes)} codes for levels {plan['levels']}")
            for code in codes:
                parts = code.split("-")
                if not re.fullmatch(r"[0-9-]*", code) or len(parts) > len(sizes) \
                        or any(len(part) > size for part, size in zip(parts, sizes)):
                    raise ValueError(f"{plan['id']}: code {code!r} does not fit the {class_slug} trees")
            plans.append({
                "id": plan["id"],
                "role": plan["role"],
                "first": 10,
                "last": plan["levels"][1],
                "respecs": plan.get("respecs") or None,
                "codes": codes,
                "orders": build_plan_orders(plan, sizes),
                "name": {"enUS": plan["name"]["en"] or plan["id"], "zhCN": plan["name"].get("zh")},
                "use": {"enUS": plan["use"].get("en"), "zhCN": plan["use"].get("zh")}
                if plan["use"].get("en") else None,
            })
        ids = {plan["id"] for plan in plans}
        classes[class_slug] = {"default": entry.get("default") if entry.get("default") in ids else None,
                               "plans": plans}
    return classes


BIS_SLOTS = {"Head", "Neck", "Shoulder", "Back", "Chest", "Wrist", "Hands", "Waist", "Legs", "Feet",
             "Finger", "Trinket", "Weapon", "Off Hand", "Ranged", "Relic"}
BIS_SOURCE_ARGS = {"drop": 2, "quest": 1, "vendor": 2, "mob": 2, "trash": 1, "crafted": 2}


def load_bis_gear(site: Path) -> dict:
    """调用 node 运行 tools/dump_bis_gear.mjs，读网站 BiS 页用的装备推荐；网站没有 BiS 源码时返回空表。"""
    if not (site / "src" / "data" / "classLeveling.ts").exists():
        return {}
    script = REPO_ROOT / "tools" / "dump_bis_gear.mjs"
    result = subprocess.run(["node", str(script), str(site)], check=True, capture_output=True, text=True)
    return json.loads(result.stdout)


def merge_faction_picks(alliance: list, horde: list) -> list:
    """把两个阵营的推荐合成一个列表，每项带阵营标记（"" 两边都有，"A" / "H" 只属于一方）。

    按阵营筛出来的顺序与原列表一致（备选装备按好坏排序，顺序有意义）：共同的项按联盟顺序放，
    部落独有的项放在它在部落列表里后面那个共同项之前。"""
    out, j = [], 0
    for pick in alliance:
        k = next((i for i in range(j, len(horde)) if horde[i] == pick), None)
        if k is None:
            out.append((pick, "A"))
            continue
        out.extend((other, "H") for other in horde[j:k])
        out.append((pick, ""))
        j = k + 1
    out.extend((other, "H") for other in horde[j:])
    return out


def bis_timeline(levels: list) -> list:
    """一个阵营逐级的首选装备 -> 变化列表 [(等级, 格子键, 条目或 None)]：只记格子换装备（或空出来）的那一级。

    格子键是装备栏名，戒指与饰品按顺序编号（Finger1、Finger2、Trinket1、Trinket2）；双手武器换下副手时副手记为 None。"""
    changes, worn = [], {}
    for level, gear in enumerate(levels, start=1):
        now, counts = {}, {}
        for pick in gear:
            slot = pick["slot"]
            counts[slot] = counts.get(slot, 0) + 1
            key = f"{slot}{counts[slot]}" if slot in ("Finger", "Trinket") else slot
            now[key] = pick
        for key in list(worn) + [k for k in now if k not in worn]:
            if worn.get(key) != now.get(key):
                changes.append((level, key, now.get(key)))
        worn = now
    return changes


def build_bis_gear(raw: dict, talents: dict, dungeons: list, professions: list, npc_zh: dict) -> dict:
    """BiS 装备：{npcs = {NPC ID: 名字}, siteSets = 网站 BiS 页开放的组, classes = {职业: {default, specs}}}。

    每个天赋：timeline 是网站算法逐级（1–60）的首选装备变化，每项 {等级, 格子键, 阵营, 物品 ID（0 表示这格空出来）,
    获取途径, 参数…}，从这一级起生效，直到同一格子的下一项；bands 是网站原来的 10 级一段（range、alts 各栏备选，好的在前）；
    pvp 是 60 级 PvP 组（range、gear、alts）。gear / alts 每项是 {物品 ID, 装备栏, 阵营, 获取途径, 参数…}。
    阵营 "" 两边都有，"A" 联盟，"H" 部落：两个阵营合在一个列表里，按阵营筛出来与各自的原列表一致。
    获取途径：drop 副本 slug 与首领英文名（插件按副本数据取本地化名字）、quest 任务 ID、vendor / mob NPC ID、
    trash 副本 slug、crafted 专业 slug 与配方技能 ID。物品名称、图标、属性一律运行时向客户端取。
    tree 是天赋树序号（从 1 起，对应 Data/Talents.lua）；slug 是网站 BiS 页的天赋路径。"""
    dungeon_bosses = {}
    for dungeon in dungeons:
        names = dungeon_bosses.setdefault(dungeon["siteSlug"], set())
        names.update(boss["name"]["enUS"] for boss in dungeon.get("bosses") or [])
    profession_slugs = {profession["slug"] for profession in professions}
    npcs, classes = {}, {}

    def source(pick: dict) -> list:
        if pick["slot"] not in BIS_SLOTS or not isinstance(pick["id"], int) or pick["id"] <= 0:
            raise ValueError(f"bad BiS pick {pick}")
        kind, *args = pick["source"]
        if BIS_SOURCE_ARGS.get(kind) != len(args):
            raise ValueError(f"bad BiS source {pick['source']}")
        if kind in ("drop", "trash") and args[0] not in dungeon_bosses:
            raise ValueError(f"BiS source in unknown dungeon {args[0]}")
        if kind == "crafted" and args[0] not in profession_slugs:
            raise ValueError(f"BiS source with unknown profession {args[0]}")
        if kind in ("vendor", "mob"):
            npc_id, name = args
            npcs[npc_id] = {"enUS": name, "zhCN": npc_zh.get(name)}
            args = [npc_id]
        return [kind, *args]

    def merged(alliance: list, horde: list) -> list:
        return [[pick["id"], pick["slot"], side, *source(pick)]
                for pick, side in merge_faction_picks(alliance, horde)]

    def timeline(alliance: list, horde: list) -> list:
        if len(alliance) != len(horde):
            raise ValueError("BiS levels differ between factions")
        a = bis_timeline(alliance)
        h = bis_timeline(horde)
        shared = [change for change in a if change in h]
        rows = [(change, "") for change in shared] + [(c, "A") for c in a if c not in shared] \
            + [(c, "H") for c in h if c not in shared]
        rows.sort(key=lambda row: (row[0][1], row[0][0], row[1]))
        out = []
        for (level, key, pick), side in rows:
            out.append([level, key, side, pick["id"], *source(pick)] if pick else [level, key, side, 0])
        return out

    for class_slug, entry in (raw.get("classes") or {}).items():
        trees = [tree["name"]["enUS"] for tree in (talents.get(class_slug) or {}).get("trees") or []]
        if not trees:
            continue
        specs = []
        for spec in entry["specs"]:
            if spec["tree"] not in trees:
                raise ValueError(f"{class_slug}: BiS spec {spec['tree']} is not a talent tree")
            alliance, horde = spec["alliance"], spec["horde"]
            if [b["range"] for b in alliance["bands"]] != [b["range"] for b in horde["bands"]]:
                raise ValueError(f"{class_slug} {spec['tree']}: faction bands differ")
            specs.append({
                "tree": trees.index(spec["tree"]) + 1,
                "slug": spec["slug"],
                "timeline": timeline(alliance["levels"], horde["levels"]),
                "bands": [{"range": a["range"], "alts": merged(a["alts"], h["alts"])}
                          for a, h in zip(alliance["bands"], horde["bands"])],
                "pvp": {"range": alliance["pvp"]["range"],
                        "gear": merged(alliance["pvp"]["gear"], horde["pvp"]["gear"]),
                        "alts": merged(alliance["pvp"]["alts"], horde["pvp"]["alts"])},
            })
        default = entry.get("default")
        classes[class_slug] = {
            "default": trees.index(default) + 1 if default in trees else None,
            "specs": specs,
        }
    return {"npcs": npcs, "siteSets": raw.get("siteSets") or [], "classes": classes}


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
            "graveyards": build_graveyards(load(generated / "graveyards.json"), load_collected_spirit_healers(site))
            if (generated / "graveyards.json").exists() else {},
            "classTrainers": build_class_trainers(load(generated / "class-trainers.json"))
            if (generated / "class-trainers.json").exists() else {},
            "transmogrifiers": build_transmogrifiers(TRANSMOGRIFIERS),
            "transport": build_transport(load(REPO_ROOT / "tools" / "data" / "transport.json")),
            "zonePaths": build_zone_paths(load(REPO_ROOT / "tools" / "data" / "zone-paths.json")),
            "gathering": build_gathering(load(generated / "gathering-nodes.json"))
            if (generated / "gathering-nodes.json").exists() else {"nodes": [], "maps": {}},
            "professions": build_professions(load(generated / "professions.json"),
                                             load(generated / "zh" / "professions.json"),
                                             load(generated / "profession-trainers.json")
                                             if (generated / "profession-trainers.json").exists() else {},
                                             load_skill_lines(site)),
            "talents": build_talents(load(generated / "talents.json"), load(generated / "zh" / "talents.json"))
            if (generated / "talents.json").exists() else {},
            "talentPlans": {},
            "hunterPets": build_hunter_pets(load(generated / "hunter-pets.json"), load_hunter_pet_copy(site))
            if (generated / "hunter-pets.json").exists() else build_hunter_pets({}),
            "build": load(generated / "zones.json").get("build")}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--site", type=Path, default=DEFAULT_SITE)
    args = parser.parse_args()
    data = export(args.site)
    graveyards_json = args.site / "src" / "data" / "generated" / "graveyards.json"
    data["graveyardAreas"] = build_graveyard_areas(load(graveyards_json), data["graveyards"]) \
        if graveyards_json.exists() else {}
    data["talentPlans"] = build_talent_plans(load_talent_plans(args.site), data["talents"])
    npc_names = args.site / "src" / "data" / "generated" / "zh" / "npc-names.json"
    data["bisGear"] = build_bis_gear(load_bis_gear(args.site), data["talents"], data["dungeons"],
                                     data["professions"], load(npc_names)["names"] if npc_names.exists() else {})
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    write_lua("Zones.lua", "zones", data["zones"])
    write_lua("Dungeons.lua", "dungeons", data["dungeons"])
    write_lua("Quests.lua", "quests", data["quests"])
    write_lua("Spells.lua", "spells", data["spells"])
    write_lua("MapOverlays.lua", "mapOverlays", data["mapOverlays"])
    # 灵魂医者刷新点来自 GPL-3.0 的 Questie，按许可保留署名
    write_lua("Graveyards.lua", "graveyards", data["graveyards"],
              "Spirit healer locations from Questie (https://github.com/Questie/Questie), GPL-3.0.")
    write_lua("GraveyardAreas.lua", "graveyardAreas", data["graveyardAreas"])
    # 训练师名单与坐标主要来自 Questie 项目的 QuestieDB（GPL-3.0），按许可保留署名
    write_lua("Professions.lua", "professions", data["professions"],
              "Profession trainer locations from QuestieDB (https://github.com/Questie/QuestieDB), "
              "the Questie project, GPL-3.0, with positions checked in WoW: Forever.")
    # 职业训练师位置来自 Questie 项目的 QuestieDB（GPL-3.0），按许可保留署名
    write_lua("ClassTrainers.lua", "classTrainers", data["classTrainers"],
              "Class trainer locations from QuestieDB (https://github.com/Questie/QuestieDB), "
              "the Questie project, GPL-3.0, with positions checked in WoW: Forever.")
    write_lua("Transmogrifiers.lua", "transmogrifiers", data["transmogrifiers"])
    # 飞艇塔位置来自 Questie 项目的 QuestieDB（GPL-3.0），按许可保留署名
    write_lua("Transport.lua", "transport", data["transport"],
              "Zeppelin tower locations from QuestieDB (https://github.com/Questie/QuestieDB), "
              "the Questie project, GPL-3.0.")
    write_lua("ZonePaths.lua", "zonePaths", data["zonePaths"])
    # 采集点刷新位置来自 Questie 项目的 QuestieDB（GPL-3.0），按许可保留署名
    write_lua("GatheringNodes.lua", "gathering", data["gathering"],
              "Herb and mining node locations from QuestieDB (https://github.com/Questie/QuestieDB), "
              "the Questie project, GPL-3.0.")
    write_lua("Talents.lua", "talents", data["talents"])
    write_lua("TalentPlans.lua", "talentPlans", data["talentPlans"])
    write_lua("BisGear.lua", "bisGear", data["bisGear"])
    # 野兽刷新位置来自 Questie 项目的 QuestieDB（GPL-3.0），按许可保留署名
    write_lua("HunterPets.lua", "hunterPets", data["hunterPets"],
              "Beast spawn locations from QuestieDB (https://github.com/Questie/QuestieDB), the Questie project, GPL-3.0.")
    print(f"稀有宠物 {len(data['hunterPets']['beasts'])} 只，家族 {len(data['hunterPets']['families'])} 个")
    print(f"推荐天赋方案 {sum(len(c['plans']) for c in data['talentPlans'].values())} 个")
    print(f"BiS 天赋 {sum(len(c['specs']) for c in data['bisGear']['classes'].values())} 个，"
          f"NPC {len(data['bisGear']['npcs'])} 个")
    print(f"天赋 {sum(len(t['talents']) for c in data['talents'].values() for t in c['trees'])} 个，"
          f"职业 {len(data['talents'])}")
    print(f"区域 {len(data['zones'])}，副本 {len(data['dungeons'])}，任务 {len(data['quests'])}，"
          f"职业 {len(data['spells'])}（技能 {sum(len(v) for v in data['spells'].values())}），"
          f"地图探索贴图 {len(data['mapOverlays'])} 张地图，灵魂医者 {sum(len(v) for v in data['graveyards'].values())} 个"
          f"（复活区域 {len(data['graveyardAreas'])} 张地图），"
          f"专业 {len(data['professions'])}（训练师 {sum(len(p['trainers']) for p in data['professions'])}），"
          f"职业训练师 {sum(len(v) for v in data['classTrainers'].values())} 个，幻化师 {len(data['transmogrifiers'])} 个，"
          f"采集点 {sum(len(v) for m in data['gathering']['maps'].values() for v in m.values())} 处")
    if place_conflicts:
        ids = ", ".join(str(item["id"]) for item in place_conflicts[:10])
        print(f"注意：{len(place_conflicts)} 个地点网站坐标与参照不一致且按地点名推断不出地图，未导出坐标（{ids}…）")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
