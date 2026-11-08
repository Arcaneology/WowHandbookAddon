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

    def test_boss_npc_id_overrides_replace_placeholder_ids(self) -> None:
        zones = [{"slug": "city-of-dalaran", "name": "City of Dalaran", "kind": "dungeon", "levels": [28, 33],
                  "bosses": ["Arcane Anomaly", "Mana Wraith"]},
                 {"slug": "deadmines", "name": "The Deadmines", "kind": "dungeon", "levels": [17, 26],
                  "bosses": ["Sneed"]}]
        facts = {"city-of-dalaran": {"_root": {"Arcane Anomaly": {"npcId": 18401, "level": 24},
                                               "Mana Wraith": {"npcId": 18409, "level": 24}}},
                 "deadmines": {"_root": {"Sneed": {"npcId": 643}}}}
        result = {d["slug"]: d for d in exporter.build_dungeons(zones, {}, {}, {}, {}, None, facts)}
        ids = {b["name"]["enUS"]: b["npcID"] for b in result["city-of-dalaran"]["bosses"]}
        # 有可靠 ID 的换成真实 ID，没有的去掉占位值；等级等其余资料不动
        self.assertEqual(ids, {"Arcane Anomaly": 245999, "Mana Wraith": None})
        self.assertEqual(result["city-of-dalaran"]["bosses"][0]["level"], 24)
        self.assertEqual(result["deadmines"]["bosses"][0]["npcID"], 643)

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


class TransmogrifiersTest(unittest.TestCase):
    def test_rows_are_sorted_and_keep_faction_and_position(self) -> None:
        result = exporter.build_transmogrifiers([
            {"name": "B", "faction": "H", "map": 1454, "x": 46.2, "y": 53.6},
            {"name": "A", "faction": "A", "map": 1453, "x": 48.0, "y": 84.6}])
        self.assertEqual([row["map"] for row in result], [1453, 1454])
        self.assertEqual(result[0], {"name": {"enUS": "A", "zhCN": None}, "faction": "A", "map": 1453, "x": 48.0, "y": 84.6})

    def test_shipped_list_has_the_three_known_npcs(self) -> None:
        names = {row["name"] for row in exporter.TRANSMOGRIFIERS}
        self.assertEqual(names, {"Fyrenz Vishonar", "Mon'ye", "Spellweaver Thaldris"})


class TransportTest(unittest.TestCase):
    def test_shipped_source_is_consistent(self) -> None:
        source = exporter.load(exporter.REPO_ROOT / "tools" / "data" / "transport.json")
        result = exporter.build_transport(source)
        self.assertEqual(len(result["hubs"]), len(source["hubs"]))
        for hub_id, hub in result["hubs"].items():
            if ("x" in hub and "y" in hub) or hub.get("taxiNodes"):
                continue
            # 只有泊位坐标的枢纽（泽风岛）：每条两站航线的另一端都要有泊位
            partners = {stop for route in result["routes"] if hub_id in route["stops"] and not route.get("loop")
                        for stop in route["stops"] if stop != hub_id}
            self.assertTrue(partners and partners <= set(hub.get("berths") or {}), f"hub {hub_id} without a position source")
        loops = [route for route in result["routes"] if route.get("loop")]
        self.assertEqual([route["stops"] for route in loops], [["menethil", "southshore", "auberdine"]])

    def test_route_with_an_unknown_stop_or_a_two_stop_loop_is_rejected(self) -> None:
        hubs = [{"id": "a", "kind": "dock", "map": 1}, {"id": "b", "kind": "dock", "map": 1}]
        with self.assertRaises(SystemExit):
            exporter.build_transport({"hubs": hubs, "routes": [{"id": "X", "kind": "boat", "stops": ["a", "missing"]}]})
        with self.assertRaises(SystemExit):
            exporter.build_transport({"hubs": hubs, "routes": [{"id": "X", "kind": "boat", "stops": ["a", "b"], "loop": True}]})


class ClassTrainerExtrasTest(unittest.TestCase):
    def test_ratchet_warlock_trainer_is_added_once_and_the_site_wins_when_it_has_him(self) -> None:
        added = exporter.build_class_trainers({"classes": {"warlock": []}})["warlock"]
        ratchet = [row for row in added if row["id"] == 6251]
        self.assertEqual(len(ratchet), 1)
        self.assertEqual((ratchet[0]["map"], ratchet[0]["x"], ratchet[0]["y"], ratchet[0]["faction"]), (1413, 62.6, 35.5, "AH"))
        site_has_him = {"classes": {"warlock": [{"id": 6251, "name": "Strahad Farsan", "map": 1413, "x": 60.0, "y": 30.0}]}}
        merged = exporter.build_class_trainers(site_has_him)["warlock"]
        self.assertEqual([(row["x"], row["y"]) for row in merged], [(60.0, 30.0)])


class ZonePathTest(unittest.TestCase):
    def test_shipped_paths_have_known_directions_and_ashenvale_reaches_stonetalon(self) -> None:
        source = exporter.load(exporter.REPO_ROOT / "tools" / "data" / "zone-paths.json")
        result = exporter.build_zone_paths(source)
        self.assertEqual(sum(len(spots) for spots in result.values()), len(source["paths"]))
        self.assertTrue(all(spot["angle"] in exporter.PATH_ANGLES.values() for spots in result.values() for spot in spots))
        # 灰谷 1440 通往石爪山脉 1442，方向左下
        ashenvale = [spot for spot in result[1440] if spot["to"] == 1442]
        self.assertEqual([spot["angle"] for spot in ashenvale], [225])

    def test_unknown_direction_or_coordinates_outside_the_map_are_rejected(self) -> None:
        good = {"map": 1, "x": 1, "y": 1, "to": 2, "dir": "R", "kind": "path"}
        with self.assertRaises(SystemExit):
            exporter.build_zone_paths({"paths": [dict(good, dir="X")]})
        with self.assertRaises(SystemExit):
            exporter.build_zone_paths({"paths": [dict(good, x=120)]})


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

    def test_graveyard_faction_kept_and_collected_points_are_shared(self) -> None:
        site_data = {"maps": {"1411": [[47.0, 17.5, "H"], [53.5, 44.5, ""]]}}
        result = exporter.build_graveyards(site_data, {1411: [[47.2, 17.6]], 2521: [[41.1, 22.3]]})
        self.assertEqual(result[1411], [[47.2, 17.6, "H"], [53.5, 44.5]])  # 实测替换坐标，阵营不变；两边都用的不写
        self.assertEqual(result[2521], [[41.1, 22.3]])

    def test_graveyard_borders_split_by_distance_in_yards(self) -> None:
        # 两个墓地左右对称：分界线是中间那条竖线；地图边框上的边不导出
        borders = exporter.graveyard_borders([(25.0, 50.0), (75.0, 50.0)], 100.0, 100.0)
        self.assertEqual(len(borders), 1)
        x1, y1, x2, y2 = borders[0]
        self.assertAlmostEqual(x1, 50.0)
        self.assertAlmostEqual(x2, 50.0)
        self.assertEqual(sorted((round(y1), round(y2))), [0, 100])
        # 只有一个墓地（或两个几乎重合）时没有分界线
        self.assertEqual(exporter.graveyard_borders([(10.0, 10.0)], 100.0, 100.0), [])
        self.assertEqual(exporter.graveyard_borders([(10.0, 10.0), (10.5, 10.0)], 100.0, 100.0), [])
        # 三个墓地：三条分界线交于一点，相邻两块共用的边只留一条
        three = exporter.graveyard_borders([(20.0, 20.0), (80.0, 20.0), (50.0, 90.0)], 100.0, 100.0)
        self.assertEqual(len(three), 3)

    def test_graveyard_areas_per_faction_in_map_percent(self) -> None:
        # 地图 200 × 100 码：百分比坐标横竖比例不同，必须按码算
        site = {"size": {"1": [200.0, 100.0], "2": [100.0, 100.0]},
                "extra": {"1": [[150.0, 50.0, "A"]], "2": [[50.0, 120.0, ""]]}}
        spots = {1: [[25.0, 50.0], [75.0, 50.0, "H"]], 2: [[50.0, 20.0]]}
        areas = exporter.build_graveyard_areas(site, spots)
        # 联盟：(25, 50) 与地图外的 (150, 50)：中线 x = 87.5%
        self.assertEqual([round(v, 1) for v in areas[1]["A"][0][::2]], [87.5, 87.5])
        # 部落：(25, 50) 与 (75, 50)：中线 x = 50%
        self.assertEqual([round(v, 1) for v in areas[1]["H"][0][::2]], [50.0, 50.0])
        # 两个阵营一样时只存一份；地图外的墓地也参与划分
        self.assertEqual(list(areas[2]), ["both"])
        self.assertEqual([round(v, 1) for v in areas[2]["both"][0][1::2]], [70.0, 70.0])
        # 没有尺寸的地图不导出
        self.assertNotIn(3, exporter.build_graveyard_areas(site, {3: [[1.0, 1.0], [90.0, 90.0]]}))


class TalentPlansTest(unittest.TestCase):
    TALENTS = {"mage": {"trees": [{"talents": [{}] * 3}, {"talents": [{}] * 2}]}}

    def plan(self, **overrides):
        plan = {"id": "mage-test", "role": "damage", "levels": [10, 12], "respecs": [12],
                "codes": ["1", "2", "-1"], "orders": [{"respecAt": 12, "steps": [101, 101]}, {"respecAt": None, "steps": [201, 101]}],
                "name": {"en": "Test", "zh": "测试"}, "use": {"en": "Use", "zh": None}}
        plan.update(overrides)
        return plan

    def test_plan_keeps_codes_and_respecs(self) -> None:
        plans = exporter.build_talent_plans({"classes": {"mage": {"default": "mage-test", "plans": [self.plan()]}}},
                                            self.TALENTS)
        plan = plans["mage"]["plans"][0]
        self.assertEqual(plans["mage"]["default"], "mage-test")
        self.assertEqual((plan["first"], plan["last"], plan["codes"], plan["respecs"]), (10, 12, ["1", "2", "-1"], [12]))
        self.assertEqual(plan["name"], {"enUS": "Test", "zhCN": "测试"})
        self.assertEqual(plan["orders"][1], {"respecAt": None, "steps": [201, 101]})

    def test_unknown_default_and_class_without_trees_are_dropped(self) -> None:
        plans = exporter.build_talent_plans({"classes": {
            "mage": {"default": "other", "plans": [self.plan()]},
            "rogue": {"default": None, "plans": [self.plan(id="rogue-test")]},
        }}, self.TALENTS)
        self.assertIsNone(plans["mage"]["default"])
        self.assertNotIn("rogue", plans)

    def test_codes_must_cover_every_level_and_fit_the_trees(self) -> None:
        for bad in (self.plan(codes=["1", "2"]), self.plan(codes=["1", "2", "1111"]), self.plan(role="dps"),
                    self.plan(orders=[{"respecAt": None, "steps": [104]}]), self.plan(orders=[{"respecAt": 12, "steps": [101]}])):
            with self.assertRaises(ValueError):
                exporter.build_talent_plans({"classes": {"mage": {"plans": [bad]}}}, self.TALENTS)


class BisGearTest(unittest.TestCase):
    TALENTS = {"mage": {"trees": [{"name": {"enUS": "Arcane"}}, {"name": {"enUS": "Fire"}}, {"name": {"enUS": "Frost"}}]}}
    DUNGEONS = [{"siteSlug": "deadmines", "bosses": [{"name": {"enUS": "Mr. Smite"}}]}]
    PROFESSIONS = [{"slug": "tailoring"}]

    @staticmethod
    def pick(item, slot, *source):
        return {"id": item, "slot": slot, "source": list(source)}

    def faction(self, levels, alts=None, pvp=None):
        return {"levels": levels, "bands": [{"range": [1, 10], "alts": alts or []}],
                "pvp": {"range": [50, 60], "gear": pvp or [], "alts": []}}

    def raw(self, alliance, horde, tree="Frost"):
        return {"siteSets": ["20"], "classes": {"mage": {"default": "Frost", "specs": [
            {"tree": tree, "slug": "frost", "alliance": alliance, "horde": horde}]}}}

    def build(self, raw):
        return exporter.build_bis_gear(raw, self.TALENTS, self.DUNGEONS, self.PROFESSIONS, {"Vendor Bob": "商人鲍勃"})

    def test_timeline_records_changes_and_shares_common_ones(self) -> None:
        hat = self.pick(1, "Head", "drop", "deadmines", "Mr. Smite")
        better = self.pick(5, "Head", "crafted", "tailoring", 555)
        staff = self.pick(2, "Weapon", "quest", 100)
        sword = self.pick(3, "Weapon", "vendor", 7, "Vendor Bob")
        ring_a, ring_b = self.pick(8, "Finger", "quest", 9), self.pick(9, "Finger", "quest", 10)
        alliance = self.faction([[hat, staff, ring_a, ring_b], [better, staff, ring_a, ring_b]],
                                alts=[self.pick(4, "Head", "quest", 11)], pvp=[hat])
        horde = self.faction([[hat, sword, ring_a], [better, sword, ring_a]],
                             alts=[self.pick(4, "Head", "quest", 11)], pvp=[hat])
        data = self.build(self.raw(alliance, horde))
        spec = data["classes"]["mage"]["specs"][0]
        self.assertEqual((data["classes"]["mage"]["default"], spec["tree"], spec["slug"]), (3, 3, "frost"))
        self.assertEqual(spec["timeline"], [
            [1, "Finger1", "", 8, "quest", 9],
            [1, "Finger2", "A", 9, "quest", 10],
            [1, "Head", "", 1, "drop", "deadmines", "Mr. Smite"],
            [2, "Head", "", 5, "crafted", "tailoring", 555],
            [1, "Weapon", "A", 2, "quest", 100],
            [1, "Weapon", "H", 3, "vendor", 7],
        ])
        self.assertEqual(spec["bands"], [{"range": [1, 10], "alts": [[4, "Head", "", "quest", 11]]}])
        self.assertEqual(spec["pvp"]["gear"], [[1, "Head", "", "drop", "deadmines", "Mr. Smite"]])
        self.assertEqual(data["npcs"], {7: {"enUS": "Vendor Bob", "zhCN": "商人鲍勃"}})
        self.assertEqual(data["siteSets"], ["20"])

    def test_emptied_slot_is_recorded(self) -> None:
        two_hand, main, off = self.pick(1, "Weapon", "quest", 1), self.pick(2, "Weapon", "quest", 2), \
            self.pick(3, "Off Hand", "quest", 3)
        changes = exporter.bis_timeline([[main, off], [two_hand]])
        self.assertIn((2, "Off Hand", None), changes)
        self.assertIn((2, "Weapon", two_hand), changes)

    def test_merge_keeps_each_faction_order(self) -> None:
        alliance, horde = ["a", "b", "c", "x"], ["c", "b", "y", "x"]
        merged = exporter.merge_faction_picks(alliance, horde)
        for side, original in (("A", alliance), ("H", horde)):
            self.assertEqual([pick for pick, mark in merged if mark in ("", side)], original)

    def test_bad_sources_are_rejected(self) -> None:
        for bad in (self.pick(1, "Shirt", "quest", 1), self.pick(1, "Head", "drop", "nowhere", "X"),
                    self.pick(1, "Head", "crafted", "cooking", 2), self.pick(1, "Head", "teleport", 3),
                    self.pick(1, "Head", "quest")):
            with self.assertRaises(ValueError):
                self.build(self.raw(self.faction([[bad]]), self.faction([[bad]])))
        with self.assertRaises(ValueError):
            self.build(self.raw(self.faction([]), self.faction([]), tree="Shadow"))


if __name__ == "__main__":
    unittest.main()


class HunterPetsTest(unittest.TestCase):
    PETS = {
        "families": [{"id": 2, "slug": "cat", "name": "Cat", "zh": "豹", "icon": "ability_hunter_pet_cat",
                      "diet": ["meat", "fish"], "abilities": ["prowl", "bite"], "signature": "prowl",
                      "confirmed": True, "modifiers": {"damage": 10, "armor": 0, "health": -2}}],
        "abilities": [{"slug": "prowl", "name": "Prowl", "zh": "潜伏", "kind": "signature", "icon": "x",
                       "ranks": [{"rank": 1, "spellId": 24450, "level": 30}, {"rank": 2, "spellId": 24452, "level": 0}],
                       "families": ["cat"], "cooldown": 10}],
        "beasts": [
            {"id": 5828, "name": "Humar the Pridelord", "zh": "狮王休玛", "family": "cat", "minLevel": 23,
             "maxLevel": 23, "rank": "rare-elite", "new": False, "evidence": "forever-db", "attack": 1.3,
             "teaches": [["prowl", 2], ["prowl", 9]],
             "zones": ["the-barrens", "nowhere"], "instances": [],
             "spawns": {"the-barrens": [[62.0, 33.3]] * 8, "nowhere": [[1, 1]]}},
            {"id": 3653, "name": "Kresh", "zh": None, "family": "turtle", "minLevel": 20, "maxLevel": None, "attack": 2.0,
             "rank": "elite", "new": True, "zones": [], "instances": ["wailing-caverns"], "spawns": {}},
        ],
        "featured": [5828, 99999],
        "zones": {"the-barrens": {"uiMapId": 1413}},
    }

    COPY = {"featured": {"5828": {"why": {"enUS": "Black lion", "zhCN": "黑狮"}, "tip": {"enUS": "Trap it", "zhCN": "放陷阱"},
                                  "tags": ["look", "pvp"]}},
            "families": {"cat": {"role": {"enUS": "Damage", "zhCN": "输出"}}}}

    def test_shape_and_limits(self):
        pets = dict(self.PETS)
        pets["beasts"] = self.PETS["beasts"] + [{"id": 1, "name": "Plain Wolf", "family": "wolf", "minLevel": 5,
                                                  "rank": None, "zones": [], "spawns": {}}]
        out = exporter.build_hunter_pets(pets, self.COPY)
        # 家族只带名称、图标、专属技能（第 1 级的技能 ID）与网站的定位；修正、食谱放网站
        self.assertEqual(out["families"], [{"slug": "cat", "name": {"enUS": "Cat", "zhCN": "豹"},
                                            "icon": "ability_hunter_pet_cat", "signature": 24450,
                                            "role": {"enUS": "Damage", "zhCN": "输出"}}])
        self.assertNotIn("abilities", out)
        humar = out["beasts"][5828]
        self.assertEqual((humar["rank"], humar["featured"]), ("rareelite", True))
        # 特点：攻击间隔、自带技能（技能 ID 与等级；超出技能等级数的丢掉）、网站文案
        self.assertEqual(humar["attack"], 1.3)
        self.assertEqual(humar["teaches"], [[24452, 2]])
        self.assertEqual((humar["why"]["zhCN"], humar["tip"]["enUS"], humar["tags"]), ("黑狮", "Trap it", ["look", "pvp"]))
        self.assertEqual(len(humar["spots"]), exporter.BEAST_SPOTS_PER_MAP)  # 每张图限量；没有 uiMapID 的地区跳过
        self.assertEqual(humar["spots"][0], [1413, 62.0, 33.3])
        # 不是稀有、也不是重点的普通野兽不进插件
        self.assertNotIn(1, out["beasts"])
        self.assertNotIn(3653, out["beasts"])
        self.assertNotIn("evidence", humar)  # 网站内部字段不进插件

    def test_featured_non_rare_kept(self):
        pets = dict(self.PETS, featured=[5828, 3653])
        kresh = exporter.build_hunter_pets(pets)["beasts"][3653]
        self.assertEqual((kresh["levels"], kresh["new"], kresh["featured"], kresh["spots"], kresh["instances"]),
                         ([20, 20], True, True, None, ["wailing-caverns"]))
        # 普通攻速（2 秒）不带；没有文案时不带看点
        self.assertEqual((kresh["attack"], kresh["teaches"], kresh["why"], kresh["tags"]), (None, None, None, None))

    def test_missing_source(self):
        self.assertEqual(exporter.build_hunter_pets({}), {"families": [], "beasts": {}})
