// 输出网站推荐天赋方案的 JSON，供 export_site_data.py 生成 WowHandbook/Data/TalentPlans.lua。
// 方案写在网站的 TypeScript 源码里（src/data/builds.ts，文案在 src/data/buildCopy.ts），
// 这里只读导入网站自己的模块并用网站的 replayPlan 逐级重放，保证插件与网站的点法完全一致。
// 需要 Node 22.18 及以上（直接导入 .ts 文件）。
// 用法：node tools/dump_talent_plans.mjs /path/to/WowHandbook
import { pathToFileURL } from 'node:url';
import path from 'node:path';

const site = process.argv[2];
if (!site) {
  console.error('usage: node tools/dump_talent_plans.mjs <site>');
  process.exit(2);
}
const load = (file) => import(pathToFileURL(path.join(site, file)).href);

const { buildPresets } = await load('src/data/builds.ts');
const { replayPlan, replayOrder } = await load('src/lib/builds.ts');
const { talentTreesFor } = await load('src/data/talents.ts');
const { buildCopy, classGuideCopy } = await load('src/data/buildCopy.ts');

const classes = {};
for (const preset of buildPresets) {
  const trees = talentTreesFor(preset.classSlug, 'en');
  const replay = replayPlan(trees, preset);
  if (replay.error) throw new Error(`${preset.id}: ${replay.error}`);
  // 每个阶段（洗天赋前的各段与最终方案）的加点顺序：第 n 点 = 树序号 * 100 + 天赋序号（都从 1 起）
  const phases = [...(preset.earlier ?? []).map((p) => ({ respecAt: p.respecAt, order: p.order })), { respecAt: null, order: preset.order }];
  const orders = phases.map((phase) => ({
    respecAt: phase.respecAt,
    steps: replayOrder(trees, phase.order).steps.map((step) => (step.tree + 1) * 100 + step.talent + 1),
  }));
  const copy = (lang) => buildCopy[lang]?.[preset.id] ?? {};
  const entry = (classes[preset.classSlug] ??= {
    default: classGuideCopy[preset.classSlug]?.en?.startWith?.build ?? null,
    plans: [],
  });
  entry.plans.push({
    id: preset.id,
    role: preset.role,
    levels: preset.levels,
    respecs: replay.levels.filter((level) => level.respec).map((level) => level.level),
    codes: replay.levels.map((level) => level.code),
    orders,
    name: { en: copy('en').name ?? null, zh: copy('zh').name ?? null },
    use: { en: copy('en').use ?? null, zh: copy('zh').use ?? null },
  });
}
process.stdout.write(JSON.stringify({ classes }));
