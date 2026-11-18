#!/usr/bin/env python3
"""从网站数据生成专业工作台的配方数据 WowHandbook/Data/Recipes.lua。

每个制造类专业：中英文名、图标、技能线 ID（识别玩家学了哪个专业）、全部配方（技能 ID、变黄 / 变绿 / 变灰的技能点、
产物、材料、配方物品）、冲级推荐（与网站 skillUpPicks 同一规则）。采集类专业（草药、剥皮、钓鱼）没有配方。

怎么学会（冲级路线用，来自网站 recipe-acquisition.json）：
learn 学会它需要的技能点；auto 随专业等级自动学会；nip 标为未实装；via 图纸物品的获取方式
（vendor / drop / quest，空表为未知）；buy 图纸的商人金币价，按阵营 { A = 铜, H = 铜 }；
spot 各阵营最便宜的图纸商人位置 { A = { 地图, x, y } }；
cooldown 冷却秒数（有冷却的不能连做，冲级路线不用）；tools 背包里要有的工具，每组任选其一 { { 物品, ... } }。

ns.Data.reagentVendorPrices：材料的商人金币价 { [物品] = { A = 铜, H = 铜 } }（网站 vendor-stock.json）。

手册路线 route（有攻略的专业才有）：网站专业攻略页的固定制作顺序，
{ recipe 配方 ID, from, to, crafts 次数, stock 为后面备料（不涨点）, keepBelow 备料在技能低于它时还需要（网站叫 until，那是 Lua 的保留字）, forced 做一件留着的工具 }。
攻略在网站的 TypeScript 里，所以用 node 读；没有 node 或读取失败时不带 route，工作台就只有计算的路线。

只读网站仓库。用法（仓库根目录）：
    python3 tools/export_recipe_data.py [--site /path/to/WowHandbook]
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
OUTPUT = REPO_ROOT / "WowHandbook" / "Data" / "Recipes.lua"

sys.path.insert(0, str(REPO_ROOT / "tools"))
from export_site_data import DEFAULT_SITE, icon_name, load, load_skill_lines, lua_value  # noqa: E402

# 采集类专业靠采集升级，网站不列配方也不给冲级推荐（src/data/professions.ts 的 GATHERING）
GATHERING = {"herbalism", "skinning", "fishing"}
# 冲级分段，与网站 skillBrackets 一致；Forever 有 300 以上的配方，插件多一段 300–375
SKILL_BRACKETS = ((1, 75), (75, 150), (150, 225), (225, 300), (300, 375))


def skill_up_picks(recipes: list, low: int, high: int, limit: int = 6) -> list:
    """与网站 skillUpPicks 相同：分段开始时仍是橙色的配方，按变黄的技能点排序，同分时材料少的在前。
    学习配方所需技能是服务器数据，客户端没有，所以变黄点比分段起点高 60 以上的视为多半还学不到，不选。"""
    def materials(recipe):
        return sum(count for _, count in recipe.get("reagents") or [])
    picks = [r for r in recipes if r.get("skill") and low < r["skill"][0] <= high + 25 and r["skill"][0] - low <= 60]
    picks.sort(key=lambda r: (r["skill"][0], materials(r)))
    return picks[:limit]


def recipe_item_price(vendors: list) -> dict | None:
    """图纸的商人金币价（每个阵营取最低）；只收代币的商人不算。"""
    best: dict = {}
    for vendor in vendors or []:
        price = vendor.get("price")
        if not price or vendor.get("currency"):
            continue
        for side in ("A", "H"):
            if side in (vendor.get("faction") or "AH"):
                best[side] = min(best.get(side, price), price)
    return best or None


def reagent_vendor_prices(vendor_stock: dict | None, reagent_ids: set) -> dict:
    """材料的商人金币价（网站 vendor-stock.json，在商人窗口实测）：只收配方材料，每个阵营取最低。
    玩家没在本机记过这件物品的商人价时，冲级路线用它（Modules/Workbench.lua 的 Market）。"""
    best: dict = {}
    for vendor in ((vendor_stock or {}).get("vendors") or {}).values():
        sides = vendor.get("faction") or "AH"
        for item, price in (vendor.get("items") or {}).items():
            item_id = int(item)
            if item_id not in reagent_ids or not price or price <= 0:
                continue
            entry = best.setdefault(item_id, {})
            for side in ("A", "H"):
                if side in sides:
                    entry[side] = min(entry.get(side, price), price)
    return {item: prices for item, prices in sorted(best.items()) if prices}


def recipe_item_spot(vendors: list) -> dict | None:
    """每个阵营最便宜的、有坐标的图纸商人：{A: [uiMapID, x, y], H: [...]}，点一下在地图上标出。"""
    best: dict = {}
    for vendor in vendors or []:
        price = vendor.get("price")
        if not price or vendor.get("currency") or not (vendor.get("map") and vendor.get("x") is not None):
            continue
        for side in ("A", "H"):
            if side in (vendor.get("faction") or "AH") and (side not in best or price < best[side][0]):
                best[side] = (price, [vendor["map"], vendor["x"], vendor["y"]])
    return {side: spot for side, (_, spot) in best.items()} or None


def acquisition_fields(entry: dict | None) -> dict:
    """recipe-acquisition.json 的一条 → 配方上的 learn / auto / nip / via / buy。"""
    entry = entry or {}
    return {
        "learn": (entry.get("learn") or [None])[0],
        "auto": True if entry.get("auto") else None,
        "nip": True if entry.get("nip") else None,
        "via": entry.get("via") if entry.get("item") else None,
        "buy": recipe_item_price(entry.get("vendors")),
        "spot": recipe_item_spot(entry.get("vendors")),
    }


def build_recipes(profession: dict, acquisition: dict | None = None, cooldowns: dict | None = None,
                  tools: dict | None = None) -> tuple[list, list]:
    """配方（按变黄的技能点排序）与冲级推荐 [{from, to, picks: [技能 ID]}]。名称、图标运行时向客户端取。
    cooldowns（recipe-cooldowns.json）与 tools（recipe-tools.json）给了才带 cooldown / tools 字段。"""
    if profession["slug"] in GATHERING:
        return [], []
    recipes = []
    for recipe in sorted(profession.get("recipes") or [], key=lambda r: ((r.get("skill") or [999])[0], r["id"])):
        creates = recipe.get("creates") or []
        recipes.append({
            "id": recipe["id"],
            "skill": recipe.get("skill"),
            "makes": creates[0] if creates else None,
            "count": creates[1] if len(creates) > 1 and creates[1] != 1 else None,
            "reagents": [value for item, count in recipe.get("reagents") or [] for value in (item, count)],
            "learnedFrom": recipe.get("learnedFrom"),
            "new": True if recipe.get("new") else None,
            **(acquisition_fields(acquisition.get(str(recipe["id"]))) if acquisition is not None else {}),
            **({"cooldown": cooldowns.get(str(recipe["id"]))} if cooldowns is not None else {}),
            **({"tools": tools.get(str(recipe["id"]))} if tools is not None else {}),
        })
    guide = []
    for low, high in SKILL_BRACKETS:
        picks = skill_up_picks(profession.get("recipes") or [], low, high)
        if picks:
            guide.append({"from": low, "to": high, "picks": [r["id"] for r in picks]})
    return recipes, guide



# 与网站 src/components/ProfessionGuide.astro 的 liveFixed 同一个算式（until 改名 keepBelow）
HANDBOOK_SCRIPT = """
const g = await import('./src/data/guides.ts');
const m = await import('./src/data/guideModel.ts');
const p = await import('./src/data/professions.ts');
const out = {};
for (const spec of Object.values(g.professionGuides)) {
  const profession = p.getProfessions('en').find((x) => x.slug === spec.slug);
  const { stages } = m.buildGuide(spec, profession.recipes);
  out[spec.slug] = stages.flatMap((stage) => stage.steps.map((step) => ({
    recipe: step.entry.id, from: step.from, to: step.stock ? step.from : step.to, crafts: step.count,
    stock: step.stock || undefined, keepBelow: step.stock ? stage.to : undefined, forced: step.keep ? true : undefined,
  })));
}
console.log(JSON.stringify(out));
"""


def handbook_routes(site: Path) -> dict:
    """各专业的手册路线 {slug: [步骤]}；读不到时返回空表并说明原因。"""
    try:
        done = subprocess.run(["node", "--input-type=module", "-e", HANDBOOK_SCRIPT], cwd=site, check=True,
                              capture_output=True, text=True, timeout=120)
        return json.loads(done.stdout.strip().splitlines()[-1])
    except (OSError, subprocess.SubprocessError, ValueError, IndexError) as error:
        print(f"手册路线没有导出（需要 node 读网站的攻略）：{error}", file=sys.stderr)
        return {}


def build(site: Path, routes: dict | None = None) -> list:
    generated = site / "src" / "data" / "generated"
    professions = load(generated / "professions.json")
    zh = {p["slug"]: p["name"] for p in load(generated / "zh" / "professions.json").get("professions", [])}
    skill_lines = load_skill_lines(site)
    acquisition_file = generated / "recipe-acquisition.json"
    acquisition = load(acquisition_file).get("recipes", {}) if acquisition_file.exists() else None

    def optional(name: str) -> dict | None:
        file = generated / name
        return load(file).get("recipes", {}) if file.exists() else None

    cooldowns, tools = optional("recipe-cooldowns.json"), optional("recipe-tools.json")
    out = []
    for profession in professions.get("professions", []):
        recipes, guide = build_recipes(profession, acquisition, cooldowns, tools)
        if not recipes:
            continue
        out.append({
            "slug": profession["slug"],
            "kind": profession.get("kind"),
            "name": {"enUS": profession["name"], "zhCN": zh.get(profession["slug"])},
            "icon": icon_name(profession.get("icon")),
            "skillLines": skill_lines.get(profession["name"]),
            "recipes": recipes,
            "guide": guide,
            "route": (routes or {}).get(profession["slug"]),
        })
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--site", type=Path, default=DEFAULT_SITE)
    args = parser.parse_args()
    data = build(args.site, handbook_routes(args.site))
    reagent_ids = {r["reagents"][i] for p in data for r in p["recipes"] for i in range(0, len(r.get("reagents") or []), 2)}
    stock_file = args.site / "src" / "data" / "generated" / "vendor-stock.json"
    vendor_prices = reagent_vendor_prices(load(stock_file) if stock_file.exists() else None, reagent_ids)
    OUTPUT.write_text(
        "-- 自动生成的数据文件，请勿手工编辑（tools/export_recipe_data.py）。\n"
        "local ADDON_NAME, ns = ...\n"
        "ns.Data = ns.Data or {}\n"
        f"ns.Data.recipes = {lua_value(data)}\n"
        f"ns.Data.reagentVendorPrices = {lua_value(vendor_prices)}\n", encoding="utf-8")
    print(f"Recipes.lua：{len(data)} 个专业，配方 {sum(len(p['recipes']) for p in data)} 个，"
          f"手册路线 {sum(1 for p in data if p.get('route'))} 个")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
