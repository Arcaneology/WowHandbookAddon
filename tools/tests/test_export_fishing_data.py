import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from export_fishing_data import build  # noqa: E402


SAMPLE = {
    "build": "1.60.1.70959",
    "zones": [{
        "slug": "durotar", "level": -70,
        "waters": [
            {"areas": ["Durotar"], "areasZh": ["杜隆塔尔"], "main": True, "level": -70,
             "catch": [[6303, 98.0, "", 1, 1], [6356, 2.0, "", 1, 1]]},
            {"areas": ["Sen'jin Village"], "areasZh": ["森金村"], "main": False, "level": -70,
             "catch": [[6291, 58.8, "", 1, 1]]},
        ],
        "schools": [{"name": "Floating Wreckage", "nameZh": "帆船残骸", "yields": [[21113, 60.0, "", 1, 1]]}],
    }],
    "items": {"6303": ["Raw Slitherskin Mackerel", "新鲜的滑皮鲭鱼", "common", "fish"],
              "6356": ["Raw Bristle", "", "common", "fish"], "6291": ["x", "", "common", "fish"],
              "21113": ["Watertight Trunk", "", "common", "treasure"], "999": ["Unused", "", "poor", "junk"]},
}


class BuildTest(unittest.TestCase):
    def test_zone_map_and_waters(self):
        data = build(SAMPLE, {"durotar": 1411})
        zone = data["zones"][0]
        self.assertEqual(zone["map"], 1411)
        self.assertEqual(zone["level"], -70)
        self.assertTrue(zone["waters"][0]["main"])
        self.assertEqual(zone["waters"][1]["areas"], {"enUS": ["Sen'jin Village"], "zhCN": ["森金村"]})
        self.assertEqual(zone["waters"][0]["catch"][0], [6303, 98.0, "", 1, 1])
        self.assertEqual(zone["schools"][0]["name"], {"enUS": "Floating Wreckage", "zhCN": "帆船残骸"})

    def test_kinds_only_used_items(self):
        kinds = build(SAMPLE, {"durotar": 1411})["kinds"]
        self.assertEqual(kinds[21113], "treasure")
        self.assertNotIn(999, kinds)

    def test_missing_map_fails(self):
        with self.assertRaises(ValueError):
            build(SAMPLE, {})


if __name__ == "__main__":
    unittest.main()
