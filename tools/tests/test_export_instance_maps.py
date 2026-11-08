import io
import struct
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import export_instance_maps as exporter  # noqa: E402


def rows_for(folder, prefix, floors, flat=False):
    rows = []
    fid = 1000
    for floor in floors:
        for tile in range(1, 13):
            fid += 1
            name = f"{prefix}{tile}" if flat else f"{prefix}{floor}_{tile}"
            rows.append((str(fid), f"interface/worldmap/{folder}/{name}.blp"))
    return rows


class FloorTilesTest(unittest.TestCase):
    def test_consecutive_floors_only(self):
        art = {70: ("uldaman", "uldaman")}
        tiles = exporter.floor_tiles(rows_for("uldaman", "uldaman", [1, 2, 18]), art)
        self.assertEqual(len(tiles[70]), 2)
        self.assertEqual(len(tiles[70][0]), 12)

    def test_flat_legacy_floor(self):
        art = {209: ("zulfarrak", "zulfarrak")}
        tiles = exporter.floor_tiles(rows_for("zulfarrak", "zulfarrak", [1], flat=True), art)
        self.assertEqual(len(tiles[209]), 1)

    def test_underscored_form_wins_and_tiles_in_order(self):
        art = {34: ("thestockade", "thestockade")}
        rows = rows_for("thestockade", "thestockade", [1], flat=True) + rows_for("thestockade", "thestockade", [1])
        tiles = exporter.floor_tiles(reversed(rows), art)
        underscored = [int(fid) for fid, path in rows[12:]]
        self.assertEqual(tiles[34][0], underscored)

    def test_incomplete_floor_skipped(self):
        art = {389: ("ragefire", "ragefire")}
        self.assertEqual(exporter.floor_tiles(rows_for("ragefire", "ragefire", [1])[:11], art), {})


class FanMapTest(unittest.TestCase):
    def test_size_never_upscales(self):
        self.assertEqual(exporter.fan_size(3000, 2000), (1536, 1024))
        self.assertEqual(exporter.fan_size(1200, 800), (1200, 800))
        self.assertEqual(exporter.grid(1536, 1024, 512), (3, 2))
        self.assertEqual(exporter.grid(1200, 800, 512), (3, 2))

    def test_blp_round_trip(self):
        try:
            from PIL import Image
        except ImportError:
            self.skipTest("Pillow unavailable")
        image = Image.new("RGB", (64, 64), (200, 150, 50))
        data = exporter.blp2_dxt1(image)
        self.assertEqual(data[:4], b"BLP2")
        self.assertEqual(struct.unpack("<II", data[12:20]), (64, 64))
        decoded = Image.open(io.BytesIO(data)).convert("RGB")
        r, g, b = decoded.getpixel((10, 10))
        self.assertTrue(abs(r - 200) <= 10 and abs(g - 150) <= 10 and abs(b - 50) <= 10)


if __name__ == "__main__":
    unittest.main()
