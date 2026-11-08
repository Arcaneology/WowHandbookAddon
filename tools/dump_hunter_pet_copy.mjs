// 输出网站猎人宠物专栏的文案 JSON，供 export_site_data.py 生成 WowHandbook/Data/HunterPets.lua。
// 网站的重点宠物看点、驯服提示、标签与家族定位写在 src/data/hunterPetCopy.ts 里，不是生成的数据文件；
// 这里只读导入网站自己的模块，保证插件与网站 /hunter-pets/ 页面用同一份文案。不改网站仓库的任何文件。
// 需要 Node 22.18 及以上（直接导入 .ts 文件）。
// 用法：node tools/dump_hunter_pet_copy.mjs /path/to/WowHandbook
import { pathToFileURL } from 'node:url';
import path from 'node:path';

const site = process.argv[2];
if (!site) {
  console.error('usage: node tools/dump_hunter_pet_copy.mjs <site>');
  process.exit(2);
}
const copy = await import(pathToFileURL(path.join(site, 'src/data/hunterPetCopy.ts')).href);

const pair = ([en, zh]) => ({ enUS: en, zhCN: zh });
const featured = {};
for (const [id, entry] of Object.entries(copy.featuredCopy)) {
  featured[id] = { why: pair(entry.why), tip: pair(entry.tip), tags: entry.tags };
}
const families = {};
for (const [slug, entry] of Object.entries(copy.familyCopy)) {
  families[slug] = { role: pair(entry.role) };
}
process.stdout.write(JSON.stringify({ featured, families }));
