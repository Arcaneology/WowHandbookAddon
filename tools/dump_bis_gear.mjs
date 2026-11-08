// 输出网站 BiS（最佳升级装备）的 JSON，供 export_site_data.py 生成 WowHandbook/Data/BisGear.lua。
// 网站的 BiS 不是现成的数据文件，而是建站时由 src/data/classLeveling.ts 的 classBands 按天赋的属性权重
// 从副本掉落、任务、商人、制造里挑出来的；这里只读导入网站自己的模块并调用同一个函数，
// 保证插件与网站 /bis/ 页面用的是同一套算法。只输出物品 ID 与获取途径，名称、图标、属性由插件运行时向客户端取。
//
// 逐级推荐：classBands 按 leveling.ts 的 brackets（1–10、10–20 … 50–60）分段，挑装备时只看每段的最高等级
// （物品需求等级、副本进入等级、任务等级都不超过它）。这里在本进程内存里把 brackets 换成每级一段，
// 就得到网站算法在每一级的结果；不改网站仓库的任何文件。备选装备与 60 级 PvP 组仍按网站原来的分段导出。
// 需要 Node 22.18 及以上（直接导入 .ts 文件）。
// 用法：node tools/dump_bis_gear.mjs /path/to/WowHandbook
import { pathToFileURL } from 'node:url';
import path from 'node:path';

const site = process.argv[2];
if (!site) {
  console.error('usage: node tools/dump_bis_gear.mjs <site>');
  process.exit(2);
}
const load = (file) => import(pathToFileURL(path.join(site, file)).href);

const leveling = await load('src/data/classLeveling.ts');
const { brackets } = await load('src/data/leveling.ts');
const { getClasses } = await load('src/data/classes.ts');

// 获取途径压成纯值列表：[种类, 参数…]
function source(s) {
  switch (s.kind) {
    case 'drop':
      return ['drop', s.dungeon.entry.slug, s.boss];
    case 'quest':
      return ['quest', s.quest.id];
    case 'world-quest':
      return ['quest', s.questId];
    case 'vendor':
      return ['vendor', s.npcId, s.npc.name];
    case 'mob':
      return ['mob', s.npcId, s.npc.name];
    case 'trash':
      return ['trash', s.dungeon];
    case 'crafted':
      return ['crafted', s.profession, s.recipe];
    default:
      throw new Error(`unknown gear source ${s.kind}`);
  }
}

const pick = (p) => ({ id: p.id, slot: p.slot, source: source(p.source) });
const alts = (b) => Object.values(b.alternatives).flat().map(pick);
const MAX_LEVEL = 60;

// 网站原来的分段
const bandRanges = brackets.map((range) => [...range]);
const bandsFor = (slug, faction, tree, pvp = false) => {
  brackets.splice(0, brackets.length, ...bandRanges);
  return leveling.classBands(slug, faction, tree, pvp);
};
// 每级一段
const levelsFor = (slug, faction, tree) => {
  brackets.splice(0, brackets.length, ...Array.from({ length: MAX_LEVEL }, (_, i) => [i + 1, i + 1]));
  return leveling.classBands(slug, faction, tree).map((b) => b.gear.map(pick));
};

const classes = {};
for (const { slug } of getClasses()) {
  const preset = leveling.levelingBuildFor(slug);
  const specs = leveling.specsFor(slug).map((tree) => {
    const factions = {};
    for (const faction of ['alliance', 'horde']) {
      const bands = bandsFor(slug, faction, tree);
      const pvp = bandsFor(slug, faction, tree, true).at(-1);
      factions[faction] = {
        levels: levelsFor(slug, faction, tree),
        bands: bands.map((b) => ({ range: b.range, alts: alts(b) })),
        pvp: { range: pvp.range, gear: pvp.gear.map(pick), alts: alts(pvp) },
      };
    }
    return { tree, slug: leveling.specSlug(tree), ...factions };
  });
  classes[slug] = { default: preset?.tree ?? null, specs };
}
brackets.splice(0, brackets.length, ...bandRanges);
// 网站 BiS 页开放的组（链接可直接跳到该组）
const siteSets = leveling.gearSets.filter((set) => leveling.openGearCheckpoints.has(set.level)).map((set) => set.id);
process.stdout.write(JSON.stringify({ classes, siteSets }));
