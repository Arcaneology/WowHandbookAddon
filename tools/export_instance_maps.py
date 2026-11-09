#!/usr/bin/env python3
"""生成副本地图数据 WowHandbook/Data/InstanceMaps.lua 与玩家自制地图贴图 WowHandbook/Media/InstanceMaps/*.blp。

无限版客户端没有副本的 UiMap 行，大地图在副本里只能退回世界地图。做法与网站副本页一致：

- 经典 1–60 地下城与团队副本：客户端里仍带着这些副本每层 4 × 3 张、每张 256 像素的地图贴图
  （interface/worldmap/<目录>/<前缀><层>_<格>.blp，拼起来裁成 1002 × 668）。插件只记文件 ID，
  贴图在运行时由客户端加载，不随插件分发。文件 ID 来自网站仓库的社区 listfile，
  目录与“只取从 1 开始的连续层”的规则与网站 scripts/extract-maps.py 相同；团队副本是插件另加的，
  逐张拼图核对过与经典布局一致（2026-11-07，客户端 1.60.1.70790）。
- 无限版新地下城：客户端没有地图贴图，用网站同样采用的玩家自制地图（Santiago Reyes 绘制，
  网站 src/data/fanMaps.ts 记录了来源与授权说明）。原图保持原样（含水印，只等比缩小），
  切成 512 像素的格子，压成 DXT1 的 BLP2 贴图；界面上署名作者。

用法（仓库根目录）：python3 tools/export_instance_maps.py [--site /path/to/WowHandbook] [--skip-images]
"""

from __future__ import annotations

import argparse
import csv
import re
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import export_site_data as site_export  # noqa: E402

REPO_ROOT = Path(__file__).resolve().parents[1]
MEDIA_DIR = REPO_ROOT / "WowHandbook" / "Media" / "InstanceMaps"
MEDIA_PATH = "Interface\\AddOns\\WowHandbook\\Media\\InstanceMaps\\"
LISTFILE = Path("assets/research/listfile/community-listfile.csv")
FAN_ORIGINALS = Path("assets/research/maps/fan-originals")

# 客户端地图贴图：每层 4 × 3 格，每格 256 像素，拼好后取左上 1002 × 668
CLIENT_TILE = 256
CLIENT_COLUMNS = 4
CLIENT_WIDTH, CLIENT_HEIGHT = 1002, 668

# 副本地图 ID（GetInstanceInfo 第 8 个返回值）→ 客户端地图目录与文件名前缀。
# 地下城与网站 INSTANCE_FLOOR_ART 相同：通灵学院用 old 目录（不是后来的重制版）；血色修道院用
# scarletmonastery（old 目录没有英文版）。
INSTANCE_FLOOR_ART = {
    389: ("ragefire", "ragefire"),
    36: ("thedeadmines", "thedeadmines"),
    43: ("wailingcaverns", "wailingcaverns"),
    33: ("shadowfangkeep", "shadowfangkeep"),
    48: ("blackfathomdeeps", "blackfathomdeeps"),
    34: ("thestockade", "thestockade"),
    90: ("gnomeregan", "gnomeregan"),
    47: ("razorfenkraul", "razorfenkraul"),
    189: ("scarletmonastery", "scarletmonastery"),
    129: ("razorfendowns", "razorfendowns"),
    70: ("uldaman", "uldaman"),
    209: ("zulfarrak", "zulfarrak"),
    349: ("maraudon", "maraudon"),
    109: ("thetempleofatalhakkar", "thetempleofatalhakkar"),
    230: ("blackrockdepths", "blackrockdepths"),
    229: ("blackrockspire", "blackrockspire"),
    429: ("diremaul", "diremaul"),
    329: ("stratholme", "stratholme"),
    289: ("scholomanceold", "scholomanceold"),
    # 团队副本
    409: ("moltencore", "moltencore"),
    249: ("onyxiaslair", "onyxiaslair"),
    309: ("zulgurub", "zulgurub"),
    469: ("blackwinglair", "blackwinglair"),
    509: ("ruinsofahnqiraj", "ruinsofahnqiraj"),
    531: ("ahnqiraj", "ahnqiraj"),
    533: ("naxxramas", "naxxramas"),
}

# 玩家自制地图：副本地图 ID → 原图（网站 assets/research/maps/fan-originals/）与各层的名字。
# 层名是本地化表的键；只有一层时不显示层名。
FAN_ARTIST = "Santiago Reyes"
# 2026-11-08 用户决定：向作者确认授权之前，玩家自制地图不随插件分发（0.6.0 起关闭，不生成数据与贴图）。
# 确认后改为 True 并重新运行本脚本即可恢复；插件代码仍支持带 artist 的副本地图。
FAN_MAPS_ENABLED = False
FAN_TILE = 512
FAN_MAX_WIDTH = 1536
FAN_MAPS = {
    3065: [{"source": "hallofthanes.jpg", "name": "hall-of-thanes"}],
    2999: [{"source": "rol.jpg", "name": "ruins-of-lordaeron"}],
    2998: [{"source": "excavation-site-wetlands-wowhead-1305264.jpg", "name": "excavation-site-wetlands"}],
    2959: [
        {"source": "city-of-dalaran-1-icyveins.webp", "name": "city-of-dalaran-1", "label": "City"},
        {"source": "city-of-dalaran-2-icyveins.webp", "name": "city-of-dalaran-2", "label": "Underbelly"},
    ],
}


# ---------------------------------------------------------------------------
# 客户端地图贴图
# ---------------------------------------------------------------------------

def floor_tiles(rows, floor_art: dict) -> dict:
    """listfile 行 (fileID, path) → {mapID: [[12 个文件 ID], ...]}，按层排列。"""
    wanted = {folder: (map_id, prefix) for map_id, (folder, prefix) in floor_art.items()}
    underscored: dict = {}
    legacy: dict = {}
    for fid, path in rows:
        match = re.fullmatch(r"interface/worldmap/([^/]+)/([^/]+)\.blp", path, re.I)
        if not match:
            continue
        config = wanted.get(match.group(1).lower())
        if not config:
            continue
        map_id, prefix = config
        filename = match.group(2).lower()
        tile = re.fullmatch(re.escape(prefix) + r"(\d+)_(\d+)", filename)
        if tile:
            floor, index = int(tile.group(1)), int(tile.group(2))
            if 1 <= index <= 12:
                underscored.setdefault((map_id, floor), {})[index] = int(fid)
            continue
        # 少数旧地图（祖尔法拉克、安其拉废墟、祖尔格拉布）一层存成 name1.blp … name12.blp
        flat = re.fullmatch(re.escape(prefix) + r"(\d+)", filename)
        if flat and 1 <= int(flat.group(1)) <= 12:
            legacy.setdefault((map_id, 1), {})[int(flat.group(1))] = int(fid)
    result = {}
    for map_id in floor_art:
        floors = []
        floor = 1
        # 优先用不会混淆的“层_格”形式（监狱两种都有）；只取从 1 开始的连续层（奥达曼还有后来的场景层 18）
        while True:
            tiles = underscored.get((map_id, floor)) or (legacy.get((map_id, floor)) if floor == 1 else None)
            if not tiles or len(tiles) != 12:
                break
            floors.append([tiles[i] for i in range(1, 13)])
            floor += 1
        if floors:
            result[map_id] = floors
    return result


def read_listfile(path: Path):
    with path.open(newline="", encoding="utf-8") as handle:
        for row in csv.reader(handle, delimiter=";"):
            if len(row) == 2 and row[1].startswith("interface/worldmap/"):
                yield row[0], row[1]


# ---------------------------------------------------------------------------
# 玩家自制地图贴图
# ---------------------------------------------------------------------------

def fan_size(width: int, height: int, max_width: int = FAN_MAX_WIDTH) -> tuple[int, int]:
    """等比缩小到不超过 max_width 宽，不放大。"""
    if width <= max_width:
        return width, height
    return max_width, round(height * max_width / width)


def grid(width: int, height: int, tile: int) -> tuple[int, int]:
    return -(-width // tile), -(-height // tile)


def dxt1_blocks(pixels):
    """RGB 像素 (H, W, 3)，H、W 为 4 的倍数 → DXT1 数据。每块取主轴方向上的两端颜色作端点。"""
    import numpy as np

    height, width, _ = pixels.shape
    blocks = (pixels.reshape(height // 4, 4, width // 4, 4, 3).transpose(0, 2, 1, 3, 4)
              .reshape(-1, 16, 3).astype(np.float32))
    mean = blocks.mean(axis=1, keepdims=True)
    centered = blocks - mean
    cov = np.einsum("nki,nkj->nij", centered, centered)
    axis = np.ones((blocks.shape[0], 3), np.float32)
    for _ in range(8):
        axis = np.einsum("nij,nj->ni", cov, axis)
        norm = np.linalg.norm(axis, axis=1, keepdims=True)
        axis = np.where(norm > 1e-6, axis / np.maximum(norm, 1e-6), np.float32(0.57735))
    projection = np.einsum("nki,ni->nk", centered, axis)
    low = blocks[np.arange(len(blocks)), projection.argmin(axis=1)]
    high = blocks[np.arange(len(blocks)), projection.argmax(axis=1)]

    def to565(color):
        c = np.clip(np.rint(color), 0, 255).astype(np.uint32)
        return ((c[:, 0] * 31 + 127) // 255) << 11 | ((c[:, 1] * 63 + 127) // 255) << 5 | ((c[:, 2] * 31 + 127) // 255)

    def from565(value):
        r = (value >> 11) & 31
        g = (value >> 5) & 63
        b = value & 31
        return np.stack([r * 255 / 31, g * 255 / 63, b * 255 / 31], axis=1).astype(np.float32)

    c0, c1 = to565(high), to565(low)
    swap = c0 < c1
    c0, c1 = np.where(swap, c1, c0), np.where(swap, c0, c1)
    p0, p1 = from565(c0), from565(c1)
    palette = np.stack([p0, p1, (2 * p0 + p1) / 3, (p0 + 2 * p1) / 3], axis=1)  # (N, 4, 3)
    distance = ((blocks[:, :, None, :] - palette[:, None, :, :]) ** 2).sum(axis=3)
    indices = distance.argmin(axis=2).astype(np.uint32)
    indices[c0 == c1] = 0  # 端点相同：三色模式，全部取第一个颜色
    packed = np.zeros(len(blocks), np.uint32)
    for k in range(16):
        packed |= indices[:, k] << (2 * k)
    out = np.zeros((len(blocks), 4), np.uint16)
    out[:, 0] = c0
    out[:, 1] = c1
    out[:, 2] = packed & 0xFFFF
    out[:, 3] = packed >> 16
    return out.astype("<u2").tobytes()


def blp2_dxt1(image) -> bytes:
    """RGB 图（边长为 2 的幂）→ 带全部多级纹理的 DXT1 BLP2。"""
    import numpy as np
    from PIL import Image

    width, height = image.size
    mips = []
    level = image
    while True:
        w, h = level.size
        padded = Image.new("RGB", (max(4, w), max(4, h)))
        padded.paste(level, (0, 0))
        mips.append(dxt1_blocks(np.asarray(padded)))
        if w == 1 and h == 1:
            break
        level = level.resize((max(1, w // 2), max(1, h // 2)), Image.LANCZOS)
    header_size = 4 + 4 + 4 + 8 + 16 * 4 * 2 + 256 * 4
    offsets, sizes, position = [], [], header_size
    for data in mips[:16]:
        offsets.append(position)
        sizes.append(len(data))
        position += len(data)
    offsets += [0] * (16 - len(offsets))
    sizes += [0] * (16 - len(sizes))
    header = b"BLP2" + struct.pack("<I4BII", 1, 2, 0, 0, 1, width, height)
    header += struct.pack("<16I", *offsets) + struct.pack("<16I", *sizes) + bytes(256 * 4)
    return header + b"".join(mips[:16])


def build_fan_floor(source: Path, name: str, write: bool) -> dict:
    from PIL import Image

    image = Image.open(source).convert("RGB")
    width, height = fan_size(*image.size)
    columns, rows = grid(width, height, FAN_TILE)
    textures = [f"{MEDIA_PATH}{name}-{index}" for index in range(1, columns * rows + 1)]
    if write:
        if image.size != (width, height):
            image = image.resize((width, height), Image.LANCZOS)
        MEDIA_DIR.mkdir(parents=True, exist_ok=True)
        for row in range(rows):
            for column in range(columns):
                tile = Image.new("RGB", (FAN_TILE, FAN_TILE))
                tile.paste(image.crop((column * FAN_TILE, row * FAN_TILE,
                                       min(width, (column + 1) * FAN_TILE), min(height, (row + 1) * FAN_TILE))))
                index = row * columns + column + 1
                (MEDIA_DIR / f"{name}-{index}.blp").write_bytes(blp2_dxt1(tile))
    return {"width": width, "height": height, "tile": FAN_TILE, "columns": columns, "textures": textures}


# ---------------------------------------------------------------------------

def export(site: Path, write_images: bool) -> dict:
    result = {}
    for map_id, floors in floor_tiles(read_listfile(site / LISTFILE), INSTANCE_FLOOR_ART).items():
        result[map_id] = {"floors": [
            {"width": CLIENT_WIDTH, "height": CLIENT_HEIGHT, "tile": CLIENT_TILE, "columns": CLIENT_COLUMNS,
             "textures": textures}
            for textures in floors
        ]}
    if write_images and MEDIA_DIR.exists():
        for old in MEDIA_DIR.glob("*.blp"):
            old.unlink()
    for map_id, floors in (FAN_MAPS.items() if FAN_MAPS_ENABLED else ()):
        built = []
        for floor in floors:
            entry = build_fan_floor(site / FAN_ORIGINALS / floor["source"], floor["name"], write_images)
            entry["label"] = floor.get("label")
            built.append(entry)
        result[map_id] = {"artist": FAN_ARTIST, "floors": built}
    return dict(sorted(result.items()))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--site", type=Path, default=site_export.DEFAULT_SITE)
    parser.add_argument("--skip-images", action="store_true", help="只重写数据文件，不重新生成贴图")
    args = parser.parse_args()
    data = export(args.site, not args.skip_images)
    missing = sorted(set(INSTANCE_FLOOR_ART) - set(data))
    if missing:
        print(f"warning: no floor art found for {missing}")
    site_export.write_lua("InstanceMaps.lua", "instanceMaps", data,
                          "玩家自制地图（无限版新地下城）由 Santiago Reyes 绘制，界面上署名。" if FAN_MAPS_ENABLED else None)
    print(f"InstanceMaps.lua: {len(data)} instances")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
