import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import export_recipe_data as recipe_export  # noqa: E402


class RecipeGuideTest(unittest.TestCase):
    def test_picks_follow_the_site_rule(self) -> None:
        recipes = [
            {"id": 1, "skill": [10, 15, 20], "reagents": [[100, 3]]},
            {"id": 2, "skill": [10, 15, 20], "reagents": [[100, 1]]},  # 同分，材料少的在前
            {"id": 3, "skill": [5, 10, 15], "reagents": []},
            {"id": 4, "skill": [1, 5, 10], "reagents": []},            # 分段起点就不是橙色了
            {"id": 5, "skill": [90, 95, 100], "reagents": []},         # 比起点高 60 以上，多半学不到
            {"id": 6, "reagents": []},                                  # 没有技能点
        ]
        self.assertEqual([r["id"] for r in recipe_export.skill_up_picks(recipes, 1, 75)], [3, 2, 1])

    def test_gathering_has_no_recipes_and_crafting_keeps_reagent_pairs(self) -> None:
        self.assertEqual(recipe_export.build_recipes({"slug": "herbalism", "recipes": [{"id": 1, "skill": [1, 2, 3]}]}), ([], []))
        recipes, guide = recipe_export.build_recipes({"slug": "alchemy", "recipes": [
            {"id": 7, "skill": [20, 25, 30], "creates": [500, 2], "reagents": [[765, 1], [3371, 1]],
             "learnedFrom": 900, "new": True}]})
        self.assertEqual(recipes[0], {"id": 7, "skill": [20, 25, 30], "makes": 500, "count": 2,
                                      "reagents": [765, 1, 3371, 1], "learnedFrom": 900, "new": True, "favor": None})
        self.assertEqual(guide, [{"from": 1, "to": 75, "picks": [7]}])

    def test_acquisition_adds_learn_skill_and_recipe_item_price(self) -> None:
        acquisition = {
            "7": {"item": 900, "learn": [20, "client"], "via": ["vendor"], "vendors": [
                {"npc": 1, "price": 500, "faction": "A"},
                {"npc": 2, "price": 400, "faction": "AH", "map": 1453, "x": 10.5, "y": 20},
                {"npc": 3, "price": 100, "faction": "H", "currency": [5, 2]}]},   # 只收代币的不算
            "8": {"trainer": True, "learn": [35, "measured"]},
            "9": {"auto": True, "nip": True},
        }
        recipes, _ = recipe_export.build_recipes({"slug": "alchemy", "recipes": [
            {"id": 7, "skill": [20, 25, 30], "reagents": [], "learnedFrom": 900},
            {"id": 8, "skill": [40, 45, 50], "reagents": []},
            {"id": 9, "skill": [1, 5, 10], "reagents": []},
            {"id": 10, "skill": [60, 65, 70], "reagents": []}]}, acquisition)
        by_id = {r["id"]: r for r in recipes}
        self.assertEqual((by_id[7]["learn"], by_id[7]["via"], by_id[7]["buy"]), (20, ["vendor"], {"A": 400, "H": 400}))
        self.assertEqual(by_id[7]["spot"], {"A": [1453, 10.5, 20], "H": [1453, 10.5, 20]})
        self.assertIsNone(by_id[8]["spot"])
        self.assertEqual((by_id[8]["learn"], by_id[8]["via"], by_id[8]["buy"]), (35, None, None))
        self.assertEqual((by_id[9]["auto"], by_id[9]["nip"], by_id[9]["learn"]), (True, True, None))
        self.assertIsNone(by_id[10]["learn"])

    def test_merchant_favor_offers_mark_recipes_and_list_unmatched_formulas(self) -> None:
        favor = recipe_export.favor_offers({"offerings": [
            {"id": 900, "role": "alchemy", "favor": 45, "gold": None, "standing": "honored", "skill": 20,
             "sides": ["alliance", "horde"]},
            {"id": 901, "role": "alchemy", "favor": 60, "gold": None, "standing": None, "skill": 300,
             "sides": ["horde"]}]})
        recipes, _ = recipe_export.build_recipes({"slug": "alchemy", "recipes": [
            {"id": 7, "skill": [20, 25, 30], "reagents": [], "learnedFrom": 900}]}, None, None, None, favor)
        self.assertEqual(recipes[0]["favor"], {"cost": 45, "standing": "honored", "gold": None, "side": None})
        self.assertEqual(recipe_export.build_formulas("alchemy", recipes, favor),
                         [{"item": 901, "favor": 60, "standing": None, "skill": 300, "side": "H"}])
        self.assertIsNone(recipe_export.build_formulas("tailoring", recipes, favor))

    def test_cooldowns_and_tools_are_added_when_given(self) -> None:
        recipes, _ = recipe_export.build_recipes({"slug": "alchemy", "recipes": [
            {"id": 7, "skill": [20, 25, 30], "reagents": []},
            {"id": 8, "skill": [40, 45, 50], "reagents": []}]}, None, {"7": 3600}, {"8": [[5956, 6219]]})
        by_id = {r["id"]: r for r in recipes}
        self.assertEqual((by_id[7]["cooldown"], by_id[7]["tools"]), (3600, None))
        self.assertEqual((by_id[8]["cooldown"], by_id[8]["tools"]), (None, [[5956, 6219]]))

    def test_reagent_vendor_prices_keep_reagents_and_cheapest_per_faction(self) -> None:
        stock = {"vendors": {
            "1": {"faction": "A", "items": {"2604": 50, "2321": 100, "9999": 5}},
            "2": {"faction": "A", "items": {"2604": 45}},
            "3": {"faction": "H", "items": {"2604": 60}},
            "4": {"faction": "", "items": {"2321": 90}}}}
        prices = recipe_export.reagent_vendor_prices(stock, {2604, 2321})
        self.assertEqual(prices, {2321: {"A": 90, "H": 90}, 2604: {"A": 45, "H": 60}})
        self.assertEqual(recipe_export.reagent_vendor_prices(None, {2604}), {})


if __name__ == "__main__":
    unittest.main()
