import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import export_site_data as exporter  # noqa: E402


class DeadminesSiteSyncTest(unittest.TestCase):
    def test_toxic_soil_chain_stays_under_one_dungeon_card(self):
        if not (exporter.DEFAULT_SITE / "src/data/quest-chain-overrides.json").exists():
            self.skipTest("Local website checkout unavailable")
        data = exporter.export(exporter.DEFAULT_SITE)
        quests = data["quests"]
        self.assertTrue(quests[92753]["newInForeverChain"])
        self.assertFalse(quests[92753].get("inside"))
        self.assertEqual(quests[92753]["before"], [92742,92744,92745,92747,92748,92749,92750,92751,92752])
        self.assertEqual(quests[92753]["after"], [92819])
        self.assertEqual(quests[92819]["before"], [92753])
        self.assertTrue(quests[92819]["chainOnly"])
        self.assertEqual(quests[92742]["min"], 12)
        self.assertEqual(quests[92753]["min"], 12)
        self.assertTrue(quests[92819]["summary"]["zhCN"])
        dungeon = next(d for d in data["dungeons"] if d["slug"] == "deadmines")
        self.assertIn(92753, dungeon["quests"])
        for qid in [92742,92744,92745,92747,92748,92749,92750,92751,92752,92819]:
            self.assertNotIn(qid, dungeon["quests"])

    def test_curated_site_classification_reaches_addon(self):
        site = exporter.DEFAULT_SITE
        if not (site / "src/data/deadminesQuestSync.ts").exists():
            self.skipTest("Local website checkout unavailable")
        doc = {"quests": [{"id": 92819}, {"id": 166}],
               "referenceQuests": [{"id": 1654}, {"id": 92819}, {"id": 92747}]}
        zh = {}
        exporter.apply_deadmines_site_sync(site, doc, zh)
        self.assertEqual([q["id"] for q in doc["quests"]], [166, 1654])
        self.assertEqual([q["id"] for q in doc["referenceQuests"]], [92747])
        paladin = doc["quests"][-1]
        result = exporter.build_quests([paladin], zh, {"chains": {}, "steps": {}}, {},
                                       {"Dun Morogh": 1426})[1654]
        self.assertTrue(result["relatedExternal"])
        self.assertEqual(result["classRestriction"], "PALADIN")
        self.assertEqual(result["before"], [1653])
        self.assertEqual(result["start"]["map"], 1426)
        self.assertEqual(result["name"]["zhCN"], "正义试炼")


class ResolveMapTest(unittest.TestCase):
    ZONES = {"Ashenvale": 1440, "Swamp of Sorrows": 1435, "Orgrimmar": 1454}

    def test_exact_name(self) -> None:
        self.assertEqual(exporter.resolve_map("Ashenvale", self.ZONES), 1440)

    def test_subzone_comma_zone(self) -> None:
        self.assertEqual(exporter.resolve_map("Zoram'gar Outpost, Ashenvale", self.ZONES), 1440)

    def test_case_insensitive(self) -> None:
        self.assertEqual(exporter.resolve_map("Swamp Of Sorrows", self.ZONES), 1435)

    def test_inside_instance_is_none(self) -> None:
        self.assertIsNone(exporter.resolve_map("Blackrock Depths — Shadowforge City", self.ZONES))
        self.assertIsNone(exporter.resolve_map(None, self.ZONES))


class PlaceTest(unittest.TestCase):
    ZONES = {"Westfall": 1436, "Dun Morogh": 1426}

    def place(self, source, reference=None):
        return exporter.place(dict(source, kind="npc", id=1, name="N"), self.ZONES, None, reference)

    def setUp(self) -> None:
        exporter.place_conflicts.clear()

    def test_site_only(self) -> None:
        p = self.place({"location": "Westfall", "coordinates": [10, 20]})
        self.assertEqual((p["map"], p["x"], p["y"]), (1436, 10, 20))
        self.assertNotIn("unverified", p)

    def test_reference_map_without_coordinates_corrects_the_map(self) -> None:
        p = self.place({"location": "Dun Morogh", "coordinates": [69.5, 50.3]}, {"uiMapId": 1455})
        self.assertEqual((p["map"], p["x"], p["y"]), (1455, 69.5, 50.3))

    def test_matching_reference_coordinates_use_reference_map(self) -> None:
        p = self.place({"location": "Sentinel Tower", "coordinates": [56.7, 47.3]},
                       {"uiMapId": 1436, "coordinates": [56.8, 47.0]})
        self.assertEqual((p["map"], p["x"], p["y"]), (1436, 56.7, 47.3))

    def test_conflicting_reference_never_mixes_sources(self) -> None:
        # 参照 map=200、坐标 (70,80)，网站坐标 (10,20)：不得输出 map=200 + (10,20)
        p = self.place({"location": "Westfall", "coordinates": [10, 20]}, {"uiMapId": 200, "coordinates": [70, 80]})
        self.assertEqual((p["map"], p["x"], p["y"]), (1436, 10, 20))
        p = self.place({"location": "Nowhere", "coordinates": [10, 20]}, {"uiMapId": 200, "coordinates": [70, 80]})
        self.assertEqual((p["map"], p["x"], p["y"]), (None, None, None))
        self.assertEqual(len(exporter.place_conflicts), 1)

    def test_reference_only_is_whole_and_unmarked(self) -> None:
        p = self.place({"location": "Westfall"}, {"uiMapId": 1436, "coordinates": [30, 40]})
        self.assertEqual((p["map"], p["x"], p["y"]), (1436, 30, 40))
        self.assertNotIn("unverified", p)
        p = self.place({"location": "Nowhere"}, {"coordinates": [30, 40]})
        self.assertEqual((p["map"], p["x"], p["y"]), (None, None, None))


class SpellIdTest(unittest.TestCase):
    def test_prefers_matching_learn_level(self) -> None:
        ids = {("mage", "Frostbolt", "Rank 1"): [(1, 9999), (4, 116)]}
        self.assertEqual(exporter.pick_spell_id(ids, "mage", "Frostbolt", "Rank 1", 4), 116)

    def test_falls_back_to_lowest_id(self) -> None:
        ids = {("mage", "Frostbolt", "Rank 1"): [(0, 205), (0, 116)]}
        self.assertEqual(exporter.pick_spell_id(ids, "mage", "Frostbolt", "Rank 1", 4), 116)

    def test_missing_spell(self) -> None:
        self.assertIsNone(exporter.pick_spell_id({}, "mage", "Frostbolt", "Rank 1", 4))


class FactionOnlyDungeonTest(unittest.TestCase):
    def test_capital_dungeons_are_faction_only(self) -> None:
        self.assertEqual(exporter.FACTION_ONLY_DUNGEONS["hall-of-thanes"], "alliance")
        self.assertEqual(exporter.FACTION_ONLY_DUNGEONS["ragefire-chasm"], "horde")


class LuaValueTest(unittest.TestCase):
    def test_nested_table(self) -> None:
        text = exporter.lua_value({1440: {"levels": [18, 30], "name": {"enUS": "Ash\"en", "zhCN": "灰谷"}, "x": None}})
        self.assertIn("[1440] = {", text)
        self.assertIn("levels = { 18, 30 }", text)
        self.assertIn('enUS = "Ash\\"en"', text)
        self.assertIn('zhCN = "灰谷"', text)
        self.assertNotIn("x =", text)  # 空值不输出

    def test_non_identifier_keys_are_quoted(self) -> None:
        self.assertIn('["npc:1"] = 2', exporter.lua_value({"npc:1": 2}))


class SpellRanksTest(unittest.TestCase):
    def test_learned_at_level_is_not_filtered(self) -> None:
        spellbook = {"classes": {"mage": {"tabs": [{"name": "Fire", "spells": [
            {"name": "Fire Blast", "rank": "Rank 2", "icon": "/icons/game/spell_fire_fireball.jpg",
             "requires": "Learned at level 6",
             "ranks": [{"rank": "Rank 1", "level": 6}, {"rank": "Rank 2", "level": 14}]},
        ]}]}}}
        zh = {"classes": {"mage": {"tabs": [{"name": "火焰", "spells": [{"name": "火焰冲击"}]}]}}}
        spells = exporter.build_spells(spellbook, zh)["mage"]
        self.assertEqual(len(spells), 1)
        self.assertEqual(spells[0]["name"], {"enUS": "Fire Blast", "zhCN": "火焰冲击"})
        self.assertEqual(spells[0]["icon"], "spell_fire_fireball")
        self.assertEqual([r["level"] for r in spells[0]["ranks"]], [6, 14])


class StartsInsideTest(unittest.TestCase):
    def test_locations(self) -> None:
        inside = exporter.starts_inside
        self.assertTrue(inside({"kind": "item", "location": None}, ["Deadmines"]))
        self.assertTrue(inside({"kind": "npc", "location": "Blackrock Depths — Shadowforge City"}, ["Blackrock Depths"]))
        self.assertTrue(inside({"kind": "npc", "location": "Blackrock Spire"}, ["Lower Blackrock Spire"]))
        self.assertTrue(inside({"kind": "npc", "location": "Hall of Thanes — west wing"}, ["The Hall of Thanes"]))
        self.assertTrue(inside({"kind": "npc", "location": "map 48"}, ["Blackfathom Deeps"]))
        self.assertFalse(inside({"kind": "npc", "location": "Blackrock Mountain — central tomb"}, ["Blackrock Depths"]))
        self.assertFalse(inside({"kind": "npc", "location": "Sentinel Tower (56.4, 47.5)"}, ["Deadmines"]))
        self.assertFalse(inside({"kind": "npc", "location": "Westfall"}, ["The Deadmines"]))
        self.assertFalse(inside(None, ["Deadmines"]))


class MapOverlaysTest(unittest.TestCase):
    def test_tiles_are_row_major_per_map(self) -> None:
        art = [{"UiMapArtID": "7", "UiMapID": "1411", "PhaseID": "0"}]
        overlays = [
            {"ID": "1", "UiMapArtID": "7", "TextureWidth": "300", "TextureHeight": "100", "OffsetX": "10",
             "OffsetY": "20", "PlayerConditionID": "0"},
            {"ID": "2", "UiMapArtID": "7", "TextureWidth": "10", "TextureHeight": "10", "OffsetX": "0",
             "OffsetY": "0", "PlayerConditionID": "55"},
        ]
        tiles = [
            {"WorldMapOverlayID": "1", "RowIndex": "0", "ColIndex": "1", "LayerIndex": "0", "FileDataID": "502"},
            {"WorldMapOverlayID": "1", "RowIndex": "0", "ColIndex": "0", "LayerIndex": "0", "FileDataID": "501"},
            {"WorldMapOverlayID": "2", "RowIndex": "0", "ColIndex": "0", "LayerIndex": "0", "FileDataID": "900"},
        ]
        result = exporter.build_map_overlays(art, overlays, tiles)
        self.assertEqual(result, {1411: [[300, 100, 10, 20, 501, 502]]})


class RewardsTest(unittest.TestCase):
    def test_money_parsing(self) -> None:
        self.assertEqual(exporter.money_copper("35s"), 3500)
        self.assertEqual(exporter.money_copper("1g 5s 20c"), 10520)
        self.assertIsNone(exporter.money_copper(None))
        self.assertEqual(exporter.money_copper(250), 250)

    def test_rewards(self) -> None:
        rewards = {"experience": 2400, "money": "35s", "items": [],
                   "choiceItems": [{"id": 7003}, {"id": 7004}], "reputation": [{"name": "Darnassus", "value": 150}]}
        zh = {"reputation": [{"name": "达纳苏斯"}]}
        result = exporter.build_rewards(rewards, zh)
        self.assertEqual(result["xp"], 2400)
        self.assertEqual(result["money"], 3500)
        self.assertEqual([c["id"] for c in result["choices"]], [7003, 7004])
        self.assertNotIn("items", result)
        self.assertEqual(result["reputation"][0]["name"], {"enUS": "Darnassus", "zhCN": "达纳苏斯"})

    def test_extra_reward_items_use_a_neutral_field(self) -> None:
        result = exporter.build_rewards({"items": []}, None, {"rewardItemIds": [901], "followUpRewardItemIds": [902]})
        self.assertEqual(result["extraItems"], [{"id": 901}, {"id": 902, "followUp": True}])
        self.assertNotIn("referenceItems", result)


class DungeonSectionsTest(unittest.TestCase):
    def test_sections_become_independent_dungeons_with_drop_metadata(self) -> None:
        zones = [{"slug": "scarlet-monastery", "name": "Scarlet Monastery", "kind": "dungeon",
                  "levels": [30, 40], "sections": [
                      {"slug": "scarlet-library", "name": "Scarlet Monastery Library", "nameZh": "血色修道院图书馆",
                       "levelMin": 32, "levelMax": 39, "bosses": ["Arcanist Doan"]},
                  ]}]
        loot = {"scarlet-monastery": {"sections": {"scarlet-library": {
            "bosses": {"Arcanist Doan": [111, 222]}}}}}
        details = {"scarlet-monastery": {"scarlet-library": {"Arcanist Doan": {
            "111": {"rate": 12.5, "unverified": True, "newInForever": True}}}}}
        quests = {1: {"instances": ["scarlet-monastery"], "sectionSlugs": ["scarlet-library"]},
                  2: {"instances": ["scarlet-monastery"], "sectionSlugs": ["unassigned"]}}
        result = exporter.build_dungeons(zones, {}, loot, quests, {}, details)
        self.assertEqual(len(result), 2)
        dungeon = next(d for d in result if d.get("parentSlug"))
        self.assertEqual(dungeon["parentSlug"], "scarlet-monastery")
        self.assertEqual(dungeon["slug"], "scarlet-monastery-scarlet-library")
        self.assertEqual(dungeon["name"]["zhCN"], "血色修道院图书馆")
        self.assertEqual(dungeon["levels"], [32, 39])
        self.assertEqual(dungeon["quests"], [1])
        self.assertEqual(dungeon["bosses"][0]["items"][0]["id"], 111)
        self.assertEqual(dungeon["bosses"][0]["items"][0]["rate"], 12.5)
        # 未验证只进采集插件的待核验清单，主插件数据不带这个标记
        self.assertNotIn("unverified", dungeon["bosses"][0]["items"][0])
        self.assertTrue(dungeon["bosses"][0]["items"][0]["newInForever"])
        self.assertEqual(dungeon["bosses"][0]["items"][1]["id"], 222)
        fallback = next(d for d in result if d.get("aggregateOnly"))
        self.assertEqual(fallback["quests"], [2])

    def test_loot_table_rows_outside_site_bosses_are_loot_only(self) -> None:
        zones = [{"slug": "deadmines", "name": "The Deadmines", "kind": "dungeon", "levels": [17, 26],
                  "bosses": ["Rhahk'Zor", "Sneed"]},
                 {"slug": "new-dungeon", "name": "New Dungeon", "kind": "dungeon", "levels": [30, 35]}]
        loot = {"deadmines": {"bosses": {"Rhahk'Zor": [1], "Miner Johnson": [2], "Sneed's Shredder": [3]},
                              "extra": [{"name": "Trash mobs", "items": [4]}]},
                "new-dungeon": {"bosses": {"Someone": [5]}}}
        result = {d["slug"]: d for d in exporter.build_dungeons(zones, {}, loot, {}, {})}
        flags = {b["name"]["enUS"]: b["lootOnly"] for b in result["deadmines"]["bosses"]}
        self.assertEqual(flags, {"Rhahk'Zor": None, "Sneed": None, "Miner Johnson": True,
                                 "Sneed's Shredder": True, "Trash mobs": True})
        # 网站还没有首领列表时不标记，掉落表的行照常当首领
        self.assertIsNone(result["new-dungeon"]["bosses"][0]["lootOnly"])

    def test_deadmines_bosses_follow_the_actual_route(self) -> None:
        zones = [{"slug": "deadmines", "name": "The Deadmines", "kind": "dungeon", "levels": [17, 26],
                  "bosses": ["Rhahk'Zor", "Sneed", "Gilnid", "Captain Greenskin", "Mr. Smite", "Cookie",
                             "Edwin VanCleef"]}]
        loot = {"deadmines": {"bosses": {"Miner Johnson": [1]}}}
        result = exporter.build_dungeons(zones, {}, loot, {}, {})[0]
        self.assertEqual([b["name"]["enUS"] for b in result["bosses"]],
                         ["Rhahk'Zor", "Sneed", "Gilnid", "Mr. Smite", "Captain Greenskin", "Edwin VanCleef",
                          "Cookie", "Miner Johnson"])


class ProfessionsTest(unittest.TestCase):
    def test_trainers_join_their_profession_with_both_names(self) -> None:
        professions = {"professions": [{"slug": "alchemy", "kind": "primary", "name": "Alchemy",
                                        "icon": "/icons/game/trade_alchemy.jpg", "recipes": []}]}
        zh = {"professions": [{"slug": "alchemy", "name": "炼金术"}]}
        trainers = {"professions": {"alchemy": [
            {"id": 3184, "name": "Miao'zan", "nameZh": "米奥赞", "faction": "H", "rank": "journeyman",
             "map": 1411, "x": 55.4, "y": 74.0, "position": "questie"},
            {"id": 5, "name": "Somebody", "nameZh": None, "faction": "A", "rank": "odd",
             "map": 1453, "x": None, "y": None, "position": None}]}}
        result = exporter.build_professions(professions, zh, trainers)[0]
        self.assertEqual(result["name"], {"enUS": "Alchemy", "zhCN": "炼金术"})
        self.assertEqual(result["icon"], "trade_alchemy")
        self.assertEqual(result["trainers"][0]["name"], {"enUS": "Miao'zan", "zhCN": "米奥赞"})
        self.assertEqual(result["trainers"][0]["rank"], "journeyman")
        # 未知的等级不导出；没有坐标的保留地图
        self.assertIsNone(result["trainers"][1]["rank"])
        self.assertEqual(result["trainers"][1]["map"], 1453)
        self.assertIsNone(result["trainers"][1]["x"])


class ClassTrainersTest(unittest.TestCase):
    def test_trainers_keep_kind_and_both_names(self) -> None:
        result = exporter.build_class_trainers({"classes": {"hunter": [
            {"id": 3306, "name": "Keldas", "nameZh": "凯尔达斯", "faction": "A", "kind": "pet",
             "map": 1438, "x": 56.1, "y": 59.7, "position": "questie"}]}})
        self.assertEqual(result["hunter"][0], {"id": 3306, "name": {"enUS": "Keldas", "zhCN": "凯尔达斯"},
                                               "faction": "A", "kind": "pet", "map": 1438, "x": 56.1, "y": 59.7})


class GatheringTest(unittest.TestCase):
    def test_nodes_keep_item_and_skill_and_maps_use_numeric_ids(self) -> None:
        gathering = {"nodes": [{"key": "peacebloom", "kind": "herb", "item": 2447, "skill": 1, "rare": False, "objects": [1618]},
                               {"key": "silver_vein", "kind": "ore", "item": 2775, "skill": 75, "rare": True, "objects": [1733]}],
                     "maps": {"1411": {"herb": [[35.7, 28.4, 1]]}}}
        result = exporter.build_gathering(gathering)
        # 稀有变种带 rare，普通的不写这个字段
        self.assertEqual(result["nodes"], [{"kind": "herb", "item": 2447, "skill": 1, "rare": None, "objects": [1618]},
                                           {"kind": "ore", "item": 2775, "skill": 75, "rare": True, "objects": [1733]}])
        self.assertEqual(result["maps"], {1411: {"herb": [[35.7, 28.4, 1]]}})


class PetSpellTest(unittest.TestCase):
    def test_demon_ranks_split_into_grimoire_and_innate(self) -> None:
        spellbook = {"classes": {"warlock": {"tabs": [{"name": "Imp", "pet": True, "spells": [
            {"name": "Firebolt", "rank": "Rank 2", "level": 1,
             "ranks": [{"rank": "Rank 1", "level": 1}, {"rank": "Rank 2", "level": 8}]},
            {"name": "Phase Shift", "rank": "", "level": 12},
        ]}]}}}
        zh = {"classes": {"warlock": {"tabs": [{"name": "小鬼", "spells": [{"name": "火焰箭"}, {"name": "相位转移"}]}]}}}
        grimoires = {"Firebolt": {2: {"item": 16302, "price": 400, "level": 8}},
                     "Phase Shift": {0: {"item": 16331, "price": 900, "level": 12}}}
        firebolt, phase = exporter.build_spells(spellbook, zh, grimoires)["warlock"]
        self.assertEqual(firebolt["pet"], {"enUS": "Imp", "zhCN": "小鬼"})
        self.assertTrue(firebolt["ranks"][0]["innate"])
        self.assertEqual(firebolt["ranks"][1]["book"], 16302)
        self.assertEqual(phase["ranks"][0]["book"], 16331)

    def test_without_grimoire_data_nothing_is_marked(self) -> None:
        spellbook = {"classes": {"warlock": {"tabs": [{"name": "Imp", "pet": True, "spells": [
            {"name": "Firebolt", "rank": "Rank 1", "level": 1}]}]}}}
        zh = {"classes": {"warlock": {"tabs": [{"name": "小鬼", "spells": [{"name": "火焰箭"}]}]}}}
        rank = exporter.build_spells(spellbook, zh, {})["warlock"][0]["ranks"][0]
        self.assertNotIn("innate", rank)
        self.assertNotIn("book", rank)


class GraveyardsTest(unittest.TestCase):
    def test_talents_keep_site_order_with_one_based_prerequisites(self) -> None:
        talent = {"name": "Deflection", "max": 2, "row": 1, "col": 2, "icon": "/icons/game/ability_parry.jpg",
                  "ranks": [{"text": "Parry +1%."}, {"text": "Parry +2%."}]}
        active = {"name": "Riposte", "max": 1, "row": 3, "col": 2, "icon": "/icons/game/ability_warrior_challange.jpg",
                  "ranks": [{"text": "Strike back."}], "req": 0, "cost": "10 Energy | Instant"}
        english = {"classes": {"rogue": {"name": "Rogue", "trees": [
            {"name": "Combat", "icon": "/icons/game/ability_backstab.jpg", "talents": [talent, active]}]}}}
        chinese = {"classes": {"rogue": {"name": "Rogue", "trees": [{"name": "战斗", "talents": [
            {"name": "偏斜", "ranks": [{"text": "招架 +1%。"}, {"text": "招架 +2%。"}]},
            {"name": "还击", "ranks": [{"text": "反击。"}], "cost": "10点能量 | 瞬发"}]}]}}}
        tree = exporter.build_talents(english, chinese)["rogue"]["trees"][0]
        self.assertEqual(tree["name"], {"enUS": "Combat", "zhCN": "战斗"})
        self.assertEqual(tree["icon"], "ability_backstab")
        first, second = tree["talents"]
        self.assertEqual((first["max"], first["row"], first["col"], first["req"]), (2, 1, 2, None))
        self.assertEqual(first["ranks"], {"enUS": ["Parry +1%.", "Parry +2%."], "zhCN": ["招架 +1%。", "招架 +2%。"]})
        self.assertEqual(second["req"], 1)  # 网站从 0 起，Lua 从 1 起
        self.assertEqual(second["cost"], {"enUS": "10 Energy | Instant", "zhCN": "10点能量 | 瞬发"})
        # 每一级都要有说明，否则导出报错而不是带着残缺数据上线
        broken = {"classes": {"rogue": {"name": "Rogue", "trees": [{"name": "Combat", "talents": [dict(talent, max=3)]}]}}}
        with self.assertRaises(ValueError):
            exporter.build_talents(broken, chinese)

    def test_collected_spirit_healers_replace_nearby_points_and_add_new_ones(self) -> None:
        site_data = {"maps": {"1458": [[68.2, 9.1]], "1429": [[39.5, 60.5], [83.6, 69.7]]}}
        collected = {1458: [[68.0, 14.0]], 1429: [[39.4, 60.5]], 2521: [[41.1, 22.3]]}
        result = exporter.build_graveyards(site_data, collected)
        self.assertEqual(result[1458], [[68.0, 14.0]])                 # 5 以内：换成实测坐标
        self.assertEqual(result[1429], [[39.4, 60.5], [83.6, 69.7]])   # 没采到的点保留
        self.assertEqual(result[2521], [[41.1, 22.3]])                 # 新地图：新增
        self.assertEqual(list(result), [1429, 1458, 2521])
        self.assertEqual(exporter.build_graveyards(site_data)[1458], [[68.2, 9.1]])

    def test_collected_spirit_healers_read_from_the_snapshot(self) -> None:
        import tempfile
        with tempfile.TemporaryDirectory() as folder:
            archive = Path(folder) / "assets" / "addon-collector"
            archive.mkdir(parents=True)
            self.assertEqual(exporter.load_collected_spirit_healers(Path(folder)), {})
            (archive / "latest_WowHandbook_Collector.lua").write_text(
                'WowHandbookCollectorDB = {\n["npcs"] = {\n[375] = {\n["positions"] = {\n["1429:49.8:39.5"] = 2,\n},\n},\n'
                '[6491] = {\n["nearPositions"] = {\n["1420:79.2:40.9"] = 1,\n},\n["positions"] = {\n'
                '["2521:41.1:22.4"] = 1,\n["2521:41.1:22.3"] = 2,\n["1458:68.0:14.0"] = 1,\n},\n},\n'
                '[7000] = {\n["positions"] = {\n["1:1.0:1.0"] = 1,\n},\n},\n},\n}\n', encoding="utf-8")
            # 只取灵魂医者的交互坐标；同一处的两个坐标合并，取次数多的
            self.assertEqual(exporter.load_collected_spirit_healers(Path(folder)),
                             {2521: [[41.1, 22.3]], 1458: [[68.0, 14.0]]})

    def test_new_trainers_get_their_confirmed_faction_unless_the_source_has_one(self) -> None:
        rows = [{"id": 254086, "name": "Shenaan Spellwind", "faction": None, "map": 2521, "x": 45.1, "y": 45.8},
                {"id": 254086, "name": "Same NPC with a source faction", "faction": "AH", "map": 2521},
                {"id": 999999, "name": "Unknown new trainer", "faction": None, "map": 2521}]
        mage = exporter.build_class_trainers({"classes": {"mage": rows}})["mage"]
        self.assertEqual([t["faction"] for t in mage], ["A", "AH", None])
        professions = exporter.build_professions(
            {"professions": [{"slug": "alchemy", "name": "Alchemy"}]}, {"professions": []},
            {"professions": {"alchemy": [{"id": 257019, "name": "Nyassa Swiftdraught", "map": 2521}]}})
        self.assertEqual(professions[0]["trainers"][0]["faction"], "A")

    def test_starter_island_trainers_get_the_lowest_rank_of_their_profession(self) -> None:
        def trainer(npc_id, rank, map_id):
            return {"id": npc_id, "name": f"T{npc_id}", "rank": rank, "map": map_id, "x": 1.0, "y": 1.0}
        professions = {"professions": [{"slug": "tailoring", "name": "Tailoring"}, {"slug": "mining", "name": "Mining"}]}
        trainers = {"professions": {
            "tailoring": [trainer(1, "journeyman", 1429), trainer(2, "expert", 1453), trainer(3, "artisan", 1453),
                          trainer(4, None, 2521), trainer(5, None, 1411)],
            # 采集类：其他训练师基本不带等级，出生岛上的也不补
            "mining": [trainer(6, None, 1429), trainer(7, None, 1426), trainer(8, "artisan", 1453), trainer(9, None, 2521)],
        }}
        tailoring, mining = exporter.build_professions(professions, {"professions": []}, trainers)
        ranks = {row["id"]: row["rank"] for row in tailoring["trainers"] + mining["trainers"]}
        self.assertEqual(ranks[4], "journeyman")  # 出生岛：补成这个专业最低的一档
        self.assertIsNone(ranks[5])               # 其他地图没写等级的不动
        self.assertIsNone(ranks[9])
        self.assertEqual(ranks[2], "expert")

    def test_graveyards_keyed_by_ui_map(self) -> None:
        graveyards = exporter.build_graveyards({"maps": {"1453": [[49.7, 42.5]], "1429": [[83.6, 69.8], [39.5, 60.5]]}})
        self.assertEqual(list(graveyards), [1429, 1453])
        self.assertEqual(graveyards[1429], [[83.6, 69.8], [39.5, 60.5]])
        self.assertEqual(exporter.build_graveyards({}), {})


if __name__ == "__main__":
    unittest.main()
