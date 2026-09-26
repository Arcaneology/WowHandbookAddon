import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import export_site_data as exporter  # noqa: E402


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


if __name__ == "__main__":
    unittest.main()
