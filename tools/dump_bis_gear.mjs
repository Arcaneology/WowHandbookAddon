// 输出网站 BiS（最佳升级装备）的 JSON，供 export_site_data.py 生成 WowHandbook/Data/BisGear.lua。
// 网站的 BiS 不是现成的数据文件，而是建站时由 src/data/classLeveling.ts 的 classBands 按天赋的属性权重
// 从副本掉落、任务、商人、制造里挑出来的；这里只读导入网站自己的模块并调用同一个函数，
// 保证插件与网站 /bis/ 页面用的是同一套算法。只输出物品 ID 与获取途径，名称、图标、属性由插件运行时向客户端取。
//
// 逐级推荐：classBands 的 ranges 参数传每级一段（[[1, 1], [2, 2] …]），挑装备时只看每段的最高等级
// （物品需求等级、副本进入等级、任务等级都不超过它），就得到网站算法在每一级的结果。
// 备选装备与 60 级 PvP 组仍按网站原来的分段（leveling.ts 的 brackets）导出。
//
// 专业装备（拾取绑定的制造装备、需要专业才能装备的物品，见网站的 professionNeeded）：
// - 逐级推荐与 PvP 首选的基础组不含任何专业装备（classBands 的 professions 传 []）；
// - variants 是学了某个专业、或某两个专业时的结果，键是排好序、用 + 连接的专业 slug；
//   单个专业只在结果和基础组不同时才导出，两个专业只在两者都单独导出过时才计算（算了就导出，即使和基础组相同）；
// - 备选装备取包含全部专业装备的结果，插件运行时按 restricted（物品 ID -> 所需专业）筛掉没学的专业。
// 每个职业在一个工作线程里算（约 10 倍于原来的计算量，并行后约一两分钟）。
// 需要 Node 22.18 及以上（直接导入 .ts 文件）。
// 用法：node tools/dump_bis_gear.mjs /path/to/WowHandbook
import { pathToFileURL } from 'node:url';
import path from 'node:path';
import { Worker, isMainThread, parentPort, workerData } from 'node:worker_threads';

const MAX_LEVEL = 60;
const PER_LEVEL = Array.from({ length: MAX_LEVEL }, (_, i) => [i + 1, i + 1]);

const loader = (site) => (file) => import(pathToFileURL(path.join(site, file)).href);

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

// 一个职业的全部天赋（在工作线程里运行）
async function dumpClass(site, slug) {
  const load = loader(site);
  const leveling = await load('src/data/classLeveling.ts');
  const { brackets } = await load('src/data/leveling.ts');
  const { worldGear } = await load('src/data/gearSources.ts');

  // 可能出现专业装备的专业：制造装备里拾取绑定的、需要专业才能装备的
  const professions = new Set();
  for (const gear of worldGear) {
    for (const s of gear.sources) {
      const needs = leveling.professionNeeded(gear.item, s);
      if (needs) professions.add(needs);
    }
  }
  const allProfessions = [...professions].sort();

  const restricted = {};
  const pick = (p) => {
    const needs = leveling.professionNeeded(p.item, p.source);
    if (needs) restricted[p.id] = needs;
    return { id: p.id, slot: p.slot, source: source(p.source) };
  };
  const alts = (b) => Object.values(b.alternatives).flat().map(pick);
  const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
  const pvpRange = [[...brackets.at(-1)]];

  const preset = leveling.levelingBuildFor(slug);
  const specs = leveling.specsFor(slug).map((tree) => {
    const factions = {};
    for (const faction of ['alliance', 'horde']) {
      const levelsFor = (profs) => leveling.classBands(slug, faction, tree, false, PER_LEVEL, profs).map((b) => b.gear.map(pick));
      const pvpFor = (profs) => leveling.classBands(slug, faction, tree, true, pvpRange, profs)[0].gear.map(pick);
      const bands = leveling.classBands(slug, faction, tree);
      const pvp = leveling.classBands(slug, faction, tree, true).at(-1);
      const base = { levels: levelsFor([]), pvp: pvpFor([]) };
      const variants = {};
      for (const profession of allProfessions) {
        const v = { levels: levelsFor([profession]), pvp: pvpFor([profession]) };
        if (!same(v, base)) variants[profession] = v;
      }
      const single = Object.keys(variants);
      for (let i = 0; i < single.length; i++) {
        for (let j = i + 1; j < single.length; j++) {
          const profs = [single[i], single[j]];
          variants[profs.join('+')] = { levels: levelsFor(profs), pvp: pvpFor(profs) };
        }
      }
      factions[faction] = {
        levels: base.levels,
        bands: bands.map((b) => ({ range: b.range, alts: alts(b) })),
        pvp: { range: pvp.range, gear: base.pvp, alts: alts(pvp) },
        variants,
      };
    }
    return { tree, slug: leveling.specSlug(tree), ...factions };
  });
  return { entry: { default: preset?.tree ?? null, specs }, restricted };
}

if (!isMainThread) {
  parentPort.postMessage(await dumpClass(workerData.site, workerData.slug));
} else {
  const site = process.argv[2];
  if (!site) {
    console.error('usage: node tools/dump_bis_gear.mjs <site>');
    process.exit(2);
  }
  const load = loader(site);
  const leveling = await load('src/data/classLeveling.ts');
  const { getClasses } = await load('src/data/classes.ts');
  const slugs = getClasses().map((c) => c.slug);
  const results = await Promise.all(slugs.map((slug) => new Promise((resolve, reject) => {
    const worker = new Worker(new URL(import.meta.url), { workerData: { site, slug } });
    worker.once('message', resolve);
    worker.once('error', reject);
    worker.once('exit', (code) => code && reject(new Error(`${slug}: worker exited with ${code}`)));
  })));
  const classes = {};
  const restricted = {};
  slugs.forEach((slug, i) => {
    classes[slug] = results[i].entry;
    Object.assign(restricted, results[i].restricted);
  });
  // 网站 BiS 页开放的组（链接可直接跳到该组）
  const siteSets = leveling.gearSets.filter((set) => leveling.openGearCheckpoints.has(set.level)).map((set) => set.id);
  process.stdout.write(JSON.stringify({ classes, siteSets, restricted }));
}
